# Zampa — Revisione clinica veterinaria

Data: 10/11/2026. Revisore: medico veterinario (medicina interna del cane, medicina preventiva, comportamento).
Oggetto: codice in `lib/` (logica, modelli, testi dell'interfaccia) e rapporti `ricerca/04` e `ricerca/05`.
Metodo: lettura del codice riga per riga, confronto con le linee guida, esecuzione di `flutter test` (17 test, tutti superati).

> Sintesi in tre righe. L'impianto è serio e prudente, e i rapporti di ricerca sono in gran parte corretti. Il codice però **non applica alcune soglie che i rapporti stessi indicano come "subito dal veterinario"**: sforzo a urinare nel maschio, piometra, vomito. Mancano del tutto le urgenze più frequenti in pronto soccorso: dilatazione-torsione gastrica, colpo di calore, avvelenamento, convulsioni, dispnea. Nel piano di prevenzione ci sono tre errori di calendario: filariosi a novembre, sverminazione del cucciolo ogni 90 giorni, vaccino leishmania ogni 3 anni. In nutrizione, gravidanza e allattamento non sono gestiti e i cuccioli ricevono 2 pasti al giorno. Prima di mostrare l'app al fondatore servono le correzioni ❌ con gravità **A** (sicurezza).

Legenda della gravità: **A** = rischio per la salute del cane o rischio medico-legale, da correggere prima di qualsiasi rilascio; **B** = errore clinico o di calendario, da correggere prima del rilascio pubblico; **C** = miglioramento di testo o precisione.

---

## ✅ Cosa va bene

1. **Posizionamento corretto.** Il disclaimer ("non fa diagnosi e non sostituisce il veterinario", `lib/ui/common.dart:178-180`) e il commento di `AlertEngine` (`lib/logic/alerts.dart:15-17`) sono coerenti. Gli allarmi parlano di "segnali" e "possibili cause", non di diagnosi. L'app non suggerisce farmaci né dosi: il campo "Dose" (`lib/ui/health_screen.dart:627`) è a testo libero, compilato dal proprietario.
2. **Filosofia delle soglie.** "Meglio un avviso in più che uno in meno" (04, avvertenza) è il principio giusto per un'app per proprietari.
3. **Anuria.** L'urgenza dopo 24 h nell'adulto e dopo 8 h da sveglio nel cucciolo è corretta (`alerts.dart:39-57`). È corretto anche il richiamo esplicito ai maschi e il controllo "se non è una registrazione mancante".
4. **Diarrea nel cucciolo.** L'allarme è urgente e il testo cita disidratazione e parvovirosi (`alerts.dart:136-151`): giusto.
5. **Polidipsia > 100 ml/kg/die** (`nutrition.dart:136`) e acqua di riferimento 50-60 ml/kg/die: valori da manuale (Ettinger & Feldman, *Textbook of Veterinary Internal Medicine*, 9ª ed.; Nelson & Couto, *Small Animal Internal Medicine*, 6ª ed.).
6. **Aumento di frequenza della minzione rispetto alla baseline del singolo cane** (`alerts.dart:197-223`). L'impostazione è corretta: la frequenza "normale" di popolazione è poco nota, quindi conviene confrontare il cane con sé stesso.
7. **Nutrizione di base.** RER = 70 × peso^0,75. I fattori MER sono corretti: 1,6 per il sterilizzato, 1,8 per l'intero, 3,0 sotto i 4 mesi, 2,0 da 4 a 12 mesi. Il dimagrimento è calcolato come 1,0 × RER del peso ideale. Ogni punto BCS sopra 5 vale circa il 10% di peso in eccesso. Snack entro il 10% delle calorie, ritmo di dimagrimento dell'1-2% a settimana (AAHA 2021 Nutrition and Weight Management Guidelines, Cline et al., *JAAHA* 57:153; WSAVA Global Nutrition Guidelines 2011).
8. **Scala BCS 1-9 (Laflamme).** Le descrizioni (`nutrition.dart:138-148`) sono corrette e comprensibili.
9. **Alimenti tossici principali.** Xilitolo, uva/uvetta, cioccolato, allium, macadamia, alcol/impasto, caffeina sono presenti. È buona l'istruzione "senza aspettare i sintomi" (`nutrition_screen.dart:156`).
10. **Calendario vaccinale del cucciolo.** Core a 8, 12 e 16 settimane, con l'ultima dose non prima delle 16 settimane. Leptospirosi a 10 e 14 settimane con richiamo annuale. Core ogni 3 anni nell'adulto (WSAVA 2024, Squires et al., *J Small Anim Pract* 65:277).
11. **Controllo geriatrico semestrale** e inizio della fase senior per taglia (AAHA 2023 Senior Care Guidelines, Dhaliwal et al., *JAAHA* 59:1).
12. **Modello pipì/cacca.** I prior per età sono plausibili: mediane di 1 h a 2 mesi, 5 h nell'adulto, 4 h nell'anziano. La cacca segue il riflesso gastrocolico e l'esercizio, e il tetto senior è di 6 h. Il rallentamento intestinale dopo anestesia (×2 per 48 h) è corretto. Le correzioni per cortisonici, diuretici, diabete, Cushing, malattia renale e cistite vanno nella direzione giusta, con ordini di grandezza ragionevoli. Il modello impara dal singolo cane, e la validazione su cani sintetici con regole diverse dal simulatore interno (test) è un buon controllo, ma va dichiarato che **non è una validazione su cani reali**.
13. **Rapporti di ricerca 04 e 05.** Sono di buona qualità: le fonti sono quasi tutte corrette, i livelli di evidenza sono dichiarati con onestà e le incertezze sono segnalate (regola "mesi + 1" non validata, normativa regionale da verificare). La tabella degli allarmi di 04 §1.4 è clinicamente corretta, ed è **più prudente del codice** (vedi ❌).
14. **Privacy.** Tutti i dati restano sul dispositivo. Per i dati sanitari degli animali è la scelta più prudente.

---

## ❌ Cosa non va

Formato: **[gravità] file:riga — problema.** Perché è sbagliato. **Correzione proposta.**

### A. Allarmi clinici (`lib/logic/alerts.dart`)

**❌1 [A] `alerts.dart:77-106` — Lo sforzo a urinare è sottovalutato, soprattutto nel maschio.**
Oggi un singolo episodio di sforzo o di "poche gocce" produce solo "attenzione" ("tieni d'occhio le prossime minzioni"). Servono 2 episodi in 24 h per l'urgenza, con il testo "oggi stesso". Nel maschio, lo sforzo con poca o nessuna urina è un'**ostruzione uretrale fino a prova contraria**: calcoli che si fermano dietro l'osso penieno, cause prostatiche. Il rischio è iperkaliemia, aritmie e rottura vescicale nel giro di ore. Lo stesso rapporto 04 §1.4 prevede "qualsiasi episodio → 🔴 subito".
**Correzione:**
- Maschio, ≥ 1 episodio con `sforzo` o `gocce` nelle ultime 12 h → `AlertLevel.urgente`.
  Titolo: «Sforzo a urinare: possibile urgenza».
  Testo: «Se ${nome} si mette in posizione e non esce urina, o escono solo poche gocce, contatta **subito** il veterinario o un pronto soccorso veterinario, anche di notte. Nel maschio un blocco delle vie urinarie è un'emergenza: non aspettare il giorno dopo.»
- Femmina, 1 episodio → `attenzione`, con il testo attuale più «Se non riesce a urinare affatto, contatta subito il veterinario».
- Femmina, ≥ 2 episodi in 24 h → `urgente`, «contatta il veterinario oggi stesso. Se non esce urina, subito».
- Aggiungere a tutti i testi: «Lo sforzo per urinare e lo sforzo per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.»

**❌2 [A] `alerts.dart:58-66` — Nessuna pipì per 12-24 h: il testo non distingue il maschio e la condizione "loggingActive" può nascondere l'avviso.**
Se il proprietario registra solo le pipì, l'avviso tra 12 e 24 h non compare mai.
**Correzione:** mostrare l'avviso anche senza `loggingActive` quando il cane è sveglio da almeno 4 h, con un testo che prevede la possibilità di una registrazione mancante.
- Maschio: livello `urgente` se nelle ultime 24 h c'è anche un segno `sforzo` o `gocce`.
- Testo: «Nessuna pipì registrata da ${h} ore. Portalo fuori e osserva: se prova a urinare senza riuscirci, è abbattuto o vomita, contatta **subito** il veterinario. Se non urina entro 24 ore in totale è comunque un'urgenza.»

**❌3 [A] `alerts.dart:122`, `models.dart:290`, `log_sheet.dart:76-85` — Il vomito si conta solo se accompagnato da diarrea.**
Vomito ripetuto senza diarrea non genera nessun allarme. Lo stesso vale per i conati senza materiale, segno cardine della dilatazione-torsione gastrica (GDV), e per il vomito nel cucciolo (parvovirosi, corpo estraneo). Inoltre il vomito oggi si annota solo come "segno" di una pipì, di una cacca o di un pasto: non è un evento a sé.
**Correzione:** creare `LogType.vomito` con un sottotipo: cibo, liquido/schiuma, bile, **sangue o "fondi di caffè"**, **conati a vuoto**. Regole:
- conati a vuoto **oppure** addome gonfio (vedi ➕1) → `urgente` «Possibile emergenza: vai subito dal veterinario» (vedi testo GDV in ➕1);
- vomito con sangue o "fondi di caffè" → `urgente`, «contatta il veterinario oggi stesso; subito se è abbattuto o ha le gengive pallide»;
- cucciolo (< 6 mesi) o cane < 5 kg con ≥ 2 vomiti in 24 h → `urgente`, «Nei cuccioli e nei cani molto piccoli vomito ripetuto porta rapidamente a disidratazione e ipoglicemia: contatta il veterinario oggi stesso»;
- adulto con ≥ 3 vomiti in 24 h, oppure vomito con abbattimento o inappetenza → `attenzione`, «senti il veterinario entro 24 ore; subito se non trattiene nemmeno l'acqua, è abbattuto o ha l'addome dolente»;
- 1 vomito isolato → `info`.

**❌4 [A] `alerts.dart:123-135` — Feci nere o con sangue sono sempre "attenzione", anche nel cucciolo.**
Diarrea emorragica in un cucciolo vuol dire parvovirosi fino a prova contraria. Diarrea "a marmellata di lamponi" con vomito è la sindrome emorragica acuta (AHDS), che può portare a shock ipovolemico in poche ore. Le feci nere (melena) indicano un sanguinamento alto: ulcera da FANS o cortisonici, rodenticidi anticoagulanti.
**Correzione:**
- Cucciolo con sangue o feci nere → `urgente`, «Nei cuccioli diarrea con sangue richiede una visita **oggi stesso** (va esclusa la parvovirosi, soprattutto se non ha completato i vaccini).»
- Sangue con vomito, oppure feci nere in qualsiasi cane → `urgente`.
- Feci nere con una terapia attiva con FANS o cortisonici (vedi ❌37) → `urgente`, «Sospendi la prossima dose solo se te lo dice il veterinario e chiamalo subito: potrebbe trattarsi di un sanguinamento dello stomaco.»
- Sangue rosso isolato, cane adulto vivace → resta `attenzione`, entro 24-48 h.

**❌5 [B] `alerts.dart:107-118` — Sangue nelle urine in una femmina in calore.**
Nella femmina intera in proestro/estro il sangue vulvare è fisiologico e l'allarme oggi è un falso positivo. Al contrario, con sangue + sforzo, o sangue + abbattimento, il livello dovrebbe salire.
**Correzione:** se `dog.reproAt(now) == ReproState.calore`, mostrare un `info`: «In calore è normale una perdita di sangue dalla vulva. Se il sangue è nelle urine stesse, se si sforza o se il calore dura più di 3-4 settimane, senti il veterinario.» Se c'è sangue + sforzo/gocce → applicare ❌1. Se c'è sangue + vomito o abbattimento → `urgente`.

**❌6 [B] `alerts.dart:154-174` — La pollachiuria vera non viene rilevata.**
`if (gap >= 15 && gap < 60)` scarta gli intervalli inferiori a 15 minuti, cioè proprio i tentativi ripetuti ogni 2-10 minuti tipici di cistite e ostruzione. Il cucciolo è escluso: va bene per la frequenza, non per lo sforzo.
**Correzione:** contare tutte le pipì delle ultime 3 h senza fondere i cluster, ed escludere solo quelle registrate durante una passeggiata da un maschio intero (marcatura). Allarme se ≥ 4 eventi in 2 h fuori passeggiata, oppure ≥ 3 eventi con almeno un segno `sforzo`/`gocce`/`sangue`. Il livello sale secondo ❌1.

**❌7 [B] `alerts.dart:301-309` — "Il cucciolo non cresce" genera falsi positivi.**
L'allarme scatta anche fra due pesate a pochi giorni di distanza (`orElse: () => w.first`) e anche tra 6 e 12 mesi, quando le taglie piccole hanno già finito di crescere: un Chihuahua di 10 mesi è adulto.
**Correzione:** richiedere `days >= 14` e limitare la regola ai cuccioli < 6 mesi, oppure < 9 mesi se il peso è ≥ 10 kg. Testo: «Un cucciolo sotto i 6 mesi dovrebbe aumentare di peso ogni settimana. Se il peso è fermo da 2 settimane o cala, senti il veterinario; subito se mangia poco, vomita o ha diarrea.»

**❌8 [B] `alerts.dart:284-292` — Calo di peso: stesse soglie per tutti e nessuna distinzione col dimagrimento voluto.**
Nell'anziano e nel cane a dieta (BCS ≥ 7) la soglia va diversa. Se il cane è a dieta, il calo è voluto, ma un calo > 2% a settimana è troppo rapido.
**Correzione:**
- anziano: `attenzione` già al 5%;
- cane a dieta: calo settimanale > 2% → `attenzione`, «Sta dimagrendo troppo in fretta (oltre il 2% a settimana): parlane col veterinario per adattare la razione»;
- tutti: calo ≥ 10% in < 3 mesi → `attenzione`, «Un calo di peso non voluto ≥ 10% va sempre valutato dal veterinario, anche se mangia normalmente.»

**❌9 [C] `alerts.dart:262-264` — Errore di italiano e testo incompleto.**
"Ne vale la pena parlarne" non è corretto. **Testo proposto:** «${n} incidenti in 7 giorni in un cane adulto. Le cause possibili sono infezione urinaria, aumento della sete, incontinenza (frequente nelle femmine sterilizzate di taglia media e grande), declino cognitivo nell'anziano, oppure intervalli troppo lunghi tra le uscite. Vale la pena parlarne con il veterinario. Se le perdite avvengono mentre dorme o riposa, annotale come "perdite a riposo".»

**❌10 [B] `alerts.dart:313-322` — Il sottopeso non è segnalato.**
C'è solo l'allarme per BCS ≥ 7. Un BCS ≤ 3 in un adulto è un segno clinico: malassorbimento, endocrinopatie, neoplasie, parassiti.
**Correzione:** BCS ≤ 3 in un cane ≥ 12 mesi → `attenzione`, «Body Condition Score ${bcs}/9: è sottopeso. Prima di aumentare la razione fallo visitare, per escludere cause mediche.» BCS 6 → `info`, «Leggermente sovrappeso: riduci gli snack e ricontrolla tra un mese.»

**❌11 [B] `alerts.dart:324-339` — Una scadenza superata è sempre "info".**
Un vaccino core del cucciolo scaduto lascia un cucciolo esposto alla parvovirosi.
**Correzione:** se la voce scaduta è un vaccino core e il cane ha meno di 6 mesi → `attenzione`, «Il ciclo vaccinale del cucciolo non è completo: finché non lo è, evita aree frequentate da cani sconosciuti e chiama il veterinario per fissare la dose.»

**❌12 [B] Nessuna sorveglianza della piometra (`alerts.dart`, regola assente).**
04 §1.4 la prevede come 🔴, ma il codice non la implementa. Tutti i dati necessari sono già presenti: femmina, non sterilizzata, data del calore, frequenza delle pipì e acqua.
**Correzione:** femmina con `neutered == false`, da 2 a 12 settimane dopo l'inizio dell'ultimo calore registrato, con almeno uno tra: allarme "beve molto", allarme "pipì più spesso", vomito, perdite vulvari, abbattimento o inappetenza (vedi ➕2) → `urgente`. Testo: «In una femmina non sterilizzata, nelle settimane dopo il calore, sete e pipì aumentate, perdite dalla vulva, vomito o abbattimento possono indicare un'infezione dell'utero (piometra), che è un'urgenza. Contatta il veterinario **oggi stesso**.» Serve conservare lo storico dei calori: oggi `reproState` e `reproSince` vengono sovrascritti (vedi ➕).

### B. Prevenzione (`lib/logic/prevention.dart`)

**❌13 [A] `prevention.dart:93-103` — A novembre la filariosi viene proposta "a partire da oggi" come "stagione 2026".**
Il 10/11/2026 `year = 2026`, `heartwormStart = 1/5/2026` e `now.month <= 11`: la data proposta è oggi. Il titolo fa pensare a un inizio di stagione, che a novembre è privo di senso.
- Per un cane già protetto da maggio, la dose di novembre o di dicembre è **l'ultima dose stagionale**, utile per l'effetto retroattivo dei lattoni macrociclici sulle larve contratte nelle ultime 4-8 settimane.
- Per un cane **mai protetto** e di età > 6-7 mesi, iniziare senza test è sconsigliato da ESCCAP e AHS: possibili reazioni in cani microfilaremici. Il test antigenico (+ Knott) va fatto prima della stagione successiva.
- Il testo dice "maggio-novembre", ma ESCCAP prevede la profilassi fino a **1 mese dopo la fine** della stagione delle zanzare. Nella maggior parte d'Italia l'ultima dose cade quindi a novembre o dicembre, e lo stesso rapporto 04 indica `heartwormMonthlyToMonth = 12`.
**Correzione:**
- Mesi 5-12 con cane già in profilassi: voce «Filariosi – dose mensile (ultima della stagione a dicembre)».
- Mesi 11-12 senza profilassi registrata e cane > 7 mesi: **non** proporre l'inizio. Proporre «Filariosi: chiedi al veterinario se fare una dose ora e il test» con data = oggi, nota «Se non era protetto quest'estate, il veterinario valuterà un test (antigene + microfilarie) prima di iniziare. Il test affidabile si fa in primavera.»
- Proporre sempre «Test filariosi annuale» a marzo/aprile per i cani > 7 mesi e «Inizio profilassi filariosi ${anno+1}» al 1° maggio (1° aprile al Sud).
- Cucciolo nato in stagione: inizio entro 6-8 settimane di vita, secondo il prodotto.
- Dopo una dose a dicembre la scadenza successiva è il 1° maggio, non tra 30 giorni (vedi ❌16).
- Fonti: ESCCAP GL5 (Control of Vector-Borne Diseases in Dogs and Cats), ESCCAP Italia; American Heartworm Society Canine Guidelines 2024.

**❌14 [A] `prevention.dart:77-83` + `prevention.dart:137` — La sverminazione del cucciolo diventa trimestrale.**
Si crea un'unica voce «Sverminazione cucciolo» e, una volta fatta, `suggestedInterval` restituisce 90 giorni (`t.contains('sverm')`). ESCCAP GL1 prevede **ogni 2 settimane** da 2 settimane di vita fino a 2 settimane dopo lo svezzamento, **poi mensile fino a 6 mesi**. Il nematode *Toxocara canis*, trasmesso per via transplacentare e galattogena, è una zoonosi (larva migrans oculare e viscerale nei bambini).
**Correzione:** in `suggestedInterval`, se `t.contains('sverm')` e l'età del cane è < 10 settimane → 14 giorni; se è < 6 mesi → 30 giorni; adulto → 90 giorni (≥ 4 volte l'anno), con nota «mensile se ci sono bambini piccoli in casa, se mangia prede o carne cruda, o se è molto libero». `suggestedInterval` deve quindi ricevere il `Dog` (o la data di nascita) oltre al record.

