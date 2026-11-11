# 12 — Protocollo dello studio di accuratezza e prove di robustezza (C1-5)

*10-11 novembre 2026. Autore: data scientist del progetto. Incarico C1-5 di `ricerca/08-piano-ceo.md`. Nessuna modifica a `lib/` né a `test/`: tutto il codice di analisi è in `ricerca/analisi/`.*

Convenzioni: **[MISURATO]** = numero prodotto dal banco di prova in questa consegna (simulazione, non cani veri). **[STIMA]** = mio giudizio ragionato. Gli intervalli tra parentesi quadre sono IC 95% bootstrap per cane (2.000 repliche, si ricampionano i cani con tutti i loro eventi).

---

## 0. Sintesi

1. **Sul banco realistico (32 cani, 4 settimane, tutti i disturbi insieme) il modello attuale NON supera L2 sulla pipì.** Errore mediano 91 min [82–104] contro 84 min [76–95] del timer fisso: rapporto R = **1,08 [1,03–1,13]** (soglia ≤ 0,80). Lo batte solo nel 34% [22–47%] dei cani. Il riferimento "stesso orario degli ultimi 7 giorni" fa ancora meglio (72 min; R = 1,26 [1,18–1,34]). [MISURATO]
2. La **copertura** dell'intervallo all'80% è 70% [68–73%]: appena sulla soglia L2. La finestra oggi mostrata in app (25°-75° percentile, nominale 50%) contiene il 40% delle pipì. Il modello è **troppo sicuro di sé**. [MISURATO]
3. La **calibrazione** (L3) fallisce: quando il modello dichiara 60-80% di probabilità nella prossima ora, si osserva il 40% [27–50%]; a 80-100% si osserva il 48%. Il Brier score (0,166) è peggiore di quello della semplice frequenza oraria del cane (0,155). [MISURATO]
4. **Il "3 minuti" della cacca è un artefatto, ma non per la passeggiata:** nel test attuale la previsione parte 1 minuto dopo l'ultimo evento di qualsiasi tipo prima della cacca, cioè in mediana **11 minuti prima** della cacca stessa (spesso la pipì dopo colazione). Con la stessa simulazione e un'origine onesta (1 minuto dopo la cacca precedente) l'errore diventa **381 min** [281–492] contro 99 del timer (R = 2,88). Sulla pipì la stessa origine ottimista porta la validazione da R 0,76 a 0,66. [MISURATO]
5. **Causa principale dell'errore, diagnosticata:** di giorno il modello prevede la pipì **in ritardo** (mediana −24 / −49 min nello scenario pulito). Si addestra sapendo quando il cane ha bevuto, è uscito o ha giocato, ma al momento della previsione questi inneschi futuri sono ignoti e il modello li considera assenti. L'intervallo tipico appreso è il 10-47% più lungo di quello osservato nel cane. [MISURATO, diagnosi in §3.5]
6. Dove il modello **batte** il timer: cani con **uscite decise dal padrone** (R = 0,71 [0,64–0,79]). Però lì il riferimento "stesso orario" è imbattibile (13 min contro 26). E la cacca nello scenario pulito (R = 0,64). [MISURATO]
7. **Il protocollo (§4) fissa le soglie prima dei dati:** L2a R ≤ 0,80 con limite superiore IC < 1,00; L2b copertura 80% ≥ 70% con limite inferiore ≥ 65%; L3 ±10 punti per fascia con n ≥ 50. Minimo 60 cani inclusi, reclutamento 90. Regola a quattro esiti per il Premium (§4.9).
8. **Raccomandazione:** il modello va corretto **prima della beta** (§6, 7 correzioni, nessuna soglia clinica toccata). Il banco diventa il collaudo d'ingresso: senza R ≤ 0,85 e copertura 80% ≥ 75% sul banco realistico, la beta parte con la sola finestra visibile e senza promessa di accuratezza.

---

## 1. Cosa ho fatto e come riprodurlo

| File in `ricerca/analisi/` | Cosa fa |
|---|---|
| `banco.dart` | Generatore dei cani "veri", disturbi, valutazione prequenziale, metriche, bootstrap per cane, riepiloghi |
| `s_<scenario>_test.dart` | Uno scenario per file (pulito, mancanti, jitter, orari_padrone, weekend, cambio_routine, poliuria, realistico, realistico_cacca, griglie, origine ottimista) |
| `s_artefatto_test.dart` | Generatore del test attuale (copiato), 10 semi, due origini |
| `riepilogo_test.dart` | Ricalcola i riferimenti (senza rifare il modello) e scrive i `*_finale.txt` |
| `potenza_test.dart` | Numerosità dello studio per simulazione |
| `diagnosi_pipi_test.dart`, `diagnosi_cacca_test.dart` | Diagnosi del ritardo sulla pipì e della cacca |
| `risultati/` | Riepiloghi `.txt` (con tutti i sottogruppi) e dati per evento `.json` |

Esecuzione: `flutter test -j 6 ricerca/analisi/s_*_test.dart`, poi `flutter test ricerca/analisi/riepilogo_test.dart` e `potenza_test.dart`. Sono file `_test.dart` fuori da `test/`: `flutter test` senza argomenti non li esegue, quindi la CI non rallenta. `flutter analyze` è pulito.

Costo: circa 25.000 previsioni, ognuna con un `fit` completo (circa 80 ms su questo Mac scarico). Sulla macchina condivisa e carica ci sono voluti 53 minuti. Per contenere i tempi gli scenari di ablazione valutano un evento ogni tre (`every: 3`), lo scenario realistico tutti gli eventi.

---

## 2. Banco di prova

### 2.1 I cani

32 cani (`population()`, seme 2026), metà con uscite decise dal padrone e metà "a richiesta":

| Gruppo | n | Età | Peso |
|---|---|---|---|
| Cucciolo | 6 | 3–5,5 mesi | 4–30 kg |
| Adulto | 14 | 1,5–7,5 anni | 4–40 kg |
| Anziano | 6 | oltre la soglia AAHA per taglia (+6–36 mesi) | 5–38 kg |
| Malattia cronica dichiarata | 3 | 7–10 anni | 8–30 kg; `conditions = 'diabete'`, poliuria vera ×2 stabile |
| Poliuria che compare | 3 | 4–11 anni | 10–24 kg; non dichiarata, ×2,2 dal giorno 12–18 |

Ogni cane ha un seme diverso, risveglio tra le 6 e le 8, sonno 15,5–16,5 h dopo. Il profilo dell'app (`wakeHour`, `sleepStartHour`) è quello dichiarato all'inizio, arrotondato all'ora, e **non viene aggiornato**: come farà un padrone vero.

### 2.2 Il processo "vero" (diverso dal simulatore interno del modello)

Il modello impara da pseudo-dati generati con una hazard log-normale moltiplicata dagli inneschi (`EliminationModel._simulate`). Il banco usa invece la fisiologia di 05 §P2/P9, al minuto:

