# Strumento per i rapporti di errore (crash): scelta motivata

> C2-7, 11/11/2026. Serve a C2-6 (sviluppatore principale), che integra lo strumento.
> Dati verificati sulle pagine ufficiali l'11/11/2026; i punti segnati [da verificare]
> vanno ricontrollati al momento dell'iscrizione.

## Decisione

**Sentry in versione SaaS con regione UE (Francoforte, `de.sentry.io`), piano gratuito
Developer, con l'SDK ufficiale `sentry_flutter`, attivo solo con consenso.**

Alternativa pronta: **GlitchTip self-hosted** su un server in UE. Usa lo stesso SDK,
quindi per cambiare basta sostituire il DSN, senza toccare il codice.

## Requisiti

1. Dati degli errori conservati in UE.
2. Crash nativi (iOS e Android) e non solo errori Dart, con simboli leggibili.
3. Gratuito o quasi, nel tetto di spesa del progetto.
4. Nessun lavoro di manutenzione di server per Lorenzo, che è da solo.
5. Si può configurare per non mandare dati personali (niente IP, niente schermate).
6. DPA disponibile e garanzie per il trasferimento.

## Confronto

| Opzione | Dati in UE | Crash nativi | Costo | Manutenzione | Note privacy | Esito |
|---|---|---|---|---|---|---|
| **Sentry SaaS, regione UE** | eventi, rilasci, simboli e loro backup a Francoforte. Account, impostazioni, chiavi DSN, log di audit negli USA | sì, con caricamento dei simboli | piano gratuito Developer, stesso prezzo delle regioni USA | nessuna | di serie l'SDK Flutter **non** manda IP, utente, nome del dispositivo; il server può non salvare l'IP; Sentry è certificata DPF e ha un DPA | **scelta** |
| GlitchTip self-hosted (es. VPS in Germania) | tutto dove decidi tu | sì per gli eventi; i simboli con il flusso "artifact bundle" non sono supportati, solo il vecchio caricamento per rilascio | circa 5 €/mese di server | aggiornamenti, backup, sicurezza del server: un server dimenticato è un rischio in sé | massimo controllo, nessun fornitore USA; il fornitore del server diventa responsabile (DPA del provider) | alternativa |
| Firebase Crashlytics | no: nessuna regione UE per Crashlytics | sì | gratuito | nessuna | Google come responsabile, dati negli USA; porta dentro anche gli SDK Firebase | scartato |
| Tabella "errori" sul nostro Supabase | sì, stesso progetto di Francoforte | **no**: solo errori Dart, niente crash nativi né simboli | gratuito | poca | nessun fornitore nuovo | utile come ripiego se Lorenzo non vuole altri fornitori |

**Perché Sentry e non GlitchTip:** per un progetto con una sola persona, un server da
mantenere è il rischio maggiore (aggiornamenti di sicurezza, backup). Gli eventi di
Sentry restano a Francoforte; negli USA restano solo i dati dell'**account dello
sviluppatore** (Lorenzo) e la configurazione, non i dati degli utenti dell'app. Con le
impostazioni qui sotto i rapporti non contengono dati identificativi.

**Quando passare a GlitchTip:** se un legale o il Capo Progetto chiedono zero fornitori
USA, o se il piano gratuito di Sentry non basta più.

## Impostazioni obbligatorie

### Iscrizione (Lorenzo)

1. Creare l'organizzazione Sentry scegliendo **Data Storage Location: European Union
   (Germany)**. **Non si cambia dopo**: se si sbaglia, bisogna creare un'organizzazione nuova.