**❌15 [A] `prevention.dart:130-135` — Il vaccino leishmania viene richiamato ogni 3 anni.**
Il preset «Leishmaniosi» (`health_screen.dart:483`) non contiene 'lepto', 'rabbia', 'tosse' o 'dose', quindi cade nel default di 3 anni. LetiFend richiede un richiamo **annuale** (scheda tecnica EMA; WSAVA 2024). La prima dose si fa da 6 mesi d'età e solo dopo un test sierologico negativo.
**Correzione:** aggiungere `if (t.contains('leish')) return const Duration(days: 365);` prima del default, con nota «Prima del vaccino serve un test negativo. Il vaccino non sostituisce il repellente.»

**❌16 [B] `prevention.dart:127-147` — Altri intervalli sbagliati o assenti.**
- `Leptospirosi – 1ª dose` finita → 365 giorni, perché `lepto` è controllato prima di `dose`. Questo crea una scadenza duplicata e sbagliata. **Correzione:** controllare `dose` (ciclo iniziale) **prima** di `lepto`/`rabbia`: «1ª dose» → 21-28 giorni (seconda dose), «2ª dose» → 365.
- `Prevenzione filariosi` → 30 giorni tutto l'anno, quindi promemoria scaduti per tutto l'inverno. **Correzione:** dopo una dose di dicembre, prossima scadenza al 1° maggio (1° aprile al Sud, impostazione per area: vedi ➕). Se il prodotto è iniettabile a lento rilascio (moxidectina), 6 o 12 mesi secondo il prodotto: aggiungere i preset «Filariosi iniettabile 6 mesi» e «Filariosi iniettabile 12 mesi».
- `Repellente anti-pappataci` → 30 giorni. I collari durano 5-12 mesi secondo il prodotto. **Correzione:** preset distinti, «Collare repellente» → nota "secondo il prodotto (es. 6 mesi)" e scadenza modificabile; «Spot-on repellente» → 21-28 giorni.
- `Test filaria/leishmania` (tipo `esame`) → nessuna scadenza. **Correzione:** 365 giorni, con data consigliata a marzo/aprile.
- `Rabbia` → 365: accettabile come scelta prudente, ma la nota deve dire «secondo la scheda tecnica del vaccino usato (1-3 anni); valido per l'espatrio 21 giorni dopo la prima vaccinazione.»
- Vaccino core adulto → 3 anni: corretto secondo WSAVA, ma alcuni vaccini commercializzati in Italia hanno ancora un richiamo annuale in scheda tecnica. Nota: «ogni 3 anni se il vaccino usato lo prevede: segui la data scritta dal veterinario sul libretto.»

