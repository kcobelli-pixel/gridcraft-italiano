# GridCraft in italiano

Questo repository ricompila ogni nuova versione di [GridCraft](https://github.com/storytold/gridcraft)
con le sue patch e la pubblica tra le [release](../../releases):

- **l'italiano**, per le versioni che non lo hanno ufficialmente (catalogo `catalog/it.rs`, 971
  voci; le frasi non ancora tradotte restano in inglese). Dalla 0.16.0 GridCraft è in italiano
  ufficialmente: le patch lo riconoscono e lo dicono, e su Mac non serve più niente;
- **su Windows, la correzione della stampa per le stampanti Brother** (per esempio la
  MFC-L3760CDW): se il driver rifiuta la stampa con l'errore 0x80040003 ("Interfaccia non
  supportata"), il documento viene stampato tramite GDI. È la stessa correzione della patch di
  PdfCraft ([pdfcraft-stampa](https://github.com/kcobelli-pixel/pdfcraft-stampa)).

Sono build **non ufficiali e non firmate**, fatte da GitHub Actions a partire dal codice
pubblico di storytold/gridcraft (`.github/workflows/build.yml`). Il controllo avviene ogni ora:
una nuova versione di GridCraft è pronta in italiano circa un'ora dopo l'uscita.

## Windows

Una volta sola: scarica `GridCraft-Italiano-Windows.zip` dalla release
[strumenti](../../releases/tag/strumenti). Prima di estrarlo, aprilo con il tasto destro
› Proprietà › spunta **Annulla blocco** › OK. Estrai la cartella dove preferisci, per esempio
sul Desktop.

Dopo ogni aggiornamento di GridCraft fatto con l'ArtCraft Launcher:

1. chiudi GridCraft;
2. fai doppio clic su `Applica-italiano.cmd` (se Windows mostra "PC protetto", scegli
   "Ulteriori informazioni" › "Esegui comunque");
3. quando Windows chiede il permesso di installare, rispondi **Sì** (l'autore risulta
   sconosciuto perché la build non è firmata).

Lo script legge la versione installata, scarica la build con la patch della stessa versione
(italiano e correzione della stampa), ne controlla l'impronta SHA-256, la installa e imposta
l'italiano nelle preferenze (`ui.json`, con una copia `ui.json.bak`). Se la build non è ancora
pronta, te lo dice e non tocca niente: riprova più tardi.

Per tornare alla versione ufficiale in inglese basta **Reinstalla** nel Launcher. Il Launcher
continua a proporre gli aggiornamenti come sempre: dopo ognuno, riapplica la patch.

## Mac

Una volta sola: scarica `GridCraft-Italiano-Mac.zip` dalla stessa release
[strumenti](../../releases/tag/strumenti) e aprilo: compare `Applica-italiano.command`. Mettilo
dove preferisci, per esempio sul Desktop.

Dopo ogni aggiornamento di GridCraft fatto con l'ArtCraft Launcher:

1. chiudi GridCraft;
2. fai doppio clic su `Applica-italiano.command`: si apre il Terminale e fa tutto da solo.

La prima volta macOS non lo apre perché il file viene da internet: vai in Impostazioni di
Sistema › Privacy e sicurezza, scorri in basso e scegli **Apri comunque**. Dalle volte
successive si apre subito.

Lo script fa le stesse cose della versione Windows: legge la versione installata, scarica il
`.dmg` italiano della stessa versione, ne controlla l'impronta SHA-256, sostituisce l'app e
imposta l'italiano (`~/Library/Application Support/GridCraft/ui.json`, con una copia
`ui.json.bak`). L'app è firmata ad-hoc, non da ArtCraft: il Launcher la vede comunque come
GridCraft aggiornato e al prossimo aggiornamento la sostituisce con quella ufficiale.

## Contenuto

- `catalog/it.rs`: il catalogo italiano.
- `add_italian.py`: aggiunge l'italiano al codice di una versione di GridCraft. Se un giorno
  GridCraft avrà l'italiano ufficiale, lo riconosce e non cambia niente.
- `windows/`: la patch per Windows. La correzione della stampa viene applicata in fase di build
  con `apply_print_fix.sh` di pdfcraft-stampa: se un giorno GridCraft la avrà ufficialmente, la
  build per Windows avrà solo l'italiano.
- `mac/`: la patch per Mac.

Il catalogo segue la licenza di GridCraft (MIT OR Apache-2.0).
