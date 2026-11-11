# Installare Zampa sul telefono

Zampa è gratuita e funziona senza account: i dati restano sul telefono.

## Android (qualsiasi telefono Android 7 o più recente)

1. Apri la pagina delle compilazioni:
   <https://github.com/lorebiri/zampa/actions/workflows/android.yml>
2. Apri l'ultima riga con la spunta verde. In fondo, sotto **Artifacts**, scarica **zampa-android**
   (serve essere entrati su GitHub).
3. Dentro lo zip c'è `zampa.apk`: copialo sul telefono, per esempio mandandolo a te stesso via mail o
   Telegram, oppure scaricandolo direttamente dal telefono.
4. Apri `zampa.apk` sul telefono. Android chiede di consentire l'installazione da quella app (Chrome,
   File, Telegram…): consenti, poi **Installa**.
5. Al primo avvio:
   - aggiungi il tuo cane;
   - alla domanda sulle notifiche rispondi **Attiva** e poi **Consenti**;
   - se compare la richiesta «Sveglie e promemoria», attivala: serve a far arrivare le dosi all'orario
     esatto.

Gli aggiornamenti si installano allo stesso modo, sopra la versione precedente, e i dati restano.

## iPhone

Senza account Apple Developer a pagamento l'app si installa dal Mac con Xcode e il tuo Apple ID
gratuito. Va reinstallata ogni 7 giorni, e i dati restano.

1. Collega l'iPhone al Mac con il cavo e sblocca il telefono. Se chiede «Considerare attendibile
   questo computer?», rispondi **Sì**.
2. Sull'iPhone attiva **Impostazioni › Privacy e sicurezza › Modalità sviluppatore**: il telefono si
   riavvia.
3. Apri `ios/Runner.xcworkspace` con Xcode.
   - Vai su **Xcode › Settings › Accounts › +** ed entra con il tuo Apple ID.
   - Seleziona **Runner › Signing & Capabilities › Team**, poi scegli il tuo nome (Personal Team).
   - Se Xcode dice che l'identificativo `it.zampa.zampa` è già usato, cambialo in qualcosa di tuo,
     per esempio `it.lorenzo.zampa`.
4. Da Terminale, nella cartella del progetto:
   ```bash
   flutter run --release
   ```
   Se ci sono più dispositivi, scegli l'iPhone.
5. Al primo avvio l'iPhone può dire «Sviluppatore non attendibile». Vai su
   **Impostazioni › Generali › VPN e gestione dispositivi**, tocca il tuo Apple ID e poi **Autorizza**.

## Cosa sapere

- La previsione della pipì usa l'intervallo abituale del tuo cane e i suoi orari. Nei primi giorni usa
  valori tipici per età e taglia, poi si adatta. È una stima: se il cane chiede di uscire, ascolta lui.
- Allarmi, dosi e vaccini funzionano solo con le notifiche attive. Se sono spente, la schermata Oggi lo
  dice e propone **Attiva**.
- L'app non sostituisce il veterinario. In caso di dubbio, chiamalo. Il pulsante rosso **Emergenze** è
  sempre in alto.
