# Zampa — Seconda revisione clinica veterinaria

Data: 10/11/2026. Revisore: medico veterinario (medicina interna del cane, urgenze, medicina preventiva, comportamento, comunicazione con i proprietari).
Oggetto: verifica delle 42 correzioni e 21 aggiunte del rapporto `ricerca/06-revisione-veterinaria.md`; revisione delle parti nuove (allarmi §14 e seguenti, Emergenze, registrazione, diari, PDF, stagionalità, meteo, compagno in pixel art, modello dei bisogni).
Metodo: lettura del codice riga per riga ed esecuzione di `flutter test` (45 test, tutti superati). I test verificano il comportamento del software, non la correttezza clinica delle soglie.

> **Sintesi.** Il lavoro è stato fatto con serietà: delle 42 correzioni, 27 sono applicate correttamente, 12 in parte, 2 non applicate (rapporti di ricerca) e **1 è applicata in modo sbagliato**: il richiamo annuale della leptospirosi non viene mai programmato e resta una scadenza "1ª dose" eternamente superata. Le aggiunte ad alta priorità ci sono quasi tutte. La scheda Emergenze è buona.
> Restano però **falsi negativi pericolosi** nelle regole nuove:
> - nel cucciolo, un vomito e una diarrea danno solo un "info";
> - le glicemie registrate non vengono mai valutate;
> - la cagna che allatta con tremori riceve "oggi" e non "subito" (eclampsia);
> - il cucciolo toy che trema riceve "oggi" e non "subito" (ipoglicemia);
> - nel diabetico, vomito e abbattimento non vengono alzati di livello;
> - due dosi di insulina ravvicinate non vengono segnalate.
>
> Il compagno in pixel art è accettabile solo con regole precise. Oggi può mostrarsi "contento" mentre c'è un allarme "attenzione", e diventa felice e scodinzolante se lo tocchi anche quando è "preoccupato". L'indicatore "Uscite" premia 4 uscite anche nel cucciolo e nel cane a riposo post-operatorio.

Legenda della gravità (come in 06): **A** = rischio per la salute o rischio medico-legale, da correggere prima di qualsiasi uso esterno; **B** = errore clinico, da correggere prima del rilascio pubblico; **C** = testo o precisione.

---

## 1) Verifica delle correzioni del rapporto 06

Esito: ✔ applicata · ◐ parziale · ✘ non applicata · ⚠ applicata ma sbagliata.

### Correzioni ❌

