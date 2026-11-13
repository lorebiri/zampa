# Installare Lulù sul telefono

Lulù è gratuita e funziona senza account: i dati restano sul telefono.

## Android (qualsiasi telefono Android 7 o più recente)

L'APK si scarica dalla pagina **Installa Lulù** della web app (`download.html`, oppure
**Profilo › Installa Lulù sul telefono**), che spiega anche i passaggi:

1. Tocca **Scarica per Android (APK)** e conferma il download.
2. Apri `lulu.apk` dalla notifica o dalla cartella Download. Android chiede di consentire
   l'installazione da quella app (Chrome, File…): consenti, poi **Installa**.
3. Al primo avvio:
   - aggiungi il tuo cane;
   - alla domanda sulle notifiche rispondi **Attiva** e poi **Consenti**;
   - se compare la richiesta «Sveglie e promemoria», attivala: serve a far arrivare le dosi all'orario
     esatto.

Gli aggiornamenti si installano allo stesso modo, sopra la versione precedente, e i dati restano
(purché l'APK sia firmato sempre con la stessa chiave: vedi `LULU-WEB-REPORT.md`).

Per chi sviluppa: l'APK di ogni rilascio è anche allegato alla GitHub Release del tag `v*`
(workflow `.github/workflows/release.yml`) e, per ogni commit su `main`, tra gli artifact del
workflow **Android** (`lulu-android`).

## iPhone e iPad: web app sulla schermata Home

Lulù su iPhone non passa dall'App Store: si usa da Safari come web app installabile.

1. Apri l'indirizzo della web app con **Safari**.
2. Tocca **Condividi** (il quadrato con la freccia in su) › **Aggiungi alla schermata Home** › **Aggiungi**.
3. Da ora aprila dall'icona: si apre a schermo intero e funziona anche senza rete.

Limiti su iPhone: niente notifiche (promemoria e allarmi si vedono aprendo l'app); i dati stanno
nel browser, quindi va aggiunta alla schermata Home, altrimenti Safari può cancellarli dopo
qualche settimana senza uso.

## Web app: build e pubblicazione

```bash
tool/build_web.sh                        # sito alla radice del dominio
BASE_HREF=/lulu/ tool/build_web.sh       # sito in una sottocartella
APK=lulu.apk tool/build_web.sh           # mette anche l'APK nella pagina di download
```

Il risultato in `build/web` va caricato così com'è su un hosting statico qualsiasi (HTTPS
obbligatorio per l'installazione e l'uso offline).

## Cosa sapere

- La previsione della pipì usa l'intervallo abituale del tuo cane e i suoi orari. Nei primi giorni usa
  valori tipici per età e taglia, poi si adatta. È una stima: se il cane chiede di uscire, ascolta lui.
- Allarmi, dosi e vaccini funzionano solo con le notifiche attive. Se sono spente, la schermata Oggi lo
  dice e propone **Attiva**.
- L'app non sostituisce il veterinario. In caso di dubbio, chiamalo. Il pulsante rosso **Emergenze** è
  sempre in alto.
