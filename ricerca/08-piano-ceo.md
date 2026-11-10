# 08 — Piano del CEO: stato, tesi economica, decisioni e cicli fino al lancio

*10 novembre 2026. Autore: CEO e coordinatore del progetto (agente nominato da Lorenzo). Documento vincolante per il prossimo periodo: le decisioni della sezione 3 valgono finché non le cambio io con un nuovo documento, oppure finché Lorenzo non le cambia.*

Convenzioni: **[FATTO]** = verificato da me nei file o nei comandi, oppure riportato da un rapporto con fonte. **[STIMA]** = mia ipotesi ragionata. **[DA VERIFICARE]** = serve un controllo esterno prima di usarla.

Il mandato di Lorenzo è *"un'app perfetta, funzionante, che mette al centro la salute del cane in tutto e per tutto e che renda il CEO anche milionario"*. Lo traduco in due obiettivi in quest'ordine:
1. **Prima la salute del cane.** Nessuna scelta commerciale può peggiorare la sicurezza. Se un conflitto non si risolve, vince la salute.
2. **Poi il valore economico, per Lorenzo.** Il CEO è un agente: i soldi, i rischi legali e fiscali e le firme sono di Lorenzo. La sezione 2 dice con franchezza quanto è probabile arrivare a 1 milione.

---

## 0. Sintesi in 12 righe

- Il prototipo è **molto più ricco della media del mercato**: oltre 60 allarmi rivisti due volte, diari clinici, PDF per il veterinario, sincronizzazione in famiglia. Ho verificato che 76 test passano e che `flutter analyze` non segnala problemi.
- Però **non è mai stato su un telefono**, **non ha mai visto un cane vero** e **non è sotto controllo di versione**. La funzione che dovrebbe farci pagare, la previsione, è validata su un solo cane simulato.
- Ho trovato difetti concreti che i test non vedono. Il manifest Android non dichiara le autorizzazioni e i ricevitori delle notifiche programmate. Le notifiche sono "inesatte", e quindi possono arrivare in ritardo. Su iOS si possono superare le 64 notifiche in attesa. La policy del database permette a un familiare di diventare proprietario del cane.
- **Decisioni principali:**
  - blocco delle nuove funzioni (feature freeze) fino alla beta, salvo correzioni di sicurezza;
  - "Zampa" non sarà il marchio definitivo;
  - **tutti gli allarmi, le emergenze, la cartella e il PDF base restano gratis per sempre**;
  - Premium = previsione proattiva e comodità, attivato **solo quando l'accuratezza è dimostrata su cani veri**;
  - lancio in Italia su iOS e Android, con beta chiusa a febbraio 2027 e lancio pubblico non prima di fine aprile 2027.
- **Milionario:** con i numeri del rapporto 03 non succede in nessuno dei tre scenari. Servono da 3 a 8 volte le installazioni dello scenario ottimista, l'Europa e un canale veterinario o assicurativo. Stimo una probabilità dell'ordine dell'1-3%. Il piano tiene aperta questa possibilità spendendo poco, e si ferma presto se i dati dicono di no.

---

## 1. Valutazione franca dello stato

### 1.1 Cosa ho verificato direttamente

| Verifica | Esito |
|---|---|
| `flutter analyze` | **Nessun problema** [FATTO] |
| `flutter test` | **76 test, tutti superati** [FATTO]. Validazione pipì: n=44, errore mediano 18 min contro 26 min del timer, 89% degli eventi nella finestra. Cacca: n=11, 3 min contro 363 min |
| Controllo di versione | **Assente**: la cartella non è un repository git [FATTO]. Il codice esiste solo su OneDrive CNR |
| Dimensione | circa 14.100 righe Dart in `lib/`; 28 tipi di evento in `LogType` (il dossier ne dice 24) [FATTO] |
| Manifest Android | Non dichiara `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` né i ricevitori `ScheduledNotificationReceiver` e `ScheduledNotificationBootReceiver`, che la documentazione di `flutter_local_notifications` chiede per le notifiche programmate [FATTO sul file; DA VERIFICARE sul dispositivo]. Etichetta dell'app: `zampa` in minuscolo |
| Modalità delle notifiche | `AndroidScheduleMode.inexactAllowWhileIdle` (`lib/notifications.dart:79`): con Doze il promemoria "portalo fuori ora" può arrivare in ritardo [FATTO] |
| Quantità di notifiche | `_reschedule` programma per ogni cane, fino a 9 cani, fino a 20 scadenze × 2, fino a 30 dosi e altri promemoria: si superano facilmente le **64 notifiche in attesa** che iOS conserva, scartando le più lontane [FATTO sul codice; il limite di 64 è documentato da Apple, DA VERIFICARE se le priorità sono giuste] |
| Accessibilità | Una sola occorrenza di `Semantics` in tutto `lib/` [FATTO] |
| Lingue | Testi scritti direttamente nel codice in italiano, senza file di localizzazione: `supportedLocales` dichiara `en`, ma non esiste una traduzione [FATTO] |
| Database (`supabase/schema.sql`) | La policy `dogs_update` usa solo `using (is_member(id))`, senza `with check` sul campo `owner`: un familiare può riscrivere `owner` e diventare proprietario, cambiando cosa succede quando un account viene eliminato [FATTO sul testo, DA VERIFICARE su Postgres]. Gli inviti sono riutilizzabili per 7 giorni, non vengono consumati e non hanno limiti ai tentativi (codice di 8 caratteri su 32 simboli, circa 40 bit) [FATTO] |
| Identificativo dell'app | `it.zampa.zampa` su iOS e Android [FATTO]. Dopo il primo caricamento sugli store **non si può più cambiare** |
| Dossier | È in parte superato: dice "68 test" e, nella sezione 3, "non ci sono server" [FATTO] |
| Validazione del modello | Usa **un** cane adulto sintetico con un solo seme casuale e log completi [FATTO]. Il risultato sulla cacca (3 min) è quasi certamente ottimistico: nel simulatore la cacca segue a breve distanza l'inizio della passeggiata, e il modello riceve proprio quell'evento come informazione [STIMA] |

### 1.2 Punti di forza (reali)

1. **Profondità clinica senza pari tra i concorrenti trovati** (rapporto 01): allarmi a 4 livelli con frase d'azione fissa, scheda Emergenze, diari per diabete, epilessia, respiro e anziano, regole sui farmaci. È il vantaggio più difficile da copiare.
2. **Etica di progetto giusta:** nessuna diagnosi, nessuna dose suggerita, il compagno non si ammala mai, offline per primo, niente pubblicità né vendita di dati.
3. **Trasparenza del modello:** finestra di probabilità con motivo e accuratezza mostrata. I concorrenti non lo fanno (rapporto 01, §3.2).
4. **Contesto italiano:** filaria e leishmania per area, microchip, detrazione 730, processionaria e forasacchi.
5. **Disciplina di test:** 76 test, analisi pulita, revisioni documentate con fonti.
6. **Costi fissi vicini allo zero** (rapporto 03, §4): notifiche locali, Supabase gratuito o Pro.

### 1.3 I 10 rischi principali, in ordine di gravità

| # | Rischio | Perché è grave | Area |
|---|---|---|---|
| 1 | **Promemoria e allarmi possono non arrivare sul telefono vero** (manifest Android, notifiche inesatte, limite di 64 su iOS, app mai installata) | Un'app di salute che non avvisa è peggio di nessuna app, perché il proprietario si fida. Un avviso di anuria o di dose non confermato che non arriva è un rischio clinico diretto | Tecnica / clinica |
| 2 | **Testi clinici mai approvati da un veterinario abilitato in carne e ossa** | Le due revisioni sono di agenti. Un falso negativo (es. ostruzione nel maschio) o un'istruzione d'emergenza sbagliata espone il cane a un danno e Lorenzo a responsabilità civile. Gli store possono anche rifiutare un'app sanitaria senza una fonte professionale | Clinica / legale |
| 3 | **Posizione di Lorenzo verso il CNR non chiarita**: art. 53 d.lgs. 165/2001, proprietà del software, uso di risorse dell'ente | Il progetto vive nella cartella **OneDrive CNR**. Se il computer o l'archivio sono dell'ente, il CNR potrebbe avere argomenti per rivendicare diritti. Senza chiarezza non si incassa e non si vende: il "milionario" sarebbe impossibile per definizione | Legale |
| 4 | **Il valore centrale non è dimostrato**: accuratezza della previsione sconosciuta su cani veri | La validazione è autoreferenziale: un cane sintetico, log perfetti. Nella realtà mancheranno log e le uscite sono decise dal padrone (dossier §3.1). Se il modello non batte un timer, cadono differenziazione e Premium | Prodotto / scienza |
| 5 | **Nessun controllo di versione né backup indipendente** | Un errore di sincronizzazione di OneDrive o una modifica sbagliata di un agente possono cancellare settimane di lavoro, senza storico per tornare indietro. Non esistono integrazione continua né revisioni del codice | Tecnica / processo |
| 6 | **Costo della registrazione per l'utente e complessità** | Il modello funziona solo se l'utente registra ogni pipì. Con 28 tipi di evento, decine di schermate e diari, il nuovo utente rischia di perdersi. La causa più probabile di abbandono è la fatica di registrare [STIMA] | Prodotto / UX |
| 7 | **Sicurezza e privacy della sincronizzazione non collaudate** | RLS mai provata su Postgres vero; difetto della policy `owner`; inviti riutilizzabili; informativa in bozza; nessuna DPIA; DPA con Supabase non firmato; foto solo locali. Perdere dati è la prima lamentela verso i concorrenti (rapporto 01, §3.3) | Sicurezza / privacy |
| 8 | **Nome e marchio** | "Zampa" confina con Ca' Zampa (catena veterinaria, stesso ambito) e ZampaVet (app di cartella clinica). L'identificativo `it.zampa.zampa` diventerebbe permanente al primo caricamento | Legale / marchio |
| 9 | **Distribuzione ed economia** | Lo scenario realistico porta circa 2.500 € di utile in 36 mesi (rapporto 03). La pubblicità costa più di quanto rende. Non esiste ancora un canale: né veterinari, né canili, né comunità | Business |
| 10 | **Una persona sola, a tempo parziale, con regole cliniche e normative scritte nel codice** | Ogni aggiornamento di calendari o leggi richiede una nuova versione. Senza localizzazione, l'espansione UE (la leva principale dello scenario ottimista) costa una riscrittura dei testi. Lorenzo è l'unico che può fare account, firme e contatti, quindi è un collo di bottiglia | Organizzazione |

**Rischi minori, tenuti d'occhio:**
- accessibilità quasi assente (obbligo di fatto per un'app di salute, e requisito dell'European Accessibility Act per alcuni servizi [DA VERIFICARE se si applica]);
- web senza notifiche ad app chiusa;
- dati personali di Lorenzo resi pubblici dallo status di "trader" DSA sugli store (rapporto 03, §2.3);
- possibile nuova regola Google Play: i nuovi account personali devono fare un test chiuso con almeno 12 tester per 14 giorni prima della pubblicazione [DA VERIFICARE, regola introdotta nel 2023].

### 1.4 Giudizio complessivo per area

| Area | Voto (1-5) | Motivo |
|---|---|---|
| Prodotto (ampiezza) | 4 | Più completo di qualsiasi concorrente trovato |
| Prodotto (usabilità reale) | 2 | Non provato su dispositivo né con utenti; registrazione troppo onerosa da dimostrare |
| Qualità clinica | 3,5 | Ottima sulla carta, ma senza firma umana non è utilizzabile in pubblico |
| Tecnica | 3 | Codice pulito e testato; mancano git, CI, dispositivo e monitoraggio dei crash |
| Sicurezza e privacy | 2,5 | Impostazione giusta (UE, RLS, offline), ma ci sono difetti e i documenti legali mancano |
| Legale | 1,5 | CNR, fisco, marchio e veterinario firmatario: tutto aperto |
| Business | 1,5 | Nessuna monetizzazione, nessun canale, nessun dato sugli utenti |

---

## 2. La tesi per arrivare a "milionario": numeri onesti

### 2.1 I fatti di partenza (rapporto 03)

| | Pessimista | Realistico | Ottimista |
|---|---|---|---|
| Installazioni a 36 mesi | 3.000 | 30.000 | 150.000 |
| Conversione da download a pagante | 1,5% | 2,5% | 4,0% |
| Prezzo annuo | 19,99 € | 24,99 € | 29,99 € |
| Netto per abbonato all'anno (meno IVA e 15% store) | 13,93 € | 17,41 € | 20,89 € |
| Ricavi del 3° anno | 314 € | 7.962 € | 93.006 € |
| Utile cumulato a 36 mesi | ~0 € | ~2.500 € | ~100.000 € |

- Benchmark [FATTO, RevenueCat]: solo il ~20% delle app in abbonamento incassa 1.000 $ in due anni, e solo il ~5% arriva a 10.000 $.
- **Conclusione:** in **nessuno** dei tre scenari Zampa porta 1 milione a Lorenzo entro 3 anni. Lo scenario ottimista porta circa 100.000 € prima delle imposte personali.

### 2.2 Cosa servirebbe davvero [STIMA, calcolo mio sui parametri del rapporto 03]

**Via A: reddito dagli abbonamenti.**
- Abbonati attivi a regime ≈ nuovi abbonati all'anno × 1,9 (rinnovo al 50%, poi al 40%, come nello scenario ottimista).
- A 29,99 € (20,89 € netti):

| Ricavi annui netti dallo store | Abbonati attivi | Nuovi abbonati all'anno | Installazioni all'anno con il 4% di conversione |
|---|---|---|---|
| 400.000 € | ~19.000 | ~10.000 | **~250.000** |
| 1.000.000 € | ~48.000 | ~25.000 | **~630.000** |