| # | Tema | Esito | Dove / nota |
|---|---|---|---|
| 1 | Sforzo a urinare (maschio subito, femmina 1→attenzione, ≥2→oggi, frase sulla confusione) | ✔ | `alerts.dart:74-103` |
| 2 | Nessuna pipì 12-24 h anche senza `loggingActive`, maschio con sforzo = urgente | ✔ | `alerts.dart:105-135`. Restano due difetti nuovi: ❌N5 e ❌N9 |
| 3 | Vomito come evento, conati/GDV, sangue, cucciolo/<5 kg, adulto ≥3, singolo = info | ◐ | `alerts.dart:189-247`. Manca "vomito + inappetenza". Il caso cucciolo con vomito + diarrea non è coperto (❌N1) |
| 4 | Feci nere/sangue: cucciolo oggi, FANS/cortisonici subito | ✔ | `alerts.dart:249-288` |
| 5 | Sangue nelle urine in calore → info; con vomito/abbattimento → più alto | ✔ | `alerts.dart:137-170` |
| 6 | Pollachiuria con eventi grezzi, esclusa solo la marcatura in passeggiata | ◐ | `alerts.dart:172-187`. Esclude **tutte** le pipì del maschio intero dalla regola "≥4 in 2 h", non solo quelle in passeggiata |
| 7 | "Il cucciolo non cresce": ≥14 giorni, <6 mesi (<9 se ≥10 kg) | ✔ | `alerts.dart:458-475` |
| 8 | Calo di peso: anziano 5%, dieta >2%/settimana, ≥10% in 3 mesi | ✔ | `alerts.dart:476-521` |
| 9 | Testo "pipì in casa ripetute" | ◐ | `alerts.dart:445-450`: corretto, ma finisce con "annotalo nella nota" mentre ora esiste l'evento "Perdita di urina a riposo" |
| 10 | Sottopeso BCS ≤3, BCS 6 info | ✔ | `alerts.dart:523-544` |
| 11 | Vaccino core scaduto nel cucciolo → attenzione | ✔ | `alerts.dart:980-992` |
| 12 | Piometra | ◐ | `alerts.dart:405-434`. Scatta solo se è registrato un calore (❌N6) |
| 13 | Filariosi a novembre | ✔ | `prevention.dart:147-193` |
| 14 | Sverminazione del cucciolo 14/30/90 giorni | ◐ | Corretto in "Fatto" (`health_screen.dart:204`), ma il preset "Sverminazione" del modulo chiama `suggestedInterval` senza `dog` e dà **90 giorni** anche al cucciolo (`health_screen.dart:565-574`) |
| 15 | Leishmania annuale | ◐ | `prevention.dart:243` ✔. Manca la nota «test negativo prima; non sostituisce il repellente» |
| 16 | Altri intervalli (lepto, filaria inverno, collare, test, rabbia) | ⚠ | Vedi ❌N10: la 2ª dose di lepto non genera il richiamo annuale e la 1ª dose lascia una scadenza perpetua. Mancano i preset "Collare repellente" e "Filariosi iniettabile 6/12 mesi". Manca la nota sulla rabbia |
| 17 | Richiamo core a 26 settimane | ✔ | `prevention.dart:93-101` |
| 18 | Recupero per cuccioli adottati tardi e adulti | ◐ | Cucciolo ✔. **L'adulto senza vaccini registrati non riceve alcuna proposta per il core** (`prevention.dart:85`: `ageMonths < 12`) |
| 19 | Microchip/anagrafe sempre se manca | ◐ | ✔ la logica. Mancano i riferimenti di legge e la voce «Verifica che l'anagrafe sia intestata a te» quando il microchip c'è |
| 20 | Pasti automatici per età, 5 nei toy | ✔ | `models.dart:160`, `nutrition.dart:58-64`, `nutrition_screen.dart:271` |
| 21 | Gravidanza e allattamento | ◐ | `nutrition.dart:72-90` ✔, ma l'accoppiamento registrato nello storico **non** imposta lo stato "gravidanza" (`store.dart:291`): la razione di fine gravidanza non scatta (❌N16) |
| 22 | Crescita più lunga nelle taglie grandi | ◐ | `nutrition.dart:95-99` usa il **peso attuale**, non la taglia adulta prevista: un cucciolo di Alano di 4 mesi e 20 kg finisce la crescita a 12 mesi |
| 23 | Dimagrimento: dieta specifica, visita, patologie | ✔ | `nutrition.dart:179-187`. Manca solo «Pesalo ogni 2 settimane» (C) |
| 24 | Sottopeso: visita e aumento graduale | ✔ | `nutrition.dart:188-193` |
| 25 | Lista dei tossici | ✔ | `nutrition.dart:227-335`, testo finale `nutrition_screen.dart:171` |
| 26 | Acqua con umido; "beve poco" | ✔ | `log_sheet.dart:306`, `alerts.dart:394-402` |
| 27 | Tetto diurno scalato per malattie e farmaci | ◐ | `elimination_model.dart:981-997`. Non si applica se il tetto è già passato (❌N8) |
| 28 | Tetto notturno per tutte le età | ✔ | `elimination_model.dart:999-1044` |
| 29 | Tetti del cucciolo e "non un obiettivo" | ✔ | `bio_params.dart:109-116`, `potty_screen.dart:106` |
| 30 | Etichette di prudenza, "Meno uscite" solo per adulti sani | ✔ | `models.dart:55-66`, `elimination_model.dart:931-938` |
| 31 | Malattie a parola intera, lista a scelta | ◐ | Il confronto a inizio parola c'è (`bio_params.dart:236`). La lista a scelta multipla no |
| 32 | Perdita a riposo come evento separato | ✔ | `models.dart:347`, `alerts.dart:864-874` |
| 33 | Gravidanza fino a 72 giorni, >70 → visita | ✔ | `models.dart:232`, `alerts.dart:921-940` |
| 34 | Disclaimer con l'emergenza, accettato al primo avvio | ✔ | `common.dart:241-247`, `main.dart:188-256` |
| 35 | Frasi d'azione fisse per livello, pulsanti di chiamata | ◐ | `alerts.dart:12-19`: "subito" e "oggi" ✔. "attenzione" e "info" non hanno frase fissa (06 chiedeva «Prenota una visita nei prossimi 1-2 giorni; prima se peggiora» e «Parlane alla prossima visita») |
| 36 | Linguaggio "solo il veterinario può dirlo" | ✔ | applicato in modo omogeneo |
| 37 | FANS, insulina, trilostano, metronidazolo | ◐ | FANS ✔ (`models.dart:121-133`). Il riconoscimento usa solo i principi attivi, non i nomi commerciali (❌N11). Mancano trilostano/mitotano, metronidazolo, l'avviso "FANS + cortisone insieme" e l'escalation per FANS + inappetenza |
| 38 | 04 §1.2 "mesi + 1" vale a riposo | ✘ | `ricerca/04:41` dice ancora "(di giorno, da sveglio)" |
| 39 | 04 cipolla | ✘ | `ricerca/04:224` invariato |
| 40 | 04 §1.4 nota "da implementare" | ◐ | superata dal codice, ma il documento non è aggiornato |
| 41 | SINAC: D.M. da verificare | ◐ | `ricerca/04:310` cita ancora il D.M. come certo (c'è un avviso generico al §556) |
| 42 | Leishmaniosi endemica anche al Nord | ◐ | App ✔ (`prevention.dart:202`). `ricerca/04:299` non aggiornato |

### Aggiunte ➕

| # | Tema | Esito | Nota |
|---|---|---|---|
| 1 | Scheda Emergenze | ◐ | Buona (`emergency_screen.dart`). Il numero del CAV compare all'utente con la scritta «numero da verificare prima del rilascio». Mancano occhio, reazione allergica, ustioni/folgorazione |
| 2 | Nuovi segni ed eventi | ◐ | Quasi tutti presenti. Mancano: addome gonfio come evento a sé (oggi è solo un segno del vomito), collasso/svenimento, colore delle urine. Le soglie dell'inappetenza non tengono conto del numero di pasti |
| 3 | Dosi affidabili, conferma | ◐ | Dosi a 72 h ✔, "Dato/Saltato" in Home ✔, avviso a 2 h ✔. Mancano i pulsanti nella notifica. Nel PDF ci sono solo i totali, senza le date delle dosi saltate |
| 4 | Modulo diabete | ◐ | Le glicemie non sono valutate. Manca il controllo di una doppia insulina (❌N2, ➕N2) |
| 5 | Diario crisi | ✔ | Mancano il campo "fattori scatenanti" e la fase post-critica, salvo nella nota (C) |
| 6 | Area e stagionalità | ✔ | |
| 7 | Storico riproduttivo | ◐ | ✔ calori, accoppiamenti, parti. Non è collegato allo stato "gravidanza" (❌N16) |
| 8 | Validazione dei testi da un veterinario abilitato | — | È un processo, non verificabile dal codice: resta obbligatoria |
| 9 | Qualità della vita e dolore | ◐ | HHHHHMM ✔. Mancano CBPI/LOAD, CCDR e Muscle Condition Score |
| 10 | Esami con valori | ✔ | |
| 11 | Cardiopatia | ◐ | Timer ✔. `Modules.cardiac` non riconosce le terapie (pimobendan, furosemide). Manca la tolleranza all'esercizio |
| 12 | Nicturia | ✔ | `alerts.dart:892-919` |
| 13 | Notifica degli allarmi urgenti | ◐ | Calcolati solo quando l'app salva o si apre (`store.dart:343-374`). Un solo id (`base + 90`): le notifiche si sovrascrivono (❌N13) |
| 14 | Socializzazione | ✔ | |
| 15 | Denti | ✔ | |
| 16 | PDF per il veterinario | ◐ | Vedi la sezione PDF |
| 17 | Foto | ◐ | Solo dalla galleria (`log_sheet.dart:393`), non dalla fotocamera |
| 18 | Viaggi | ✔ | Il riferimento «Reg. 2026/131» va verificato |
| 19 | Spese | ✔ | Il calcolo è per cane, mentre il tetto di 550 € vale per contribuente |
| 20 | Meteo/caldo | ✔ | |
| 21 | Razze | ✔ | |

---

## 2) ✅ Cosa va bene

1. **I livelli sono ora quattro con una frase d'azione fissa** (`alerts.dart:10-19`), e le schede "subito"/"oggi" hanno i pulsanti "Chiama il veterinario" ed "Emergenze" (`common.dart:134-151`). Le urgenze in Home stanno **sopra** il compagno (`home_screen.dart:72-77`), e il compagno passa a "preoccupato" con il rimando «leggile qui sopra». È la scelta giusta.
2. **Le regole urinarie del maschio** (sforzo = subito; anuria 12-24 h con sforzo = subito) sono ora corrette e i testi sono chiari.
3. **Torsione gastrica, gengive pallide/blu, dispnea, convulsioni > 5 min o a grappolo (IVETF 2015), temperatura ≥ 41 o < 37 °C, ingestione** → "subito". Le soglie sono corrette.
4. **Sicurezza farmacologica**: l'app non calcola mai dosi («come prescritte dal veterinario», `log_sheet.dart:181`). In ogni punto pertinente c'è la frase «se l'hai saltata non raddoppiare» (`store.dart:436`, `home_screen.dart:145`, `alerts.dart:959`). I FANS sono riconosciuti, con escalation su vomito e feci nere.
5. **Diabete**: la regola «non fare l'insulina se non ha mangiato o ha vomitato» compare nel foglio, nel diario e negli allarmi. Il primo soccorso per l'ipoglicemia è corretto («mai liquidi in bocca a un cane incosciente»).
6. **Scheda Emergenze**: copre 15 situazioni con un primo gesto concreto e i numeri dal profilo. Non contiene istruzioni pericolose: niente induzione del vomito, niente farmaci umani.
7. **Prevenzione**: filariosi di novembre/dicembre gestita bene, ripartenza a maggio (aprile al Sud), test di primavera, leishmania annuale, richiamo a 26 settimane, sverminazione del cucciolo corretta nel percorso "Fatto".
8. **Nutrizione**: pasti automatici con 5 pasti nei toy sotto i 3 mesi, allattamento a volontà, avvertenze per i cuccioli di taglia grande, avviso di visita prima di dimagrire. Elenco dei tossici completo e aggiornato all'Italia.
9. **Modello dei bisogni**: tetti accorciati da malattie e farmaci, tetto notturno per tutte le età, "Meno uscite" bloccato nei cani a rischio, perdite a riposo escluse dal modello.
10. **Diari**: timer dei respiri a 30" × 2 con istruzioni corrette («mentre dorme tranquillo, non dopo il gioco né al caldo»). Diario delle crisi con grafico mensile. Scheda parto con le soglie giuste ed eclampsia. HHHHHMM con soglia 35. Esami con il range del laboratorio e senza interpretazione: è la scelta corretta.
11. **Stagionalità**: processionaria febbraio-maggio, forasacchi, caldo con il dato del 74% di colpi di calore da sforzo (Hall E.J. et al., *Sci Rep* 2020;10:9128), veleni d'autunno, botti di Capodanno, zecche per area, MDR1, Dalmata, schiena lunga, Cavalier.
12. **Meteo**: soglia più bassa per i cani a rischio, umidità considerata, consiglio pratico («uscita breve all'ombra, evita asfalto»). Privacy rispettata: viene inviata solo la città.

---

## 3) ❌ Cosa non va

Formato: **❌N [gravità] file:riga — problema.** Perché. **Correzione** (valori e testi).

### A. Falsi negativi e soglie negli allarmi (`lib/logic/alerts.dart`)

**❌N1 [A] `alerts.dart:224-246` e `289-307` — Il cucciolo con 1 vomito + 1 diarrea riceve solo "Ha vomitato una volta" (info).**
La regola della diarrea nel cucciolo chiede ≥ 2 diarree. La regola del vomito chiede ≥ 2 vomiti. La combinazione vomito + diarrea non è coperta nel cucciolo: il ramo `!puppy` della diarrea la copre solo nell'adulto. Un cucciolo non vaccinato con vomito e diarrea è parvovirosi fino a prova contraria. Lo stesso vale per il cucciolo con 1 diarrea e abbattimento.
**Correzione:** subito dopo la regola 6, aggiungere:
```
if (puppy && (vomits24.isNotEmpty || diarrhea24 >= 1) &&
    (vomits24.isNotEmpty && diarrhea24 >= 1 || depressed24 ||
     typeIn(h24, LogType.abbattimento) || typeIn(h24, LogType.inappetenza)))
  → AlertLevel.oggi
```
Titolo «Cucciolo con vomito o diarrea e altri segni». Testo: «Nei cuccioli vomito e diarrea insieme, o con abbattimento o inappetenza, richiedono una visita oggi stesso: la disidratazione è rapida e va esclusa la parvovirosi, soprattutto se non ha completato i vaccini. Subito se è molto abbattuto, ha sangue nelle feci o non trattiene l'acqua.» Se c'è anche `bloodStool` o un `LogType.abbattimento` → `AlertLevel.subito`. In questo caso non mostrare l'info «Ha vomitato una volta».

**❌N2 [A] `alerts.dart` (regola assente) + `log_sheet.dart:183-186` — Le glicemie registrate non vengono mai valutate.**
Un proprietario che misura 45 mg/dL non riceve nessun avviso. Oggi l'app raccoglie il dato senza usarlo, e il proprietario può credere che "se fosse grave Zampa me lo direbbe".
**Correzione:** nuova regola sulle `LogType.glicemia` delle ultime 6 h:
- valore < 60 mg/dL (< 3,3 mmol/L) → `subito`, «Glicemia bassa (${v} mg/dL)», testo: «Possibile ipoglicemia. Se è cosciente strofina miele o glucosio sulle gengive (mai liquidi in bocca a un cane incosciente) e chiama subito il veterinario. Non fare la prossima insulina senza averlo sentito.»;
- 60-79 mg/dL → `oggi`, «Glicemia al limite basso: segnalala al veterinario oggi, prima della prossima insulina.»;
- > 400 mg/dL con vomito, abbattimento o inappetenza nelle 24 h → `oggi` (possibile chetoacidosi);
- > 400 mg/dL da sola → `attenzione`.

Nel campo, unità esplicite e controllo: se il valore è < 30, chiedere «Hai inserito mmol/L? Moltiplica per 18 per avere mg/dL» oppure offrire la scelta dell'unità. Fonte: AAHA 2018 Diabetes Management Guidelines (Behrend et al., *JAAHA* 54:1-21).

**❌N3 [A] `alerts.dart:695-716` — Tremori/barcollamento nella cagna che allatta, o nel cucciolo toy, sono solo "oggi" (salvo "improvviso").**
Nella cagna che allatta, tremori, rigidità e agitazione sono eclampsia (ipocalcemia puerperale): morte in poche ore senza calcio endovenoso. Nel cucciolo toy sono ipoglicemia. La stessa scheda Emergenze (`emergency_screen.dart:46-50` e `62-65`) li indica come "subito".
**Correzione:** prima del ramo generico:
- `dog.reproAt(now) == ReproState.allattamento` (oppure parto registrato negli ultimi 50 giorni) e `neuro.isNotEmpty` o una `convulsione` → `subito`, titolo «Tremori in una cagna che allatta», testo «Possibile eclampsia (calcio basso dopo il parto): è un'emergenza. Allontana i cuccioli e vai subito dal veterinario.»;
- `puppy && (dog.weightKg < 5 || dog.ageInMonths(now) < 4)` con `neuro`, `convulsione` o `LogType.abbattimento` → `subito`, titolo «Cucciolo debole o tremante», testo «Nei cuccioli piccoli può essere un'ipoglicemia. Se è cosciente strofina un po' di miele sulle gengive, poi vai subito dal veterinario.»

**❌N4 [A] `alerts.dart:189-247`, `742-787` — Nel diabetico vomito, abbattimento e un pasto saltato non salgono di livello in modo coerente.**
Un diabetico che vomita una volta riceve "info". Se è abbattuto riceve "attenzione". Vomito, anoressia e abbattimento sono i segni d'esordio della chetoacidosi. Inoltre il proprietario rischia di fare l'insulina dopo il vomito.
**Correzione:** se `diabetic` e (`vomits24.isNotEmpty` o `LogType.abbattimento` nelle 24 h) → `oggi`, titolo «Diabetico con vomito o abbattimento», testo «Non fare l'insulina senza aver sentito il veterinario. Vomito e abbattimento in un cane diabetico vanno valutati oggi stesso; subito se è molto debole, respira in modo strano o non beve.» Con vomito + abbattimento insieme → `subito`. Mettere questa regola **prima** delle regole generiche del vomito e sopprimere l'info «Ha vomitato una volta».

**❌N5 [B] `alerts.dart:105-135` (e `elimination_model.dart:94`) — Una "pipì" con sforzo o poche gocce azzera il contatore dell'anuria e il timer del modello.**
Un cane ostruito che tenta ogni ora, se il proprietario annota ogni tentativo come "Pipì + gocce", non arriva mai a "nessuna pipì da 24 h". Nel maschio lo sforzo fa scattare comunque "subito", ma nella femmina (e nei tentativi registrati senza segni) il contatore riparte da capo.
**Correzione:** per la regola 2 e per il modello, considerare "pipì valida" solo `l.type == LogType.pipi && !l.signs.contains(Sign.gocce)`. Le pipì con solo `gocce` non azzerano il contatore. Nel testo dell'anuria aggiungere «Se escono solo gocce, conta come se non avesse urinato.»

**❌N6 [B] `alerts.dart:412` — La piometra non viene mai considerata se nessun calore è registrato.**
Molti proprietari non annotano i calori. Una femmina intera di 8 anni con sete aumentata, vomito e abbattimento oggi non riceve nessuna menzione dell'utero.
**Correzione:** se `!male && !dog.neutered && heat == null && ageM >= 12` e almeno 2 segni tra `drinksTooMuch`, `moreUrine`, vomito, abbattimento, inappetenza, perdite vulvari → `oggi`, titolo «Femmina non sterilizzata con sete, vomito o abbattimento», testo «Se è stata in calore negli ultimi 2-3 mesi può trattarsi di un'infezione dell'utero (piometra), che è un'urgenza: contatta il veterinario oggi stesso. Registra i calori nella sezione Riproduzione: Zampa potrà avvisarti meglio.» Con un solo segno: lo stesso testo con livello `attenzione`.

**❌N7 [B] `alerts.dart:742-771` — L'inappetenza conta gli eventi e non tiene conto dei pasti al giorno.**
`skipped48 >= 4` presuppone 2 pasti al giorno. Un cane con 1 pasto al giorno che salta 2 giorni (2 eventi) non arriva mai a "oggi", e in 24 h (1 evento) non riceve neanche "attenzione". Nel cucciolo, 2 pasti saltati senza abbattimento danno solo "attenzione".
**Correzione:** `final mpd = Nutrition.plan(dog, now).meals;`
- `skipped48 >= 2 * mpd` → `oggi` («Non mangia da 2 giorni»);
- `skipped24 >= mpd` → `attenzione` («Non mangia da 24 ore: senti il veterinario entro 1-2 giorni; prima se vomita o è abbattuto.»);
- cucciolo < 4 mesi o < 5 kg con `skipped24 >= 2` → `oggi` anche senza abbattimento («Nei cuccioli piccoli saltare i pasti espone all'ipoglicemia.»);
- FANS o cortisonico attivo e `skipped24 >= 1` → `oggi` (06 ❌37).

**❌N8 [B] `elimination_model.dart:988` — Il tetto diurno scalato non si applica se è già superato.**
`if (!asleep && recommended.isAfter(latest) && latest.isAfter(now))`: quando `latest` è già passato (diabetico con ultima pipì 4 h fa e tetto 3 h 12'), la raccomandazione resta all'orario appreso, anche ore più tardi.
**Correzione:**
```
if (!asleep && recommended.isAfter(latest)) {
  recommended = latest.isAfter(now) ? latest : now;
  …
}
```
Testo, quando `latest` è passato: «Ha superato ${dur(dayCapMin)} dall'ultima pipì: portalo fuori adesso.»

**❌N9 [B] `alerts.dart:111` — Ogni mattina scatta "Cucciolo senza pipì da 8 ore" (subito).**
`hours` conta anche le ore di sonno. Ultima pipì alle 23, sveglia alle 7: al risveglio, prima di registrare la prima pipì, l'allarme "SUBITO" è già acceso e la notifica parte. I falsi "subito" quotidiani insegnano al proprietario a ignorare il rosso.
**Correzione:** contare le ore **da sveglio**: `awakeHours = now.difference(max(pees.last.time, todayWake)).inMinutes / 60`, con soglia `awakeHours >= 6` (cucciolo < 4 mesi) o `>= 8` (4-6 mesi). Così l'allarme del cucciolo non dipende dalle ore di sonno.

**❌N10 [B, con effetto A sulla leptospirosi] `prevention.dart:238-241` — Il richiamo annuale della leptospirosi non viene mai programmato e la 1ª dose lascia una scadenza perpetua.**
- «Leptospirosi – 1ª dose» → 28 giorni. Ma la 2ª dose è già una voce pianificata, e poiché i titoli sono diversi, la scadenza della 1ª non viene mai "superata" (`dueItems`, `prevention.dart:311-318`). Risultato: «Leptospirosi – 1ª dose» resta per sempre tra le scadenze superate.
- «Leptospirosi – 2ª dose» → `contains('dose')` → `null`: nessun richiamo a 12 mesi. Siccome `hasLepto` è vero, il piano non lo propone più. L'immunità vaccinale per la leptospirosi dura circa 12 mesi (WSAVA 2024) ed è una zoonosi.
**Correzione:**
```
if (t.contains('lepto')) {
  if (t.contains('1ª dose')) return null;          // la 2ª è già pianificata
  return const Duration(days: 365);                 // 2ª dose e richiami
}
if (t.contains('core') && t.contains('ª dose')) return null;
```
`lepto` va controllato **prima** di `dose`. Lo stesso per «core – 3ª dose» → `null` (il richiamo a 26 settimane è già pianificato).

**❌N11 [B] `models.dart:91-138` — I farmaci si riconoscono solo dal principio attivo, mai dal nome commerciale.**
Il proprietario scrive "Metacam", "Rimadyl", "Previcox", "Onsior", "Galliprant", "Prednicortone", "Vetoryl", "Vetmedin", "Lasix"/"Dimazon", "Caninsulin". Con questi nomi il FANS non è riconosciuto e l'escalation "vomito/feci nere in terapia" (`alerts.dart:215`, `253`) non scatta.
**Correzione:** aggiungere alle liste:
- FANS: `metacam`, `meloxidyl`, `loxicom`, `inflacam`, `rimadyl`, `carprodyl`, `rycarfa`, `norocarp`, `previcox`, `onsior`, `cimalgex`, `trocoxil`, `galliprant`, `aspirin`, `acido acetilsal`;
- cortisonici: `prednicortone`, `prednicort`, `medrol`, `dexadreson`, `soludecadron`, `cortavance`, `apoquel` (no: è oclacitinib, va in `nessuno`);
- diuretici: `lasix`, `dimazon`, `diuren`, `upcard`, `prilactone`;
- poliuria: `soriphen`, `epiphen`, `libromide`;
- nuovo `DrugEffect.trilostano` (`vetoryl`, `trilostan`, `lysodren`, `mitotan`): vomito, debolezza, diarrea o abbattimento in terapia → `subito`, «Durante la terapia per il Cushing questi segni possono indicare un calo eccessivo del cortisolo: sospendi la prossima dose solo se te lo dice il veterinario e chiamalo subito.»;
- `Modules.cardiac`: aggiungere terapie con `pimobendan`, `vetmedin`, `cardisure`, `furosemide`.

Spostare `tramadol` fuori da "antidiarroico" (06 ❌37), oppure lasciarlo ma con l'etichetta «oppioide: può rallentare l'intestino».

**❌N12 [B] `alerts.dart:581-588` — "Gengive rosso scuro" ha livello `oggi`, ma il testo dice «chiama subito».**
Le gengive rosso mattone sono segno di colpo di calore o di shock settico/distributivo: è un'emergenza.
**Correzione:** livello `subito`. Testo: «Gengive rosso scuro, soprattutto dopo caldo o sforzo, possono indicare un colpo di calore o uno shock: raffreddalo con acqua (vedi Emergenze) e vai subito dal veterinario.»

**❌N13 [B] `store.dart:343-374` — Le notifiche degli allarmi urgenti non partono in background e si sovrascrivono a vicenda.**
- Gli allarmi vengono ricalcolati solo quando l'app salva un dato o si avvia. L'anuria a 24 h di un maschio che ha registrato sforzo alle 8 non viene notificata alle 8 del giorno dopo se nessuno apre l'app.
- Tutti usano l'id `base + 90`: con due allarmi visibile resta solo l'ultimo.

**Correzione:**
1. id distinti (`base + 90 + i`, max 5).
2. Pre-programmare le notifiche **a tempo**: all'ultima pipì valida (vedi ❌N5) + 24 h (adulto), + 12 h se maschio con sforzo nelle 24 h, + 8 h da sveglio (cucciolo); alla dose prevista + 2 h se non confermata. Vanno annullate e riprogrammate a ogni registrazione.
3. Ordine: GDV, respiro, gengive, convulsioni, anuria prima degli altri.

**❌N14 [B] `alerts.dart:590-612` — Respiro nel sonno: una singola misura > 40 dà "subito"; la misura precedente può essere di mesi prima.**
Una misura durante il sonno REM, o un errore di conteggio, manda il proprietario al pronto soccorso di notte. Al contrario, `prev` viene presa senza limite di tempo: due misure > 30 a 3 mesi di distanza contano come "due di fila".
**Correzione:**
- > 40 → `subito` solo se il cane è cardiopatico **oppure** c'è anche `Sign.dispnea`/gengive blu, **oppure** una seconda misura > 40 entro 30 minuti. Altrimenti `oggi`, con testo «Rimisura tra 15-30 minuti mentre dorme tranquillo. Se resta sopra 40, o respira con fatica a bocca aperta, vai subito dal veterinario.»
- "Due di fila > 30": le due misure devono essere entro 48 h.
- Aggiungere il confronto con la baseline del cane: media delle ultime 7 misure ≥ 25% sopra la media del mese precedente e > 30 → `oggi` (ACVIM 2019, Keene et al., *JVIM* 33:1127; Porciello et al. 2016, riferimento esatto da verificare).

**❌N15 [B] `alerts.dart:789-801` — "Insulina registrata senza pasto": il testo arriva tardi.**
Se l'evento è registrato, l'insulina **è già stata fatta** senza pasto: il rischio è un'ipoglicemia nelle ore successive. Dire «non fare l'insulina» non serve più.
**Correzione:** titolo «Insulina fatta senza che abbia mangiato». Testo: «Chiama ora il veterinario e chiedi come comportarti. Nelle prossime ore offrigli il suo pasto e osservalo: se compaiono debolezza, tremori o barcollamento strofina miele sulle gengive e vai subito dal veterinario.» Livello `oggi`.

**❌N16 [B] `store.dart:291` — Registrare un accoppiamento non imposta lo stato "gravidanza".**
La razione (`nutrition.dart:72-81`), la sete (`bio_params.dart:268-270`) e il calcolo del parto usano due fonti diverse. Con il solo accoppiamento nello storico, l'app prevede il parto ma nutre la cagna come un'adulta normale.
**Correzione:** `case ReproEventType.accoppiamento: d..reproState = ReproState.gravidanza..reproSince = e.date;`. Con un evento "pseudogravidanza" o "fine calore" senza accoppiamento, lo stato torna a "nessuno". In `deleteRepro` ricalcolare lo stato dall'ultimo evento.

**❌N17 [B] `alerts.dart:215-222`, `253-263` — L'escalation in corso di FANS/cortisonici non comprende inappetenza e abbattimento, e manca l'avviso "FANS + cortisone".**
**Correzione:** se `onNsaidOrSteroid` e (`LogType.inappetenza` o `LogType.abbattimento` nelle 24 h) → `oggi`, «Durante una terapia con antinfiammatori o cortisone, perdita di appetito o abbattimento vanno segnalati al veterinario oggi.» Se FANS **e** cortisonico sono attivi insieme → `attenzione`, «Antinfiammatori e cortisone insieme aumentano il rischio di ulcere: verifica col veterinario che sia voluto.»

**❌N18 [B] `alerts.dart:772-787` — "Abbattuto": il calcolo di `other` è sbagliato.**
`temps.isNotEmpty || gums.isNotEmpty` vale anche per una temperatura **normale** o gengive **rosa**. Inoltre, quando questi segni sono anomali, esiste già un allarme `oggi`/`subito` e la regola non viene nemmeno raggiunta. Quindi oggi l'escalation scatta proprio quando i valori sono normali. Inoltre il cucciolo abbattuto riceve solo "attenzione".
**Correzione:** `other = vomits24.isNotEmpty || diarrhea24 > 0 || typeIn(h24, LogType.inappetenza);` e livello `oggi` anche se `puppy || diabetic || senior`.

**❌N19 [B] `alerts.dart:553-562` — "Ha ingerito qualcosa" sparisce dopo 12 h.**
Le intossicazioni più frequenti in Italia hanno effetti ritardati: rodenticidi anticoagulanti 3-5 giorni, uva 24-72 h, xilitolo epatico 12-72 h.
**Correzione:** dopo le prime 12 h, mantenere per 5 giorni un `attenzione`: «Il ${data} ha ingerito: ${nota}. Alcuni veleni (es. topicidi) danno sintomi dopo giorni: sangue dal naso o dalle gengive, lividi, debolezza, vomito o pipì scarsa → subito dal veterinario.»

**❌N20 [B] `alerts.dart:875-890` — Perdite vulvari in una femmina intera senza calore registrato: solo "attenzione".**
Non si distingue tra sangue (calore non registrato) e pus (piometra a collo aperto).
**Correzione:** aggiungere a `LogType.perditeVulvari` i segni «Sangue», «Pus/giallo-verde», «Maleodoranti». Femmina intera con pus o maleodoranti → `oggi`, «Perdite purulente in una femmina non sterilizzata possono indicare un'infezione dell'utero: contatta il veterinario oggi stesso.» Con sangue e senza calore registrato → `info`, «Se è in calore registralo in Riproduzione; se non lo è, senti il veterinario.»

**❌N21 [C] `alerts.dart:718-740` e `log_sheet.dart:178` — Nessun controllo dei valori fuori scala.**
Una temperatura scritta in °F (101,5) produce "subito – colpo di calore".
**Correzione:** accettare 30-45 °C. Se il valore è > 90, chiedere «Sembra in °F: vuoi convertirlo?». Respiri: accettare 4-150. Convulsione: 0-60 min.

**❌N22 [C] `alerts.dart:629-634` — Nel Cavalier sano la tosse genera «Tosse in un cane con malattia di cuore».**
`Modules.cardiac` include la razza (`modules.dart:36`).
**Correzione:** separare `cardiac` (patologia o terapia) da `cardiacBreed` (Cavalier). Per la sola razza: `attenzione`, «Il Cavalier è predisposto alla malattia della valvola mitrale: segnala la tosse al veterinario e conta i respiri nel sonno.»

**❌N23 [C] `alerts.dart:445-450` — Il testo dice «annotalo nella nota».**
**Testo:** «Se le perdite avvengono mentre dorme o riposa, registrale come "Perdita di urina a riposo".»

**❌N24 [C] `alerts.dart:12-19` — "attenzione" e "info" non hanno frase d'azione (06 ❌35).**
**Correzione:** `attenzione` → «Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.» `info` → «Parlane alla prossima visita.» Togliere dai singoli testi le frasi temporali in conflitto (es. «entro qualche giorno» nella pelle).

**❌N25 [C] `alerts.dart:1003` — `List.sort` non è stabile: a parità di livello l'ordine può cambiare.**
**Correzione:** aggiungere a `HealthAlert` un `priority` (GDV 0, dispnea 1, gengive 2, convulsioni 3, anuria/sforzo 4, ingestione 5, …) e ordinare per livello, poi per priorità.

### B. Prevenzione, farmaci e calendario

**❌N26 [B] `prevention.dart:85` — Il cane adulto senza vaccini registrati non riceve nessuna proposta per il core.**
**Correzione:** `else if (!hasCore)` (togliere `ageMonths < 12`). Titolo «Vaccino core – verifica il libretto». Nota per l'adulto: «Se non trovi il libretto, il veterinario può fare una dose (WSAVA considera protettiva una dose dei vaccini core vivi attenuati nell'adulto) oppure dosare gli anticorpi.»

**❌N27 [B] `health_screen.dart:565-574` — Il preset "Sverminazione" calcola 90 giorni anche nel cucciolo.**
**Correzione:** passare `dog: widget.dog` e `at: date` a `suggestedInterval`. Fare lo stesso per tutti i preset.

**❌N28 [B] `prevention.dart:198-205` — Repellente con permetrina: nessun avviso sui gatti.**
L'app consiglia lo spot-on. I prodotti a base di permetrina sono letali per i gatti di casa (intossicazione frequente).
**Correzione:** aggiungere alla nota: «Gli spot-on e alcuni collari per cani contengono permetrina, molto tossica per i gatti: se in casa c'è un gatto chiedi al veterinario un prodotto adatto e tienili separati finché il prodotto è asciutto.»

**❌N29 [C] `prevention.dart:196` — A novembre il repellente anti-pappataci è proposto "da oggi".**
Con `sandflyYear = now.month >= 12 ? …`, il 10/11 la data diventa oggi.
**Correzione:** `now.month >= 11 ? now.year + 1 : now.year` (Nord: `>= 10`).

**❌N30 [C] `prevention.dart:157` — "Prevenzione filariosi" proposta anche a un cucciolo di 2-3 settimane.**
**Correzione:** richiedere `ageWeeks >= 6` e aggiungere la nota «dall'età indicata dal prodotto (in genere 6-8 settimane)».

**❌N31 [C] `prevention.dart:51-61` e `245-246` — Mancano le note di legge e di scheda tecnica.**
- Microchip: aggiungere «(L. 281/1991; O.M. 6/8/2008); poi registrazione nell'anagrafe regionale / SINAC secondo la tua Regione». Se il microchip c'è: voce «Verifica che l'anagrafe sia intestata a te».
- Rabbia: nota «Durata secondo la scheda tecnica del vaccino (1-3 anni). Per l'espatrio è valido 21 giorni dopo la prima vaccinazione.»
- Preset "Leishmaniosi": nota «Prima del vaccino serve un test negativo. Il vaccino non sostituisce il repellente.»
- Preset mancanti: «Collare repellente (durata secondo il prodotto)», «Filariosi iniettabile 6 mesi», «Filariosi iniettabile 12 mesi».

### C. Nutrizione

**❌N32 [B] `nutrition.dart:95-99` — La fine della crescita dipende dal peso attuale.**
**Correzione:** aggiungere al profilo «Taglia adulta prevista» (piccola < 10 kg, media 10-25, grande 25-45, gigante > 45). Fine crescita: 12 / 12 / 15 / 18-24 mesi. Senza il dato, stima dal peso a 4 mesi × 2 (taglie medio-grandi). L'avviso "puppy large breed" (`nutrition.dart:171`) va legato alla taglia prevista ≥ grande.

### D. Registrazione (`lib/ui/log_sheet.dart`)

**❌N33 [C] `log_sheet.dart:92-100` — Scala Purina: le descrizioni 4-6 non corrispondono alla scala originale.**
**Testi:**
- 1 «Molto dure e secche, a palline; richiedono sforzo»;
- 2 «Compatte ma non dure, segmentate; raccolte non lasciano residui (ideale)»;
- 3 «A tronchetto, umide in superficie; lasciano un segno ma restano intere»;
- 4 «Molto umide, a tronchetto; lasciano residuo e si disfano se raccolte»;
- 5 «Molto umide, a mucchietti con una forma riconoscibile»;
- 6 «Consistenza presente ma nessuna forma, a mucchietti o chiazze»;
- 7 «Liquide, senza consistenza, a pozza».

Il punteggio è facoltativo e non c'è più il chip "Diarrea": chi non sceglie un numero non può segnalare una diarrea. Aggiungere il chip «Diarrea», che imposta 6 se non è scelto un numero.

**❌N34 [C] `log_sheet.dart:128-158` — Mancano alcuni segni.**
- Pipì: «Urina scura/rossastra/color caffè», che porta a ➕N6.
- Vomito: «Corpo estraneo/erba».
- Cacca: «Vermi visibili».
- "Addome gonfio" deve esistere anche fuori dal vomito (vedi ➕N4).

### E. Scheda Emergenze (`lib/ui/emergency_screen.dart`)

**❌N35 [A, medico-legale] `emergency_screen.dart:131-136` — Il numero del CAV è mostrato all'utente con «numero da verificare prima del rilascio».**
**Correzione:** verificare prima del rilascio con il CAV Niguarda (02 6610 1029) che risponda per gli animali e a quali condizioni (alcuni CAV rispondono solo ai veterinari o a pagamento). Poi mostrare «Centro Antiveleni Ospedale Niguarda, Milano – h24». Se la verifica non è possibile, togliere il numero e lasciare solo «Chiama il tuo veterinario o il pronto soccorso».

**❌N36 [B] `emergency_screen.dart:28-32` — Primo soccorso del colpo di calore: testo prudente ma non aggiornato.**
Le evidenze più recenti indicano di raffreddare **prima** di partire, con acqua anche fredda: l'immersione in acqua fredda è sicura ed efficace. Gli asciugamani bagnati appoggiati sul cane trattengono il calore.
**Testo:** «Raffreddalo subito: bagnalo abbondantemente con acqua fresca o fredda e fai aria (ventilatore, finestrini). Non coprirlo con asciugamani bagnati. Poi vai subito dal veterinario continuando a raffreddarlo in auto, anche se sembra riprendersi.» Fonti: principio «cool first, transport second» del gruppo VetCompass/Nottingham Trent (Hall E.J. et al., riferimento esatto da verificare prima di citarlo in app); Bruchim Y. et al., *JVECC* 2017;27:1-11.

**❌N37 [B] `emergency_screen.dart:11-78` — Mancano tre situazioni frequenti in pronto soccorso.**
Aggiungere:
- «Muso gonfio, orticaria, vomito o collasso dopo una puntura d'insetto, un farmaco o un vaccino» → «Possibile reazione allergica grave: subito dal veterinario.»
- «Occhio sporgente, ferito, molto arrossato o che non riesce ad aprire; perdita improvvisa della vista» → «Non toccarlo; tienilo umido con soluzione fisiologica e vai subito.»
- «Ustioni, morso a un cavo elettrico, quasi-annegamento» → «Anche se sembra stare bene: i danni ai polmoni compaiono nelle ore successive.»

Nella voce della piometra aggiungere «o ha perdite dalla vulva».

### F. Compagno in pixel art (`lib/ui/avatar.dart`, `home_screen.dart`)

**❌N38 [B] `avatar.dart:409-416` — Il compagno è "contento" o "tranquillo" anche con un allarme "attenzione" attivo.**
Esempi: sangue nelle urine, calo di peso, sforzo della femmina, vomito ripetuto nell'adulto. Il messaggio «sta tranquillo» contraddice la scheda gialla subito sotto e banalizza il problema.
**Regola:** se c'è almeno un allarme `attenzione`, posa `idle` (mai `happy`), fumetto `Icons.visibility` e messaggio «C'è qualcosa da tenere d'occhio: leggi qui sotto.» Nessuna animazione di gioia.

**❌N39 [B] `avatar.dart:376-377` — Toccando il cane diventa felice e scodinzola anche quando è "preoccupato".**
`boost && widget.pose != Pose.sleeping ? Pose.happy`.
**Correzione:** nessun `boost` se `pose == Pose.concerned`. Con un allarme `subito` sostituire il compagno con una scheda rossa statica («Emergenza: chiama il veterinario») senza animazioni.

**❌N40 [B] `avatar.dart:427-438` — "È contento: uscita fatta!" anche se l'ultima pipì aveva sangue, sforzo o gocce.**
**Correzione:** posa `happy` solo se le registrazioni degli ultimi 30 minuti hanno `signs.isEmpty` e nessun allarme ≥ `attenzione`.

**❌N41 [B] `avatar.dart:446-468` — "Ha fame" può spingere a dare cibo nel momento sbagliato.**
Sopprimere la posa `hungry` e il messaggio se:
- nelle 12 h ci sono vomito, conati, `addomeGonfio`, `ingestione` o `inappetenza`;
- c'è un intervento pianificato (`RecordType.intervento`, `done == false`) entro 24 h, cioè un possibile digiuno pre-operatorio;
- `plan.freeFeeding` (allattamento);
- il cane è a dieta (BCS ≥ 7) e i pasti di oggi hanno raggiunto `meals`.

Nel diabetico sostituire il messaggio con «Ora del pasto: prima il pasto, poi l'insulina solo se ha mangiato.» Messaggio generale: «È l'ora del suo pasto abituale» (non "ha fame").

**❌N42 [B] `avatar.dart:508-511`, `623-628` — L'indicatore "Uscite" premia 4 uscite per tutti e conta anche le pipì in casa.**
- Per un cucciolo di 2-3 mesi servono 8-12 uscite al giorno: la barra piena a 4 suggerisce "basta così".
- Per un cane in riposo post-operatorio o cardiopatico, una barra da "riempire" spinge a uscire di più.
- `walks` somma passeggiate **e** pipì, comprese quelle `indoor`.

**Correzione:**
- contare solo `passeggiata` + `pipì && !indoor`, raggruppate a 30';
- obiettivo = numero di uscite previste dal modello per oggi (cucciolo ≥ 6);
- mostrare il numero («Uscite oggi: 5»), non una barra da riempire;
- nascondere l'indicatore se c'è un intervento negli ultimi 14 giorni o se le patologie contengono "riposo", "gabbia" o "ernia".

"Pappa": mostrare «Pasti 1/2», non una barra; nasconderlo in allattamento (`freeFeeding`) e nelle 12 h dopo vomito o ingestione. "Bisogno": va bene, ma con un'etichetta onesta («Tempo dall'ultima pipì»).

**❌N43 [C] `avatar.dart:418-424` — «${nome} dorme» è un'affermazione sul cane reale che l'app non conosce.**
**Testo:** «È la sua ora di riposo. Prima uscita prevista alle ${hh:mm}.» Se c'è una dose da dare nella notte, mostrarla al posto di "riposo".

### G. Diari e PDF

**❌N44 [C] `diaries_screen.dart:137-141` — Il timer salva anche 0 o 2 respiri.**
**Correzione:** non salvare se `taps < 4` («Misura non valida: riprova»). Offrire l'opzione 60 secondi. Mostrare la media degli ultimi 7 giorni e la baseline personale.

**❌N45 [C] `diaries_screen.dart:212-222` — L'acqua media dei 7 giorni divide per 7 anche se è registrata in 2 soli giorni.**
**Correzione:** dividere per i giorni con almeno una registrazione e dichiararlo («media su N giorni registrati»).

**❌N46 [C] `diaries_screen.dart:470` — HHHHHMM parte da 7 per ogni voce (totale 49 = "accettabile").**
L'ancoraggio orienta la risposta.
**Correzione:** partire da 5, oppure dall'ultima valutazione, e obbligare a toccare ogni voce prima di salvare.

**❌N47 [B] `pdf_export.dart` — Il PDF è utile, ma manca proprio ciò che il veterinario chiede per primo.** Aggiungere:
1. punteggi fecali (Purina) e segni (sangue, muco, nero) per giorno;
2. pipì in casa, notturne e con segni (sforzo/sangue/gocce) evidenziate nel grafico;
3. acqua in **ml/kg/die**, con il numero di giorni effettivamente registrati;
4. grafico dei respiri nel sonno (ultimi 30 giorni);
5. crisi per mese (6 mesi) con durata;
6. glicemie e insulina con orari e pasti;
7. dosi **saltate con data e ora** (non solo il totale);
8. storico riproduttivo (ultimo calore, accoppiamento, parto) per le femmine intere;
9. ultime 3 valutazioni HHHHHMM;
10. date delle segnalazioni;
11. unità accanto ai valori (`°C`, `min`, `atti/min`, `U`, `mg/dL`): oggi `pdf_export.dart:263` stampa "Temperatura: 39.6" senza unità;
12. riga iniziale «Dati inseriti dal proprietario, non verificati clinicamente».

### H. Stagionalità, razze, meteo, viaggi, spese

**❌N48 [C] `seasonal.dart:114-126` — "Levriero" fa scattare la torsione gastrica anche nel Piccolo levriero italiano (4 kg).**
**Correzione:** escludere `piccolo levriero`. Aggiungere `basset`, `bloodhound`, `irish setter` (già coperto da setter), `boxer` (rischio moderato).

**❌N49 [C] `seasonal.dart:144-153` — MDR1: aggiungere `pastore svizzero` (bianco), `mcnab`, `pastore scozzese`, `border collie` (già coperto da collie).**
Se è registrata la loperamide in un cane di queste razze → `attenzione`, «Nelle razze con possibile mutazione MDR1 la loperamide può dare effetti neurologici: verifica col veterinario.»

**❌N50 [C] `weather.dart:69-73` — Mancano tra i cani a rischio di colpo di calore:**
peso > 50 kg, Chow chow, malattie respiratorie (paralisi laringea, collasso tracheale) e il cane `BCS ≥ 7` (già presente).
**Correzione:** aggiungere `dog.weightKg >= 50` e `conditions` con `laring|trache|respir`. Testo in coda: «Asfalto: se non riesci a tenerci il dorso della mano per 7 secondi è troppo caldo per le zampe.» (Hall et al. 2020: i cani > 50 kg e i brachicefali hanno rischio più alto.)

**❌N51 [C] `modules.dart:152-156`, `173` — Viaggi.**
- Il controllo dei 21 giorni va applicato solo alla **prima** vaccinazione antirabbica, non ai richiami fatti entro la validità.
- Aggiungere «età minima: vaccino da 12 settimane, quindi viaggio da 15 settimane».
- Il riferimento «Reg. 2026/131» non è verificabile da me: va controllato sulla Gazzetta Ufficiale UE prima di citarlo, oppure va sostituito con «Reg. UE 576/2013 e successive modifiche».

**❌N52 [C] `modules.dart:124-133`, `diaries_screen.dart:900-905` — Spese.**
Il tetto di 550 € vale per contribuente, ma il calcolo è per cane: con 2 cani la stima raddoppia.
**Correzione:** sommare tutti i cani nella stessa pagina. Aggiungere «La detrazione richiede il pagamento tracciabile (carta, bancomat, bonifico).» (L. 160/2019, art. 1 c. 679).

**❌N53 [C] `main.dart:239-242` — Il testo «nessun server» non è esatto: l'avviso caldo, facoltativo, invia la città a Open-Meteo.**
**Testo:** «I dati restano solo su questo dispositivo. Solo se attivi l'avviso caldo, la città viene inviata al servizio meteo Open-Meteo.»

### I. Modello di previsione: quando i promemoria possono nuocere

| Situazione | Rischio | Regola proposta |
|---|---|---|
| **Cistite / IVU** | Il modello si adatta (fattore 0,4 e tetto ridotto) ✔. Rischio: il proprietario riduce l'acqua per uscire meno | In ogni promemoria con fattore "cistite" aggiungere «Non ridurre l'acqua: bere aiuta». Se ci sono sforzo o gocce, il promemoria lascia il posto all'allarme |
| **Ostruzione** | Ogni tentativo annotato come pipì riavvia il timer (❌N5) | Le pipì con sole gocce non azzerano il timer |
| **Incontinenza** | Gestita ✔ (perdite escluse) | Nessuna regola aggiuntiva; mai suggerire meno acqua |
| **Diabete / Cushing / renale** | Tetto ridotto ✔, ma non applicato se già superato (❌N8) | Correggere ❌N8. Nel diabetico, poliuria in aumento rispetto alla baseline = controllo glicemico da rivedere: alzare "Fa pipì più spesso" ad `attenzione` con «segnalalo al veterinario: la terapia potrebbe andare rivista» |
| **Cardiopatico in diuretico** | Rischio che il proprietario sposti o salti la furosemide per evitare le uscite notturne | Se è attivo un diuretico e la dose cade dopo le 18, mostrare nella terapia: «Non spostare né saltare il diuretico per ridurre le uscite notturne: chiedi al veterinario se si può dare al mattino.» Nessun promemoria per "più esercizio" |
| **Post-operatorio** (sterilizzazione, ortopedia, ernia discale) | I promemoria e il trigger "passeggiata" spingono a uscire e a camminare; l'indicatore "Uscite" premia il movimento; nelle prime 12-24 h può non urinare per gli oppioidi | Nuova "modalità post-operatoria" (14 giorni dall'`intervento`): promemoria «uscita breve al guinzaglio solo per i bisogni»; niente indicatore "Uscite"; anuria: "attenzione" a 12 h e "subito" a 24 h (già così). Dopo una chirurgia della colonna: «Se non riesce a urinare da solo chiama il veterinario oggi: alcuni cani devono essere aiutati a svuotare la vescica» |
| **Cucciolo di notte** | I promemoria notturni ogni 4 h a 2 mesi sono corretti. Rischio: risvegli inutili se il cucciolo dorme tranquillo; la mattina il falso "subito" (❌N9) | Promemoria notturno solo se `nightCap` cade prima del risveglio (già così) e con testo «Se dorme tranquillo nel trasportino puoi aspettare il suo segnale». Correggere ❌N9 |
| **Anziano con declino cognitivo** | Le uscite "previste" possono non coincidere con un cane disorientato | Nessuna modifica; il messaggio di nicturia c'è ✔ |
| **Femmina in calore / allattamento** | Fattori corretti ✔ | — |

---

## 4) ➕ Cosa aggiungere

### Priorità ALTA

**➕N1. Soglie della glicemia e unità di misura** (vedi ❌N2). Obbligatorio prima di offrire il diario del diabete.

**➕N2. Controllo della doppia insulina.** Due `LogType.insulina` a meno di `max(6, everyHours − 4)` ore → `subito`: «Due dosi di insulina registrate a ${h} ore di distanza. Se le hai fatte davvero, chiama subito il veterinario: rischio di ipoglicemia. Se è un errore di registrazione, cancellane una.» È un errore frequente nelle famiglie (due persone fanno l'iniezione). Consiglio collegato: nel diario diabete, il pulsante «Chi ha fatto l'insulina?» oppure un blocco visivo «Insulina di stamattina già fatta alle 7:40».

**➕N3. Post-partum e neonati** (collegati allo stato "allattamento"):
- tremori/agitazione/rigidità → subito (❌N3);
- febbre ≥ 39,5 °C, perdite maleodoranti o abbattimento nella prima settimana → oggi (metrite);
- mammelle calde, dure, arrossate → oggi (mastite);
- temperatura rettale < 37,5 °C a fine gravidanza → `info` «Il parto è atteso entro circa 24 ore»; oltre 24 h da questo calo senza travaglio → `oggi`.
- Fonte: Johnston S.D., Root Kustritz M.V., Olson P.N., *Canine and Feline Theriogenology*.

**➕N4. Evento "Collasso/svenimento" e "Addome gonfio" autonomi** (gruppo Sintomi) → `subito`. Oggi il collasso non è registrabile, e l'addome gonfio lo è solo dentro il vomito: un cane gonfio che non vomita non viene intercettato.

**➕N5. Notifiche a tempo per anuria, insulina e dosi critiche** (❌N13): sono gli unici casi in cui un allarme deve arrivare anche ad app chiusa.

**➕N6. Colore delle urine e dopo le zecche.** Segno «Urina scura/rossastra/color caffè». Con abbattimento o febbre → `oggi`: «Urine scure con abbattimento possono indicare una distruzione dei globuli rossi (es. malattie trasmesse dalle zecche come la babesiosi) o un danno muscolare.» Tra marzo e novembre aggiungere «Hai trovato zecche di recente? Dillo al veterinario.»

**➕N7. Nomi commerciali dei farmaci** (❌N11) e `DrugEffect.trilostano`.

### Priorità MEDIA

**➕N8. Modalità post-operatoria** (vedi la tabella I): riposo, controllo della ferita (arrossamento, gonfiore, secrezione → `attenzione`; deiscenza o sanguinamento → `oggi`), collare elisabettiano, prima pipì entro 24 h, appetito entro 24-48 h.

**➕N9. Forasacchi come allarme** (maggio-agosto): `pelle` con `otite` (scuote la testa) comparsa all'improvviso, oppure starnuti violenti → `oggi`, «In stagione dei forasacchi, scuotere la testa o starnutire all'improvviso dopo un prato richiede una visita oggi: prima si toglie, meno danni fa.»

**➕N10. Questionari validati per l'anziano**: CBPI (dolore), LOAD (artrosi), CCDR (disfunzione cognitiva: CCDR ≥ 50 = probabile), Muscle Condition Score (WSAVA). Fonti: Brown D.C. et al., *JAVMA* 2008;233:1278 (CBPI); Walton M.B. et al., *PLoS One* 2013 (LOAD); Salvin H.E. et al., *Vet J* 2011;188:331 (CCDR).

**➕N11. Socializzazione: precisazione igienica.** Aggiungere a `seasonal.dart:197-204`: «Finché i vaccini non sono completi evita parchi e aree con feci di cani sconosciuti; sì a cani sani e vaccinati, case di amici e classi per cuccioli con protocollo igienico.»

**➕N12. Leptospirosi e acqua stagnante.** Tip estivo-autunnale: «Non farlo bere da pozzanghere, fossi e stagni: la leptospirosi si trasmette con l'urina dei topi ed è trasmissibile all'uomo. Vomito, abbattimento e sete dopo un bagno in acque ferme → veterinario oggi.»

**➕N13. Freddo e cani piccoli/anziani**: con temperatura percepita < 0 °C, tip «Uscite brevi, cappottino per i cani a pelo raso o piccoli; asciugalo dopo la pioggia; attenzione al sale antighiaccio sui polpastrelli.»

**➕N14. Esportazione delle conferme di dose con data** e grafico della frequenza delle crisi rispetto alle dosi saltate (utile al neurologo).

### Priorità BASSA

**➕N15.** Foto dalla fotocamera, non solo dalla galleria.
**➕N16.** "Cosa dire al telefono" nella scheda Emergenze: peso, cosa ha ingerito e quanto, a che ora, farmaci in corso (generato dal profilo).
**➕N17.** Predisposizioni aggiuntive: collasso tracheale e ipoglicemia nei toy (Yorkshire, Chihuahua, Pomerania), pancreatite nello Schnauzer nano, cardiomiopatia dilatativa nel Dobermann, otiti nel Cocker, ernia discale nel Bulldog francese.
**➕N18.** Informazione sull'età della sterilizzazione nelle taglie grandi (Hart B.L. et al., *Front Vet Sci* 2020;7:388): solo «parlane col veterinario», senza raccomandare un'età.

---

## Riferimenti aggiuntivi rispetto a 06

- Hall E.J., Carter A.J., O'Neill D.G. Incidence and risk factors for heat-related illness (heatstroke) in UK dogs under primary veterinary care in 2016. *Sci Rep* 2020;10:9128.
- Hall E.J. et al. (VetCompass, Nottingham Trent University): principio «cool first, transport second» per il colpo di calore nel cane. Rivista e anno da verificare prima di citarlo in app.
- Bruchim Y., Horowitz M., Aroch I. Pathophysiology of heatstroke in dogs. *JVECC* 2017;27:1-11.
- Porciello F. et al. Sleeping and resting respiratory rates in dogs and cats with medically-controlled left-sided congestive heart failure (2016; rivista e pagine da verificare).
- Keene B.W. et al. ACVIM consensus guidelines for MMVD. *JVIM* 2019;33:1127-1140.
- Behrend E. et al. 2018 AAHA Diabetes Management Guidelines. *JAAHA* 2018;54:1-21.
- Berendt M. et al. IVETF consensus (classificazione). *BMC Vet Res* 2015;11:182.
- Squires R.A. et al. WSAVA 2024 vaccination guidelines. *J Small Anim Pract* 2024;65:277-316.
- Brown D.C. et al. CBPI. *JAVMA* 2008;233:1278-1283. Salvin H.E. et al. CCDR. *Vet J* 2011;188:331-336.
- Purina Fecal Scoring Chart (Nestlé Purina PetCare).
- Johnston S.D., Root Kustritz M.V., Olson P.N. *Canine and Feline Theriogenology*. Saunders, 2001.