2. Usare il DSN che punta a `*.de.sentry.io` (o `ingest.de.sentry.io`).
3. Attivare la verifica in due passaggi sull'account Sentry.
4. Salvare una copia del DPA di Sentry (`sentry.io/legal/dpa`) con la data. [da verificare
   se si accetta con le condizioni d'uso o va firmato]
5. In **Settings › Security & Privacy**:
   - attivare **Prevent Storing of IP Addresses**;
   - attivare **Data Scrubber** e **Use Default Scrubbers**;
   - aggiungere una regola di **Advanced Data Scrubbing** che rimuove `$user.geo` (Sentry
     ricava la posizione approssimativa dall'IP anche quando l'IP non viene salvato);
   - impostare la conservazione degli eventi al minimo disponibile, massimo 90 giorni.
6. Nessuna integrazione con altri servizi (Slack, GitHub...) che copi i rapporti fuori
   dall'UE, salvo decisione esplicita.

### Nel codice (sviluppatore, C2-6; nomi delle opzioni da verificare sulla versione dell'SDK)

```dart
// Solo se l'utente ha acceso "Rapporti di errore" (docs/CONSENSO-TELEMETRIA.md).
await SentryFlutter.init((o) {
  o.dsn = const String.fromEnvironment('SENTRY_DSN'); // dominio de.sentry.io
  o.sendDefaultPii = false;          // niente IP, utente, nome del dispositivo
  o.attachScreenshot = false;        // niente schermate
  o.attachViewHierarchy = false;     // niente testi dell'interfaccia
  o.tracesSampleRate = 0;            // niente misure di prestazioni
  o.enableAutoSessionTracking = false; // niente sessioni legate all'installazione
  o.maxRequestBodySize = MaxRequestBodySize.never;
  o.beforeSend = (event, hint) => scrub(event); // toglie messaggi con testo utente e URL con parametri
});
```

- **Niente Session Replay** e niente `setUser`.
- Le briciole (breadcrumbs) di navigazione e HTTP vanno **filtrate**: tenere solo il tipo
  di evento, togliere URL completi di Supabase e Open-Meteo (contengono la città nei
  parametri) e i testi.
- Il nome del cane non deve finire nei messaggi d'errore: usare id, non nomi.
- Se l'utente spegne l'interruttore: `Sentry.close()` e nessun invio alla partenza
  successiva.
- La chiave DSN si passa a compilazione come le chiavi di Supabase; non è segreta, ma
  non va scritta nel codice.
- Aggiungere Sentry al manifest della privacy di iOS (`PrivacyInfo.xcprivacy`, se l'SDK
  non lo porta già) e alla scheda "Sicurezza dei dati" di Google Play come "Arresti
  anomali" e "Diagnostica", **facoltativi**, non condivisi, cifrati in transito.

## Base giuridica

Il consenso (art. 6.1.a GDPR), con un interruttore separato da quello dello studio.

C'è chi sostiene che i rapporti di errore rientrino nell'eccezione "strettamente
necessario" dell'art. 5.3 della direttiva ePrivacy (art. 122 del Codice privacy) e nel
legittimo interesse. Le linee guida EDPB 2/2023 interpretano in modo ampio cosa conta
come accesso al dispositivo, e la CNIL chiede il consenso per tutto ciò che non serve al
funzionamento richiesto dall'utente. Per una beta con pochi utenti, il consenso costa
poco e toglie ogni dubbio: è la scelta prudente. Si può rivedere al lancio.

## Fonti

- Sentry, *Data Storage Location (US or EU)*: https://docs.sentry.io/organization/data-storage-location/
- Sentry, *Choose your data center*: https://docs.sentry.io/product/accounts/choose-your-data-center/
- Sentry, *Data collected* (Flutter): https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
- Sentry, *Server-side data scrubbing*: https://docs.sentry.io/security-legal-pii/scrubbing/server-side-scrubbing/
- Sentry, *GDPR best practices* e DPF: https://sentry.io/trust/privacy/gdpr-best-practices/
- GlitchTip vs Sentry (compatibilità dell'SDK): https://dev.to/selfhostingsh/glitchtip-vs-sentry-206o
- EDPB, Linee guida 2/2023 sull'ambito tecnico dell'art. 5.3 ePrivacy, v2.0 del 7/10/2024: https://edpb.europa.eu/system/files/2024-10/edpb_guidelines_202302_technical_scope_art_53_eprivacydirective_v2_en_0.pdf
- CNIL, raccomandazioni sulle applicazioni mobili (2024, aggiornate nel 2025): https://www.cnil.fr/en/mobile-applications-cnil-publishes-its-recommendations-better-privacy-protection
