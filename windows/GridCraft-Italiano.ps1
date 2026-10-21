<#
  GridCraft in italiano, per Windows.

  Dopo ogni aggiornamento di GridCraft fatto con l'ArtCraft Launcher, esegui Applica-italiano.cmd.
  Lo script:
    1. legge la versione di GridCraft installata;
    2. scarica da github.com/kcobelli-pixel/gridcraft-italiano la build italiana della stessa
       versione e ne controlla l'impronta SHA-256;
    3. la installa al posto di quella inglese (Windows chiede il permesso di amministratore);
    4. imposta l'italiano come lingua dell'interfaccia (ui.json, con una copia ui.json.bak).
  Le frasi non ancora tradotte restano in inglese. Per tornare alla versione ufficiale basta
  "Reinstalla" nel Launcher, o il prossimo aggiornamento.

  Funziona con Windows PowerShell 5.1 (quello di Windows 10/11) e con PowerShell 7.
  Il file è salvato in UTF-8 con BOM: senza, PowerShell 5.1 mostra male le lettere accentate.
#>
$ErrorActionPreference = 'Stop'

# A 32-bit PowerShell sees the 32-bit registry and would miss the x64 install: rerun as 64-bit.
if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
  & "$env:windir\sysnative\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File $PSCommandPath
  exit $LASTEXITCODE
}

# Invoke-WebRequest in Windows PowerShell 5.1 is very slow while it draws a progress bar.
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$Repo = 'kcobelli-pixel/gridcraft-italiano'
$Publisher = 'Learning Machines LLC'
$Headers = @{ 'User-Agent' = 'gridcraft-italiano'; 'Accept' = 'application/vnd.github+json' }
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$InstallLog = Join-Path ([IO.Path]::GetTempPath()) 'gridcraft-italiano-installazione.log'
$script:Tmp = $null

function Fail([string] $Text, [int] $Code = 1) {
  if ($script:Tmp) { Remove-Item -LiteralPath $script:Tmp -Recurse -Force -ErrorAction SilentlyContinue }
  Write-Host ''
  Write-Host $Text -ForegroundColor Red
  exit $Code
}

function Fail-NotReady {
  Fail "La versione italiana di GridCraft $version non è ancora pronta. Viene preparata in automatico entro qualche ora da ogni aggiornamento: riprova più tardi." 2
}

function Assert-NotRunning {
  if (Get-Process -Name gridcraft -ErrorAction SilentlyContinue) {
    Fail 'GridCraft è aperto: chiudilo e riesegui la patch.'
  }
}

# The ArtCraft Launcher installs GridCraft with its MSI (per-machine): the Uninstall entry is the
# truth for the version, as in the launcher's own detection.
function Find-MsiInstall {
  $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
          'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
          'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
  @(Get-ItemProperty -Path $keys -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -eq 'GridCraft' -and $_.Publisher -eq $Publisher })
}

function Get-MsiFolder {
  $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\gridcraft.exe'
  $exe = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).'(default)'
  if (-not $exe) { return $null }
  $dir = Split-Path -Parent $exe.Trim('"')
  if ($dir -and (Test-Path -LiteralPath $dir) -and $dir -notmatch '"') { return $dir }
  $null
}

function Assert-Hash([string] $File, [string] $SumsFile) {
  $name = Split-Path -Leaf $File
  $expected = $null
  foreach ($line in Get-Content -LiteralPath $SumsFile) {
    if ($line -match '^([0-9a-fA-F]{64}) [ *](.+)$' -and $Matches[2].Trim() -eq $name) {
      $expected = $Matches[1].ToLowerInvariant()
      break
    }
  }
  # Not listed yet: the release is still being published.
  if (-not $expected) { Fail-NotReady }
  $actual = (Get-FileHash -LiteralPath $File -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actual -ne $expected) {
    Fail "Il file scaricato $name non corrisponde all'impronta pubblicata, quindi non lo installo. Se la versione italiana si stava aggiornando proprio ora, riprova tra qualche minuto."
  }
}

