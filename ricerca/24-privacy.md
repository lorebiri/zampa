# 24 — Privacy e GDPR per la beta

Incarico C2-7 di `ricerca/08-piano-ceo.md` §11.5. Data: 11 novembre 2026.
Autore: esperto privacy e GDPR del progetto.

**In breve:** Zampa è un'app a basso rischio per la privacy. Senza account non riceviamo
nulla, e con l'account i dati stanno a Francoforte. I dati sanitari del cane non sono
dati sanitari ai sensi del GDPR. Però orari delle uscite e città dicono quando la casa è
vuota, quindi li trattiamo con cura. La DPIA non è obbligatoria e l'abbiamo fatta lo
stesso: tutti i rischi residui sono bassi, a patto di chiudere **A1 e A2** di
`ricerca/11` prima di aprire gli account al pubblico. Lo studio sull'accuratezza e i
rapporti di errore partono **solo con consenso**, con due interruttori separati e spenti
di serie. Per i crash scelgo **Sentry con regione UE**.

Per B7: **bozza rivista consegnata**. Mancano i dati di Lorenzo, i dati che si leggono
solo dopo la creazione del progetto Supabase e la lettura di un legale.

## 1. File consegnati

| File | Cosa contiene |
|---|---|
| `docs/PRIVACY.md` | informativa per la beta (sostituisce la bozza): cosa resta sul telefono, account su Supabase a Francoforte, Open-Meteo, studio e crash facoltativi, destinatari, conservazione, diritti, età minima, contatti con segnaposto `[[ ]]` |
| `docs/CONSENSO-TELEMETRIA.md` | regole per lo sviluppatore e testi del consenso, a due livelli: studio sull'accuratezza e rapporti di errore, testo per Profilo › Privacy, messaggio al ritiro |
| `docs/REGISTRO-TRATTAMENTI.md` | registro art. 30: T1 account, T2 accesso e sicurezza, T3 meteo, T4 studio, T5 crash, T6 richieste; trattamenti esclusi; registro delle violazioni vuoto |
| `docs/DPIA.md` | DPIA leggera: criteri WP248, cosa i dati del cane rivelano della persona, 12 rischi con misure, condizioni per aprire gli account |
| `docs/CRASH-STRUMENTO.md` | confronto Sentry UE, GlitchTip, Crashlytics, tabella propria; impostazioni obbligatorie per Lorenzo e per il codice |
| `docs/DPA-SUPABASE-CHECKLIST.md` | checklist del DPA di Supabase |

## 2. Cosa viene davvero trattato (dal codice, 11/11/2026)

Ho letto `lib/sync/supabase_backend.dart`, `lib/ui/account_screen.dart`,
`lib/logic/weather.dart`, `lib/models.dart` e `lib/store.dart`.

- **Sul server, con l'account:** tutto l'oggetto `Dog`, cioè anche microchip, nome e
  telefono del veterinario, telefono di emergenza, città e coordinate del comune. Poi
  diario, cartella, peso, dosi, calori, qualità di vita ed esami, con data e ora.
  Inoltre `updated_by` (chi ha scritto). Il cane di esempio è escluso (A1 risolta in
  `syncItems`).
- **Solo sul telefono:** le foto (sul server va solo `photoId`), le notifiche (locali), le
  previsioni.
- **Open-Meteo:** il nome della città (geocodifica) e poi le coordinate del comune.
  Niente GPS, niente permesso di posizione. La richiesta parte dal telefono, quindi
  Open-Meteo vede anche l'IP.
- **Accesso:** email con codice, Apple, Google. Le email sono inviate dal servizio di
  Supabase, o da un SMTP proprio se Lorenzo lo configura.
- **Non c'è ancora:** telemetria, crash, schermata Profilo › Privacy (C2-6).

## 3. Scelte principali e motivi

1. **Basi giuridiche.** Contratto per account, sincronizzazione e avviso caldo; consenso
   per studio e crash; legittimo interesse solo per la sicurezza.
2. **Dati del cane ≠ dati sanitari.** L'art. 9 non si applica, ma la DPIA tratta le
   abitudini come il dato più delicato. Il rischio vero è "quando la casa è vuota", non
   la salute del cane.
3. **Crash con consenso**, anche se c'è chi sostiene che si possa farne a meno: le linee
   guida EDPB 2/2023 leggono in modo ampio l'art. 5.3 ePrivacy, e la CNIL chiede il
   consenso per tutto ciò che non è necessario. In una beta costa poco.
4. **Sentry UE** invece di GlitchTip: nessun server da mantenere per una persona sola;
   eventi a Francoforte; negli USA solo i dati dell'account dello sviluppatore. Lo stesso
   SDK funziona con GlitchTip, se un giorno servirà.
5. **Open-Meteo come titolare autonomo**, senza DPA: è un servizio pubblico svizzero
   (Paese adeguato). Riceve solo città, coordinate e IP. Le sue condizioni gratuite
   valgono per uso **non commerciale**: Zampa gratuita e senza pubblicità ci rientra.
   Se un giorno ci sarà un abbonamento, serve il piano a pagamento.