- Lo scenario ottimista, al 3° anno, fa circa 80.000 installazioni all'anno. **Servirebbero quindi da 3 a 8 volte lo scenario ottimista, ogni anno**. Non è possibile con la sola Italia: con 5,5 milioni di famiglie con cane, 250.000 installazioni l'anno sono il 4,5% delle famiglie ogni anno.
- Per **tenere in tasca** 1 milione con il regime ordinario e i contributi (aliquota marginale 43% più la gestione separata, rapporto 03 §7) servono circa 2 milioni di utile lordo: per esempio 400.000 € all'anno per 5 anni.

**Via B: vendita della società (exit).**
- Le app in abbonamento piccole e profittevoli si vendono di solito a **2-4 volte l'utile annuo** [STIMA, multipli tipici dei marketplace di acquisizione di piccole aziende software, DA VERIFICARE].
- Una vendita da 1 milione richiede quindi **250.000-500.000 € di utile annuo**: è la stessa scala della via A, solo anticipata.
- Con una partecipazione in una srl, la plusvalenza è tassata circa al 26% [STIMA, DA VERIFICARE con il commercialista]: per incassare 1 milione netto serve una vendita da circa 1,35 milioni.
- **Acquirenti strategici:**
  - Tractive, ora di Bending Spoons dal maggio 2026 (rapporto 01) [FATTO];
  - assicurazioni per animali;
  - produttori di cibo;
  - catene veterinarie.
- Pagherebbero un premio per **una base di utenti attiva e fidelizzata** e per un marchio di fiducia sulla salute, **non** per la vendita di dati, che resta esclusa.
- Bending Spoons tende a comprare prodotti già grandi [FATTO noto, natura delle sue acquisizioni]. Prima di **100.000 utenti attivi al mese** un'acquisizione strategica è un'ipotesi, non un piano [STIMA].

**Via C: canali B2B e partner (moltiplicatori, non basi).**
- **Cliniche:** 6.500 strutture in Italia (rapporto 03). A 39 €/mese, 1 milione di ricavi annui richiede circa 2.100 cliniche, cioè un terzo di tutte quelle italiane: irrealistico per una persona sola. 200 cliniche portano circa 94.000 €/anno. **Il vero valore dei veterinari è la distribuzione, non la quota mensile**: ogni clinica che consiglia l'app porta decine o centinaia di installazioni gratuite [STIMA].
- **Assicurazioni:** con una segnalazione da 10-30 € (rapporto 03, STIMA), 5.000 segnalazioni l'anno valgono 50.000-150.000 €. Serve però un partner regolamentato (IVASS/RUI). È la leva extra più promettente e coerente con la salute: chi ha una polizza va più spesso dal veterinario.

### 2.3 Le condizioni per lo scenario da ≥ 1 M€ (tutte necessarie)

1. **Il modello funziona sui cani veri.** Batte il timer fisso di almeno il 20% nell'errore mediano, e la finestra a 80% contiene almeno il 70% degli eventi. Senza questo non c'è un motivo per pagare.
2. **Gli utenti restano.** Almeno il 30% è attivo a 30 giorni e almeno il 15% a 90 giorni.
3. **Gli utenti pagano.** Almeno il 4% passa da download a pagante a circa 25-30 €, e almeno il 50% rinnova il primo anno annuale.
4. **Si cresce senza pubblicità.** Almeno 40% delle installazioni da canali gratuiti a costo zero (veterinari, canili, inviti in famiglia, passaparola), con un coefficiente di invito ≥ 0,2.
5. **Europa entro 12-18 mesi dal lancio:** inglese, spagnolo e tedesco, con le regole sanitarie di ciascun Paese.
6. **Almeno 300.000 installazioni cumulate entro il 36° mese**, contro le 150.000 dello scenario ottimista.
7. **Una struttura giuridica che permetta di incassare e di vendere** (es. una srl, con Lorenzo socio se il CNR lo consente), con la proprietà del software pulita.
8. **Un partner regolamentato** per assicurazioni, oppure un programma con le catene veterinarie.

**Probabilità [STIMA mia]:**
- tutte le condizioni insieme: **1-3%**;
- arrivare a coprire le spese e a qualche centinaio di euro al mese (scenario realistico): circa 20-30%, se la beta conferma retention e accuratezza.

Non prometto il milione. Prometto un piano che:
- arriva presto ai dati che decidono (accuratezza, retention, conversione);
- spende pochissimo prima di averli (tetto di spesa nella sezione 3.10);
- si ferma o resta un progetto personale gratuito se i dati dicono di no;
- accelera (Europa, partner, società) solo se i dati dicono di sì.

Il primo bivio cade a 6 mesi dal lancio (ottobre 2027), con le soglie della sezione 3.9.

---

## 3. Decisioni vincolanti

### 3.1 Blocco delle nuove funzioni (feature freeze)
- **Da oggi fino al lancio della beta non si aggiunge nessuna nuova funzione clinica o di prodotto.** Sono ammessi solo:
  - correzioni di sicurezza e di bug;
  - semplificazioni;
  - quanto previsto da un ciclo di questo piano.
- Ogni richiesta nuova va in un elenco "dopo il lancio", in fondo a questo documento o nei successivi.
- **Motivo:** il rischio non è la mancanza di funzioni. È che quelle esistenti non funzionino sul telefono, o che nessuno le usi.

### 3.2 Nome
- **"Zampa" non sarà il marchio definitivo.** Il conflitto con Ca' Zampa (cliniche veterinarie) e ZampaVet (app di cartella clinica veterinaria) cade nello stesso ambito di servizi (classi di Nizza 9, 42 e 44). Il rischio di opposizione o di confusione è troppo alto per un prodotto di salute [STIMA, verifica nel Ciclo 1].
- **"Lulù" entra nella verifica, con riserve:**
  - è debole come marchio (è un nome di cane comune, quindi poco distintivo);
  - l'accento crea problemi nella ricerca sugli store;
  - all'estero si confonde con marchi forti come Lulu (editoria) e lululemon.
  - Può passare solo in forma composta e distintiva (es. "Lulù – diario di salute del cane"), se la ricerca di anteriorità è pulita.
- **Procedura:**
  1. L'agente legale e marchi propone 5-8 candidati, compresa la forma composta con Lulù, che superano una ricerca di anteriorità preliminare: banche dati EUIPO (eSearch e TMview) e UIBM, App Store e Play Italia, domini .it, .com e .app, account social.
  2. **Lorenzo sceglie entro la fine del Ciclo 2.**
  3. Il deposito del marchio avviene dopo la scelta e prima del lancio pubblico, **direttamente come marchio UE (EUIPO)**, che copre tutti i mercati delle ondate europee (sezione 9).
- **Nel frattempo:** "Zampa" resta il nome in codice interno. **Nessun caricamento sugli store e nessun App ID registrato su Apple con l'identificativo `it.zampa.zampa`.** Prima del primo caricamento in TestFlight, l'identificativo diventa neutro e definitivo, legato a un dominio di Lorenzo (es. `it.<dominio>.app`).

### 3.3 Posizionamento
- **Frase guida:** "Sappi quando deve uscire. Accorgiti subito se qualcosa cambia." Sottotitolo per gli store: "Diario di salute del cane, pensato con i veterinari".
  - "Pensato con i veterinari" si può usare **solo dopo** la firma di un veterinario abilitato.
- **Chi servo per primo:**
  1. proprietari di **cani adulti e anziani in città, in appartamento**;
  2. proprietari di **cani con una condizione cronica** (diabete, epilessia, cardiopatia, malattia renale, Cushing, cistite ricorrente): sono il segmento più motivato a registrare, più legato al veterinario e più disposto a pagare [STIMA];
  3. i cuccioli sono un canale di ingresso, non il centro: lì la concorrenza è già affollata (rapporto 01).
- **Cosa non siamo:**
  - non un'app di addestramento;
  - non un social;
  - non un collare GPS;
  - non un "veterinario in tasca": non diagnostichiamo.

### 3.4 Modello di prezzo

**Principio:** nulla di ciò che protegge il cane da un danno sta dietro un pagamento. Il Premium vende **tempo risparmiato e previsione**, non sicurezza.

| Sempre gratis (per sempre, anche senza account) | Premium "Plus" |
|---|---|
| Registrazione illimitata di tutti gli eventi | **Promemoria predittivi proattivi** ("tra 20 minuti è il momento giusto"), con orari adattivi |
| **Tutti gli allarmi, a ogni livello** (SUBITO, OGGI, ATTENZIONE, INFO), con le notifiche urgenti | Curva delle 12 ore, piano delle uscite della giornata, statistiche dell'accuratezza |
| Scheda Emergenze e "cosa dire al telefono" | Widget e azioni rapide avanzate (dopo il lancio) |
| Cartella sanitaria, prevenzione, promemoria di scadenze e dosi, conferma delle dosi | PDF esteso: storico completo, grafici di 90 giorni e oltre, allegati |
| Diari clinici (diabete, epilessia, respiro, riproduzione, anziano, esami, convalescenza) | Archivio foto e documenti sincronizzato (quando ci sarà) |
| Previsione **visibile in app** (finestra e motivo), senza notifiche proattive | Dal terzo cane in poi |
| Primo e secondo cane | Temi e accessori del compagno in pixel art |
| Famiglia: condivisione con almeno 2 persone (serve per la sicurezza: doppia insulina, dosi) | Famiglia allargata: dog sitter (dopo il lancio) |
| PDF per il veterinario di base (ultimi 30 giorni) | |
| Esportazione completa e cancellazione dei dati | |

- **Prezzi:**
  - 24,99 €/anno;
  - 3,99 €/mese;
  - 59 € a vita;
  - prova gratuita di 14 giorni;
  - prezzo "fondatori" a vita di 39 € solo per i beta tester.
  - **Niente abbonamenti settimanali, niente pubblicità.**
- **Regola di attivazione:** il Premium si attiva **solo** quando:
  1. lo studio di accuratezza della beta raggiunge le soglie della sezione 3.8;
  2. la posizione con il CNR e il fisco è chiarita per iscritto.
- Se una delle due condizioni manca al lancio, **si lancia tutto gratis** e il Premium arriva con un aggiornamento.
- Una funzione con accuratezza non dimostrata non si fa pagare.
- **Clausola di salute:** se in futuro una funzione Premium si rivela utile alla sicurezza (es. un allarme che usa la previsione), diventa gratuita.

### 3.5 Piattaforme di lancio
- **iOS e Android insieme**, con lo stesso codice Flutter. iOS 16 e superiori e Android 8 e superiori [STIMA, da confermare con il QA in base ai pacchetti].
- **Web:** solo per la dimostrazione o come pagina pubblica; non si promuove come app, perché non manda notifiche ad app chiusa.
- **Desktop (macOS, Windows, Linux):** non si pubblica.
- **Account:**
  - facoltativi al lancio;
  - in beta, attivi per chi vuole la famiglia;
  - accesso con Apple, con Google e con email e codice.

### 3.6 Mercato iniziale
**Aggiornata il 10/11/2026 dalla sezione 9, che prevale in caso di contrasto.**
- **Al lancio:** Italia, in italiano, con le regole sanitarie italiane già presenti.
- **Europa:** a ondate, a partire da circa 4 mesi dopo il lancio. Lingue, condizioni e tempi sono nella sezione 9.
- **Infrastruttura di traduzione:** si anticipa al Ciclo 2, per i testi clinici, e al Ciclo 3, per l'interfaccia.

### 3.7 Governo clinico (vincolante)
1. **Ogni testo** di allarme, emergenza, prevenzione e nutrizione ha:
   - un identificativo stabile;
   - una versione;
   - la fonte;
   - la data di approvazione del veterinario abilitato.
2. **Nessun cambiamento** a soglie o testi clinici dopo la firma senza una nuova approvazione. Ogni regola clinica ha almeno un test.
3. **Canale di segnalazione** degli eventi avversi:
   - "Segnala un problema" in ogni allarme;
   - casella email dedicata;
   - risposta entro 48 h in beta;
   - registro degli incidenti.
4. **Priorità dei promemoria.** Se il sistema non può programmare tutte le notifiche, l'ordine è:
   1. allarmi urgenti;
   2. dosi;
   3. scadenze vicine;
   4. promemoria di uscita;
   5. scadenze lontane.

### 3.8 Criteri di uscita (definition of done)

**Beta chiusa (obiettivo: inizio febbraio 2027)**

| # | Criterio | Come si verifica |
|---|---|---|
| B1 | Codice in un repository git privato, con integrazione continua che esegue `analyze` e `test` su ogni modifica | Link al repository; ultima esecuzione verde |
| B2 | App installata e usata **7 giorni consecutivi** su almeno 1 iPhone reale e 1 Android reale (oltre agli emulatori), senza crash | Rapporto QA con il registro |
| B3 | Notifiche: su 7 giorni, **≥ 95% dei promemoria entro 2 minuti dall'orario** e **100% degli allarmi urgenti consegnati**. Anche ad app chiusa e dopo un riavvio del telefono | Rapporto QA con la tabella degli orari |
| B4 | Pulsanti "Chiama il veterinario", "Pronto soccorso" e mappa funzionanti su entrambi i sistemi | Rapporto QA |
| B5 | **Testi SUBITO/OGGI e scheda Emergenze firmati** da almeno un veterinario abilitato (versione v1 registrata). Numero del centro antiveleni verificato o assente | Documento firmato in `docs/clinica/` |
| B6 | Supabase UE reale con la RLS provata da test automatici (accesso negato tra famiglie, `owner` non modificabile, inviti consumati) | Test SQL verdi; rapporto di sicurezza |
| B7 | Informativa per la beta, condizioni d'uso e consenso esplicito (opt-in) alla telemetria per lo studio, rivisti da un esperto privacy | `docs/` aggiornati |
| B8 | Telemetria dell'accuratezza attiva (opt-in, minima, in UE) | Prova end-to-end su un dispositivo |
| B9 | Domanda scritta al CNR inviata (la risposta può arrivare dopo, ma la beta è gratuita e senza ricavi) | Copia della richiesta |
| B10 | Identificativo dell'app definitivo e nome scelto | Decisione registrata |

