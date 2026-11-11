# Registro delle attività di trattamento (art. 30 GDPR)

> **Stato:** versione 1, beta, 11/11/2026 (C2-7). Va aggiornato a ogni nuova funzione
> che tratta dati e riletto almeno una volta l'anno. Conservarlo anche in PDF datato.

**Perché lo teniamo.** Sotto i 250 dipendenti il registro è obbligatorio se il
trattamento **non è occasionale** (art. 30.5 GDPR). Un'app con account che sincronizza
ogni giorno non è occasionale, quindi lo teniamo. Il Garante lo consiglia comunque come
strumento di responsabilizzazione (FAQ sul registro, 2018). Il modello segue lo schema
semplificato del Garante per le PMI.

## Dati del titolare

| Voce | Valore |
|---|---|
| Titolare | Lorenzo Birindelli, persona fisica |
| Indirizzo | `[[via, numero civico, CAP, città]]` |
| Contatto privacy | `[[email privacy]]` |
| Rappresentante nell'UE (art. 27) | non serve: il titolare è in UE |
| DPO (art. 37) | non nominato, non obbligatorio (nessun monitoraggio su larga scala, nessun dato degli artt. 9-10 come attività principale) |
| Contitolari | nessuno |

## Trattamenti

### T1. Account e sincronizzazione

| Voce | Contenuto |
|---|---|
| Finalità | backup, uso su più dispositivi, condivisione del cane con i familiari |
| Base giuridica | contratto (art. 6.1.b) |
| Interessati | utenti con account; familiari invitati; terzi indicati dall'utente (veterinario, contatto di emergenza) |
| Categorie di dati | email; id dell'account e del fornitore di accesso (Apple, Google); dati del cane (anagrafica, microchip, salute, alimentazione, città e coordinate del comune); diario con data e ora; cartella sanitaria, farmaci e dosi; nome e telefono del veterinario e di emergenza; autore e orario di ogni modifica |
| Dati particolari (art. 9) | **no**: i dati sanitari riguardano il cane. Possibili deduzioni sulla persona (abitudini, presenza in casa): valutate nella DPIA |
| Destinatari | Supabase, Inc. (responsabile, art. 28); sub-responsabili di Supabase (es. invio email); familiari invitati dall'utente; Apple e Google come titolari autonomi per l'accesso |
| Trasferimenti extra UE | dati ospitati a Francoforte; possibili accessi dagli USA da parte di Supabase (assistenza, sub-responsabili): clausole contrattuali standard, modulo 2, incluse nel DPA |
| Conservazione | fino all'eliminazione dell'account (cancellazione immediata nel database); backup del fornitore `[[N giorni]]`; lapidi senza contenuto finché esiste il cane |
| Misure di sicurezza | TLS; cifratura a riposo del fornitore (AES-256); Row Level Security provata con 79 test (`ricerca/11`); inviti monouso a 7 giorni; limite a 5 tentativi falliti l'ora; funzioni `security definer` con `search_path` vuoto; nessuna chiave segreta nell'app; regione UE; eliminazione dell'account dall'app |

### T2. Accesso e sicurezza dell'account

