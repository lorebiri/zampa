# 23 — Previsione di base sul banco realistico, correzioni R1-R7 in ombra, protocollo v1.1

*11 novembre 2026. Autore: data scientist del progetto. Incarichi C2-3(a) e «R1-R7 sul modello in ombra» di `ricerca/08-piano-ceo.md` §11.3 e §11.5, più le correzioni A1, A2, A3 e A10 della terza revisione veterinaria (`ricerca/26`), aggiunte dal coordinatore.*

Convenzioni come in `ricerca/12`: **[MISURATO]** = numero del banco di prova (simulazione, non cani veri); **[STIMA]** = giudizio. Tra parentesi quadre l'IC 95% bootstrap per cane. R = Σ<sub>cani</sub> errore mediano / Σ<sub>cani</sub> errore mediano del riferimento: sotto 1 vuol dire meglio del riferimento. «Errore con segno» = evento vero − previsione: negativo vuol dire previsione **in ritardo** (il verso pericoloso).

---

## 0. Sintesi

1. **La previsione di base, così come era in main, non raggiungeva i valori attesi.** Sul banco realistico: R/timer **1,15** [1,05–1,25], copertura della finestra **37%**, e la prima pipì del mattino era prevista in media **6 ore prima** (l'orario atteso cadeva nel sonno). Il fattore biologico contava due volte la taglia e le malattie note (cronici: R 2,06). [MISURATO, `risultati/base0_*.txt`]
2. **Ho corretto la previsione di base dentro `Baseline` e `forecast`, senza toccare tetti e logica della notte** (§2.2). Dopo le correzioni, banco realistico: R/timer **0,92** [0,85–0,98], migliore nei cani a orari decisi dal padrone (**0,86** nel realistico, **0,37** nello scenario dedicato, alla pari con «stesso orario»), copertura della finestra **74%** [71–77%] (prima di A1), ritardo con poliuria in corso da 4 giorni **+5 min** (non in ritardo). In tutti gli scenari R/timer tra 0,37 e 0,93, copertura tra 74% e 86%. Dopo le correzioni veterinarie A1 (§5) i numeri restano quasi uguali: realistico **0,92** [0,86–0,99] e copertura **73%** [70–76%]. [MISURATO, `risultati/base_*.txt` e `basefin_*.txt`, §2.3-2.4]
3. **Unico valore atteso mancato di poco:** la copertura della finestra nel realistico (73%, IC 70-76%, soglia 75%); negli altri 7 scenari 76-85%. Ampiezza mediana della finestra: circa 7 ore nel realistico (registrazioni mancanti), 1 ora con orari decisi dal padrone.
4. **Modello in ombra, R1-R7 nell'ordine di `ricerca/12` §6.** Sul banco realistico R/timer passa da **1,02** a **0,91** [0,87–0,96], la copertura all'80% da **67%** a **71%**, il ritardo con la poliuria da **−42** a **0** min (scenario poliuria). Le correzioni che contano sono R1 (inneschi attesi), R2 (uscita abituale) e R4 (calibrazione fuori campione); R5 **non** migliora la calibrazione della prossima ora. [MISURATO, §3]
5. **Collaudo d'ingresso (§11.3 punto 3): non superato.** R/timer 0,91 (soglia 0,85), R/«stesso orario» 1,07 (soglia 1,00), copertura all'80% 71% (soglia 75-88%), fascia 60-80% della probabilità oraria −20 punti (soglia ±10); verdi solo T14 (poliuria) e T15 (tetto) (§3.3). Sul banco il modello corretto è alla pari con la previsione di base (0,91 contro 0,92). Non riaccendo il modello nell'interfaccia: la decisione è del CEO.
6. **Protocollo v1.1** (§4): una sola modifica, il modello è valutato in ombra accanto ai riferimenti e alla previsione mostrata, con il registro prequenziale R6. Soglie invariate.
7. **Correzioni veterinarie A1, A2, A3, A10** fatte in un commit separato, con test (§5).

---

## 1. Cosa ho fatto e come riprodurlo

| File | Cosa fa |
|---|---|
| `ricerca/analisi/banco2.dart` | Banco v2 (parte di `banco.dart`): valuta con origine onesta, una sola volta per evento, la **previsione mostrata** (`expectedAt`, finestra `windowStart`-`windowEnd`) e il **modello in ombra** (`Forecast.shadow`: quantili 10-25-50-75-90 calibrati); eventi e griglia oraria in ordine di tempo con il registro R6; controllo T1 (log futuri) e T15 (tetto) a ogni previsione |
| `ricerca/analisi/v2_shard{0..3}_test.dart`, `v2_unisci_test.dart`, `risultati/lavori.json` | Esecuzione in 4 frammenti paralleli (`-j 4`) e riepilogo con bootstrap per cane |
| `ricerca/analisi/diag_base_test.dart`, `diag_tetto_test.dart` | Diagnosi su singoli eventi (previsione di base, tetto) |
| `risultati/base0_*` | Previsione di base com'era in main (prima delle correzioni) |
| `risultati/base_*` | Previsione di base corretta, tutti gli eventi, 9 scenari (prima di A1) |
| `risultati/R0_*` … `R7_*` | Modello in ombra prima e dopo ogni correzione (righe «BASE» e «OMBRA») |
| `test/banco/` | T1-T18 portati in `test/` con il tag `banco` (§3.4) |

Esecuzione: scrivere i lavori in `risultati/lavori.json`, poi `flutter test -j 4 ricerca/analisi/v2_shard*_test.dart` e `flutter test ricerca/analisi/v2_unisci_test.dart`. Senza modello (`"shadow": false`) i 9 scenari della previsione di base richiedono circa 10 minuti; con il modello in ombra, realistico completo con griglia più 7 scenari con un evento su tre, circa 45 minuti sulla macchina condivisa.

`EliminationModel.fit(..., shadow: false)` salta l'addestramento del modello: la previsione mostrata non ne dipende e costa pochi millisecondi. Il banco è lo stesso di `ricerca/12` (32 cani, 4 settimane, 8 scenari); è cambiato solo ciò che si valuta.

---

## 2. Previsione di base (C2-3a)

### 2.1 Com'era in main [MISURATO, `base0_*`]

| Scenario | R/timer | R/«stesso orario» | Copertura finestra 20-80 | Errore con segno |
|---|---|---|---|---|
| Realistico | **1,15** [1,05–1,25] | 1,35 | **37%** | +59 |
| — orari decisi dal padrone | 1,09 | 1,46 | 31% | +53 |
| — prima pipì del mattino | **2,40** | 2,39 | **4%** | **+350** |
| — cronico dichiarato (3 cani) | **2,06** | 2,12 | 22% | +179 |
| Pulito | 1,45 | 2,26 | 45% | +44 |
| Orari decisi dal padrone | 1,42 | 4,26 | 46% | +15 |
| Poliuria | 0,66 | 1,34 | 55% | +8 (≥ 4 giorni: +6) |

Tre difetti, tutti diagnosticati su singoli eventi:
- **Orario atteso nel sonno.** Ultima pipì alle 22, intervallo 4,5 h: l'orario atteso era alle 2:30. Il promemoria passava al mattino per la logica della notte, ma l'orario «più probabile» no. È il +350 min della prima pipì.
- **Fattore biologico contato due volte.** Il diabete (0,4) e la taglia piccola (0,85) erano già dentro gli intervalli misurati del cane e venivano applicati di nuovo. È lo stesso difetto A1 trovato dal veterinario (`ricerca/26` §1.2).
- **Finestra troppo stretta.** Il 20°-80° percentile degli intervalli passati, nominale 60%, conteneva il 37% delle pipì: il ritmo del cane cambia e le pipì non registrate allungano gli intervalli.

### 2.2 Correzioni (commit `fa99a99`, poi A1 nel commit `cbf4a0b`)

Nessuna tocca tetti (`maxDay`, `maxNight`, minimi 120/180 min), logica della notte, prudenza o testi clinici.

| # | Correzione | Dove |
|---|---|---|
| B1 | **Mattino.** Se l'orario atteso cade nel sonno, la prossima pipì è la prima del mattino: mediana delle prime uscite dopo la notte negli ultimi 14 giorni, feriali e fine settimana separati (almeno 3 giorni dello stesso tipo, altrimenti tutti); senza dati, risveglio del profilo + picco | `Baseline.usualFirst`, `_basePoint` |
| B2 | **Fattore biologico solo per ciò che è cambiato.** Prima versione: rapporto tra il fattore di adesso e quello tipico degli intervalli osservati. Sostituita da A1 (§5): con dati misurati accorciano solo i farmaci iniziati da meno di 14 giorni e la finestra dopo il diuretico, mai sotto 0,5 | `_basePoint` |
| B3 | **Orario atteso all'orario abituale.** Se il prossimo orario abituale cade entro 1,5 intervalli, l'orario atteso è quello (non quando l'intervallo si è appena accorciato per la poliuria). Il promemoria resta anticipato dall'orario abituale solo se cade prima, come prima | `_basePoint` |
| B4 | **Finestra empirica.** Per ciascuna pipì degli ultimi 14 giorni si rifà la previsione di base 1 minuto dopo la pipì precedente, con i soli dati di allora, e si misura lo scarto. Finestra = orario atteso + 7,5° e 92,5° percentile degli scarti (separati per le previsioni del mattino se ce ne sono almeno 6; servono almeno 8 scarti, altrimenti 10°-90° degli intervalli). È onesta per costruzione: guarda solo indietro | `_empiricalWindow` |

Ho provato e scartato: finestra 10°-90° e 5°-95° degli intervalli (copertura nel realistico 63% e 67%, con finestre già di 5 ore); il 10°-90° degli scarti (70%, sotto soglia).

### 2.3 Risultati dopo le correzioni [MISURATO]

Tutti gli eventi, 32 cani, previsione di base corretta prima di A1 (`base_*.txt`):

| Scenario | Errore (min) | Timer | «Stesso orario» | **R/timer** | R/«stesso orario» | **Copertura finestra** | Ampiezza (min) | Errore con segno |
|---|---|---|---|---|---|---|---|---|
| **Realistico** | 77 | 84 | 72 | **0,92** [0,85–0,98] | 1,08 | **74%** [71–77] | 422 | +13 |
| — orari decisi dal padrone | 77 | 89 | 65 | **0,86** [0,76–0,95] | 1,15 | 70% | 399 | +13 |
| — a richiesta | 77 | 82 | 75 | 0,99 | 1,01 | 78% | 433 | +13 |
| — prima pipì del mattino | 75 | 87 | 105 | 1,11 | 1,11 | 53% | 451 | +13 |
| — poliuria in corso (3 cani) | 105 | 116 | 110 | 0,95 | 1,11 | 66% | 464 | −9 |
| — cronico dichiarato (3 cani) | 87 | 86 | 89 | 1,12 | 1,15 | 81% | 532 | +15 |
| Pulito | 41 | 53 | 33 | 0,88 | 1,36 | 80% | 315 | +8 |
| Pipì mancanti | 62 | 75 | 58 | 0,93 | 1,08 | 76% | 480 | +11 |
| Orari ±10 min | 43 | 54 | 34 | 0,92 | 1,44 | 80% | 330 | +8 |
| **Orari decisi dal padrone** | 14 | 39 | 14 | **0,37** [0,33–0,40] | 1,09 | 78% | 57 | −3 |
| Fine settimana | 44 | 56 | 43 | 0,86 | 1,16 | 81% | 308 | +9 |
| Cambio di routine | 56 | 71 | 41 | 0,85 | 1,41 | 78% | 316 | +3 |
| **Poliuria** | 34 | 65 | 35 | **0,52** | 1,05 | 86% | 282 | −1 |
| Poliuria, da ≥ 4 giorni | | | | | | | | **0** (n = 2.743) |

Confronto con gli attesi di §11.5 (C2-3):

| Atteso | Misurato | Esito |
|---|---|---|
| R ≈ 1 o meglio contro il timer | 0,92 realistico; 0,37-0,93 negli scenari | ✔ |
| Migliore nei cani a orari decisi dal padrone | 0,86 contro 0,99 nel realistico; 0,37 nello scenario | ✔ |
| Copertura della finestra 75-88% | 74% realistico (73% dopo A1); 76-86% negli altri | **≈** (manca di 1-2 punti nel realistico) |
| Ritardo con poliuria ≤ 20 min | 0 min (≥ 4 giorni, scenario poliuria); +5 nel realistico | ✔ |
| Tetto (T15) | rispettato in tutti gli eventi, in tutti gli scenari | ✔ |

Dopo A1 (§5) i numeri finali sono in §2.4.

**Limiti della previsione di base.**
- **Finestra larga** dove le registrazioni mancano: 7 ore nel realistico, 1 ora con orari fissi. È onesta (contiene davvero 3 pipì su 4), ma per un adulto a richiesta dice poco. Il modello in ombra non fa meglio (§3).
- **Prima pipì del mattino** nel realistico: il risveglio del profilo è arrotondato all'ora e l'uscita consigliata resta «risveglio + picco» (logica della notte invariata). L'orario atteso usa l'abitudine del mattino, ma la finestra copre il 53%.
- **Cacca** (`base_realistico_cacca.txt`): l'orario abituale sbaglia di 5 ore in mediana e il timer di 1,8. Non è una previsione e non va presentata come tale (11.3: solo «di solito dopo colazione / dopo cena»).

### 2.4 Riepilogo finale (dopo A1) [MISURATO]

Tutti gli eventi, 32 cani, codice finale (previsione di base con A1), `risultati/basefin_*.txt`. È la previsione che l'utente vede.

| Scenario | Errore (min) | Timer | «Stesso orario» | **R/timer** | R/«stesso orario» | **Copertura finestra** | Ampiezza (min) | Errore con segno | T15 |
|---|---|---|---|---|---|---|---|---|---|
| **Realistico** | 77 | 84 | 72 | **0,92** [0,86–0,99] | 1,08 | **73%** [70–76] | 415 | +13 | 2.636/2.636 |
| — orari decisi dal padrone | 77 | 89 | 65 | **0,86** [0,76–0,95] | 1,16 | 69% | 394 | +13 | |
| — a richiesta | 77 | 82 | 75 | 0,99 | 1,01 | 77% | 428 | +13 | |
| — prima pipì del mattino | 77 | 87 | 105 | 1,13 | 1,12 | 50% | 414 | +12 | |
| — poliuria in corso (3 cani) | 105 | 116 | 110 | 0,95 | 1,11 | 66% | 464 | −9 | |
| — cronico dichiarato (3 cani) | 87 | 86 | 89 | 1,12 | 1,15 | 81% | 532 | +15 | |
| Pulito | 41 | 53 | 33 | 0,88 | 1,36 | 79% | 311 | +8 | ✔ |
| Pipì mancanti | 62 | 75 | 58 | 0,93 | 1,08 | 76% | 479 | +11 | ✔ |
| Orari ±10 min | 43 | 54 | 34 | 0,93 | 1,44 | 80% | 327 | +8 | ✔ |
| **Orari decisi dal padrone** | 14 | 39 | 14 | **0,37** [0,33–0,40] | 1,10 | 78% | 56 | −3 | ✔ |
| Fine settimana | 44 | 56 | 43 | 0,86 | 1,15 | 81% | 308 | +9 | ✔ |
| Cambio di routine | 57 | 71 | 41 | 0,85 | 1,42 | 77% | 311 | +3 | ✔ |
| **Poliuria** | 34 | 65 | 35 | **0,52** | 1,05 | 85% | 280 | −1; da ≥ 4 giorni **0** | ✔ |
| Cacca, realistico (descrittivo) | 318 | 106 | 110 | 2,97 | 2,69 | 11% | 75 | +169 | — |

Rispetto alla tabella §2.3, A1 cambia poco sul banco: i cani piccoli del banco sono adulti sani senza farmaci, e per i cronici la correzione B2 dava già k = 1. Il cambiamento conta nei cani con farmaci appena iniziati (k < 1 per 14 giorni) e nei tetti dei cani piccoli, che non si accorciano più.

**Esito per C2-3(a):** R ≈ 1 o meglio contro il timer ✔ (0,92); migliore con gli orari del padrone ✔ (0,86 e 0,37); copertura 75-88% ✔ in 7 scenari su 8, **73% nel realistico** (IC 70-76%) ≈; ritardo con poliuria ≤ 20 min ✔ (0 e +5); tetto ✔ ovunque.

---

## 3. Modello in ombra: R1-R7

### 3.1 Cosa ho fatto, nell'ordine di `ricerca/12` §6

| # | Correzione | Commit |
|---|---|---|
| R1 | **Inneschi futuri attesi.** In addestramento gli inneschi sono quelli noti all'ultimo evento (prima: anche quelli successivi), più pasti, acqua, gioco e passeggiate attesi agli orari abituali (14 giorni; contano solo dopo il momento della previsione e se non ne è stato registrato uno nei 90 minuti prima) | `969bbc9` |
| R2 | **Covariata «uscita abituale»** (17ª): vicinanza (kernel di 30 min) agli orari ricorrenti delle uscite, calcolati per ogni giorno solo sui 14 giorni precedenti, feriali e fine settimana separati | `c354332` |
| R3 | **Risveglio appreso** per giorno (risvegli registrati o prima pipì − 15 min, 14 giorni, stesso tipo di giorno, entro ±3 h dal profilo): risvegli attesi, covariata del sonno, previsione del mattino. Solo dentro il modello | `59d91b9` |
| R4 + R6 | **R6:** `ShadowRecord` registra la previsione in ombra fatta dopo ogni evento; `accuracy()` diventa fuori campione. **R4:** ricalibrazione per PIT (Kuleshov 2018): la ripartizione empirica G dei PIT fuori campione corregge l'intera distribuzione (quantile mostrato = quantile grezzo G⁻¹(p)); con meno di 5 eventi, allargamento ×1,2 in scala log | `b3c5bd3` |
| R5 | **Probabilità nella prossima ora** con la stessa G; mai oltre il 90% | `e4eee90` |
| R7 | **Adattamento rapido**: se la mediana degli intervalli degli ultimi 3 giorni è < 0,7× o > 1,4× quella dei 14 giorni, emivita a 3 giorni | ``e4df51a`` |

R6 è prerequisito di R4 e sta nello stesso commit. La persistenza del registro (`store.dart`) **non** l'ho fatta: è dello sviluppatore principale (§6). Nel banco il registro è tenuto dal banco stesso.

### 3.2 Risultati dopo ciascuna correzione [MISURATO]

Banco realistico, tutti gli eventi (2.636), modello in ombra:

| | R/timer | R/«stesso orario» | Copertura 80% | Copertura 50% | PIT < 0,1 / > 0,9 | Errore con segno | Cani che battono il timer | Brier skill | Fascia peggiore (n ≥ 50) |
|---|---|---|---|---|---|---|---|---|---|
| R0 (com'era) | 1,02 [0,98–1,06] | 1,20 | 67% | 41% | 15% / 18% | −17 | 44% | −0,03 | 0-10%: +9 |
| R1 | 0,98 [0,95–1,01] | 1,15 | 66% | 41% | 15% / 19% | −13 | 44% | −0,04 | 60-80%: −10 |
| R2 | 0,89 [0,86–0,92] | 1,04 | 67% | 41% | 13% / 20% | −6 | 75% | −0,01 | 60-80%: −12 |
| R3 | 0,89 [0,84–0,94] | 1,04 | 67% | 40% | 13% / 20% | −2 | 75% | −0,01 | 60-80%: −15 |
| R4 + R6 | 0,90 [0,86–0,94] | 1,05 | 71% | 45% | 13% / 16% | −5 | 75% | −0,01 | 60-80%: −15 |
| R5 | 0,90 [0,87–0,93] | 1,05 | 71% | 45% | 14% / 15% | −5 | 75% | −0,02 | **60-80%: −22** |
| R7 | 0,91 [0,87–0,96] | 1,07 | 71% | 45% | 14% / 15% | −6 | 75% | −0,03 | **60-80%: −20** | |

Altri scenari (un evento su tre), R/timer e ritardo con la poliuria:

| | Pulito | Orari decisi dal padrone | Poliuria | Poliuria ≥ 4 giorni, errore con segno |
|---|---|---|---|---|
| R0 | 0,99 | 0,67 | 1,02 | **−42** |
| R1 | 0,81 | 0,48 | 0,76 | −35 |
| R2 | 0,73 | 0,41 | 0,62 | −23 |
| R3 | 0,72 | 0,40 | 0,63 | −21 |
| R4 + R6 | 0,76 | 0,40 | 0,52 | −3 |
| R5 | 0,75 | 0,40 | 0,51 | 0 |
| R7 | 0,74 | 0,41 | 0,51 | 0 | |

Lettura:
- **R1 e R2 fanno quasi tutto il guadagno sull'errore.** R1 toglie il ritardo sistematico diagnosticato in `ricerca/12` §3.5 (pulito 0,99 → 0,81); R2 dà al modello l'orario del padrone (orari fissi 0,48 → 0,41; nel realistico i cani che battono il timer passano dal 44% al 75%).
- **R3** serve al mattino (prima pipì: 84 → 73 min nel realistico), non al totale.
- **R4** porta la copertura dal 67% al 71% e toglie il ritardo con la poliuria (−21 → −3): la calibrazione per cane impara che il cane «arriva prima».
- **R5 non funziona come previsto.** La G stimata sugli eventi (previsione fatta subito dopo l'evento precedente) non corregge la probabilità oraria (fatta a metà intervallo, dato che non è ancora successo): la fascia 60-80% peggiora da −15 a −22 punti. Va rifatta con le previsioni a orari fissi registrate (§6).

### 3.3 Collaudo d'ingresso (§11.3 punto 3) [MISURATO, banco realistico, dopo R7]

| Criterio (§11.3 punto 3) | Soglia | Misurato | Esito |
|---|---|---|---|
| R contro il timer | ≤ 0,85 | **0,91** [0,87–0,96] | ✘ |
| R contro «stesso orario» | ≤ 1,00 | **1,07** [1,00–1,14] | ✘ |
| Copertura dell'intervallo all'80% | 75-88% | **71%** [69–72] | ✘ |
| Calibrazione, fasce con n ≥ 50 | ±10 punti | 0-10%: +9; 10-20%: +5; …; **60-80%: −20** (n = 85) | ✘ |
| T14 poliuria (≥ 4 giorni, scenario poliuria) | errore con segno ≥ −20 min | 0 min | ✔ |
| T15 tetto | sempre | 2.636/2.636 e tutti gli scenari | ✔ |

**Esito: il modello corretto non supera il collaudo d'ingresso.** È molto migliorato (da 1,02 a 0,91 contro il timer; batte il timer nel 75% dei cani contro il 44%; dal ritardo di 42 minuti con la poliuria a 0), ma sul banco realistico **non è migliore della previsione di base** (0,91 contro 0,92, IC sovrapposti), e la previsione di base è più semplice, più onesta nella finestra (73% contro 71%) e non ha probabilità da calibrare.

Dove il modello in ombra fa meglio della previsione di base [MISURATO]: prima pipì del mattino nel realistico (72 min contro 75; R 0,66 contro 1,11), pulito (0,74 contro 0,88), fine settimana (0,70 contro 0,86), cambio di routine (0,76 contro 0,85), orari ±10 min (0,74 contro 0,92). Dove fa peggio: orari decisi dal padrone (0,41 contro 0,37) e poliuria (0,51 contro 0,52, pari).

### 3.4 Test T1-T18 portati in `test/`

`test/banco/base_test.dart` (previsione di base, pochi minuti) e `test/banco/ombra_test.dart` (modello in ombra, circa un'ora), con il tag `banco`. Nella suite normale e in CI sono saltati: si eseguono con `flutter test -j 4 --dart-define=BANCO=true test/banco`. Le soglie sono quelle di `ricerca/12` §7; i test non ancora superati hanno `skip` con il valore misurato, così restano visibili come obiettivo.

| Test | Soglia (`ricerca/12` §7) | Previsione di base | Modello in ombra dopo R7 | In `test/banco/` |
|---|---|---|---|---|
| T1 origine onesta | nessun log futuro | ✔ | ✔ | ✔ `base_test` |
| T2 pulito | R ≤ 0,85 | 0,88 | **0,74** ✔ | ✔ |
| T3 realistico | R ≤ 0,85, IC < 1 | 0,92 | 0,91 ✘ | skip con valore |
| T4 «stesso orario» | R ≤ 1,00 | 1,08 | 1,07 ✘ | skip |
| T5 orari del padrone | ≤ 1,3 × «stesso orario» | 1,0 × ✔ | 1,15 × ✔ | ✔ |
| T6 copertura 80% | 75-88% | finestra 73% | 71% ✘ | skip |
| T7 copertura 50% | 45-60% | — | 44,7% ✘ | skip |
| T8 PIT | code 6-14% | — | 14% / 15% ✘ | skip |
| T9 calibrazione | ±10 punti; BSS ≥ 0 | — | −20 punti; −0,03 ✘ | skip |
| T10 ritardo diurno (pulito) | mediana in valore assoluto ≤ 15 min | +10 | −7 ✔ | ✔ |
| T11 prima pipì (fine settimana, cambio) | ≤ 45 min | 20 / 42 | 15 / 30 ✔ | ✔ |
| T12 mancanti | R ≤ 0,95 | 0,93 | 0,87 ✔ | ✔ |
| T13 orari ±10 min | R ≤ 0,90 | 0,92 | 0,74 ✔ | ✔ |
| T14 poliuria | ≥ −20 min | 0 | 0 ✔ | ✔ (base e ombra) |
| T15 tetto | sempre | ✔ | ✔ | ✔ |
| T16 cacca | descrittivo | 318 min (orario abituale) | — | descrittivo |
| T17 artefatto | origine onesta | ✔ (`model_validation_test`) | — | già in `test/` |
| T18 accuratezza fuori campione | ≤ 5 punti dalla copertura del banco | — | 0 punti (stesso registro) ✔ | ✔ |

In `base_test.dart` la copertura della finestra è controllata tra 70% e 88% in 4 scenari: è una guardia contro le regressioni, non la soglia del CEO (75%), che oggi il realistico manca di 2 punti.

T17 è già in `test/model_validation_test.dart` (origine onesta, sulla previsione di base). T1 è verificato a ogni previsione del banco (eccezione se un log futuro è visibile).

---

## 4. Protocollo dello studio, versione 1.1

*Versione 1.1 dell'11/11/2026. Sostituisce la 1.0 di `ricerca/12` §4 (10/11/2026), che resta valida in tutto il resto. Scritta prima di qualsiasi dato reale. Motivo della modifica: decisione del CEO dell'11/11 (`08` §11.3 punto 4): ciò che l'utente vede è la previsione di base, il modello lavora in ombra.*

**Unica modifica: che cosa si valuta.**
1. **Le ipotesi H1-H6 (`ricerca/12` §4.1) si applicano al modello in ombra**, valutato in modo prequenziale con il registro R6: per ogni pipì registrata, la previsione in ombra salvata subito dopo la pipì precedente (orario puntuale = mediana calibrata, spostata al risveglio appreso se cade nel sonno; intervallo all'80% = quantili calibrati 10°-90°). Non si ricalcola nulla a posteriori: il registro è la fonte. Questo sostituisce il ricalcolo prequenziale di `ricerca/12` §5.1.
2. **La previsione mostrata (previsione di base) si registra accanto, come riferimento aggiuntivo**: stesso record evento, campi `err_base`, `in_window_base`, `width_window_base`. È descrittiva e non entra nella regola di decisione.
3. **La regola a quattro esiti (`ricerca/12` §4.9) decide se il modello sostituisce la previsione di base** (decisione del CEO, `08` §11.3), con le stesse soglie: H1 R ≤ 0,80 con IC < 1,00; H2 copertura 80% ≥ 70% con limite inferiore ≥ 65%; H3 ±10 punti per fascia con n ≥ 50.

**Limite da annotare.** Le uscite dei cani «a orari decisi dal padrone» e di chi segue il promemoria tendono a cadere sull'orario mostrato, cioè sulla previsione di base. Questo favorisce un po' la previsione di base e, in misura minore, il timer (entrambi guardano all'intervallo passato), e sfavorisce il modello. È un errore nel verso conservativo: il modello non può «autoavverarsi». Analisi di sensibilità aggiunta (§4.10, n. 6): solo gli eventi segnati «l'ha chiesto lui» (`ricerca/12` §4.4), se compilati in almeno il 30% degli eventi.

**Telemetria (`ricerca/12` §5.2): aggiunte minime.** Nel record evento: `err_base`, `in_window_base`, `width_window_base` (arrotondati come gli altri), `model_version` già previsto; nel record griglia: la probabilità del modello calibrata (R5) e quella grezza, entrambe arrotondate al 5%. Nessun dato nuovo sul cane.

**Cosa non cambia:** popolazione, criteri di inclusione, numerosità (60 cani inclusi, 90 reclutati), sottogruppi, bootstrap per cane, regola anti-sbirciata, analisi di sensibilità 1-5, pseudonimizzazione e conservazione.

**Da fare prima della beta:** congelare questo file e `ricerca/12` §4 con un commit firmato e annotare l'hash nel rapporto finale.

---

## 5. Correzioni della terza revisione veterinaria (commit `cbf4a0b`)

| # | Cosa | Test (`test/revisione26_test.dart`) |
|---|---|---|
| A1 | `BioParams.modifier` restituisce `constitutional` (taglia, dieta), `clinical` (calore, gravidanza, allattamento, malattie, farmaci) e `recent` (farmaci iniziati da < 14 giorni e finestra di 6 h dopo la dose di diuretico, mai sotto 0,5). Con ≥ 4 intervalli la previsione di base usa solo `recent`; senza dati il fattore intero, come prima. Tetti e blocco di «Meno uscite» solo sul fattore clinico. Testo: «In base al suo intervallo abituale da sveglio, accorciato per {cause}: circa {X}.» | cane piccolo a cibo umido k = 1; diabetico noto k = 1; furosemide da 2 giorni k < 1 e testo; furosemide da 20 giorni k = 1; nessun k < 0,5; «Meno uscite» sbloccata per l'adulto piccolo sano e bloccata per il cucciolo |
| A2 | Soglia di «Fa pipì più spesso» con il solo fattore clinico (`alerts.dart`), testo invariato | cane piccolo a cibo umido: l'allarme scatta come per un cane medio |
| A3 | Notifica «nessuna pipì» a 12 ore nei 3 giorni dopo un intervento e nei 14 giorni dopo una chirurgia della colonna (`planNotifications`), con titolo e testo di `ricerca/26` §7 | 24 h senza intervento, 12 h dopo una sterilizzazione di ieri, 24 h dopo 5 giorni, 12 h dopo un'ernia del disco di 5 giorni fa |
| A10 | «Piano consigliato di oggi» (`dailyPlan`) ricostruito sulla previsione di base: stesso intervallo personale con lo stesso k, stessa prudenza corretta (`_prudenceQuantile`), stesso tetto clinico (`dayCapMinutes`); per la cacca solo gli orari abituali. Non usa più il modello statistico | in 4 casi (adulto che trattiene 9 h, cucciolo con «Meno uscite», adulto in diuretico, senza dati) nessun intervallo del piano supera il tetto |

A1 sostituisce la mia correzione B2 (rapporto dei fattori): la regola del veterinario è più semplice e più prudente sui farmaci appena iniziati.

---

## 6. Raccomandazioni al CEO

1. **La beta parte con la previsione di base.** Rispetta gli attesi di C2-3 su errore, orari del padrone, poliuria e tetto; la copertura della finestra nel realistico è al limite. Il modello corretto non supera il collaudo d'ingresso e sul banco non è migliore della previsione di base: **resta in ombra**. Non lo riaccendo; la decisione è sua.
2. **Copertura della finestra al limite.** Le alternative sono due. (a) Accettarla: l'IC comprende il 75% e lo studio la misurerà sui cani veri. (b) Allargarla al 5°-95° degli scarti, con finestre ancora più lunghe (oggi circa 7 ore nel realistico). Consiglio (a) [STIMA]: una finestra di 8 ore non aiuta nessuno.
3. **Allo sviluppatore principale: persistenza del registro R6.** Alla registrazione di ogni pipì va salvato `forecast.shadow.record` (`ShadowRecord.toJson`, pochi byte), e la lista va ripassata a `forecast(history: ...)`. Senza registro, in app la calibrazione R4 non lavora: resta l'allargamento fisso ×1,2, e `accuracy()` restituisce null. Serve anche alla telemetria dello studio (§4). Il lavoro è in `store.dart`, che non ho toccato oltre A3.
4. **R5 va rifatta, e intanto nessuna probabilità oraria in interfaccia.** La calibrazione fatta sui PIT degli eventi non vale per la probabilità oraria. Proposta: registrare anche le previsioni a orari fissi (record «griglia» di `ricerca/12` §5.2, già nel protocollo) e calibrare su quelle con una regressione isotonica per cane, quando ce ne sono almeno 50.
5. **Risveglio del profilo arrotondato all'ora.** L'uscita consigliata al mattino resta «risveglio del profilo + picco» (logica della notte invariata, come da incarico). Nel realistico è la parte con l'errore più alto. Proposta per il Ciclo 3, da far vedere al veterinario: al mattino usare la prima uscita abituale appresa (B1, R3) quando cade prima del risveglio del profilo.
6. **Prossima prova sul modello [STIMA, non misurata].** Una combinazione delle due previsioni, per esempio la media dell'orario atteso di base e della mediana calibrata del modello. Dove una sbaglia, l'altra spesso no: il modello va meglio al mattino e nei fine settimana, la base con gli orari del padrone. Si misura sul banco in pochi minuti.
7. **Frasi.** Restano vietate tutte le frasi di accuratezza (`08` §11.3). I numeri di questo rapporto sono di una simulazione e non vanno citati fuori dal progetto.
8. **«Piano consigliato di oggi».** Con A10 ora segue la previsione di base, con lo stesso tetto clinico e la stessa prudenza dei promemoria. È un cambiamento visibile, chiesto dal veterinario. Il QA dovrebbe controllare `potty_screen.dart` con un cane piccolo, un cucciolo e un cane in diuretico.

---

## 7. Limiti

- È una simulazione: vale tutto quanto scritto in `ricerca/12` §8. I numeri dicono quale versione è migliore sul banco, non quanto sarà accurata sui cani veri.
- Le correzioni della previsione di base sono state scelte guardando il banco (4 varianti della finestra, §2.2). Con 1-2 parametri il rischio di adattamento al banco è piccolo, ma esiste [STIMA]. Il collaudo vero resta lo studio.
- I gruppi «cronico» e «poliuria» del realistico hanno 3 cani: solo descrittivi.
- Gli scenari diversi dal realistico, nel modello in ombra, usano un evento su tre: la calibrazione R4 vi lavora con un terzo della storia, quindi è un po' penalizzata.
