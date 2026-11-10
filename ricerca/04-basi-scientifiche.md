# Zampa — Basi scientifiche per i moduli Minzione, Nutrizione, Prevenzione

Data: 10/11/2026. Consulenza scientifico-veterinaria per il team di progetto.

> **Avvertenza di prodotto.** Zampa non fa diagnosi. Tutti i valori sotto servono a (a) stimare abitudini e (b) far emergere il messaggio "parlane col veterinario". Le soglie d'allarme sono scelte per essere **sensibili** (meglio un avviso in più che uno in meno), mai per rassicurare.

## Legenda dei livelli di evidenza

| Sigla | Significato |
|---|---|
| **[E]** Evidenza forte | Dato misurato in studi pubblicati o valore fisiologico di riferimento nei testi standard |
| **[C]** Consenso clinico | Linea guida di società scientifica (WSAVA, AAHA, ESCCAP, ISCAID, FEDIAF, NRC) o pratica clinica condivisa |
| **[R]** Regola empirica | Indicazione diffusa (addestratori, divulgazione, veterinari comportamentalisti) senza base sperimentale diretta; usarla solo come prior iniziale |

Le citazioni bibliografiche verificate su PubMed riportano il DOI. Le linee guida non indicizzate riportano l'URL.

---

## 1. MINZIONE

### 1.1 Valori fisiologici

| Parametro | Valore | Livello | Fonte |
|---|---|---|---|
| Produzione urinaria normale | 1–2 ml/kg/h = **20–45 ml/kg/giorno** | [E] | Valore standard di medicina interna e terapia intensiva (Ettinger & Feldman, *Textbook of Veterinary Internal Medicine*, cap. "Polyuria and polydipsia"; Nelson & Couto, *Small Animal Internal Medicine*) |
| Oliguria | < 0,5 ml/kg/h (< 12 ml/kg/giorno) in animale idratato | [E]/[C] | Criteri IRIS per danno renale acuto (AKI grading): http://www.iris-kidney.com |
| **Poliuria** | **> 50 ml/kg/giorno** di urina | [C] | Ettinger & Feldman; Nelson & Couto |
| Assunzione di acqua normale | **40–60 ml/kg/giorno** (circa 1 ml per kcal ingerita); con dieta umida l'acqua bevuta scende molto | [E] | NRC 2006, *Nutrient Requirements of Dogs and Cats*, https://doi.org/10.17226/10668 |
| **Polidipsia** | **> 100 ml/kg/giorno** di acqua bevuta | [C] | Ettinger & Feldman; Nelson & Couto. Zona grigia 80–100 ml/kg/giorno |
| Volume residuo post-minzionale normale | < 0,2–0,4 ml/kg | [E] | Atalan G. et al., misurazione ecografica del volume vescicale nel cane, *Res Vet Sci* 1998–1999 |
| Frequenza normale adulto | **3–5 minzioni "vere" al giorno** (escluse le marcature) | [C]/[R] | Testi di medicina comportamentale (Landsberg, Hunthausen, Ackerman, *Behavior Problems of the Dog and Cat*, 3ª ed., 2013). Dati di campo scarsi |
| Marcatura (maschi interi, anche femmine) | Durante una passeggiata un maschio può fare da 10 a oltre 30 emissioni piccole | [E] | Sprague R.H., Anisko J.J., "Elimination patterns in the laboratory beagle", *Behaviour* 1973;47:257–267. Studi di McGuire B. et al. su cani di rifugio (*Appl Anim Behav Sci*, 2017–2019): la frequenza di marcatura dipende da sesso, taglia ed età |

**Nota per l'algoritmo.** La frequenza "normale" del cane è poco studiata in modo quantitativo. Per questo l'app deve imparare la **baseline individuale** e allarmare sullo **scostamento dalla baseline**, non da un valore di popolazione.

### 1.2 Quanto riesce a trattenere

| Fascia | Valore usato da Zampa | Livello | Commento |
|---|---|---|---|
| Neonato < 3 settimane | Non ha controllo: minzione riflessa stimolata dalla madre | [E] | Fisiologia dello sviluppo neonatale |
| Cucciolo | **ore ≈ età in mesi + 1** come tetto **a riposo** (es. di notte nel trasportino), non da sveglio; da sveglio va portato fuori molto più spesso (revisione 06/07). Tetto massimo 8 h | [R] | Regola di addestramento diffusa (ASPCA, AKC, testi di educazione del cucciolo). **Nessuno studio la convalida.** Ha però senso fisiologico: capacità vescicale e controllo dello sfintere crescono con l'età, e la maturazione del controllo volontario si completa intorno a 4–6 mesi. Di notte, dormendo, il cucciolo trattiene un po' di più (circa +1–2 h oltre la regola) |
| Adulto | **Raccomandato: uscita almeno ogni 6 h di giorno; massimo 8 h** | [C] | L'Agenzia svedese per l'agricoltura (Jordbruksverket, SJVFS 2020:8, consiglio generale) raccomanda di far uscire i cani almeno ogni 6 ore di giorno, più spesso per cuccioli e anziani: https://lagen.nu/sjvfs/2020:8. Non è un limite fisiologico misurato |
| Adulto, notte | 8–10 h di sonno senza uscire sono comuni e tollerate | [C]/[R] | Pratica clinica |
| Anziano | **Uscita ogni 4–6 h; massimo 6 h** | [C] | Con l'età calano capacità di concentrare le urine e tono sfinterico. Sono più frequenti malattia renale cronica, endocrinopatie e incontinenza. Fonte: 2023 AAHA Senior Care Guidelines, Dhaliwal R. et al., *JAAHA* 59(1):1–21, https://doi.org/10.5326/JAAHA-MS-7343 |

Trattenere a lungo e spesso è associato, in modo plausibile ma poco provato nel cane, a maggiore rischio di infezioni urinarie e di urolitiasi (stasi urinaria). È un consenso clinico, non un dato sperimentale.

### 1.3 Fattori che anticipano il bisogno

Quasi tutti questi ritardi sono **[R]/[C]**, presi dalla letteratura sull'educazione del cucciolo e dalla pratica comportamentale (Landsberg et al., 2013; AVSAB; AAHA Canine Life Stage Guidelines 2019, Creevy K.E. et al., *JAAHA* 55(6):267–290, https://doi.org/10.5326/JAAHA-MS-6999). Il riflesso gastrocolico (defecazione dopo il pasto) è fisiologia consolidata **[E]**. Il legame tra pasto e **minzione** è più debole e passa soprattutto per l'acqua bevuta col pasto.

| Evento | Cucciolo (< 6 mesi) | Adulto | Anziano | Livello |
|---|---|---|---|---|
| Risveglio da sonno ≥ 1 h o notturno | **0–10 min** (quasi immediato) | 0–30 min | 0–20 min | [R]/[C] |
| Risveglio da pisolino < 1 h | 0–15 min | effetto debole | 0–30 min | [R] |
| Dopo il pasto | **10–30 min** (anche defecazione) | 20–60 min (più per la defecazione) | 15–45 min | [E] gastrocolico / [R] minuti |
| Dopo aver bevuto molto (> 10 ml/kg) | **10–30 min** | 30–90 min | 20–60 min | [R] (fisiologia: picco di diuresi 30–90 min dopo un carico idrico) |
| Gioco o attività intensa | **durante o entro 0–15 min** | 0–30 min | 0–20 min | [R] |
| Eccitazione (arrivo persone, saluto) | immediato (anche minzione da eccitazione o sottomissione involontaria) | raro | possibile | [C] (comportamentale) |
| Inizio passeggiata | primi 5–10 min | primi 5–10 min, poi marcature ripetute | primi 5 min | [R] |