function Save-Asset($Release, [string] $Name, [string] $Dir) {
  $asset = @($Release.assets) | Where-Object { $_.name -eq $Name } | Select-Object -First 1
  if (-not $asset) { Fail-NotReady }
  $url = [string] $asset.browser_download_url
  if (-not $url.StartsWith("https://github.com/$Repo/releases/download/")) { Fail "Indirizzo di download inatteso: $url" }
  $out = Join-Path $Dir $Name
  try {
    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -Headers @{ 'User-Agent' = 'gridcraft-italiano' }
  } catch {
    Fail "Download di $Name non riuscito: $($_.Exception.Message)"
  }
  $out
}

# GridCraft saves ui.json only when it closes, so it must not be running. The file is edited as
# text (only the "language" value changes) and written without a BOM, which GridCraft rejects.
# A new file also keeps the first-run "follow the Windows theme", which GridCraft only assumes
# while ui.json is missing.
function Set-ItalianLanguage {
  $dir = Join-Path $env:APPDATA 'GridCraft'
  $file = Join-Path $dir 'ui.json'
  $fresh = "{`n  `"systemTheme`": true,`n  `"language`": `"it`"`n}`n"
  if (-not (Test-Path -LiteralPath $file)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    [IO.File]::WriteAllText($file, $fresh, $Utf8NoBom)
    return $true
  }
  $text = [IO.File]::ReadAllText($file)
  $key = New-Object System.Text.RegularExpressions.Regex('"language"\s*:')
  $language = New-Object System.Text.RegularExpressions.Regex('"language"\s*:\s*("(?:[^"\\]|\\.)*"|null|true|false|-?[0-9][0-9.eE+-]*)')
  if ($key.Matches($text).Count -gt 1) { return $false }
  if ($language.IsMatch($text)) {
    $new = $language.Replace($text, '"language": "it"', 1)
  } elseif ($key.IsMatch($text)) {
    return $false
  } elseif ($text.Trim() -match '^\{\s*\}$') {
    $new = $fresh
  } else {
    $new = (New-Object System.Text.RegularExpressions.Regex('^\s*\{')).Replace($text, "{`n  `"language`": `"it`",", 1)
  }
  try { $null = $new | ConvertFrom-Json } catch { return $false }
  Copy-Item -LiteralPath $file -Destination "$file.bak" -Force
  [IO.File]::WriteAllText($file, $new, $Utf8NoBom)
  $true
}

function Set-LanguageOrWarn {
  Assert-NotRunning
  if (Set-ItalianLanguage) {
    Write-Host 'Lingua dell''interfaccia impostata su Italiano.'
  } else {
    Write-Host 'Non sono riuscito a impostare la lingua: in GridCraft scegli Italiano nel menu della lingua.' -ForegroundColor Yellow
  }
}

Write-Host 'GridCraft in italiano'
Write-Host '====================='

if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64' -or $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64' -or -not [Environment]::Is64BitOperatingSystem) {
  Fail 'Questa patch esiste solo per Windows a 64 bit su processori Intel o AMD (x64).'
}

$msiInstalls = @(Find-MsiInstall)
$portableExe = Join-Path $env:LOCALAPPDATA 'ArtCraft Launcher\apps\gridcraft\gridcraft.exe'
if ($msiInstalls.Count -gt 1) {
  Fail 'Risultano installate più copie di GridCraft: disinstallale da Impostazioni > App, reinstalla GridCraft dal Launcher e riprova.'
} elseif ($msiInstalls.Count -eq 1) {
  $mode = 'msi'
  $version = [string] $msiInstalls[0].DisplayVersion
} elseif (Test-Path -LiteralPath $portableExe) {
  $mode = 'portable'
  $record = Join-Path $env:LOCALAPPDATA 'ArtCraft Launcher\installed.json'
  $version = $null
  if (Test-Path -LiteralPath $record) {
    try { $version = [string] (Get-Content -LiteralPath $record -Raw | ConvertFrom-Json).apps.gridcraft.version } catch { $version = $null }
  }
  if (-not $version) { $version = [string] (Get-Item -LiteralPath $portableExe).VersionInfo.ProductVersion }
} else {
  Fail 'GridCraft non risulta installato: installalo (o aggiornalo) con l''ArtCraft Launcher, poi riesegui la patch.'
}
if ($version -notmatch '^\d+\.\d+\.\d+$') { Fail "Versione di GridCraft non riconosciuta: '$version'." }
Write-Host "GridCraft installato: versione $version"
Assert-NotRunning

$tag = "v$version"
try {
  $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/tags/$tag" -Headers $Headers
} catch {
  $status = 0
  if ($_.Exception.Response) { $status = [int] $_.Exception.Response.StatusCode }
  if ($status -eq 404) { Fail-NotReady }
  Fail "Non riesco a contattare GitHub: $($_.Exception.Message)"
}

# build.yml publishes this marker instead of a build once upstream ships Italian itself.
if (@($release.assets) | Where-Object { $_.name -eq 'ITALIANO-UFFICIALE.txt' }) {
  $official = "Buone notizie: GridCraft $version è già in italiano nella versione ufficiale.`n`nLa patch non serve più: da ora puoi aggiornare GridCraft con il Launcher e usarlo così com'è."
  Write-Host ''
  Write-Host $official -ForegroundColor Green
  Set-LanguageOrWarn
  try { $null = (New-Object -ComObject WScript.Shell).Popup($official, 0, 'GridCraft in italiano', 64) } catch { }
  exit 0
}

$script:Tmp = Join-Path ([IO.Path]::GetTempPath()) ('gridcraft-italiano-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $script:Tmp | Out-Null
Write-Host 'Scarico la versione italiana...'
$sums = Save-Asset $release 'SHA256SUMS.txt' $script:Tmp

if ($mode -eq 'msi') {
  $msi = Save-Asset $release "gridcraft-$version-windows-x64.msi" $script:Tmp
  Assert-Hash $msi $sums
  Unblock-File -LiteralPath $msi
  $msiArgs = @('/i', "`"$msi`"", '/passive', '/norestart', '/l*v', "`"$InstallLog`"")
  $folder = Get-MsiFolder
  if ($folder) { $msiArgs += "INSTALLFOLDER=`"$folder`"" }
  Assert-NotRunning
  Write-Host 'Installo la versione italiana: se Windows chiede il permesso, rispondi Sì.'
  $msiexec = Join-Path $env:SystemRoot 'System32\msiexec.exe'
  $process = Start-Process -FilePath $msiexec -ArgumentList $msiArgs -Wait -PassThru
  switch ($process.ExitCode) {
    0 { }
    3010 { Write-Host 'Windows chiede di riavviare il PC per completare l''installazione.' -ForegroundColor Yellow }
    1641 { }
    1602 { Fail 'Installazione annullata: GridCraft resta in inglese.' }
    1618 { Fail 'Un''altra installazione è in corso: aspetta che finisca e riesegui la patch.' }
    default { Fail "L'installazione non è riuscita (codice $($process.ExitCode)). Il registro è in $InstallLog" }
  }
  $after = @(Find-MsiInstall)
  if ($after.Count -ne 1 -or [string] $after[0].DisplayVersion -ne $version) {
    Fail "Dopo l'installazione GridCraft non risulta alla versione $version. Il registro è in $InstallLog"
  }
} else {
  $zip = Save-Asset $release "gridcraft-$version-windows-x64-portable.zip" $script:Tmp
  Assert-Hash $zip $sums
  Unblock-File -LiteralPath $zip
  $unpacked = Join-Path $script:Tmp 'unpacked'
  Expand-Archive -LiteralPath $zip -DestinationPath $unpacked -Force
  $target = Split-Path -Parent $portableExe
  Assert-NotRunning
  foreach ($name in 'gridcraft.exe', 'gridcraft-cli.exe') {
    $source = Get-ChildItem -LiteralPath $unpacked -Recurse -Filter $name | Select-Object -First 1
    if (-not $source) { Fail "Nello zip manca $name." }
    Copy-Item -LiteralPath $source.FullName -Destination (Join-Path $target $name) -Force
  }
}

Set-LanguageOrWarn
Remove-Item -LiteralPath $script:Tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host ''
Write-Host "Fatto: GridCraft $version è in italiano. Le frasi non ancora tradotte restano in inglese." -ForegroundColor Green
Write-Host 'Dopo il prossimo aggiornamento di GridCraft riesegui Applica-italiano.cmd.'
exit 0