- **Pipì = vescica che si riempie.** Produzione basale 0,5 ml/kg/h di giorno, 0,35 di notte, × (peso/15)^−0,25. Il 70% dell'acqua bevuta arriva in vescica con picco a 65 min (DS 35). Bevute: 6 ml/kg dopo ogni pasto, 2 bevute da 4 ml/kg a caso, ×1,4 nei cuccioli. Volume a uno svuotamento: 8 ml/kg nell'adulto, 6 nell'anziano, 3,5–4,5 nel cucciolo. Soglia di bisogno 0,85–1,25 × quel volume; di notte si trattiene fino a 2,2×.
- **Opportunità.**
  - Cani **a richiesta**: passeggiata al mattino e alla sera; quando la vescica è piena chiedono di uscire e il padrone risponde in 2–20 min.
  - Cani **a orari decisi dal padrone**: 4 uscite al giorno (6 nei cuccioli), ±15–30 min. Il cane fa pipì a ogni uscita se la vescica è almeno al 25%; se arriva a 2,5× ha un incidente in casa.
  - I maschi aggiungono 0–2 marcature nei 10 minuti successivi.
- **Cacca = inneschi + prontezza del colon.** Dopo ogni cacca il colon è "pronto" dopo 0,55 × la mediana di 05 §P7, con dispersione log-normale. Da pronto, il cane la fa in passeggiata (in media 8 minuti dopo l'inizio), dopo un pasto (25–60 min, cani a richiesta) o, dopo 4 ore, con uno stimolo forte. I cani a orari fissi la trattengono fino alla prossima uscita (oltre 14 ore: incidente).

Realismo [MISURATO, `risultati/realistico_pipi.txt`]: pipì vere al giorno 3,2–4,8 negli adulti, 3,9–5,5 negli anziani, 6–11 nei cuccioli, 4,3–6,5 con poliuria; cacca 1,9–2,4 al giorno negli adulti e 3–3,9 nei cuccioli. Sono coerenti con 04 §1.5 e 05 §P7.

### 2.3 I disturbi

| Disturbo | Implementazione |
|---|---|
| Pipì non registrate | quota per cane uniforme tra 10% e 40%; cacca ×0,6; pasti registrati 85%, acqua 25% (quantità nota nella metà dei casi), risvegli 50%, passeggiate 25%; incidenti registrati 90% |
| Orari spostati | ogni orario registrato ±10 min (uniforme) |
| Uscite decise dal padrone | vedi sopra; nello scenario "orari_padrone" tutti i cani |
| Fine settimana | risveglio +1,5 h, letto +0,5 h, pasti e uscite spostati, passeggiata lunga del pomeriggio |
| Cambio di routine dal giorno 15 | nei giorni feriali risveglio −1 h; uscite di mezzogiorno e della sera +1,5 h; cena +1 h |
| Poliuria che compare | produzione e sete ×2,2 dal giorno 12–18, non dichiarata (in "poliuria" tutti i cani, in "realistico" solo i 3 della scheda) |

### 2.4 Protocollo di valutazione (prequenziale)

- 28 giorni dal lunedì 7/9/2026; si valutano gli eventi dei giorni 8–28 (i primi 7 sono rodaggio).
- **Origine della previsione:** 1 minuto dopo l'evento precedente *registrato* dello stesso tipo. Il modello vede solo i log con orario ≤ origine. È la domanda del prodotto: "appena tornato dalla passeggiata, quando dovrò riuscire?".
- **Bersaglio:** l'evento successivo *registrato*, come potrà fare lo studio vero. Riporto anche l'errore rispetto all'evento *vero* successivo, possibile solo in simulazione.
- **Riferimenti.**
  - *Timer fisso*: evento precedente + media degli intervalli da svegli (< 10 h) osservati finora. Se cade nel sonno, risveglio dichiarato + 15 min.
  - *Stesso giorno della settimana*: mediana, sulle ultime 3 settimane, di quanto dopo lo stesso orario è arrivato l'evento.
  - *Stesso orario 7 gg*: lo stesso sugli ultimi 7 giorni. In entrambi l'evento deve arrivare almeno 0,4 intervalli medi dopo lo stesso orario, per non prendere come "prossimo" il doppione di 15 minuti dopo; la prima versione aveva questo difetto ed è stata corretta prima di leggere i confronti.
- **Probabilità nella prossima ora:** a orari fissi (ogni 4 ore da sveglio per la pipì, ogni 6 per la cacca), con il modello riaddestrato a quell'orario. Riferimento: climatologia del cane, cioè la quota dei 14 giorni precedenti con un evento in quella stessa ora.
- **Intervallo all'80%:** 10° e 90° percentile letti dalla curva cumulata `Forecast.curve`. L'app oggi non lo espone: espone solo il 25°-75°.

---
## 3. Risultati del banco di prova [MISURATO]

### 3.1 Scenario realistico, pipì (32 cani, 2.636 eventi, tutti i disturbi)

| Metrica | Valore [IC 95%] | Soglia del protocollo | Esito |
|---|---|---|---|
| Errore mediano modello | 91 min [82–104] | | |
| Errore mediano timer fisso | 84 min [76–95] | | |
| Errore mediano "stesso giorno della settimana" | 76 min [66–87] | | |
| Errore mediano "stesso orario 7 gg" | 72 min [63–84] | | |
| **R modello/timer** (per cane) | **1,08 [1,03–1,13]** | ≤ 0,80 e limite superiore < 1,00 | **non superato** |
| R modello / stesso giorno della settimana | 1,14 [1,05–1,25] | | perde |
| R modello / stesso orario 7 gg | 1,26 [1,18–1,34] | | perde |
| Cani in cui il modello batte il timer | 34% [22–47%] | | |
| **Copertura dell'intervallo 10-90%** (nominale 80%) | **70% [68–73%]** | ≥ 70% e limite inferiore ≥ 65% | al limite, superato |
| Copertura della finestra 25-75% mostrata in app (nominale 50%) | 40% [37–42%] | | troppo stretta |
| Stessa, con la tolleranza di ±15 min usata in app | 47% [44–49%] | | |
| Ampiezza mediana 25-75% / 10-90% | 167 / 360 min | | |
| PIT nelle code < 0,1 / > 0,9 (attesi 10% / 10%) | 15% / 19% | | troppo sicuro |
| Errore mediano rispetto alla pipì VERA | 76 min [66–85] | | |

**Probabilità nella prossima ora** (2.520 previsioni a orari fissi, frequenza osservata 21,7%):

| | Valore |
|---|---|
| Brier modello | 0,166 [0,148–0,186] |
| Brier della climatologia del cane | 0,155 [0,142–0,170] |
| Brier skill score | **−0,07 [−0,13; −0,02]** (peggio della climatologia) |
| ECE | 7,3 punti |

| Fascia dichiarata | n | Dichiarata | Osservata [IC] | Scarto |
|---|---|---|---|---|
| 0–10% | 960 | 4% | 9% [6–12] | +5 |
| 10–20% | 440 | 15% | 18% [14–22] | +3 |
| 20–30% | 346 | 25% | 31% [26–36] | +6 |
| 30–40% | 293 | 35% | 31% [24–39] | −3 |
| 40–50% | 218 | 45% | 33% [25–41] | **−12** |
| 50–60% | 122 | 55% | 42% [32–51] | **−13** |
| 60–80% | 91 | 68% | 40% [27–50] | **−29** |
| 80–100% | 50 | 91% | 48% [33–62] | **−43** |

L3 (±10 punti per fascia con n ≥ 50) **non è superato** in 4 fasce: sopra il 40% il modello promette troppo.

### 3.2 Scenari con un disturbo alla volta (pipì, un evento ogni 3)

| Scenario | n | Modello | Timer | Stesso orario 7 gg | R / timer | R / stesso orario | Copertura 80% | Errore con segno* |
|---|---|---|---|---|---|---|---|---|
| Pulito (tutti a richiesta, log completi) | 1.131 | 66 [62–71] | 51 [44–59] | 30 [24–36] | **1,21 [1,12–1,31]** | 2,00 | 77% [75–80] | −24 |
| Pipì mancanti 10–40% | 888 | 90 [77–106] | 76 [60–91] | 54 [41–73] | **1,19 [1,06–1,38]** | 1,36 | 70% [66–74] | +1 |
| Orari ±10 min | 3.402† | 70 [62–80] | 54 [48–64] | — | **1,18 [1,09–1,30]** | — | 76% [74–79] | — |
| Tutti a orari decisi dal padrone | 1.017 | 26 [23–29] | 35 [31–40] | **13 [13–14]** | **0,71 [0,64–0,79]** | 2,10 | 88% [85–91] | −3 |
| Fine settimana diversi | 1.132 | 70 [63–80] | 53 [45–64] | 43 [38–48] | **1,23 [1,13–1,33]** | 1,77 | 76% [72–79] | −16 |
| Cambio di routine al giorno 15 | 1.150 | 69 [64–76] | 69 [58–77] | 38 [32–45] | 0,98 [0,92–1,05] | 1,66 | 77% [75–80] | −35 |
| Poliuria che compare (tutti) | 1.688 | 70 [58–88] | 65 [54–82] | 35 [30–41] | **1,10 [1,02–1,18]** | 2,09 | 75% [70–79] | −45 |
| **Realistico (tutto insieme)** | 2.636 | 91 [82–104] | 84 [76–95] | 72 [63–84] | **1,08 [1,03–1,13]** | 1,26 | 70% [68–73] | −7 |

\* Errore con segno = evento reale − previsione. Negativo vuol dire che la pipì arriva **prima** di quanto previsto (modello in ritardo).
† Per un disguido di esecuzione lo scenario "jitter" è stato valutato su tutti gli eventi e non uno ogni tre; il ricalcolo dei riferimenti "stesso orario" non è stato possibile e quei valori non sono riportati (timer e modello sono corretti).

### 3.3 Sottogruppi dello scenario realistico (pipì)

| Sottogruppo | Eventi / cani | Modello | R / timer | R / stesso orario | Copertura 80% | Errore con segno |
|---|---|---|---|---|---|---|
| Cucciolo | 799 / 6 | 69 | 1,00 [0,97–1,04] | 1,29 | **64%** | −5 |
| Adulto | 892 / 14 | 111 | 1,03 [0,97–1,09] | 1,20 | 76% | −7 |
| Anziano | 462 / 6 | 97 | 1,14 [1,09–1,20] | 1,29 | **66%** | +15 |
| Cronico dichiarato | 255 / 3 | 116 | 1,38 [1,19–1,63] | 1,42 | 73% | −45 |
| Poliuria in corso | 164 / 3 | 115 | 0,97 [0,89–1,09] | 1,14 | 72% | **−65** |
| Orari decisi dal padrone | 1.190 / 16 | 93 | 1,02 [0,98–1,08] | 1,37 | 70% | −5 |
| A richiesta | 1.446 / 16 | 90 | 1,14 [1,06–1,21] | 1,16 | 70% | −11 |
| Fine settimana | 744 / 32 | 97 | 1,12 [1,01–1,25] | 0,91 | 65% | −1 |
| Giorni feriali | 1.892 / 32 | 89 | 1,02 [0,97–1,08] | 1,59 | 72% | −9 |
| Prima del cambio (g. 8–14) | 862 / 32 | 78 | 1,24 [1,10–1,38] | 1,49 | 71% | −2 |
| Dopo il cambio (g. 15–28) | 1.774 / 32 | 97 | 1,04 [1,00–1,09] | 1,16 | 70% | −14 |
| Solo di giorno | 1.973 / 32 | 89 | 1,06 [0,98–1,14] | 1,59 | 70% | **−29** |
| Prima pipì del mattino | 663 / 32 | 100 | 1,07 [0,92–1,29] | 1,06 | 71% | **+94** |

(Gruppi con 3 cani: solo descrittivi.)

### 3.4 Cacca

| Scenario | Eventi | Modello | Timer | Stesso orario 7 gg | R / timer | Errore con segno |
|---|---|---|---|---|---|---|
| Pulito | 801 | 52 [46–59] | 54 [41–70] | 31 [27–37] | **0,64 [0,54–0,81]** | −34 |
| Realistico | 1.396 | 119 [105–135] | 106 [98–116] | 110 [96–130] | **1,14 [1,03–1,26]** | −31 |
| Realistico, sottogruppo a orari fissi | 680 | 161 [131–198] | | | | |
| Realistico, sottogruppo a richiesta | 716 | 97 [87–106] | | | | |

Probabilità nella prossima ora, scenario realistico: Brier 0,077 [0,060–0,092] contro 0,081 della climatologia, BSS 0,06 [−0,03; 0,15]. Le fasce sopra il 40% sono sovrastimate di 12–64 punti, ma con pochi casi (n = 11–33).

**Limite di misura:** la curva `Forecast.curve` copre solo 12 ore. Per la cacca (mediana 11–13 h) il 90° percentile spesso non c'è, quindi la copertura all'80% (84%) e il PIT della cacca **non sono affidabili** e non li uso.

### 3.5 Diagnosi: perché il modello perde sulla pipì

`risultati/diagnosi_pipi.txt`, scenario pulito, giorno 20:

| Cane | Mediana osservata da sveglio | Letteratura | Dopo Bayes empirico | Intervallo tipico del modello |
|---|---|---|---|---|
| c07 adulto 6 kg | 236 | 300 | 268 | 295 |
| c10 adulto 12 kg | 256 | 300 | 258 | 331 |
| c14 adulto 22 kg | 291 | 300 | 282 | 326 |
| c18 adulto 36 kg | 273 | 300 | 304 | **401** |
| c22 anziano 14 kg | 230 | 240 | 197 | 281 |
| c24 anziano 30 kg | 272 | 240 | 262 | 297 |

Il Bayes empirico centra bene il ritmo del cane. Ma la hazard stimata, **senza inneschi**, implica intervalli più lunghi del 10–47%. In addestramento ogni quarto d'ora "vede" l'acqua bevuta, le passeggiate e il gioco già avvenuti (`_rows` → `features(c, t, last, t, pr)`, con cutoff = t), e attribuisce a loro una parte del rischio. Al momento della previsione, invece, `_withFuture` aggiunge solo i **pasti** abituali: acqua, passeggiate e gioco futuri valgono zero, e la previsione arriva tardi. Di giorno lo scarto è di −24 min nello scenario pulito e di −49 min sui soli eventi diurni, ed è **sistematico** (un timer non ne soffre).

Gli altri difetti sono secondari ma misurabili:
- **troppa sicurezza:** code del PIT al 15% e 19% invece di 10%; probabilità alte sovrastimate;
- **risveglio fisso del profilo:** la prima pipì del mattino è prevista in anticipo di 94 min in mediana nel realistico (+38 min nel pulito), perché `dog.wakeHour` non segue weekend e cambi di routine;
- **lentezza ad adattarsi alla poliuria:** in ritardo di 65 min mentre è in corso, con emivita di 14 giorni.

### 3.6 Il "3 minuti" della cacca (`risultati/artefatto.txt`)

Ho copiato il generatore di `test/model_validation_test.dart` e l'ho fatto girare con 10 semi e due origini.

| | Origine A (come il test: 1 min dopo l'ultimo evento di qualsiasi tipo) | Origine B (1 min dopo l'evento precedente dello stesso tipo) |
|---|---|---|
| Cacca, errore modello | **8 min** [6–9] (seme 3: 5 min) | **381 min** [281–492] (seme 3: 289) |
| Cacca, timer | 99 | 99 |
| Cacca, R / timer | 0,06 | **2,88 [2,28–3,97]** |
| Cacca, stesso orario 7 gg | 12 min | 12 min |
| Pipì, errore modello | 18 [15–20] | 21 [18–22] |
| Pipì, R / timer | 0,66 | 0,76 [0,68–0,87] |
| Pipì, R / stesso orario 7 gg | 1,03 | 1,19 |

- Con l'origine A la previsione della cacca parte in mediana **11 minuti** prima dell'evento (90° percentile 27 min). Di solito parte dalla pipì fatta 25–35 minuti dopo colazione, che nel generatore precede la cacca (30–45 minuti dopo colazione). Il modello deve solo dire "a breve": da qui i 3 minuti. **È un artefatto della scelta dell'origine.** In quel generatore la passeggiata non viene registrata: l'ipotesi del piano (la passeggiata come innesco quasi deterministico) non è la causa.
- Con l'origine onesta il modello sbaglia di 6 ore. `diagnosi_cacca.txt` mostra perché: dopo la cacca del mattino la curva dà solo il 24% di probabilità di farla entro le 20, mentre nel generatore la cacca dopo cena c'è 2 volte su 3. La mediana scavalca la sera e cade la mattina dopo (distribuzione bimodale: la mediana è un cattivo punto di previsione).
- Sullo stesso generatore il riferimento "stesso orario" fa 12 minuti: la cacca di quel cane è un orologio. Un modello con 16 parametri non serve a prevederla.
- Anche sul banco nuovo l'origine ottimista abbellisce: pipì R 0,72 (contro 1,08 con l'origine onesta), cacca R 0,61 (contro 1,14).