6. **Registro tenuto** perché il trattamento non è occasionale (art. 30.5).
7. **Età minima 14 anni** per account e consensi (art. 2-quinquies Codice privacy).

## 4. Requisiti degli store

### Apple (App Store)

- **Informativa obbligatoria** e link nell'app e nella scheda (linea guida 5.1.1).
- **Eliminazione dell'account dall'app** (5.1.1(v)): c'è già, in Account e famiglia ›
  Elimina account.
- **"Etichette" della privacy** (App Privacy in App Store Connect). Proposta:
  - dati collegati all'utente, con l'account: **Contatti › Email** e **Identificativi ›
    ID utente**;
  - il diario del cane va in **Contenuti dell'utente › Altri contenuti**, non in
    **Salute e fitness**, che per Apple riguarda la salute della persona;
  - **Posizione approssimativa**: sì, se si attiva l'avviso caldo (la città è salvata
    nell'account);
  - **Diagnostica › Dati sugli arresti anomali**, non collegata all'utente, solo con
    consenso;
  - **Utilizzo › Altri dati di utilizzo** per lo studio, non collegati all'utente;
  - nessun tracciamento, quindi **nessuna richiesta ATT**.
- **Manifest della privacy** (`PrivacyInfo.xcprivacy`): **non c'è** in `ios/Runner`.
  `shared_preferences` usa `UserDefaults`, che è una API "con motivo obbligatorio". I
  plugin Flutter recenti portano il loro manifest, ma va controllato con Xcode › Product ›
  Privacy Report prima dell'invio (richiesta allo sviluppatore, R-P2).

### Google Play

- **Sicurezza dei dati** (Data safety), obbligatoria anche per chi non raccoglie nulla.
  "Raccolta" vuol dire dati che lasciano il telefono, anche tramite SDK. Proposta:

| Tipo di dato (Play) | Raccolto | Condiviso | Facoltativo | Scopo |
|---|---|---|---|---|
| Informazioni personali › Indirizzo email | sì | no | sì (account facoltativo) | gestione dell'account |
| Informazioni personali › ID utente | sì | no | sì | gestione dell'account |
| Posizione › Posizione approssimativa | sì (città, se avviso caldo e account) | no¹ | sì | funzionalità dell'app |
| Salute e fitness › Informazioni sanitarie | prudente dichiararlo: sì² | no | sì | funzionalità dell'app |
| Attività nelle app › Altri contenuti generati dagli utenti | sì (diario) | no | sì | funzionalità dell'app |
| Informazioni e prestazioni app › Log degli arresti anomali, Diagnostica | sì, solo con consenso | no | sì | analisi |
| Foto e video | **no** (restano sul telefono) | no | — | — |

¹ Supabase, Sentry e Open-Meteo lavorano per l'app o su richiesta dell'utente: per Play
non è "condivisione". Open-Meteo rientra nel trasferimento avviato dall'utente.
² Play parla di sintomi e cartelle cliniche senza dire "umane". Dichiararlo non costa
nulla e evita contestazioni.

  - **Cifratura in transito: sì** (tutto HTTPS).
  - **Eliminazione:** oltre al percorso nell'app, Play chiede un **link web** dove
    chiedere la cancellazione **senza accedere all'app**. Serve una pagina, anche
    semplice, o almeno un indirizzo email pubblicato su una pagina web (azione di Lorenzo).
- **Informativa** con un URL pubblico, che non sia un PDF da scaricare.

## 5. Richieste allo sviluppatore principale (per C2-6)

| # | Pri. | Richiesta |
|---|---|---|
| R-P1 | P1 | Schermata **Profilo › Privacy**: link all'informativa, interruttori "Studio" e "Rapporti di errore" (spenti di serie), stato dei consensi, data e versione del testo salvate sul telefono |
| R-P2 | P1 | `PrivacyInfo.xcprivacy` in `ios/Runner` (o verifica che i plugin lo forniscano), con i motivi per `UserDefaults` |
| R-P3 | P1 | Sentry con le impostazioni di `docs/CRASH-STRUMENTO.md`, inizializzato **solo** dopo il consenso |
| R-P4 | P1 | Domanda sull'età (≥ 14 anni) prima di account e consensi |
| R-P5 | P2 | Backup JSON: salvare su file con il foglio di condivisione invece degli appunti (DPIA R8) |
| R-P6 | P2 | Elenco dei familiari visibile al proprietario, con "Togli" (DPIA R3, `ricerca/11` A12) |
| R-P7 | P0 (già nota) | A2 di `ricerca/11` prima di aprire gli account a chi non è un beta tester noto |

## 6. Azioni per Lorenzo

