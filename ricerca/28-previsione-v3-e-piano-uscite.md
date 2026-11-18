# 28 — Previsione v3 e piano di uscite: zero incidenti con meno uscite

*13 novembre 2026. Branch `claude/lulu-previsione-v3` (da `claude/lulu-previsione-pipi`). Seguito di `ricerca/27`. Convenzioni come in `ricerca/12`, `23` e `27`: **[MISURATO]** = numero del banco di prova (simulazione, non cani veri); **[STIMA]** = giudizio; **[IPOTESI]** = parametro del simulatore o del modello scelto senza dati, da misurare nella beta. Tra parentesi quadre l'IC 95% bootstrap per cane. R = Σ<sub>cani</sub> errore mediano / Σ<sub>cani</sub> errore mediano del riferimento (sotto 1 = meglio). Allegato: `ricerca/28-allegato-registrazione.md` (notifiche, geofence, widget). Materiali della beta: `ricerca/beta/`.*

---

## 0. Sintesi per chi non è tecnico

**L'obiettivo.** Passare da «prevedere la prossima pipì» ad «aiutare chi ha il cane in appartamento senza giardino ad avere meno incidenti possibile con il minor numero di uscite». (Nei testi per gli utenti «zero incidenti» resta una **domanda dello studio**, non una promessa: è una frase vietata, `08` §11.3.)

**Cosa c'è di nuovo nell'app** (tutto nella schermata pipì/cacca, segnato «in prova»):
1. **Segnali con un tocco**: annusa a terra, gira su sé stesso, va alla porta, guaisce, è irrequieto. Dopo un segnale l'app dice subito **«Esci adesso»** e impara quanto quel segnale, per quel cane, annuncia davvero un bisogno.
2. **Cacca legata ai pasti**: «Prossima cacca verso le 19:40. Di solito la fa dopo il pasto delle 19:00».
3. **Piano di uscite**: il padrone dice quando è fuori casa e sceglie 3, 4 o 5 uscite; l'app propone gli orari e dice il rischio a parole («rischio basso: meno di un incidente al mese»). Si rifà ogni giorno con i dati nuovi e avvisa se un intervallo supera il limite per l'età del cane.
4. **Registrare senza fatica**: nella notifica del promemoria i bottoni «Fatta ✓» e «Non ancora» (Android); la logica per riconoscere l'uscita da casa è pronta ma non ancora collegata al GPS; il widget è progettato.
5. **Beta**: invito, modulo di adesione (pagina senza server), consenso separato, istruzioni ed esportazione anonima dall'app sono pronti come bozze.

**Com'è andata sul banco di prova** (simulazione: 32 cani in appartamento per 4 settimane, padroni che lavorano fuori casa, a metà tempo o a casa):
- **Il piano di uscite** con 4 uscite fa **meno incidenti degli orari fissi con 4 uscite, uscendo meno**: 1,5 incidenti a settimana per cane contro 1,8, con 5,3 uscite al giorno contro 5,9 (contano anche le uscite chieste dal cane). La differenza di incidenti è piccola e incerta; quella di uscite è chiara.
- **I segnali aiutano più di tutto il resto**: con il padrone che li segna e segue «Esci adesso», gli incidenti scendono in media di circa un quinto (dal 5% al 34% secondo la strategia; per esempio da 1,8 a 1,5 a settimana con gli orari fissi), al prezzo di circa una uscita in più al giorno. **Piano con 3 uscite + segnali** fa gli stessi incidenti degli orari fissi con 4 uscite + segnali (1,5) con **1,4 uscite in meno** al giorno (in 2 semi su 3; nel terzo fa un po' peggio, 1,67 contro 1,48).
- Seguire ogni avviso della previsione v2 dà il minimo di incidenti (1,2-1,4) ma con **11-12 uscite al giorno**: non è un piano sostenibile.
- Il rischio dichiarato dal piano è onesto per la pipì: dice 0,8-1,0 incidenti a settimana e se ne vedono 0,9. La cacca non è ancora nel conto del rischio.
- **Cuccioli**: 3-5 incidenti a settimana con qualsiasi strategia, soprattutto quando il padrone è fuori tutto il giorno. Il piano lo dice; serve un aiuto (dog sitter, vicino), non un orario.
- **La cacca**: l'errore tipico passa da circa 5 ore (ciò che l'app mostra oggi) a circa 1 ora e 45. Batte il timer, ma **non abbastanza da superare la soglia** che mi ero dato (0,86 contro 0,85 sul banco nuovo). Dove è il padrone a decidere le uscite, il modello con i pasti è nettamente migliore (0,68).