| Voce | Contenuto |
|---|---|
| Finalità | autenticazione con codice via email, Apple o Google; prevenzione degli abusi |
| Base giuridica | contratto (art. 6.1.b); legittimo interesse alla sicurezza (art. 6.1.f) |
| Interessati | utenti con account |
| Categorie di dati | email; codice monouso; indirizzo IP e user agent nei registri di Supabase Auth e API; tentativi falliti di invito |
| Destinatari | Supabase; fornitore dell'email (sub-responsabile di Supabase, oppure SMTP proprio `[[nome]]`) |
| Trasferimenti extra UE | come T1; verificare dove ha sede il servizio email |
| Conservazione | registri: secondo il piano Supabase `[[giorni]]`; tentativi: circa 1 giorno |
| Misure | limiti di invio delle email; CAPTCHA (quando l'app lo supporta); accesso con password disattivato; protezione da password compromesse |

### T3. Avviso caldo (meteo)

| Voce | Contenuto |
|---|---|
| Finalità | avvisare se all'ora della prossima uscita fa troppo caldo o troppo freddo |
| Base giuridica | contratto: funzione attivata dall'utente (art. 6.1.b) |
| Interessati | utenti che attivano l'avviso |
| Categorie di dati | nome della città scritto dall'utente; coordinate del comune; indirizzo IP del telefono |
| Destinatari | OpenMeteo GmbH (Svizzera), che riceve le richieste direttamente dal telefono |
| Ruolo di Open-Meteo | servizio pubblico con proprie condizioni: lo trattiamo come **titolare autonomo** per i suoi registri. Non c'è un DPA. Rischio basso perché non riceve né email né id né dati del cane |
| Trasferimenti extra UE | Svizzera: decisione di adeguatezza della Commissione |
| Conservazione | registri di Open-Meteo: 90 giorni (sue condizioni); la città resta nei dati del cane (T1) |
| Misure | si invia la città, non la posizione GPS; nessun altro dato; funzione spenta di serie |

### T4. Studio sull'accuratezza (telemetria)

| Voce | Contenuto |
|---|---|
| Finalità | valutare l'accuratezza della previsione (`ricerca/12` §5) |
| Base giuridica | **consenso** separato e revocabile (art. 6.1.a); per la lettura e scrittura sul telefono, art. 122 del Codice privacy (art. 5.3 della direttiva ePrivacy) |
| Interessati | utenti che hanno acconsentito |
| Categorie di dati | dati pseudonimi: `pid` casuale per cane; metriche di errore arrotondate; fasce del cane; versione dell'app e del testo di consenso. Nessun orario, data, posizione, nome o testo libero |
| Destinatari | Supabase (responsabile), tabella separata dallo schema dell'app; data scientist e Capo Progetto del progetto, solo lettura dei cruscotti |
| Trasferimenti extra UE | come T1 |
| Conservazione | fino a 12 mesi dopo la chiusura della beta; poi solo aggregati con celle ≥ 5 cani; cancellazione entro 30 giorni dal ritiro |
| Misure | endpoint senza account; IP non salvato nella tabella; registri di rete ≤ 7 giorni; limite di frequenza per `pid`; nessun SDK di terzi |

### T5. Rapporti di errore (crash)

| Voce | Contenuto |
|---|---|
| Finalità | trovare e correggere i difetti dell'app |
| Base giuridica | **consenso** separato (art. 6.1.a) |
| Interessati | utenti che hanno acconsentito |
| Categorie di dati | traccia dello stack; versione dell'app; modello e sistema del telefono; id casuale dell'installazione generato dall'SDK; nessun IP (`sendDefaultPii = false` e salvataggio dell'IP disattivato sul server), nessuna schermata |
| Destinatari | Functional Software, Inc. (Sentry), responsabile del trattamento |
| Trasferimenti extra UE | eventi salvati a Francoforte; dati dell'organizzazione Sentry (account dello sviluppatore, impostazioni) negli USA; clausole contrattuali standard del DPA di Sentry |
| Conservazione | al massimo 90 giorni |
| Misure | vedi `docs/CRASH-STRUMENTO.md` |

### T6. Richieste degli interessati e assistenza

| Voce | Contenuto |
|---|---|
| Finalità | rispondere a richieste di accesso, cancellazione, domande |
| Base giuridica | obbligo di legge (art. 6.1.c, artt. 12-22) |
| Categorie di dati | email e contenuto della richiesta |
| Destinatari | fornitore della casella email `[[nome]]` |
| Conservazione | 2 anni dalla chiusura della richiesta, per poter dimostrare la risposta |
| Misure | casella dedicata al progetto, non quella del CNR |

## Trattamenti esclusi

- **Dati solo sul telefono** senza account: il titolare non li riceve e non li tratta.
  Restano comunque soggetti alla protezione fin dalla progettazione (art. 25) perché
  dipendono da come è fatta l'app.
- **Notifiche**: locali, nessun server di notifiche push.
- **Foto**: restano sul telefono; sul server va solo il loro id.
- **Pubblicità, analisi di marketing, profilazione**: nessuna.

## Registro delle violazioni (art. 33.5)

Anche se non ci sono violazioni, tenere qui l'elenco. Per ogni violazione: data, cosa è
successo, dati e persone coinvolte, conseguenze, misure prese, se è stata notificata al
Garante (entro 72 ore, se c'è un rischio) e agli interessati (se il rischio è elevato).

| Data | Descrizione | Dati e interessati | Notifica Garante | Notifica utenti | Misure |
|---|---|---|---|---|---|
| — | nessuna | — | — | — | — |