| # | Entro | Azione |
|---|---|---|
| 1 | Prima della beta | **Completare i segnaposto** di `docs/PRIVACY.md` e `docs/REGISTRO-TRATTAMENTI.md`: indirizzo e una **email privacy dedicata** (non del CNR). Se non vuoi pubblicare l'indirizzo di casa, valuta un domicilio digitale (PEC) o una casella postale: chiedi al legale se basta |
| 2 | Alla creazione del progetto Supabase | Seguire `docs/DPA-SUPABASE-CHECKLIST.md`: regione Francoforte, DPA scaricato e conservato, iscrizione agli avvisi sui sub-responsabili, poi completare l'informativa con sub-responsabili e tempi di backup |
| 3 | Prima di attivare i crash | Creare l'organizzazione **Sentry con regione UE** (non si cambia dopo), verifica in due passaggi, "Prevent Storing of IP Addresses", regola che toglie la posizione ricavata dall'IP |
| 4 | Prima di pubblicare sugli store | **Pagina web pubblica** con l'informativa e con le istruzioni per chiedere la cancellazione senza accedere all'app (richiesta di Google Play). Può stare sul dominio scelto dopo il nome (B10) |
| 5 | Prima del lancio pubblico | Far leggere informativa e DPIA a un **legale** (anche in un'unica consulenza insieme ai temi di `ricerca/14`). Poi firmare la DPIA (sezione 7) |

**Nota:** se il CNR risponde all'email di `ricerca/14` rivendicando i diritti sull'app,
potrebbe cambiare anche il **titolare del trattamento**. In quel caso informativa e
registro vanno rifatti prima della beta pubblica.

## 7. Cosa non è stato fatto

- Nessuna verifica legale umana: i testi sono una bozza rivista, non un parere.
- Condizioni d'uso (anche loro in B7): non erano in questo incarico. Servono prima
  della pubblicazione negli store, con l'avvertenza "non è un dispositivo medico".
- Lancio in UE: per ora i testi sono solo in italiano. Gli altri Paesi richiedono
  traduzioni e l'indicazione della loro autorità di controllo.
- Nessuna prova dell'endpoint di telemetria: arriva con C2-6.

## 8. Fonti

Normativa e autorità:
- Regolamento (UE) 2016/679 (GDPR), artt. 4, 5, 6, 7, 8, 9, 12-22, 25, 28, 30, 33-37,
  44-46: https://eur-lex.europa.eu/eli/reg/2016/679/oj
- Codice privacy (d.lgs. 196/2003 come modificato dal d.lgs. 101/2018), art. 2-quinquies
  (età di 14 anni) e art. 122 (accesso al dispositivo).
- Garante privacy, *FAQ sul registro delle attività di trattamento* (2018) e modelli
  semplificati per le PMI: https://www.garanteprivacy.it (sezione Registro); sintesi:
  https://www.assolombarda.it/servizi/privacy/gdpr-le-istruzioni-del-garante-privacy-sul-registro-dei-trattamenti
- Garante privacy, provv. n. 467 dell'11/10/2018, elenco dei trattamenti soggetti a
  DPIA (G.U. n. 269 del 19/11/2018), doc. web n. 9058979:
  https://www.dirittobancario.it/wp-content/uploads/sites/default/files/allegati/delibera_garante_per_la_protezione_dei_dati_personali_11_ottobre_2018_n._467.pdf
- Gruppo Art. 29 / EDPB, *Linee guida WP248 rev.01 sulla DPIA*.
- EDPB, *Linee guida 05/2020 sul consenso*.
- EDPB, *Linee guida 2/2023 sull'ambito tecnico dell'art. 5.3 ePrivacy*, v2.0 del 7/10/2024:
  https://edpb.europa.eu/system/files/2024-10/edpb_guidelines_202302_technical_scope_art_53_eprivacydirective_v2_en_0.pdf
- EDPB, *Linee guida 01/2025 sulla pseudonimizzazione* (i dati pseudonimi restano personali):
  https://edpb.europa.eu/news/news/2025/edpb-adopts-pseudonymisation-guidelines-and-paves-way-improve-cooperation_en
- CNIL, raccomandazioni sulle applicazioni mobili (settembre 2024, aggiornate ad aprile 2025):
  https://www.cnil.fr/en/mobile-applications-cnil-publishes-its-recommendations-better-privacy-protection

Store:
- Apple, *App Review Guidelines*, 5.1.1: https://developer.apple.com/app-store/review/guidelines/
- Apple, eliminazione dell'account: https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion
- Apple, *App privacy details*: https://developer.apple.com/app-store/app-privacy-details/
- Apple, *Privacy manifest files*: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- Google Play, *Sicurezza dei dati*: https://support.google.com/googleplay/android-developer/answer/10787469
- Google Play, eliminazione dell'account: https://support.google.com/googleplay/android-developer/answer/13327111

Fornitori:
- Supabase, DPA v1 del 1/8/2026: https://supabase.com/legal/dpa
- Supabase, elenco dei sub-responsabili (1/6/2026): https://supabase.com/legal/subprocessor-list/June-1-2026.pdf
- Open-Meteo, *Terms & Privacy*: https://open-meteo.com/en/terms
- Sentry, *Data Storage Location*: https://docs.sentry.io/organization/data-storage-location/
- Sentry, *Data collected* (Flutter): https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
- Sentry, *GDPR e DPF*: https://sentry.io/trust/privacy/gdpr-best-practices/