**❌17 [B] `prevention.dart:59-64` — Il richiamo del cucciolo è a 52 settimane.**
WSAVA 2024 raccomanda il richiamo a **26 settimane** (opzione preferita), per proteggere i cuccioli che non hanno risposto alla serie primaria per interferenza degli anticorpi materni. La prassi a 12 mesi resta accettabile.
**Correzione:** `weeks(26)`, con nota «WSAVA 2024: richiamo a 6 mesi (in alternativa a 12 mesi, secondo il veterinario), poi ogni 3 anni secondo il vaccino.»

**❌18 [B] `prevention.dart:38-91` — Manca il recupero per cuccioli adottati tardi e per gli adulti.**
- Un cucciolo adottato a 18 settimane perde tutte le dosi passate (scartate da `date.isBefore(now - 7 giorni)`) e il piano non propone niente.
- Un cane ≥ 26 settimane non riceve **né il richiamo annuale della leptospirosi, né il core triennale, né i test annuali** (filaria, leishmania, coprologico). Riceve solo filariosi, antiparassitario esterno e visita.
**Correzione:**
- Se nessun vaccino core è registrato e il cane ha ≥ 16 settimane: «Vaccino core – verifica il libretto o fai una dose ora» (oggi), con nota «Cucciolo sopra le 16 settimane: 1-2 dosi a 2-4 settimane di distanza secondo il veterinario. Adulto senza storia vaccinale: WSAVA considera protettiva una dose dei vaccini core.»
- Lo stesso per la leptospirosi: 2 dosi a 2-4 settimane, poi annuale.
- Per tutti i cani ≥ 26 settimane senza una vaccinazione per la leptospirosi negli ultimi 12 mesi: «Leptospirosi – richiamo annuale».
- Test annuale filaria e leishmania (≥ 7 mesi): marzo/aprile, oppure prima della stagione dei flebotomi.
- Esame coprologico: 1-4 volte l'anno.