**Cosa non ha funzionato.** La prima regola della cacca, scritta prima della verifica, non ha superato la prova (0,97). Nella prima versione del piano i segnali facevano sembrare il cane molto meno capace di trattenerla di quanto è (rischio dichiarato 4 volte quello vero) e la cacca era ignorata. Le correzioni sono dichiarate e provate su banchi nuovi (§2.3, §3.4).

**Prossimo passo.** La beta con cani veri, con l'emendamento del protocollo per piano, segnali e uscite al giorno (§5). I numeri di questo rapporto vengono da una simulazione con ipotesi forti sul comportamento dei cani e dei padroni: **non vanno citati fuori dal progetto**.

---

## 1. Cosa ho fatto e come riprodurlo

| File | Cosa fa |
|---|---|
| `lib/logic/potty_signals.dart` | Segnali del cane (annusa a terra, gira su sé stesso, va alla porta, guaisce, è irrequieto): «Esci adesso» per 20 minuti dopo un segnale, probabilità imparata sul cane |
| `lib/logic/poop_forecast.dart` | Cacca legata ai pasti: modello «ad ancore» (pasti e uscite abituali, colon pronto, cacca «spontanea»), combinato con «stesso orario» e timer; finestre dai residui del cane |
| `lib/logic/outing_plan.dart` | Piano di uscite: tenuta del cane imparata dallo storico, orari del padrone, programmazione dinamica per N uscite, rischio stimato |
| `lib/logic/study_export.dart` | Esportazione anonima per lo studio (solo con consenso) |
| `lib/logic/quick_actions.dart`, `outing_geofence.dart`, `lib/notifications.dart` | Azioni «Fatta ✓» / «Non ancora» nel promemoria; logica del geofence (allegato) |
| `lib/models.dart` | `LogType.segnale` e 5 valori di `Sign` (unica modifica al modello dei dati) |
| `lib/ui/potty_v3.dart`, `lib/ui/potty_screen.dart` | Schede «in prova» nella schermata pipì/cacca, spegnibili con `kPrevisioneV3InVista` |
| `test/previsione_v3_test.dart`, `test/quick_actions_test.dart`, `test/outing_geofence_test.dart` | 44 test nuovi |
| `ricerca/analisi/banco_v3.dart`, `v3_cacca_test.dart` | Banco della cacca (origine onesta, candidati, finestre) |
| `ricerca/analisi/banco_piano.dart`, `v3_piano_test.dart` | Banco **a ciclo chiuso**: la strategia decide quando il cane esce, il cane fa la pipì fuori o in casa |
| `ricerca/analisi/risultati/cacca_regola_congelata.md` | Regola della cacca scritta prima della verifica, esito e correzione dichiarata |
| `ricerca/analisi/risultati/v3cacca_*.txt`, `v3piano_*.txt` | Risultati |

Esecuzione: `CACCA_SC=realistico CACCA_EVERY=1 CACCA_FULL=1 flutter test ricerca/analisi/v3_cacca_test.dart` (circa 10 minuti per banco); `PIANO_ARMS=fisso4,piano4,v2 PIANO_SEED=0 PIANO_EVERY=1 flutter test ricerca/analisi/v3_piano_test.dart` (2 s per cane e strategia, 30-60 s con la v2). Le prove sono partite su un campione (un evento o un cane su tre), il banco completo solo sulle regole finali.

---

## 2. Cacca legata ai pasti [MISURATO]

### 2.1 Il modello

