# 27 — Previsione della prossima pipì, versione 2

*13 novembre 2026. Branch `claude/lulu-previsione-pipi`. Seguito di `ricerca/23`. Convenzioni come in `ricerca/12` e `23`: **[MISURATO]** = numero del banco di prova (simulazione, non cani veri); **[STIMA]** = giudizio. Tra parentesi quadre l'IC 95% bootstrap per cane. R = Σ<sub>cani</sub> errore mediano / Σ<sub>cani</sub> errore mediano del riferimento: sotto 1 vuol dire meglio. «Errore con segno» = pipì vera − previsione: negativo vuol dire previsione **in ritardo** (il verso pericoloso).*

---

## 0. Sintesi per chi non è tecnico

**Cosa è cambiato.** Prima l'app usava una sola regola: «il suo intervallo abituale da sveglio». Adesso guarda **tre regole semplici** e mostra **quella di mezzo**:
1. l'intervallo abituale da sveglio (la regola di prima);
2. a che ora ha fatto la pipì, dopo lo stesso orario, negli ultimi 7 giorni;
3. lo stesso, ma lo stesso giorno della settimana scorsa e di quelle prima.

Quando una delle tre sbaglia (per esempio l'intervallo con un cane portato fuori a orari fissi, o l'orario abituale di sabato), le altre due la mettono in minoranza. Non serve nessun calcolo complicato: niente «intelligenza artificiale», tutto spiegabile.

**Com'è andata sul banco di prova** (32 cani simulati per 4 settimane, con pipì dimenticate, orari approssimati, fine settimana, cambi di routine e poliuria):
- l'errore tipico scende da **77 a 70 minuti** (il timer semplice sbaglia di 84);
- la nuova previsione batte il timer nell'**81% dei cani** (prima nel 66%);
- la finestra «di solito tra X e Y» ora è **onesta**: la pipì ci cade dentro circa 1 volta su 2, come dichiarato (la finestra larga, quella «all'80%», contiene l'80% delle pipì);
- la probabilità «nella prossima ora» è ora **calibrata**: quando dice 30%, succede circa 3 volte su 10;
- l'avviso arriva **dopo** la pipì nel **14%** dei casi, contro il **20%** dell'uscita consigliata di oggi;
- con una poliuria in corso la previsione **non va in ritardo** (−4 minuti al massimo).

**Il collaudo d'ingresso è superato?** Sul banco realistico, sì, tutte e quattro le soglie, **ma per un soffio** su quella principale (0,84 contro una soglia di 0,85). Su due banchi nuovi, mai usati per scegliere la regola, la soglia principale **non** è raggiunta (0,86 e 0,87), mentre le altre tre sì. Va detto chiaramente: è un grande passo avanti rispetto a oggi, non ancora la «rivoluzione» promessa. Lo dirà lo studio con i cani veri.

**Cosa non ha funzionato.** Aggiornare la previsione quando il padrone segna «ha bevuto» o «ha mangiato» **non** la migliora, nemmeno se il padrone li segna quasi tutti. Il modello statistico «in ombra» da solo non è migliore delle tre regole.

**Proposta di prodotto** (§5): «Prossima pipì tra circa 40 minuti (verso le 15:10). Di solito tra le 14:40 e le 15:50. Per stare tranquilli, esci verso le 14:30.», con un livello di fiducia a parole (alta, media, bassa). È già nella schermata della pipì, segnata «in prova».

**Prossimo passo** (§6): beta con almeno 60 cani inclusi (90 reclutati), di cui almeno 30 in appartamento senza giardino, con consenso separato e senza che il diario esca dal telefono.

---

## 1. Cosa ho fatto e come riprodurlo