**❌19 [B] `prevention.dart:84-90` — Il promemoria anagrafe sparisce proprio quando serve.**
Il promemoria ha data a 8 settimane e viene scartato se il cucciolo ha più di 9 settimane, cioè quando di solito arriva a casa (8-12 settimane). Inoltre non controlla se il microchip è già registrato.
**Correzione:** se `dog.microchip.isEmpty`, proporre sempre «Microchip e iscrizione all'anagrafe canina» con data = max(nascita + 60 giorni, oggi). Nota: «Obbligatoria per legge (L. 281/1991; Accordo Stato-Regioni 6/2/2003; O.M. 6/8/2008): entro 60 giorni dalla nascita e comunque prima della cessione. Se hai adottato il cane, verifica che sia intestato a te (cambio di proprietà entro i termini della tua Regione). Oggi l'anagrafe confluisce nel sistema nazionale SINAC.» Se il microchip è presente, proporre invece «Verifica che l'anagrafe sia intestata a te e aggiornata».

### C. Nutrizione (`lib/logic/nutrition.dart`, `lib/models.dart`)

**❌20 [A] `models.dart:134` + `nutrition.dart:119` — I cuccioli ricevono 2 pasti al giorno.**
`mealsPerDay` vale 2 di default, quindi `mealsFor()` (4 pasti sotto i 4 mesi, 3 fino a 6 mesi) non viene mai usato. Un cucciolo toy di 8 settimane con 2 pasti è a rischio di **ipoglicemia**: tremori, debolezza, convulsioni. Il modello della cacca (`elimination_model.dart:338`) usa lo stesso valore.
**Correzione:** default `mealsPerDay = 0` (= automatico per età). Nel form mostrare "Automatico (consigliato: N)". Sotto i 6 mesi, avvisare se l'utente sceglie meno pasti di `mealsFor()`. Per i cuccioli < 3 mesi e < 5 kg suggerire 4-5 pasti, con nota «Nei cuccioli di taglia toy non saltare pasti: debolezza, tremori o sonnolenza insolita possono essere ipoglicemia (vedi Emergenze).»

**❌21 [A] `nutrition.dart:55-108` — Gravidanza e allattamento non sono considerati.**
L'app ha lo stato riproduttivo, ma per una cagna in allattamento propone 1,6-1,8 × RER, mentre il fabbisogno reale è **4-8 × RER**, oppure cibo a volontà al picco della lattazione (settimane 3-4). Con la razione proposta la cagna va in deficit energetico. Il rischio di eclampsia (ipocalcemia puerperale) dipende soprattutto dalla gestione del calcio, che l'app non deve toccare, ma la cagna deve mangiare a sufficienza.
**Correzione** (NRC 2006; AAHA 2021):
- gravidanza ≤ 42 giorni → fattore come l'adulto non sterilizzato (1,8), motivo «gravidanza, prime 6 settimane»;
- gravidanza > 42 giorni → 3,0, motivo «ultime 3 settimane di gravidanza: aumenta gradualmente; meglio un alimento per cuccioli»;
- allattamento → non mostrare grammi fissi. Testo: «In allattamento il fabbisogno arriva a 4-8 volte quello di riposo, secondo il numero di cuccioli e la settimana: lascia il cibo a disposizione (alimento per cuccioli) e acqua fresca sempre. Se trema, ansima, è agitata o barcolla, chiama **subito** il veterinario.»