**Conclusione:** il risultato pubblicato nel piano (18 contro 26 min sulla pipì, 3 contro 363 sulla cacca) non va più citato. La validazione in `test/` va riscritta con l'origine onesta e più cani (§7). Lo segnalo allo sviluppatore principale: non ho toccato i test esistenti.

### 3.7 Dove il modello non batte i riferimenti (risultato valido, da scrivere)

| Scenario | Chi vince | Perché |
|---|---|---|
| Uscite decise dal padrone | **"Stesso orario"** (13 min contro 26) | la pipì segue l'agenda del padrone, non la vescica. Il modello non ha una covariata "uscita abituale" |
| Cani a richiesta con log completi | **timer** (51 contro 66) e "stesso orario" (30) | ritardo sistematico (§3.5) |
| Fine settimana | timer | profilo di risveglio fisso, ritardo diurno |
| Poliuria nuova | timer e "stesso orario" | adattamento lento; ritardo di 45–65 min, cioè **nel verso pericoloso** (il cane deve uscire prima di quanto detto) |
| Malattia cronica dichiarata | timer (R 1,38) | il fattore 0,4 del diabete accorcia l'intervallo del prior, ma l'apprendimento e la hazard senza inneschi lo riallungano (3 cani: indicativo) |
| Cacca dalla cacca precedente | timer (R 1,14; 2,88 sul vecchio generatore) | distribuzione bimodale e curva di 12 h |

