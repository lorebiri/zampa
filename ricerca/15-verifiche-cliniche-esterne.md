# 15 — Verifiche cliniche esterne e pacchetto per il veterinario abilitato (incarico C1-8)

*10 novembre 2026. Autore: veterinario-editore del progetto (agente). Non sono un medico veterinario abilitato: questo lavoro prepara la revisione e la firma di un professionista iscritto all'Ordine. Nessun file in `lib/` o `test/` è stato modificato.*

## 1. Cosa è stato consegnato

| File | Contenuto |
|---|---|
| `docs/clinica/testi-clinici-v1.md` | 269 testi clinici con ID, livello, condizione di attivazione, testo esatto, fonte, file:riga, caselle di esito e note. Ordine: frasi d'azione, Emergenze, SUBITO, OGGI, ATTENZIONE, INFO, altri testi, tabelle. Stampabile |
| `docs/clinica/testi-clinici-v1.csv` | Stesse 269 righe. Colonne: ID, Livello, Gruppo, Quando scatta, Titolo, Testo esatto, Frase d'azione mostrata, Fonte, File:riga, Approvato / Modificare / Eliminare, Note del veterinario, **Note per la traduzione**. UTF-8 con BOM, separatore virgola |
| `docs/clinica/lettera-incarico-veterinario.md` | Modello di lettera d'incarico: oggetto, fasi e tempi, compenso da definire con Lorenzo, limiti di responsabilità, citazione solo con consenso, riservatezza, verifica dell'iscrizione all'Albo |
| questo rapporto | Esiti delle verifiche esterne, problemi trovati nei testi, proposta dei testi come dati |

### 1.1 Conteggio e verifica di completezza

- `lib/logic/alerts.dart` contiene **99 chiamate `add(`** che generano un avviso (le altre 4 occorrenze di `add(` sono la definizione della funzione, `out.add`, `v.add` e `seen.add`). Lo script di estrazione collega ogni scheda alla sua chiamata: **99 su 99 coperte**.
- Sei chiamate hanno due testi alternativi (feci nere, convulsioni, temperatura, «Non mangia», «Abbattuto», parto): sono divise in schede a/b. Totale: **105 schede di avviso**.
- **Ogni testo è stato confrontato in automatico con il sorgente**: lo script divide ogni testo nei pezzi fissi (esclusi i valori `{…}`) e controlla che ciascun pezzo compaia nel file indicato. Nessuna discrepanza residua.
- Lo script e i dati sono nella cartella di lavoro dell'agente, non nel progetto. Si possono rigenerare quando serve.

| Livello | Avvisi automatici | Altri testi | Totale |
|---|---|---|---|
| Frasi d'azione dei livelli | — | 4 | 4 |
| EMERGENZE (scheda + avvertenza) | — | 22 | 22 |
| SUBITO | 27 (di cui 4 a livello variabile) | 6 | 33 |
| OGGI | 36 (di cui 5 variabili) | 1 | 37 |
| ATTENZIONE | 31 | 4 | 35 |
| INFO | 11 | 73 (informativi) | 84 |
| Tabelle (alimenti 21, scale 33) | — | 54 | 54 |
| **Totale** | **105** | **164** | **269** |

Gli avvisi a livello variabile sono contati al livello più alto che possono raggiungere.

