#!/bin/bash
# GridCraft in italiano, per macOS.
#
# Dopo ogni aggiornamento di GridCraft fatto con l'ArtCraft Launcher, fai doppio clic su questo
# file. Legge la versione di GridCraft installata, scarica da
# github.com/kcobelli-pixel/gridcraft-italiano la build italiana della stessa versione, ne
# controlla l'impronta SHA-256, sostituisce l'app e imposta l'italiano come lingua
# dell'interfaccia (ui.json, con una copia ui.json.bak). Le frasi non ancora tradotte restano in
# inglese. Per tornare alla versione ufficiale basta "Reinstalla" nel Launcher, o il prossimo
# aggiornamento.
set -euo pipefail

REPO='kcobelli-pixel/gridcraft-italiano'
BUNDLE_ID='ai.storyteller.gridcraft'
UI_JSON="$HOME/Library/Application Support/GridCraft/ui.json"
LAUNCHER_RECORD="$HOME/Library/Application Support/ArtCraft Launcher/installed.json"
TMP=''

cleanup() {
  if [ -n "$TMP" ]; then
    hdiutil detach -quiet "$TMP/mnt" 2>/dev/null || hdiutil detach -force -quiet "$TMP/mnt" 2>/dev/null || true
    # Never recurse into an image that is still mounted (its folder is on another device).
    if [ ! -d "$TMP/mnt" ] || [ "$(stat -f %d "$TMP/mnt")" = "$(stat -f %d "$TMP")" ]; then rm -rf "$TMP"; fi
  fi
}
trap cleanup EXIT

fail() {
  printf '\n\033[31m%s\033[0m\n' "$1"
  exit "${2:-1}"
}

fail_not_ready() {
  fail "La versione italiana di GridCraft $VERSION non è ancora pronta. Viene preparata in automatico entro qualche ora da ogni aggiornamento: riprova più tardi." 2
}

plist() { /usr/libexec/PlistBuddy -c "Print :$2" "$1/Contents/Info.plist" 2>/dev/null || true; }

app_version() {
  local v
  v="$(plist "$1" GridCraftVersion)"
  [ -n "$v" ] || v="$(plist "$1" CFBundleShortVersionString)"
  printf '%s' "$v"
}

assert_not_running() {
  if pgrep -x GridCraft >/dev/null 2>&1; then fail 'GridCraft è aperto: chiudilo e riesegui la patch.'; fi
}

# Where the launcher put GridCraft (its own record first), as long as it is GridCraft.
find_app() {
  local recorded='' app
  if [ -f "$LAUNCHER_RECORD" ]; then
    recorded="$(osascript -l JavaScript -e '
      function run(argv) {
        ObjC.import("Foundation");
        const s = $.NSString.stringWithContentsOfFileEncodingError(argv[0], $.NSUTF8StringEncoding, null);
        if (s.isNil()) return "";
        const r = JSON.parse(s.js);
        return (r && r.apps && r.apps.gridcraft && r.apps.gridcraft.path) || "";
      }' "$LAUNCHER_RECORD" 2>/dev/null || true)"
  fi
  for app in "$recorded" /Applications/GridCraft.app "$HOME/Applications/GridCraft.app"; do
    if [ -n "$app" ] && [ -d "$app" ] && [ "$(plist "$app" CFBundleIdentifier)" = "$BUNDLE_ID" ]; then
      printf '%s' "$app"
      return 0
    fi
  done
  return 1
}

# GridCraft saves ui.json only when it closes, so it must not be running. Only "language"
# changes; the file is written without a BOM (GridCraft rejects one). A new file also keeps the
# first-run "follow the system theme", which GridCraft only assumes while ui.json is missing.
set_language() {
  assert_not_running
  if osascript -l JavaScript -e '
    function run(argv) {
      ObjC.import("Foundation");
      const path = argv[0];
      const fm = $.NSFileManager.defaultManager;
      let ui = { systemTheme: true, language: "it" };
      if (fm.fileExistsAtPath(path)) {
        const s = $.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null);
        if (s.isNil()) throw new Error("unreadable");
        let text = s.js;
        if (text.charCodeAt(0) === 0xFEFF) text = text.slice(1);
        ui = JSON.parse(text);
        if (ui === null || typeof ui !== "object" || Array.isArray(ui)) throw new Error("not an object");
        ui.language = "it";
        fm.removeItemAtPathError(path + ".bak", null);
        if (!fm.copyItemAtPathToPathError(path, path + ".bak", null)) throw new Error("backup failed");
      } else {
        const dir = $(path).stringByDeletingLastPathComponent;
        if (!fm.createDirectoryAtPathWithIntermediateDirectoriesAttributesError(dir, true, $(), null)) throw new Error("mkdir failed");
      }
      if (!$(JSON.stringify(ui, null, 2) + "\n").writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null)) throw new Error("write failed");
      return "ok";
    }' "$UI_JSON" >/dev/null 2>&1; then
    echo "Lingua dell'interfaccia impostata su Italiano."
  else
    printf '\033[33m%s\033[0m\n' 'Non sono riuscito a impostare la lingua: in GridCraft scegli Italiano in View › Interface language.'
  fi
}