Vince invece contro il timer: orari fissi (R 0,71), cacca nello scenario pulito (R 0,64) e, nel realistico, la sola poliuria in corso, alla pari (0,97).

---
## 4. Protocollo dello studio di accuratezza con i beta tester (preregistrato)

*Versione 1.0 del 10/11/2026, scritta prima di qualsiasi dato reale. Ogni modifica successiva va datata, motivata e riportata nel rapporto finale come deviazione. Il file va congelato con un commit firmato (hash nel rapporto) prima dell'apertura della beta.*

### 4.1 Domanda e ipotesi

**Domanda.** Su cani veri, registrati da padroni veri, la previsione della prossima pipì di Zampa è più precisa di un timer fisso e onesta nelle probabilità che dichiara?

| # | Ipotesi | Tipo |
|---|---|---|
| H1 (L2a) | Il rapporto R = Σ<sub>cani</sub> errore mediano del modello / Σ<sub>cani</sub> errore mediano del timer fisso è **≤ 0,80**, e il limite superiore dell'IC 95% di R è **< 1,00** | primaria |
| H2 (L2b) | La quota di pipì che cadono nell'**intervallo all'80%** dichiarato (10°-90° percentile) è **≥ 70%**, con limite inferiore dell'IC 95% **≥ 65%** | primaria |
| H3 (L3) | Calibrazione della "probabilità nella prossima ora": in ogni fascia con almeno 50 previsioni, |osservata − dichiarata| **≤ 10 punti** | secondaria vincolante per il lancio (L3) |
| H4 | Il modello non è peggiore del riferimento "stesso orario" (mediana degli ultimi 7 giorni): R<sub>abitudine</sub> ≤ 1,00 | secondaria, descrittiva |
| H5 | Utilità percepita: ≥ 60% dei tester risponde 4-5 su 5 a "I promemoria arrivano al momento giusto" (questionario a 4 e a 8 settimane) | secondaria (L3, utilità) |
| H6 | Sicurezza: gli incidenti in casa per cane-settimana non aumentano dopo l'attivazione dei promemoria (confronto prime 2 settimane vs successive, descrittivo) | sicurezza |

