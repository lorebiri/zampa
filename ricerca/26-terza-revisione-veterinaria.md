# 26 — Terza revisione veterinaria

*11 novembre 2026. Revisore: agente veterinario del progetto (medicina interna del cane, comportamento eliminatorio), autore di `ricerca/06` e `ricerca/07`. Questa revisione non sostituisce la firma del veterinario abilitato prevista per la v1.0-rc (B5). Ho lavorato in sola lettura sul codice del branch `main`, commit `446d8ed`. Le citazioni con PMID e DOI vengono da PubMed; le linee guida non indicizzate le ho cercate con Consensus.*

Ho letto: `ricerca/06`, `07`, `08` §11, `12`, `15`; `lib/logic/potty_predictor.dart`, `elimination_model.dart` (`forecast`), `bio_params.dart` (`modifier`), `alerts.dart` (parti citate), `lib/store.dart` (`planNotifications`, `pendingDoses`, `confirmDose`, `_reschedule`), `lib/notifications.dart` (`schedule`), `lib/ui/home_screen.dart` (`_DoseCard`), `lib/ui/dog_wizard.dart`, `lib/logic/nutrition.dart` (`merFactor`), `lib/l10n/country_pack.dart`, `lib/l10n/app_it.arb` (voci citate), `docs/clinica/testi-clinici-v1.md`.

---

## 0. In sintesi

- **La previsione di base è l'impostazione giusta.** Intervallo personale, accorciamento rapido solo verso il più breve, orari abituali usati solo se cadono prima, tetti per età invariati. Rispetto al modello va nella direzione sicura e mantiene ciò che avevo chiesto in 06 §27-30 e 07 N8.
- **C'è un difetto clinico importante (A1-A2).** Il fattore biologico si applica una seconda volta a un intervallo che è già misurato sul cane. Dentro il fattore ci sono anche taglia piccola e cibo umido, che non sono condizioni cliniche. Il risultato:
  - un cane piccolo e sano riceve per sempre un intervallo più corto del 32%;
  - un diabetico con «cistite» nelle note riceve un promemoria ogni 20-30 minuti;
  - l'allarme per la poliuria diventa meno sensibile proprio nei cani piccoli.
- **v1.0-rc:** delle 5 proposte (più il CAV), nessuna è respinta.
  - VIA-004: approvata.
  - VIA-005, EMG-019, la frase d'azione «Chiama subito…» (6 avvisi) e ALR-URI-006: approvate con modifica (testi esatti al §3).
  - Il CAV di Milano solo per l'Italia: approvato con modifica.
- **Procedura guidata:** manca la domanda sulle **terapie in corso**, da cui dipendono 6 avvisi SUBITO e il fattore della pipì (A6). Il resto può aspettare (B).
- **«Saltato» con conferma:** approvato. Mancano un testo specifico per insulina e antiepilettici (A7) e la possibilità di annullare «Dato» (B).
- **Il «Piano consigliato di oggi» usa ancora il modello statistico** e non applica né la prudenza corretta né il tetto clinico (A10).
- **Correzioni:** 10 di priorità A, 11 di priorità B, 7 di priorità C (§7).

---

## 1. Previsione di base della pipì (`Baseline`, `FittedModel.forecast`)

### 1.1 Cosa va bene

| Elemento | Giudizio | Motivo |
|---|---|---|
| Mediana degli intervalli da sveglio, 14 giorni, almeno 4 intervalli, intervalli nel sonno esclusi | ✔ | È il dato più robusto che un proprietario può produrre. Escludere la notte evita che le 8-10 ore di sonno allunghino la stima |
| Esclusione degli intervalli oltre 1,5 × `maxDay` | ✔ | Toglie le giornate in cui il cane «la tiene» perché il proprietario è al lavoro. Sposta la mediana verso il breve, cioè nel verso prudente |
| Accorciamento a 3 giorni solo se < 85%, solo verso il basso | ✔ | Più prudente del 30% deciso dal CEO (08 §11.3). È il verso giusto per una poliuria che compare (diabete, Cushing, cortisonici, pielonefrite) |
| Orari abituali usati solo se anticipano | ✔ | Non possono mai ritardare l'uscita |
| Finestra 20°-80° «di solito tra X e Y», nessuna percentuale | ✔ | Onesta. Coerente con le frasi ammesse (08 §11.3) |
| Tetti per età, mai sotto 120 min di giorno e 180 di notte; notte dei cuccioli | ✔ invariati | Restano la vera rete di sicurezza e non dipendono da nessun modello |
| Cacca solo come orario abituale | ✔ | Corretto: la defecazione dipende da pasto ed esercizio più che dal tempo trascorso. Un orario puntuale sarebbe falsa precisione |
| Fattore biologico «solo verso il basso» | ✔ come principio, **✘ come è applicato** (§1.2) | |

### 1.2 Difetto A1: il fattore biologico si applica due volte all'intervallo misurato

`elimination_model.dart:980-986`:

```dart
final k = need == Need.pipi && bio.factor < 1 && base.nIntervals >= 4 && !base.adaptedRecent
    ? bio.factor : 1.0;
```

`bio.factor` (`bio_params.dart:215-318`) è il prodotto di tutti i fattori. Ci sono due problemi.

1. **Fattori costituzionali, non clinici.** Sono «taglia piccola» (0,85) e «cibo umido» (0,80 sotto i 10 kg). Valgono per tutta la vita del cane, quindi **sono già dentro la sua mediana dei 14 giorni**. Applicarli di nuovo a un intervallo misurato è un doppio conteggio.
2. **Malattie croniche scritte nel testo libero** (diabete 0,4, Cushing 0,5, renale 0,6, cistite 0,4). Anche queste, se il cane le ha da settimane, sono già nella mediana misurata. Il prodotto può arrivare al limite di 0,2.

**Esempi calcolati sul codice:**

| Cane | `bio.factor` | Intervallo misurato | Intervallo usato | Testo mostrato |
|---|---|---|---|---|
| Maltese 4 kg, adulto sano, cibo umido | 0,85 × 0,80 = **0,68** | 300 min | **204 min**, per sempre | «In base al suo intervallo abituale da sveglio (circa 5 h)», ma l'orario è calcolato su 3 h 24 min: testo e orario non tornano |
| Barboncino 6 kg diabetico in terapia, con «cistite» rimasta nelle note | 0,85 × 0,4 × 0,4 = 0,136 → **0,2** | 150 min (già poliurico) | **30 min**; promemoria a 20 minuti da ogni pipì | Promemoria continui, finché il proprietario non li spegne. Così perde anche il tetto di sicurezza |

Ci sono altre due conseguenze dello stesso fattore cumulativo.

- **Prudenza «Meno uscite» bloccata** per tutti i cani piccoli o a cibo umido (`bio.factor < 0.95`, `elimination_model.dart:957`). La regola di 06 §30 parlava di cani «sani», non di cani piccoli.
- **Tetto diurno accorciato** per i cani piccoli sani (480 × 0,68 = 326 min), con il testo «Con taglia piccola, cibo umido ha bisogno di uscire più spesso…» (`elimination_model.dart:1052-1054`). La frase suona come una diagnosi su un cane sano.