**Variazione circadiana.** Di notte la produzione di urina e la frequenza calano **[C]**. Nel cane il ritmo circadiano dell'ADH è meno documentato che nell'uomo. **Nicturia** nuova in un adulto (si sveglia per urinare, perde urina di notte) è un segnale clinico (PU/PD, incontinenza).

**Differenze individuali.**
- **Taglia [E]/[C].** I cani piccoli hanno metabolismo specifico più alto, assumono più acqua per kg e hanno vescica assoluta piccola, quindi tendono a urinare più spesso in volumi piccoli. I cani piccoli marcano anche più frequentemente (McGuire & Bemis 2017, *Appl Anim Behav Sci* 186:49–55).
- **Sesso e marcatura [E].** I maschi interi marcano molto. La castrazione riduce la marcatura in circa il 50–60% dei casi (Hopkins S.G., Schubert T.A., Hart B.L., *JAVMA* 1976;168:1108–1110). Le marcature vanno **escluse** dalla stima degli intervalli di svuotamento.
- **Sterilizzazione delle femmine [E].** Rischio di incontinenza da incompetenza dello sfintere uretrale: circa 5–20% delle cagne sterilizzate, più alto nelle razze > 20 kg. La revisione sistematica di Beauvais, Cardwell & Brodbelt (*J Small Anim Pract* 2012;53:198–204, https://doi.org/10.1111/j.1748-5827.2011.01176.x) trova l'associazione ma evidenza debole sull'età di sterilizzazione.

### 1.4 Segnali d'allarme

Fonti cliniche: ISCAID 2019 sulle infezioni urinarie, Weese J.S. et al., *Vet J* 247:8–25, https://doi.org/10.1016/j.tvjl.2019.02.008. Per PU/PD: Ettinger & Feldman. Le soglie numeriche sono **proposte di prodotto [R]** coerenti col consenso clinico.

| Segnale | Soglia proposta | Urgenza nell'app | Possibili cause (solo per il testo informativo) |
|---|---|---|---|
| **Nessuna minzione** | Adulto: nessuna pipì registrata da **> 12 h** (sveglio) → avviso. **> 24 h → URGENZA**. Cucciolo: **> 8 h** da sveglio → urgenza | 🔴 Urgenza / pronto soccorso | Ostruzione uretrale (calcoli, soprattutto nei maschi), insufficienza renale acuta, disidratazione grave |
| **Sforzo senza urina** o solo gocce | Qualsiasi episodio, soprattutto nel maschio | 🔴 **Subito**, senza attendere | Ostruzione uretrale: emergenza (rischio di iperkaliemia) |
| Sangue nelle urine (ematuria) | Un episodio → avviso. Con sforzo, abbattimento, vomito → urgenza | 🟠 entro 24–48 h / 🔴 se sistemico | Cistite, calcoli, tumori, coagulopatie, estro (nelle femmine intere è normale perdere sangue vulvare) |
| **Pollachiuria** (tante pipì piccole) | ≥ 3 minzioni con intervallo < 60 min nell'arco di 3 h **oppure** conteggio giornaliero ≥ 2 × baseline **oppure** ≥ +50% per 2 giorni consecutivi | 🟠 entro 24–48 h | Cistite batterica, urolitiasi, cistite sterile, tumore vescicale |
| Aumento di frequenza con volumi grandi | Conteggio ≥ +50% sulla baseline per **≥ 3 giorni** **e** acqua aumentata | 🟠 entro qualche giorno | PU/PD: diabete mellito, Cushing, malattia renale cronica, piometra (femmina intera: urgenza!), farmaci (cortisone, diuretici) |
| Polidipsia | Acqua > **100 ml/kg/giorno** come media di 2–3 giorni. 80–100 = zona grigia: "tienilo d'occhio". Ignorare le giornate molto calde o di attività intensa (o almeno ridurne il peso) | 🟠 | Come sopra |
| Incontinenza (perdite a riposo o nel sonno) | Un episodio segnalato → avviso | 🟡 visita programmata | Incompetenza sfinterica, PU/PD, malattie neurologiche |
| Nicturia nuova | ≥ 2 notti su 7 con minzione notturna in un cane prima "asciutto" | 🟡 | PU/PD, infezione urinaria, disfunzione cognitiva |
| Minzione in casa in un cane educato | ≥ 2 episodi in 7 giorni | 🟡 | Medica (sopra) o comportamentale |
| Femmina intera + PU/PD + abbattimento 4–8 settimane dopo il calore | Combinazione | 🔴 | Piometra |

### 1.5 Algoritmo proposto per prevedere la prossima pipì

#### Modello

Usiamo un modello di **sopravvivenza (hazard)** sul tempo dalla pipì precedente, condizionato su fascia oraria ed eventi recenti.

1. **Pulizia dei dati**
   - Episodi a meno di 15 minuti l'uno dall'altro vengono uniti in un unico episodio (passeggiata con marcature). In alternativa l'utente marca un evento come "marcatura" e quell'evento non azzera il timer.
   - Gli intervalli **che attraversano il sonno notturno** vanno in un modello separato, "notte".
2. **Intervallo di base per fascia oraria.** Si divide la giornata in 6 fasce da 4 h (oppure 8 fasce da 3 h). Per ciascuna fascia *b* si modella il log dell'intervallo come **log-normale**: `log(T) ~ N(μ_b, σ_b²)`.
3. **Aggiornamento bayesiano con media mobile esponenziale.**
   - `μ_b ← (1 − α)·μ_b + α·log(t_osservato)`
   - `σ²_b ← (1 − α)·σ²_b + α·(log t − μ_b)²`
   - α = 0,2 per adulto e anziano (memoria di circa 5 osservazioni per fascia). α = 0,35 per il cucciolo, che cambia in fretta.
   - All'inizio il prior pesa come **n₀ = 5 osservazioni**: `α_eff = max(α, 1/(n_b + n₀))`.
   - Per il **cucciolo** il prior si aggiorna anche in automatico ogni settimana con l'età (vedi tabella dei prior).
4. **Aggiustamenti per eventi (hazard additivo).** Ogni evento *e* (risveglio, pasto, acqua, gioco) avvenuto dopo l'ultima pipì aggiunge una "finestra di probabilità" centrata a `delay_e` con ampiezza `width_e`. In pratica si calcola un tempo previsto per l'evento, `t_e = t_evento + delay_e`, e la previsione finale è il minimo tra il tempo di base e i tempi degli eventi:
   - `t_pred = min( t_base_q50 , min_e (t_evento_e + delay_e) )`, dove gli eventi con peso < 1 vengono mescolati: `t_e' = t_base + w_e·(t_e − t_base)` se `t_e < t_base`.
   - I ritardi `delay_e` si **imparano** anch'essi con EMA (α = 0,2), sui casi in cui la pipì è avvenuta entro 2 × `delay_e` dall'evento.
5. **Previsione con margine di sicurezza.** L'app mostra:
   - **Finestra "probabile"**: dal quantile 25% al 75% della log-normale.
   - **Notifica "è ora di uscire"**: al quantile **20%** (anticipo prudente), oppure al primo `t_e` di un evento.
   - **Limite massimo**: `t_max(età)` dalla tabella. La previsione non può mai superare `t_max`; se lo supera, l'app forza la notifica al tempo `t_max − 15 min`.
6. **Avvisi di salute.** Si calcolano separatamente su conteggi giornalieri. Media e deviazione della baseline usano EMA su 14 giorni. Un avviso scatta con z-score > 2 per 2 giorni consecutivi **oppure** con le soglie assolute del § 1.4.
7. **Cold start.** Senza dati si usano i prior per età. Dopo circa 20 intervalli diurni registrati le stime personali dominano.

#### Prior iniziali (pronti per il codice)

Mediana e quantili dell'intervallo diurno tra minzioni "vere", **cane sveglio**. Valori [R]/[C] derivati dalla regola "mesi + 1" (che va usata come limite, non come mediana) e dal consenso clinico. Sono pensati come prior deboli.

| Età | Mediana diurna | q20 (notifica) | q80 | Max diurno `t_max` | Max notturno | Pipì/giorno attese |
|---|---|---|---|---|---|---|
| 8–10 settimane | 60 min | 35 min | 100 min | 3 h | 4 h | 10–14 |
| 11–13 settimane (≈ 3 mesi) | 90 min | 50 min | 150 min | 4 h | 5 h | 8–12 |
| 4 mesi | 2 h | 75 min | 3 h | 5 h | 6–7 h | 6–9 |
| 5 mesi | 2,5 h | 1,5 h | 3,5 h | 6 h | 7–8 h | 5–8 |
| 6–11 mesi | 3,5 h | 2 h | 5 h | 7 h | 8–9 h | 4–6 |
| Adulto (1 anno → senior) | 5 h | 3 h | 7 h | 8 h | 10 h | 3–5 |
| Anziano (ultimo 25% della vita attesa) | 4 h | 2,5 h | 5,5 h | 6 h | 8 h | 4–6 |

**Inizio della fase senior** (AAHA 2019 e 2023; ultimo 25% della vita attesa): taglia piccola < 10 kg circa 10–11 anni; media 10–25 kg circa 8–9 anni; grande 25–45 kg circa 7–8 anni; gigante > 45 kg circa 6 anni.

Deviazione standard del log-intervallo nel prior: σ = 0,45 (cucciolo), 0,40 (adulto), 0,45 (anziano). Con la log-normale, q20 ≈ mediana·e^(−0,84σ) e q80 ≈ mediana·e^(+0,84σ).

Correttivi di prior (moltiplicativi sulla mediana, [R]):
- taglia < 10 kg: ×0,85
- maschio intero in passeggiata: le marcature non contano
- dieta umida > 50% dell'energia: ×1,0 (meno acqua bevuta ma acqua totale simile)
- clima caldo (> 28 °C): mediana ×0,9, acqua attesa ×1,3–1,5

---

## 2. NUTRIZIONE

### 2.1 Energia

**RER** (fabbisogno energetico a riposo) **[E]**:
- `RER (kcal/giorno) = 70 × PC(kg)^0,75`. Questa è la formula di riferimento: NRC 2006; WSAVA Global Nutrition Guidelines, Freeman L. et al., *J Small Anim Pract* 2011;52:385–396, https://doi.org/10.1111/j.1748-5827.2011.01079.x; AAHA 2021 Nutrition and Weight Management Guidelines, Cline M.G. et al., *JAAHA* 57(4):153–178, https://doi.org/10.5326/JAAHA-MS-7232.
- Formula lineare alternativa, valida solo tra 2 e 45 kg: `30 × PC + 70`. Si sconsiglia di usarla nel codice.

**MER** (fabbisogno di mantenimento) = RER × fattore. I fattori sono **[C]**: stime di partenza con variabilità individuale di ±20–30% **[E]**. Per questo vanno sempre corretti sul peso e sul BCS ogni 2–4 settimane.

| Condizione | Fattore × RER | Fonte |
|---|---|---|
| Adulto sterilizzato, attività normale | **1,6** | AAHA 2021; WSAVA |
| Adulto intero, attività normale | **1,8** | AAHA 2021; WSAVA |
| Adulto inattivo o con tendenza a ingrassare | **1,2–1,4** | AAHA 2021 |
| Dimagrimento | **1,0 × RER calcolato sul peso ideale** (in alcuni protocolli 0,8) | AAHA 2021; WSAVA |
| Aumento di peso | 1,2–1,8 × RER del peso ideale | AAHA 2021 |
| Lavoro leggero | 2,0 | AAHA 2021 |
| Lavoro moderato | 3,0 | AAHA 2021 |
| Lavoro intenso (slitta, caccia prolungata) | 4,0–8,0 | AAHA 2021; NRC 2006 |
| Anziano | 1,1–1,4 (spesso −10/20% rispetto all'adulto) | AAHA 2023 Senior; FEDIAF |
| Cucciolo 0–4 mesi | **3,0** | AAHA 2021; WSAVA |
| Cucciolo da 4 mesi all'età adulta | **2,0** | AAHA 2021; WSAVA |
| Gestazione, primi 42 giorni | 1,6–1,8 (come adulto) | NRC 2006 |
| Gestazione, ultimi 21 giorni | 3,0 | NRC 2006 |
| Allattamento | 4–8 (dipende da numero di cuccioli e settimana) | NRC 2006 |
| Malato critico o ospedalizzato | 1,0 | consenso di terapia intensiva |

**Formule alternative con coefficiente sul peso metabolico** (NRC 2006 / FEDIAF): `MER = k × PC^0,75`. Sono utili per un'opzione "precisa".

| Situazione | k (kcal/kg^0,75/giorno) | Fonte |
|---|---|---|
| Cane da compagnia poco attivo (< 1 h/giorno di attività) | 95 | FEDIAF Nutritional Guidelines 2021 (aggiornate 2024): https://europeanpetfood.org/self-regulation/nutrition/ |
| Attività moderata (1–3 h/giorno) | 110 | FEDIAF |
| Attività alta (3–6 h/giorno) | 125 | FEDIAF |
| Attività alta in condizioni estreme | 150–175 | FEDIAF |
| Adulto giovane attivo da canile | 130 | NRC 2006 |
| Anziano | 80–105 (media circa 90) | NRC 2006; FEDIAF |
| Razze molto attive (terrier, Border) / Alano | 180 / 200 | NRC 2006 |

**Cucciolo, formula NRC 2006 [E]:**
`ME (kcal/giorno) = 130 × PCa^0,75 × 3,2 × [e^(−0,87·p) − 0,1]`, dove PCa è il peso attuale, PCm il peso adulto atteso e `p = PCa / PCm`. Richiede una stima del peso adulto (da razza o da genitori). Si usa dallo svezzamento in poi.

### 2.2 Fabbisogno idrico [E]/[C]

- Circa **1 ml per kcal di MER**, cioè circa **50–60 ml/kg/giorno** (NRC 2006). Va contato tutto: acqua bevuta più acqua del cibo. Il cibo umido contiene circa il 75–80% di acqua, le crocchette circa il 10%.
- Aumentare del 50–100% e oltre con caldo, esercizio, allattamento.
- Per l'app: l'**acqua bevuta** attesa con dieta secca è circa 45–60 ml/kg/giorno. Con dieta umida può scendere a 10–25 ml/kg/giorno.
- Polidipsia > 100 ml/kg/giorno (vedi § 1.4).

### 2.3 Body Condition Score (BCS) 1–9

Scala Laflamme a 9 punti: Laflamme D., *Canine Practice* 1997;22(4):10–15. Validata contro DEXA: Mawby D.I. et al., *JAAHA* 2004;40:109–114, https://doi.org/10.5326/0400109. Inclusa in WSAVA Global Nutrition Toolkit: https://wsava.org/global-guidelines/global-nutrition-guidelines/

| BCS | Descrizione | % grasso corporeo circa | Cosa vede il proprietario |
|---|---|---|---|
| 1 | Emaciato | < 5 | Coste, vertebre e bacino visibili a distanza, nessun grasso, perdita muscolare |
| 2 | Molto magro | 5–10 | Coste, vertebre e bacino visibili, nessun grasso palpabile |
| 3 | Magro | 10–15 | Coste facilmente palpabili e forse visibili, punte delle vertebre visibili, vita e addome retratto evidenti |
| 4 | Sottopeso lieve | 15–20 | Coste palpabili con poco grasso, vita ben visibile dall'alto, addome retratto |
| **5** | **Ideale** | **20–25** | Coste palpabili senza eccesso di grasso, vita visibile dietro le coste, addome retratto di lato |
| 6 | Sovrappeso lieve | 25–30 | Coste palpabili con leggero eccesso di grasso, vita visibile ma poco marcata |
| 7 | Sovrappeso | 30–35 | Coste palpabili con difficoltà, depositi sul dorso e alla base della coda, vita assente o appena visibile |
| 8 | Obeso | 35–40 | Coste non palpabili sotto un grosso strato di grasso, nessuna vita, addome che può sporgere |
| 9 | Obeso grave | > 40–45 | Depositi massivi su torace, colonna, collo e arti, addome disteso |

**Peso ideale [C]:** ogni punto sopra 5 corrisponde a circa il **10% di peso in eccesso** (AAHA 2021; WSAVA).
`peso_ideale = peso_attuale × 100 / (100 + (BCS − 5) × 10)`, valida per BCS 5–9.
Per BCS > 7 l'errore cresce (sottostima l'eccesso): segnalare all'utente che serve la valutazione del veterinario.

**Evidenza sull'importanza [E]:** in una coppia di cucciolate di Labrador con razione ridotta del 25% (BCS circa 4,5 contro 6,8) la vita mediana è stata **1,8 anni più lunga** (Kealy R.D. et al., *JAVMA* 2002;220:1315–1320, https://doi.org/10.2460/javma.2002.220.1315). Nello studio Salt C. et al. (*J Vet Intern Med* 2019;33:89–99, https://doi.org/10.1111/jvim.15367) i cani in sovrappeso vivevano fino a 2,5 anni in meno.

**Ritmo di dimagrimento consigliato [C]:** 1–2% del peso a settimana (AAHA 2021).

**Muscle Condition Score (WSAVA) [C]:** scala separata (normale, perdita lieve, moderata, grave), utile negli anziani.

### 2.4 Alimenti tossici

Gravità per l'app: 🔴 **alta** (chiama subito veterinario o centro antiveleni), 🟠 **moderata**, 🟡 **bassa** o dipende dalla dose.

| Alimento / sostanza | Principio | Dose critica | Gravità | Fonte |
|---|---|---|---|---|
| **Xilitolo** (gomme, dentifrici, dolci "senza zucchero", alcuni burri d'arachidi) | Rilascio di insulina, ipoglicemia, insufficienza epatica | > **0,1 g/kg** ipoglicemia; > **0,5 g/kg** danno epatico | 🔴 | Dunayer E.K., Gwaltney-Brant S.M., *JAVMA* 2006;229:1113–1117, https://doi.org/10.2460/javma.229.7.1113 |
| **Uva, uvetta, sultanina**, tamarindo, cremor tartaro | Acido tartarico (ipotesi principale), insufficienza renale acuta | **Idiosincrasica: nessuna dose sicura** | 🔴 | Eubig P.A. et al., *J Vet Intern Med* 2005;19:663–674, https://doi.org/10.1111/j.1939-1676.2005.tb02744.x; Wegenast C.A. et al., *J Vet Emerg Crit Care* 2022;32:812–816, https://doi.org/10.1111/vec.13234 |
| **Cioccolato / cacao** | Teobromina e caffeina | Teobromina: sintomi lievi **20 mg/kg**, cardiaci **40–50 mg/kg**, convulsioni **≥ 60 mg/kg**. Contenuto indicativo: cacao in polvere circa 20 mg/g, fondente circa 5–16 mg/g, al latte circa 2 mg/g, bianco trascurabile | 🔴 (fondente/cacao) / 🟠 (latte) | Weingart C. et al., *J Small Anim Pract* 2021;62:979–983, https://doi.org/10.1111/jsap.13377; ASPCA APCC |
| Caffè, tè, energy drink, compresse di caffeina | Metilxantine | > 20 mg/kg di caffeina dà sintomi; 140–150 mg/kg può essere letale | 🔴 | ASPCA APCC; Gwaltney-Brant, *Small Animal Toxicology* |
| **Cipolla, aglio, porro, erba cipollina** (anche cotti o in polvere) | Disolfuri, anemia emolitica con corpi di Heinz | Alterazioni del sangue già da circa **5 g/kg** (≈ 0,5% del peso corporeo); quadri clinici con **15–30 g/kg**. L'aglio è circa 3–5 volte più potente. Effetto anche cumulativo | 🟠 (🔴 a dosi alte) | Salgado B.S. et al., *J Venom Anim Toxins* 2011;17:4–11, https://doi.org/10.1590/S1678-91992011000100002 |
| **Noci di macadamia** | Ignoto: debolezza, tremori, ipertermia | circa **2,4 g/kg** | 🟠 (raramente fatale) | Hansen S.R. et al., *Vet Hum Toxicol* 2000;42:18–21 |
| **Alcol** e **impasto crudo lievitato** | Etanolo, acidosi; l'impasto si dilata nello stomaco | Etanolo circa 5,5–6,5 ml/kg (100%) letale | 🔴 | ASPCA APCC |
| Luppolo (birra artigianale) | Ipertermia maligna | piccole quantità, soprattutto nei levrieri | 🔴 | ASPCA APCC |
| Cibi molto grassi (avanzi, frattaglie, pelle) | Pancreatite | variabile | 🟠 | Consenso clinico |
| **Ossa cotte** | Perforazione o ostruzione | — | 🟠 | Consenso clinico |
| Sale in eccesso (pasta di sale, acqua di mare, salgemma) | Ipernatriemia | > 2–4 g/kg di NaCl | 🔴 | ASPCA APCC |
| Cibo ammuffito o compost | Micotossine tremorgene | — | 🔴 | ASPCA APCC |
| Noce moscata | Miristicina | dose da cucina alta | 🟡/🟠 | ASPCA APCC |
| Avocado | Persina (il cane è poco sensibile), il nocciolo dà ostruzione | — | 🟡 | ASPCA APCC |
| Pomodoro acerbo, parti verdi di solanacee | Solanina | quantità elevate | 🟡 | ASPCA APCC |
| Latte e latticini | Intolleranza al lattosio | — | 🟡 | Consenso clinico |
| Noci comuni o pecan ammuffite, ghiande | Micotossine, tannini | — | 🟡/🟠 | ASPCA APCC |
| Farmaci umani (paracetamolo, ibuprofene, naprossene) | Non alimenti ma frequenti | Ibuprofene > 25 mg/kg gastrolesivo; > 175 mg/kg renale | 🔴 | ASPCA APCC |

Fonte generale: ASPCA Animal Poison Control Center, https://www.aspca.org/pet-care/animal-poison-control/people-foods-avoid-feeding-your-pets

Italia: Centro Antiveleni di Milano Niguarda (risponde anche per animali), 02 6610 1029; Centro Antiveleni Pavia. **Da verificare** prima di inserire i numeri nell'app.

### 2.5 Frequenza dei pasti [C]

| Età | Pasti al giorno | Fonte |
|---|---|---|
| Svezzamento – 3/4 mesi | 4 (taglie toy: 4–5, per rischio di ipoglicemia) | AAHA 2019 Life Stage; WSAVA |
| 4–6 mesi | 3 | AAHA 2019; WSAVA |
| 6–12 mesi (giganti fino a 18–24) | 2–3 | AAHA 2019 |
| Adulto | 1–2. **2 è il default consigliato** per le razze a rischio di torsione gastrica (taglie grandi, torace profondo); evitare l'esercizio intenso 1 h prima e 2 h dopo il pasto | AAHA; consenso clinico |
| Anziano | 2 (o più, piccoli, se ci sono patologie) | AAHA 2023 Senior |

Il Dog Aging Project ha trovato un'associazione tra pasto unico giornaliero e migliori punteggi cognitivi e di salute (Bray E.E. et al., *GeroScience* 2022;44:1779–1790, https://doi.org/10.1007/s11357-022-00575-7). È uno studio trasversale, quindi **non causale**: non usarlo come raccomandazione.

---

## 3. PREVENZIONE IN ITALIA

### 3.1 Vaccinazioni

Riferimenti principali:
- **WSAVA 2024**: Squires R.A., Crawford C., Marcondes M., Whitley N., *J Small Anim Pract* 2024;65(5):277–316, https://doi.org/10.1111/jsap.13718
- **AAHA 2022**: Ellis J. et al., *JAAHA* 2022;58(5):213–230, https://doi.org/10.5326/JAAHA-MS-Canine-Vaccination-Guidelines

**Classificazione [C]**

| Vaccino | Categoria (WSAVA 2024) | Note per l'Italia |
|---|---|---|
| Cimurro (CDV) | **Core** | — |
| Adenovirus (CAV-2, protegge anche dall'epatite CAV-1) | **Core** | — |
| Parvovirus (CPV-2) | **Core** | — |
| Leptospirosi (L4 in Europa) | Non-core secondo WSAVA, ma **raccomandata in pratica a quasi tutti i cani in Italia** (malattia diffusa, zoonosi) | In Italia è di fatto routinaria |
| Rabbia | Core dove la malattia è endemica; in Italia è **obbligatoria per l'espatrio** (Reg. UE 576/2013) e talvolta per eventi, concorsi o ordinanze regionali | L'Italia è indenne da rabbia urbana. Il focolaio silvestre nel Nord-Est (2008–2011) ha portato all'obbligo temporaneo in Friuli VG, Veneto e Trentino-Alto Adige. **Verificare con l'ASL** gli obblighi locali vigenti |
| Tosse dei canili (*Bordetella bronchiseptica* + parainfluenza CPiV) | Non-core | Per pensioni, toelettature, mostre, addestramento di gruppo. Versione intranasale o orale, annuale |
| Leishmania (LetiFend; CaniLeish non più in commercio in UE dal 2023) | Non-core | Zone endemiche, da 6 mesi d'età, richiamo annuale. **Non sostituisce i repellenti** |
| Herpesvirus canino | Non-core | Solo per fattrici in allevamenti con problemi |

**Calendario cucciolo (WSAVA 2024) [C]**

| Età | Core (CDV, CAV, CPV ± CPiV) | Leptospirosi | Altro |
|---|---|---|---|
| 6–8 settimane | Dose 1 | — | — |
| 10–12 settimane | Dose 2 | Dose 1 (da ≥ 8 settimane secondo il prodotto) | Tosse dei canili se a rischio |
| 14–16 settimane | Dose 3. **L'ultima dose deve cadere a ≥ 16 settimane**; se l'ultima cade prima, aggiungerne una | Dose 2 (2–4 settimane dopo la prima) | Rabbia da ≥ 12 settimane se serve (valida 21 giorni dopo la prima dose per l'espatrio) |
| **26 settimane (6 mesi)** | Richiamo, opzione WSAVA 2024 preferita per coprire chi non ha risposto per interferenza degli anticorpi materni. In alternativa, a **12 mesi** (prassi tradizionale) | — | — |
| 12–16 mesi | (Se non già fatto a 26 settimane) | Richiamo annuale | Rabbia: richiamo secondo la scheda tecnica del prodotto (1–3 anni) |
| Poi | **Ogni 3 anni** (non più spesso; si può fare titolazione anticorpale al posto del richiamo) | **Ogni anno** (la protezione dura circa 12 mesi) | Tosse dei canili: annuale. Rabbia: secondo prodotto |

Le dosi del cucciolo vanno fatte **ogni 2–4 settimane**. Se tra due dosi della serie iniziale di leptospirosi passano più di circa 6 settimane, la serie va ricominciata (prassi sulle schede tecniche; [C]). Cane adulto mai vaccinato o con storia ignota: per i core, 1 dose è considerata protettiva da WSAVA (molti veterinari ne fanno 2 a distanza di 2–4 settimane); per la leptospirosi servono 2 dosi a 2–4 settimane.

### 3.2 Antiparassitari (ESCCAP)

Fonti: ESCCAP GL1 (vermi), GL3 (ectoparassiti), GL5 (malattie trasmesse da vettori), https://www.esccap.org/guidelines/ e le versioni italiane su https://www.esccap.it. Per la leishmaniosi: LeishVet, Solano-Gallego L. et al., *Parasit Vectors* 2011;4:86, https://doi.org/10.1186/1756-3305-4-86.

| Parassita | Raccomandazione per l'Italia | Livello |
|---|---|---|
| **Filariosi cardiopolmonare** (*Dirofilaria immitis*) | Endemica, soprattutto in Pianura Padana e al Nord, in espansione al Centro-Sud. **Chemioprofilassi mensile** (lattoni macrociclici) da **1 mese dopo l'inizio** a **1 mese dopo la fine** della stagione delle zanzare: in pratica **aprile/maggio → novembre/dicembre** (al Sud o con clima caldo valutare tutto l'anno). In alternativa iniezione a lento rilascio (moxidectina, 6 o 12 mesi). **Test antigenico annuale** prima della stagione nei cani > 6–7 mesi. Nei cuccioli si inizia entro la prima stagione (da 6–8 settimane secondo il prodotto) | [C] ESCCAP GL5 |
| Filariosi sottocutanea (*D. repens*) | Stessa profilassi; è zoonosi | [C] |
| **Leishmaniosi** (*L. infantum*, flebotomi) | Endemica al Centro-Sud, sulle isole e nelle zone costiere, focolai stabili anche al Nord. **Repellenti** (collari a deltametrina o flumetrina+imidacloprid, spot-on a permetrina) durante tutta la stagione dei flebotomi, **circa aprile/maggio → ottobre/novembre**, anche tutto l'anno al Sud. Stare in casa al tramonto e di notte. *Revisione 07: proporre i repellenti a tutti i cani, anche al Nord, da aprile a novembre.* Test sierologico annuale nelle zone endemiche, prima della stagione. Vaccino opzionale | [E] efficacia dei repellenti (riduzione dell'infezione del 50–90% in studi di campo) / [C] |
| Zecche | Trattamento acaricida per tutta la stagione: in gran parte dell'Italia **marzo → novembre**, **tutto l'anno al Centro-Sud** e per i cani che frequentano boschi. Durata secondo il prodotto: isoxazoline orali 1–3 mesi, collari 6–8 mesi | [C] ESCCAP GL3 |
| Pulci | Prevenzione continuativa per cani a rischio, almeno stagionale. Trattare anche l'ambiente se c'è infestazione | [C] ESCCAP GL3 |
| **Vermi intestinali** (ascaridi, anchilostomi, tricocefali, tenie) | **Cucciolo**: ogni **2 settimane** da 2 settimane d'età fino a 2 settimane dopo lo svezzamento, poi **mensile fino a 6 mesi**. **Femmina** gravida/allattante: trattare insieme ai cuccioli. **Adulto**, rischio non noto: **almeno 4 volte l'anno** (1–2 trattamenti l'anno non hanno effetto dimostrato sulla popolazione). Rischio alto (bambini piccoli in casa, cane che mangia prede o carne cruda, molto libero): **mensile**, oppure esame coprologico mensile o trimestrale come alternativa | [C] ESCCAP GL1 |
| *Echinococcus granulosus* | Al Sud e sulle isole, cani che hanno accesso a frattaglie o pascoli ovini: praziquantel ogni 6 settimane | [C] ESCCAP GL1 |
| Giardia | Solo trattamento dei casi clinici | [C] |
| Angiostrongylus vasorum | Zone endemiche (Nord-Est e altre): prevenzione mensile con lattoni macrociclici | [C] |

### 3.3 Microchip e anagrafe (obbligo di legge)

- **Obbligo di identificazione e iscrizione all'anagrafe canina per tutti i cani** **[obbligo di legge]**. Riferimenti: Legge 281/1991; Accordo Stato-Regioni 6/2/2003; O.M. 6/8/2008 e successive.
- **SINAC**, Sistema Informativo Nazionale Animali da Compagnia: istituito dal D.Lgs. 134/2022, con modalità attuative in un D.M. Salute del 2023 (*data esatta da verificare in Gazzetta Ufficiale prima di citarla nell'app*). Sta sostituendo progressivamente le anagrafi regionali.
- **Tempi.** Identificazione e iscrizione **entro 60 giorni dalla nascita** (a cura del detentore della madre), comunque prima di cedere il cane. Se il cane viene acquisito in altro modo: entro 10–15 giorni dal possesso, secondo la Regione.
- **Variazioni** (cessione, cambio di residenza, morte, smarrimento): da comunicare in pochi giorni (smarrimento spesso entro 3–5 giorni, altre variazioni entro 10–15), secondo la Regione.
- **Sanzioni** amministrative regionali, per esempio in FVG da 150 a 900 €.
- **Per l'app:** chiedere numero di microchip (15 cifre, ISO 11784/11785) e Regione. Promemoria "iscritto all'anagrafe entro 60 giorni". Promemoria "aggiorna l'anagrafe" quando cambia indirizzo o proprietario.
- Fonti: Ministero della Salute, https://www.salute.gov.it (sezione "Animali da compagnia – Anagrafe"); Regione Toscana, https://www.regione.toscana.it/it/-/anagrafe-animali-d-affezione; Regione Lazio, https://regione.lazio.it/enti/salute/sanit-veterinaria-sicurezz-alimentare/animali-daffezione. **Verificare le scadenze regionali prima del rilascio.**
- **Passaporto europeo per animali da compagnia** (Reg. UE 576/2013): microchip + vaccino antirabbico valido + 21 giorni di attesa dopo la prima vaccinazione.

### 3.4 Visite di controllo [C]

AAHA 2019 Canine Life Stage Guidelines (https://doi.org/10.5326/JAAHA-MS-6999) e AAHA 2023 Senior Care (https://doi.org/10.5326/JAAHA-MS-7343).

| Fase | Visite | Esami |
|---|---|---|
| Cucciolo | A ogni vaccino (ogni 2–4 settimane fino a 16 settimane), poi a 6 mesi | Coprologico ×2–4 |
| Adulto | **Almeno 1 volta l'anno** | Coprologico 1–4 volte l'anno; test filaria e leishmania annuali nelle zone endemiche; esami del sangue di base a 1–2 anni, poi ogni 1–2 anni |
| Anziano | **Ogni 6 mesi** | Emocromo, biochimico, esame urine con peso specifico (± UPCR), pressione arteriosa, T4 se indicato, almeno una volta l'anno (in genere ogni 6 mesi). Valutare dolore, cognitività, muscolo (MCS) |
| Tutti | Igiene dentale a ogni visita | — |

---

> **Nota (revisione veterinaria 06/07):** la tabella degli allarmi di questo capitolo è stata implementata e in alcuni punti resa più prudente nel codice (`lib/logic/alerts.dart`), che fa fede.

## 4. Dati pronti per il codice (Dart)

```dart
// ===== MINZIONE =====
// Valori: [R]/[C]. Unità: minuti, salvo indicazione diversa.
enum LifeStage { puppy8to10w, puppy11to13w, puppy4m, puppy5m, junior6to11m, adult, senior }

class PeeIntervalPrior {
  final int medianDayMin, q20DayMin, q80DayMin, maxDayMin, maxNightMin;
  final double logSigma;       // dev. std del log-intervallo
  final int expectedPerDayMin, expectedPerDayMax;
  final double emaAlpha;
  const PeeIntervalPrior(this.medianDayMin, this.q20DayMin, this.q80DayMin,
      this.maxDayMin, this.maxNightMin, this.logSigma,
      this.expectedPerDayMin, this.expectedPerDayMax, this.emaAlpha);
}

const peeIntervalPriors = <LifeStage, PeeIntervalPrior>{
  LifeStage.puppy8to10w:  PeeIntervalPrior(60,  35,  100, 180, 240, 0.45, 10, 14, 0.35),
  LifeStage.puppy11to13w: PeeIntervalPrior(90,  50,  150, 240, 300, 0.45, 8, 12, 0.35),
  LifeStage.puppy4m:      PeeIntervalPrior(120, 75,  180, 300, 390, 0.45, 6, 9, 0.35),
  LifeStage.puppy5m:      PeeIntervalPrior(150, 90,  210, 360, 450, 0.45, 5, 8, 0.30),
  LifeStage.junior6to11m: PeeIntervalPrior(210, 120, 300, 420, 510, 0.40, 4, 6, 0.25),
  LifeStage.adult:        PeeIntervalPrior(300, 180, 420, 480, 600, 0.40, 3, 5, 0.20),
  LifeStage.senior:       PeeIntervalPrior(240, 150, 330, 360, 480, 0.45, 4, 6, 0.20),
};
const int priorPseudoCount = 5;          // n0
const int mergeEpisodesWithinMin = 15;   // marcature unite in un episodio
const double smallDogMedianFactor = 0.85; // < 10 kg
const double hotWeatherMedianFactor = 0.90; // > 28 °C

// Regola cucciolo "mesi + 1" (ore) come tetto diurno [R], max 8 h
int puppyMaxHoldMin(double ageMonths) =>
    ((ageMonths + 1) * 60).clamp(60, 480).round();

// Ritardi post-evento: (delay medio, larghezza finestra, peso) in minuti [R]
class EventDelay { final int delayMin, widthMin; final double weight;
  const EventDelay(this.delayMin, this.widthMin, this.weight); }

enum PeeTrigger { wakeLong, wakeNap, meal, bigDrink, play, excitement, walkStart }

const eventDelays = <String, Map<PeeTrigger, EventDelay>>{
  'puppy': {
    PeeTrigger.wakeLong:   EventDelay(5, 10, 1.0),
    PeeTrigger.wakeNap:    EventDelay(5, 15, 0.9),
    PeeTrigger.meal:       EventDelay(20, 20, 0.8),
    PeeTrigger.bigDrink:   EventDelay(20, 20, 0.8),
    PeeTrigger.play:       EventDelay(5, 15, 0.8),
    PeeTrigger.excitement: EventDelay(0, 5, 0.5),
    PeeTrigger.walkStart:  EventDelay(5, 10, 0.9),
  },
  'adult': {
    PeeTrigger.wakeLong:   EventDelay(15, 30, 0.9),
    PeeTrigger.wakeNap:    EventDelay(30, 60, 0.3),
    PeeTrigger.meal:       EventDelay(40, 40, 0.4),
    PeeTrigger.bigDrink:   EventDelay(60, 60, 0.6),
    PeeTrigger.play:       EventDelay(15, 30, 0.5),
    PeeTrigger.excitement: EventDelay(0, 10, 0.1),
    PeeTrigger.walkStart:  EventDelay(5, 10, 0.9),
  },
  'senior': {
    PeeTrigger.wakeLong:   EventDelay(10, 20, 1.0),
    PeeTrigger.wakeNap:    EventDelay(15, 30, 0.6),
    PeeTrigger.meal:       EventDelay(30, 30, 0.5),
    PeeTrigger.bigDrink:   EventDelay(40, 40, 0.7),
    PeeTrigger.play:       EventDelay(10, 20, 0.5),
    PeeTrigger.excitement: EventDelay(0, 10, 0.2),
    PeeTrigger.walkStart:  EventDelay(5, 10, 0.9),
  },
};
const double bigDrinkMlPerKg = 10.0; // soglia per "bevuto molto"

// ===== SOGLIE FISIOLOGICHE / ALLARMI =====
const urineNormalMlPerKgDay = (min: 20.0, max: 45.0);   // [E]
const polyuriaMlPerKgDay = 50.0;                        // [C]
const waterNormalMlPerKgDay = (min: 40.0, max: 60.0);   // [E] (dieta secca)
const polydipsiaGreyMlPerKgDay = 80.0;                  // [R] tieni d'occhio
const polydipsiaMlPerKgDay = 100.0;                     // [C] → veterinario
const oliguriaMlPerKgHour = 0.5;                        // [C]

const noPeeWarnHoursAdult = 12;     // avviso
const noPeeUrgentHoursAdult = 24;   // URGENZA
const noPeeUrgentHoursPuppy = 8;    // URGENZA (da sveglio)
const pollakiuriaMinEpisodes = 3;   // ≥3 pipì...
const pollakiuriaMaxGapMin = 60;    // ...con intervallo <60 min...
const pollakiuriaWindowMin = 180;   // ...in 3 h
const freqIncreaseFactorDay = 2.0;  // ≥2× baseline in un giorno
const freqIncreasePct2Days = 0.5;   // ≥+50% per 2 giorni consecutivi
const freqIncreasePct3DaysPuPd = 0.5; // +50% per 3 giorni con acqua alta
const baselineWindowDays = 14;
const zScoreAlert = 2.0;
const nocturiaNightsPer7 = 2;
const houseSoilingPer7Days = 2;

enum Urgency { immediate, within24to48h, scheduleVisit, monitor }
const alarmUrgency = <String, Urgency>{
  'strainingNoUrine': Urgency.immediate,
  'noPee24h': Urgency.immediate,
  'hematuriaWithSystemicSigns': Urgency.immediate,
  'intactFemalePuPdLethargy': Urgency.immediate, // sospetta piometra
  'hematuria': Urgency.within24to48h,
  'pollakiuria': Urgency.within24to48h,
  'polyuriaPolydipsia': Urgency.within24to48h,
  'incontinence': Urgency.scheduleVisit,
  'newNocturia': Urgency.scheduleVisit,
  'houseSoiling': Urgency.scheduleVisit,
  'waterGreyZone': Urgency.monitor,
};

// ===== NUTRIZIONE =====
double rerKcal(double kg) => 70 * math.pow(kg, 0.75);   // [E]

enum EnergyState { neuteredAdult, intactAdult, inactiveObeseProne, weightLoss,
  weightGain, workLight, workModerate, workHeavy, senior, puppyUnder4m,
  puppy4mToAdult, gestationEarly, gestationLate, lactation }

// (min, max, default) × RER — [C] AAHA 2021 / WSAVA / NRC 2006
const merFactors = <EnergyState, (double, double, double)>{
  EnergyState.neuteredAdult:      (1.4, 1.6, 1.6),
  EnergyState.intactAdult:        (1.6, 1.8, 1.8),
  EnergyState.inactiveObeseProne: (1.2, 1.4, 1.3),
  EnergyState.weightLoss:         (0.8, 1.0, 1.0), // × RER del PESO IDEALE
  EnergyState.weightGain:         (1.2, 1.8, 1.4), // × RER del peso ideale
  EnergyState.workLight:          (1.8, 2.2, 2.0),
  EnergyState.workModerate:       (2.5, 3.5, 3.0),
  EnergyState.workHeavy:          (4.0, 8.0, 5.0),
  EnergyState.senior:             (1.1, 1.4, 1.3),
  EnergyState.puppyUnder4m:       (3.0, 3.0, 3.0),
  EnergyState.puppy4mToAdult:     (2.0, 2.0, 2.0),
  EnergyState.gestationEarly:     (1.6, 1.8, 1.8),
  EnergyState.gestationLate:      (3.0, 3.0, 3.0),
  EnergyState.lactation:          (4.0, 8.0, 5.0),
};

// FEDIAF / NRC: kcal per kg^0.75
const fediafK = {'lowActivity': 95, 'moderateActivity': 110,
  'highActivity': 125, 'extremeActivityMin': 150, 'extremeActivityMax': 175,
  'nrcActiveYoung': 130, 'seniorTypical': 90};

// NRC 2006 cucciolo
double puppyMeNrc(double kgNow, double kgAdult) {
  final p = kgNow / kgAdult;
  return 130 * math.pow(kgNow, 0.75) * 3.2 * (math.exp(-0.87 * p) - 0.1);
}

const waterMlPerKcal = 1.0;                       // [E]
const waterTotalMlPerKgDay = (min: 50.0, max: 60.0);
const waterHotOrActiveFactor = (min: 1.5, max: 2.0);

// BCS 1–9 (Laflamme) → % grasso circa
const bcsBodyFatPct = {1: 4, 2: 7, 3: 12, 4: 17, 5: 22, 6: 27, 7: 32, 8: 37, 9: 45};
double idealWeightKg(double kg, int bcs) =>
    bcs <= 5 ? kg : kg * 100 / (100 + (bcs - 5) * 10);   // [C] 10%/punto
const weightLossPctPerWeek = (min: 1.0, max: 2.0);       // [C] AAHA 2021

// Pasti/giorno [C]
const mealsPerDay = {'weaningTo4m': 4, '4to6m': 3, '6to12m': 2, 'adult': 2, 'senior': 2};

// Tossici: severità 3=alta, 2=moderata, 1=bassa; soglie in mg o g per kg
const toxicFoods = [
  (id: 'xylitol', sev: 3, thresholdGPerKg: 0.1, note: 'ipoglicemia; >0.5 g/kg fegato'),
  (id: 'grapes_raisins', sev: 3, thresholdGPerKg: 0.0, note: 'nessuna dose sicura'),
  (id: 'tamarind_cream_of_tartar', sev: 3, thresholdGPerKg: 0.0, note: 'acido tartarico'),
  (id: 'chocolate_theobromine', sev: 3, thresholdGPerKg: 0.020, note: 'mg teobromina: 20 lieve, 40-50 cardio, 60 convulsioni'),
  (id: 'caffeine', sev: 3, thresholdGPerKg: 0.020, note: '>20 mg/kg sintomi'),
  (id: 'alcohol_raw_dough', sev: 3, thresholdGPerKg: 0.0, note: ''),
  (id: 'hops', sev: 3, thresholdGPerKg: 0.0, note: 'ipertermia maligna'),
  (id: 'salt_excess', sev: 3, thresholdGPerKg: 2.0, note: 'NaCl 2-4 g/kg'),
  (id: 'moldy_food', sev: 3, thresholdGPerKg: 0.0, note: 'micotossine tremorgene'),
  (id: 'onion', sev: 2, thresholdGPerKg: 15.0, note: '15-30 g/kg; cumulativo'),
  (id: 'garlic', sev: 2, thresholdGPerKg: 5.0, note: '3-5× più potente della cipolla'),
  (id: 'macadamia', sev: 2, thresholdGPerKg: 2.4, note: ''),
  (id: 'fatty_scraps', sev: 2, thresholdGPerKg: 0.0, note: 'pancreatite'),
  (id: 'cooked_bones', sev: 2, thresholdGPerKg: 0.0, note: 'perforazione/ostruzione'),
  (id: 'nutmeg', sev: 1, thresholdGPerKg: 0.0, note: ''),
  (id: 'avocado', sev: 1, thresholdGPerKg: 0.0, note: 'nocciolo: ostruzione'),
  (id: 'unripe_tomato', sev: 1, thresholdGPerKg: 0.0, note: ''),
  (id: 'dairy', sev: 1, thresholdGPerKg: 0.0, note: 'lattosio'),
];
// teobromina mg/g circa: cacao 20, fondente 5-16 (default 10), latte 2, bianco 0.01

// ===== PREVENZIONE =====
// Calendario vaccini: settimane di vita [C] WSAVA 2024
const coreVaccinePuppyWeeks = [8, 12, 16];       // range: 6-8, 10-12, ≥16
const coreBoosterWeeks = 26;                      // oppure 52
const coreRevaccinationMonths = 36;               // non più spesso
const leptoFirstDoseMinWeeks = 8;
const leptoDoseGapWeeks = (min: 2, max: 4);
const leptoRevaccinationMonths = 12;
const kennelCoughRevaccinationMonths = 12;
const rabiesMinWeeks = 12;
const rabiesTravelWaitDays = 21;
const leishVaccineMinMonths = 6;
const puppyDoseGapWeeks = (min: 2, max: 4);
const lastPuppyCoreMinWeeks = 16;

// Antiparassitari [C] ESCCAP (mesi 1-12)
const heartwormMonthlyFromMonth = 5, heartwormMonthlyToMonth = 12; // da 1 mese dopo l'inizio a 1 mese dopo la fine della stagione delle zanzare
const heartwormTestAnnualAfterMonths = 7;
const sandflyRepellentFromMonth = 4, sandflyRepellentToMonth = 11;
const ticksFromMonth = 3, ticksToMonth = 11; // tutto l'anno al Centro-Sud
const dewormPuppyEveryWeeksUntilWeaningPlus2 = 2;
const dewormMonthlyUntilMonths = 6;
const dewormAdultMinPerYear = 4;
const dewormHighRiskPerYear = 12;
const echinococcusPraziquantelEveryWeeks = 6;

// Anagrafe [obbligo di legge]
const microchipDeadlineDaysFromBirth = 60;
const microchipDeadlineDaysFromAcquisition = 10; // 10-15 secondo la Regione

// Check-up [C] AAHA
const checkupMonthsAdult = 12;
const checkupMonthsSenior = 6;
// inizio fase senior (anni) per taglia
const seniorStartYears = {'small_<10kg': 10, 'medium_10-25kg': 8.5, 'large_25-45kg': 7.5, 'giant_>45kg': 6};
```

---

## 5. Limiti e punti aperti

1. **Frequenza e ritardi della minzione** sono la parte con meno evidenza. Non ci sono studi su larga scala sui cani di casa. Prior e ritardi sono [R]: per questo il modello deve adattarsi in fretta (α alto nelle prime settimane). Zampa potrebbe essere, in prospettiva, una fonte di dati originali.
2. La regola "**mesi + 1 ore**" non è supportata da studi: va usata **solo come tetto prudente**, mai come obiettivo da allenare.
3. **Soglie PU/PD** (50 e 100 ml/kg/giorno) sono consenso clinico consolidato, ma le misure domestiche sono imprecise (evaporazione, acqua rovesciata). Servono 2–3 giorni di media.
4. **Normativa italiana** (SINAC, obbligo antirabbico regionale, sanzioni): le tempistiche variano per Regione e la normativa si sta aggiornando. **Verificare con ASL o Ministero prima del rilascio.**
5. **Calendari dei parassiti**: dipendono da latitudine, altitudine e clima dell'anno. Conviene un'impostazione per macro-area (Nord, Centro, Sud e isole) con la nota "segui il calendario del tuo veterinario".
6. I testi "parlane col veterinario" vanno fatti rivedere da un veterinario abilitato prima della pubblicazione.