Le soglie sono quelle della sezione 3.8 del piano (L2, L3); il protocollo fissa solo come si misurano.

### 4.2 Disegno

- **Studio osservazionale prospettico, prequenziale**, senza gruppo di controllo randomizzato. Ogni previsione si confronta con l'evento successivo registrato.
- **Unità di analisi: il cane.** Le statistiche si calcolano per cane e poi si aggregano (ogni cane pesa uguale nel rapporto R; nella copertura pesa per numero di eventi, come richiesto da L2).
- **Durata:** beta di almeno 8 settimane (L1). Finestra di analisi: dal giorno 8 di registrazione di ogni cane (i primi 7 giorni sono rodaggio; vengono riportati a parte come "partenza a freddo").

### 4.3 Criteri di inclusione ed esclusione

**Cane incluso nell'analisi primaria se:**
1. ≥ 21 giorni di calendario con registrazioni (L1);
2. in quei giorni, una media di **≥ 3 pipì registrate al giorno** (≥ 2 per i cani dichiarati "senza accesso libero" e adulti, vedi 4.4);
3. il profilo ha data di nascita, peso, ora di risveglio e di sonno compilati;
4. il padrone ha dato il consenso alla telemetria dello studio.

**Giorni esclusi** (non il cane): giorni con < 2 pipì registrate (giorno "dimenticato"); giorni in pensione/dog sitter segnalati; i 2 giorni dopo un intervento chirurgico.

**Cani esclusi:** cani con incontinenza dichiarata o con traversina come unico luogo; cani con più di un padrone che registra senza account famiglia (doppie registrazioni). Il numero di esclusi per motivo va nel diagramma di flusso del rapporto.

### 4.4 Uscite decise dal padrone

È il problema principale (dossier §3.1, 05 §0 punto 4): se il padrone porta fuori il cane alle 7, 13, 19 e 23, la pipì "vera" è l'orario del padrone, non il bisogno del cane.

1. **All'ingresso e ogni 2 settimane** l'app chiede: «Di solito il tuo cane esce: (a) quando lo chiede, (b) a orari fissi decisi da te, (c) un po' e un po', (d) ha accesso libero al giardino». La risposta è un campo del profilo (`outingStyle`) inviato con la telemetria.
2. **Analisi primaria su tutti i cani inclusi** (è la popolazione reale, e il timer è svantaggiato allo stesso modo).
3. **Analisi per sottogruppo prespecificata**: (a)+(d) "a richiesta" contro (b) "orari fissi". Il banco (§3.2, §3.7) prevede che nel sottogruppo "orari fissi" il modello **non** batta il riferimento "stesso orario": è un risultato atteso, non un fallimento. Per questi cani il valore del prodotto va misurato con la sicurezza (incidenti in casa, tetto massimo rispettato) e con l'utilità percepita, non con i minuti.
4. Ogni evento ha un campo facoltativo «l'ha chiesto lui / l'ho portato io» (un tocco, non obbligatorio). Se compilato in ≥ 30% degli eventi, si fa un'analisi di sensibilità solo sugli eventi "chiesti".

### 4.5 Metriche

**Primarie (L2), sulla pipì:**
- *Errore assoluto* = |orario della pipì registrata − orario "più probabile" (mediana) previsto subito dopo la pipì precedente|. **Origine della previsione: 1 minuto dopo la pipì precedente registrata**, con solo i dati registrati fino a quel momento (vedi §3.6: qualsiasi altra origine è ottimista).
- *Timer fisso* (riferimento): pipì precedente + intervallo medio da svegli dei 14 giorni precedenti (intervalli < 10 h, entrambi gli estremi fuori dalla finestra di sonno); se cade nel sonno, risveglio + 15 min.
- *Copertura*: quota di pipì tra il 10° e il 90° percentile della distribuzione prevista alla stessa origine.