**Lancio pubblico in Italia (obiettivo: tra fine aprile e maggio 2027; mai prima che i criteri siano soddisfatti)**

| # | Criterio | Soglia |
|---|---|---|
| L1 | Beta di almeno **8 settimane**, con **≥ 60 cani** che abbiano almeno 21 giorni di registrazioni | Cruscotto della telemetria |
| L2 | **Accuratezza sulla pipì** su cani reali: errore mediano almeno il 20% migliore del timer fisso; ≥ 70% degli eventi nella finestra dichiarata all'80% | Rapporto dello studio, con soglie fissate prima (preregistrate) |
| L3 | **Calibrazione:** le probabilità dichiarate corrispondono a quelle osservate entro ±10 punti per fascia | Rapporto dello studio |
| L4 | Sessioni senza crash ≥ 99,5%; avvio a freddo < 2,5 s su un Android di fascia media | Strumento di raccolta dei crash |
| L5 | Retention a 30 giorni dei beta tester ≥ 30% | Telemetria |
| L6 | Nessun evento avverso grave aperto; tutti i testi clinici (non solo SUBITO/OGGI) firmati in versione v1 | Registro degli incidenti; documento firmato |
| L7 | Accessibilità: flussi principali (registra pipì, leggi allarme, chiama il veterinario) usabili con VoiceOver e TalkBack e con il testo al 200%; contrasto WCAG AA | Rapporto di accessibilità |
| L8 | Registrazione di una pipì in ≤ 2 tocchi dall'apertura dell'app o dalla notifica | Prova di usabilità con 5 persone |
| L9 | Marchio depositato (domanda EUIPO); dominio; schede degli store complete; informazioni sulla privacy per gli store corrette | Ricevute e schede |
| L10 | Documenti legali definitivi; DPA di Supabase; registro dei trattamenti; DPIA leggera | `docs/` |
| L11 | Se il Premium è attivo: acquisti provati in sandbox su entrambi gli store, ripristino degli acquisti, periodo di tolleranza attivo su Google Play | Rapporto QA |

### 3.9 Metriche (KPI) e soglie

Le metriche si misurano solo con il consenso dell'utente, aggregate, su server UE, senza tracciatori di terze parti.

| Metrica | Definizione | Soglia "verde" | Soglia di allarme |
|---|---|---|---|
| Attivazione | Cane creato e ≥ 3 eventi nelle prime 24 h | ≥ 60% | < 40% |
| Retention a 1, 7 e 30 giorni | Utente con ≥ 1 evento registrato quel giorno o dopo | ≥ 50% / 35% / 30% | < 35% / 20% / **15%** |
| Registrazioni | Eventi pipì e cacca per cane attivo al giorno | ≥ 3 | < 1,5 |
| Accuratezza della pipì | Errore mediano rispetto al timer; copertura della finestra | ≥ 20% meglio; ≥ 70% | peggio del timer |
| Notifiche consentite | Utenti che autorizzano le notifiche | ≥ 70% | < 50% |
| Avvio della prova | Prove iniziate / installazioni | ≥ 8% | < 4% |
| Da prova a pagante | | ≥ 40% | < 25% |
| Da download a pagante (giorno 35) | | ≥ 2,5% (realistico), 4% (obiettivo milione) | **< 1,5%** |
| Rinnovo annuale | | ≥ 40% | < 30% |
| Coefficiente di invito | Nuovi utenti da inviti in famiglia o da veterinari / utenti attivi | ≥ 0,2 | < 0,05 |
| Qualità | Sessioni senza crash; voto sugli store | ≥ 99,5%; ≥ 4,5 | < 99%; < 4,0 |
| Sicurezza clinica | Eventi avversi segnalati e verificati | 0 gravi | ≥ 1 → blocco dei rilasci e revisione |
| Utilità degli allarmi | Risposte "era utile" agli allarmi SUBITO e OGGI | ≥ 70% | < 50% (troppi falsi allarmi) |

**Bivi (riprendono il rapporto 03):**

- **Mese 6 dopo il lancio (circa ottobre-novembre 2027).**
  - Se la retention a 30 giorni è sotto il 15% **e** la conversione è sotto l'1,5%, Zampa resta un **progetto personale gratuito**, con costi vicini a zero.
  - Se si è sopra il realistico, si passa a traduzione ed Europa e a un pilota con le cliniche.
- **Mese 12 (circa aprile-maggio 2028).**
  - Con meno di 300 paganti: niente società, niente spese nuove.
  - Con più di 1.500 paganti e una retention sana: valutare una srl, un partner assicurativo e un'eventuale piccola raccolta di capitali.

### 3.10 Tetto di spesa fino al lancio pubblico

- **Massimo 3.000 €**, salvo diversa decisione di Lorenzo [STIMA delle voci]. Il tetto è salito da 2.500 € perché il marchio si deposita direttamente come marchio UE (sezione 9). Le ondate europee hanno un budget separato, da approvare (sezione 9.6).

| Voce | Costo |
|---|---|
| Apple Developer | 99 € |
| Google Play | ~23 € |
| Veterinario abilitato | 600-1.500 € |
| Revisione privacy e legale | 300-800 € |
| Ricerca di anteriorità e deposito EUIPO (tasse ufficiali in 1-3 classi, DA VERIFICARE sul sito EUIPO) | ~850-1.100 € |
| Android di prova di fascia media | ~150 € |
| Dominio | ~15 € |

- **Zero pubblicità a pagamento** fino al bivio del mese 6.

---

## 4. Piano a cicli

- **Durata:** cicli di circa 2-3 settimane, tenendo conto che Lorenzo lavora al CNR e delle feste.
- **Chiusura di ogni ciclo:**
  1. tutti gli agenti consegnano un rapporto scritto in `ricerca/` (numerazione progressiva);
  2. il CEO li legge per intero e decide se il ciclo è chiuso, se va ripetuto o cosa cambia;
  3. i rapporti integrali restano disponibili a Lorenzo.
- **Regola sul codice:** gli agenti specialisti non modificano `lib/` né `test/`. Segnalano. Le modifiche le fa lo sviluppatore principale.
- **Eccezioni** indicate negli incarichi: `supabase/`, `docs/`, configurazioni native di `android/` e `ios/`, CI.

### Calendario

| Ciclo | Date | Obiettivo |
|---|---|---|
| **1** | 11–24 nov 2026 | **Verità:** codice al sicuro, app sul telefono, difetti noti, misura dell'accuratezza progettata, domande legali preparate |
| **2** | 25 nov–15 dic 2026 | **Fondamenta sicure:** correzioni dal Ciclo 1, backend reale sicuro, telemetria opt-in, crash, prima firma del veterinario, documenti privacy, scelta del nome |
| **3** | 16 dic 2026–19 gen 2027 | **Semplice da usare:** inserimento iniziale, registrazione in 2 tocchi, azioni dalle notifiche, accessibilità, testi estratti in file di localizzazione, nuovo nome e identificativo |
| **4** | 20 gen–9 feb 2027 | **Beta chiusa 1:** 15-25 cani di persone vicine, TestFlight e test chiuso Play |
| **5** | 10 feb–16 mar 2027 | **Beta allargata:** 60-150 cani tramite veterinari, canili e gruppi; studio di accuratezza a metà; Premium in sandbox; schede degli store |
| **6** | 17 mar–13 apr 2027 | **Candidato al rilascio:** verifica di tutti i criteri L1-L11, invio in revisione agli store |
| **7** | 14 apr–15 mag 2027 | **Lancio pubblico Italia** (Go/No-Go del CEO), contenuti di primavera ed estate (caldo, forasacchi, processionaria) |
| M1-3 | mag–lug 2027 | Retention, primi 10 veterinari "consiglia l'app", correzioni |
| M4-6 | ago–ott 2027 | Ottimizzazione di prezzo e prova; **ondata europea 1** (inglese, spagnolo, tedesco), se il cancello E1 è superato (sezione 9); **bivio del mese 6** |
| M7-12 | nov 2027–apr 2028 | Se il bivio è superato: **ondata europea 2** (francese, portoghese, olandese), pilota con 3-5 cliniche, studio scientifico (con il consenso degli utenti e la posizione CNR chiarita), contatto con un partner assicurativo regolamentato. **Bivio del mese 12** |

### Ciclo 2 — Fondamenta sicure (25 nov–15 dic)

**Lavori:**
- Lo sviluppatore principale corregge tutti i difetti A e B del Ciclo 1.
- Schema Supabase corretto e caricato in un progetto UE reale, quando Lorenzo l'ha creato.
- Telemetria opt-in secondo la specifica del data scientist.
- Raccolta dei crash, con fornitore e regione UE scelti dall'esperto privacy.
- Testi clinici in tabelle con ID e versione.
- **Infrastruttura di traduzione per i testi clinici e di logica** (incarico L-1 della sezione 9): `gen-l10n`, messaggi con ID, test di identità dell'italiano.
- Priorità delle notifiche (sezione 3.7.4).
- Correzione del dossier.

**Agenti:**
- sviluppatore principale;
- QA su dispositivo (seconda passata);
- esperto privacy e GDPR (informativa per la beta, consenso, registro dei trattamenti, DPIA leggera, scelta dello strumento per i crash, DPA);
- legale e marchi (seconda passata sui candidati scelti);
- veterinario-editore (raccoglie le correzioni del veterinario abilitato).

**Criteri di accettazione:**
- B1, B2, B3, B4 e B6 verdi;
- B5 almeno per SUBITO e OGGI, se il veterinario ha risposto;
- B7 in bozza revisionata;
- nome scelto (B10).

### Ciclo 3 — Semplice da usare (16 dic–19 gen)