**Tempo di lettura stimato:** la parte prioritaria (frasi d'azione, Emergenze, SUBITO, OGGI) conta 96 schede brevi: 2½-3 ore. Il criterio di fine (≤ 3 ore) è rispettato.

**Non estratti, di proposito:**

- le etichette delle cause usate dentro i promemoria (`bio_params.dart`: «cistite», «diabete», «diuretico (…)»), che compaiono solo dentro PRM-002;
- i nomi degli eventi e dei segni (`models.dart`);
- i testi non clinici dell'interfaccia (account, avatar, impostazioni).

## 2. Esito delle verifiche esterne

Legenda: **confermato** = la fonte primaria dice quello che è scritto; **corretto** = il riferimento esiste ma con dati diversi; **non trovato** = la fonte primaria non lo conferma.

| # | Riferimento | Esito | Dettaglio | Fonte primaria |
|---|---|---|---|---|
| 1 | Centro antiveleni che risponde per gli animali | **Confermato** | **Centro Antiveleni di Milano (CAV), Ospedale Niguarda: 02 6610 1029**, 24 ore su 24, 7 giorni su 7. FAQ del centro: «Si, certamente, rispondiamo anche per intossicazioni negli animali». Numero contattabile da privati cittadini e da strutture ospedaliere, per tutto il territorio nazionale. Non risponde ad anonimi: chiede i dati anagrafici. Il sito non dice se la consulenza è gratuita per i privati. Il sito dell'ospedale Niguarda riporta lo stesso numero tra i numeri utili e rimanda al sito del centro | [centroantiveleni.org](https://www.centroantiveleni.org/) (consultato il 10/11/2026); [ospedaleniguarda.it — Numeri utili](https://www.ospedaleniguarda.it/servizi-al-paziente/numeri-utili) |
| 1b | Altri CAV (Pavia, Bergamo, Roma, ecc.) per animali | **Non verificato** | Non cercato sui siti dei singoli enti. Non vanno citati finché non sono verificati | — |
| 2 | D.M. sul SINAC | **Confermato** (data corretta) | **D.M. Salute 2 novembre 2023**, «Modalità tecniche e operative per l'implementazione del Sistema di identificazione nazionale degli animali da compagnia (SINAC)», GU Serie Generale n. 294 del 18/12/2023 (cod. 23A06843). Nota: il nome ufficiale è «Sistema di **identificazione** nazionale», non «Sistema informativo» come scritto in `ricerca/04:310` | [Gazzetta Ufficiale](https://www.gazzettaufficiale.it/eli/id/2023/12/18/23A06843/sg) |
| 2b | D.Lgs. 134/2022 (base del SINAC) | **Confermato da fonte secondaria** | GU n. 213 del 12/9/2022, in vigore dal 27/9/2022 (nota del Ministero della Salute). Testo in GU non aperto | [Nota Min. Salute 19/9/2022](https://www.unionalimentari.com/wp-content/uploads/2024/09/MINSALUTE-Nota-22341-del-19.09.2022-identificazione-e-registrazione.pdf) |
| 3 | Reg. (UE) 2026/131 (viaggi) | **Confermato e precisato** | È il **Regolamento delegato (UE) 2026/131 della Commissione del 20 gennaio 2026**, che integra il Reg. (UE) 2016/429 sui movimenti a carattere non commerciale di animali da compagnia. Pubblicato nella GU UE serie L il 27/3/2026. In vigore dal giorno dopo la pubblicazione. **Si applica dal 22 aprile 2026** (art. 33). Il Reg. (UE) 576/2013 si è applicato, in via transitoria, solo fino al 21 aprile 2026 (considerando 1 e 56). Requisiti confermati: antirabbica completata almeno 21 giorni prima del movimento, con rinvio all'all. VII parte 1 del Reg. delegato (UE) 2020/688 (art. 8, lett. a); deroga per i cuccioli sotto 12 settimane o tra 12 e 16 solo se lo Stato di destinazione la ammette (art. 9); trattamento Echinococcus 24-120 ore prima dell'ingresso in uno Stato o zona indenne (art. 8, lett. b). Restano validi i passaporti rilasciati prima del 22/4/2026 secondo il Reg. 577/2013 (art. 31) e gli animali identificati prima di quella data (art. 30) | [EUR-Lex, Reg. del. (UE) 2026/131](https://eur-lex.europa.eu/eli/reg_del/2026/131/oj/ita) |
| 3b | Elenco dei Paesi indenni da Echinococcus | **Non trovato** nel Reg. 2026/131 | Il regolamento non elenca i Paesi: rinvia ad altri atti. L'elenco dell'app («Regno Unito, Irlanda, Finlandia, Norvegia e Malta») non è verificato. Il Regno Unito non è nell'UE e applica regole proprie | — |
| 3c | Età minima 12 settimane, microchip prima del vaccino | **Da ricontrollare** | Il Reg. 2020/688 (all. VII, parte 1, testo originale) rinvia ai requisiti di validità dell'allegato III del Reg. 576/2013, dove si trovavano queste regole. Non ho verificato se il testo consolidato del 2020/688 sia stato modificato nel 2026 | [EUR-Lex, Reg. del. (UE) 2020/688](https://eur-lex.europa.eu/eli/reg_del/2020/688/oj/ita) |
| 4 | D.Lgs. 218/2023 | **Confermato; pertinente solo in modo indiretto** | D.Lgs. 7 dicembre 2023, n. 218: adeguamento della normativa nazionale al Reg. (UE) 2019/6 sui **medicinali veterinari**. GU Serie Generale n. 2 del 3/1/2024, in vigore dal 18/1/2024. L'app non lo cita. Riguarda i testi che vietano di dare farmaci per persone o di cambiare terapie di propria iniziativa, che vanno nella stessa direzione: scelta e uso dei farmaci restano al veterinario. Sarà pertinente se l'app gestirà ricette o promemoria legati alla ricetta elettronica veterinaria | [Gazzetta Ufficiale](https://www.gazzettaufficiale.it/eli/id/2024/01/03/23G00225/sg) |
| 5 | Porciello et al. 2016 (respiri nel sonno), «rivista e pagine da verificare» (07) | **Corretto** | Porciello F, Rishniw M, Ljungvall I, Ferasin L, Häggström J, Ohad DG. *Vet J* 2016;207:164-168 (online 2015). [doi:10.1016/j.tvjl.2015.08.017](https://doi.org/10.1016/j.tvjl.2015.08.017) | PubMed 26639825 |
| 6 | ACVIM 2019, Keene et al., *JVIM* 33:1127 | **Confermato** | *J Vet Intern Med* 2019;33(3):1127-1140. [doi:10.1111/jvim.15488](https://doi.org/10.1111/jvim.15488) | PubMed 30974015 |
| 7 | Hall E.J. et al., «cool first, transport second», «rivista e anno da verificare» (07) | **Corretto** | Il principio è attribuito da Hall et al. a linee guida del 2016 per la gestione pre-ospedaliera; quelle linee guida non le ho identificate. Fonti citabili: Hall EJ et al. *Vet Sci* 2023;10(7):465, [doi:10.3390/vetsci10070465](https://doi.org/10.3390/vetsci10070465) (richiama le linee guida 2016: immersione in acqua fredda o raffreddamento per evaporazione; nota che il metodo più usato, gli asciugamani bagnati, non è tra quelli raccomandati); Carter AJ et al. *J Therm Biol* 2024;121:103827, [doi:10.1016/j.jtherbio.2024.103827](https://doi.org/10.1016/j.jtherbio.2024.103827) (sostiene il messaggio «cool first, transport second»). Gli autori sono del Royal Veterinary College e della Nottingham Trent University | PubMed 37505869, 38518416 |
| 8 | Bruchim Y. et al., *JVECC* 2017;27:1-11 (citato in 07, N36) | **Non trovato come citato; corretto** | Non esiste un articolo di Bruchim su *JVECC* 2017 alle pagine 1-11. Su *JVECC* 2017 c'è Bruchim et al. 27(3):315-324, sulle alterazioni dell'emostasi, che non tratta il raffreddamento. La rassegna pertinente è: Bruchim Y, Horowitz M, Aroch I. *Temperature (Austin)* 2017;4(4):356-370, [doi:10.1080/23328940.2017.1367457](https://doi.org/10.1080/23328940.2017.1367457) | PubMed 28273401, 29435477 |
| 9 | «Il 74% dei colpi di calore avviene durante lo sforzo» (STG-003) | **Confermato, con un limite** | 74,2% degli episodi, cani in cura primaria nel **Regno Unito**, 2016: Hall EJ, Carter AJ, O'Neill DG. *Animals* 2020;10(8):1324, [doi:10.3390/ani10081324](https://doi.org/10.3390/ani10081324) | PubMed 32751913 |
| 10 | Hart et al. 2020 (età della sterilizzazione, RAZ-012) | **Confermato** | Hart BL et al. *Front Vet Sci* 2020;7:388, [doi:10.3389/fvets.2020.00388](https://doi.org/10.3389/fvets.2020.00388) | PubMed 32733924 |
| 11 | IVETF 2015 (convulsioni oltre 5 minuti, crisi a grappolo) | **Confermato** (riferimento) | Berendt M et al. *BMC Vet Res* 2015;11:182, [doi:10.1186/s12917-015-0461-2](https://doi.org/10.1186/s12917-015-0461-2). Le soglie esatte (5 minuti, 2 crisi in 24 ore) le deve confermare il revisore | PubMed 26316133 |
| 12 | Iscrizione all'Albo dei veterinari | **Confermato** (strumento) | Il sito FNOVI ha la funzione «Ricerca iscritti». L'Albo è tenuto dagli Ordini provinciali | [fnovi.it — Ricerca iscritti](https://fnovi.it/popular/ricerca-iscritti) |
| 13 | L. 281/1991 e O.M. 6/8/2008 (PRV-001) | **Non verificato** in questo ciclo | Non era nell'elenco richiesto. Da controllare: l'O.M. 6/8/2008 era un'ordinanza a termine, prorogata più volte, quindi va confermato che sia ancora in vigore. In alternativa si può citare il D.M. 2/11/2023 | — |

Ho consultato le fonti PubMed con lo strumento di ricerca PubMed. I DOI sono indicati accanto a ogni voce.

## 3. Problemi trovati nei testi

Non ho modificato i testi né le soglie. Le correzioni proposte vanno decise dal veterinario abilitato o, per le norme, dal CEO.

### 3.1 Da correggere prima del rilascio

1. **VIA-004 cita una norma superata** (`lib/logic/modules.dart:193`): «Regole UE: Reg. (UE) 576/2013 e successive modifiche».
   - Dal 22/4/2026 i viaggi sono regolati dal Reg. (UE) 2016/429 e dal Reg. delegato (UE) 2026/131.
   - Proposta: «Regole UE: Reg. (UE) 2016/429 e Reg. delegato (UE) 2026/131, in vigore dal 22 aprile 2026; i passaporti rilasciati prima restano validi. Verifica prima di partire sul sito del Ministero della Salute.»
2. **VIA-005, elenco dei Paesi per l'Echinococcus non verificato** (`modules.dart:200`).
   - Il Regno Unito ha regole proprie (non UE).
   - Proposta prudente: «Obbligatorio 24-120 ore prima dell'ingresso nei Paesi indenni (verifica l'elenco aggiornato con il veterinario).» Oppure verificare l'elenco sull'atto UE vigente.
3. **EMG-019, numero del centro antiveleni.**
   - Oggi la scheda non mostra numeri, il che è corretto finché non c'è una verifica. Ora la verifica c'è: CAV di Milano, 02 6610 1029, h24, risponde anche per gli animali.
   - Proposta da sottoporre al revisore e al CEO: «Centro Antiveleni di Milano (Ospedale Niguarda): 02 6610 1029, 24 ore su 24. Risponde anche per gli animali. Ti chiederanno nome e recapiti.»
   - Restano da chiarire eventuali costi per i privati, che il sito non indica. Ricontrollare il numero a ogni versione: data di verifica nel pacchetto Paese.
4. **Frase d'azione in contrasto con il testo in alcuni avvisi SUBITO.**
   - Avvisi: ALR-TOX-001 (ingestione), ALR-DIA-002 (glicemia bassa), ALR-DIA-005 (doppia insulina), ALR-FAR-001 (Cushing), ALR-FAR-004 (vomito con FANS/cortisone), ALR-GI-007a (feci nere con FANS).
   - Il testo dice «chiama subito», ma sotto compare la frase fissa del livello: «Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte».
   - Per l'ingestione l'indicazione corretta è chiamare prima: il veterinario o il centro antiveleni dice se e dove andare.
   - Proposta: frase d'azione specifica, es. «Chiama subito il veterinario; se non risponde, vai al pronto soccorso veterinario.»
5. **ALR-URI-006 può essere SUBITO senza frase d'azione.**
   - Succede nel maschio con sforzo registrato tra 12 e 24 ore prima: il livello sale a SUBITO, ma la frase d'azione è disattivata.
   - Il testo resta condizionale («se prova a urinare senza riuscirci…»).
   - Proposta: nel caso SUBITO usare il testo di ALR-URI-001 o una frase d'azione esplicita.

### 3.2 Da far valutare al revisore

6. **ALR-RES-002, gengive rosso scuro.** L'istruzione «raffreddalo con acqua» è data senza condizioni. Il testo stesso cita anche lo shock, dove raffreddare non è indicato. Proposta: «Se ha preso caldo o ha fatto sforzi, raffreddalo con acqua (vedi Emergenze); in ogni caso vai subito dal veterinario.»
7. **ALR-ALT-006, forasacco.** Da maggio ad agosto scatta OGGI con un qualsiasi starnuto registrato. Il testo invece parla di starnuti «all'improvviso dopo un prato». La condizione è più larga del testo: rischio di falsi allarmi.
8. **ALR-REP-008, perdite vulvari.** Il livello OGGI scatta solo nella femmina **sterilizzata** con perdite purulente, perché la non sterilizzata va in ALR-REP-007. Il testo però parla di «calore», che in una sterilizzata non c'è. Va valutato un testo specifico (possibile piometra del moncone o vaginite).
9. **ALR-URI-008, sangue durante il calore.** Livello INFO con la frase «Parlane alla prossima visita». Il testo invece invita a sentire il veterinario in alcune condizioni. Le due indicazioni vanno armonizzate.
10. **ALR-PES-007, sovrappeso.** Scatta anche nei cuccioli, mentre «Sottopeso» solo da 12 mesi. Va deciso se è voluto.
11. **TOS-004, cipolla e aglio.** «Alterazioni del sangue da circa 5 g/kg»: le fonti divulgative danno soglie diverse (circa 0,5% del peso corporeo, oppure 15-30 g/kg). Il revisore scelga il valore e la fonte.
12. **MET-002, avviso caldo.** Le soglie di 24 °C e 27 °C di temperatura percepita, l'umidità al 70% e la regola dei 7 secondi sull'asfalto non hanno una fonte nel codice. Vanno validate o presentate come prudenziali.
13. **STG-003.** Il 74% è un dato britannico (Hall 2020). Proposta: «Nel Regno Unito circa 3 colpi di calore su 4 avvengono durante lo sforzo.»
14. **PRV-001.** Citazione normativa (L. 281/1991, O.M. 6/8/2008): verificare che l'O.M. sia ancora in vigore. Valutare di citare il D.M. 2/11/2023. I tempi di iscrizione (60 giorni) possono variare per Regione: sul punto serve un parere legale, oltre a quello veterinario.
15. **Fonti citate nella documentazione** (`ricerca/04`, `ricerca/07`).
    - Correggere «Sistema Informativo» in «Sistema di identificazione nazionale» per il SINAC.
    - Correggere le citazioni di Porciello e Bruchim e completare quella di Hall (§2, righe 5, 7, 8).

### 3.3 Osservazioni tecniche (per lo sviluppatore, nessuna modifica fatta)

- **Avvisi duplicati eliminati in base al titolo** (`alerts.dart:1522-1523`). I titoli contengono numeri (es. «Calo di peso del 12%»), quindi il controllo funziona per caso. Con le traduzioni smetterebbe di funzionare. Conviene eliminare i duplicati in base all'ID (vedi §4).
- **Testi composti a pezzi**, con concatenazioni e frasi condizionali dentro la frase: ALR-URI-006, ALR-URI-015, ALR-REP-002, ALR-CIB-003a, MET-002. Non sono traducibili così come sono: servono frasi intere per variante (§4).

## 4. Proposta: i testi clinici come dati versionati

Obiettivo: ogni testo clinico ha un ID, una versione e uno stato di revisione. Il codice usa solo l'ID, mai il testo. Si allinea agli incarichi L-1 e L-2 del piano (`ricerca/08`, §9.7).

### 4.1 Due livelli: catalogo clinico e stringhe

1. **Catalogo clinico** (`assets/clinical/catalog.v1.yaml` oppure una tabella in `docs/clinica/`): **una riga per ID**, con i metadati che servono al veterinario e ai test.

```yaml
- id: ALR-URI-001
  rev: 1                      # cresce a ogni modifica del testo italiano
  level: subito               # subito | oggi | attenzione | info | variabile
  levels: [subito]            # se variabile: tutti i livelli possibili
  scope: fisiologico          # fisiologico (vale ovunque) | paese
  trigger: "Maschio con ≥ 1 pipì con sforzo o gocce nelle ultime 12 ore"
  thresholds: {strain_male_h: 12}
  sources: ["ricerca/04 §4", "ricerca/06"]
  action: default             # default | none | <ID di una frase d'azione specifica>
  text_hash_it: "sha256:…"    # impronta del titolo e del testo italiano approvati
  review:
    status: approvato         # bozza | da_rivedere | approvato | da_modificare | eliminato
    by: "Dott.ssa …"          # solo se c'è il consenso alla citazione
    date: 2026-11-xx
    signed_doc: docs/clinica/firme/v1.pdf
  translations:
    en: {status: da_tradurre}
  translator_notes: "«Pronto soccorso veterinario»: servizio diverso per Paese."
```

2. **Stringhe** (`lib/l10n/app_it.arb`, come previsto da L-1): le chiavi ARB derivano dall'ID, ad esempio `alrUri001Title` e `alrUri001Body`, perché le chiavi devono essere nomi Dart validi. Ogni voce ha un `@description` con ID, livello, revisione e fonte. I parametri sono ICU: `{name}`, `{hours, plural, …}`, i numeri formattati con `intl` (virgola o punto secondo la lingua).

### 4.2 Regole

1. **Una frase intera per variante.** Le schede a/b e le parti condizionali diventano chiavi separate o messaggi ICU `select` (es. `{hasNote, select, true{: {note}} other{}}`). Niente frasi composte a pezzi nel codice.
2. **Frase d'azione come dato.** Il campo `action` ammette la frase del livello, nessuna frase, oppure l'ID di una frase specifica (es. `ACT-CALL-FIRST` per «Chiama subito…»). Risolve i problemi 4 e 5 del §3.1.
3. **ID nel `HealthAlert`.** `HealthAlert` porta un `id` e i parametri. I duplicati si eliminano in base all'ID. L'ordine resta per livello e priorità clinica.
4. **Blocco in CI sui testi non rivisti.** Un test calcola l'impronta (hash) del testo italiano di ogni ID e la confronta con `text_hash_it` del catalogo. Se il testo cambia senza nuova revisione, il test fallisce, oppure segna la voce `da_rivedere` e impedisce la build di rilascio.
5. **Test di copertura.**
   - Ogni ID usato nel codice esiste nel catalogo e nell'ARB, e viceversa.
   - Ogni regola di `alerts.dart` ha almeno un caso di test che la attiva.
   - È lo stesso controllo «99 su 99» fatto qui, reso automatico.
6. **Ambito: fisiologico o Paese** (regola 9.2 del piano).
   - Sono di ambito «paese»: PRV-*, VIA-*, EMG-019 (centro antiveleni), PRV-001/002 (anagrafe), STG-007 (zone delle zecche), PRV-010…015 (zone ESCCAP).
   - Vanno nel `CountryPack`, con fonte e **data di validità**. Esempio: numero del CAV verificato il 10/11/2026, da ricontrollare entro 12 mesi.
   - Gli avvisi fisiologici restano attivi in ogni Paese.
7. **Versione clinica nell'app.** Una costante `clinicalTextsVersion = "v1"` compare in Impostazioni › Informazioni. Se c'è il consenso, compare anche la riga «Testi rivisti da … il …» (lettera d'incarico, §7). Il PDF per il veterinario riporta la versione.
8. **Registro delle firme.** `docs/clinica/firme/` contiene il documento firmato per ogni versione e un `approvazioni.csv` (ID, rev, esito, data, revisore). La v1.1 nasce applicando le modifiche richieste. Una breve verifica finale del revisore chiude il ciclo.

### 4.3 Ordine di lavoro proposto per il Ciclo 2

1. Raccogliere la firma sulla v1 (fase A della lettera).
2. Creare il catalogo dagli stessi dati di questo documento: gli ID coincidono.
3. Fare l'istantanea dei testi attuali (test d'identità di L-1).
4. Spostare i testi nell'ARB e nel catalogo, senza cambiare né testi né comportamento.
5. Applicare le modifiche approvate dal veterinario come v1.1, con un nuovo hash per ogni voce modificata.

## 5. Cosa resta aperto

- Firma di un veterinario abilitato: nessuna voce del catalogo è approvata finché non c'è.
- Altri centri antiveleni per gli animali, se si vogliono numeri alternativi: da verificare sui siti degli enti.
- Elenco UE dei Paesi indenni da Echinococcus e regole di validità della vaccinazione antirabbica nel testo consolidato del Reg. 2020/688 (§2, righe 3b e 3c).
- Stato dell'O.M. 6/8/2008 (§2, riga 13).
- Revisione legale della lettera d'incarico (manleva, cessione dei diritti, privacy).