**Secondarie:**
- riferimento "stesso orario" (mediana degli ultimi 7 giorni) e "stesso giorno della settimana" (mediana delle ultime 3 settimane);
- copertura della finestra 25-75% oggi mostrata in app (attesa 50%);
- PIT (valore della funzione di ripartizione prevista all'orario reale): istogramma in 10 classi, atteso piatto;
- Brier score e Brier skill score rispetto alla climatologia del cane (frequenza nella stessa ora nei 14 giorni precedenti) sulla probabilità nella prossima ora, calcolata **a orari fissi** (ogni 2 ore da sveglio, vedi telemetria) e non solo quando l'utente apre l'app;
- calibrazione per fasce: 0-10, 10-20, 20-30, 30-40, 40-50, 50-60, 60-80, 80-100%;
- le stesse metriche per la cacca (solo descrittive: nessuna soglia di lancio);
- utilità percepita (H5) e quota di promemoria "posticipati" o ignorati.

### 4.6 Intervalli di confidenza

Bootstrap **per cane** (si ricampionano i cani con reinserimento, con tutti i loro eventi), 2.000 repliche, intervallo percentile al 95%, seme fisso pubblicato. Nessun test d'ipotesi multiplo sulle primarie: H1 e H2 devono essere vere entrambe.

### 4.7 Numerosità

- **Minimo: 60 cani inclusi** (coincide con L1), **obiettivo di reclutamento: 90 cani**, perché con il 25-35% di abbandono o di esclusione a 21 giorni (L5 prevede retention a 30 giorni ≥ 30% sul pubblico; i beta tester sono più motivati) se ne includono circa 60.
- Motivazione dalla simulazione (`ricerca/analisi/potenza_test.dart`, `risultati/potenza.txt`): si estraggono n cani dal banco con la loro variabilità tra cani, gonfiata ×1, ×1,5 e ×2 perché i cani veri saranno più diversi di quelli simulati, attorno all'effetto che un modello **corretto** dovrebbe avere.
  - Con R vero 0,75 e copertura vera 74%, la probabilità di "superato" con 60 cani è 98% (variabilità ×1), 91% (×1,5), 81% (×2). Con 30 cani scende a 92%, 83% e 68%.
  - Con R vero 0,70 è ≥ 98% con 60 cani in tutti i casi.
  - **Protezione dai falsi successi:** se il modello vero ha R = 0,85, la regola lo dichiara "superato" nell'1% dei casi con 60 cani (8-15% con variabilità ×1,5-2). Se la copertura vera è 67%, lo dichiara superato nello 0-7% dei casi.
  - Quindi 60 cani bastano con un modello che abbia davvero R ≤ 0,75; sotto i 45 cani il rischio di bocciare un modello buono supera il 20% se la variabilità reale è doppia.
- **Composizione minima per i sottogruppi**: ≥ 10 cuccioli, ≥ 25 adulti, ≥ 12 anziani, ≥ 8 cani con malattia cronica dichiarata. Con meno di 10 cani un sottogruppo è solo descrittivo.

### 4.8 Sottogruppi prespecificati

Cucciolo (< 6 mesi), adulto, anziano (soglia AAHA per taglia, come in `seniorStartMonths`), malattia cronica dichiarata (qualsiasi testo in `conditions` riconosciuto da `BioParams.modifier`), stile di uscita (4.4), completezza della registrazione (terzili delle pipì registrate al giorno rispetto all'attesa per età). Per ogni sottogruppo: R, copertura, Brier, con IC. Nessuna soglia di superamento per sottogruppo; **però** se in un sottogruppo con ≥ 10 cani R > 1,00 con IC tutto sopra 1, la previsione proattiva per quel sottogruppo **non** entra nel Premium al lancio (si mostra solo la finestra, gratis).

### 4.9 Regola di decisione per il Premium (sezione 3.4)

Applicata una sola volta, alla chiusura dell'analisi (fine delle 8 settimane), dal data scientist; il Capo Progetto la ratifica.

| Esito | Condizione | Decisione |
|---|---|---|
| **Superato** | H1 **e** H2 **e** H3 veri sulla popolazione inclusa (≥ 60 cani) | Il Premium "promemoria predittivi" si può attivare (resta la condizione 2 della sezione 3.4: CNR e fisco) |
| **Superato in parte** | H1 vero e (H2 o H3) falso di poco: copertura 80% tra 62% e 70%, oppure una sola fascia di calibrazione fuori di 10-15 punti | Niente Premium al lancio. Si corregge la larghezza della finestra o la ricalibrazione (correzioni R4/R5, §6) e si ripete l'analisi su **nuovi** dati di almeno 4 settimane, con le stesse soglie |
| **Non superato** | R > 0,80, oppure IC di R che include 1,00, oppure copertura < 62% | Si lancia tutto gratis (sezione 3.4). La previsione resta visibile come "stima", senza promemoria a pagamento. Il risultato si pubblica nel rapporto e nella pagina di trasparenza |
| **Dati insufficienti** | < 60 cani inclusi alla scadenza | Si prolunga la beta di 4 settimane al massimo una volta; poi vale "Non superato" |

Vincoli: (1) le soglie non si cambiano dopo aver visto i dati; (2) un'analisi "superata" solo dopo aver escluso cani o giorni con criteri non scritti qui non vale; (3) la cacca non entra nella regola (solo descrittiva) e quindi i promemoria della cacca non possono essere venduti come "accurati" finché uno studio successivo non lo dimostra; (4) clausola di salute: nessuna delle funzioni di sicurezza (tetto massimo, allarmi) dipende da questo esito.

### 4.10 Analisi di sensibilità prespecificate

1. Solo cani con ≥ 4 pipì registrate al giorno (registrazione quasi completa).
2. Esclusione della prima pipì del mattino (dipende dal risveglio, facile per tutti).
3. Solo eventi con un intervallo dal precedente compreso tra 30 minuti e 10 ore (esclude i "doppioni" e le dimenticanze evidenti).
4. Prima e dopo un cambio di routine dichiarato (campo "è cambiato qualcosa?" nel questionario).
5. Riferimento timer calcolato con la mediana invece che con la media.
Se il risultato primario cambia di esito in una sola di queste analisi, il rapporto lo dice nella sintesi.

### 4.11 Gestione dei dati mancanti

Le pipì non registrate non si possono vedere. Si stima la completezza come rapporto tra pipì registrate al giorno e l'attesa per età e taglia (04 §1.5). Il banco mostra (§3.2) che i log mancanti **gonfiano l'errore misurato** sia per il modello sia per il timer, perché l'evento "successivo" diventa quello dopo. Il rapporto R è quindi più stabile dei minuti assoluti, ed è per questo la metrica primaria.

## 5. Specifica della telemetria minima per lo studio

**Principio:** dal telefono escono solo **metriche già calcolate sul dispositivo**, mai il diario. Base giuridica: consenso esplicito e separato (opt-in) per lo studio, revocabile in ogni momento dalle impostazioni (B7, B8). Senza consenso l'app funziona uguale.

### 5.1 Calcolo sul dispositivo

Una volta al giorno (alla prima apertura dopo le 4:00 o con un'attività in background), l'app **ricalcola in modo prequenziale le previsioni del giorno precedente**: per ogni pipì e cacca registrata, rifà la previsione dall'evento precedente usando solo i log con orario ≤ origine; per la calibrazione, rifà la probabilità nella prossima ora a orari fissi (ogni 2 ore da sveglio). Costo misurato sul banco: circa 80 ms per previsione su un Mac scarico, quindi 20 previsioni al giorno sono circa 1,6 s, e circa 8 s su un telefono 5 volte più lento: va fatto in background, a pezzi. Con la correzione R6 (§6) il ricalcolo non serve più per gli eventi: la previsione fatta all'evento precedente è già salvata. Non usa l'accuratezza oggi mostrata in app (`FittedModel.accuracy`), che è calcolata con coefficienti stimati anche sugli eventi da verificare (vedi §6, R6).

Limite noto: un log inserito in ritardo con un orario passato è visibile al ricalcolo. Per correggerlo serve un campo `createdAt` nel `LogEntry` (da aggiungere, non clinico): nel ricalcolo si usano solo i log con `createdAt ≤ origine + 10 min`.

### 5.2 Cosa esce dal telefono

**Record "evento" (uno per pipì o cacca valutata):**

| Campo | Valori | Note |
|---|---|---|
| `pid` | identificativo pseudonimo dello studio (vedi 5.3) | |
| `need` | pipì / cacca | |
| `day_index` | giorni dall'inizio dello studio per quel cane (0, 1, 2...) | niente date assolute |
| `weekend` | sì / no | |
| `daypart` | notte-mattino (prima pipì dopo il sonno) / giorno / sera | niente orari |
| `err_model`, `err_timer`, `err_habit`, `err_weekday` | minuti, arrotondati a 5, troncati a 720 | |
| `signed_err_model` | minuti con segno, arrotondati a 5 | per vedere se il modello è in anticipo o in ritardo |
| `in_80`, `in_50` | sì / no | |
| `pit_decile` | 0-9 | calibrazione dell'intervallo |
| `width_80` | minuti arrotondati a 15 | nitidezza |
| `asked` | chiesto / portato / non indicato | uscita decisa dal padrone |
| `indoor` | sì / no | sicurezza |

**Record "griglia" (uno per previsione a orario fisso):** `pid`, `need`, `day_index`, `p_next_hour` arrotondata al 5%, `p_clim` arrotondata al 5%, `outcome` (sì/no).

**Record "cane" (uno all'ingresso, aggiornato ogni 2 settimane):** fascia d'età (cucciolo / adulto / anziano), fascia di taglia (< 10, 10-25, 25-45, > 45 kg), sesso e sterilizzazione, **malattia cronica sì/no** e famiglia (urinaria / endocrina / renale / intestinale / altra) senza testo libero, farmaci che cambiano i bisogni sì/no, stile di uscita (4.4), prudenza scelta, pasti al giorno, pipì registrate al giorno (media della settimana, arrotondata a 0,5), versione dell'app e del modello (`model_version`).

**Non escono mai:** nome del cane, razza in testo libero, note, foto, testo delle condizioni, orari assoluti, date di nascita, città o coordinate, dati del veterinario, eventi clinici (vomito, convulsioni...), dosi, account o email. Nessun identificativo pubblicitario, nessun SDK di terze parti.

### 5.3 Pseudonimizzazione

- `pid` = identificativo casuale (UUID v4) generato sul telefono al momento del consenso, diverso per ogni cane, **non derivato** dall'id dell'account o del cane e non ricostruibile.
- La corrispondenza `pid` ↔ cane resta solo sul telefono. Revocando il consenso il telefono genera una richiesta di cancellazione firmata con il `pid` e lo dimentica.
- Invio senza autenticazione dell'account, verso un endpoint dedicato (es. una funzione Supabase in UE con una tabella separata dallo schema dell'app), con limite di frequenza per `pid`. L'indirizzo IP non viene registrato nella tabella dello studio; i log del server di rete vanno ridotti a 7 giorni.
- Soglia minima nei cruscotti: nessuna cella con meno di 5 cani.

### 5.4 Conservazione

- Record grezzi dello studio: **fino a 12 mesi dopo la chiusura della beta**, poi cancellati; restano solo le tabelle aggregate del rapporto.
- Cancellazione su richiesta: entro 30 giorni (in pratica immediata).
- Le tabelle sono nel registro dei trattamenti (L10) con finalità "valutazione dell'accuratezza della previsione".

### 5.5 Cruscotto

Una pagina interna (sola lettura, accesso del data scientist e del Capo Progetto), aggiornata ogni notte:
1. cani con consenso, cani inclusi (criteri 4.3) e diagramma di flusso;
2. **R con IC 95%** e copertura dell'intervallo 80% con IC, con la linea delle soglie (0,80 e 70%), per settimana e cumulati;
3. diagramma di affidabilità (calibrazione) con le fasce e il numero di previsioni;
4. istogramma PIT;
5. le stesse metriche per sottogruppo (4.8) e per stile di uscita;
6. salute dei dati: pipì registrate al giorno, quota di giorni esclusi, versioni del modello in uso;
7. sicurezza: incidenti in casa per cane-settimana.
**Regola anti-sbirciata:** il cruscotto mostra i numeri durante la beta per controllare la qualità dei dati, ma la decisione (4.9) si prende una sola volta, alla fine. Se a metà beta emerge un difetto del modello, si corregge cambiando `model_version` e si analizza separatamente: le soglie non cambiano.

---

## 6. Correzioni consigliate al modello prima della beta

Nessuna tocca soglie cliniche: i tetti `maxDay`/`maxNight`, i fattori di malattia e farmaco di `BioParams.modifier`, la regola "meno uscite solo per adulti sani", le note cliniche e gli allarmi restano come sono. Sono correzioni statistiche e di presentazione. Ordine = priorità.

| # | Correzione | Dove | Problema misurato | Effetto atteso [STIMA] |
|---|---|---|---|---|
| **R1** | **Inneschi futuri attesi.** Come per i pasti, aggiungere le **uscite/passeggiate abituali** e le **bevute abituali** (orari ricorrenti degli ultimi 14 giorni, eventi `scheduled`) al contesto di previsione. In alternativa, addestrare con le covariate di innesco limitate a ciò che era noto all'ultimo evento | `FittedModel._withFuture` (generalizzare `habitualMealMinutes` a `LogType.passeggiata`, `acqua`, `gioco`); oppure `_rows`/`_Model.features` con un cutoff all'ultimo evento | Ritardo diurno sistematico di −24/−49 min; R 1,21 nello scenario pulito | è la correzione con più peso. Togliere il ritardo porta l'errore verso o sotto il timer |
| **R2** | **Covariata "uscita abituale"** (kernel centrato sugli orari ricorrenti delle pipì degli ultimi 14 giorni, separando feriali e weekend). Il modello impara da solo quanto pesa: molto nei cani a orari fissi, poco negli altri | `_Context.fromLogs` + una covariata in `features` (`_nFeat` 16 → 17-18) | Con le uscite decise dal padrone "stesso orario" vince 13 contro 26 min | avvicina il modello al riferimento "stesso orario" dove conta, senza perderlo altrove |
| **R3** | **Risveglio appreso, feriali e weekend.** Stimare l'orario di risveglio dai `risveglio` registrati e dalla prima pipì del mattino (mediana degli ultimi 14 giorni, separata per sabato e domenica) e usarlo per i risvegli "scheduled" e per la finestra di sonno nel modello. Il profilo resta il valore iniziale | `_Context.fromLogs` (blocco dei risvegli, righe ~114-128); `PottyPredictor.inSleepWindow` solo dentro il modello | Prima pipì del mattino sbagliata di +94 min (realistico), +38 (pulito) | errore del mattino da ~100 a ~40 min |
| **R4** | **Intervallo all'80% esposto e calibrato.** Aggiungere i quantili 0,10 e 0,90 a `_quantiles` e a `Forecast` (`window80Start/End`); l'app dice «8 volte su 10 tra X e Y». Allargamento conformale per cane: si usano i PIT degli ultimi 30 eventi valutati in modo prequenziale per correggere i quantili (se meno di 30: fattore prudente fisso ×1,2 sulla scala logaritmica) | `FittedModel._quantiles`, `forecast`; `Forecast` | Copertura 80% al 70% [68–73]; PIT con code 15%/19%; finestra 25-75% al 40% invece del 50% | copertura 78-82% senza raddoppiare l'ampiezza |
| **R5** | **Ricalibrare la probabilità nella prossima ora** con una regressione isotonica (o di Platt) appresa sulle previsioni a orari fissi del cane stesso e, finché sono poche, della popolazione del banco. Mai mostrare più del 90% | `FittedModel._quantiles` (`probNextHour`) | Sopra il 40% dichiarato si osserva 12–43 punti in meno (L3 fallito) | L3 entro ±10 punti |
| **R6** | **Accuratezza in app fuori campione.** `accuracy()` oggi rivaluta gli ultimi 20 eventi con coefficienti stimati anche su quegli eventi (in campione), con tolleranza di ±15 min, e da questo dipende "Affidabilità alta" (`inWindowRate ≥ 0,55`). Va sostituita da un registro prequenziale: alla registrazione di ogni pipì si salva la previsione fatta all'evento precedente, e si calcolano errore, copertura e PIT su quelle | `FittedModel.accuracy`, `forecast` (calcolo di `conf`); persistenza in `store.dart` | Sul banco la copertura vera della finestra con ±15 min è 47%, mentre "alta" si accende già al 55% (in campione è ottimista) | etichetta di affidabilità onesta; dà anche i dati della telemetria (§5) senza ricalcoli |
| **R7** | **Adattamento rapido ai cambiamenti.** Se la mediana degli intervalli degli ultimi 3 giorni è < 0,7× quella dei 14 giorni (o > 1,4×), emivita a 3 giorni per 7 giorni (05 §P12 lo prevede già dopo un cambio di farmaco o dieta). Non cambia gli allarmi "fa pipì più spesso", che restano separati e invariati | `EliminationModel.fit` (`halfLife`, Bayes empirico) | Con la poliuria che compare il modello resta in ritardo di 45–65 min, nel verso pericoloso | ritardo dimezzato in 3–4 giorni |
| R8 | **Cacca: non vendere il punto, mostrare la prossima occasione.** Curva estesa a 24 h; come "momento probabile" mostrare la prima finestra con probabilità ≥ 30% dopo il prossimo innesco abituale (pasto o passeggiata), non la mediana di una distribuzione bimodale. Nessuna promessa di accuratezza sulla cacca in beta | `_quantiles` (`plotEnd`), `forecast` per `Need.cacca` | R 1,14 nel realistico; 2,88 sul generatore del test | evita previsioni "domattina" quando la cacca arriva dopo cena |

**Non consiglio** di cambiare ora la forza del prior (`priorDays`), la penalità ridge o i nodi della spline: sul banco il Bayes empirico centra già il ritmo del cane, e il difetto è nella previsione, non nell'apprendimento.

**Collaudo d'ingresso della beta [proposta per il Capo Progetto]:** dopo R1-R6 si rifà girare il banco. La beta parte con i **promemoria predittivi** solo se, sullo scenario realistico, R ≤ 0,85 contro il timer, R ≤ 1,00 contro "stesso orario", copertura 80% tra 75% e 88%, e nessuna fascia di calibrazione con n ≥ 50 oltre ±10 punti. Altrimenti parte con la sola finestra visibile e con il tetto di sicurezza (che non dipende dal modello statistico). Le soglie sono più severe di quelle per i cani veri perché la simulazione è più facile della realtà [STIMA].

---

## 7. Test di robustezza pronti da implementare (per lo sviluppatore principale)

Da portare in `test/` come test lenti (tag `@Tags(['banco'])`, esclusi dalla CI veloce con `--exclude-tags banco`, eseguiti ogni notte o prima di un rilascio). Il generatore e le metriche esistono già in `ricerca/analisi/banco.dart` e si possono spostare in `test/support/`. "Attuale" = misurato oggi; "atteso" = soglia del test dopo R1-R6.

| # | Test | Scenario (`scenarios`) | Asserzione | Attuale | Atteso dopo le correzioni |
|---|---|---|---|---|---|
| T1 | Origine onesta | tutti | la previsione usa solo log con orario ≤ origine = evento precedente + 1 min (verifica sul generatore: nessun log futuro in `visible`) | — | sempre vero |
| T2 | Batte il timer, scenario pulito | `pulito` | R/timer ≤ 0,85 | 1,21 | **passa** |
| T3 | Batte il timer, scenario realistico | `realistico` | R/timer ≤ 0,85 e IC superiore < 1,00 | 1,08 [1,03–1,13] | **passa** |
| T4 | Non peggiore di "stesso orario" | `realistico` | R/stesso orario ≤ 1,00 | 1,26 | passa |
| T5 | Orari decisi dal padrone | `orari_padrone` | errore mediano ≤ 1,3 × "stesso orario" | 2,10 × | passa |
| T6 | Copertura dell'intervallo 80% | `realistico` | 75% ≤ copertura ≤ 88% | 70% | passa |
| T7 | Finestra 25-75% (in app) | `realistico` | 45% ≤ copertura ≤ 60% senza tolleranza | 40% | passa |
| T8 | PIT | `realistico` | quota < 0,1 e > 0,9 entrambe tra 6% e 14% | 15% / 19% | passa |
| T9 | Calibrazione dell'ora successiva | griglia `realistico` | ogni fascia con n ≥ 50 entro ±10 punti; BSS ≥ 0 | 4 fasce fuori; BSS −0,07 | passa |
| T10 | Nessun ritardo sistematico di giorno | `pulito`, solo eventi diurni | |mediana dell'errore con segno| ≤ 15 min | −49 | passa |
| T11 | Prima pipì del mattino | `weekend`, `cambio_routine` | errore mediano della prima pipì ≤ 45 min | +94 (realistico) | passa |
| T12 | Pipì mancanti | `mancanti` | R/timer ≤ 0,95 (i log mancanti danneggiano entrambi) | 1,19 | passa |
| T13 | Orari spostati ±10 min | `jitter` | R/timer ≤ 0,90 | 1,18 | passa |
| T14 | Poliuria che compare | `poliuria`, eventi con poliuria in corso da ≥ 4 giorni | errore con segno mediano ≥ −20 min (non in ritardo) | −45 | passa |
| T15 | Sicurezza invariata | tutti | `recommendedAt` mai oltre `last + maxDay × fattore` da sveglio (tetto 06 §27-28, 07 N8) | vero | resta vero (test di non regressione clinica) |
| T16 | Cacca, onestà | `realistico`, cacca | nessuna asserzione di accuratezza; solo: `expectedAt` non oltre il prossimo risveglio + 3 h quando un pasto abituale cade prima | falso (diagnosi cacca) | passa |
| T17 | Artefatto non ripresentato | generatore di `model_validation_test` | il test di validazione usa l'origine onesta; con 10 semi R/timer pipì ≤ 0,85 | 0,76 | resta vero |
| T18 | Accuratezza in app fuori campione | `realistico` | `accuracy()` (rifatto con R6) differisce di ≤ 5 punti dalla copertura prequenziale del banco | non misurabile oggi (in campione) | passa |

Durata stimata: T2-T14 con 32 cani e un evento su tre richiedono circa 10-15 minuti su una macchina scarica. Per la CI notturna bastano 16 cani.

---

## 8. Limiti di questa analisi

- **È una simulazione.** I cani veri saranno più vari, i padroni meno regolari. Il banco serve a trovare difetti e a fissare il protocollo, non a dimostrare l'accuratezza: quella la dimostra solo lo studio (§4).
- Il generatore "vero" è mio. È diverso dal simulatore del modello, ma condivide le stesse fonti (05). Un difetto comune alle due versioni non verrebbe fuori.
- La cacca vera dipende molto più dell'ipotizzato da passeggiate e padroni; i numeri sulla cacca sono indicativi.
- Il riferimento "stesso orario" è forte nel banco perché i cani simulati sono abitudinari. Nella realtà potrebbe esserlo meno.
- I gruppi "cronico" e "poliuria" hanno 3 cani: solo descrittivi.
- Durante l'esecuzione la macchina era molto carica. Ho fermato con `pkill -f flutter_tester` la mia prima esecuzione troppo lenta. Il comando può aver interrotto anche test Flutter di altre sessioni in corso nello stesso momento: se un'altra sessione ha visto test "uccisi" verso le 23:13 del 10/11, è questa la causa.