**❌22 [B] `nutrition.dart:59-69` — Le razze grandi e giganti finiscono la crescita a 12 mesi.**
I cani con peso adulto atteso ≥ 25 kg crescono fino a 12-18 mesi, quelli ≥ 45 kg fino a 18-24 mesi. Passarli a 1,6 a 12 mesi è troppo presto. Inoltre, per un cucciolo di taglia grande l'app non dice che l'eccesso di calorie e di calcio causa malattie ortopediche dello sviluppo (displasia dell'anca e del gomito, osteocondrosi: Kealy et al. 2002; Hazewinkel; WSAVA).
**Correzione:**
- aggiungere al profilo «Taglia adulta prevista» (piccola, media, grande, gigante), oppure il peso adulto atteso;
- fattore di crescita 2,0 fino a 12 mesi (piccola/media), 15 mesi (grande), 18-24 mesi (gigante), scendendo a 1,6-1,8 nell'ultimo tratto, oppure usare la formula NRC per il cucciolo già riportata in 04 §2.1;
- testo fisso per i cuccioli di taglia grande: «Usa un alimento specifico "puppy large breed". Non aggiungere integratori di calcio. Mantienilo snello (BCS 4-5): crescere più in fretta non lo fa diventare più grande, aumenta invece il rischio di problemi alle articolazioni.»

**❌23 [B] `nutrition.dart:70-76` + `nutrition_screen.dart:121-124` — Il dimagrimento si calcola riducendo l'alimento di mantenimento.**
A 1,0 × RER del peso ideale, un alimento di mantenimento può non coprire proteine, vitamine e minerali (AAHA 2021: per il dimagrimento serve una dieta specifica). In più il programma parte senza visita, anche nei cani con malattie in cui il dimagrimento va gestito dal veterinario (diabete, malattia renale, cardiopatia) e anche per un BCS 7 dovuto a ipotiroidismo o Cushing.
**Correzione:** sotto le kcal, testo: «Per dimagrire con questa quota di calorie è consigliato un alimento dietetico specifico per il dimagrimento: riducendo molto la razione del cibo normale si rischiano carenze. Prima di iniziare fai visitare il cane: alcune malattie ormonali causano aumento di peso. Pesalo ogni 2 settimane.» Se `dog.conditions` non è vuoto: «Con le patologie indicate, la dieta va decisa con il veterinario.»

**❌24 [B] `nutrition.dart:77-83` — Sottopeso: si aumentano le calorie senza visita.**
**Correzione:** stesso testo di ❌10 nella scheda Nutrizione. Il fattore 1,6/1,8 sul peso ideale va bene, ma aumentando gradualmente: «Aumenta la razione gradualmente nell'arco di 1-2 settimane.»

**❌25 [B] `nutrition.dart:151-207` — La lista dei tossici è incompleta.**
Mancano le cause di avvelenamento più frequenti in Italia: farmaci umani, rodenticidi, lumachicidi, piante comuni e processionaria. Il rapporto 04 §2.4 ne elencava già alcune (farmaci umani, luppolo, cibo ammuffito, noce moscata) che non sono state riportate nel codice. La sezione si chiama "Alimenti pericolosi", ma il proprietario la userà come elenco "veleni".
**Correzione:** rinominare la sezione in «Alimenti e sostanze pericolose» e aggiungere queste voci (tra parentesi la gravità):
- Farmaci per uso umano: paracetamolo, ibuprofene, naprossene, ketoprofene, aspirina, antidepressivi, farmaci per l'ADHD, farmaci per il cuore — ulcere, insufficienza renale o epatica, convulsioni (grave). Testo: «Non dare mai farmaci per persone senza indicazione del veterinario.»
- Topicidi o rodenticidi (esche) — anticoagulanti: emorragie che compaiono 3-5 giorni dopo, anche senza sintomi iniziali; colecalciferolo: insufficienza renale (grave).
- Lumachicidi con metaldeide — tremori, convulsioni, ipertermia entro 1-3 ore (grave).
- Antigelo (glicole etilenico) — insufficienza renale acuta, sapore dolce (grave).
- Insetticidi e diserbanti (organofosfati, carbammati) e bocconi avvelenati — salivazione, tremori, convulsioni (grave). Nota: «I bocconi avvelenati vanno segnalati: il veterinario è tenuto a notificare i casi (Ordinanza del Ministero della Salute sui bocconi avvelenati, rinnovata periodicamente).»
- Cannabis e prodotti con THC — barcollamento, perdita di urina, letargia (moderata).
- Processionaria del pino (bruchi, febbraio-maggio) — necrosi della lingua, gonfiore del muso: **subito** dal veterinario e sciacquare la bocca con acqua senza strofinare (grave).
- Piante: oleandro (cuore), palma del sago (*Cycas revoluta*, fegato), tasso, mughetto, azalea/rododendro, ricino, bulbi di tulipano e narciso (grave/moderata).
- Funghi selvatici (grave).
- Alghe azzurre (cianobatteri) in laghi e stagni d'estate (grave).
- Rospi e vipere (morso di vipera: **subito** dal veterinario, tenerlo calmo, non incidere né succhiare la ferita) (grave).
- Cibo ammuffito e compost — micotossine tremorgene (grave).
- Luppolo (birra fatta in casa) — ipertermia (grave).
- Noce moscata (moderata).
- Batterie a bottone e magneti — ustioni ed ostruzioni (grave).
- Pannocchie, noccioli, giocattoli — ostruzione intestinale (moderata).
Inoltre: allineare la cipolla a 04 (soglia ≥ 5 g/kg, effetto cumulativo) e aggiungere allo xilitolo «anche dentifricio per persone, burro di arachidi "light", alcuni integratori».
Testo finale della sezione (`nutrition_screen.dart:154-157`): «Se ne ha mangiato: contatta **subito** il veterinario o un centro antiveleni, anche se sta bene. Non provocare il vomito di tua iniziativa (niente sale, acqua ossigenata o dita in gola) se non te lo dice il veterinario. Porta con te la confezione o una foto dell'etichetta.»

**❌26 [C] `log_sheet.dart:157` — L'acqua di riferimento "in totale" vale anche con dieta umida.**
Con dieta umida o mista l'acqua **bevuta** attesa è molto più bassa (10-25 ml/kg con umido, 04 §2.2), e il proprietario può allarmarsi inutilmente pensando che beva poco.
**Correzione:** «Riferimento con crocchette: ${50×kg}-${60×kg} ml al giorno. Con cibo umido beve molto meno: è normale.» In più aggiungere un avviso di calo: acqua bevuta < 20 ml/kg/die per 2 giorni con dieta secca → `attenzione`, «Beve poco: con il caldo o se è abbattuto rischia di disidratarsi.»

### D. Modello pipì/cacca (`lib/logic/bio_params.dart`, `lib/logic/elimination_model.dart`)

**❌27 [A] `elimination_model.dart:965-976` — I tetti massimi non tengono conto di malattie e farmaci.**
`latest = last + prior.maxDay`: il tetto è quello dell'età (8 h nell'adulto) anche per un cane diabetico, con Cushing, renale, con cistite o in terapia con furosemide. In questi cani trattenere 8 h significa incidenti, discomfort e, nel cistitico, peggioramento. Il modificatore (`bio_params.dart:213-315`) accorcia solo la mediana.
**Correzione:** `maxDayEff = max(120, prior.maxDay × modifier.factor)` quando `factor < 1` (es. diabete 0,4 → circa 3 h). Per i diuretici, uscita consigliata entro 1-2 h dopo ogni dose. Testo del motivo: «Con ${motivo} ha bisogno di uscire più spesso: non farlo aspettare oltre ${durata}.»