**Perché è un problema clinico e non solo di comodità.** Gli studi sull'aderenza ai promemoria (e la mia esperienza con i diari minzionali) dicono la stessa cosa: un promemoria che suona troppo spesso viene spento. Lo stesso canale porta il tetto di sicurezza e l'allarme «nessuna pipì». Il rischio vero è la perdita di fiducia, non l'uscita in più.

**Correzione (A1):**

1. `BioParams.modifier` restituisce due fattori:
   - `constitutional`: taglia, dieta;
   - `clinical`: calore, gravidanza, allattamento, malattie, farmaci.

   Oggi restituisce solo il prodotto.
2. **Senza dati** (`nIntervals < 4`): resta `prior.median × constitutional × clinical`, come oggi. Qui il fattore serve, perché non c'è nessuna misura.
3. **Con dati** (`nIntervals ≥ 4`): `k` comprende **solo i fattori clinici nuovi**:
   - farmaci con effetto sulla pipì iniziati da meno di 14 giorni (`r.date`);
   - la finestra dopo la dose di diuretico (che è un effetto di orario, non di livello);
   - mai le malattie scritte nel testo libero, che non hanno una data;
   - mai taglia e dieta.

   Limite inferiore: `k ≥ 0,5`.
4. **Tetti:** `dayCapMin = max(120, maxDay × clinical)` e `nightCapMin = max(180, maxNight × clinical)`. Taglia e dieta escluse.
5. **Prudenza «bassa»:** bloccata solo se `clinical < 0,95` (oltre a età e malattie, come oggi).
6. **Testo:** l'intervallo mostrato deve essere quello usato.
   - Attuale: «In base al suo intervallo abituale da sveglio (circa {base.intervalMin}).»
   - Proposto, se `k < 1`: «In base al suo intervallo abituale da sveglio, accorciato per {cause}: circa {intervalMin × k}.» `{cause}` = es. «la terapia con furosemide iniziata da poco».
7. **Test da aggiungere:**
   - cane piccolo sano a cibo umido con 14 giorni di dati → `k = 1`;
   - diabetico noto con 14 giorni di dati → `k = 1`;
   - furosemide iniziata 2 giorni fa → `k < 1`;
   - nessuna combinazione con `k < 0,5`.

### 1.3 Difetto A2: lo stesso fattore rende meno sensibile l'allarme della poliuria

`alerts.dart:367-369`:

```dart
final bioFactor = BioParams.modifier(Need.pipi, dog, records, now).factor;
final expectedRise = bioFactor < 0.8 ? 2.5 : 1.5;
```

Un cane piccolo a cibo umido (0,68) deve **più che raddoppiare e mezzo** le uscite prima che scatti «Fa pipì più spesso». Un cane medio deve aumentarle di una volta e mezza. La soglia più alta (06 §PU) era pensata per i cani **in terapia** con diuretici o cortisone, nei quali un aumento è atteso.

- **Proposto:** `final expectedRise = clinicalFactor < 0.8 ? 2.5 : 1.5;`, con lo stesso `clinical` di A1.

### 1.4 Testi della previsione (`reason`)

| Situazione | Testo attuale | Giudizio | Testo proposto |
|---|---|---|---|
| Meno di 4 intervalli | «Sto ancora imparando il ritmo di {nome}: per ora uso valori tipici per età e taglia.» | ✔ | — (manca la parola «stima» chiesta dal CEO, ma è un tema di interfaccia) |
| Intervallo abituale | «In base al suo intervallo abituale da sveglio (circa X).» | ✘ se `k < 1` | Vedi A1, punto 6 |
| Orario abituale | «È uno dei suoi orari abituali di uscita.» | ✔ | — |
| Adattamento a 3 giorni | «Negli ultimi giorni fa pipì più spesso del solito: ho accorciato l'intervallo.» | **Incompleto (B3).** La previsione si adatta in silenzio a un possibile segno clinico. Tra 67% e 85% dell'intervallo abituale l'allarme ALR-URI-0xx non scatta, e il testo non orienta | «Negli ultimi 3 giorni fa pipì più spesso del solito: ho anticipato le uscite. Se beve anche di più, ha incidenti in casa, fa fatica a urinare o la pipì cambia colore, parlane con il veterinario.» |
| Scaduto | «È ora: è passato il suo intervallo abituale.» | ✘ se `nIntervals < 4` (non è «suo») (C2) | Con meno di 4 intervalli: «È ora: è passato l'intervallo tipico per la sua età.» |
| Tetto superato | «Ha superato X dall'ultima pipì: portalo fuori adesso.» | ✔ | — |
| Tetto con fattori | «Con {cause} ha bisogno di uscire più spesso: non farlo aspettare oltre X.» | ✔ solo con cause cliniche (A1) | Invariato, ma `{cause}` solo cliniche |
| Notte | testi invariati | ✔ | — |
| Cistite | «… Non ridurre l'acqua: bere aiuta.» | ✔ (ISCAID 2019 non prevede restrizioni idriche; diluire l'urina è utile) | Aggiungere nel maschio: « Se si sforza e non esce pipì è un'urgenza.» (B4) |
| Dopo un intervento | «Dopo l'intervento: uscita breve al guinzaglio solo per i bisogni. …» | ✔ | — |
| Cacca | «Di solito la fa verso le {orari}.» / «Registra qualche giorno di cacche per vedere i suoi orari abituali.» | ✔ | — |

### 1.5 Sicurezza per gruppi

| Gruppo | Esito | Note |
|---|---|---|
| **Cuccioli** | ✔ con una lacuna (B2) | Tetti di giorno e di notte invariati. Una mediana dei 14 giorni in un cucciolo che cresce resta indietro, cioè dà intervalli più corti: è il verso sicuro. **Lacuna:** la previsione di base non usa più gli inneschi (pasto, gioco, risveglio) che il modello usava. Per un cucciolo in educazione sono il consiglio principale (AAHA 2015, Hammerle et al.). Proposta B2 al §7 |
| **Anziani** | ✔ | Prior 240/360/480 invariati. La nicturia (segno precoce di IRC, Cushing e disfunzione cognitiva) è fuori dalla previsione, perché la notte è esclusa: resta affidata all'allarme sulla pipì notturna nuova (`alerts.dart`, nicturia). Va bene così |
| **Poliuria nuova** | ✔ con A2 | L'adattamento a 3 giorni è la protezione giusta. Restano due condizioni: che il proprietario registri le uscite (§8) e che l'allarme non sia reso meno sensibile (A2) |
| **Cistite** | ✔ con B4 | Come malattia «nota» nel testo libero resta attiva per sempre (0,4). La cistite sporadica guarisce in 3-5 giorni di terapia (ISCAID 2019). Proposta B4 |
| **Diuretici** | ✔ con C3 | Furosemide orale: aumento della diuresi entro 1 h, picco 2-3 h, effetto finito a 6 h (Uechi 2003). Il codice usa 0,35 nelle prime 2 h e 0,6 da 2 a 6 h: il picco cade a cavallo. Proposta C3 |
| **Cortisonici** | ✔ | 0,67 è ragionevole. Con prednisone o prednisolone a dose antinfiammatoria, il 90% dei proprietari nota PU/PD o polifagia entro 14 giorni, e un terzo pulisce incidenti in casa (Gober & Hillier 2023). Con A1 il fattore si applica nei primi 14 giorni di terapia, poi è nella mediana |
| **Dopo un intervento** | ✘ notifica (A3) | Il testo va bene. Manca il push a 12 ore (§2.2) |