# Prints the HTTP status (000 when the transfer itself failed); the body goes to $TMP/<name>.
fetch() {
  local code
  code="$(curl -sSL --retry 2 -o "$TMP/$1" -w '%{http_code}' "https://github.com/$REPO/releases/download/v$VERSION/$1" 2>/dev/null)" || code=000
  printf '%s' "$code"
}

echo 'GridCraft in italiano'
echo '====================='

APP="$(find_app)" || fail "GridCraft non risulta installato: installalo (o aggiornalo) con l'ArtCraft Launcher, poi riesegui la patch."
VERSION="$(app_version "$APP")"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Versione di GridCraft non riconosciuta: '$VERSION'."
echo "GridCraft installato: versione $VERSION ($APP)"
assert_not_running

TMP="$(mktemp -d "${TMPDIR:-/tmp}/gridcraft-italiano.XXXXXX")"
echo 'Scarico la versione italiana...'
status="$(fetch SHA256SUMS.txt)"
if [ "$status" != 200 ]; then
  # build.yml publishes this marker instead of a build once upstream ships Italian itself.
  if [ "$(fetch ITALIANO-UFFICIALE.txt)" = 200 ]; then
    official="Buone notizie: GridCraft $VERSION è già in italiano nella versione ufficiale. La patch non serve più: da ora puoi aggiornare GridCraft con il Launcher e usarlo così com'è."
    printf '\n\033[32m%s\033[0m\n' "$official"
    set_language
    osascript -e 'on run argv' -e 'display dialog (item 1 of argv) with title "GridCraft in italiano" buttons {"OK"} default button 1 with icon note' -e 'end run' "$official" >/dev/null 2>&1 || true
    exit 0
  fi
  [ "$status" != 404 ] || fail_not_ready
  fail "Non riesco a contattare GitHub (risposta: $status). Controlla la connessione e riprova."
fi

DMG="gridcraft-$VERSION-macos-universal.dmg"
status="$(fetch "$DMG")"
[ "$status" != 404 ] || fail_not_ready
[ "$status" = 200 ] || fail "Non riesco a scaricare $DMG da GitHub (risposta: $status). Controlla la connessione e riprova."
want="$(awk -v n="$DMG" 'length($1) == 64 && $1 ~ /^[0-9a-fA-F]+$/ && ($2 == n || $2 == "*" n) { print tolower($1); exit }' "$TMP/SHA256SUMS.txt")"
# Not listed yet: the release is still being published.
[ -n "$want" ] || fail_not_ready
got="$(shasum -a 256 "$TMP/$DMG" | awk '{ print $1 }')"
[ "$got" = "$want" ] || fail "Il file scaricato $DMG non corrisponde all'impronta pubblicata, quindi non lo installo. Se la versione italiana si stava aggiornando proprio ora, riprova tra qualche minuto."

mkdir "$TMP/mnt"
hdiutil attach -nobrowse -readonly -noverify -noautoopen -mountpoint "$TMP/mnt" "$TMP/$DMG" >/dev/null || fail "Non riesco ad aprire $DMG."
NEW_APP="$TMP/mnt/GridCraft.app"
[ "$(plist "$NEW_APP" CFBundleIdentifier)" = "$BUNDLE_ID" ] || fail "$DMG non contiene GridCraft."
[ "$(app_version "$NEW_APP")" = "$VERSION" ] || fail "$DMG non contiene GridCraft $VERSION."

PARENT="$(dirname "$APP")"
[ -w "$PARENT" ] || fail "Non ho il permesso di scrivere in $PARENT."
STAGED="$PARENT/.GridCraft-italiano.app"
OLD="$PARENT/.GridCraft-originale.app"
rm -rf "$STAGED" "$OLD"
echo 'Installo la versione italiana...'
ditto "$NEW_APP" "$STAGED"
xattr -dr com.apple.quarantine "$STAGED" 2>/dev/null || true
codesign --verify "$STAGED" 2>/dev/null || { rm -rf "$STAGED"; fail "La copia di GridCraft non è integra: non la installo."; }
assert_not_running
# The new copy is complete beside the old one before the swap, two renames in one folder.
mv "$APP" "$OLD"
if ! mv "$STAGED" "$APP"; then
  mv "$OLD" "$APP"
  rm -rf "$STAGED"
  fail "Non sono riuscito a sostituire $APP: GridCraft resta com'era."
fi
rm -rf "$OLD"

set_language
echo ''
printf '\033[32m%s\033[0m\n' "Fatto: GridCraft $VERSION è in italiano. Le frasi non ancora tradotte restano in inglese."
echo 'Dopo il prossimo aggiornamento di GridCraft riesegui Applica-italiano.command.'