**❌28 [A] `elimination_model.dart:977-998` — Il tetto notturno si applica solo ai cuccioli.**
Per tutti gli altri, se l'uscita consigliata cade nella finestra di sonno, l'app dice «prima uscita al risveglio» anche se l'ultima pipì risale a molte ore prima. Esempio: un anziano con ultima pipì alle 18 e sonno 23-7 arriva a 13 h. Anziani, cani in poliuria e cani con diuretici/cortisonici non dovrebbero mai ricevere questo messaggio.
**Correzione:** applicare `nightCap` a tutte le età. Se `last + maxNight` (scalato come in ❌27) precede il risveglio, proporre un'uscita prima di andare a dormire (`sleepStart − 15'`) se è ancora nel futuro, altrimenti un'uscita notturna. Testo per anziano o PU/PD: «Dall'ultima pipì passerebbero più di ${h} ore: fallo uscire prima di dormire. Se si sveglia e chiede di uscire durante la notte, assecondalo.» Inoltre, per l'anziano e per i cani con PU/PD, nicturia nuova = segnale clinico (04 §1.4): aggiungere l'allarme (vedi ➕).

**❌29 [B] `bio_params.dart:109-116` (+ etichetta `potty_screen.dart:106`) — Per i cuccioli svegli "mesi + 1 ore" è un tetto troppo alto, ed è mostrato come "attesa massima consigliata".**
La regola "mesi + 1" vale per il cucciolo **a riposo o nel trasportino**, non per un cucciolo sveglio che gioca, mangia e beve: a 8-10 settimane da sveglio serve un'uscita ogni 30-60 min più dopo ogni innesco (AVSAB; Landsberg et al., *Behavior Problems of the Dog and Cat*, 3ª ed.). Mostrare "Attesa massima consigliata: 3 h" a un neo-proprietario di un cucciolo di 2 mesi lo induce a lasciarlo 3 h senza uscire. Il proprietario lo leggerà come obiettivo, e alla lunga questo porta a incidenti e a un apprendimento lento.
**Correzione:** tetti diurni da sveglio:

| Età (mesi) | maxDay attuale (min) | maxDay proposto (min) | maxNight (min) |
|---|---|---|---|
| 2 | 180 | **120** | 240 (invariato) |
| 3 | 240 | **180** | 300 |
| 4 | 300 | **240** | 390 |
| 5 | 360 | **300** | 450 |
| 6 | 420 | **360** | 510 |
| 12 | 480 | 480 | 600 |

Etichetta: «Tetto massimo (non un obiettivo)», con la nota «Da sveglio un cucciolo va portato fuori più spesso: al risveglio, dopo i pasti, dopo il gioco.» Correggere di conseguenza 04 §1.2 e §1.5: "mesi + 1" vale **a riposo**.

**❌30 [B] `models.dart:44-54` + `dog_form.dart:180-192` — L'etichetta "Massima (mai incidenti)" promette troppo, e "Meno uscite" è disponibile per tutti.**
"Mai incidenti" è una promessa che l'app non può mantenere. Con l'opzione "Meno uscite" (quantile 0,40) un cucciolo, un anziano o un cane malato viene fatto aspettare di più.
**Correzione:** etichette «Massima (meno incidenti)», «Equilibrata», «Meno uscite (solo adulti sani)». Disabilitare "Meno uscite" se il cane è cucciolo, anziano, ha `conditions` non vuoto o ha una terapia diuretica/cortisonica attiva.

**❌31 [B] `bio_params.dart:252` — Riconoscimento delle malattie con sottostringhe ambigue.**
`'irc'` è contenuto in "c**irc**a" e "c**irc**olazione", e `'ivu'` è a rischio di falsi positivi: "Patologie note: circa 2 anni fa otite" diventa "malattia renale".
**Correzione:** usare espressioni regolari a parola intera (`\birc\b`, `\bivu\b`). Meglio ancora: una lista di patologie a scelta multipla (diabete mellito, Cushing, malattia renale cronica, cistite/calcoli, incontinenza, cardiopatia, epilessia, ipotiroidismo, Addison, epatopatia, artrosi, disfunzione cognitiva), con un campo libero aggiuntivo.

**❌32 [B] Incontinenza (`models.dart:321`, `alerts.dart:252-268`, modello).**
Le perdite a riposo di una femmina sterilizzata con incontinenza da incompetenza sfinterica oggi si possono registrare solo come "pipì in casa". In questo modo (a) accorciano l'intervallo appreso, (b) fanno scattare "pipì in casa ripetute" come se fosse un problema di educazione, e (c) il cane viene portato fuori più spesso senza beneficio. Se il cane è incontinente non bisogna limitare l'acqua: il rischio è che il proprietario lo faccia.
**Correzione:** nuovo evento «Perdita a riposo / bagnato al risveglio» che non azzera il timer e non entra nel modello. Allarme dedicato `attenzione`: «Perdite di urina mentre dorme o riposa: spesso è un problema curabile (incontinenza). Parlane col veterinario. Non ridurre l'acqua.»

**❌33 [C] `models.dart:186` — La durata della gravidanza è fissata a 65 giorni.**
Calcolata dall'accoppiamento, la gravidanza dura 57-72 giorni (63 ± 2 dall'ovulazione). A 66 giorni l'app torna a "nessuno" mentre la cagna può essere ancora gravida: proprio il momento in cui servono le avvertenze sul parto.
**Correzione:** limite a 72 giorni. Dal giorno 58 mostrare la scheda "Parto" (vedi ➕). Oltre il giorno 70 senza parto registrato → `attenzione`, «Oltre 70 giorni dall'accoppiamento senza parto: senti il veterinario.»

### E. Testi, comunicazione e aspetti medico-legali

**❌34 [A] `common.dart:178-180` — Il disclaimer non dice cosa fare in emergenza.**
**Testo proposto:** «Zampa aiuta a osservare e organizzare: non fa diagnosi e non sostituisce la visita veterinaria. **In emergenza** (fatica a respirare, gengive pallide o blu, addome gonfio con conati a vuoto, collasso, convulsioni, sospetto avvelenamento, sforzo a urinare senza risultato, colpo di calore) contatta **subito** il veterinario o il pronto soccorso veterinario più vicino.» Il disclaimer va anche mostrato e accettato al primo avvio, insieme alle condizioni d'uso.

**❌35 [A] Tempistiche non uniformi negli allarmi (`alerts.dart`, tutti i testi).**
Lo stesso livello `urgente` oggi vuol dire "contatta il veterinario" (cucciolo), "oggi stesso" (sforzo) o "subito" (anuria). Il proprietario deve sapere **quando**.
**Correzione:** ogni allarme deve chiudersi con una di queste quattro frasi fisse, legate al livello:
- 🔴 **Subito** — «Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.»
- 🟠 **Oggi** — «Contatta il veterinario oggi stesso.»
- 🟡 **24-48 h** — «Prenota una visita nei prossimi 1-2 giorni; prima se peggiora.»
- ⚪ **Prossima visita** — «Parlane alla prossima visita.»
Serve un quarto livello: `AlertLevel` va esteso in `info`, `visita`, `oggi`, `subito`. Ogni allarme 🔴/🟠 deve avere il pulsante «Chiama il veterinario» (`dog.vetPhone`) e «Pronto soccorso».

**❌36 [B] Linguaggio quasi diagnostico.**
Formule come «possibile ostruzione o cistite» (`alerts.dart:89-90`) o «es. infezione urinaria, diabete, problemi renali» (`alerts.dart:219-220`) sono accettabili come esempi, ma conviene usare uno schema fisso: «Può essere un segno di… (solo il veterinario può dirlo con una visita).» Non usare mai frasi che **rassicurano** («è normale», «non è niente»), salvo casi davvero fisiologici e circoscritti, come il calore (❌5).

**❌37 [B] Farmaci: il riconoscimento automatico (`models.dart:78-112`) è utile ma incompleto per la sicurezza.**
- Mancano FANS (meloxicam, carprofen, robenacoxib, firocoxib, cimicoxib, mavacoxib) e la loro combinazione con i cortisonici, rischiosa per ulcere gastrointestinali.
- Manca l'insulina (vedi ➕).
- Mancano trilostano e mitotano: riducono la poliuria del Cushing e il loro effetto collaterale è l'iposurrenalismo (vomito, debolezza → subito dal veterinario).
- Manca il metronidazolo (feci molli; effetti neurologici ad alte dosi).
- Il tramadolo è classificato come "antidiarroico": accettabile solo per l'effetto sul transito.
**Correzione:** aggiungere `DrugEffect.fans`, con allarme `urgente` se compaiono vomito, feci nere o inappetenza durante la terapia («Durante una terapia con antinfiammatori, vomito, feci nere o perdita di appetito vanno segnalati **subito** al veterinario»), più un `info` se FANS e cortisonico sono attivi insieme («Antinfiammatori e cortisone insieme aumentano il rischio di ulcere: verifica col veterinario che sia voluto»). In nessun caso l'app suggerisce dosi o sospensioni: deve rimandare al veterinario. Nel campo dose: «come prescritta dal veterinario».

### F. Rapporti di ricerca

**❌38 [C] `ricerca/04` §1.2 e §1.5 — "Mesi + 1 ore di giorno, da sveglio".**
Come in ❌29: la regola vale a riposo. Da sveglio servono uscite molto più frequenti.

**❌39 [C] `ricerca/04` §2.4, riga della cipolla — Soglie contraddittorie nella stessa cella.**
"≥ 15-30 g/kg" e "≥ 0,5% del peso corporeo" (= 5 g/kg) non sono la stessa soglia. **Correzione:** «Alterazioni ematologiche da ≈ 5 g/kg (0,5% del peso) in un'unica assunzione; quadri clinici con 15-30 g/kg; effetto cumulativo con piccole dosi ripetute.»

**❌40 [C] `ricerca/04` §1.4 — Le soglie della tabella sono più prudenti del codice.**
Sforzo, piometra, incontinenza, nicturia, sangue con segni sistemici: va aggiunta una nota "da implementare", oppure il codice va allineato (❌1, ❌12, ❌32, ❌28).

**❌41 [C] `ricerca/04` §3.3 — Riferimenti normativi del SINAC.**
D.Lgs. 134/2022 è corretto come istituzione del sistema I&R. Il decreto attuativo per gli animali da compagnia («D.M. 2 novembre 2023») e le scadenze regionali vanno **verificati sulla Gazzetta Ufficiale** prima di citarli in app. Nel testo per l'utente conviene restare generici: «entro i termini della tua Regione».

**❌42 [C] `ricerca/04` §3.2 — Le aree endemiche della leishmaniosi vanno aggiornate.**
Oggi sono descritte come "Centro-Sud, isole, zone costiere, focolai al Nord". In realtà la malattia è ormai endemica anche in molte aree collinari del Nord: Piemonte, Liguria, Emilia-Romagna, Veneto, Lombardia prealpina (Maroli et al. 2008; Mendoza-Roldan et al. 2020; ESCCAP Italia). Per l'app conviene proporre i repellenti a **tutti** i cani da aprile a novembre, salvo diversa indicazione del veterinario.

---

## ➕ Cosa aggiungere

### Priorità ALTA (prima di mostrare l'app al fondatore o comunque prima del rilascio)

**➕1. Scheda "Emergenze" sempre raggiungibile** (pulsante rosso nella Home e nella barra). Contiene:
- **Chiama il mio veterinario** (`vetPhone`) e un campo per un **pronto soccorso veterinario h24** di riferimento, inserito dall'utente. Più un pulsante «Cerca pronto soccorso veterinario vicino a me», che apre la mappa del sistema con la ricerca "pronto soccorso veterinario 24 ore" (nessun dato inviato a server propri).
- **Centro antiveleni.** Il CAV dell'Ospedale Niguarda di Milano (02 6610 1029, h24) risponde anche per gli animali. **Numero da verificare prima del rilascio**, come già indicato in 04. Non inserire numeri non verificati.
- **"Vai subito dal veterinario se…"**, una lista breve con un rigo di spiegazione per ciascuna voce:
  1. **Addome gonfio, conati di vomito senza vomitare, salivazione, irrequietezza**, soprattutto nei cani grandi a torace profondo (Alano, Pastore tedesco, Setter, Weimaraner, Dobermann, Bovaro) → possibile **dilatazione-torsione gastrica**: ogni minuto conta.
  2. **Fatica a respirare**, respiro a bocca aperta a riposo, gengive blu o grigie.
  3. **Gengive pallide o bianche**, collasso, debolezza improvvisa.
  4. **Convulsione** che dura più di 5 minuti, oppure 2 o più convulsioni in 24 h, oppure il cane non si riprende tra una crisi e l'altra.
  5. **Colpo di calore**: ansimare violento, lingua rosso scuro, barcollamento, vomito o diarrea dopo caldo o sforzo (a rischio i brachicefali: Bulldog, Carlino, Boxer). Primo soccorso: all'ombra, bagnarlo con acqua fresca, non ghiacciata, e ventilarlo. **Andare subito dal veterinario anche se sembra riprendersi.**
  6. **Sospetto avvelenamento** (vedi lista dei tossici), **morso di vipera**, **contatto con processionaria**.
  7. **Sforzo a urinare senza risultato** (soprattutto nei maschi), **nessuna pipì da 24 h**.
  8. **Cucciolo con vomito e/o diarrea** (soprattutto con sangue) e abbattimento: possibile **parvovirosi**, specie se non ha completato i vaccini.
  9. **Cucciolo toy debole, tremante, che non si sveglia bene**: possibile **ipoglicemia**. Primo soccorso: un po' di miele o sciroppo di glucosio strofinato sulle gengive se è cosciente (mai versare liquidi in bocca a un cane incosciente), poi subito dal veterinario.
  10. **Femmina non sterilizzata abbattuta, che beve molto, vomita o ha perdite dalla vulva** nelle settimane dopo il calore: possibile **piometra**.
  11. **Parto**: contrazioni forti per più di 30 minuti senza nascita di un cucciolo; più di 2 ore tra un cucciolo e l'altro; perdite verdi o nere senza cuccioli; gravidanza oltre 70 giorni.
  12. **Cagna che allatta** con tremori, ansimare, rigidità o agitazione: possibile **eclampsia** (ipocalcemia).
  13. Trauma (investimento, caduta), anche se sembra stare bene; ferite profonde; occhio sporgente o dolente.
  14. Sangue dalla bocca, dal naso o dall'ano senza causa evidente; feci nere.
  15. Dolore intenso: guaisce quando viene toccato, schiena arcuata, non si muove.
- Fonti: Silverstein & Hopper, *Small Animal Critical Care Medicine*, 3ª ed.; Ettinger & Feldman 9ª ed.; per le convulsioni, la classificazione IVETF 2015 (Berendt et al., *BMC Vet Res* 11:182).

**➕2. Nuovi segni ed eventi registrabili** (`models.dart:266` LogType, `models.dart:290` Sign), ognuno collegato alle regole d'allarme:

| Da aggiungere | Tipo | Regola minima |
|---|---|---|
| Vomito (cibo, schiuma/bile, sangue, conati a vuoto) | evento | ❌3 |
| **Inappetenza** (non ha mangiato il pasto) | segno sul pasto | cucciolo ≥ 1 pasto saltato con abbattimento → oggi; adulto ≥ 24 h → 24-48 h; ≥ 48 h → oggi; anziano/diabetico 1 pasto → oggi |
| **Abbattimento/letargia** | evento | con vomito, diarrea, febbre, pallore → oggi/subito |
| **Addome gonfio** | evento | con conati a vuoto o irrequietezza → subito |
| **Respiro affannoso a riposo / tosse** | evento | dispnea → subito; tosse > 3 giorni o con febbre/abbattimento → 24-48 h; tosse in cardiopatico → oggi |
| **Frequenza respiratoria a riposo (atti/minuto durante il sonno)** | misura | > 30 per 2 misure → oggi; > 40 → subito (ACVIM 2019, Keene et al., *JVIM* 33:1127) |
| **Gengive** (rosa, pallide, blu, gialle, rosso scuro) | segno | pallide/blu → subito; gialle → oggi |
| **Convulsione** (ora di inizio, durata, recupero) | evento | > 5 min o ≥ 2 in 24 h → subito; prima crisi → oggi |
| **Zoppia** (arto, carica sì/no) | evento | non carica l'arto → oggi; zoppia > 3-5 giorni → 24-48 h |
| **Prurito / grattamento, perdita di pelo, lesioni cutanee, otite (scuote la testa)** | evento | 24-48 h |
| **Tremori, barcollamento, testa inclinata** | evento | oggi; subito se acuto |
| **Temperatura rettale** | misura | 38,0-39,2 °C normale; ≥ 39,5 → oggi; ≥ 41 o < 37 → subito |
| **Perdita a riposo (incontinenza)** | evento | ❌32 |
| **Perdite vulvari** (femmina intera) | segno | ❌12 |
| **Consistenza delle feci con la scala Purina 1-7** (foto facoltativa) | punteggio sulla cacca | 2 = ideale; 5-7 = diarrea (sostituisce il booleano `diarrea`); 1 = troppo dure. Usare la scala Purina o la scala Waltham per il cane, non la scala di Bristol (che è umana) |
| **Ha ingerito qualcosa** (sostanza, quantità, ora) | evento | apre la scheda Emergenze con "chiama subito" |

**➕3. Promemoria delle terapie affidabili, con conferma "somministrato".**
Oggi `_reschedule` (`store.dart:254-266`) programma solo **la prossima dose**: se l'app non viene aperta, le dosi successive non vengono notificate. Per insulina, antiepilettici, cardiologici e terapie del Cushing questo è un rischio clinico. Servono:
- programmare tutte le dosi delle prossime 48-72 h;
- un pulsante "Dato" o "Saltato" nella notifica;
- una cronologia delle somministrazioni da esportare per il veterinario;
- un avviso «Dose non confermata da 2 h» con il testo «Se hai saltato una dose non raddoppiare la successiva: chiedi al veterinario cosa fare.»
L'app non deve mai suggerire come recuperare la dose.

**➕4. Modulo diabete** (attivo se tra le patologie c'è "diabete" o se è registrata un'insulina):
- diario insulina: ora, unità **prescritte dal veterinario**, inserite dall'utente, mai calcolate; pasto prima dell'insulina sì/no;
- regola fissa da mostrare: «Se non ha mangiato o ha vomitato, non fare l'insulina senza aver sentito il veterinario.»;
- segni di **ipoglicemia** (debolezza, tremori, barcollamento, convulsioni) → subito, primo soccorso con miele o glucosio sulle gengive;
- acqua bevuta e pipì come indicatori di controllo; peso settimanale;
- glicemie a domicilio (se usate) e curve, solo come registro.
Fonte: AAHA 2018 Diabetes Management Guidelines (Behrend et al., *JAAHA* 54:1); ISFM/ESVE ALIVE.

**➕5. Diario delle crisi epilettiche**: data, ora, durata, tipo (generalizzata/focale), fase post-critica, possibili fattori scatenanti, terapia e dosi confermate. Allarmi: crisi > 5 min, ≥ 2 crisi in 24 h (cluster), aumento della frequenza mensile. Grafico mensile da mostrare al neurologo. Fonte: IVETF 2015 consensus (Bhatti et al., *BMC Vet Res* 11:176; Berendt et al. 11:182).

**➕6. Area geografica e stagionalità** (Nord, Centro, Sud e isole; eventualmente provincia). Serve per:
- filariosi: Nord maggio-dicembre; Centro maggio-dicembre; Sud e isole aprile-dicembre o tutto l'anno;
- repellenti contro i flebotomi: aprile-novembre, tutto l'anno al Sud se indicato;
- zecche: marzo-novembre al Nord, tutto l'anno al Centro-Sud;
- avvisi stagionali: processionaria (febbraio-maggio), forasacchi (maggio-agosto: «controlla orecchie, zampe e narici dopo i prati»), colpo di calore (giugno-settembre: «non lasciarlo mai in auto, passeggiate al fresco»), veleni per lumache e topi (autunno-primavera), petardi a Capodanno (comportamento).
Fonte: ESCCAP Italia GL1/GL3/GL5.

**➕7. Storico riproduttivo della femmina** (calori, accoppiamenti, gravidanze, parti, sterilizzazione), invece del solo stato corrente. Serve per la piometra (❌12), per il calcolo del parto (accoppiamento + 63 giorni ± 5), per la pseudogravidanza (6-9 settimane dopo il calore) e per sapere dopo quanto ricompare il calore (in media ogni 6-7 mesi; un calore persistente oltre 4 settimane → visita).

**➕8. Validazione formale dei testi.** Tutti i testi degli allarmi e della scheda Emergenze devono essere rivisti e approvati da un medico veterinario abilitato prima del rilascio (04 §5.6), con la versione registrata. Le condizioni d'uso devono dire che l'app non è un dispositivo medico e non sostituisce la visita, e che in Italia la diagnosi e la prescrizione dei farmaci veterinari (ricetta elettronica veterinaria, D.Lgs. 218/2023 e normativa sul farmaco veterinario) sono atti riservati al medico veterinario.

### Priorità MEDIA

**➕9. Qualità della vita e dolore nel cane anziano.**
- Scala HHHHHMM (Villalobos): 7 voci da 0 a 10, ogni 1-2 settimane, con grafico; < 35 → «parlane col veterinario».
- Dolore cronico: CBPI (Canine Brief Pain Inventory) o LOAD per l'artrosi; Helsinki Chronic Pain Index.
- Disfunzione cognitiva: questionario CCDR o CADES (disorientamento, ciclo sonno-veglia, sporcare in casa, interazione).
- Muscle Condition Score (WSAVA).
Fonte: AAHA 2023 Senior Care; AAHA 2022 Pain Management Guidelines (Gruen et al., *JAAHA* 58:55).

**➕10. Cartella degli esami con valori**: emocromo, biochimico, esame delle urine con peso specifico, UPCR, pressione arteriosa, T4, SDMA, test filaria/leishmania con titolo. Va previsto inserimento manuale o foto del referto, grafico nel tempo e campo per gli intervalli di riferimento del laboratorio. L'app **non** interpreta i valori: mostra solo l'andamento ed evidenzia i valori fuori dal range indicato dal laboratorio. Utile per malattia renale cronica (IRIS), Cushing, leishmaniosi (staging LeishVet).

**➕11. Cardiopatia**: frequenza respiratoria a riposo con timer di 30 secondi e soglie ACVIM (vedi ➕2), tosse notturna, tolleranza all'esercizio, terapie (pimobendan, diuretici) con conferma della dose.

**➕12. Allarme nicturia** (04 §1.4): ≥ 2 notti su 7 con pipì notturna in un cane prima "asciutto" → visita programmata.

**➕13. Notifica degli allarmi urgenti.** Se il proprietario ha attivato i promemoria, un allarme 🔴 calcolato in background va notificato, ad esempio "nessuna pipì da 24 h" per un cane maschio che ha registrato sforzo.

**➕14. Promemoria comportamentali e di socializzazione per il cucciolo**: finestra di socializzazione 3-14 settimane (AVSAB Position Statement on Puppy Socialization 2008: la socializzazione inizia prima della fine dei vaccini, in ambienti controllati), corsi per cuccioli, abituazione al trasportino e alla manipolazione. Per l'educazione al bisogno: «Premia subito, fuori, appena ha fatto. Non punire gli incidenti: pulisci con un detergente enzimatico.»

**➕15. Igiene dentale**: promemoria spazzolamento (quotidiano o almeno 3 volte a settimana) e controllo dentale annuale; segnalazione di alitosi, sanguinamento gengivale e difficoltà a masticare (AAHA 2019 Dental Care Guidelines).

**➕16. Esportazione per il veterinario in PDF**, con i grafici di frequenza di pipì, cacca, acqua e peso, gli allarmi delle ultime settimane e le terapie con le conferme di somministrazione.

### Priorità BASSA

**➕17.** Foto di feci e lesioni con data, per il confronto nel tempo (senza alcuna analisi automatica diagnostica).
**➕18.** Viaggi: checklist per il passaporto europeo (microchip, rabbia ≥ 21 giorni, trattamento contro *Echinococcus* per Regno Unito, Irlanda, Finlandia, Norvegia e Malta), rischi parassitari della destinazione.
**➕19.** Assicurazione e spese: riepilogo annuale per la detrazione.
**➕20.** Termometro ambientale o meteo per gli avvisi di colpo di calore: più di 25-27 °C con umidità alta → avviso per brachicefali, anziani, obesi e cardiopatici.
**➕21.** Taglia o razza con predisposizioni note: torsione gastrica nelle razze giganti, urolitiasi da urati nel Dalmata, MDR1 nei Collie e Pastori australiani («chiedi al veterinario il test MDR1 prima di usare alcuni antiparassitari»), problemi respiratori nei brachicefali. Solo come informazione, senza diagnosi.

---

## Riferimenti principali

- WSAVA 2024 Guidelines for the Vaccination of Dogs and Cats — Squires R.A. et al., *J Small Anim Pract* 2024;65:277-316.
- AAHA 2022 Canine Vaccination Guidelines — Ellis J. et al., *JAAHA* 2022;58:213-230.
- ESCCAP GL1 (Worm control), GL3 (Ectoparasites), GL5 (Vector-borne diseases); ESCCAP Italia, www.esccap.it.
- American Heartworm Society, Canine Guidelines (aggiornamento 2024).
- LeishVet — Solano-Gallego L. et al., *Parasit Vectors* 2011;4:86.
- AAHA 2021 Nutrition and Weight Management Guidelines — Cline M.G. et al., *JAAHA* 57:153-178; WSAVA Global Nutrition Guidelines 2011; NRC 2006 *Nutrient Requirements of Dogs and Cats*.
- AAHA 2019 Canine Life Stage Guidelines — Creevy K.E. et al., *JAAHA* 55:267-290; AAHA 2023 Senior Care — Dhaliwal R. et al., *JAAHA* 59:1-21.
- ISCAID 2019 Urinary tract infection guidelines — Weese J.S. et al., *Vet J* 247:8-25.
- ACVIM 2019 MMVD consensus — Keene B.W. et al., *J Vet Intern Med* 33:1127-1140.
- ACVIM 2013 Cushing's consensus — Behrend E.N. et al., *J Vet Intern Med* 27:1292-1304.
- AAHA 2018 Diabetes Management Guidelines — Behrend E. et al., *JAAHA* 54:1-21.
- IVETF 2015 consensus statements (epilessia) — *BMC Vet Res* 11:176 e 11:182.
- AAHA 2022 Pain Management Guidelines — Gruen M.E. et al., *JAAHA* 58:55-76.
- Ettinger S.J., Feldman E.C., Côté E., *Textbook of Veterinary Internal Medicine*, 9ª ed.; Nelson R.W., Couto C.G., *Small Animal Internal Medicine*, 6ª ed.; Silverstein D., Hopper K., *Small Animal Critical Care Medicine*, 3ª ed.
- Landsberg G., Hunthausen W., Ackerman L., *Behavior Problems of the Dog and Cat*, 3ª ed. 2013; AVSAB Position Statement on Puppy Socialization 2008.