---

## 2. Notifiche di uscita e di sicurezza (`store.dart`, `planNotifications`)

### 2.1 Promemoria di uscita

- Programmato a `recommendedAt − reminderLeadMinutes`. Se l'orario è già passato, `Notifier.schedule` **lo scarta** (`notifications.dart:162`). Il ricalcolo avviene a ogni salvataggio. Quindi:
  - non c'è rischio di raffiche di notifiche ad app aperta;
  - quando la previsione è già scaduta, **non parte più nessun promemoria** per quell'uscita.
- **Il tetto non ha una notifica propria (B1).** Se l'uscita consigliata è prima del tetto, la notifica parte solo all'orario consigliato. Se il proprietario la ignora o non la vede, il tetto (la rete di sicurezza dichiarata in 08 §11.3) resta visibile solo dentro l'app.
  - Proposta: una seconda notifica a `latestAt`, solo pipì, solo se `latestAt` è dopo `recommendedAt` di almeno 30 min. Testo: «{nome}: sono passate {X} dall'ultima pipì» / «È il limite consigliato per la sua età. Se è già uscito, registralo.»
  - Va tenuto il tetto di 60 notifiche: basta un solo ID per cane.
- Il testo «È quasi ora di uscire con {nome} 🐾 — Uscita consigliata alle HH:MM. {reason}» va bene.

### 2.2 «Nessuna pipì da N ore»

Le soglie attuali vanno bene:
- 6 h nei cuccioli sotto i 4 mesi, 8 h nei cuccioli da 4 a 6 mesi;
- 12 h nel maschio con sforzo o gocce nelle 24 ore;
- 24 h negli altri.

Il cucciolo di notte viene spostato a 1 ora dopo il risveglio: va bene.

**Manca il periodo dopo un intervento (A3).** La ritenzione urinaria dopo l'anestesia è frequente:
- 17,8% entro 24 h dopo protesi d'anca con epidurale (Viilmann 2021);
- 62% con epidurale lombosacrale in chirurgia dell'arto pelvico (Ferrero 2021);
- 11-16% con morfina intratecale o epidurale toracica (Lardone 2022).

ALR-URI-006 in app scatta già a 12 ore dopo un intervento, ma la notifica ad app chiusa parte solo a 24 ore. Le due regole devono coincidere: vedi A3.

---

## 3. Testi clinici v1.0-rc: esito

