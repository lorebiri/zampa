# Lulù – dossier di progetto

*10 novembre 2026 · prototipo 0.1 · nome provvisorio*

Lulù è un'app web installabile (PWA) e Android dedicata alla salute del cane. Raccoglie in un solo posto la cartella sanitaria, le scadenze di vaccini e antiparassitari, le terapie, il peso e la nutrizione. Ha in più un **modello probabilistico che impara quando il cane deve fare pipì e cacca** e manda il promemoria prima che sia troppo tardi: è pensato per chi vive in appartamento senza giardino.

Il lavoro è stato svolto da un team di agenti, ciascuno con un rapporto completo e le fonti in `ricerca/`:

| # | Agente | Rapporto |
|---|---|---|
| 01 | Analista di mercato | [Concorrenza](ricerca/01-concorrenza.md) |
| 02 | Product strategist | [Funzionalità e roadmap](ricerca/02-funzionalita-roadmap.md) |
| 03 | Business analyst | [Modello di business: quando si guadagna](ricerca/03-business-model.md) |
| 04 | Consulente scientifico-veterinario | [Basi scientifiche (pipì, nutrizione, prevenzione)](ricerca/04-basi-scientifiche.md) |
| 05 | Ricercatore di fisiologia | [Fattori biologici dell'eliminazione](ricerca/05-fattori-biologici-eliminazione.md) |
| 06 | Medico veterinario (revisore) | [Revisione clinica dell'app](ricerca/06-revisione-veterinaria.md) |
| 07 | Medico veterinario (seconda revisione) | [Verifica e revisione delle novità](ricerca/07-seconda-revisione-veterinaria.md) |

---

## 1. Esiste già un'app del genere?

**In parte.** La previsione della pipì è un'idea già sul mercato: nel 2025-2026 sono uscite 8-10 app che dichiarano di "imparare" dai dati registrati (PupIQ, pupdate, Puppy Routine, Pupty, PottyPal, Puppy Potty Trainer…). Hanno però molti limiti:
- sono piccole, con poche decine di recensioni;
- sono quasi tutte solo in inglese e quasi tutte solo per iPhone;
- servono solo per educare il cucciolo;
- non spiegano il loro algoritmo; un utente stima l'accuratezza di PupIQ al 50-60% dopo settimane.

Le app di salute generaliste registrano la pipì ma non la prevedono: 11pets (2,8★ in Italia), DogLog (solo inglese, 44 €/anno) e Doggy Time (in italiano). In Italia il concorrente più vicino è **Joppys**: diario di urine e feci, ma solo iOS e senza previsione.

**Nessuna app trovata unisce tutte queste cose:**
- cartella sanitaria completa e adatta all'Italia (microchip, filariosi, leishmaniosi);
- previsione di pipì **e** cacca anche per cani adulti e anziani;
- uso dei bisogni come **segnale di salute**, con avvisi quando cambia il ritmo, quando il cane beve troppo o quando c'è sforzo nell'urinare;
- italiano, Android, iOS e web.

Questo è lo spazio di Lulù (nome scelto a novembre 2026 al posto del provvisorio «Zampa», che si scontrava con ZampaVet, la catena Ca' Zampa e l'app Zampa a Zampa). Anche per «Lulù» va fatta una verifica del marchio prima di investire.

## 2. Quando potremmo guadagnarci?

Risposta onesta del rapporto 03, con lancio ipotizzato ad aprile 2027:

| Traguardo | Pessimista | Realistico | Ottimista |
|---|---|---|---|
| Copre le spese vive | mai | mese 16 (agosto 2028 circa) | mese 7 (novembre 2027 circa) |
| Recupera quanto investito | — | mese 30 (fine 2029 circa) | mese 12 (aprile 2028 circa) |
| ≥ 1.000 € netti al mese | mai | non entro 36 mesi | mese 13 (maggio 2028 circa) |
| Utile cumulato a 36 mesi | ~0 € | ~2.500 € | ~100.000 € |

- **Contesto:** solo il 20% delle app in abbonamento incassa 1.000 $ in due anni (RevenueCat 2025). Lo scenario ottimista richiede di espandersi nell'UE: 69,6 milioni di cani contro i 9 dell'Italia.
- **Modello consigliato:**
  - cartella sanitaria ed esportazione sempre gratuite;
  - Premium sul modello predittivo e sugli avvisi di salute, con prova di 14 giorni, a circa 24,99 €/anno o con un'opzione a vita;
  - offerta B2B per le cliniche veterinarie e affiliazioni solo dopo 12-18 mesi.
  - Niente pubblicità e niente vendita di dati.
- **Crescita:** deve essere organica (veterinari, canili, comunità di proprietari). La pubblicità a pagamento costa più di quanto rende.
- **Da chiarire prima di incassare il primo euro.** Da dipendente CNR si applica l'art. 53 del d.lgs. 165/2001 (autorizzazione per attività esterne) e va verificato se il CNR ha diritti sul software. Il regime forfettario non si applica sopra 35.000 € di reddito da lavoro dipendente. Servono l'ufficio del personale e un commercialista.

## 3. Il prodotto costruito

Codice in `lib/`, test in `test/`. Funziona offline: i dati restano sul dispositivo, non serve un account e non ci sono server.

| Sezione | Cosa fa |
|---|---|
| **Oggi** | Prossima pipì e prossima cacca, con orario consigliato, finestra probabile, probabilità nella prossima ora, motivo e affidabilità. Registrazione con un tocco (fatta fuori o in casa, passeggiata, pasto, acqua, risveglio, gioco). Allarmi, terapie in corso, prossime scadenze. |
| **Bisogni** | Curva di probabilità delle prossime 12 ore, quanto e come sta imparando il modello (accuratezza misurata sulle ultime uscite), piano delle uscite della giornata, grafico degli ultimi 14 giorni, diario con i segni clinici (sangue, sforzo, gocce, diarrea, muco, feci nere, vomito). |
| **Salute** | Scadenze con promemoria a 3 giorni e il giorno stesso, piano di prevenzione automatico (WSAVA 2024 ed ESCCAP Italia), cartella (vaccini, antiparassitari, farmaci con promemoria a ogni dose, visite, esami, interventi, sintomi), andamento del peso, cartella in testo da copiare per il veterinario. |
| **Nutrizione** | Fabbisogno calorico (NRC 2006: RER × MER), grammi al giorno e per pasto a partire dalle kcal dell'alimento, Body Condition Score 1-9 con peso ideale e dimagrimento, acqua di riferimento, alimenti tossici. |
| **Profilo** | Più cani, tutti i fattori biologici, routine (sveglia e sonno), prudenza delle uscite, promemoria, backup JSON, cancellazione dei dati (GDPR). |

### 3.1 L'algoritmo di previsione di pipì e cacca

È un **modello di rischio (hazard) a tempo discreto**: per ogni quarto d'ora stima la probabilità che il cane debba eliminare. Su questa probabilità si basano tutte le risposte dell'app.

1. **Tempo dall'ultima volta**, normalizzato sul ritmo tipico del cane: una spline a tratti permette una curva di rischio bassa all'inizio e poi ripida.
2. **Ritmo circadiano e sonno**: di notte la produzione di urina e la motilità del colon calano.
3. **Inneschi**, con latenze tratte dalla fisiologia:
   - **risveglio**;
   - **pasto**, attraverso il riflesso gastrocolico: il colon distale è attivo da 0 a 2 h (Sarna & Lang 1989);
   - **acqua** in ml/kg: l'ADH cala entro 15 minuti dalla bevuta (Thrasher 1981);
   - **gioco**;
   - **inizio passeggiata**: è il trigger più forte per la cacca (Dapoigny & Sarna 1991).
4. **Fattori biologici** che modificano il ritmo:
   - età e fase di vita (inizio della fase senior in base alla taglia, AAHA);
   - taglia;
   - dieta umida, con effetto che dipende dalla taglia (Stevenson 2003);
   - calore, gravidanza avanzata, allattamento;
   - farmaci riconosciuti dal nome: cortisonici (Elkholly 2020), furosemide con picco a 2 h (Koh 2021), torasemide, fenobarbital, lassativi, oppioidi;
   - malattie note: diabete, Cushing, malattia renale, cistite, colite;
   - anestesia recente, che rallenta l'intestino per 24-48 h (Boscan 2014).
5. **Apprendimento bayesiano**:
   - il punto di partenza sono i pseudo-dati di un simulatore fisiologico, calibrato perché riproduca gli intervalli della letteratura (circa 7 giorni equivalenti per la pipì, 4 per la cacca);
   - con il **Bayes empirico** il centro del prior si sposta sul ritmo osservato del cane;
   - i dati reali pesano di più quando sono recenti (emivita di 14 giorni, 5 per il cucciolo);
   - la stima usa la massima verosimiglianza penalizzata, risolta con il metodo di Newton.
6. **Sicurezza**:
   - l'uscita consigliata segue la "prudenza" scelta (quantile 12%, 25% o 40%);
   - diventa più prudente dopo un incidente in casa;
   - non supera l'attesa massima per l'età;
   - di notte, solo per i cuccioli, prevede l'uscita notturna.
7. **Trasparenza**: l'app mostra a ogni previsione il motivo e i fattori considerati. L'accuratezza oggi mostrata è calcolata in campione e quindi ottimista: va sostituita con una misura fuori campione (correzione R6, Ciclo 2).

**Validazione (aggiornata l'11/11/2026, `ricerca/12-protocollo-accuratezza.md`):**
- **I numeri pubblicati in precedenza (pipì 18 contro 26 minuti del timer, cacca 3 contro 363 minuti, ±14 minuti sul cane di esempio) sono ritirati.** Erano artefatti: la previsione partiva pochi minuti prima dell'evento (in mediana 11 minuti prima della cacca) e l'accuratezza mostrata in app è calcolata sugli stessi eventi usati per stimare il modello. Non vanno più citati.
- **Banco di prova realistico** (32 cani simulati, 4 settimane, pipì non registrate, orari decisi dal padrone, fine settimana, cambi di routine, poliuria): sulla pipì il modello **non batte il timer fisso**. Errore mediano 91 minuti contro 84, rapporto 1,08 [IC 95% 1,03–1,13] contro la soglia di lancio ≤ 0,80. La probabilità nella "prossima ora" non è calibrata e, con una poliuria nuova, la previsione arriva in ritardo, cioè nel verso pericoloso.
- **Decisione del CEO** (`ricerca/08-piano-ceo.md`, §11): finché il modello non supera il banco e poi lo studio su cani veri, l'app mostra una previsione di base onesta (ritmo personale del cane e orari abituali, con il tetto di sicurezza per età invariato). Il modello lavora "in ombra" e si corregge (correzioni R1-R8 del rapporto 12). Nessuna affermazione di accuratezza, in app o nel marketing.
- **Limiti onesti:**
  - **Dati sintetici:** anche il banco di prova è una simulazione. L'accuratezza su cani reali si potrà misurare solo con utenti veri, ed è il primo esperimento da fare con i beta tester.
  - **Uscite decise dal padrone:** un cane educato elimina quando viene portato fuori. Gli eventi registrati riflettono quindi anche gli orari del padrone, e il modello lo compensa solo in parte con la covariata "passeggiata".
  - **Latenze stimate:** molte latenze in minuti sono stime dentro finestre fisiologiche misurate (rapporto 05). Nessuno ha mai misurato su larga scala la frequenza di pipì e cacca nei cani di casa. Con il consenso degli utenti, i dati di Lulù potrebbero diventare il primo dataset su questo, e quindi una pubblicazione scientifica.

### 3.2 Allarmi di salute

Gli allarmi non sono diagnosi: servono a far notare un cambiamento e a dire **quando sentire il veterinario** (SUBITO / OGGI / ATTENZIONE / INFO). Elenco completo e aggiornato dopo la revisione veterinaria in `lib/logic/alerts.dart` e nella sezione 4.

| Situazione | Quando scatta |
|---|---|
| Nessuna pipì | Oltre 24 h nell'adulto; oltre 8 h nel cucciolo sveglio |
| Sforzo a urinare | Nel maschio basta un episodio per un allarme SUBITO (possibile ostruzione) |
| Sangue nelle urine o nelle feci, feci nere | Sempre |
| Pollachiuria | Pipì piccole e ravvicinate |
| Frequenza della pipì in aumento | +50% rispetto alla sua baseline |
| Polidipsia | Oltre 100 ml/kg al giorno |
| Diarrea | Diarrea e vomito; nel cucciolo è un'urgenza |
| Stitichezza | Nessuna cacca da oltre 48 h, 24 h nel cucciolo |
| Incidenti in casa nell'adulto | Ripetuti |
| Peso | Calo oltre il 5-10% |
| Cucciolo | Non cresce |
| Scadenze sanitarie | Superate |

### 3.3 Il compagno in pixel art

La schermata Oggi si apre con il cane disegnato in pixel art, in stile "animaletto virtuale". Il disegno è originale: niente nome, marchio o grafica di prodotti esistenti.

- **Personalizzabile perché somigli al proprio cane:**
  - taglia: piccola, media, grande;
  - 10 colori del mantello, principale e secondario;
  - 6 motivi: tinta unita, focature, petto e muso chiari, macchie, pezzato, maschera;
  - orecchie dritte, semi o pendenti;
  - coda lunga, arricciata o corta;
  - pelo lungo;
  - colore del collare.
- **L'umore segue i dati veri:**
  - **dorme** negli orari di sonno;
  - **aspetta la porta** quando si avvicina l'uscita consigliata;
  - **ha fame** all'ora abituale della pappa, se il pasto non è registrato;
  - **scodinzola** dopo un'uscita (anche se lo tocchi);
  - di notte lo schermo diventa blu con la luna.
- **Indicatori a blocchi:** Bisogno, Pappa e Uscite. Sono informativi, non un punteggio.
- **Regole cliniche, chieste dal veterinario:**
  - il cane non si ammala e non muore mai nell'app, e non ci sono sensi di colpa;
  - gli allarmi SUBITO / OGGI compaiono **sopra** il compagno, perché una cosa seria non deve sembrare un gioco;
  - con un allarme urgente il compagno si fa da parte con "Leggi le segnalazioni".
- **Collaudo:** un test disegna tutte le 1.350 combinazioni di aspetto e posa senza errori.

### 3.4 Moduli clinici aggiunti (revisione veterinaria, seconda tornata)

| Area | Cosa c'è |
|---|---|
| Registrazione | 24 tipi di evento in 4 gruppi (Bisogni, Routine, Sintomi, Misure). Scala fecale **Purina 1-7**. Foto allegabili. "Ha ingerito qualcosa" apre direttamente la scheda Emergenze |
| Nuovi allarmi | Respiri nel sonno oltre 30 (oggi) o oltre 40 (subito), soglie ACVIM 2019. Gengive pallide o blu (subito), gialle (oggi). Temperatura ≥ 39,5 °C (oggi), ≥ 41 o < 37 (subito). Convulsione oltre 5 minuti o a grappolo (subito), prima crisi (oggi), crisi più frequenti nel mese. Zoppia senza carico (oggi). Inappetenza per età e diabete. Abbattimento. Pipì notturne nuove. Perdite a riposo ("non ridurre l'acqua"). Perdite vulvari e piometra dallo storico dei calori. Parto oltre 70 giorni. Calore oltre 4 settimane. Dose non confermata. Denti |
| Terapie | Dosi da confermare "Dato" / "Saltato" in Oggi. Promemoria per 72 h. Avviso dopo 2 h senza conferma ("non raddoppiare"). Conferme incluse nel PDF |
| Diabete | Diario dell'insulina (unità prescritte, mai calcolate) e delle glicemie. Regola "non ha mangiato → non fare l'insulina senza sentire il veterinario". Tremori o convulsioni in un diabetico → allarme ipoglicemia con primo soccorso |
| Epilessia | Diario delle crisi con durata e tipo, grafico mensile per il neurologo (IVETF 2015) |
| Cuore e respiro | Timer di 30 secondi per contare i respiri nel sonno |
| Riproduzione | Storico di calori, accoppiamenti, parti e sterilizzazione. Prossimo calore stimato. Parto presunto (+63 giorni) con scheda parto. Finestre di gravidanza isterica e piometra |
| Anziano | Scala della qualità della vita HHHHHMM (Villalobos) con andamento e soglia 35 |
| Esami | Valori con intervallo del laboratorio, andamento nel tempo, fuori range evidenziato, senza interpretazione |
| Stagione e razza | Avvisi per area (Nord / Centro / Sud): processionaria, forasacchi, caldo, veleni per lumache e topi, zecche, botti. Predisposizioni di razza (torsione gastrica, brachicefali, MDR1, Dalmata, schiena lunga, Cavalier). Socializzazione ed educazione del cucciolo |
| Meteo | Avviso caldo all'ora della prossima uscita (Open-Meteo, facoltativo, si invia solo la città), con soglia più bassa per brachicefali, anziani, obesi e cardiopatici |
| Documenti | **PDF per il veterinario**: scheda, segnalazioni, grafici di 14 giorni (pipì, cacca, acqua), peso, terapie con conferme, sintomi, esami, storico |
| Altro | Checklist viaggi UE (microchip, rabbia ≥ 21 giorni, Echinococcus). Spese annue con stima della detrazione IRPEF (19% oltre 129,11 €, fino a 550 €). Allarmi urgenti notificati subito sul telefono |

## 4. Revisione del veterinario

Un agente con il ruolo di medico veterinario (medicina interna e preventiva) ha rivisto codice, testi e rapporti. Il rapporto completo è in [06-revisione-veterinaria.md](ricerca/06-revisione-veterinaria.md).

**Cosa va bene:**
- impostazione prudente, che non fa diagnosi;
- formule nutrizionali corrette (NRC, WSAVA);
- rapporti scientifici 04 e 05 in gran parte corretti;
- modello trasparente.

**Cosa non andava:** il codice era meno prudente dei rapporti. Ha indicato 42 correzioni e 8 aggiunte ad alta priorità. Tutte le correzioni di gravità A (rischio per la salute o medico-legale) e la maggior parte delle B sono state **applicate e coperte da test**:

| Area | Correzione applicata |
|---|---|
| Urgenze | 4 livelli (SUBITO / OGGI / ATTENZIONE / INFO) con frase d'azione fissa e pulsanti "Chiama il veterinario" ed "Emergenze" |
| Vie urinarie | Nel maschio basta **un** episodio di sforzo o gocce per un allarme SUBITO (rischio di blocco urinario). L'avviso "nessuna pipì" non dipende più dagli altri eventi registrati. La pollachiuria è contata sugli eventi grezzi. Sangue durante il calore gestito a parte |
| Vomito | Nuovo evento con conati a vuoto, schiuma, sangue e addome gonfio. Torsione gastrica → SUBITO. Cani piccoli e cuccioli → OGGI. Vomito o feci nere durante una terapia con FANS o cortisone → SUBITO |
| Feci | Feci nere → OGGI. Sangue nel cucciolo → OGGI (parvovirosi). Niente allarme stitichezza dopo un'anestesia |
| Piometra | Nuova regola: femmina intera 2-12 settimane dopo il calore con sete, pipì, vomito o abbattimento → OGGI |
| Peso | Crescita del cucciolo valutata solo su ≥ 14 giorni. Calo di peso più sensibile nell'anziano. Dimagrimento troppo rapido. Avvisi per sottopeso e BCS 6 |
| Modello pipì | Tetti diurni dei cuccioli abbassati: "mesi + 1 ore" vale a riposo, non da sveglio. Il tetto si accorcia con malattie e farmaci (es. diabete). Uscita prima di dormire o notturna **anche per adulti e anziani**. "Meno uscite" solo per adulti sani. Malattie riconosciute a parola intera |
| Prevenzione | Filariosi: niente "inizio" a novembre; stagione per area (Nord/Centro/Sud); test annuale in primavera. Sverminazione ogni 14 o 30 giorni nel cucciolo. Leishmania annuale. Leptospirosi: 1ª → 2ª dose dopo 28 giorni. Richiamo del cucciolo a 26 settimane. Microchip proposto finché manca. Repellente anti-pappataci per tutti. Piano per cuccioli adottati tardi |
| Nutrizione | Pasti automatici per età: 5 nei cuccioli toy, per prevenire l'ipoglicemia. Gravidanza (×1,8 → ×3,0). Allattamento (cibo a disposizione, avviso eclampsia). Crescita più lunga nelle taglie grandi con avvertenze sul calcio. Avvertenze per dimagrimento e sottopeso. **21 sostanze pericolose** (farmaci umani, topicidi, metaldeide, processionaria, piante…) e istruzioni su cosa NON fare |
| Medico-legale | Avvertenza da accettare al primo avvio. Disclaimer con l'elenco delle emergenze. Nessuna dose suggerita. Promemoria delle terapie programmati per 72 h con "non raddoppiare la dose" |
| Emergenze | Nuova scheda sempre raggiungibile: veterinario, pronto soccorso h24, mappa dei pronto soccorso vicini, centro antiveleni, 15 situazioni "vai subito" con i primi gesti |

**Seconda tornata: tutte le 21 aggiunte del rapporto 06 sono state implementate.** Restano due attività che non può fare il software:
- far approvare tutti i testi di allarme ed emergenza da un veterinario abilitato in carne e ossa;
- verificare il numero del centro antiveleni e i riferimenti normativi (D.M. SINAC, D.Lgs. 218/2023, Reg. UE 2026/131).

### 4.1 Seconda revisione veterinaria

Un secondo agente veterinario ha verificato punto per punto il lavoro fatto e ha rivisto tutte le novità. Il rapporto completo è in [07-seconda-revisione-veterinaria.md](ricerca/07-seconda-revisione-veterinaria.md).

**Verifica delle 42 correzioni della prima revisione:**

| Esito | Numero | Note |
|---|---|---|
| Applicate correttamente | 27 | |
| Applicate in parte | 12 | |
| Non applicate | 2 | Rapporto 04 |
| Applicate in modo sbagliato | 1 | Il richiamo della leptospirosi non veniva mai programmato |

Ha poi segnalato 53 nuovi punti e 8 aggiunte. **Le correzioni di gravità A e B sono state applicate tutte, quelle C quasi tutte, e sono coperte da 16 nuovi test.**

| Punto | Correzione applicata |
|---|---|
| Falsi negativi pericolosi | Cucciolo con vomito e diarrea insieme, o con abbattimento → OGGI/SUBITO, non più "info". Glicemie valutate: < 60 mg/dL → SUBITO, 60-79 → OGGI, > 400 → attenzione/oggi. **Eclampsia** nella cagna che allatta con tremori → SUBITO. Cucciolo toy debole o tremante → SUBITO (ipoglicemia). Diabetico con vomito o abbattimento → OGGI/SUBITO, "non fare l'insulina senza sentire il veterinario" |
| Ostruzione urinaria | Una pipì "a gocce" non azzera più il timer né il conteggio dell'anuria |
| Falsi allarmi | Nel cucciolo l'anuria si conta sulle ore da sveglio (prima scattava ogni mattina). I respiri sopra 40 in un cane sano danno "rimisura" (OGGI); diventano SUBITO se il cane è cardiopatico, ha fatica a respirare o gengive blu |
| Farmaci | Riconosciuti i nomi commerciali (Metacam, Rimadyl, Previcox, Vetoryl, Lasix, Vetmedin…). **Trilostano** con vomito, diarrea o abbattimento → SUBITO. FANS + cortisone insieme → avviso. Cardiopatia riconosciuta anche dai farmaci |
| Altre regole | Piometra anche senza calori registrati. Perdite vulvari purulente. Gengive rosso scuro → SUBITO. Ingestione: 5 giorni di sorveglianza (topicidi). Doppia insulina → SUBITO. Collasso e addome gonfio come eventi autonomi. Mastite, malessere dopo il parto, calo termico pre-parto. Urina scura con richiamo alla babesiosi. Loperamide nelle razze MDR1 |
| Modello dei bisogni | Il tetto di attesa vale anche quando è già superato ("portalo fuori adesso"). Modalità post-operatoria. "Non ridurre l'acqua" con la cistite. "Non spostare il diuretico" se la dose è serale. Avviso alla colonna dopo chirurgia spinale |
| Notifiche | Ogni allarme urgente ha la sua notifica. Notifiche a tempo anche ad app chiusa per pipì mancata e dosi non confermate |
| Compagno in pixel art | Mai felice con un allarme aperto. Con un allarme SUBITO lascia il posto a una scheda rossa. Toccarlo non lo rende felice se è preoccupato. Niente "ha fame" dopo vomito o ingestione, in allattamento o prima di un intervento. "Uscite" come numero con l'obiettivo del modello, nascosto nel riposo post-operatorio. Di notte "è la sua ora di riposo" |
| Prevenzione | Richiamo della leptospirosi corretto. Adulti senza vaccini → "verifica il libretto". Avviso permetrina per chi ha gatti. Repellente proposto dalla stagione successiva. Filariosi solo dalle 6 settimane. Note di legge su microchip e anagrafe |
| Emergenze | Il numero del centro antiveleni **non verificato è stato tolto**: l'app non mostra mai un "da verificare". Nuovo testo per il colpo di calore ("raffreddalo subito"). Aggiunte reazione allergica, occhio, ustioni, folgorazione e annegamento |
| Altro | Scala Purina con i testi corretti. Controlli di plausibilità (°F, mmol/L). Foto dalla fotocamera. Timer dei respiri anche da 60 secondi. Taglia adulta prevista. Detrazione calcolata su tutti i cani con l'obbligo di pagamento tracciabile. PDF più completo (bisogni, acqua in ml/kg, respiri, crisi, glicemie, dosi saltate, riproduzione, qualità della vita, unità di misura) |

**Terza tornata: implementate anche tutte le aggiunte di priorità media e bassa del rapporto 07**, coperte da 7 nuovi test (68 in totale):

| Aggiunta | Cosa c'è |
|---|---|
| Modalità post-operatoria | Scheda "Convalescenza: giorno N di 14" con riposo, collare elisabettiano, controllo della ferita, prima pipì e appetito. Diario della ferita: arrossata, gonfia o con secrezione → attenzione; punti aperti o sanguinamento → oggi. Pasto non ancora registrato 48 h dopo l'intervento → oggi. Indicatore "Riposo" al posto di "Uscite" |
| Forasacchi | Maggio-agosto: orecchie scosse all'improvviso o starnuti violenti → oggi |
| Anziano | Massa muscolare (Muscle Condition Score WSAVA). Checklist dei cambiamenti cognitivi sui 6 ambiti DISHAA, **scritta per Lulù e dichiarata non validata**. CBPI, LOAD e CCDR sono protetti da copyright: serve una licenza per inserirli nell'app |
| Consigli | Socializzazione con le precauzioni igieniche. Leptospirosi e acque stagnanti (giugno-novembre). Freddo (dicembre-febbraio) con avviso meteo sotto 0 °C. Età della sterilizzazione nelle grandi taglie, solo "parlane col veterinario" |
| Razze | Toy (trachea, ipoglicemia), Schnauzer nano (pancreatite), Dobermann (cardiomiopatia), Cocker (otiti), Bulldog francese (ernia discale) |
| Diabete | Blocco "Insulina già fatta alle…" contro la doppia somministrazione in famiglia |
| Urine scure | Testo sulla distruzione dei globuli rossi e domanda "Hai trovato zecche di recente?" |
| Emergenze | "Cosa dire al telefono" generato dal profilo: segnalamento, peso, cosa ha ingerito e quando, farmaci, patologie, allergie |
| PDF | Tutte le conferme di somministrazione con data. Crisi e dosi saltate mese per mese |

**Ancora aperto (non risolvibile scrivendo codice):**
- **Testi clinici:** approvazione da parte di un veterinario abilitato in carne e ossa, con la versione registrata.
- **Verifiche esterne:**
  - quale centro antiveleni risponde per gli animali, e con quale numero;
  - D.M. sul SINAC;
  - regolamento UE sui viaggi;
  - fonti segnate "da verificare" nel rapporto 07.
- **Licenze** per i questionari validati (CBPI, LOAD, CCDR), se si vogliono nell'app.
- **Prova su telefoni veri:** notifiche, foto, condivisione del PDF.

## 5. Roadmap (dal rapporto 02)

- **MVP da completare:**
  - famiglia multi-utente sincronizzata (serve un backend in UE);
  - widget in home e notifiche con azioni rapide;
  - export PDF e link a tempo per il veterinario;
  - archivio di documenti e foto;
  - avviso caldo legato all'orario della prossima uscita: il 74% dei colpi di calore avviene durante lo sforzo;
  - accessibilità.
- **v1.x:**
  - accesso per il dog sitter;
  - QR "cane smarrito";
  - OCR del libretto;
  - viaggi UE, con il nuovo Reg. (UE) 2026/131 in vigore dal 22/04/2026;
  - detrazione delle spese veterinarie nel 730;
  - scala di qualità della vita per il cane anziano;
  - calendario dei parassiti per regione;
  - Live Activity e Apple Watch;
  - inglese.
- **v2:** portale per il veterinario, assistente AI con limiti precisi (dichiarato come IA, AI Act art. 50), altre lingue UE.
- **Futuro:** integrazioni con anagrafe SINAC e ricetta elettronica veterinaria (REV). Oggi non esistono API pubbliche per le app dei proprietari: va chiesto formalmente a VetInfo.

## 6. Come provarla

```bash
cd ~/Library/CloudStorage/OneDrive-CNR/Desktop/zampa
flutter test            # 68 test: modello, regole cliniche, due revisioni veterinarie, avatar, PDF
flutter run -d chrome   # oppure -d macos, o un simulatore iOS / Android
```

Al primo avvio va accettata l'avvertenza d'uso. Poi "Prova con un cane di esempio" crea Luna con due settimane di diario.

Le notifiche programmate funzionano su iOS, Android e macOS. Sul web l'app mostra il conto alla rovescia, ma non manda notifiche quando è chiusa.