**Lavori:**
- Inserimento iniziale in meno di 60 secondi: nome, età, peso, orari; il resto dopo.
- Tipi di evento avanzati nascosti finché non servono (es. il diario del diabete compare solo se c'è la condizione).
- Azioni rapide dalla notifica ("Fatta fuori", "Fatta in casa").
- Accessibilità: `Semantics`, testo grande, contrasto.
- Estrazione dei testi dell'interfaccia in ARB (solo italiano), con pseudo-lingua e separazione tra lingua e Paese (incarico L-2 della sezione 9).
- Cambio di nome e identificativo; icona e schede.

**Agenti:**
- designer UX e accessibilità;
- sviluppatore principale;
- QA;
- growth e ASO (prime schede degli store, pagina di presentazione).

**Criteri di accettazione:**
- 5 prove di usabilità (persone vere con cane): ≥ 4 su 5 registrano una pipì senza aiuto in ≤ 2 tocchi;
- verifica con VoiceOver e TalkBack dei 3 flussi principali;
- nessun testo italiano rimasto nel codice fuori dagli ARB (controllo automatico).

### Ciclo 4 — Beta chiusa 1 (20 gen–9 feb)

**Lavori:**
- Distribuzione con TestFlight e test chiuso su Google Play.
- Istruzioni per i tester.
- Canale di segnalazione.
- Revisione settimanale degli allarmi scattati, con il veterinario-editore.

**Agenti:**
- QA;
- data scientist (cruscotto);
- veterinario-editore;
- sviluppatore principale (correzioni).

**Criteri di accettazione:**
- ≥ 15 cani attivi per 14 giorni;
- crash-free ≥ 99%;
- 0 allarmi urgenti persi;
- prime metriche di accuratezza calcolate correttamente (controllo sui dati a mano su 3 cani).

### Ciclo 5 — Beta allargata (10 feb–16 mar)

**Lavori:**
- Reclutamento tramite 3-5 veterinari, 1-2 canili e gruppi di proprietari, con materiale stampabile per le cliniche.
- Analisi a metà dello studio.
- RevenueCat in sandbox, solo se il CNR e il fisco lo permettono.
- Schede degli store e pagina di presentazione.
- Documenti legali definitivi.

**Agenti:**
- growth e community;
- data scientist;
- sviluppatore principale;
- legale e privacy;
- QA (pagamenti).

**Criteri di accettazione:**
- ≥ 60 cani con ≥ 21 giorni di dati entro la fine del ciclo, oppure una proroga decisa dal CEO;
- analisi a metà pubblicata in `ricerca/`.

### Ciclo 6 — Candidato al rilascio (17 mar–13 apr)

**Lavori:**
- Verifica di L1-L11.
- Correzioni.
- Invio in revisione agli store.
- Piano di risposta agli incidenti.
- Revisione di sicurezza finale (RLS, segreti, dipendenze).

**Agenti:**
- QA;
- revisore di sicurezza;
- veterinario-editore (tutti i testi firmati);
- legale.

**Criteri di accettazione:** tutti i criteri L verdi, oppure una deroga scritta del CEO motivata (mai su L6).

### Ciclo 7 — Lancio pubblico Italia (14 apr–15 mag)

**Lavori:**
- Go/No-Go.
- Rilascio graduale su Android (20% → 100%).
- Contenuti di stagione.
- Prima ondata di veterinari.
- Monitoraggio quotidiano di crash e incidenti per 2 settimane.

**Criteri di accettazione:**
- crash-free ≥ 99,5%;
- voto sugli store ≥ 4,5 sui primi 20 voti;
- 0 eventi avversi gravi.

---

## 5. Ciclo 1 — incarichi completi (11–24 novembre 2026)

**Obiettivo del ciclo:** sapere la verità sullo stato reale e mettere al sicuro il lavoro. Nessuna nuova funzione.

**Ordine di partenza:**
1. **C1-1 subito**, da solo: nessun altro modifica file finché il repository non esiste.
2. Poi in parallelo: C1-2, C1-4, C1-5, C1-6, C1-7, C1-8, C1-9.
3. **C1-3** parte quando C1-2 ha consegnato il primo elenco di difetti.

**Criteri di chiusura del ciclo** (decide il CEO):
- tutti e 9 i rapporti consegnati;
- repository e CI attivi;
- app avviata almeno su un simulatore iOS e un emulatore Android, e su un telefono reale se Lorenzo lo rende disponibile;
- difetti di gravità A delle notifiche corretti e coperti da test dove possibile;
- protocollo dello studio di accuratezza con soglie fissate;
- bozza della lettera al CNR pronta per Lorenzo;
- pacchetto di revisione pronto per il veterinario umano.

---

### C1-1 — Sviluppatore principale (DevOps): repository, backup e CI · priorità P0

**Contesto:** il progetto in `/Users/lorenzobirindelli/Library/CloudStorage/OneDrive-CNR/Desktop/zampa` non è un repository git. Esiste solo su OneDrive CNR.

**Cosa fare:**
1. **Prima di tutto** fai un archivio compresso datato dell'intera cartella, esclusi `build/` e `.dart_tool/`, in `~/Backups/zampa-2026-11-10.tar.gz`. Verificane l'integrità con `tar -tzf`.
2. Crea la copia di lavoro fuori da OneDrive, in `~/Documents/zampa`, come per gli altri progetti di Lorenzo che costruiscono fuori da OneDrive.
   - **Chiedi conferma a Lorenzo prima di spostare**: se il Mac è un bene CNR, la collocazione va decisa insieme alla verifica di C1-7.
   - La cartella OneDrive resta intatta finché Lorenzo non decide.
3. Esegui `git init` e controlla `.gitignore`:
   - `config/supabase.json` deve restare escluso;
   - aggiungi `*.jks`, `*.keystore`, `key.properties`, `ios/**/GoogleService-Info.plist`, `android/app/google-services.json`, `.env*`.
   - Fai il primo commit con il messaggio "Stato al 10/11/2026: prototipo 0.1, 76 test" e l'attribuzione prevista.
4. Prepara il repository remoto **privato** su GitHub, a nome di Lorenzo.
   - Se `gh` non è autenticato, **non** inserire credenziali: lascia a Lorenzo il comando esatto da eseguire.
   - Non pubblicare nulla in pubblico.
5. Aggiungi una CI con GitHub Actions (`.github/workflows/ci.yml`):
   - Flutter alla stessa versione locale (`flutter --version`);
   - `flutter pub get`, `flutter analyze --fatal-infos`, `flutter test`;
   - controllo dei segreti, almeno un `grep` che fallisca se trova `supabase.co` insieme a una chiave nel codice.
6. Aggiorna `README.md`: cos'è il progetto, come eseguire i test, dove sono i rapporti, regole del repository (rami, nessun segreto). Sostituisce il testo generato da Flutter.

**Vincoli:** non modificare `lib/` né `test/`. Non fare push forzati. Nessun segreto nel repository.

**Consegna:** `ricerca/09-repository-e-ci.md` con:
- percorso dell'archivio e sua dimensione;
- percorso della copia di lavoro;
- hash del primo commit;
- stato del remoto (creato o comando per Lorenzo);
- esito della prima esecuzione della CI.

**Criteri di fine:**
- `git status` pulito;
- `git log` con almeno un commit;
- la CI passa (oppure il file è pronto e verificato localmente con `act` o eseguendo a mano gli stessi comandi);
- archivio di backup esistente e leggibile.

---

### C1-2 — QA e collaudatore su dispositivo · priorità P0

**Contesto:** l'app non è mai stata eseguita su un telefono. Xcode è installato; il simulatore iOS è in download. I dubbi già noti sono nella sezione 1.1 di `ricerca/08-piano-ceo.md`.

**Cosa fare:**
1. Avvia l'app su un **simulatore iOS** e su un **emulatore Android** (API 34 o 35), e sui telefoni reali che Lorenzo mette a disposizione (chiedi quali).
   - Su iPhone reale serve la firma: con un Apple ID gratuito si può installare per 7 giorni; non serve l'Apple Developer Program per questa prova.
2. Esegui questa matrice di prove e registra per ognuna esito, dispositivo, versione del sistema operativo, schermate e passi per riprodurre:
   - **a. Primo avvio:** avvertenza da accettare; "Prova con un cane di esempio"; creazione di un cane vero.
   - **b. Registrazione:** pipì, cacca, pasto, acqua e un sintomo; conteggio dei tocchi necessari.
   - **c. Notifiche, il punto più importante.**
     - Autorizzazione su Android 13+ (`POST_NOTIFICATIONS`) e su iOS.
     - Promemoria della pipì; dose con conferma; scadenza; allarme urgente.
     - Prova ad **app chiusa**, **dopo un riavvio** del dispositivo, in **Doze** (`adb shell dumpsys deviceidle force-idle`) e con il risparmio energetico.
     - Annota l'orario previsto e quello reale.
     - Conta le notifiche in attesa con 3 cani, 2 terapie ogni 8 h e un piano di prevenzione completo; su iOS verifica quante ne restano oltre 64 e quali vengono perse.
   - **d. Pulsanti di emergenza:** "Chiama il veterinario" (`tel:`), mappa dei pronto soccorso, link; su Android 11+ verifica anche la visibilità dei pacchetti.
   - **e. Foto:** fotocamera e galleria, autorizzazioni negate e poi concesse.
   - **f. PDF:** generazione, anteprima, condivisione via mail e WhatsApp, leggibilità su telefono.
   - **g. Persistenza:** chiudi e riapri; aggiorna l'app sopra la versione precedente; esportazione e importazione del backup JSON.
   - **h. Aspetto:** tema scuro, testo grande (200%), schermo piccolo (iPhone SE) e grande, rotazione.
   - **i. Prestazioni:** avvio a freddo; tempo di apertura con 90 giorni di dati simulati (chiedi allo sviluppatore principale una build con dati di carico, oppure usa il cane di esempio).
   - **l. Account**, solo se Lorenzo ha già creato Supabase; altrimenti segna "non provato".
   - **m. Web:** comportamento dichiarato (nessuna notifica ad app chiusa) e messaggio chiaro all'utente.
3. Classifica ogni difetto:
   - **A** = un avviso di salute o un'emergenza può non funzionare, oppure si perdono dati;
   - **B** = funzione rotta;
   - **C** = estetica o testo.

**Vincoli:** non modificare `lib/` né `test/`. Le modifiche a `android/` e `ios/` le fa lo sviluppatore principale (C1-3), a cui passi i difetti con la correzione proposta.

**Consegna:** `ricerca/10-collaudo-dispositivo.md` con:
- matrice dei dispositivi;
- tabella delle prove (esito ✔/✘);
- elenco dei difetti numerati con gravità;
- tabella degli orari delle notifiche;
- raccomandazioni.

**Criteri di fine:**
- tutte le prove da a. a m. eseguite almeno su un dispositivo iOS e uno Android, oppure dichiarate non eseguibili con il motivo;
- ogni difetto A ha i passi per riprodurlo;
- seconda passata sui difetti A dopo le correzioni di C1-3, con esito.

---

### C1-3 — Sviluppatore principale: correzioni bloccanti delle notifiche e del dossier · priorità P0

**Contesto:** difetti già individuati dal CEO (sezione 1.1) più quelli di gravità A trovati da C1-2.

**Cosa fare:**
1. **Android:** aggiungi a `android/app/src/main/AndroidManifest.xml` le autorizzazioni e i ricevitori richiesti dalla documentazione della versione di `flutter_local_notifications` in `pubspec.lock`:
   - `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`;
   - `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`;
   - le `queries` per `tel:`, `https:` e `geo:` se servono;
   - etichetta "Zampa" con la maiuscola.
   - Richiedi l'autorizzazione alle notifiche nel momento giusto (dopo il primo cane creato) e spiega a cosa serve.
2. **Notifiche esatte:**
   - per gli **allarmi urgenti** e le **dosi** valuta `exactAllowWhileIdle`, con la richiesta di autorizzazione `SCHEDULE_EXACT_ALARM` dove serve, oppure `USE_EXACT_ALARM` se la categoria dell'app lo consente secondo le regole Play;
   - i promemoria di uscita possono restare inesatti;
   - documenta la scelta.
3. **Bilancio delle notifiche:** in `_reschedule` (`lib/store.dart`) applica un budget massimo complessivo (es. 60 su iOS) con l'ordine di priorità della sezione 3.7.4 del piano. Aggiungi un test che, con 3 cani, 2 terapie ogni 8 h e un piano di prevenzione completo, verifica che:
   - il totale sia ≤ 60;
   - nessuna dose delle prossime 24 h e nessun allarme urgente venga escluso.
4. Correggi gli altri difetti A di C1-2. Per i B, pianificali nel Ciclo 2, salvo che siano banali.
5. **Dossier:** aggiorna `DOSSIER.md` (numero dei test, sezione "non ci sono server" ora superata, 28 tipi di evento, rimando a questo piano). Non cambiare altro.

**Vincoli:**
- Nessuna nuova funzione (feature freeze).
- Nessuna modifica a soglie o testi clinici.
- `flutter analyze` pulito e tutti i test verdi a ogni commit.

**Consegna:**
- commit nel repository di C1-1;
- nota in fondo a `ricerca/10-collaudo-dispositivo.md`: "Correzioni applicate", con l'elenco dei difetti chiusi e i test aggiunti.

**Criteri di fine:**
- C1-2 conferma su dispositivo che i difetti A delle notifiche sono chiusi;
- test del budget verde;
- CI verde.

---

### C1-4 — Revisore di sicurezza del backend (Supabase / Postgres) · priorità P1

**Contesto:** `supabase/schema.sql`, `supabase/LEGGIMI.md`, `lib/sync/` (`supabase_backend.dart`, `sync_engine.dart`) e `test/sync_test.dart`. Lo schema non è mai stato eseguito su un Postgres vero.

**Cosa fare:**
1. Esegui lo schema su un Postgres locale con la Supabase CLI (`supabase start`, se Docker è disponibile), altrimenti su un Postgres locale con uno schema `auth` simulato. **Non** usare progetti cloud di Lorenzo senza il suo permesso.
2. Scrivi test SQL ripetibili (pgTAP o script `psql` con asserzioni) in `supabase/tests/`, che verifichino almeno:
   - un utente non membro non legge né scrive cani e voci di altri;
   - **un familiare non può cambiare `owner`** né trasferirsi la proprietà (oggi `dogs_update` non ha `with check`: correggilo);
   - un familiare non può cancellare membri altrui;
   - un invito scaduto è rifiutato;
   - **un invito viene consumato** all'uso, oppure ha un numero massimo di usi;
   - ci sono limiti ai tentativi di `accept_invite` (es. tabella dei tentativi per utente e ora);
   - `delete_my_account` cancella i cani di proprietà e lascia intatti quelli condivisi da altri;
   - nessuna funzione `security definer` è sfruttabile (verifica `search_path` e permessi `grant` e `revoke`);
   - `updated_at` viene assegnato dal server.
3. Correggi `supabase/schema.sql` in modo idempotente (rieseguibile) e prepara uno script di migrazione `supabase/migrations/2026-11-xx_sicurezza.sql`.
4. Rivedi `lib/sync/` **solo in lettura** e segnala allo sviluppatore principale:
   - dove la chiave pubblica viene letta;
   - gestione degli errori;
   - conflitti (l'ultima scrittura vince?);
   - cosa succede ai dati locali all'uscita dall'account;
   - rischio di caricare per errore i dati del cane di esempio.
5. Prepara la checklist per la messa in produzione:
   - protezione dalle password compromesse;
   - limiti sulle email;
   - CAPTCHA o protezione anti-abuso, solo da configurare: lo fa Lorenzo;
   - backup PITR (opzione a pagamento);
   - regione UE;
   - DPA.

**Vincoli:** puoi modificare solo `supabase/`. Non modificare `lib/` né `test/`. Nessun segreto nei file.

**Consegna:** `ricerca/11-sicurezza-backend.md` con:
- risultati dei test;
- difetti con gravità;
- correzioni applicate allo schema;
- richieste allo sviluppatore principale;
- checklist per Lorenzo.

**Criteri di fine:**
- tutti i test SQL verdi sullo schema corretto;
- il difetto `owner` e gli inviti riutilizzabili sono chiusi;
- l'elenco delle richieste per `lib/sync/` è consegnato.

---

### C1-5 — Data scientist: protocollo dello studio di accuratezza e prove di robustezza · priorità P1

**Contesto:**
- `lib/logic/elimination_model.dart`, `bio_params.dart`, `potty_predictor.dart`;
- `test/model_validation_test.dart` (un solo cane sintetico, log completi);
- `ricerca/04`, `ricerca/05` e la sezione 3.1 del dossier;
- soglie di lancio L2 e L3 di `ricerca/08-piano-ceo.md`.

**Cosa fare:**
1. **Prove di robustezza** (specifica per lo sviluppatore principale, che scrive i test).
   - Definisci un banco di prova con almeno 30 cani sintetici: età, taglie e condizioni diverse; semi diversi.
   - Introduci i disturbi realistici:
     - 10-40% di pipì non registrate;
     - orari spostati di ±10 minuti;
     - uscite decise dal padrone a orari fissi (il cane fa pipì quando esce);
     - fine settimana diversi;
     - un cambio di routine a metà periodo;
     - cani con poliuria che compare durante il periodo.
   - Indica le metriche, ognuna con un intervallo di confidenza bootstrap:
     - errore assoluto mediano;
     - copertura della finestra dichiarata;
     - calibrazione (affidabilità per fasce);
     - Brier score sulla probabilità nella prossima ora;
     - confronto con 2 riferimenti: timer fisso sull'intervallo medio e "orario abituale" dello stesso giorno della settimana.
   - Prevedi in quali scenari il modello **non** batte i riferimenti. È un risultato valido e va scritto.
   - Valuta se il risultato sulla cacca (3 min) è un artefatto della simulazione, cioè della passeggiata come innesco quasi deterministico.
2. **Protocollo dello studio con i beta tester**, scritto prima di vedere i dati:
   - ipotesi;
   - metriche primarie (L2) e secondarie (L3, utilità percepita);
   - criteri di inclusione (≥ 21 giorni, ≥ 3 pipì registrate al giorno);
   - come trattare le uscite "decise dal padrone";
   - numerosità minima con la motivazione;
   - analisi per sottogruppi (cucciolo, adulto, anziano, malattia cronica);
   - regola di decisione per il Premium (sezione 3.4).
3. **Specifica della telemetria minima** (per l'esperto privacy del Ciclo 2 e per lo sviluppatore):
   - quali dati lasciano il telefono, e solo con opt-in. Preferire le metriche calcolate sul dispositivo (errore per evento, copertura, fascia d'età, condizioni presenti sì/no) agli eventi grezzi;
   - pseudonimizzazione;
   - conservazione;
   - cruscotto.
   - Nessun orario assoluto né posizione, se non servono.
4. Indica se il modello ha bisogno di correzioni prima della beta (es. ampiezza della finestra, prudenza), **senza** cambiare le soglie cliniche.

**Vincoli:** non modificare `lib/` né `test/`. Puoi creare script di analisi in `ricerca/analisi/` (Python o Dart a riga di comando) che usano il modello solo tramite i test, oppure chiedere allo sviluppatore principale un punto d'accesso.

**Consegna:** `ricerca/12-protocollo-accuratezza.md` con:
- banco di prova;
- risultati, se lo sviluppatore ha già implementato il banco nel ciclo, altrimenti la specifica dei test;
- protocollo;
- specifica della telemetria;
- raccomandazioni.

**Criteri di fine:**
- protocollo con le soglie fissate e la regola di decisione;
- specifica della telemetria che rispetta la minimizzazione;
- elenco dei test di robustezza pronti da implementare, ognuno con il risultato atteso.

---

### C1-6 — Legale e marchi: verifica del nome · priorità P1

**Contesto:**
- decisione 3.2 di `ricerca/08-piano-ceo.md`;
- `ricerca/01-concorrenza.md`, che cita ZampaVet, Ca' Zampa e Zampa a Zampa.

**Cosa fare:**
1. Ricerca di anteriorità preliminare (desk research, non un parere legale) per "Zampa", "Lulù"/"Lulu" e almeno **6 nuovi candidati** generati da te. I candidati devono essere:
   - brevi;
   - pronunciabili nelle lingue delle ondate 1 e 2 (italiano, inglese, spagnolo, tedesco, francese, portoghese, olandese), senza significati negativi nemmeno in polacco (sezione 9);
   - adatti a un **marchio dell'Unione europea** (EUIPO), non solo italiano;
   - senza accenti obbligatori;
   - evocativi di cane e salute, ma distintivi.
2. Per ogni candidato verifica:
   - EUIPO eSearch e TMview (classi 9, 42, 44 e, se rilevante, 35);
   - UIBM;
   - App Store e Google Play in Italia, Spagna, Germania, Irlanda e Regno Unito;
   - domini .it, .com e .app;
   - account Instagram e TikTok;
   - significati negativi nelle 8 lingue di cui sopra.
3. Dai un giudizio di rischio (basso, medio o alto) con il motivo e consiglia la classe e la via di deposito (EUIPO, con eventuale ricerca di anteriorità professionale), con i costi ufficiali verificati sui siti degli uffici.
4. Proponi la forma dell'identificativo dell'app e del dominio coerente con il candidato migliore.
5. Elenca le verifiche che deve fare un consulente in marchi abilitato prima del deposito, e il costo indicativo.

**Vincoli:**
- Non depositare nulla.
- Non registrare domini né account: lo fa Lorenzo.
- Dichiara che è una ricerca preliminare e non sostituisce un parere professionale.

**Consegna:** `ricerca/13-nome-e-marchio.md`: tabella dei candidati × verifiche, con link e data, e una classifica.

**Criteri di fine:** almeno 3 candidati a rischio basso con tutte le verifiche fatte e i link alle ricerche, pronti per la scelta di Lorenzo.

---

### C1-7 — Analista legale e fiscale: dossier CNR e fisco per Lorenzo · priorità **P0** (alzata il 10/11: il Mac usato è del CNR, sezione 10)

**Contesto:**
- sezione 7 di `ricerca/03-business-model.md`;
- art. 53 d.lgs. 165/2001;
- il progetto oggi vive nella cartella OneDrive CNR.

**Cosa fare:**
1. Trova e riassumi, con citazioni puntuali e link, le fonti **pubbliche** applicabili:
   - regolamento del CNR sulla proprietà intellettuale e sui risultati della ricerca (brevetti e software dei dipendenti);
   - regolamento CNR sugli incarichi extraistituzionali (autorizzazioni ex art. 53);
   - codice di comportamento del CNR;
   - art. 53 commi 6-7 d.lgs. 165/2001 (opere dell'ingegno);
   - art. 12-bis della legge sul diritto d'autore (L. 633/1941) sul software creato dal dipendente "nell'esecuzione delle sue mansioni o su istruzioni del datore di lavoro";
   - art. 65 del Codice della proprietà industriale, se pertinente ai ricercatori;
   - regole d'uso di OneDrive e degli strumenti informatici del CNR.
2. Analizza i fattori che contano per la titolarità del software e per l'autorizzazione:
   - attinenza con le mansioni di Lorenzo (da chiedere a lui);
   - uso di mezzi, orario e archivi dell'ente;
   - natura commerciale continuativa (abbonamenti) rispetto alla semplice utilizzazione di un'opera dell'ingegno.
3. Prepara una **bozza di email o di istanza** all'ufficio del personale e all'ufficio di valorizzazione della ricerca del CNR. Deve:
   - descrivere il progetto in modo neutro;
   - chiedere esplicitamente: se serve un'autorizzazione; se l'ente rivendica diritti; quali condizioni (es. fuori orario, mezzi propri); se una srl con Lorenzo socio è compatibile.
   - **Non inviarla:** la invia Lorenzo.
4. Prepara la scaletta di domande per il commercialista:
   - regime con un reddito da dipendente sopra i 35.000 €;
   - partita IVA o meno nella fase gratuita;
   - incasso dagli store (Apple e Google come soggetti UE);
   - quando conviene una srl;
   - imposizione di un'eventuale cessione;
   - RC per l'attività.
5. Elenca cosa fare **subito** per ridurre il rischio sulla proprietà, come opzioni per Lorenzo e non come consulenza: per esempio lavorare con mezzi personali e fuori orario, e tenere un registro delle date.

**Vincoli:** non è consulenza legale. Distingui [FATTO con fonte] da [INTERPRETAZIONE]. Non contattare nessuno.

**Consegna:** `ricerca/14-cnr-e-fisco.md` con le fonti, l'analisi, la bozza dell'email e le domande per il commercialista.

**Criteri di fine:**
- bozza dell'email pronta da inviare;
- almeno il regolamento IP del CNR e quello sugli incarichi trovati e citati, oppure dichiarati non reperibili pubblicamente con le ricerche fatte.

---

### C1-8 — Veterinario-editore: pacchetto per il veterinario abilitato e verifiche esterne · priorità P1

**Contesto:**
- `lib/logic/alerts.dart` (oltre 60 regole), `lib/ui/emergency_screen.dart`, `lib/logic/prevention.dart`, `lib/logic/nutrition.dart`, `lib/logic/seasonal.dart`;
- rapporti `ricerca/06` e `ricerca/07`, con le voci "da verificare".

**Cosa fare:**
1. Estrai **in sola lettura** tutti i testi clinici visibili all'utente in un documento di revisione `docs/clinica/testi-clinici-v1.md` (e un CSV gemello), con:
   - ID stabile (es. `ALR-URI-003`);
   - livello (SUBITO, OGGI, ATTENZIONE, INFO);
   - condizione di attivazione in linguaggio semplice (soglie e popolazione);
   - testo esatto;
   - fonte;
   - file e riga;
   - colonna vuota "Approvato / Modificare / Eliminare" e "Note del veterinario".
   - Ordina per priorità di revisione: Emergenze e SUBITO, poi OGGI, poi gli altri.
2. Prepara una **lettera d'incarico** tipo per il veterinario abilitato:
   - oggetto della revisione;
   - tempo stimato;
   - compenso da definire con Lorenzo;
   - limiti di responsabilità e citazione nell'app ("testi rivisti da Dott./Dott.ssa … il …", solo con il suo consenso);
   - riservatezza;
   - verifica dell'iscrizione all'Ordine (FNOVI, albo).
3. Verifica con fonti primarie:
   - **quale centro antiveleni risponde per gli animali** e con quale numero; confermalo dal sito dell'ente, non da blog;
   - D.M. sul SINAC;
   - Reg. (UE) 2026/131 sui viaggi e data di applicazione;
   - D.Lgs. 218/2023 se pertinente;
   - i riferimenti segnati "da verificare" nel rapporto 07.
   - Per ognuno: confermato, corretto o non trovato, con il link.
4. Proponi la struttura dei **testi come dati** (tabella versionata con ID), da passare allo sviluppatore principale per il Ciclo 2.

**Vincoli:**
- Non modificare `lib/`, `test/` né soglie e testi.
- Non inserire numeri non verificati.
- Non presentarti come veterinario abilitato: il tuo lavoro prepara la firma di un professionale umano.

**Consegna:**
- `docs/clinica/testi-clinici-v1.md` (+ `.csv`);
- `docs/clinica/lettera-incarico-veterinario.md`;
- `ricerca/15-verifiche-cliniche-esterne.md`.

**Criteri di fine:**
- il 100% dei testi di allarme ed emergenza è estratto (conteggio confrontato con le regole nel codice);
- ogni riferimento esterno ha un esito;
- il pacchetto è stampabile e leggibile da un veterinario in ≤ 3 ore per la parte SUBITO, OGGI ed Emergenze.

---

### C1-9 — Designer UX e accessibilità: audit (solo analisi) · priorità P2

**Contesto:**
- `lib/ui/` (home, log_sheet, potty, health, diaries, dog_form, profile, account, emergency, avatar);
- il cane di esempio;
- KPI di attivazione e di registrazione di `ricerca/08-piano-ceo.md`.

**Cosa fare:**
1. Percorri l'app (web locale con `flutter run -d chrome`, oppure il simulatore quando C1-2 l'ha avviato) come tre personaggi:
   - "Giulia, 34 anni, primo cane adulto in appartamento a Milano";
   - "Franco, 68 anni, cane anziano cardiopatico";
   - "Sara, cucciolo di 10 settimane".
2. Misura e annota:
   - numero di passi dall'installazione al primo evento registrato;
   - tocchi per registrare una pipì;
   - testi incomprensibili o ansiogeni;
   - funzioni che il personaggio non dovrebbe vedere il primo giorno.
3. Audit di accessibilità: etichette per i lettori di schermo (oggi c'è un solo `Semantics`), contrasti, dimensioni dei bersagli (≥ 44 pt / 48 dp), testo al 200%, colori come unica informazione (livelli di allarme), animazioni del compagno (riduzione del movimento).
4. Proponi:
   - una **semplificazione** con divulgazione progressiva (cosa nascondere e quando mostrarlo);
   - inserimento iniziale in meno di 60 secondi;
   - azioni rapide dalla notifica;
   - una **gerarchia degli allarmi** che non si confonda con il compagno.
   - Usa wireframe testuali o immagini semplici.

**Vincoli:** non modificare codice. Rispetta le regole cliniche del compagno (rapporto 07, sezione F) e il fatto che gli allarmi SUBITO stanno sempre sopra.

**Consegna:** `ricerca/16-audit-ux-accessibilita.md`, con i problemi in ordine di impatto sui KPI e le proposte stimate per difficoltà (S, M, L).

**Criteri di fine:**
- percorso completo dei tre personaggi;
- almeno 10 problemi con prova (schermata o passi);
- piano di semplificazione pronto per il Ciclo 3.

---

## 6. Cosa deve fare personalmente Lorenzo, in ordine

Solo Lorenzo può fare queste cose: hanno bisogno della sua identità, dei suoi soldi, della sua firma o dei suoi contatti.

| # | Quando | Azione | Perché ora |
|---|---|---|---|
| 1 | ✔ **Fatto** | Repository GitHub privato `lorebiri/zampa` creato, CI verde. Copia di lavoro: resta su OneDrive CNR, per decisione di Lorenzo | — |
| 2 | ✔ In parte | Il Mac è **del CNR** (risposta di Lorenzo). Resta da dire se Zampa ha attinenza con le mansioni. Valutare, con l'esito di C1-7, se spostare lo sviluppo su un computer e un archivio personali, fuori orario | Pesa sulla proprietà del software (C1-7) |
| 3 | Entro il 24 novembre | Inviare al CNR l'email preparata da C1-7, dopo averla riletta, e conservare la risposta | Senza risposta non si incassa e non si vende |
| 4 | Entro fine novembre | Prenotare un **commercialista** con le domande di C1-7 | Regime, partita IVA, eventuale srl |
| 5 | Entro fine novembre | Trovare **1-2 veterinari abilitati** (meglio uno di medicina interna e uno di pronto soccorso, anche dalla tua rete), proporre la lettera di C1-8 e concordare il compenso (stima 600-1.500 €) | È il collo di bottiglia del Ciclo 2 e del criterio B5 |
| 6 | Durante il Ciclo 1 | Mettere a disposizione del QA **il tuo telefono** ed eventualmente comprare un **Android di fascia media** (~150 €) | Il criterio B2 richiede telefoni veri |
| 7 | Inizio dicembre | Creare il **progetto Supabase** nella regione Frankfurt (piano gratuito per la beta) seguendo `supabase/LEGGIMI.md` **dopo** le correzioni di C1-4; accettare il DPA di Supabase; configurare le opzioni anti-abuso della checklist | Serve per la famiglia e per la telemetria della beta |
| 8 | Dopo la scelta del nome (fine Ciclo 2) | **Apple Developer Program** (99 €/anno, come persona fisica), App ID con l'identificativo definitivo, Sign in with Apple. **Google Play Console** (25 $), verifica dell'identità; controllare se vale l'obbligo dei 12 tester per 14 giorni. **Google Cloud OAuth** | Non prima del nome: l'identificativo è permanente |
| 9 | Insieme al punto 8 | Decidere quale **indirizzo pubblico** usare come "trader" DSA sugli store, per non esporre l'indirizzo di casa (domiciliazione o PEC; chiedere al commercialista) | Apple lo rende pubblico |
| 10 | Fine Ciclo 2 | **Scegliere il nome** tra i candidati di C1-6; registrare il dominio e gli account social; poi, prima del lancio, depositare il marchio UE all'EUIPO (eventualmente con un consulente) | Serve per l'identificativo e per le schede degli store |
| 11 | Gennaio 2027 | Reclutare **15-25 beta tester** (colleghi, amici, gruppi di proprietari) e chiedere ai veterinari del punto 5 se consigliano la beta ai clienti | Ciclo 4 e studio di accuratezza |
| 12 | Febbraio 2027 | Se il CNR e il fisco hanno dato il via libera: account **RevenueCat**, contratti a pagamento e dati fiscali e bancari negli store, iscrizione al Small Business Program di Apple | Solo con il via libera |
| 13 | Sempre | ✔ Tetto **confermato a 3.000 €** il 10/11 (marchio UE prima del lancio). Resta da indicare il tempo settimanale disponibile | I cicli sono tarati su poche ore a settimana tue |
| 14 | Entro il 15/12/2026 | **Acquistare un Mac personale** per lo sviluppo (sezione 10.4; investimento personale fuori dal tetto, circa 700-1.100 €) e migrare lì la copia di lavoro e gli account | Riduce il rischio sulla proprietà del software |

---

## 7. Cose che **non** faremo prima del bivio del mese 6

- pubblicità a pagamento;
- vendita o cessione di dati, anche "anonimi";
- marketplace di dog sitter;
- assistente AI conversazionale;
- integrazioni con collari;
- versione per desktop;
- nuove lingue fuori dalle ondate e dai cancelli della sezione 9;
- nuove funzioni cliniche non chieste dal veterinario abilitato o dai dati della beta.

## 8. Elenco "dopo il lancio" (non si toccano ora)

- widget e Live Activity;
- accesso del dog sitter;
- QR "cane smarrito";
- OCR del libretto;
- sincronizzazione di foto e documenti (Premium);
- Apple Watch e Wear OS;
- portale per il veterinario;
- **ciclo della cagna (calore):** vedi la decisione nella sezione 10.2. Non prima della fine della beta;
- studio scientifico pubblicabile sui dati di eliminazione: solo con consenso esplicito e con la posizione CNR chiarita, perché un lavoro di ricerca potrebbe ricadere nelle mansioni di Lorenzo.

---

## 9. Lingue europee — decisione del 10/11/2026

*Richiesta di Lorenzo: "mettici le lingue europee", cioè l'app in più lingue europee e pubblicata in tutta Europa. Questa sezione prevale sulla decisione 3.6 e integra la regola 3.7.*

### 9.0 Decisione in breve
- **Sì all'Europa, come obiettivo esplicito del primo anno.** Senza l'Europa lo scenario da ≥ 1 M€ è impossibile (sezione 2.2), quindi la richiesta è coerente con il mandato.
- **No a "tutte le lingue dal giorno 1", per ragioni di salute del cane, non di comodità:**
  - ogni lingua porta testi clinici (allarmi SUBITO e OGGI, Emergenze) che devono essere esatti;
  - ogni Paese ha vaccini, parassiti, numeri d'emergenza e leggi diverse;
  - un allarme tradotto male, o un calendario della filaria italiano mostrato in Germania, è un danno, non una funzione.
- **Tre ondate, ognuna con un cancello a dati.** Ondata 1: inglese, spagnolo e tedesco, circa 4 mesi dopo il lancio. Ondata 2: francese, portoghese e olandese, dopo il bivio del mese 6. Ondata 3: polacco e altre lingue, solo con i dati.
- **Le 24 lingue UE non sono un obiettivo.** Non si possono validare clinicamente né offrire assistenza con un fondatore solo. Si aggiunge una lingua solo quando i dati del mercato lo giustificano.
- **L'infrastruttura si anticipa adesso:**
  - Ciclo 2: testi clinici e di logica;
  - Ciclo 3: interfaccia.

  È compatibile con il blocco delle funzioni (3.1): è un rifacimento senza cambiamenti di comportamento, verificato da un test che confronta l'italiano carattere per carattere. Anzi, rende più facile la firma del veterinario, perché i testi diventano un catalogo con ID.

### 9.1 Lingue e ordine

Criteri, in ordine di peso:
1. numero di cani nel Paese (FEDIAF Facts & Figures 2026, da tabulare: il rapporto 03 riporta solo Italia 9,0 milioni, UE-27 69,6 e Europa 91,2 milioni [FATTO]);
2. somiglianza clinica con l'Italia, cioè quanto contenuto si riusa (filaria, leishmania, processionaria, clima mediterraneo);
3. disponibilità a pagare per le app negli store (Paesi del Nord e dell'Ovest più alta) [STIMA];
4. costo di validazione: una lingua può servire più Paesi;
5. presenza di concorrenti nella lingua.

| Ondata | Lingue | Paesi serviti | Perché |
|---|---|---|---|
| **0 (lancio)** | italiano | Italia (più San Marino) | Contenuti già scritti e firmati |
| **1** | **inglese, spagnolo, tedesco** | Irlanda, Malta, Regno Unito; Spagna; Germania, Austria | L'inglese è la lingua ponte (store, recensioni, veterinari esteri) e il ripiego per chi ha il telefono in una lingua non supportata. La Spagna ha la clinica più simile all'Italia (leishmania, filaria, processionaria) e molti cani [STIMA, DA VERIFICARE su FEDIAF]. La Germania è il mercato grande dell'UE con alta disponibilità a pagare [STIMA] |
| **2** | francese, portoghese, olandese | Francia, Belgio, Lussemburgo; Portogallo; Paesi Bassi e Belgio fiammingo | La Francia è un grande mercato con un Sud mediterraneo. Il Portogallo è clinicamente vicino a Spagna e Italia. I Paesi Bassi hanno una spesa per animale alta [STIMA] |
| **3** | polacco, poi le altre (es. rumeno, ceco, svedese) | Polonia ecc. | Solo se l'analisi L-3 lo giustifica. La Polonia ha molti cani ma una spesa per app più bassa [STIMA, DA VERIFICARE] |

- **Regno Unito:** ha un mercato di cani grande, ma non è UE. Regole sanitarie proprie (es. vaccini, assenza di rabbia endemica, Pet Travel Scheme) e una protezione dei dati propria (UK GDPR). Entra nell'ondata 1 **solo se** il pacchetto Paese britannico è pronto. Altrimenti l'inglese parte con l'Irlanda e Malta.
- **Svizzera:** italiano, tedesco e francese sono già coperti dalle ondate, ma ha regole proprie. Entra quando ha un pacchetto Paese, non prima.
- L'ordine finale delle ondate 2 e 3 lo conferma o lo corregge il rapporto L-3, con i numeri FEDIAF per Paese.

### 9.2 Lingua e Paese sono due cose diverse (regola tecnica e clinica)

1. **Lingua:** come l'app parla.
   - Segue il telefono; l'utente la può cambiare.
   - Se la lingua del telefono non è supportata, il ripiego è l'inglese validato (dall'ondata 1), altrimenti l'italiano.
   - È ammesso perché ogni testo mostrato è comunque validato in quella lingua.
2. **Paese:** quali regole sanitarie valgono.
   - Si sceglie nel profilo; la proposta iniziale si ricava dallo store o dalle impostazioni.
   - Determina:
     - piano vaccinale e antiparassitario;
     - zone e stagioni dei parassiti (ESCCAP nazionale);
     - rischi stagionali (processionaria, forasacchi, caldo);
     - numeri d'emergenza e centri antiveleni;
     - leggi su microchip e anagrafe;
     - viaggi;
     - funzioni fiscali (la detrazione 730 è **solo** italiana).
3. **Ogni Paese ha un "pacchetto Paese"**: dati versionati con fonte e data di validità, firmati da un veterinario di quel Paese. È la regola 3 del rapporto 02 ("regole normative come dati").
4. **Paese senza pacchetto validato.** Se l'utente vive in un Paese non supportato (es. un italiano in Svezia):
   - restano attivi gli **allarmi fisiologici** (anuria, sforzo, torsione, gengive, respiri, convulsioni…), che non dipendono dal Paese e sono validati nella lingua mostrata;
   - restano attivi la cartella, il diario e la previsione;
   - si **nascondono** il piano di prevenzione, i numeri d'emergenza nazionali, gli avvisi stagionali e le funzioni fiscali, con il messaggio: "Per il tuo Paese non abbiamo ancora un calendario verificato: chiedi al tuo veterinario il piano di vaccini e antiparassitari";
   - la scheda Emergenze mostra solo "il tuo veterinario", "il pronto soccorso veterinario più vicino" (mappa) e i primi gesti universali.
   - **Mai** un numero di un altro Paese.

### 9.3 Testi clinici tradotti (estende la regola 3.7)

1. **Fonte unica:** il catalogo italiano con ID firmato (v1, C1-8). Si traduce **solo** dopo la firma italiana, così non si traducono testi che poi cambiano.
2. **Procedura per ogni lingua:**
   1. bozza con traduzione automatica (LLM), usando un **glossario clinico** bilingue fissato prima (es. "anuria", "conati a vuoto", "gengive pallide", livelli SUBITO e OGGI con le frasi d'azione fisse);
   2. revisione di un **traduttore professionale madrelingua con esperienza medico-veterinaria**, su ogni stringa;
   3. per SUBITO, OGGI ed Emergenze, **ritraduzione verso l'italiano** fatta da un'altra persona o da un altro modello, e confronto delle differenze di significato;
   4. **firma di un veterinario abilitato nel Paese di destinazione**, madrelingua, che firma insieme il testo tradotto e il pacchetto Paese.

   Se un veterinario bilingue copre i passaggi 2 e 4, costa meno ed è accettabile.
3. **Una lingua si attiva nell'app solo se il 100% dei testi SUBITO, OGGI ed Emergenze è firmato.** Niente testi clinici non validati, neanche "provvisori".
   - Per i testi non clinici (interfaccia, aiuto) basta la revisione del madrelingua.
   - Per i testi INFO e ATTENZIONE servono revisione e firma, ma una lingua può partire con al massimo il 5% di testi INFO ancora in revisione. In quel caso la regola mostra il ripiego inglese validato con l'avviso "testo in revisione nella tua lingua". **Mai** per SUBITO, OGGI ed Emergenze.
4. **Ogni modifica** a un testo clinico italiano rende "da rivedere" le traduzioni collegate: lo segnala un test automatico tramite l'hash della versione. Le lingue in ritardo mostrano la versione firmata precedente, solo se la regola non è cambiata, altrimenti la regola si blocca e il rilascio di quella lingua si ferma.
5. **Il PDF per il veterinario** ha una lingua scelta a parte da quella dell'app (es. utente tedesco in vacanza in Italia: PDF in italiano). Si usano solo lingue validate.
6. **Unità e formati:** °C e kg di base, °F e libbre come opzione per il Regno Unito e l'Irlanda; date e numeri con `intl`; glicemia in mg/dL o mmol/L secondo il Paese (in Germania e nel Regno Unito spesso si usa mmol/L [DA VERIFICARE]).

### 9.4 Store, distribuzione, legale e marchio

- **Paesi di distribuzione:** dal giorno 1 **solo Italia (e San Marino)**. Non si distribuisce un'app solo in italiano in tutta l'UE:
  - chi la scarica in Germania o in Spagna vedrebbe un calendario e numeri d'emergenza italiani (rischio clinico);
  - arriverebbero recensioni negative nella prima settimana, e queste pesano per sempre sulla scheda (rischio commerciale).
  - Ogni Paese si apre negli store solo quando lingua e pacchetto Paese sono firmati.
- **Schede localizzate per ogni lingua:** titolo, sottotitolo, parole chiave, schermate e testo, scritte dall'agente ASO con ricerche di parole chiave native, non tradotte e basta. Prezzo per Paese: livelli di prezzo dello store adattati al potere d'acquisto (es. Polonia e Portogallo più bassi), decisi con i dati dell'ondata 1.
- **DSA "trader":** obbligo già presente per l'Italia (rapporto 03). Vale per tutta l'UE senza costi aggiuntivi, ma rende l'indirizzo visibile in tutti gli store UE: la scelta dell'indirizzo pubblico (azione 9 di Lorenzo) diventa ancora più importante.
- **IVA:** la versano gli store in ogni Paese UE (rapporto 03), quindi non serve una registrazione IVA per Paese [FATTO, rapporto 03; DA VERIFICARE con il commercialista].
- **Privacy e condizioni d'uso:**
  - tradotte in ogni lingua attiva (il GDPR chiede un'informativa comprensibile);
  - verifica delle regole nazionali sui consumatori e sulle app a contenuto sanitario veterinario;
  - per il Regno Unito: UK GDPR, ICO, rappresentante nel Regno Unito se serve [DA VERIFICARE].
- **Assistenza:** in italiano e in inglese. Nelle altre lingue si risponde in inglese, o con traduzione assistita e un avviso. Una lingua senza capacità di assistenza non apre una nuova ondata.
- **Nome e marchio (aggiorna C1-6 e la decisione 3.2):**
  - il nome deve funzionare nelle 7 lingue delle ondate 1 e 2 ed essere libero come **marchio UE**;
  - si deposita direttamente all'**EUIPO** (tasse indicative: circa 850 € per la prima classe; DA VERIFICARE sul sito EUIPO), non all'UIBM;
  - per il Regno Unito serve un deposito separato all'UKIPO, solo se il Regno Unito entra nell'ondata 1;
  - **"Lulù" esce indebolito:** l'accento crea problemi nella ricerca su tutti gli store UE e "Lulu" è affollato di marchi. Resta in gara solo se supera la ricerca di anteriorità EUIPO.

### 9.5 Cancelli delle ondate

| Cancello | Quando | Condizioni (tutte necessarie) |
|---|---|---|
| **E1, ondata 1** | Circa 2-3 mesi dopo il lancio italiano (luglio 2027) per rilasciare a fine agosto-settembre 2027 | In Italia: crash-free ≥ 99,5%; retention a 30 giorni ≥ 25%; criterio L2 di accuratezza superato; 0 eventi avversi gravi; testi e pacchetto Paese firmati per ogni lingua e Paese; budget approvato da Lorenzo |
| **E2, ondata 2** | Bivio del mese 6 (ottobre-novembre 2027) | Bivio del mese 6 superato. Nell'ondata 1 almeno un Paese ha raggiunto, in 90 giorni, una retention a 30 giorni ≥ 20% e una conversione ≥ 1,5% |
| **E3, ondata 3** | Bivio del mese 12 | Rapporto L-3 aggiornato con i dati reali; ritorno atteso della lingua > costo di validazione entro 12 mesi |

### 9.6 Costi [STIMA, da confermare con preventivi]

- **Per ogni lingua e Paese:**
  - traduzione professionale con revisione clinica del catalogo (stima 15.000-25.000 parole fra interfaccia, allarmi, emergenze e prevenzione): ~1.200-2.500 €;
  - firma del veterinario e pacchetto Paese: ~600-1.500 €;
  - schede degli store e documenti legali: ~200-500 €.
  - **Totale ~2.000-4.500 € per lingua**; meno con un veterinario bilingue che fa insieme revisione e firma.
- **Ondata 1:** ~6.000-13.000 €. Non rientra nel tetto di 3.000 €: **serve un budget separato approvato da Lorenzo** al cancello E1, finanziato idealmente dai primi ricavi italiani.
- **Infrastruttura (Cicli 2-3):** solo tempo dello sviluppatore; nessun costo vivo.

### 9.7 Incarichi

**L-1 · Sviluppatore principale: infrastruttura di traduzione per i testi clinici e di logica (Ciclo 2) · P1**
1. Configura `flutter gen-l10n` (`l10n.yaml`, `lib/l10n/app_it.arb`) con ICU per plurali e parametri.
2. Rendi i testi generati in `lib/logic/` (`alerts.dart`, `prevention.dart`, `nutrition.dart`, `seasonal.dart`, i motivi della previsione in `elimination_model.dart` e `potty_predictor.dart`) e in `lib/ui/emergency_screen.dart` dei **messaggi con ID e parametri**: es. `AlertText(id: 'ALR-URI-003', params: {...})`. La traduzione avviene nella UI, nel PDF e nelle notifiche (queste ultime nella lingua attiva al momento della programmazione, e riprogrammate quando la lingua cambia).
   - Gli ID coincidono con il catalogo di C1-8.
   - Ogni voce dell'ARB ha `@description` con livello, fonte e versione clinica.
3. **Test d'identità:** prima del rifacimento, genera un'istantanea (snapshot) di **tutti** i testi prodotti dalle regole su un insieme di casi (riusa i test esistenti più un generatore che attiva ogni regola). Dopo il rifacimento, l'italiano deve essere identico carattere per carattere.
4. Test che ogni ID usato nel codice esista nell'ARB e viceversa, e che ogni voce clinica abbia la versione.

**Vincoli:** nessun cambiamento di comportamento, soglie o testi; analisi e test verdi.
**Criteri di fine:** test d'identità verde sul 100% delle regole; nessuna stringa visibile all'utente scritta direttamente in `lib/logic/`, verificato da un controllo automatico (es. script che cerca stringhe italiane fuori da `lib/l10n/`); CI verde.

**L-2 · Sviluppatore principale: interfaccia, Paese e pseudo-lingua (Ciclo 3) · P1**
1. Estrai tutte le stringhe di `lib/ui/` e `lib/main.dart` nell'ARB.
2. Aggiungi una **pseudo-lingua** di prova (testi allungati del 40% con accenti, es. `[!!! Ţéšţ ţéšţ !!!]`) e un test che controlla l'assenza di overflow sulle schermate principali a 360 dp di larghezza.
3. Introduci il **Paese** come impostazione dell'utente, separato dalla lingua (sezione 9.2). Predefinito "IT". Tutte le funzioni dipendenti dal Paese leggono un `CountryPack` (per ora contiene solo l'Italia, con i dati attuali spostati in strutture versionate). Con un Paese non supportato si applica il comportamento della sezione 9.2, punto 4, coperto da test.
4. Ripiego delle lingue: lingua del telefono se supportata e attivata, altrimenti inglese (quando sarà validato), altrimenti italiano. Elenco delle lingue attivate in un unico punto di configurazione.
5. Lingua del PDF scelta a parte.

**Criteri di fine:** controllo automatico "nessuna stringa visibile fuori dagli ARB" verde; test della pseudo-lingua verde; test "Paese non supportato" verde (niente prevenzione, niente numeri nazionali, allarmi fisiologici attivi); italiano invariato (test d'identità di L-1 esteso alla UI dove possibile).

**L-3 · Analista di mercato: matrice dei Paesi (Ciclo 3, aggiornata al mese 6) · P2**
1. Tabella per Paese UE più Regno Unito, Svizzera e Norvegia:
   - cani (FEDIAF Facts & Figures 2026, con pagina citata);
   - famiglie con cane;
   - quota iOS/Android;
   - spesa media per app o abbonamenti, se trovata;
   - concorrenti locali nella salute del cane e nella previsione della pipì;
   - somiglianza clinica con l'Italia (leishmania, filaria, processionaria: da ESCCAP);
   - lingua o lingue.
2. Punteggio pesato con i criteri della sezione 9.1 e conferma o modifica dell'ordine delle ondate, con il motivo.
3. Copertura cumulata (% dei cani UE) per ondata.

**Consegna:** `ricerca/17-mercati-europei.md`. **Criteri di fine:** ogni numero ha una fonte o è marcato STIMA; ordine motivato; sensibilità (cosa cambia se si pesa di più la disponibilità a pagare).

**L-4 · Veterinario-editore internazionale: pacchetti Paese dell'ondata 1 (Cicli 5-6, prima del cancello E1) · P2**
1. Per Spagna, Germania con Austria, Irlanda e Regno Unito:
   - piani vaccinali (linee guida nazionali, es. StIKo Vet in Germania; obblighi di rabbia per regione in Spagna [DA VERIFICARE]);
   - antiparassitari e zone (ESCCAP nazionali);
   - rischi stagionali;
   - **centri antiveleni e pronto soccorso veterinario con numeri verificati sulle fonti ufficiali**;
   - leggi su microchip e anagrafe (es. REIAC e registri regionali in Spagna; regole per Land in Germania [DA VERIFICARE]);
   - viaggi;
   - unità consuete (es. glicemia).
2. Formato: dati strutturati con fonte, data di validità e ID, pronti per il `CountryPack`, più un documento leggibile per la firma del veterinario locale.
3. Differenze rispetto all'Italia che toccano le regole degli allarmi (es. babesiosi e leishmania in zone diverse, specie di zecche diverse): elenco da far decidere al veterinario.

**Vincoli:** non presentarsi come veterinario abilitato; niente numeri non verificati.
**Consegna:** `docs/clinica/paesi/<codice>/` e `ricerca/18-pacchetti-paese-ondata1.md`. **Criteri di fine:** ogni voce ha fonte e data; il pacchetto di ogni Paese si legge e si firma in ≤ 3 ore.

**L-5 · Traduttori medico-veterinari, uno per lingua (en, es, de dal Ciclo 6; fr, pt, nl dopo E2) · P2**
1. Partono dal catalogo italiano firmato v1 e dal **glossario clinico** (prima consegna: glossario italiano-lingua di destinazione con le frasi d'azione fisse dei 4 livelli, approvato dal veterinario locale prima di tradurre il resto).
2. Bozza automatica ammessa; **revisione umana di ogni stringa**, registrata con chi ha revisionato e quando.
3. Ritraduzione verso l'italiano dei testi SUBITO, OGGI ed Emergenze, fatta da altri, con una tabella delle differenze risolte.
4. Consegna: `lib/l10n/app_<lingua>.arb` (lo integra lo sviluppatore principale), registro di revisione in `docs/clinica/traduzioni/<lingua>.md`.

**Criteri di fine:** 100% delle stringhe tradotte e revisionate; 0 differenze di significato aperte sui testi urgenti; ICU e parametri validi (test di L-1 verde sulla lingua); il testo regge la prova di overflow.

**L-6 · Veterinario abilitato per Paese (persona reale, reclutata da Lorenzo) · P2**
Firma glossario, testi tradotti e pacchetto Paese con la versione; segnala le regole da adattare. **Criterio di fine:** documento firmato e datato in `docs/clinica/paesi/<codice>/firma-v1.md`.

**L-7 · Legale e privacy: Europa (Ciclo 6 per l'ondata 1) · P2**
- Traduzione e adattamento di informativa e condizioni per ogni Paese.
- Regole nazionali rilevanti (consumatori, contenuti sanitari veterinari, eventuali limiti alla telemedicina).
- Regno Unito: UK GDPR e rappresentante.
- Aggiornamento del registro dei trattamenti.
- Verifica dei costi EUIPO e UKIPO per C1-6.

**Consegna:** `ricerca/19-legale-europa.md`. **Criteri di fine:** documenti pronti per ogni Paese dell'ondata, con le verifiche marcate.

**L-8 · Growth e ASO: schede degli store per lingua (Ciclo 6 per l'italiano, poi per ogni ondata) · P3**
Ricerca di parole chiave nativa per lingua, titoli e sottotitoli nei limiti di caratteri degli store, schermate localizzate, proposta di prezzo per Paese. **Criteri di fine:** schede complete e controllate da un madrelingua; nessuna promessa clinica non firmata ("pensato con i veterinari" solo se vero in quel Paese).

**L-9 · QA: collaudo per lingua e Paese (a ogni ondata) · P2**
Matrice lingua × Paese × dispositivo:
- testo al 200% in tedesco (il più lungo);
- notifiche nella lingua giusta dopo un cambio di lingua;
- PDF in un'altra lingua;
- Paese non supportato;
- ripiego della lingua;
- formati di date, numeri e unità.

**Criteri di fine:** 0 difetti A; 0 testi italiani visibili in un'altra lingua; numeri d'emergenza corretti per Paese, verificati con una chiamata di prova solo se il servizio lo consente.

### 9.8 Cosa cambia per Lorenzo
- **Azione 10:** il marchio si deposita come **marchio UE all'EUIPO** (circa 850 €, DA VERIFICARE). Il tetto di spesa prima del lancio sale a 3.000 €.
- **Nuova azione, entro luglio 2027:** approvare o no il **budget dell'ondata 1** (~6.000-13.000 € stimati) al cancello E1, e reclutare un veterinario abilitato in Spagna, uno in Germania o Austria e uno anglofono (Irlanda o Regno Unito), anche tramite la propria rete di ricerca europea.
- **Nuova azione, alla scelta del nome:** verificare la disponibilità del dominio `.eu` oltre a `.it`, `.com` e `.app`.

---

## 10. Aggiornamenti del 10/11/2026 (sera)

### 10.1 Fatti nuovi
| # | Fatto | Conseguenza |
|---|---|---|
| 1 | **C1-1 completato:** backup in `~/Backups`, git, repository privato GitHub `lorebiri/zampa`, CI verde | Criterio B1 verde. Il rischio 5 (nessun controllo di versione) è chiuso |
| 2 | La copia di lavoro **resta su OneDrive CNR** (decisione di Lorenzo) | Accettata. Il backup è comunque garantito da git e GitHub |
| 3 | **Il Mac usato per Zampa è di proprietà del CNR** | Il **rischio 3** (CNR e proprietà del software) sale a **pari merito con il rischio 1**. C1-7 passa a **P0**. L'analisi deve trattare esplicitamente l'uso di un bene dell'ente (L. 633/1941 art. 12-bis, regolamenti CNR, codice di comportamento). La bozza di email al CNR deve dichiararlo con trasparenza. **Fino alla risposta del CNR: nessun ricavo, nessun contratto a pagamento negli store, nessuna società.** Per lo sviluppo: no, per ora, a imporre un cambio di computer; è una scelta di Lorenzo da prendere con l'esito di C1-7 |
| 4 | Budget: Lorenzo aveva confermato 2.500 €; il piano ora dice 3.000 € (deposito EUIPO) | Fino alla riconferma valgono **2.500 €**. Se Lorenzo non conferma i 3.000 €, il deposito UE slitta dopo il lancio: al lancio basta la domanda UIBM, e il criterio L9 si adatta |
| 5 | **C1-3 in parte:** manifest Android, sveglie esatte, tetto di 60 notifiche con priorità e test, permesso delle notifiche dopo il primo cane | Il codice è fatto. **Non è chiuso** finché C1-2 non lo verifica sul dispositivo |
| 6 | C1-2 è bloccato: il simulatore iOS è in download e **nessun emulatore Android è installato** | **Azione nuova:** installare l'emulatore Android (Android Studio o `sdkmanager` con un'immagine API 34 o 35). Lo sviluppatore principale lo può fare con il consenso di Lorenzo, perché scarica diversi GB. Il Ciclo 1 si chiude solo con la prova su almeno un iOS e un Android. Se serve, si allunga di una settimana (fino al 1° dicembre) invece di chiudere senza prova |
| 7 | Lorenzo ha chiesto due agenti "voce dell'utente" (sopra i 40 anni e sotto i 35); rapporti attesi in `ricerca/20` e `ricerca/21` | Li leggo per intero. Entrano come prove nell'audit UX (C1-9) e nel Ciclo 3. **Non** aprono nuove funzioni prima della beta: valgono le stesse regole della sezione 10.2 |

### 10.2 Decisione: "una funzione che segue il ciclo nelle cagne"

**Decisione: sì, ma dopo la beta, come miglioramento del diario esistente. Non è una funzione nuova da costruire ora.**

- **Cosa c'è già** [FATTO, dossier e `lib/logic/modules.dart`]:
  - storico di calori, accoppiamenti, parti e sterilizzazione;
  - prossimo calore stimato;
  - parto presunto a +63 giorni;
  - finestre di pseudogravidanza e piometra;
  - allarmi collegati (piometra, perdite vulvari, calore oltre 4 settimane, parto oltre 70 giorni, eclampsia).
- **La parte di sicurezza** (piometra, eclampsia, parto) è quindi **già presente e gratuita**. Va solo collaudata in beta e firmata dal veterinario con il resto.
- **Le proposte di Lorenzo sono comodità e informazione, non sicurezza.** Per la regola 3.1 non entrano prima della beta.
- **Quando:** primo ciclo dopo il lancio (M1-3, maggio-luglio 2027). Si anticipa al Ciclo 5 solo se:
  - nella beta le femmine intere sono almeno il 15% dei cani attivi;
  - **e** almeno 3 tester lo chiedono spontaneamente.
- **Cosa si farà, e con quali limiti:**
  1. **Promemoria 5-7 giorni prima del calore previsto**, con consigli pratici:
     - guinzaglio;
     - aree cani da evitare;
     - mutandine igieniche;
     - attenzione ai maschi interi;
     - "annota il primo giorno di perdite".
     - Il promemoria mostra quanto è incerta la stima, e non scatta se lo storico ha meno di 2 calori.
  2. **Fasi proestro, estro, diestro, anestro**, solo come **informazione** sui segni osservabili. **Nessun calcolo dei "giorni fertili"** né consigli per far accoppiare o per evitare una gravidanza: la fase fertile si accerta solo con esami (progesterone, citologia) dal veterinario. Indicarla nell'app crea false sicurezze, gravidanze indesiderate e accoppiamenti mal programmati.
  3. **Sterilizzazione:** informazione neutra, già presente in parte (età nelle grandi taglie, solo "parlane col veterinario"). Si aggiunge il riferimento alla piometra e ai tumori mammari come argomenti da discutere col veterinario, **senza raccomandare un'età né spingere una scelta**.
  4. Tutti i testi entrano nel catalogo clinico con ID, firmati dal veterinario. Nelle lingue europee seguono la sezione 9.3.
- **Prezzo:** gratis. Riguarda la salute riproduttiva e la piometra (regola 3.4).
- **Incarico (da assegnare al primo ciclo dopo il lancio, non ora):**
  - **veterinario-editore:** testi e soglie per i punti 1-3, con le fonti (es. Johnston, Root Kustritz e Olson, *Canine and Feline Theriogenology*);
  - **sviluppatore principale:** promemoria e scheda delle fasi nel diario Riproduzione esistente, con test.
  - **Criteri di fine:**
    - il promemoria arriva una sola volta per calore previsto;
    - non arriva con meno di 2 calori registrati, né con la cagna sterilizzata o gravida;
    - nessun testo parla di giorni fertili;
    - testi firmati;
    - QA su dispositivo superato.

### 10.3 Risposte di Lorenzo e decisioni conseguenti (10/11/2026, notte)

| # | Risposta | Decisione |
|---|---|---|
| 1 | Budget pre-lancio **confermato a 3.000 €** | Vale la 3.10. Il marchio UE si deposita all'EUIPO prima del lancio; la riga 4 di 10.1 è superata |
| 2 | Emulatore Android **approvato**, in installazione | C1-2 riparte sui due sistemi |
| 3 | Zampa **non ha attinenza** con le mansioni CNR | Fatto favorevole per la titolarità (art. 12-bis L. 633/1941). Va scritto nell'email al CNR (C1-7) |
| 4 | Lavoro **fuori orario**, ma **solo sul Mac del CNR**; nessun computer personale | Vedi 10.4 |

### 10.4 Decisione: computer personale per lo sviluppo
- **Sì. Priorità P0 per la proprietà del software**: è la misura più economica contro il rischio 3. Da qui in poi, ogni ora di lavoro su un bene dell'ente rafforza un'eventuale pretesa del CNR. Le opzioni di `ricerca/14-cnr-e-fisco.md` restano il quadro di riferimento.
- **Serve un Mac:** le build e la firma per iOS richiedono macOS. Basta un **Mac mini o un MacBook Air con chip Apple**, anche ricondizionato con garanzia, con almeno 16 GB di RAM e 256-512 GB di disco: circa 700-1.100 € [STIMA, prezzi da verificare].
- **Fuori dal tetto di 3.000 €.** È un bene personale di Lorenzo che resta suo qualunque cosa succeda a Zampa. Lo registro come **investimento personale separato, da decidere da Lorenzo**. Se in futuro nascerà un'attività, il commercialista dirà se e come ammortizzarlo.
- **Quando:** **prima della fine del Ciclo 2 (15 dicembre 2026)**, e comunque prima del primo caricamento in TestFlight. Al più tardi prima del primo euro incassato.
- **Migrazione:**
  1. clonare da GitHub `lorebiri/zampa`, che è un account personale;
  2. copia di lavoro su un disco personale, non su OneDrive CNR;
  3. account Apple, Google e Supabase creati con credenziali personali, non istituzionali;
  4. la copia su OneDrive CNR diventa solo lettura e poi si archivia, d'accordo con l'esito della risposta del CNR.
- **Lavoro già fatto sul Mac del CNR:** non si nasconde. Va dichiarato nell'email al CNR insieme a "fuori orario" e "nessuna attinenza con le mansioni" (C1-7). Lorenzo tiene un registro delle date.
- **Fino all'arrivo del nuovo computer:** si continua (la beta resta gratuita e senza ricavi), solo fuori orario. Niente dati personali di utenti reali sul Mac del CNR oltre a quelli di prova.

### 10.5 Decisione: numero del Centro Antiveleni nell'app
- **Sì, si rimette.** La verifica di C1-8 (`ricerca/15`, fonti `centroantiveleni.org` e `ospedaleniguarda.it`, consultate il 10/11/2026) conferma che il **CAV di Milano, Ospedale Niguarda, 02 6610 1029, risponde 24 ore su 24 anche per gli animali**, da tutta Italia. Non è una funzione nuova: è il ripristino di un dato di sicurezza tolto perché non verificato, quindi è compatibile con la 3.1.
- **Regole:**
  1. Solo nel **pacchetto Paese Italia**, mai mostrato con un altro Paese (9.2).
  2. Testo, con ID nel catalogo e da far firmare al veterinario (B5): «Sospetto avvelenamento: chiama subito il tuo veterinario o il pronto soccorso veterinario. Per sapere quanto è pericoloso ciò che ha ingerito puoi chiamare anche il **Centro Antiveleni di Milano (Ospedale Niguarda), 02 6610 1029, 24 ore su 24**: risponde anche per gli animali e ti chiederà nome e recapiti.» L'ordine (prima il veterinario) è voluto: il CAV consiglia, ma non cura il cane.
  3. Numero con chiamata diretta, nella scheda Emergenze e nella situazione "Ha ingerito qualcosa".
  4. Si scrive la **data di verifica** nel catalogo. Il numero si **riverifica a ogni rilascio pubblico** e almeno ogni 6 mesi; un test controlla che la data non superi i 6 mesi.
  5. Non dichiarare che è gratuito: il sito non lo dice.
- **Chi lo fa:** lo sviluppatore principale nel Ciclo 2, insieme al catalogo dei testi; il veterinario abilitato lo firma con le Emergenze.

### 10.6 Stato del Ciclo 1 (aggiornato)
| Incarico | Stato |
|---|---|
| C1-1 repository, backup, CI | ✔ Fatto |
| C1-2 QA su dispositivo | In corso: build iOS in debug; emulatore Android in installazione |
| C1-3 correzioni notifiche | Codice fatto e testato (manifest, sveglie esatte, tetto di 60 con priorità, permesso dopo il primo cane). **Manca la prova su dispositivo**: non è chiuso |
| C1-4 sicurezza backend | ✔ Fatto (`ricerca/11`, 79 test SQL). Correzioni P0 e P1 di `lib/sync` applicate: il cane di esempio non va mai online, i cani altrui vengono rimossi all'uscita, UUID, inviti generati dal server, errori espliciti. **Restano P1 per il Ciclo 2:** concorrenza ottimistica e "reset con ombra vuota". P2 e P3 nel Ciclo 2 o 3 |
| C1-5 accuratezza | In corso |
| C1-6 nome e marchio | In corso (deve tenere conto della sezione 9.4) |
| C1-7 CNR e fisco | ✔ Fatto (`ricerca/14`, bozza dell'email pronta). Lorenzo la invia **aggiungendo** i fatti 10.3-3 e 10.3-4 |
| C1-8 pacchetto per il veterinario | ✔ Fatto (`docs/clinica`, 269 testi; antiveleni verificato) |
| C1-9 audit UX | ✔ Fatto (`ricerca/16`) |
| Voci dell'utente | ✔ Fatte (`ricerca/20`, `ricerca/21`). Già corretti su main: età calcolata male, date future, data di nascita predefinita, taglia del compagno, accordo al femminile |
| Designer visivo (chiesto da Lorenzo) | In corso su un ramo separato, compresi contrasto e accessibilità di 16/20/21. **Condizioni per l'integrazione su main:** nessuna regola del compagno violata (rapporto 07, F; allarmi SUBITO sempre sopra); nessun testo clinico cambiato; contrasto WCAG AA verificato; tutti i test e l'analisi verdi; prova di QA sulle schermate principali. È rifinitura grafica di funzioni esistenti, ammessa dalla 3.1, ma non aggiunge schermate o funzioni |

**Chiusura del Ciclo 1:** resta fissata alla prova su dispositivo di C1-2 e C1-3 e alla consegna di C1-5 e C1-6. Termine massimo 1° dicembre 2026.

### 10.7 Decisione: app gratuita come scelta di partenza (10/11/2026)

**Decisione: sì, Zampa parte gratuita**, su proposta di Lorenzo. Questa sezione prevale sulla 3.4 per tutto ciò che riguarda l'attivazione del Premium.

1. **Perché.**
   - Senza incassi si riduce il rischio art. 53 e disciplinare con il CNR.
   - Si elimina la condizione "via libera fiscale" dal percorso critico del lancio.
   - Aumenta la fiducia degli utenti e dei veterinari.
   - **Restano però obbligatori:** l'email al CNR va inviata e la risposta attesa **prima di pubblicare, anche gratis**, perché la titolarità del software (Mac del CNR) resta da chiarire. Valgono anche marchio, firma del veterinario e criteri B e L.
2. **Costi:** tutti a carico di Lorenzo, nel tetto di 3.000 € (Apple 99 €/anno, Google 25 $, veterinario, privacy, marchio UE, Android di prova). Il Mac personale resta fuori dal tetto (10.4). Supabase gratuito per la beta; il piano Pro (~25 $/mese) solo quando il gratuito non basta.
3. **Promessa pubblica:** "Gratis, senza pubblicità, i dati restano sul tuo telefono".
   - **Niente di ciò che è gratis verrà mai tolto o messo a pagamento.**
   - Un eventuale "Plus" futuro conterrà **solo funzioni nuove** (es. widget avanzati, Apple Watch, archivio di foto e documenti nel cloud, PDF esteso, accessori del compagno).
   - Allarmi, emergenze, cartella, diari e previsione restano gratis per sempre (regola 3.4).
4. **Rimandati:** RevenueCat, contratti a pagamento e dati bancari negli store, Small Business Program (azione 12 di Lorenzo) e criterio L11.
5. **Donazioni ("offrimi un caffè"): no, per ora.**
   - Anche le donazioni ricorrenti possono configurare un ricavo o un'attività economica rilevante per il CNR e per il fisco.
   - Il pulsante di donazione negli store è soggetto alle regole sugli acquisti in-app [DA VERIFICARE].
   - Si rivaluta solo con la risposta scritta del CNR e il parere del commercialista.
6. **KPI e bivi:** le metriche di conversione (avvio della prova, prova → pagante, download → pagante, rinnovo) sono **sospese**. Al loro posto:
   - retention a 30 e 90 giorni (≥ 30% / ≥ 15%);
   - cani con ≥ 21 giorni di registrazioni;
   - coefficiente di invito (≥ 0,2);
   - **veterinari che consigliano l'app** (≥ 10 entro il mese 3, ≥ 30 entro il mese 6);
   - voto sugli store (≥ 4,5);
   - utilità degli allarmi (≥ 70%);
   - **disponibilità a pagare**, misurata con un sondaggio in app, opt-in, su un "Plus" descritto, senza vendere nulla: obiettivo ≥ 15% "lo pagherei 20-30 €/anno".

   Il bivio del mese 6 usa queste soglie. Con una retention a 30 giorni sotto il 15%, Zampa resta un progetto personale gratuito.
7. **Quando si rivaluta il Premium: al bivio del mese 6** (ottobre-novembre 2027), solo se valgono tutte e cinque le condizioni:
   1. risposta scritta del CNR che consente l'incasso, e regime fiscale definito con il commercialista;
   2. accuratezza dimostrata (L2 e L3);
   3. retention a 30 giorni ≥ 30%;
   4. ≥ 15% di disponibilità a pagare nel sondaggio;
   5. almeno una funzione nuova pronta per il Plus.

   Altrimenti si rivaluta al mese 12. **Effetto sulla tesi economica:** il percorso verso il milione (sezione 2) slitta di almeno 6 mesi. È un prezzo accettabile in cambio di un rischio legale molto più basso.
