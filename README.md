# GridCraft in italiano

[GridCraft](https://github.com/storytold/gridcraft) non ha ancora l'italiano nelle versioni
ufficiali. Questo repository ricompila ogni nuova versione con un catalogo italiano
(`catalog/it.rs`, 971 voci) e la pubblica tra le [release](../../releases). Le frasi non ancora
tradotte restano in inglese.

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

Lo script legge la versione installata, scarica la build italiana della stessa versione, ne
controlla l'impronta SHA-256, la installa e imposta l'italiano nelle preferenze (`ui.json`,
con una copia `ui.json.bak`). Se la versione italiana non è ancora pronta, te lo dice e non
tocca niente: riprova più tardi.

Per tornare alla versione ufficiale in inglese basta **Reinstalla** nel Launcher. Il Launcher
continua a proporre gli aggiornamenti come sempre: dopo ognuno, riapplica la patch.

## Contenuto

- `catalog/it.rs`: il catalogo italiano.
- `add_italian.py`: aggiunge l'italiano al codice di una versione di GridCraft. Se un giorno
  GridCraft avrà l'italiano ufficiale, lo riconosce e non cambia niente.
- `windows/`: la patch per Windows.

Il catalogo segue la licenza di GridCraft (MIT OR Apache-2.0).