| File | Cosa fa |
|---|---|
| `lib/logic/pee_forecast_v2.dart` | La previsione v2: candidati, mediana, regola di sicurezza, finestre conformi, probabilità con hazard empirico |
| `lib/logic/elimination_model.dart` | `Forecast.v2` e `Forecast.adaptedRecent`; `forecast(pointOnly:, window:, v2:)` per rifare le previsioni passate; la prudenza non conta più gli incidenti successivi all'origine. Campi mostrati oggi, tetti, notte, allarmi e testi **invariati** |
| `lib/ui/potty_screen.dart` | Scheda «Nuova previsione (in prova)», spegnibile con `kPrevisioneV2InVista`, e i suoi testi (`v2Texts`; i testi visibili non stanno in `lib/logic/`) |
| `test/previsione_v2_test.dart` | 9 test: orari fissi, mediana, **origine onesta** (log futuri non cambiano nulla), poliuria, avviso mai dopo l'uscita consigliata, cacca, pochi dati, «stesso orario», testi |
| `ricerca/analisi/banco3.dart`, `v3_shard*_test.dart`, `v3_analisi.dart` | Banco «a candidati»: salva per ogni origine onesta tutte le previsioni disponibili (base, ombra, timer, «stesso orario», «stesso giorno») e l'esito; l'analisi prova le strade in pochi secondi, cane per cane, in ordine di tempo |
| `ricerca/analisi/banco.dart` | Scenari nuovi: `realistico_inneschi` (inneschi registrati all'80-95%, pipì identiche), `realistico_nuovo` e `realistico_nuovo2` (cani e storie con semi mai usati) |
| `ricerca/analisi/banco2.dart` | Valuta anche la v2 con il codice dell'app: errori, copertura 80% e 50%, PIT, griglia oraria, avvisi in ritardo, fiducia; partenza a freddo (`fromDay`) |
| `risultati/v2_regola_congelata.md` | La regola scritta prima della verifica, il suo esito e le due correzioni successive, datate |
| `risultati/v22_*` | **Risultati finali** (codice dell'app, tutti gli eventi); `v2fin_*` regola congelata; `v21_*` scenari (un evento su tre) e partenza a freddo |

Esecuzione: `dart run ricerca/analisi/v3_analisi.dart realistico 300 [fase] [punto]` per le strade (dopo `flutter test -j 4 ricerca/analisi/v3_shard*_test.dart` con `risultati/lavori3.json`); `flutter test -j 4 ricerca/analisi/v2_shard*_test.dart` e `v2_unisci_test.dart` con `risultati/lavori.json` per la verifica formale (circa 6 minuti senza modello in ombra). T1 (nessun log futuro) è garantito a ogni previsione del banco e dal test «origine onesta».

**Metodo onesto.** Ogni previsione usa solo i log fino all'origine (1 minuto dopo la pipì precedente). Le combinazioni, le finestre e le probabilità imparano solo da esiti già noti all'origine. La regola finale è stata scritta e messa in un commit (`09c35ae`) prima della verifica con il codice dell'app; le due correzioni successive sono dichiarate come tali (§3.4) e la seconda (v2.1) è stata provata su un terzo banco mai eseguito prima.

---

## 2. Le cinque strade: prima e dopo [MISURATO]

Banco realistico (32 cani, 2.636 pipì, semi standard). «Prima» = previsione di base mostrata oggi (R/timer 0,92 [0,86–0,99], R/«stesso orario» 1,08, copertura della finestra 73%) e modello in ombra dopo R7 (0,91 / 1,07 / 71%, fascia 60-80% a −20 punti).

### 2.1 Strada 1 — combinazione con i riferimenti forti (banco a candidati)

| Metodo | Errore (min) | R/timer | R/«stesso orario» | Con segno |
|---|---|---|---|---|
| Base (B) | 77 | 0,92 [0,86–0,99] | 1,08 [1,01–1,14] | +13 |
| Modello in ombra (S) | 77 | 0,92 [0,88–0,97] | 1,07 [1,00–1,14] | −6 |
| «Stesso orario» (H) | 72 | 0,86 [0,80–0,92] | 1,00 | −3 |
| Media B+S | 77 | 0,97 [0,90–1,03] | 1,13 | +5 |
| Pesi in linea per cane (Hedge, η = 2) B, S, H | 75 | 0,90 [0,85–0,95] | 1,05 [1,01–1,11] | 0 |
| Hedge con mediana pesata | 74 | 0,87 [0,83–0,92] | 1,02 | +1 |
| Correzione del ritardo (mediana dei residui recenti) su B | 74 | 0,91 [0,84–0,98] | 1,06 | +8 |
| **Mediana di B, S, H** | 69 | 0,80 [0,76–0,84] | 0,93 [0,90–0,97] | +2 |
| Mediana di B, S, H, W, timer | 69 | 0,78 [0,75–0,82] | 0,91 [0,86–0,96] | −1 |
| **Mediana di B, H, W (senza modello)** | **66** | **0,78 [0,72–0,83]** | **0,91 [0,86–0,96]** | 0 |

Lettura: i **pesi aggiornati sull'errore recente non funzionano** (0,87-0,90): l'errore di un cane cambia troppo da un evento all'altro e i pesi inseguono il rumore. La **mediana semplice** funziona molto meglio, perché i candidati sbagliano in situazioni diverse. Il modello in ombra non aggiunge nulla alla mediana (0,78 con o senza). **Tenuto: mediana di B, H, W.** Ha tre vantaggi: non serve addestrare il modello, si spiega in una frase, e l'app può rifare da sola le previsioni passate (per finestre e probabilità) senza salvare un registro.

### 2.2 Strada 2 — aggiornamento con gli inneschi registrati

Per ogni innesco registrato dopo l'ultima pipì (acqua, pasto, risveglio) ho confrontato la previsione «vecchia» (fatta dopo la pipì, portata ad «adesso» se già passata) con quelle aggiornate. R < 1 vuol dire che l'aggiornamento aiuta.

| Aggiornamento | Realistico (inneschi registrati come oggi: acqua 25%) | Realistico con inneschi registrati (acqua 80%, pasti 95%) |
|---|---|---|
| Modello in ombra riaddestrato con l'innesco | 1,23 [1,17–1,31] | 1,18 [1,09–1,29]; cani a richiesta 0,99 [0,90–1,13] |
| «Ritardo tipico del cane dopo quell'innesco» (solo anticipo) | 1,05 [0,99–1,11] | 1,09 [1,03–1,15] |
| Media dei due | 1,17 | 1,18; cani a richiesta 0,97 [0,89–1,05] |
| Solo il passare del tempo (mediana dei residui condizionata) | 1,14 | 1,11 |

Lettura: **nessun aggiornamento batte la previsione vecchia** in modo affidabile, nemmeno con quasi tutti gli inneschi registrati. Registrare l'acqua aiuta un po' il modello in ombra **all'origine** (R/timer da 0,92 a 0,86; la mediana a cinque da 0,78 a 0,74), ma non abbastanza da cambiare la scelta. Limite: nel banco gli inneschi sono quelli simulati (acqua dopo i pasti e due volte a caso, nessun gioco); con cani veri l'effetto può essere diverso [STIMA]. **Non tenuta** nella previsione. Proposta di raccolta in §5.3 e misura nella beta (§6, D1).

### 2.3 Strada 3 — modello di rischio nel tempo (hazard)

Il modello in ombra è già un hazard (tempo dall'ultima pipì, ora del giorno, sonno, feriali e fine settimana con R3, orari del padrone con R2): come previsione puntuale fa 0,92 (§2.1). Ho provato un **hazard empirico del cane** per la probabilità nella prossima ora: in passato, nello stesso stato (tempo dall'ultima pipì rispetto all'orario previsto, ora del giorno), quante volte è arrivata una pipì entro un'ora? Griglia oraria (2.512 previsioni):

| Probabilità nella prossima ora | Fascia peggiore con n ≥ 50 | Brier skill vs climatologia |
|---|---|---|
| Modello in ombra grezzo | −13 (60-80%, n = 105) | −0,015 |
| Modello in ombra calibrato (R5) | −19 (60-80%, n = 84) | −0,029 |
| Hazard empirico, solo stato | −4 / −5 | 0,00 / 0,01 |
| **Hazard empirico, stato + ora del giorno (±3 h), 10 pseudo-osservazioni** | **−6** | **+0,021** |

**Tenuto** l'ultimo: è calibrato per costruzione (impara dalla stessa domanda a cui risponde) e batte la climatologia del cane.

### 2.4 Strada 4 — finestre oneste (calibrazione conforme)

Finestra = orario previsto + percentili degli **errori passati del cane** (ultimi 40, mattino e giorno separati), ricalcolati con origine onesta.

| Percentili dei residui | Copertura (nominale 80%) | Ampiezza mediana (min) |
|---|---|---|
| 10°-90° | 72% [71–74] | 377 |
| **7,5°-92,5°** | **77% [75–78]** | 453 |
| 6°-94° | 79% | 522 |
| 5°-95° | 81% | 559 |

**Tenuto** 7,5°-92,5° (come la finestra della previsione di base, B4); con il codice dell'app copre l'80-81% (§3). La finestra «di solito» (25°-75°) copre il 47-49% (nominale 50%).

### 2.5 Strada 5 — primi giorni e cambi di routine

| Giorni di dati (un evento su tre) | Base: R/timer, finestra | v2 prima della correzione | **v2.2** |
|---|---|---|---|
| 1-3 | 0,85, 49% | 0,97, 61% | **0,78** [0,64–0,98], 54% |
| 4-6 | 0,95, 66% | 0,86, 78% | 0,86 [0,74–1,00], 70% |
| 7-28 | 0,91, 75% | 0,81, 82% | 0,81 [0,73–0,88], 81% |

**Tenuto:** nei primi 3 giorni vale la sola previsione di base (gli altri due candidati non hanno ancora storia). I priori per età e taglia sono già nella previsione di base (`BioParams`); **la razza non c'è** e non l'ho aggiunta: non ci sono dati in letteratura per ogni razza (`ricerca/05`) e sul banco non si potrebbe misurare. Nei primi giorni la finestra resta troppo stretta (54-70%): lo dice la fiducia «bassa» (§5). Dopo il **cambio di routine** la v2 fa 0,76 contro 0,85 della base (scenario dedicato).

---

## 3. Verifica formale con il codice dell'app [MISURATO]

### 3.1 Collaudo d'ingresso (`ricerca/23` §3.3, `ricerca/12` §4), soglie invariate

Tutti gli eventi, previsione v2.2 calcolata dall'app (`risultati/v22_*`).

| Criterio | Soglia | **Realistico** | Banco nuovo (seme 1) | **Terzo banco (seme 2, indipendente)** |
|---|---|---|---|---|
| R contro il timer | ≤ 0,85 | **0,84** [0,77–0,90] ✔ | 0,86 [0,77–0,94] ✘ | **0,87** [0,82–0,92] ✘ |
| R contro «stesso orario» | ≤ 1,00 | 0,98 [0,92–1,04] ✔ | 0,95 [0,88–1,02] ✔ | 1,00 [0,97–1,04] ✔ (al limite) |
| Copertura dell'intervallo all'80% | 75-88% | 80% [79–81] ✔ | 80% [79–81] ✔ | 79% [77–81] ✔ |
| Calibrazione, fasce con n ≥ 50 | ±10 punti | peggiore −7 ✔ | peggiore −6 ✔ | peggiore −5 ✔ |
| T14 poliuria (scenario, ≥ 4 giorni) | ≥ −20 min | −4 ✔ | | |
| T15 tetto | sempre | 2.636/2.636 ✔ | 2.587/2.587 ✔ | 2.761/2.761 ✔ |
| *Per confronto, previsione di base* | | *0,92 / 1,08 / 73%* | *0,96 / 1,06 / 74%* | *0,95 / 1,09 / 73%* |

Fasce con meno di 50 previsioni, che il criterio non conta ma vanno dette: 60-80% con n = 19 (−2), n = 6 (−30) e n = 36 (−15).

**Esito: collaudo superato sul banco realistico, ma non in modo robusto.** Le soglie di copertura e calibrazione sono superate ovunque, con margine. La soglia su R/timer è superata solo sul banco su cui la regola è stata scelta, e di un centesimo; sui banchi nuovi il valore è 0,86-0,87, e in tutti e tre i casi l'IC comprende valori sopra 0,85. La previsione v2 è comunque **migliore della base su ogni banco e in ogni scenario** (§3.3).

### 3.2 Altri numeri del realistico

| | Base | v2.2 |
|---|---|---|
| Errore mediano | 77 min | **70** [58–81] |
| Cani che battono il timer | 66% | **81%** [71–90] |
| Errore con segno | +13 | +5 |
| Copertura «di solito» (nominale 50%) | — | 47% [46–49], ampiezza 2 h 20 |
| Ampiezza dell'intervallo all'80% | 6 h 55 | 8 h 27 |
| PIT < 0,1 / > 0,9 (attese 10/10) | — | 11% / 11% |
| Pipì **prima** dell'avviso (avviso in ritardo) | 20% (uscita consigliata) | **14%** [13–16] |
| Minuti tra avviso e pipì (mediana) | 99 | 113 |
| Errore mediano per fiducia bassa / media / alta | | 92 / 66 / 46 min (34% / 50% / 16% delle previsioni) |
| Poliuria ≥ 4 giorni, errore con segno | +5 | −1 |
| Prima pipì del mattino, R/timer (banco a candidati, senza regola di sicurezza) | 1,13 | 0,86 |
| Orari decisi dal padrone, R/timer (idem) | 0,86 | 0,68 |

L'intervallo all'80% è largo (8 ore) perché le pipì non registrate allungano gli intervalli: è onesto, ma non è da mostrare. Si mostra la finestra «di solito» (2 ore e 20).

### 3.3 Gli altri scenari (un evento su tre, `risultati/v21_*_e3`)

| Scenario | Base R/timer | **v2 R/timer** | v2 copertura 80% | v2 con segno |
|---|---|---|---|---|
| Pulito | 0,93 | **0,71** | 83% | 0 |
| Pipì mancanti | 0,93 | **0,83** | 80% | +4 |
| Orari ±10 min | 0,94 | **0,77** | 82% | +3 |
| Orari decisi dal padrone | 0,36 | **0,34** | 82% | 0 |
| Fine settimana | 1,04 | **0,70** | 81% | +6 |
| Cambio di routine | 0,85 | **0,76** | 81% | −3 |
| Poliuria (tutti gli eventi) | 0,52 | **0,48** | 82% | −4 (≥ 4 giorni: −4) |
| Realistico con inneschi registrati | 0,90 | **0,76** | 80% | +3 |

### 3.4 Correzioni successive alla regola congelata (dichiarate)

1. **Regola congelata** (`09c35ae`): con pipì più frequenti negli ultimi 3 giorni vale il più anticipato dei tre. Con il codice dell'app: R/timer **0,87** [0,80–0,94] realistico, **0,88** banco nuovo, quindi **non superato** (`risultati/v2fin_*`). La regola scattava nel 18-21% degli eventi e li anticipava di circa 80 minuti; nell'analisi esplorativa non c'era.
2. **v2.1**, decisa dopo aver visto il banco nuovo: con pipì più frequenti la mediana non va oltre la previsione di base (che è già accorciata). Provata sul terzo banco, mai eseguito prima: 0,87. Senza alcuna regola di sicurezza R migliora, ma la poliuria va in ritardo (−31 min nel sottogruppo del realistico, −16 nello scenario): **la regola resta**.
3. **v2.2**: nei primi 3 giorni la sola base (§2.5); non cambia i numeri dal giorno 7.

Il divario tra l'analisi esplorativa (0,78) e il codice dell'app (0,84) viene quasi tutto dalla regola di sicurezza: è il prezzo per non andare in ritardo con la poliuria.

---

## 4. Cosa ho tenuto e cosa no

| Strada | Tenuta? | Perché |
|---|---|---|
| 1. Combinazione | **Sì, come mediana** di base, «stesso orario», «stesso giorno»; no ai pesi in linea | 0,92 → 0,84 (app); i pesi inseguono il rumore |
| 2. Inneschi in tempo reale | **No** | Nessun aggiornamento batte la previsione vecchia, nemmeno con l'80% dell'acqua registrata |
| 3. Hazard | **Sì, per la probabilità** (hazard empirico del cane); no come previsione puntuale | Calibrazione da −20 a −7 punti, Brier skill da −0,03 a +0,03 |
| 4. Calibrazione conforme | **Sì** (7,5°-92,5° e 25°-75° dei residui del cane) | Copertura da 71-73% a 80% su tutti i banchi |
| 5. Primi giorni | **Sì, in parte** (base nei primi 3 giorni) | Giorni 1-3: 0,97 → 0,78; finestra ancora stretta |

**Nell'app oggi:** la v2 è calcolata in `Forecast.v2` e mostrata solo nella scheda «in prova» della schermata pipì. La Home, i promemoria e il «piano consigliato» usano ancora la previsione di base. **Decisione per il CEO:** sostituire la previsione di base con la v2 anche nella Home e nei promemoria (consiglio sì [STIMA]: è migliore ovunque sul banco e anticipa gli avvisi). Il cambio è in `home_screen.dart` e `store.dart`, che non ho toccato per non entrare in conflitto con `claude/debug-completo`.

**Avvertenza per lo studio.** L'ipotesi primaria H1 dello studio (`ricerca/12` §4.1) chiede R ≤ 0,80 con IC sotto 1. Sul banco la v2 fa 0,84-0,87: se i cani veri si comportano come quelli simulati, l'esito atteso dello studio è **«non superato»** o, nel migliore dei casi, **«superato in parte»** [STIMA]. Le soglie non vanno cambiate; va saputo prima.

---

## 5. Proposta di prodotto

### 5.1 La scheda «Prossima pipì» (già in `potty_screen.dart`, «in prova»)

> **Prossima pipì tra circa 40 minuti** (verso le 15:10)
> Di solito tra le 14:40 e le 15:50.
> **Per stare tranquilli, esci verso le 14:30.**
> Fiducia media.
> *Unisce tre stime: il suo intervallo abituale, gli orari dei giorni scorsi e lo stesso giorno della settimana scorsa. È una stima: se Lulù chiede di uscire, ascolta lui.*

- **Tempo arrotondato**: a 5 minuti sotto l'ora, a 15 sopra («tra circa 2 ore e 15 minuti»). L'orario esatto tra parentesi.
- **Finestra**: si mostra solo quella «di solito» (50%, circa 2 ore). L'intervallo all'80% (8 ore) resta per il protocollo.
- **Fiducia a parole**, senza percentuali (frasi di accuratezza vietate, `08` §11.3): alta se ci sono almeno 20 errori passati e la finestra «di solito» è entro 1 ora e mezza; media se ci sono almeno 8 errori e la finestra è entro 3 ore; altrimenti bassa. Sul banco ha senso: errore mediano 46 min con fiducia alta, 66 con media, 92 con bassa.
- **Ora passata**: «Potrebbe essere ora: è passato l'orario previsto (15:10)» e «Per stare tranquilli, esci adesso».

### 5.2 L'avviso «esci tra 10 minuti»

- **Orario dell'avviso = il primo tra l'uscita consigliata di oggi (con tetti e prudenza) e l'inizio della finestra «di solito», meno il preavviso scelto dall'utente** (`reminderLeadMinutes`, già regolabile, oggi 10 min). Mai dopo l'uscita consigliata: i tetti per età e le regole dei veterinari restano tutti validi (test «l'avviso non è mai dopo l'uscita consigliata»).
- Sul banco: pipì arrivate prima dell'avviso dal 20% al **14%**, al prezzo di uscire in media 15 minuti prima (113 contro 99 min di anticipo mediano, preavviso escluso). Il verso pericoloso pesa di più: è lo scambio giusto [STIMA].
- **Da fare in `store.dart`** (non toccato): in `planNotifications` usare `p.v2?.alertAt ?? p.recommendedAt` al posto di `p.recommendedAt`. Testo: «Esci tra 10 minuti con Lulù: di solito la fa tra le 14:40 e le 15:50».
- Preavviso regolabile proposto: 0, 5, 10, 15, 20, 30 minuti; il default resta 10.

### 5.3 Inneschi a un tocco

Anche se non migliorano la previsione in tempo reale (§2.2), servono allo studio e, registrati con costanza, al modello in ombra. Proposta: una riga di 4 bottoni sotto la scheda (💧 Ha bevuto, 🍽 Ha mangiato, 🎾 Ha giocato, ☀️ Si è svegliato), un tocco salva con l'ora attuale, un secondo tocco entro 5 secondi annulla. Nessuna domanda sulla quantità. Da valutare con la UX nella sessione `claude/debug-completo`. **Non** promettere che «la previsione si sposta subito»: sul banco non succede.

---

## 6. Piano di validazione con cani veri

Il banco è una simulazione: dice quale versione è migliore sul banco, non quanto sarà precisa sui cani veri. Il collaudo vero è lo studio di `ricerca/12` §4 (protocollo v1.1 di `ricerca/23` §4), con le stesse soglie. Qui sotto c'è solo ciò che cambia per la v2.

### 6.1 Chi

- **90 cani reclutati, almeno 60 inclusi** (`ricerca/12` §4.7), 8 settimane. Composizione minima: ≥ 10 cuccioli, ≥ 25 adulti, ≥ 12 anziani, ≥ 8 cronici dichiarati.
- **Novità: almeno 30 cani in appartamento senza giardino.** Domanda all'ingresso: «Ha un giardino o un terrazzo dove può fare i bisogni da solo?». Sono i cani per cui la previsione deve funzionare. Quelli con accesso libero al giardino restano esclusi dall'analisi primaria.
- Reclutamento dalla lista d'attesa, tramite educatori cinofili e 2-3 veterinari. Il veterinario non sceglie i clienti a mano: introdurrebbe una selezione.

### 6.2 Cosa registra il padrone

| Cosa | Come | Obbligatorio |
|---|---|---|
| Pipì (fuori / in casa) | un tocco dalla notifica o dalla Home | sì |
| «L'ha chiesto lui / l'ho portato io» | secondo tocco facoltativo | no (sensibilità se compilato in ≥ 30%) |
| Ha bevuto, ha mangiato, ha giocato, si è svegliato | riga a un tocco (§5.3) | no |
| Cacca | un tocco | no (descrittiva) |
| Profilo: età, peso, risveglio, sonno, malattie, farmaci, stile di uscita, giardino | procedura guidata | sì |

### 6.3 Cosa registra l'app (oltre a `ricerca/12` §5.2)

- **Previsione v2 fatta dopo ogni pipì** (si ricalcola dai log: non serve un registro nuovo), con orario, finestra «di solito», intervallo all'80%, fiducia e i tre candidati; accanto la previsione di base e il modello in ombra come riferimenti (`err_base`, già in v1.1).
- **Record griglia** ogni 2 ore da sveglio con la probabilità v2 nella prossima ora (H3).
- **Record innesco**: tipo di innesco, errore della previsione vecchia e di quella del modello in ombra riaddestrato (arrotondati a 5 min), per D1.
- **`createdAt` su ogni registrazione** (proposta di `ricerca/12` §5.1, ancora da fare in `models.dart` / `store.dart`). Nel ricalcolo si usano solo i log inseriti entro 10 minuti dall'origine: senza questo campo una pipì segnata in ritardo «aiuterebbe» la previsione.
- **Sicurezza**: incidenti in casa per cane-settimana e quota di pipì arrivate prima dell'avviso (avviso in ritardo).

### 6.4 Consenso e privacy

Vale tutto `ricerca/24` e `ricerca/12` §5.3-5.4:
- consenso esplicito e separato per lo studio, revocabile dalle impostazioni;
- dal telefono escono solo metriche già calcolate (errori arrotondati, sì/no, fasce); mai il diario, gli orari assoluti, il nome del cane o le note;
- un `pid` casuale per ogni cane, server in UE, dati grezzi cancellati 12 mesi dopo la fine della beta;
- gli inneschi non escono: esce solo l'errore della previsione. Nessun dato nuovo sul cane rispetto alla v1.1, a parte «giardino sì/no».

Testo del consenso proposto:

> «Vuoi aiutarci a capire se le previsioni funzionano? Se dici sì, ogni giorno l'app manda, senza il nome del cane né i tuoi dati, solo di quanto ha sbagliato le previsioni del giorno prima (in minuti). Il diario resta sul telefono. Puoi smettere quando vuoi dalle impostazioni, e cancelliamo tutto.»

### 6.5 Analisi e decisione

- Si valuta la v2 con H1-H6 e con la regola a quattro esiti di `ricerca/12` §4.9, **soglie invariate**. La previsione di base e il modello in ombra sono riferimenti descrittivi.
- **Ipotesi descrittive aggiunte ora, prima dei dati:**
  - **D1:** con l'acqua, R(previsione aggiornata / previsione vecchia) < 1;
  - **D2:** pipì prima dell'avviso ≤ 15% nei cani a richiesta;
  - **D3:** l'errore mediano cresce passando da fiducia alta a media a bassa.
- Controllo della qualità dei dati alla settimana 2 (cani attivi, pipì al giorno, quota di «l'ha chiesto lui»), senza guardare R.
- Versione congelata per tutta la beta (`model_version`). Se emerge un difetto si cambia versione e si analizza a parte.

### 6.6 Tempi

| Settimana | Cosa |
|---|---|
| 0 | Congelare `ricerca/12` §4, `ricerca/23` §4 e questo §6 con un commit firmato; `createdAt` e avviso v2 nello store; decisione del CEO sulla Home |
| 1-2 | Reclutamento (90 cani), consenso, procedura guidata |
| 3-10 | Beta, 8 settimane; controllo qualità alla settimana 5 |
| 11 | Analisi unica, rapporto, decisione |

---

## 7. Limiti

- È una simulazione (vale `ricerca/12` §8). I cani simulati seguono una vescica che si riempie; i cani veri possono avere abitudini che nessuna delle tre regole coglie.
- Ho provato molte varianti sullo stesso banco (circa 20 combinazioni, 8 probabilità, 5 finestre). Per questo la prova che conta è il terzo banco (0,87), non il realistico (0,84).
- Il riferimento «stesso orario» è anche un candidato della mediana. È lecito (l'app lo calcola con i soli dati del cane), ma rende più facile battere quel riferimento che il timer.
- Nei primi 6 giorni la finestra copre meno di quanto dichiara (54-70%).
- Gli inneschi del banco sono semplici: il risultato negativo della strada 2 vale per questo banco.
- Nessuna soglia clinica, nessun tetto e nessun testo rivisto dai veterinari è cambiato. Unica modifica alla logica esistente: `_prudenceQuantile` conta solo gli incidenti già avvenuti all'istante della previsione (nell'app, dove l'istante è «adesso», non cambia nulla).