La cacca non segue un timer: segue il riflesso gastrocolico (30-60 minuti dopo il pasto, 05 §P8) e le uscite (la passeggiata la fa arrivare nei primi minuti). Il modello guarda le **occasioni** delle prossime 30 ore:
- gli orari abituali dei **pasti** (o il pasto già segnato oggi) e delle **uscite**;
- per ogni orario abituale, **quante volte il cane l'ha fatta dopo**, quando il colon era «pronto» (almeno 0,65 × il suo intervallo tipico dall'ultima cacca), con il ritardo tipico del cane (senza storia: 40 minuti dal pasto per l'adulto, 25 per il cucciolo [IPOTESI]);
- una componente «spontanea» (stimolo forte senza occasione), imparata come curva di sopravvivenza.

La previsione dell'ancora (M) è il primo orario in cui la probabilità cumulata supera il 50%. Età e numero di pasti entrano così: più pasti = più ancore; il cucciolo ha valori tipici più alti e ritardi più brevi.

### 2.2 Metodo onesto

Origine 1 minuto dopo la cacca precedente; solo log fino all'origine (T1 controllato a ogni previsione e nel test «origine onesta»). Esplorazione solo su `realistico`, un evento su tre. **Regola scritta e messa in un commit prima della verifica** (`cb6e44e`, `risultati/cacca_regola_congelata.md`): mediana di M, «stesso orario» (H), «stesso giorno» (W) e timer (T). Criterio fissato allora: R/timer ≤ 0,85 con IC < 1 sul realistico (tutti gli eventi) e su almeno un banco nuovo.

### 2.3 Risultati

| | Realistico (seme 0) | Banco nuovo (seme 1) | Banco nuovo (seme 2) | **Quarto banco (seme 3, mai eseguito prima di v3.1)** | Orari del padrone, seme 3 |
|---|---|---|---|---|---|
| **Prima: cacca nell'app oggi** («orario abituale») | 2,97 [2,61–3,41] | 2,57 | 2,71 | — | — |
| Prima: modello statistico (`ricerca/12`) | 1,14 | | | | |
| Timer (errore mediano) | 106 min | 111 | 104 | 106 | 176 |
| «Stesso orario» H | 1,10 | 0,98 | 1,01 | 1,00 | 0,91 |
| M (ancore) da sola | 1,00 | 0,86 | 1,00 | 0,90 | **0,67** |
| Regola congelata (M, H, W, T) | **0,97 [0,91–1,03] ✘** | 0,90 [0,82–1,01] ✘ | 0,91 [0,82–1,00] ✘ | 0,90 [0,83–1,01] | 0,72 |
| **v3.1 (M, H, T)**, dichiarata dopo la verifica | 0,92 [0,86–0,98] | 0,86 [0,80–0,95] | 0,88 [0,82–0,95] | **0,86 [0,77–0,98]** | **0,68 [0,58–0,79]** |
| v3.1 copertura 80% / 50% | 77% / 46% | 78% / 50% | 77% / 49% | 77% / 47% | 77% / 49% |
| v3.1 errore con segno | +21 | +25 | +11 | +29 | +13 |

Scenari (regola congelata, tutti gli eventi): pulito 0,55, orari del padrone 0,77, fine settimana 0,75.

Lettura:
- **La regola congelata non supera il suo criterio**: 0,97 sul realistico. Il campione di esplorazione (0,80) era ottimista: con la cacca, un evento su tre è troppo poco per scegliere.
- **v3.1** toglie «stesso giorno» (il candidato peggiore su tutti i banchi). È stata scelta guardando i banchi di verifica, quindi l'ho provata su un **quarto banco mai eseguito**: **0,86 [0,77–0,98]**. Batte il timer con IC sotto 1, ma manca la soglia 0,85 di un centesimo. **Criterio primario: non superato, per poco.**
- Dove il padrone decide le uscite (il caso dell'appartamento) il modello con i pasti è nettamente meglio del timer: **0,67-0,68**. È anche il caso in cui il piano di uscite (§3) deciderà gli orari.
- Rispetto a ciò che l'app mostra oggi per la cacca (R 2,6-3,0, cioè «di solito verso le…»), l'errore tipico passa da circa 5 ore a circa 1 ora e tre quarti.
- **Tenuto: v3.1**, nella scheda «Cacca legata ai pasti (in prova)». Nessuna promessa di accuratezza (`ricerca/12` §4.9 vincolo 3).

---

## 3. Segnali e piano di uscite: il banco a ciclo chiuso [MISURATO]

### 3.1 Perché un banco nuovo

Con il cane in appartamento la domanda non è «quando farà la pipì», ma «**quante uscite servono, e quando, per non avere incidenti**». Le uscite cambiano la storia del cane: per misurarlo serve un simulatore in cui la strategia decide e il cane risponde. `banco_piano.dart` usa la stessa fisiologia di `banco.dart` (vescica, acqua, pasti, colon, fine settimana, cambio di routine, poliuria nei 3 cani della scheda, pipì non registrate 10-40%) e aggiunge, come **[IPOTESI]** dichiarate prima di eseguire:

| Ipotesi | Valore |
|---|---|
| Padroni | un terzo fuori casa 8:30-17:45 nei feriali, un terzo 8:30-13:30, un terzo a casa; a casa nel fine settimana; dormono quando dorme il cane |
| Incidente | vescica a 2,5 × il volume normale (2,8 × nel sonno); cacca in casa 10 ore dopo che il colon è pronto |
| Segnali del cane | oltre l'80% dello stimolo: annusa, gira, irrequieto (0,05/min); oltre lo stimolo: porta, guaisce (0,15/min); prima della cacca: gira, annusa (0,08/min); segnali «falsi» 0,4 al giorno |
| Padrone | a casa e sveglio nota un segnale esplicito 8 volte su 10, uno lieve 5 su 10; **un segnale esplicito notato porta sempre fuori il cane, con o senza app**; con la funzione segnali segna 7 segnali notati su 10 e segue «Esci adesso» anche per quelli lievi |
| Uscite | 12 minuti; almeno 60 minuti tra due uscite decise dalla strategia |

Strategie confrontate (stessi cani, stessi pasti e stessa acqua per tutte):
- **Orari fissi standard** con 3, 4 o 5 uscite: risveglio, prima di dormire, rientro dal lavoro, pranzo, metà mattina, pomeriggio (quelli in cui il padrone è a casa);
- **v2**: uscire all'avviso della previsione v2 (`alertAt`), ricalcolato dopo ogni pipì;
- **Piano v3** con 3, 4 o 5 uscite (§3.2), rifatto ogni mattina e dopo ogni uscita non prevista o incidente;
- ciascuna **con o senza segnali** («+s»).
Si contano gli **incidenti veri** (pipì e cacca in casa, anche non registrati) e **tutte le uscite** (comprese quelle chieste dal cane), dal giorno 8 al 28. I parametri del piano (`PlanParams`) sono stati scritti prima di qualsiasi esecuzione e non sono stati cambiati dopo.

### 3.2 Il piano

- **Carico della vescica** tra due uscite = minuti da sveglio + 0,4 × minuti di sonno + 40 minuti per ogni pasto [IPOTESI, 05 §P2].
- **Tenuta del cane** C (in minuti di carico), log-normale con σ = 0,3. Si impara dallo storico degli ultimi 21 giorni (emivita 7 giorni): un incidente dice «C ≈ carico», un'uscita senza incidente dice «C > carico», un segnale dice «C ≈ 2 × carico» [IPOTESI]. Valore di partenza: 2 × il tetto diurno per età e salute (`BioParams`) [IPOTESI].
- **Rischio di un intervallo** = P(C < carico). Incidenti attesi del giorno = somma sugli intervalli, compresa la notte fino alla prima uscita di domani.
- **Orari**: programmazione dinamica sugli orari possibili (ogni 15 minuti, padrone a casa e sveglio, almeno un'ora tra due uscite) che rende minima la somma; un intervallo da sveglio oltre il tetto per età e salute è penalizzato e segnalato («un intervallo supera il limite per la sua età»).
- Nell'app: tre opzioni (3, 4, 5 uscite) con gli orari e il rischio a parole («rischio basso: meno di un incidente al mese»). Il padrone sceglie; il piano si rifà con i dati nuovi.

### 3.3 Risultati

**Banco nuovo (seme 2), mai eseguito prima della correzione v3.1** — tutti i 32 cani, giorni 8-28 (672 giorni-cane). `risultati/v3piano_s2_*.txt`.

| Strategia | Incidenti / settimana / cane [IC] | Uscite al giorno [IC] | Incidenti pipì / cacca | Rischio dichiarato dal piano (pipì) / pipì in casa vere, a settimana |
|---|---|---|---|---|
| Orari fissi, 3 | 2,05 [1,27–3,01] | 5,4 [4,9–6,0] | 114 / 83 | — |
| Orari fissi, 4 | 1,83 [1,09–2,79] | 5,9 [5,4–6,5] | 110 / 66 | — |
| Orari fissi, 5 | 1,81 [1,07–2,81] | 6,3 [5,8–7,0] | 110 / 64 | — |
| v2 (uscire a ogni avviso) | 1,40 [0,70–2,31] | 11,3 [10,3–12,3] | 99 / 35 | — |
| Piano, 3 | 2,13 [1,38–3,22] | 4,6 [4,2–5,2] | 101 / 103 | 1,43 / 1,05 |
| **Piano, 4** | **1,54 [0,88–2,43]** | **5,3 [4,9–5,8]** | 86 / 62 | 0,84 / 0,90 |
| Piano, 5 | 1,60 [0,98–2,46] | 6,0 [5,6–6,4] | 88 / 66 | 0,81 / 0,92 |
| Orari fissi, 4 + segnali | 1,45 [0,78–2,36] | 6,8 [6,4–7,5] | 106 / 33 | — |
| v2 + segnali | 1,22 [0,53–2,10] | 11,8 [10,9–12,8] | 91 / 26 | — |
| **Piano, 3 + segnali** | **1,48 [0,73–2,46]** | **5,4 [5,0–5,9]** | 97 / 45 | 1,18 / 1,01 |
| Piano, 4 + segnali | 1,46 [0,76–2,39] | 6,0 [5,7–6,5] | 90 / 50 | 0,95 / 0,94 |
| Piano, 5 + segnali | 1,42 [0,75–2,30] | 6,8 [6,4–7,2] | 87 / 49 | 0,88 / 0,91 |

Le uscite comprendono quelle chieste dal cane (segnale esplicito notato): per questo anche «3 orari fissi» fanno 5,4 uscite al giorno.

**Per gruppo** (seme 2, incidenti a settimana / uscite al giorno):

| | Cuccioli (6) | Adulti (14) | Anziani (6) | Padrone fuori 8:30-17:45 | Fuori 8:30-13:30 | A casa |
|---|---|---|---|---|---|---|
| Orari fissi, 4 | 4,2 / 8,3 | 0,88 / 4,8 | 0,83 / 5,5 | 3,8 / 5,4 | 1,1 / 6,1 | 0,47 / 6,2 |
| Piano, 4 | 3,7 / 7,3 | 0,74 / 4,3 | 0,72 / 4,9 | 2,9 / 5,1 | 1,0 / 5,3 | 0,67 / 5,5 |
| Orari fissi, 4 + segnali | 3,4 / 9,2 | 0,52 / 5,8 | 0,61 / 6,5 | 3,3 / 6,4 | 0,79 / 7,0 | 0,17 / 7,2 |
| Piano, 3 + segnali | 3,8 / 7,4 | 0,45 / 4,5 | 0,67 / 5,0 | 3,0 / 5,1 | 0,85 / 5,3 | 0,53 / 5,8 |
| Piano, 4 + segnali | 3,6 / 7,8 | 0,69 / 5,2 | 0,50 / 5,8 | 3,1 / 5,7 | 0,85 / 6,1 | 0,37 / 6,3 |

**Semi 0 e 1 (regola v3.0, prima della correzione)** e seme 0 con v3.1, incidenti / uscite:

| Strategia | Seme 0, v3.0 | Seme 1, v3.0 | Seme 0, v3.1 |
|---|---|---|---|
| Orari fissi, 4 | 1,55 / 5,9 | 1,91 / 6,0 | (uguale) |
| Orari fissi, 5 | 1,51 / 6,4 | 1,68 / 6,4 | (uguale) |
| v2 | 1,34 / 10,9 | 1,28 / 11,1 | (uguale) |
| Piano, 3 | 2,02 / 4,6 | 2,20 / 4,6 | 1,99 / 4,6 |
| Piano, 4 | 1,60 / 5,2 | 1,50 / 5,2 | 1,59 / 5,2 |
| Piano, 5 | 1,44 / 5,9 | 1,49 / 6,0 | 1,36 / 6,0 |
| Orari fissi, 4 + segnali | 1,28 / 6,9 | 1,48 / 6,9 | (uguale) |
| Piano, 3 + segnali | 1,33 / 5,4 | 1,67 / 5,4 | 1,36 / 5,4 |
| Piano, 4 + segnali | 1,36 / 6,0 | 1,36 / 6,0 | 1,24 / 6,0 |
| Piano, 5 + segnali | 1,26 / 6,7 | 1,30 / 6,8 | **1,10 / 6,7** |
| v2 + segnali | 1,09 / 12,0 | 1,07 / 11,7 | (uguale) |

Lettura:
- **Piano contro orari fissi, a parità di uscite scelte.** Con 4 uscite il piano fa meno incidenti in tutti e tre i semi tranne il seme 0 (1,60 contro 1,55), sempre con 0,6-0,8 uscite al giorno in meno. Con 5 uscite: 1,36-1,60 contro 1,51-1,81. Gli IC per cane sono larghi e si sovrappongono: **sul numero di incidenti la differenza non è dimostrata; sul numero di uscite sì**. Il criterio scritto prima del seme 2 (stessi incidenti con almeno 0,5 uscite in meno) è soddisfatto (1,54 con 5,3 uscite contro 1,83 con 5,9).
- **Il piano a 3 uscite non conviene senza segnali** (2,0-2,2): troppe cacche in casa nelle lunghe assenze. Il termine per la cacca della v3.1 non basta a correggerlo [MISURATO: 103 cacche in casa contro 83 degli orari fissi]. Il piano lo deve dire: per il cane solo 9 ore, con 3 uscite il rischio è «alto».
- **Segnali.** Sono la leva più forte: da −5% a −34% di incidenti secondo la strategia e il seme (orari fissi −17/−23%, v2 −13/−19%, piano a 3 −24/−34%, piano a 4 −5/−22%), al prezzo di circa una uscita in più al giorno (le uscite «Esci adesso»). Con i segnali il piano a 3 uscite raggiunge gli orari fissi a 4 + segnali con 1,4-1,5 uscite in meno al giorno nei semi 0 e 2 (nel seme 1: 1,67 contro 1,48). Dopo un segnale segnato arriva un bisogno entro 30 minuti nel 79-86% dei casi; il dato è ottimista, perché il padrone porta fuori il cane proprio per il segnale.
- **v2** fa il minimo di incidenti ma con 11-12 uscite al giorno: gli avvisi arrivano spesso, anche perché le pipì non registrate (10-40%) fanno sembrare il cane «in ritardo».
- **Rischio dichiarato onesto per la pipì** (v3.1): 0,81-0,95 previsti contro 0,90-0,94 veri con 4-5 uscite; con 3 uscite sovrastima (1,43 contro 1,05: verso prudente). La cacca in casa non è nel rischio dichiarato.
- **Dove conta**: cuccioli e padroni fuori casa tutto il giorno. Per gli adulti tutte le strategie stanno sotto un incidente a settimana (0,45-0,88 nel seme 2).

### 3.4 Correzioni dichiarate

`risultati/piano_regola.md`: la v3.0 (parametri scritti prima di eseguire) usava i segnali per stimare la tenuta: il rischio dichiarato con i segnali era 3,5-4,2 incidenti a settimana contro 0,9 veri. **v3.1** (decisa dopo i semi 0 e 1): i segnali non entrano nella tenuta e un intervallo che copre tutta la finestra della cacca attesa costa 0,5. Verificata sul seme 2, mai eseguito prima (tabella sopra).

---

## 4. Registrare senza fatica

Dettagli in `ricerca/28-allegato-registrazione.md`.

| | Android | iPhone come PWA | Web su computer | iPhone app nativa |
|---|---|---|---|---|
| Registrazione con un tocco nell'app (pipì, cacca, segnali) | sì | sì | sì | sì |
| Notifiche programmate | sì | no (servirebbe un server di push) | no | sì |
| «Fatta ✓» / «Non ancora» nella notifica | **sì, fatto** | no | no | sì, il tocco apre l'app; da provare (manca una riga in `AppDelegate.swift`) |
| Widget nella schermata Home | progetto (`home_widget`, 2-3 giorni) | no | no | possibile con WidgetKit, non progettato |
| Uscita rilevata intorno a casa (geofence) | solo logica e test, nessuna posizione letta | no | no | solo logica |

- «Fatta ✓» registra una pipì fuori all'ora del tocco; «Non ancora» ripropone il promemoria tra 15 minuti. Ad app chiusa il tocco viene salvato e applicato alla riapertura, senza doppioni.
- Geofence: solo con consenso, solo in locale, mai registrazione automatica senza conferma, nessuna coordinata nello storico. `docs/PRIVACY.md` («niente GPS») resta vero finché la posizione non viene letta davvero: va aggiornato quel giorno.

---

## 5. Prova con cani veri: stato dei materiali

| Materiale | File | Stato |
|---|---|---|
| Invito (lungo, breve, per educatori e veterinari) | `ricerca/beta/invito.md` | bozza pronta |
| Modulo di adesione | `ricerca/beta/adesione.html` | pagina statica senza rete né backend: prepara il testo, un'email precompilata o un file; nota per lo staff su dove raccogliere (casella in UE, foglio ad accesso limitato, cancellazione dei non inclusi entro 30 giorni). Provata in Chrome |
| Consenso informato dello studio, separato | `ricerca/beta/consenso-studio.md` (`studio-v3-2026-11`) | bozza, allineata all'esportazione; 12 «cose da aggiornare» in registro, DPIA e informativa |
| Istruzioni per i partecipanti | `ricerca/beta/istruzioni-partecipanti.md` | bozza con FAQ e tabella Android / iPhone / computer |
| Esportazione anonima dall'app | `lib/logic/study_export.dart`, bottone nella schermata pipì | **fatta**: solo con il consenso «Studio sull'accuratezza»; pid casuale; solo giorni relativi, minuti arrotondati a 5, sì/no; il file lo condivide il partecipante. Nessun invio automatico |

Prima di partire (`ricerca/beta/README.md`): titolare e contatti, indirizzo di raccolta, revisione legale/DPO, revisione del veterinario per le parti cliniche, **emendamento datato del protocollo** (`ricerca/12` §4 e `27` §6 non prevedono ancora piano, segnali e uscite al giorno), commit firmato.

Incoerenze trovate nei documenti esistenti (da decidere, non le ho toccate):
1. **«Zero incidenti» è una frase vietata** (`08` §11.3; il veterinario aveva già tolto «mai incidenti», `06` §30). Nell'app e nei materiali è scritto come **domanda dello studio**, mai come promessa.
2. Età minima: privacy e `consent.dart` dicono 14 anni, la beta ne chiede 18.
3. Il file mandato per email lega il pid a un indirizzo email (`CONSENSO-TELEMETRIA.md` dice «non inviamo mai la tua email»): il consenso lo spiega (§7) e consiglia una casella dedicata.
4. «Segnale sì/no» esce nell'esportazione, mentre `27` §6.4 diceva che gli inneschi non escono: va nell'emendamento.
5. Cani con giardino libero: `27` §6.1 li esclude dall'analisi primaria, `12` §4.4 li include.
6. `web/manifest.json` ha ancora il nome «zampa»: è il nome che vede sotto l'icona chi installa la PWA su iPhone (sessione `claude/debug-completo`).

---

## 6. Cosa ho tenuto e cosa no

| Cosa | Tenuto? | Perché |
|---|---|---|
| Segnali a un tocco con «Esci adesso» (20 minuti), probabilità imparata sul cane | **Sì** | Da −5% a −34% di incidenti sul banco (in media circa −20%), circa una uscita in più al giorno |
| Segnali dentro la stima della tenuta | **No** (v3.0 → v3.1) | Rischio dichiarato 4 volte quello vero |
| Cacca: regola congelata (M, H, W, T) | **No** | 0,97 sul realistico: criterio non superato |
| Cacca v3.1 (M, H, T) | **Sì, «in prova»** | 0,86 [0,77–0,98] sul banco nuovo, 0,68 con uscite decise dal padrone; soglia 0,85 mancata di un centesimo: nessuna promessa |
| Piano di uscite con 3/4/5 opzioni e rischio a parole | **Sì, «in prova»** | Stessi incidenti degli orari fissi o meno, con 0,6-0,8 uscite in meno; rischio dichiarato onesto per la pipì |
| Termine per la cacca nel piano | Sì, ma **non basta** | Con 3 uscite le cacche in casa restano più alte che con gli orari fissi |
| Seguire ogni avviso della v2 come piano | **No** | 11-12 uscite al giorno |
| «Fatta ✓» / «Non ancora» nella notifica | **Sì** (Android; iPhone nativo da provare) | Un tocco senza aprire l'app |
| Geofence | **Solo logica e test** | Serve il permesso di posizione e un aggiornamento di `PRIVACY.md` e DPIA |
| Widget Android | **Solo progetto** | 2-3 giorni con `home_widget` |
| Esportazione anonima | **Sì** | Solo con consenso; condivisa dal partecipante |

**Decisioni per il CEO.**
1. Il piano di uscite e i segnali vanno nella beta come funzione principale per chi è in appartamento [STIMA: è il valore che il banco mostra meglio]. Sostituire i promemoria di oggi con quelli del piano (in `store.dart`, `planNotifications`) va fatto insieme alla sessione `claude/debug-completo`, che sta toccando Home e store: non l'ho fatto.
2. La cacca resta «in prova», senza alcuna frase di accuratezza.
3. Prima della beta: emendamento datato del protocollo (`ricerca/12` §4, `27` §6) con le ipotesi descrittive nuove, proposte qui **prima dei dati**:
   - **D4:** incidenti in casa per cane-settimana nelle settimane con il piano ≤ settimane senza piano (confronto entro cane, prime 2 settimane senza piano, poi con il piano), nei cani in appartamento senza giardino;
   - **D5:** uscite al giorno con il piano ≤ uscite al giorno prima del piano, a incidenti non aumentati;
   - **D6:** dopo un segnale segnato, quota di pipì o cacca entro 30 minuti (calibrazione di «Esci adesso»);
   - **D7:** cacca, R/timer della v3.1 (descrittivo, nessuna soglia di lancio).

---

## 7. Limiti

- È una simulazione. Il banco a ciclo chiuso aggiunge ipotesi forti (tenuta, segnali, comportamento del padrone) che **nessun dato vero ha ancora controllato**: i numeri del §3 dicono quale strategia è migliore *se* i cani si comportano così, non quanti incidenti avrà un cane vero.
- Il modello del piano e il simulatore usano le stesse fonti fisiologiche (05 §P2): un errore comune non verrebbe fuori (`ricerca/12` §8).
- Cuccioli con il padrone fuori 9 ore: nessuna strategia evita gli incidenti, perché nessuno può uscire. Il piano lo dice («supera il limite per la sua età»); la soluzione è un aiuto esterno, non un orario.
- I gruppi «cronico» e «poliuria» hanno 3 cani: solo descrittivi.
- Sulla cacca ho provato più varianti sullo stesso banco; per questo conta il quarto banco (0,86), non i primi.
- Nessuna soglia clinica, nessun tetto, nessun testo clinico rivisto dai veterinari è cambiato. Il piano **usa** il tetto per età e salute come limite.