| ID | Esito |
|---|---|
| VIA-004 | **Approvata** (la parte normativa resta di competenza legale) |
| VIA-005 | **Approvata con modifica** |
| EMG-019 (CAV Niguarda, solo Italia) | **Approvata con modifica** |
| Frase d'azione «Chiama subito…»: ALR-TOX-001, ALR-DIA-002, ALR-DIA-005, ALR-FAR-001, ALR-FAR-004, ALR-GI-007a | **Approvata con modifica**: una frase comune e una parte specifica per avviso |
| ALR-URI-006 (frase d'azione quando sale a SUBITO) | **Approvata con modifica**: serve anche un testo diverso nella variante SUBITO |
| `country_pack.dart` (CAV solo `IT`, verifica entro 6 mesi) | **Approvata** |

Nessuna proposta è respinta.

### 3.1 VIA-004 — approvata

Testo da usare (identico alla proposta): «Rilasciato dal veterinario ASL o autorizzato. Regole UE: Reg. (UE) 2016/429 e Reg. delegato (UE) 2026/131, in vigore dal 22 aprile 2026; i passaporti rilasciati prima restano validi. Verifica prima di partire sul sito del Ministero della Salute.»

Non è materia clinica. Il riferimento normativo l'ha verificato `ricerca/15` §2, punto 3.

### 3.2 VIA-005 — approvata con modifica

Testo esatto: «**Trattamento contro la tenia Echinococcus** — Va fatto da un veterinario e registrato sul passaporto 24-120 ore (da 1 a 5 giorni) prima dell'ingresso nei Paesi indenni. Verifica l'elenco aggiornato prima di partire, con il veterinario o sul sito del Ministero della Salute.»

Motivo:
- il trattamento è valido solo se lo fa e lo registra un veterinario: un antiparassitario dato a casa non conta alla frontiera;
- «da 1 a 5 giorni» evita errori di calcolo.

L'elenco dei Paesi resta fuori finché non è verificato sull'atto vigente (`ricerca/15` §2, punto 3b).

### 3.3 EMG-019, CAV di Milano solo per l'Italia — approvata con modifica

Testo esatto (variante `cav = yes`): «Chiama subito il tuo veterinario o il pronto soccorso veterinario. Per sapere quanto è pericoloso ciò che ha ingerito puoi chiamare anche il Centro Antiveleni di Milano (Ospedale Niguarda), {phone}, 24 ore su 24: risponde anche per gli animali e ti chiederà nome e recapiti. Non provocare il vomito di tua iniziativa. Tieni a portata la confezione o una foto dell'etichetta. Se ha convulsioni, respira male o non è ben sveglio, parti subito per il pronto soccorso veterinario e chiama durante il tragitto.»

Due aggiunte:
1. «Non provocare il vomito di tua iniziativa». È coerente con ALR-TOX-001. Il vomito indotto è controindicato con caustici, idrocarburi, oggetti appuntiti e cane non vigile.
2. L'indicazione di partire subito se ci sono segni neurologici o respiratori. In quel caso la telefonata non deve ritardare il trasporto.

Variante `other` (altri Paesi): invariata.

`country_pack.dart` è approvato così com'è: numero solo per `IT`, nessuna dichiarazione di gratuità, verifica entro 6 mesi imposta da un test. Una nota per il CEO, non bloccante: il Paese è quello del cane. Un cane italiano in viaggio all'estero vedrebbe comunque il numero italiano. È accettabile: il CAV risponde per telefono e il testo mette per primo il veterinario.

### 3.4 Frase d'azione «Chiama subito il veterinario; se non risponde, vai al pronto soccorso veterinario» — approvata con modifica

Il principio è giusto: in questi sei avvisi la prima azione utile è una telefonata. Il veterinario decide se serve andare, dove, e cosa fare intanto (decontaminazione, zucchero, sospendere la dose).

La frase proposta ha però due difetti:
- «se non risponde» non dice quanto aspettare;
- non prevede il peggioramento mentre si aspetta.

**Frase comune (testo esatto, chiave `ACT-CALL-FIRST`):**

> «Chiama subito il veterinario. Se non risponde entro pochi minuti, o se il cane peggiora, vai al pronto soccorso veterinario, anche di notte.»

Si applica a tutti e sei gli avvisi. Per tre di essi va cambiato o completato anche il testo, come segue.

| ID | Esito | Testo esatto da usare |
|---|---|---|
| ALR-TOX-001 | Approvata con la frase comune | Testo invariato. Nessuna aggiunta: dice già «anche se sta bene» e «non provocare il vomito» |
| ALR-DIA-002 | Approvata con la frase comune **e una modifica al testo** | «Possibile ipoglicemia. Se è cosciente strofina miele o glucosio sulle gengive (mai liquidi in bocca a un cane incosciente) e chiama subito il veterinario. **Se trema, barcolla, ha convulsioni o non è ben sveglio, vai direttamente al pronto soccorso veterinario.** Non fare la prossima insulina senza averlo sentito.» (AAHA 2018, Behrend et al.: l'ipoglicemia con segni neurologici è un'emergenza) |
| ALR-DIA-005 | Approvata con la frase comune **e una modifica al testo** | «Due dosi di insulina registrate a {x} ore di distanza. Se le hai fatte davvero, chiama subito il veterinario: rischio di ipoglicemia. **Intanto offrigli il suo pasto e non lasciarlo solo.** Se è un errore di registrazione, cancellane una.» |
| ALR-FAR-001 | Approvata con la frase comune; **testo da correggere: A4** | Vedi A4 |
| ALR-FAR-004 | Approvata con la frase comune; **testo da correggere: A5** | Vedi A5 |
| ALR-GI-007a | Approvata con la frase comune; **testo da correggere: A5** | Vedi A5 |

### 3.5 ALR-URI-006 quando sale a SUBITO — approvata con modifica

Mettere la frase d'azione del livello SUBITO sotto il testo attuale non basta. Il testo resta condizionale («Portalo fuori e osserva: se prova a urinare senza riuscirci…»), mentre il dato che lo fa salire a SUBITO è proprio lo sforzo nel maschio. Il proprietario leggerebbe due indicazioni opposte: osserva / vai subito.

**Variante SUBITO** (maschio con sforzo o gocce nelle 24 ore), nuova chiave `alrUri006TextStrain`. Testo esatto:

> «{nome} è un maschio, si è sforzato a urinare nelle ultime 24 ore e da {ore} ore non risulta nessuna pipì: può essere un blocco delle vie urinarie. Non aspettare di vedere se la fa: è un'urgenza, anche di notte. Se escono solo gocce, conta come se non avesse urinato.»

Frase d'azione: quella del livello SUBITO («Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.»).

Se c'è anche un intervento alla colonna, la frase sulla colonna va **dopo** il testo urgente, non prima.

La variante ATTENZIONE resta invariata, senza frase d'azione.

---

## 4. Procedura guidata del primo cane (`dog_wizard.dart`)

Oggi la procedura chiede: nome, sesso, foto, data di nascita, peso, taglia adulta, sterilizzazione, malattie note (testo libero), sveglia e sonno.

| Dato | Serve per | Assente → conseguenza | Priorità |
|---|---|---|---|
| **Terapie in corso** (nome, ogni quante ore, prossima dose) | ALR-FAR-001/004, ALR-GI-007a, l'insulina, i fattori della pipì per diuretici e cortisonici, i promemoria delle dosi, il PDF | Il cane in FANS che vomita non riceve l'avviso SUBITO, finché il proprietario non trova da solo la sezione delle terapie | **A6** |
| Stato riproduttivo della femmina intera (in calore ora? ultimo calore circa quando? gravida o allatta?) | ALR-REP-001 (piometra 14-84 giorni dopo il calore), fattori di gravidanza e allattamento, nutrizione | C'è un ripiego: senza calore registrato si contano i segni (07 N6). Ma la finestra della piometra resta cieca e la razione di una cagna che allatta è sbagliata | B5 |
| Sterilizzazione con «Non so» | Avvisi della femmina intera | Oggi l'interruttore parte da «no». Una femmina sterilizzata per cui non si tocca l'interruttore riceve avvisi di piometra falsi; un maschio castrato riceve avvisi di prostata | B5 |
| Allergie (soprattutto a farmaci) | PDF per il veterinario, pronto soccorso | Informazione persa in emergenza | B5 |
| Vaccinazioni del cucciolo (fatte o no) | Rischio di parvovirosi nei cuccioli con vomito o diarrea | Gli avvisi GI dei cuccioli non sanno se il cucciolo è protetto | B5 |
| Malattie note come scelte (diabete, Cushing, malattia renale, cardiopatia, epilessia, Addison, ipotiroidismo) invece del solo testo libero | Fattori e sorveglianza: oggi il riconoscimento è per parola chiave | Errori di battitura («diabbete») = nessun riconoscimento. «Cistite» resta per sempre | B4/B5 |

**A6, testo proposto.** Nuovo passo 3 «Medicine», tra «Salute» e «La sua giornata».

- Titolo: «Prende medicine?»
- Introduzione: «Alcune medicine cambiano quanto beve e quanto spesso deve uscire, e alcuni segni vanno presi più sul serio durante una terapia. Se non lo sai ora, puoi aggiungerle dopo.»
- Scelta: «No» / «Sì, le aggiungo ora» / «Sì, le aggiungo dopo».
  - «Sì, le aggiungo ora» apre il modulo della terapia già esistente.
  - «Sì, le aggiungo dopo» crea in Home una scheda fissa «Aggiungi le medicine di {nome}», finché non ne è registrata almeno una o la scheda non viene chiusa.

La procedura sale a 5 passi. Il criterio «un concetto per schermata» resta rispettato.

---

## 5. Conferma di «Saltato» e promemoria di conferma delle dosi

### 5.1 Dialogo «Dose saltata?» (`home_screen.dart:380-401`) — approvato, con modifica del testo

Chiedere conferma solo per «Saltato» è giusto: una dose segnata saltata per errore falsa il diario. Nel PDF degli antiepilettici questo diario si legge accanto alle crisi.

Il testo però non dice cosa fare. Testi esatti:

- Generale: titolo «Dose saltata?» · testo «Confermi che questa dose non è stata data? Non raddoppiare la prossima: chiedi al veterinario cosa fare.»
- **Insulina** (riconosciuta dal titolo: insulin, caninsulin, vetsulin, prozinc, lantus): testo «Confermi che l'insulina non è stata fatta? Non farla in ritardo e non raddoppiare la prossima senza aver sentito il veterinario. **Se non sei sicuro che sia stata fatta, non rifarla.**»
- **Antiepilettici** (fenobarbital, levetiracetam, bromuro di potassio, imepitoina, zonisamide): testo «Confermi che la dose non è stata data? Con i farmaci per le convulsioni una dose saltata può far tornare le crisi: chiama il veterinario oggi per sapere se darla adesso.»

Fonti:
- per l'insulina, il rischio di doppia dose e la regola «nel dubbio non ripetere» seguono AAHA 2018 (Behrend et al.);
- per gli antiepilettici, la sospensione brusca e le dosi saltate sono una causa riconosciuta di crisi da rimbalzo (Podell et al. 2016, consenso ACVIM). Il levetiracetam ha un'emivita breve.

Questa è la correzione **A7**.

### 5.2 «Dato» senza annullamento — B6

Un tocco sbagliato su «Dato» fa credere che la dose sia stata data. Con l'insulina e due persone in casa, è il presupposto per una dose mancata, oppure per una dose doppia se poi si corregge male.

- Proposta: SnackBar per 10 secondi: «Dose segnata come data · Annulla».
- Stesso comportamento per «Saltato», dopo la conferma.

### 5.3 Promemoria di conferma (`store.dart:639-655`)

- Notifica 2 ore dopo la dose, al massimo 3 per cane: ✔.
- Testo attuale: «💊 Dose confermata per {nome}? Apri {app} e segna "Dato" o "Saltato". Se l'hai saltata non raddoppiare la successiva: chiedi al veterinario.» ✔ per i farmaci in generale.
- **Insulina (A7):** il promemoria arriva 2 ore dopo e chiede «Dose confermata?». In una famiglia può spingere chi non l'ha fatta a farla in quel momento. Testo esatto per l'insulina:
  - titolo «💉 Insulina di {nome}: segnata?»
  - testo «Se è stata fatta, segna "Dato". Se non sei sicuro che sia stata fatta, non rifarla: chiedi al veterinario.»
- **Dosi non confermate (B6).** `pendingDoses` guarda solo le ultime 24 ore. Le dosi non confermate dopo 24 ore spariscono senza traccia, e il PDF conta come «saltate» solo quelle segnate. Proposta: nel PDF, riga «dosi non confermate: N» accanto a «confermate» e «saltate».

---

## 6. Risposte alle domande aperte di `ricerca/15` §3.2

| # | Voce | Risposta | Testo esatto proposto | Fonti |
|---|---|---|---|---|
| 6 | **ALR-RES-002**, gengive rosso scuro | D'accordo con il revisore: il raffreddamento va condizionato al caldo o allo sforzo. Le mucose rosso mattone si vedono anche nello shock distributivo e nella sepsi iniziali, e nell'intossicazione da monossido di carbonio, dove raffreddare non serve e fa perdere tempo. **B10** | «Gengive rosso scuro possono indicare un colpo di calore, un'infezione grave o uno shock. Se ha preso caldo o ha fatto sforzi, inizia subito a raffreddarlo con acqua fresca (vedi Emergenze) e poi parti; negli altri casi parti subito per il veterinario.» | Hall et al. 2023 (*Vet Sci*, raffreddare prima, trasportare dopo); Bruchim et al. 2017 |
| 7 | **ALR-ALT-006**, forasacco | La condizione è troppo larga: qualsiasi starnuto da maggio ad agosto → OGGI. I forasacchi nasali danno **starnuti violenti e parossistici a esordio improvviso**, spesso con scolo o sangue da una sola narice e con sfregamento del muso (Lafuma 2021). Uno starnuto isolato non basta. **B9** | Condizione: da maggio ad agosto, starnuti registrati come «improvvisi/violenti», oppure ≥ 3 registrazioni di starnuti in 24 ore, oppure starnuti con sangue o scolo da una narice. Altrimenti nessun avviso. Testo: «Starnuti violenti e improvvisi dopo un prato, in stagione dei forasacchi, richiedono una visita oggi: prima si toglie, meno danni fa. Non cercare di estrarlo da solo.» | Lafuma et al. 2021 (*Vet Radiol Ultrasound*); Griffeuille et al. 2023 (*Can Vet J*, migrazione) |
| 8 | **ALR-REP-008**, perdite nella sterilizzata | Serve un testo specifico. Nella sterilizzata la parola «calore» non ha senso. Le cause sono: vaginite, piometra del moncone, sindrome dell'ovaio residuo (segni di proestro ed estro dopo la sterilizzazione: Ball 2010), incontinenza con dermatite, neoplasia. **B8** | Variante «sterilizzata», OGGI se purulente: «In una femmina sterilizzata, perdite con pus o cattivo odore possono indicare un'infezione della vagina o di ciò che resta dell'utero: contatta il veterinario oggi.» Variante ATTENZIONE: «Perdite dalla vulva in una femmina sterilizzata vanno fatte vedere nei prossimi giorni. Se sono sangue e lei si comporta come in calore, dillo al veterinario: a volte resta un pezzetto di ovaio. Oggi stesso se è abbattuta, beve molto o compaiono pus o cattivo odore.» | Ball et al. 2010 (*JAVMA*) |
| 9 | **ALR-URI-008**, sangue durante il calore | Va armonizzato. Livello INFO, frase d'azione «Parlane alla prossima visita» tolta, perché il testo contiene già le condizioni per chiamare. Proestro più estro durano in media circa 2-3 settimane; oltre le 3-4 settimane si parla di calore prolungato. **B11** | Testo: «Durante il calore è normale una perdita di sangue dalla vulva, che può macchiare la pipì. Senti il veterinario nei prossimi giorni se il calore dura più di 3-4 settimane o se la pipì resta rossa anche dopo; oggi stesso se si sforza a urinare, va molto spesso o è abbattuta.» Frase d'azione: nessuna | Testi di riproduzione (Concannon); parere clinico |
| 10 | **ALR-PES-007** nei cuccioli | Sì, l'avviso va tenuto anche nei cuccioli: il BCS è valido nel cane in crescita, e un sovrappeso precoce predice l'obesità da adulto (Salt 2017, curve di crescita). **Il testo però è sbagliato per un cucciolo.** Dice che la razione è calcolata per un dimagrimento, mentre `nutrition.dart` (`merFactor`) giustamente non applica il dimagrimento durante la crescita. Un cucciolo non va messo a dieta da solo. **B7** | Variante «in crescita» (età < fine crescita): «Body Condition Score {bcs}/9: per un cucciolo è sopra l'ideale. Non ridurre il cibo da solo: durante la crescita la razione va decisa con il veterinario, controllando la curva di crescita.» Frase d'azione: «Parlane alla prossima visita.» Adulti: invariato | Salt et al. 2017 (*PLoS One*); WSAVA BCS |
| 11 | **TOS-004**, cipolla e aglio | Le due cifre non si contraddicono. Circa **5 g/kg** di cipolla (0,5% del peso) è la soglia citata per la comparsa dei corpi di Heinz. 15-30 g/kg sono le dosi sperimentali con anemia emolitica clinicamente importante. L'aglio è più potente della cipolla. Gli effetti si sommano con assunzioni ripetute. Si tiene 5 g/kg, che è il valore prudente. **C4** | «Cipolla, aglio, porro, erba cipollina (anche cotti, in polvere o nei sughi): possono causare anemia. Già da circa 5 g di cipolla per kg di peso, cioè mezza cipolla piccola per un cane di 10 kg, e meno per l'aglio. Piccole quantità ripetute si sommano. I segni possono comparire dopo 1-5 giorni.» | Cortinovis & Caloni 2016 (*Front Vet Sci*) |
| 12 | **MET-002**, avviso caldo | Le soglie (27 °C percepiti, 24 °C nei cani a rischio, umidità ≥ 70%, prova dei 7 secondi sull'asfalto) non hanno una fonte che le validi come soglie di rischio per il cane. Hall et al. 2020 identificano chi è a rischio (brachicefali, obesi, anziani, ≥ 50 kg), non i gradi. Vanno presentate come **prudenziali**. **C5** | Aggiungere in coda: «Sono soglie prudenziali, non un limite sicuro: anche sotto, osserva come respira.» | Hall et al. 2020 (*Animals*); Hall et al. 2023 |
| 13 | **STG-003**, 74% | Approvo la formulazione proposta dal revisore. **C5** | «Nel Regno Unito circa 3 colpi di calore su 4 avvengono durante lo sforzo: nei giorni caldi, passeggiate brevi e nelle ore fresche.» | Hall et al. 2020 |
| 14 | **PRV-001**, anagrafe | Materia legale e regionale, non clinica. Dal lato clinico: microchip e iscrizione entro i termini, prima di ogni cessione. Nel testo eviterei i «60 giorni» fissi. **C6** | «Obbligatoria per legge: microchip e iscrizione all'anagrafe canina entro i termini della tua Regione (in molte entro i 60 giorni di vita) e comunque prima della cessione. Se hai adottato il cane, verifica che sia intestato a te.» I riferimenti normativi li decide il legale (`ricerca/15` riga 13) | — |
| 15 | Fonti in `ricerca/04`, `07` | D'accordo con tutte le correzioni di `ricerca/15` §2 (SINAC, Porciello, Bruchim, Hall) | — | — |

---

## 7. Elenco delle correzioni

### Priorità A — prima della beta

| # | File | Testo o codice attuale | Testo o codice proposto |
|---|---|---|---|
| **A1** | `lib/logic/elimination_model.dart:980-986`, `1039-1040`, prudenza 957; `lib/logic/bio_params.dart:215-318` | `k = bio.factor` applicato all'intervallo misurato; tetti e prudenza su `bio.factor`, che contiene taglia e dieta; testo «(circa {base.intervalMin})» | Due fattori `constitutional` / `clinical`. Con ≥ 4 intervalli `k` solo da farmaci iniziati da < 14 giorni e dalla finestra del diuretico; `k ≥ 0,5`. Tetti e prudenza solo su `clinical`. Testo: «In base al suo intervallo abituale da sveglio, accorciato per {cause}: circa {X}.» Test in §1.2 |
| **A2** | `lib/logic/alerts.dart:367-369` | `expectedRise = bioFactor < 0.8 ? 2.5 : 1.5` (fattore totale) | `expectedRise = clinicalFactor < 0.8 ? 2.5 : 1.5` |
| **A3** | `lib/store.dart:579-604` | Ore: cuccioli 6/8, maschio con sforzo 12, altri 24. Titolo «🔴 {nome}: nessuna pipì da {ore} ore?» | Aggiungere: intervento registrato come fatto da meno di 3 giorni, oppure chirurgia della colonna da meno di 14 giorni → 12 ore. Titolo «🔴 {nome}: nessuna pipì da 12 ore dopo l'intervento?». Testo: «Dopo un'anestesia alcuni cani non riescono a svuotare la vescica. Se non ha urinato, o ci prova senza riuscirci, chiama oggi il veterinario che l'ha operato. Se l'ha fatta, registrala.» |
| **A4** | `lib/l10n/app_it.arb:170` (ALR-FAR-001) | «Durante la terapia per il Cushing questi segni possono indicare un calo eccessivo del cortisolo: sospendi la prossima dose solo se te lo dice il veterinario e chiamalo subito.» | «Durante la terapia per il Cushing questi segni possono indicare un calo eccessivo del cortisolo. Non dare la prossima dose finché non hai parlato con il veterinario, e chiamalo subito.» Motivo: l'ipocortisolismo da trilostano colpisce circa il 15% dei cani entro 2 anni (King 2018) e può essere grave (Lamoureux 2023). Saltare una dose di trilostano ha un rischio trascurabile; darla a un cane in ipocortisolismo no. Il testo attuale, se il veterinario non risponde, porta a darla. *Da confrontare con il foglietto illustrativo vigente di Vetoryl prima della firma* |
| **A5** | `lib/l10n/app_it.arb:206` (ALR-FAR-004), `:247` (ALR-GI-007a) | FAR-004: «Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non sospendere né aggiungere farmaci di tua iniziativa.» GI-007a: «Feci nere durante una terapia con antinfiammatori o cortisone: chiama subito il veterinario, potrebbe trattarsi di un sanguinamento dello stomaco.» | Varianti ICU per farmaco (`fans` / `cortisone` / `entrambi`). FAR-004 FANS: «Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non dare la prossima dose di antinfiammatorio finché non l'hai sentito, e non aggiungere altri farmaci (mai antidolorifici per persone).» FAR-004 cortisone: «Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non sospendere il cortisone di colpo e non aggiungere altri farmaci: chiedi a lui cosa fare.» GI-007a: «Feci nere durante una terapia con antinfiammatori o cortisone: potrebbe essere un sanguinamento dello stomaco. Chiama subito il veterinario; [FANS:] non dare la prossima dose di antinfiammatorio finché non l'hai sentito.» Motivo: con un effetto avverso gastrointestinale il FANS va sospeso fino al parere del veterinario (WSAVA 2022, Monteiro et al.; AAHA 2022, Gruen et al.). Il cortisone a lungo termine non va interrotto di colpo |
| **A6** | `lib/ui/dog_wizard.dart` (nuovo passo dopo `_stepHealth`, riga 346) | Nessuna domanda sulle terapie | Passo «Prende medicine?» (§4, testo esatto) e scheda in Home «Aggiungi le medicine di {nome}» se la risposta è «dopo» |
| **A7** | `lib/ui/home_screen.dart:382-401`; `lib/store.dart:643-655` | Dialogo: «Confermi che questa dose non è stata data?». Promemoria: «💊 Dose confermata per {nome}?…» uguale per tutti i farmaci | Testi per farmaco generico, insulina e antiepilettici del §5.1; promemoria per l'insulina del §5.3 |
| **A8** | `lib/l10n/app_it.arb` (ALR-TOX-001, DIA-002, DIA-005, FAR-001, FAR-004, GI-007a: chiavi `…Action` e testi DIA-002/DIA-005); EMG-019 `:2103`; VIA-005 | Proposte v1.0-rc | Testi esatti del §3.2-3.4 |
| **A9** | `lib/logic/alerts.dart:179` e ARB `alrUri006Text` | Testo condizionale anche quando il livello è SUBITO | Nuova chiave `alrUri006TextStrain` con il testo del §3.5, più la frase d'azione SUBITO |
| **A10** | `lib/logic/elimination_model.dart:1209-1240` (`dailyPlan`), mostrato in `lib/ui/potty_screen.dart:30,113` («Piano consigliato di oggi») | Il piano usa ancora il modello statistico (contro 08 §11.3), `dog.prudence` senza la restrizione per cuccioli, anziani e malati (06 §30) e `prior.maxDay` senza il tetto clinico: un cane in diuretico o un cucciolo con «Meno uscite» riceve un piano più largo dei promemoria | Costruire il piano dalla previsione di base: intervallo personale con lo stesso `k`, la stessa prudenza corretta e lo stesso tetto clinico di `forecast`. In alternativa, togliere la sezione finché il modello non supera il collaudo. Test: in nessun caso il piano propone un intervallo più lungo del tetto di `forecast` |

### Priorità B — durante la beta (prima del rilascio pubblico)

| # | File | Attuale | Proposto |
|---|---|---|---|
| B1 | `lib/store.dart:657-682` | Solo la notifica all'orario consigliato | Seconda notifica al tetto (`latestAt`), solo pipì, se il tetto è ≥ 30 min dopo l'orario consigliato. Titolo «{nome}: sono passate {X} dall'ultima pipì». Testo «È il limite consigliato per la sua età. Se è già uscito, registralo.» |
| B2 | `lib/logic/elimination_model.dart`, `forecast` (ramo pipì) | I cuccioli non hanno inneschi nella previsione di base | Sotto i 6 mesi: se dopo l'ultima pipì sono registrati un pasto, un gioco o un risveglio, `recommended = min(recommended, evento + 15 min)`. Testo «Ha appena {mangiato / giocato / dormito}: i cuccioli di solito la fanno entro 15-30 minuti. Portalo fuori adesso.» (AAHA 2015, Hammerle et al.) |
| B3 | `elimination_model.dart:1020-1022` | «Negli ultimi giorni fa pipì più spesso del solito: ho accorciato l'intervallo.» | «Negli ultimi 3 giorni fa pipì più spesso del solito: ho anticipato le uscite. Se beve anche di più, ha incidenti in casa, fa fatica a urinare o la pipì cambia colore, parlane con il veterinario.» |
| B4 | `bio_params.dart:259`; `elimination_model.dart:1106-1108` | «cistite» nelle malattie note vale per sempre; testo «Non ridurre l'acqua: bere aiuta.» | La cistite diventa un episodio con data (o una terapia). Dopo 14 giorni, domanda «La cistite di {nome} è guarita?» (Sì → fattore tolto). Nel maschio aggiungere al testo: « Se si sforza e non esce pipì è un'urgenza.» (ISCAID 2019) |
| B5 | `lib/ui/dog_wizard.dart` | Sterilizzazione sì/no; nessun dato riproduttivo, allergie o vaccini | Sterilizzazione «Sì / No / Non so» (con «Non so» niente avvisi della femmina intera, ma un invito a chiedere al veterinario). Femmina intera: «È in calore adesso?», «Ultimo calore, circa», «È incinta o allatta?». Allergie a farmaci (facoltativo). Cucciolo: «Ha fatto tutte le vaccinazioni da cucciolo? Sì / Non ancora / Non so». Malattie: scelte multiple più il campo libero |
| B6 | `home_screen.dart:155-163`; `store.dart:425-469`; `pdf_export.dart:292` | «Dato» senza annullamento; dosi non confermate oltre 24 h perse | SnackBar «Dose segnata come data · Annulla» (10 s). Nel PDF: «confermate N · saltate N · non confermate N» |
| B7 | ARB `alrPes007Text:467` | Unico testo, parla di dimagrimento anche per i cuccioli | Variante «in crescita» del §6, punto 10 |
| B8 | ARB ALR-REP-008; `alerts.dart:929-945` | Testo che parla di «calore» anche per la sterilizzata | Varianti «sterilizzata» del §6, punto 8 |
| B9 | `alerts.dart:1067` (ALR-ALT-006) | Qualsiasi starnuto da maggio ad agosto → OGGI | Condizione e testo del §6, punto 7 |
| B10 | ARB ALR-RES-002 | «… raffreddalo con acqua (vedi Emergenze) e vai subito dal veterinario.» | Testo del §6, punto 6 |
| B11 | ARB ALR-URI-008 | Frase d'azione «Parlane alla prossima visita» | Testo e frase d'azione (nessuna) del §6, punto 9 |

### Priorità C — quando possibile

| # | File | Attuale | Proposto |
|---|---|---|---|
| C1 | `potty_predictor.dart`, `findHabitual` | Gruppi a catena entro 45 min (in un cane con molte uscite diventano un unico gruppo); conta gli eventi, non i giorni | Limitare l'ampiezza del gruppo a 90 min; contare i giorni distinti in cui il gruppo compare |
| C2 | `elimination_model.dart:1029` | «È ora: è passato il suo intervallo abituale.» anche con meno di 4 intervalli | Con meno di 4 intervalli: «È ora: è passato l'intervallo tipico per la sua età.» |
| C3 | `bio_params.dart:290-296` | Diuretico 0,35 per 0-2 h, 0,6 per 2-6 h | 0,35 da 0,5 a 3 h; 0,6 da 3 a 6 h; 0,85 fuori finestra (Uechi 2003: picco 2-3 h, fine a 6 h). Torasemide: effetto fino a 12 h, distinguerla se il nome la contiene |
| C4 | ARB TOS-004 | «anemia: alterazioni del sangue da circa 5 g/kg, effetto cumulativo» | Testo del §6, punto 11 |
| C5 | ARB MET-002, STG-003 | Soglie presentate senza qualifica; «Il 74% dei colpi di calore…» | Testi del §6, punti 12-13 |
| C6 | ARB PRV-001 | «entro 60 giorni dalla nascita» | Testo del §6, punto 14, previo parere legale |
| C7 | `alerts.dart` (deduplicazione delle notifiche urgenti in `_reschedule`, chiave con `a.title`) | `alert_${d.id}_${a.title}_…` | Usare l'ID dell'avviso: con le traduzioni il titolo cambia. Già segnalato in `ricerca/15` §3.3 per gli avvisi in app; qui vale per le notifiche |

---

## 8. Rischi residui (dopo le correzioni A)

1. **La previsione misura il proprietario, non solo il cane.**
   - Se il cane esce a orari fissi e fa la pipì solo fuori, gli intervalli registrati sono quelli delle passeggiate.
   - Una poliuria si vedrà allora come incidenti in casa, nicturia o sete, non come intervalli più corti.
   - Proteggono gli allarmi su sete, incidenti e notte. La previsione non è uno strumento diagnostico, e i testi non devono mai suggerirlo (frasi vietate di 08 §11.3).
2. **Tutto dipende dalla registrazione.** «Nessuna pipì da 24 ore» con dati mancanti dà falsi allarmi, e i falsi allarmi consumano fiducia. La soglia di 72 ore oltre la quale l'app tace (ALR-URI-00x) è un compromesso accettabile.
3. **Malattie scritte nel testo libero:** riconoscimento per parola chiave, errori di battitura, nessuna data. B4 e B5 lo riducono, non lo eliminano.
4. **Insulina in famiglie con più persone.** La doppia dose resta il rischio domestico più grave tra quelli coperti. A7 e ALR-DIA-005 aiutano, ma solo se tutti registrano su un'app condivisa e sincronizzata.
5. **Notifiche su Android** (sveglie esatte, Doze) non ancora provate su un dispositivo vero (08 §11.2). Le notifiche di sicurezza (nessuna pipì, dosi) hanno valore solo se arrivano.
6. **Ritenzione dopo l'intervento:** A3 copre la notifica. Resta il cane che urina per traboccamento (gocce frequenti), che il proprietario può scambiare per pipì normale. Il testo di ALR-URI-001 («se escono solo gocce…») va mostrato anche dopo un intervento.
7. **Nicturia degli anziani:** fuori dalla previsione per scelta. Resta all'allarme notturno, che dipende da una registrazione notturna che pochi faranno.
8. **Numero del CAV:** può cambiare. La verifica ogni 6 mesi è imposta da un test, ma il numero resta un dato esterno.
9. **Nessun testo è approvato** finché il veterinario abilitato non firma la v1.0-rc con queste modifiche (B5 del piano).

---

## 9. Bibliografia

Fonti trovate con PubMed (PMID, DOI) e con Consensus.

- Behrend E, Holford A, Lathan P, et al. 2018 AAHA Diabetes Management Guidelines for Dogs and Cats. *J Am Anim Hosp Assoc* 2018;54(1):1-21. PMID 29314873. [doi:10.5326/JAAHA-MS-6822](https://doi.org/10.5326/JAAHA-MS-6822)
- Weese JS, Blondeau J, Boothe D, et al. ISCAID guidelines for the diagnosis and management of bacterial urinary tract infections in dogs and cats. *Vet J* 2019;247:8-25. PMID 30971357. [doi:10.1016/j.tvjl.2019.02.008](https://doi.org/10.1016/j.tvjl.2019.02.008)
- Podell M, Volk HA, Berendt M, et al. 2015 ACVIM Small Animal Consensus Statement on Seizure Management in Dogs. *J Vet Intern Med* 2016;30(2):477-490. PMID 26899355. [doi:10.1111/jvim.13841](https://doi.org/10.1111/jvim.13841)
- Hammerle M, Horst C, Levine E, et al. 2015 AAHA Canine and Feline Behavior Management Guidelines. *J Am Anim Hosp Assoc* 2015;51(4):205-221. PMID 26191821. [doi:10.5326/JAAHA-MS-6527](https://doi.org/10.5326/JAAHA-MS-6527)
- Monteiro BP, Lascelles BDX, Murrell J, et al. 2022 WSAVA guidelines for the recognition, assessment and treatment of pain. *J Small Anim Pract* 2022 (via Consensus). [Scheda Consensus](https://consensus.app/papers/details/w:6d94cd05-d5d2-4155-9f45-3798b181c9fa/?utm_source=claude_code)
- Gruen ME, Lascelles BDX, Colleran E, et al. 2022 AAHA Pain Management Guidelines for Dogs and Cats. *J Am Anim Hosp Assoc* 2022 (via Consensus). [Scheda Consensus](https://consensus.app/papers/details/w:2addc17f-fdfd-43fa-a5f9-ecf23be9703e/?utm_source=claude_code)
- King JB, Morton JM. Incidence and risk factors for hypoadrenocorticism in dogs treated with trilostane. *Vet J* 2017;230:24-29. PMID 29208212. [doi:10.1016/j.tvjl.2017.10.018](https://doi.org/10.1016/j.tvjl.2017.10.018)
- Lamoureux A, et al. Iatrogenic symptomatic hypoadrenocorticism after treatment with trilostane for hyperadrenocorticism in dogs: eight cases (2008-2019). *J Small Anim Pract* 2023;64(6):409-414. PMID 36960837. [doi:10.1111/jsap.13594](https://doi.org/10.1111/jsap.13594)
- Gober M, Hillier A. Perception and usage of short-term prednisone and prednisolone in dogs. *BMC Vet Res* 2023;19:91. PMID 37488543. [doi:10.1186/s12917-023-03644-x](https://doi.org/10.1186/s12917-023-03644-x)
- Uechi M, Matsuoka M, Kuwajima E, et al. The effects of the loop diuretics furosemide and torasemide on diuresis in dogs and cats. *J Vet Med Sci* 2003;65(10):1057-1061. PMID 14600341. [doi:10.1292/jvms.65.1057](https://doi.org/10.1292/jvms.65.1057)
- Viilmann I, Klöppel H, Wringe E, Vettorato E. Success rate and perioperative complications of lumbosacral extradural anaesthesia in dogs undergoing total hip replacement. *Vet Comp Orthop Traumatol* 2022;35(2):81-89. PMID 34560807. [doi:10.1055/s-0041-1736194](https://doi.org/10.1055/s-0041-1736194)
- Ferrero C, Borland K, Rioja E. Retrospective comparison of three locoregional techniques for pelvic limb surgery in dogs. *Vet Anaesth Analg* 2021;48(4):554-562. PMID 34083139. [doi:10.1016/j.vaa.2020.11.011](https://doi.org/10.1016/j.vaa.2020.11.011)
- Lardone E, Sarotti D, Giacobino D, et al. Thoracic epidural anaesthesia vs intrathecal morphine in dogs undergoing major thoracic and abdominal surgery. *BMC Vet Res* 2022;18:200. PMID 35624498. [doi:10.1186/s12917-022-03296-3](https://doi.org/10.1186/s12917-022-03296-3)
- Ball RL, Birchard SJ, May LR, et al. Ovarian remnant syndrome in dogs and cats: 21 cases (2000-2007). *J Am Vet Med Assoc* 2010;236(5):548-553. PMID 20187819. [doi:10.2460/javma.236.5.548](https://doi.org/10.2460/javma.236.5.548)
- Lafuma F, Baudin Tréhiou C, Bernardin F, Blond L. Computed tomography may be helpful in discriminating grass awn foreign body rhinitis from non-foreign body rhinitis in dogs. *Vet Radiol Ultrasound* 2021;62(5):533-540. PMID 33987917. [doi:10.1111/vru.12981](https://doi.org/10.1111/vru.12981)
- Griffeuille E, et al. Septic peritonitis secondary to intra-peritoneal grass awn migration: 7 cases (2014-2021). *Can Vet J* 2023;64(3):217-224. PMID 36874536.
- Cortinovis C, Caloni F. Household food items toxic to dogs and cats. *Front Vet Sci* 2016;3:26. PMID 27047944. [doi:10.3389/fvets.2016.00026](https://doi.org/10.3389/fvets.2016.00026)
- Salt C, Morris PJ, German AJ, et al. Growth standard charts for monitoring bodyweight in dogs of different sizes. *PLoS One* 2017;12(9):e0182064. PMID 28873413. [doi:10.1371/journal.pone.0182064](https://doi.org/10.1371/journal.pone.0182064)
- Hall EJ, Carter AJ, O'Neill DG. *Animals* 2020;10(8):1324; Hall EJ et al. *Vet Sci* 2023;10(7):465; Bruchim Y et al. *Temperature* 2017;4(4):356-370: citazioni già verificate in `ricerca/15` §2.

Create or connect a free Consensus account to return more than 3 results per search in Claude Code.: https://consensus.app/sign-up/?utm_source=claude_code&auth=claude_code
