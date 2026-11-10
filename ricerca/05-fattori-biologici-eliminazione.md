# Zampa — Fattori biologici dell'eliminazione (pipì e cacca) e parametri per il modello predittivo

Data: 10/11/2026. Rapporto del ricercatore di fisiologia veterinaria per il team Zampa.
Fa seguito a `04-basi-scientifiche.md` (sezione 1, Minzione). I valori già fissati lì vengono **mantenuti** dove non c'è motivo di cambiarli; dove questo documento li precisa o li corregge lo dice esplicitamente.

> **Avvertenza di prodotto.** La previsione serve per l'organizzazione quotidiana. Le soglie d'allarme servono solo a far emergere "parlane col veterinario". Zampa non fa diagnosi.

## Legenda

| Sigla | Significato |
|---|---|
| **[E]** | Dato misurato in studi pubblicati sul cane, oppure valore fisiologico di riferimento nei testi standard |
| **[E-h]** | Dato misurato nell'uomo, trasferito al cane per analogia fisiologica |
| **[C]** | Consenso clinico o linea guida (NRC, WSAVA, AAHA, ACVIM, IRIS, FEDIAF) |
| **[R]** | Regola empirica diffusa senza base sperimentale diretta |
| **STIMA** | Valore proposto da me, coerente con la fisiologia ma **non misurato**. Va trattato come prior debole e lasciato correggere dai dati del cane |

Le citazioni con DOI sono state verificate su PubMed il 10/11/2026. Quelle trovate tramite Consensus riportano il link della scheda.

---

## 0. Sintesi in 10 righe

1. **Nessuno studio pubblicato prevede *quando* un cane farà pipì o cacca.** Non ho trovato né modelli né brevetti specifici per il cane. Esistono diari minzionali e sensori vescicali nell'uomo, da cui prendere idee. Gran parte dei parametri temporali sarà quindi **STIMA** costruita su fisiologia misurata.
2. **La pipì è un problema di "riempimento".** La vescica si riempie a una velocità di circa 1–1,5 ml/kg/h di giorno e il cane la svuota quasi del tutto (residuo mediano 0,2 ml/kg). Conviene quindi un simulatore **meccanicistico**: produzione di urina, poi volume vescicale, poi probabilità di svuotare.
3. **La cacca è un problema di "trigger".** Lo stimolo nasce dal pasto (risposta colica nelle prime 0–2 h), dall'esercizio (contrazioni giganti seguite da defecazione subito dopo l'inizio della corsa) e dal risveglio. Il tempo di transito (circa 1–2 giorni) conta solo per accorgersi dei cambiamenti di dieta o dei pasti saltati.
4. **La variabile più importante non è biologica: è l'opportunità.** Un cane educato elimina solo quando esce. Gli eventi registrati sono quindi **censurati dall'accesso all'esterno**. Il modello deve separare il bisogno (latente) dall'evento osservato.
5. **La marcatura dei maschi va separata dallo svuotamento.** In 10 minuti di passeggiata un maschio fa in media 6,9 tentativi di minzione, una femmina 1–2 (Atalan 1999). Le marcature non azzerano il timer.
6. **Taglia.** La produzione di urina per kg scala circa con BW^-0,25 (l'acqua segue l'energia, NRC 2006). Il transito colico misurato con marcatori si allunga molto con la taglia: da 22 h nel barboncino nano a 59 h nello schnauzer gigante (Hernot 2005).
7. **Effetti forti e documentati:** cortisonici (PU/PD, il primo effetto collaterale nella pratica clinica), diuretici dell'ansa (picco 1–2 h, diuresi giornaliera fino a ×3,3 con torasemide), diabete, Cushing, malattia renale, dieta ricca di sodio o di acqua.
8. **Effetti deboli o poco studiati:** caldo, estro, gravidanza, stress, età avanzata. Li tratto come moltiplicatori moderati da imparare per singolo cane.
9. Il ritmo circadiano dell'ADH che nell'uomo riduce l'urina notturna **non è stato dimostrato nel cane** (Goetz & Wang 1986). Di notte l'urina cala soprattutto perché il cane non beve e non mangia. Il calo notturno della frequenza è soprattutto un effetto del sonno.
10. La sezione finale "PARAMETRI PER IL CODICE" contiene tutti i valori pronti per l'uso.

---

## 1. PIPÌ

### 1.1 Produzione di urina e bilancio idrico

| Fattore | Valore | Evidenza | Fonte |
|---|---|---|---|
| Diuresi normale | 20–45 ml/kg/die (1–2 ml/kg/h). In beagle sani da circa 10 kg è stata misurata una diuresi basale di **220 ± 53 ml/die, cioè ~22 ml/kg/die** | [E] | Testi di medicina interna (Ettinger & Feldman; Nelson & Couto). Pelligand L. et al. 2020, *Front Vet Sci* 7:151, https://doi.org/10.3389/fvets.2020.00151 |
| Poliuria | > 50 ml/kg/die | [C] | Come sopra |
| Acqua totale introdotta | ≈ 1 ml per kcal di energia metabolizzabile, cioè **40–60 ml/kg/die** nel cane medio. Comprende acqua bevuta, acqua del cibo e acqua metabolica | [C] | NRC 2006, *Nutrient Requirements of Dogs and Cats*, https://doi.org/10.17226/10668 |
| Polidipsia | > 100 ml/kg/die (80–100 zona grigia) | [C] | Ettinger & Feldman |
| **Taglia** | Il fabbisogno energetico di mantenimento è ≈ 130·BW^0,75 kcal/die (cane domestico attivo), quindi **acqua per kg ∝ BW^-0,25**. Esempi: 5 kg ≈ 87 ml/kg; 10 kg ≈ 73; 30 kg ≈ 56; 50 kg ≈ 49 ml/kg/die. Il cane piccolo produce più urina per kg | [C] → derivato | NRC 2006 (equazione MER). La derivazione su urina è **STIMA** che assume la stessa quota renale di perdite |
| Residuo post-minzionale | Mediana **0,2 ml/kg** (0,1–3,4) nei cani normali | [E] | Atalan G., Barr F.J., Holt P.E. 1999, *Res Vet Sci* 67:295–299, https://doi.org/10.1053/rvsc.1999.0336 |
| Volume vescicale "funzionale" a uno svuotamento | **6–10 ml/kg** nell'adulto. Si ricava dividendo la diuresi (20–40 ml/kg/die) per 3–5 svuotamenti veri. Capacità massima fisiologica 20–30 ml/kg | **STIMA** | Derivato. Non ho trovato una cistometria del cane sveglio con capacità in ml/kg ripetibile |

**Ritmo dopo il pasto e circadiano.** In cani coscienti nutriti e abbeverati una volta al giorno alle 8:30, il flusso urinario e la natriuresi **raggiungono il picco 4–8 h dopo il pasto** e scendono a valori bassi durante la notte (Corea M. et al. 1996, *Kidney Blood Press Res* 19:16–23, https://doi.org/10.1159/000174041) **[E]**. Il disegno dello studio però confonde ritmo circadiano e pasto/acqua.

Nel cane la risposta renale a un carico di volume **non si attenua di notte**, a differenza di quanto avviene nei primati (Goetz K.L., Wang B.C. 1986, *Am J Physiol* 250:R638–R643, https://doi.org/10.1152/ajpregu.1986.250.4.R638) **[E]**.

→ **Implicazione per il modello.** Il "rapporto notte/giorno" della produzione di urina va legato soprattutto all'assenza di acqua e cibo notturni, non a un ADH notturno. Propongo che il simulatore usi un fattore circadiano intrinseco modesto (0,7 di notte, **STIMA**) e lasci che il resto del calo emerga da "non beve".

### 1.2 Risposta a un bolo d'acqua (latenza e picco)

- **Fisiologia [E].** Nel cane disidratato che beve, la vasopressina (ADH) scende già **6 minuti prima** che cali l'osmolalità plasmatica, per un riflesso orofaringeo. Torna ai livelli di cane idratato **entro 15 minuti** dalla bevuta. Bere dura al massimo 6 minuti (Thrasher T.N. et al. 1981, *Am J Physiol* 240:E394–E401, https://doi.org/10.1152/ajpendo.1981.240.4.E394).
- **Conseguenza [E-h]/STIMA.** Il rene comincia a diluire l'urina entro circa 15–30 minuti. Nel cane idratato l'aumento di diuresi ha:
  - inizio intorno ai 20 minuti;
  - picco a **45–90 minuti**;
  - coda fino a 3 ore.
  Circa il 50–70% del bolo è eliminato entro 3 h. Il dato nel cane libero non è misurato, quindi è STIMA ricavata dal profilo umano del carico idrico e dalla cinetica dell'ADH sopra.
- Se il cane era **disidratato** (dopo esercizio o caldo), buona parte del bolo viene trattenuta e l'effetto sulla minzione si riduce (fattore 0,3–0,5, **STIMA**).
- **Kernel proposto:** gamma con moda 60 minuti e ampiezza a metà altezza (FWHM) 90 minuti. Moltiplicatore della hazard proporzionale ai ml/kg bevuti (vedi Parametri).

### 1.3 Dieta: acqua, sodio, potassio

| Fattore | Effetto | Evidenza | Fonte |
|---|---|---|---|
| Cibo umido (70–80% di acqua) rispetto al secco | Con il secco portato al 73% di acqua è aumentata l'acqua totale introdotta ed è sceso il peso specifico urinario negli **schnauzer nani**. **Nessuna variazione nei labrador**. Il cane piccolo "compensa" meno bevendo di meno | [E] | Stevenson A.E., Hynds W.K., Markwell P.J. 2003, *Res Vet Sci* 74:145–151, https://doi.org/10.1016/S0034-5288(02)00184-4 |
| → moltiplicatore | Volume urinario: **×1,25 sotto i 10 kg, ×1,05 sopra i 25 kg**. Acqua bevuta: ×0,4–0,6 (il cibo porta l'acqua) | **STIMA** | Derivato da Stevenson 2003 |
| Sodio alimentare | Passando dallo 0,3% all'1,3% di sodio (sul tal quale) **aumentano, in modo dipendente dalla dose, l'acqua bevuta e il volume urinario** nei cani | [E] | Queau Y. et al. 2020, *J Anim Physiol Anim Nutr* 104:1524–1530, https://doi.org/10.1111/jpn.13329 |
| → moltiplicatore | Dieta "urinaria" o ad alto sodio: volume ×1,3 (fino a ×1,5) | **STIMA** | Ordine di grandezza coerente con lo studio |
| KCl (potassio) | Più KCl → più acqua bevuta, più urina, peso specifico più basso | [E] | Bijsmans E. et al. 2021, *Animals* 11:1809, https://doi.org/10.3390/ani11061809 |
| Rapporto acqua/kcal | Cani di piccola taglia con dieta secca: peso specifico basale ~1,026. Offrendo acqua "arricchita" sale l'acqua introdotta e il peso specifico scende a 1,014–1,018 | [E] | Zanghi B.M., Gardner C.L. 2018, *Front Vet Sci* 5:317, https://doi.org/10.3389/fvets.2018.00317 |

### 1.4 Esercizio e caldo

- **Caldo.** Con l'aumento della temperatura ambiente da 25 a 45 °C crescono sia la frequenza respiratoria sia l'evaporazione delle vie aeree superiori (ansimazione), cioè le perdite d'acqua non urinarie (Baker M.A. 1984, *Am J Physiol* 246:R369–R374, https://doi.org/10.1152/ajpregu.1984.246.3.R369) **[E]**. In beagle con cibo e acqua liberi, l'assunzione totale d'acqua varia con le stagioni (Rashotte M.E. et al. 1984, *Neurosci Biobehav Rev* 8:205–210, https://doi.org/10.1016/0149-7634(84)90042-3) **[E]**.
  → Il caldo aumenta **l'acqua bevuta** (×1,3–1,5 sopra i 28 °C, come in 04) ma **non proporzionalmente la diuresi**, perché una parte va persa ansimando. **STIMA**:
  - diuresi ×1,0 tra 20 e 28 °C;
  - diuresi ×0,9–1,1 sopra i 28 °C;
  - l'effetto netto sulla pipì passa soprattutto dai **boli d'acqua** registrati.
  - Freddo sotto i 5 °C: diuresi ×1,1 (**STIMA**, diuresi da freddo per analogia con l'uomo).
- **Esercizio.** Durante lo sforzo la diuresi cala, per la minore perfusione renale e l'ADH più alto (fisiologia generale [E-h]). Dopo lo sforzo il cane beve molto: è il bolo successivo a generare la pipì 45–90 minuti dopo. Durante la passeggiata, nei maschi, l'esercizio aumenta la marcatura, non lo svuotamento. Per i cani da lavoro, in ambiente caldo (> 21,7 °C), la temperatura corporea torna a riposo entro 60 minuti dallo sforzo (Zanghi B.M. et al. 2018, *Front Vet Sci* 5:202, https://doi.org/10.3389/fvets.2018.00202) **[E]**. Uso questo dato come finestra di "recupero idrico".
  → **STIMA**: hazard della pipì durante lo sforzo intenso ×0,7. Gioco in casa nel cucciolo: ×2–4 nei 0–30 minuti successivi (regola di educazione **[R]**, già in 04).

### 1.5 Sesso, marcatura, sterilizzazione, estro

| Fattore | Effetto quantitativo | Evidenza | Fonte |
|---|---|---|---|
| Maschio rispetto a femmina in passeggiata | In 10 minuti: maschi **6,9 tentativi** (75% "produttivi"), femmine **1–2** (100% produttivi) | [E] | Atalan 1999 (sopra) |
| Maschio intero, marcatura | Durante le passeggiate decine di emissioni piccole. La castrazione riduce la marcatura nel 50–60% dei casi | [E] | Sprague R.H., Anisko J.J. 1973, *Behaviour* 47:257–267. Hopkins S.G., Schubert T.A., Hart B.L. 1976, *JAVMA* 168:1108–1110 |
| Femmine e marcatura | Femmine sterilizzate e femmine intere non in calore dirigono rispettivamente il **60,8% e il 56,7%** delle minzioni verso oggetti (marcatura anche fuori dal calore). La frequenza **aumenta con l'età**. Lontano dall'area di casa le femmine urinano di più e marcano di più | [E] | Wirant S.C., McGuire B. 2004, *Appl Anim Behav Sci* 85:335–348 — [scheda](https://consensus.app/papers/details/e4e2e73c443f5cd4bb97949d090c53e3/?utm_source=claude_code) |
| **Estro** | La quota di minzioni dirette (marcature) è più alta in **proestro ed estro** che in anestro | [E] (n = 10, preliminare) | Wirant S.C. et al. 2007, *Appl Anim Behav Sci* — [scheda](https://consensus.app/papers/details/a16dc71147a054fb86e3fb167ce3029f/?utm_source=claude_code) |
| → moltiplicatore estro | Eventi di pipì in passeggiata ×1,5–2 (in gran parte marcature). Svuotamenti veri ×1,1 | **STIMA** | |
| Sterilizzazione della femmina e comportamento | Nessuna differenza di frequenza o di postura tra femmine intere e sterilizzate, prima o dopo la pubertà (labrador, 15 minuti di passeggiata) | [E] | Balogh O. et al. 2018, *Reprod Domest Anim* — [scheda](https://consensus.app/papers/details/85833a405a9253e5b42985edad405d24/?utm_source=claude_code) |
| Sterilizzazione della femmina e **incontinenza** | Incompetenza sfinterica nel 5–20% delle cagne sterilizzate, più nelle taglie > 20 kg. Si manifesta come **perdite a riposo**, non come più minzioni volontarie | [E] | Beauvais W., Cardwell J.M., Brodbelt D.C. 2012, *J Small Anim Pract* 53:198–204, https://doi.org/10.1111/j.1748-5827.2011.01176.x |
| Stress, paura e contesto sociale | Nei cani di canile i maschi maturi urinano con frequenza maggiore se portati da una donna sconosciuta che da un uomo. Maschi e femmine defecano meno spesso con un uomo | [E] | McGuire B. et al. 2020, *Animals* 10:632, https://doi.org/10.3390/ani10040632; McGuire B. et al. 2023, *Animals* 13:3649, https://doi.org/10.3390/ani13233649 |

### 1.6 Età e stadio di vita

- **Cucciolo.** La regola "mesi + 1 ore" è **[R]**: non esistono studi che la convalidino. Il controllo volontario matura entro 4–6 mesi **[C]**. Si mantiene la tabella di 04, coerente con un volume funzionale piccolo (stimato 3–5 ml/kg a 8–10 settimane) e con un'acqua per kg alta, perché l'energia per kg del cucciolo è circa il doppio di quella dell'adulto (NRC 2006).
- **Adulto.** 3–5 svuotamenti veri al giorno **[C]/[R]** (04).
- **Anziano.** Con l'età aumenta la frequenza di minzione delle femmine (Wirant & McGuire 2004 **[E]**). Aumentano anche la malattia renale cronica (perdita della capacità di concentrare, poliuria, nicturia) e l'incontinenza **[C]** (AAHA Senior Care 2023, https://doi.org/10.5326/JAAHA-MS-7343). → Intervallo ×0,8 rispetto all'adulto (04 usa una mediana di 4 h contro 5 h, quindi ×0,8: coerente).
- **Gravidanza.** Nell'ultimo terzo (dal giorno 40 circa) cresce il fabbisogno energetico e quindi l'acqua, e l'utero comprime la vescica. → Intervallo ×0,8 (**STIMA**, [C] per la direzione; NRC 2006 per l'energia).
- **Allattamento.** Al picco (settimane 3–4) l'energia sale a 2–4 volte il mantenimento, e l'acqua sale di conseguenza (NRC 2006 **[C]**). Molta acqua però va nel latte. → Acqua ×2–3, intervallo della pipì ×0,8 (**STIMA**).

### 1.7 Farmaci

| Farmaco | Effetto | Tempi | Evidenza | Fonte |
|---|---|---|---|---|
| **Cortisonici per bocca** (prednisolone) | PU/PD sono gli effetti collaterali più frequenti: polidipsia 39,2% e poliuria 28,4% dei segni registrati. Odds di PU/PD **×3,5** con compresse di prednisolone rispetto al desametasone iniettabile, **×10,7** combinando via orale e iniettabile | Inizio 12–24 h. Fine 1–3 giorni dopo la sospensione (**STIMA**) | [E] | Elkholly D.A. et al. 2020, *Front Vet Sci* 7:515, https://doi.org/10.3389/fvets.2020.00515 |
| → moltiplicatore | Diuresi ×1,5 a dosi antinfiammatorie, ×2–3 a dosi immunosoppressive | | **STIMA** | |
| **Furosemide per bocca** (2 mg/kg) | Picco di escrezione di sodio e cloro a **2 h** per bocca, 1 h per via endovenosa. Peso specifico urinario in calo | Inizio 30 minuti, picco 1–2 h, durata circa 6 h | [E] | Koh S.-K. et al. 2021, *BMC Vet Res* 17:295, https://doi.org/10.1186/s12917-021-02998-4 |
| **Torasemide** | Diuresi da 220 a **730 ml/die dopo la prima dose (×3,3)**, fino a 1150 ml/die dopo 10 giorni alla dose alta. Forte variabilità tra cani | Assorbimento in 0,5–1 h, durata ≥ 12 h | [E] | Pelligand 2020 (sopra) |
| → kernel furosemide | Produzione di urina ×4 nel picco 1–2 h, che torna a ×1 entro 6 h | | **STIMA** sul dato di Koh 2021 | |
| **Fenobarbital** (e bromuro di potassio) | PU/PD e polifagia frequenti, soprattutto nelle prime settimane e a dosi alte | Continuo durante la terapia | [C] | Bhatti S.F.M. et al. 2015, IVETF consensus, *BMC Vet Res* 11:176, https://doi.org/10.1186/s12917-015-0464-z |
| → moltiplicatore | Pipì ×1,3. Cacca ×1,2 (si mangia di più) | | **STIMA** | |
| Spironolattone, ACE-inibitori | Effetto diuretico lieve | | [C] | ×1,1 **STIMA** |
| Fenilpropanolamina, estriolo (incontinenza) | Riducono le perdite, non la frequenza delle minzioni volontarie | | [C] | ×1,0 |
| Desmopressina | Antidiuretico | | [C] | ×0,6 **STIMA** |

### 1.8 Malattie note

| Malattia | Effetto | Evidenza | Fonte |
|---|---|---|---|
| Diabete mellito (non controllato) | PU/PD con diuresi spesso 2–4 volte il normale | [C] | Behrend E. et al. 2018, AAHA Diabetes Management Guidelines, *JAAHA* 54:1–21, https://doi.org/10.5326/JAAHA-MS-6822 |
| Ipercortisolismo (Cushing) | PU/PD in circa l'80–85% dei cani. Acqua spesso > 100 ml/kg/die | [C] | Behrend E.N. et al. 2013, ACVIM consensus, *JVIM* 27:1292–1304, https://doi.org/10.1111/jvim.12192 |
| Malattia renale cronica | Perdita della capacità di concentrare, poliuria e nicturia, crescenti con lo stadio IRIS | [C] | IRIS Staging Guidelines, http://www.iris-kidney.com |
| Infezione urinaria o cistite | **Pollachiuria**: molte minzioni piccole, ×2–4 | [C] | ISCAID 2019, Weese J.S. et al., *Vet J* 247:8–25, https://doi.org/10.1016/j.tvjl.2019.02.008 |
| Piometra (femmina intera) | PU/PD 4–8 settimane dopo il calore | [C] | Testi di riproduzione |

**Moltiplicatori di malattia (STIMA, per il prior):** diabete ×2,5; Cushing ×2,0; renale IRIS 2 ×1,4, IRIS 3–4 ×1,8; cistite ×3 (con volumi piccoli). Nell'app queste condizioni devono **aprire la finestra di sorveglianza** (§ 4.4 di 04), non solo cambiare la previsione.

---

## 2. CACCA

### 2.1 Tempi di transito (misurati)

| Misura | Valore | Metodo | Fonte |
|---|---|---|---|
| Svuotamento gastrico (pasto) | Con scintigrafia, T½ **100–181 minuti** | Scintigrafia | Boillat C.S. et al. 2010a, *Am J Vet Res* 71:903–908, https://doi.org/10.2460/ajvr.71.8.903 |
| Svuotamento gastrico della capsula | 6–15 h (405–897 minuti), fino a una mediana di 17,6–20 h a casa. È **più lento del cibo**: la capsula è un oggetto grande e non digeribile | Capsula di motilità senza fili (WMC/SmartPill) | Boillat C.S. et al. 2010b, *Am J Vet Res* 71:898–902, https://doi.org/10.2460/ajvr.71.8.898; Warrit K. et al. 2017, *Vet J* 227:36–41, https://doi.org/10.1016/j.tvjl.2017.08.005 |
| Intestino tenue | **1,6–5,4 h** (mediana 3,1 h); 96–224 minuti | WMC | Warrit 2017b; Boillat 2010b |
| Crasso (colon) | Mediana **21 h** (1–69 h); 427–2573 minuti | WMC | Warrit 2017b; Boillat 2010b |
| Transito totale (WMC) | Mediana **~33–46 h** (1294–3443 minuti; mediana 2735 minuti in Lidbury 2012). Variabilità tra cani ~20–30%, nello stesso cane **~16%** | WMC | Lidbury J.A. et al. 2012, *Vet Med Int* 2012:938417, https://doi.org/10.1155/2012/938417 |
| Transito totale per taglia (marcatori, più vicini al cibo) | **22 h nel barboncino nano → 59 h nello schnauzer gigante**. Correlazione con l'altezza al garrese r = 0,71 | Perline colorate, 50 cani di 13 razze | Hernot D.C. et al. 2005, *J Anim Physiol Anim Nutr* 89:189–193, https://doi.org/10.1111/j.1439-0396.2005.00544.x |
| Transito nel crasso per taglia | **9,1 ± 1,1 h** nel barboncino nano contro **39,4 ± 1,6 h** nello schnauzer gigante. Transito oro-cecale **indipendente dalla taglia** | Marcatori + sulfasalazina | Hernot D.C. et al. 2006, *Am J Vet Res* 67:342–347, https://doi.org/10.2460/ajvr.67.2.342 |
| Età | Il cucciolo svuota lo stomaco più in fretta dell'adulto (T50 più breve). Il transito oro-cecale cala con la crescita solo nelle razze grandi | Marcatori radiopachi, sulfasalazina | Weber M.P. et al. 2002, *Am J Vet Res* 63:677–682, https://doi.org/10.2460/ajvr.2002.63.677; Weber M.P. et al. 2003, *Am J Vet Res* 64:1105–1109, https://doi.org/10.2460/ajvr.2003.64.1105 |
| Beagle, digiuno o pasto | Stomaco: 0,57 h a digiuno, **2,94 h dopo il pasto**. Intestino 1–2 h | SmartPill | Koziolek M. et al. 2019, *Eur J Pharm Biopharm* 136:221–230, https://doi.org/10.1016/j.ejpb.2019.01.026 |
| Taglia: sintesi | I cani > 25 kg hanno cieco e colon più sviluppati, colon più lento, più fermentazione e feci più morbide | Revisione | Weber M.P., Biourge V.C., Nguyen P.G. 2017, *J Anim Physiol Anim Nutr* 101:1–9, https://doi.org/10.1111/jpn.12507 |

**Nota sul conflitto tra studi.** Con la capsula non si vede l'effetto della taglia tra 19,6 e 81 kg (Boillat 2010b). Con i marcatori, che si comportano più come il cibo, l'effetto c'è ed è forte (Hernot 2005/2006). Per il simulatore uso i **marcatori**.

**Stress e ospedalizzazione [E].** Con l'ospedalizzazione lo svuotamento gastrico della capsula passa da 17,6 h a **71,8 h**; gli altri tratti non cambiano (Warrit K. et al. 2017, *JAVMA* 251:65–70, https://doi.org/10.2460/javma.251.1.65). Dopo un'anestesia generale lo svuotamento gastrico passa da 12 a 49 h e si normalizza in 30–40 h (Boscan P. et al. 2014, *Vet Anaesth Analg* 41:73–81, https://doi.org/10.1111/vaa.12093). → **Dopo un ricovero o un'anestesia la cacca può mancare per 1–2 giorni senza allarme.** Lo stress acuto in un ambiente nuovo **ritarda**, non anticipa.

### 2.2 Riflesso gastrocolico (risposta colica al pasto)

- Dopo un pasto di 1300 kcal, nel cane cosciente l'attività contrattile del **colon distale aumenta nelle prime 0–2 h** ("precoce"). Nella fase **tardiva (2–8 h)** aumenta in tutto il colon, perché arriva digesta fresca. Le contrazioni giganti migranti (GMC) sono rare (Sarna S.K., Lang I.M. 1989, *Am J Physiol* 257:G830–G835, https://doi.org/10.1152/ajpgi.1989.257.5.G830) **[E]**.
- In un modello di colite acuta, il pasto porta le GMC da 0,4 a 1,3 all'ora nella fase tardiva, e la frequenza di defecazione aumenta (Sethi A.K., Sarna S.K. 1991, *Gastroenterology* 101:1537–1546, https://doi.org/10.1016/0016-5085(91)90389-3) **[E]**. → In caso di diarrea, il picco dopo il pasto si **sposta e si allarga** verso 2–8 h.
- **Latenza proposta.** Picco a **30 minuti**, ampiezza 60 minuti (supporto 10–120 minuti), più una "gobba" tardiva debole a 2–8 h. I minuti sono **STIMA [C]**, coerente con la finestra 0–2 h misurata.

### 2.3 Esercizio

- **Dato chiave [E].** Cani su treadmill per 1 h a 5 km/h: **a riposo non defecavano mai**, né a digiuno né dopo il pasto. **Poco dopo l'inizio dell'esercizio** comparivano GMC **seguite da defecazione**. Nel 40% delle prove, circa 10 minuti dopo, una seconda GMC causava un movimento di massa senza defecazione (Dapoigny M., Sarna S.K. 1991, *Am J Physiol* 260:G646–G652, https://doi.org/10.1152/ajpgi.1991.260.4.G646).
- → Kernel: picco **5–15 minuti** dall'inizio dell'attività, ampiezza 20 minuti. È il trigger più forte (OR ~6, **STIMA** sull'intensità; direzione [E]).

### 2.4 Risveglio e ora del giorno

- **Nel cane** non ho trovato misure dirette. **Nell'uomo** il risveglio e il pasto aumentano l'attività motoria del colon in tutti i soggetti sani (Rao S.S.C. et al. 2004, *Am J Gastroenterol* 99:2405–2416, https://doi.org/10.1111/j.1572-0241.2004.40453.x). Nella popolazione **la maggior parte delle defecazioni avviene al primo mattino**, e solo il 33–40% delle persone ha un ciclo regolare di 24 h (Heaton K.W. et al. 1992, *Gut* 33:818–824, https://doi.org/10.1136/gut.33.6.818) **[E-h]**.
- → Kernel del risveglio: picco a 20 minuti, ampiezza 45 minuti, OR 3 (**STIMA**). Hazard notturna durante il sonno ×0,1.

### 2.5 Dieta: fibra e digeribilità

- Aggiungere 7% di polpa di agrumi o di mela (sulla sostanza secca) **aumenta la quantità di feci e la frequenza di defecazione** e riduce la digeribilità. La consistenza non cambia (Brambillasca S. et al. 2013, *Arch Anim Nutr* 67:492–502, https://doi.org/10.1080/1745039X.2013.857079) **[E]**.
- La quantità di feci è circa proporzionale alla **sostanza secca non digerita**: (1 − digeribilità) × sostanza secca ingerita. Passando da una digeribilità dell'85% al 75%, la sostanza secca fecale aumenta di circa ×1,7 (aritmetica, [E] per il principio). La frequenza cresce **meno che proporzionalmente** (×1,2–1,4, **STIMA**).
- Nei cani grandi la fibra fermentabile (polpa di barbabietola, FOS) peggiora le feci. La fibra non fermentabile (cellulosa) le migliora. Nei cani piccoli cellulosa e amidi purificati possono favorire la stitichezza (Weber 2017) **[E]/[C]**.
- **Umido rispetto a secco.** Non ho trovato studi solidi sulla frequenza di defecazione. Gli umidi sono spesso molto digeribili, quindi feci simili o un po' meno, ma più morbide. ×1,0 (**STIMA**).
- **Numero di pasti.** Le defecazioni al giorno seguono il numero dei pasti: ≈ 0,8–1,2 defecazioni per pasto (**STIMA [C]**).

### 2.6 Frequenza normale per stadio di vita

| Stadio | Defecazioni/giorno | Evidenza |
|---|---|---|
| Cucciolo 8–12 settimane (3–4 pasti) | 4–6 | [C]/[R] |
| Cucciolo 3–6 mesi | 3–4 | [C]/[R] |
| Giovane 6–12 mesi | 2–3 | [C]/[R] |
| Adulto | **1–3 (moda 2)** | [C] (WSAVA Global Nutrition Guidelines; Freeman L. et al. 2011, *J Small Anim Pract* 52:385–396, https://doi.org/10.1111/j.1748-5827.2011.01079.x — valutazione delle feci nella visita nutrizionale) |
| Anziano | 1–2 | [C]/STIMA |
| Allattamento (mangia 2–4 volte di più) | ×1,5–2 rispetto all'adulto | STIMA da NRC 2006 |

### 2.7 Farmaci e malattie per la cacca

| Fattore | Effetto | Evidenza |
|---|---|---|
| Cortisonici | Vomito 16,2% e diarrea 14,9% dei segni avversi registrati (Elkholly 2020) | [E] → ×1,1 STIMA |
| Antibiotici (amoxicillina-clavulanato, metronidazolo) | Possibile diarrea | [C] → ×1,2 STIMA, solo durante la terapia |
| Oppioidi | Rallentano il transito | [C] → ×0,6 STIMA |
| Lattulosio o lassativi | ×1,5–2 | [C]/STIMA |
| Fenobarbital (polifagia) | ×1,2 | STIMA |
| Anestesia generale | Svuotamento gastrico 12 → 49 h, normalizzato in 30–40 h | [E] Boscan 2014 → nessuna cacca attesa per 24–48 h |
| Colite o diarrea acuta | Frequenza ×2–4, picco tardivo dopo il pasto | [E] Sethi & Sarna 1991 (modello sperimentale) |
| Stress acuto (viaggio, ospite, temporale) | Due effetti opposti. **Ritardo** in un ambiente nuovo o in ricovero (Warrit 2017a). **Diarrea da stress** 12–48 h dopo, nei cani sensibili | [E]/[C] |

### 2.8 Consistenza delle feci

Si usa la scala fecale a 7 punti (Purina Fecal Scoring Chart; equivalente alla scala Waltham). **Normale 2–3**. Valori ≥ 5 per 2 o più evacuazioni consecutive indicano diarrea. Nei cani grandi le feci sono fisiologicamente un po' più umide (Hernot 2005/2006; Weber 2017) **[E]**: per questo la soglia d'allarme della consistenza va **resa relativa alla baseline del cane**.

---

## 3. Modelli predittivi esistenti: cosa prendere

1. **Cane.** Su PubMed e Consensus **non ho trovato** studi o brevetti che prevedano i tempi di eliminazione del cane. Esistono lavori di classificazione del comportamento con accelerometri da collare o pettorina, che potrebbero in futuro **rilevare** pipì e cacca automaticamente, ma non prevederle. Va fatta una ricerca brevettuale dedicata (Espacenet/Google Patents) prima di dichiarare "primo al mondo".
2. **Uomo: diario minzionale.** La definizione ICS di poliuria notturna è un indice (urina notturna / urina nelle 24 h) > 20–33% a seconda dell'età (van Kerrebroeck P. et al. 2002, *Neurourol Urodyn* 21:179–183, https://doi.org/10.1002/nau.10053). → Idea: calcolare per ogni cane un **"indice di eventi notturni"** e allarmare quando sale (nicturia nuova).
3. **Uomo: sensori vescicali indossabili.** Ecografia indossabile più machine learning per stimare il volume e dare un allarme **prima** della minzione: Wang J. et al. 2024, enuresi notturna ([scheda](https://consensus.app/papers/details/cd39abcdb0b458179c5ebedb1c0e5465/?utm_source=claude_code)); Jo H. et al. 2021, *Sensors* ([scheda](https://consensus.app/papers/details/556686ee0c9452db90c6f891ce1149a3/?utm_source=claude_code)); Cao L. et al. 2026, *Adv Sci* ([scheda](https://consensus.app/papers/details/2b4f1149ea345913a1090538bb85c35b/?utm_source=claude_code)). → **Idea di modellazione: il volume vescicale è lo stato latente.** Il nostro simulatore lo rende esplicito. La regressione logistica approssima la sua hazard con: tempo dall'ultimo evento, acqua recente ed eventi.
4. **Uomo: "prompted/timed voiding"** nelle residenze per anziani. Le uscite si programmano sull'intervallo individuale appreso dal diario. È la stessa logica della notifica al quantile 20% già in 04.
5. **Uomo: defecazione.** Solo il 33–40% delle persone ha un ciclo regolare di 24 h (Heaton 1992). → Aspettarsi **molta varianza individuale** nella cacca e dare un peso alto ai dati del cane, con un prior più debole che per la pipì.

---

## 4. Raccomandazioni di architettura (dal punto di vista fisiologico)

1. **Separare bisogno e opportunità.** Va registrato (o dedotto) l'accesso all'esterno: passeggiata, giardino, traversina. Nei cani educati, la probabilità di un evento in un intervallo senza accesso è ≈ 0, salvo incidenti. Senza questa covariata il modello impara gli orari del padrone, non la fisiologia del cane. Proposta:
   - `logit P(evento) = logit P(bisogno) + log(opportunità)`;
   - opportunità = 1 in passeggiata o con la porta aperta, 0,02 in casa per un adulto educato, 0,3 per un cucciolo.
2. **Marcature.** Gli eventi a meno di 15 minuti dallo svuotamento principale non azzerano il timer, oppure vanno etichettati come "marcatura" (04 § 1.5).
3. **Simulatore della pipì: meccanicistico.**
   - `V(t+Δ) = V(t) + r(t)·Δ`;
   - `r(t) = r_base · M_taglia · M_dieta · M_temp · M_farmaci · M_malattia · c(t) + Σ boli_acqua ⊗ kernel + Σ farmaci ⊗ kernel`;
   - hazard del bisogno = `h0 · (V/V_fun)^γ` con γ ≈ 3 (**STIMA**). Dopo lo svuotamento `V = residuo`.
   Generare pseudo-dati con cibo, acqua e passeggiate tipici dell'utente (orari dichiarati all'onboarding).
4. **Simulatore della cacca: a trigger.**
   - hazard di base debole e crescente col tempo dall'ultima cacca (Weibull, k ≈ 2);
   - più i kernel di pasto, attività e risveglio;
   - più uno "stato di riempimento colico" alimentato dai pasti con ritardo pari al transito totale per taglia (gamma, CV 0,3). Serve a far emergere effetti come "pasto saltato ieri → meno cacca oggi".
5. **Approssimare la logistica.** Per probabilità piccole in 15 minuti (< 0,2), un moltiplicatore della hazard M equivale a uno spostamento del logit di **ln M**. Per probabilità più alte usare la forma cloglog (`log(−log(1−p))`), che è esattamente proporzionale alla hazard: è consigliata.
6. **Peso per recenza.** Emivita di 14 giorni per adulto e anziano, 5 giorni per il cucciolo (che cambia ogni settimana), 3 giorni dopo un cambio di farmaco o di dieta.
7. **Forza del prior.** Pseudo-dati equivalenti a 7 giorni di registrazioni per la pipì, 4 giorni per la cacca (più variabile tra individui). La forza va scalata per 0,5 quando il cane ha una malattia nota, perché il prior è meno affidabile.

---

## 5. Limiti

- Le latenze in minuti (risveglio, pasto, acqua, attività) sono in gran parte **STIMA**. Sono vincolate da finestre fisiologiche misurate (ADH in 15 minuti, colon distale 0–2 h, defecazione "poco dopo" l'inizio dell'esercizio), ma non da registrazioni domestiche.
- I dati sui transiti vengono da pochi cani (6–50), spesso beagle o cani da laboratorio, e da metodi diversi (capsula o marcatori) che non danno lo stesso risultato.
- La frequenza "normale" di pipì e cacca nel cane di casa **non è mai stata misurata su larga scala**. Zampa, con il consenso degli utenti, potrebbe produrre il primo dataset del genere: è un'opportunità di pubblicazione.

---

## PARAMETRI PER IL CODICE

Convenzioni:
- intervalli in minuti; `τ` = tempo dall'ultimo evento vero (marcature escluse);
- "OR" = moltiplicatore della hazard al picco del kernel;
- kernel = gamma normalizzata a 1 al picco, con moda (`peak`) e ampiezza a metà altezza (`fwhm`): `K(Δt) = (Δt/peak)^a · exp(a·(1 − Δt/peak))`, con `a` scelto in modo da ottenere la `fwhm` (a ≈ 5,5·(peak/fwhm)²);
- effetto sul log-hazard = `ln(OR) · K(Δt)`;
- moltiplicatori biologici = offset `ln(M)` sul log-hazard (o fattori su `r(t)` nel simulatore).

### P1. PIPÌ — intervallo di base (da sveglio, svuotamenti veri)

| Stadio | Mediana `τ` | σ log | Weibull k (≈1,28/σ) | Max diurno | Max notturno | Svuotamenti/die | Fonte |
|---|---|---|---|---|---|---|---|
| 8–10 settimane | 60 | 0,45 | 2,8 | 180 | 240 | 10–14 | 04 [R] |
| 11–13 settimane | 90 | 0,45 | 2,8 | 240 | 300 | 8–12 | 04 [R] |
| 4 mesi | 120 | 0,45 | 2,8 | 300 | 390 | 6–9 | 04 [R] |
| 5 mesi | 150 | 0,45 | 2,8 | 360 | 450 | 5–8 | 04 [R] |
| 6–11 mesi | 210 | 0,42 | 3,0 | 420 | 510 | 4–6 | 04 [R]/[C] |
| Adulto | 300 | 0,40 | 3,2 | 480 | 600 | 3–5 | 04 [C] |
| Anziano | 240 | 0,45 | 2,8 | 360 | 480 | 4–6 | 04 [C] |

### P2. PIPÌ — fisiologia per il simulatore

| Parametro | Valore | Evidenza |
|---|---|---|
| `r_base` (produzione di urina, adulto 15 kg, dieta secca, 20 °C) | 1,1 ml/kg/h (≈ 26 ml/kg/die) | [E] (22 ml/kg/die in Pelligand 2020; 20–45 nei testi) |
| Scala di taglia della produzione | `(BW/15)^-0,25` | [C] derivato da NRC |
| Scala di taglia dell'intervallo (prior) | `(BW/15)^+0,15` (attenuata dalle abitudini) | STIMA |
| `V_fun` (volume a uno svuotamento normale) | adulto 8 ml/kg; anziano 6; 6–11 mesi 6; 4–5 mesi 4,5; 8–13 settimane 3,5 | STIMA |
| `V_max` (urgenza o incidente) | 2,5 × `V_fun` | STIMA |
| Residuo post-svuotamento | 0,2 ml/kg | [E] Atalan 1999 |
| Esponente dell'urgenza γ | 3 | STIMA |
| Fattore circadiano intrinseco `c(t)` sulla produzione (22–06) | 0,7 | STIMA (Goetz & Wang 1986: nessun ADH notturno nel cane) |
| Produzione netta notte/giorno risultante | ≈ 0,5 | STIMA (Corea 1996: urina bassa di notte) |
| Picco di produzione dopo il pasto | 4–8 h dopo il pasto principale, ×1,3 | [E] Corea 1996 (direzione e tempi); STIMA (ampiezza) |
| Escrezione di un bolo d'acqua (euidratato) | 60% in 3 h, kernel gamma peak 60, fwhm 90 | STIMA ([E] ADH in 15 minuti, Thrasher 1981) |
| Escrezione di un bolo d'acqua (dopo esercizio o caldo) | 25% in 3 h | STIMA |

### P3. PIPÌ — kernel di evento

| Evento | Peak (min) | FWHM (min) | OR adulto | OR cucciolo < 6 mesi | OR anziano | Evidenza |
|---|---|---|---|---|---|---|
| Risveglio da sonno ≥ 2 h (mattino) | 5 | 20 | 6 | 10 | 6 | [R]/[C] |
| Risveglio da pisolino < 1 h | 5 | 20 | 1,5 | 4 | 2 | [R] |
| Acqua (per ogni 10 ml/kg bevuti) | 60 | 90 | 2,0 | 2,5 | 2,2 | STIMA ([E] Thrasher 1981) |
| Pasto | 30 | 60 | 1,3 | 2,0 | 1,3 | [R] (via acqua del pasto) |
| Gioco o attività intensa (dalla fine) | 10 | 30 | 1,5 | 3 | 1,5 | [R] |
| Durante lo sforzo intenso | — | — | ×0,7 | ×1,0 | ×0,7 | STIMA |
| Eccitazione (arrivo persone) | 1 | 10 | 1,2 | 3 | 1,2 | [C] |
| Inizio passeggiata (opportunità) | 5 | 15 | 8 | 8 | 8 | [R] / [E] Atalan 1999 (svuotamento nei primi 10 minuti) |
| Furosemide per bocca (dose standard) | 90 | 180 | 4 (sulla produzione) | — | 4 | [E] Koh 2021 (picco 2 h); STIMA (ampiezza) |
| Torasemide | 120 | 480 | 3 (sulla produzione) | — | 3 | [E] Pelligand 2020 (×3,3/die) |

### P4. PIPÌ — moltiplicatori biologici (sulla hazard o sulla produzione)

| Fattore | Moltiplicatore | Evidenza |
|---|---|---|
| BW < 10 kg | intervallo ×0,85 (equivale a `(BW/15)^0,15`) | [C]/STIMA |
| Maschio intero, eventi totali in passeggiata | ×3–5 (marcature, **non** azzerano τ) | [E] Atalan 1999, Sprague & Anisko 1973 |
| Maschio castrato, marcatura | ×0,5 rispetto all'intero | [E] Hopkins 1976 |
| Femmina sterilizzata, frequenza | ×1,0 | [E] Balogh 2018 |
| Femmina sterilizzata, perdite a riposo | probabilità di incontinenza 5–20% (> 20 kg più alta). Evento separato, non pipì | [E] Beauvais 2012 |
| Estro/proestro: eventi in passeggiata | ×1,7 | [E] direzione (Wirant 2007); STIMA |
| Estro: svuotamenti veri | ×1,1 | STIMA |
| Gravidanza > 40 giorni | ×1,25 | STIMA |
| Allattamento | ×1,25 (acqua ×2–3) | STIMA (NRC per l'energia) |
| Anziano (già nella P1) | — | — |
| Dieta umida (> 50% dell'energia) | produzione ×1,25 se < 10 kg; ×1,1 se 10–25 kg; ×1,05 se > 25 kg; acqua bevuta ×0,5 | [E] Stevenson 2003; STIMA |
| Dieta ad alto sodio ("urinaria") | produzione ×1,3 | [E] Queau 2020 (direzione); STIMA |
| Dieta con KCl aggiunto | ×1,15 | [E] Bijsmans 2021; STIMA |
| Temperatura > 28 °C | produzione ×1,0; acqua bevuta ×1,4 | [E] Baker 1984, Rashotte 1984; STIMA |
| Temperatura < 5 °C | produzione ×1,1 | STIMA |
| Prednisolone a dose antinfiammatoria | ×1,5 | [E] Elkholly 2020 (direzione); STIMA |
| Prednisolone a dose immunosoppressiva | ×2,5 | STIMA |
| Fenobarbital / KBr | ×1,3 | [C] Bhatti 2015; STIMA |
| Spironolattone / ACE-inibitori | ×1,1 | STIMA |
| Desmopressina | ×0,6 | STIMA |
| Diabete mellito non controllato | ×2,5 | [C] AAHA 2018 |
| Cushing | ×2,0 | [C] ACVIM 2013 |
| Malattia renale IRIS 2 / 3–4 | ×1,4 / ×1,8 | [C] IRIS; STIMA |
| Cistite / infezione urinaria | ×3 (volumi piccoli) | [C] ISCAID 2019 |
| Ambiente nuovo o paura in passeggiata | ×0,6 durante, poi recupero | [E] McGuire 2020/2023 (direzione) |
| Opportunità: in casa, adulto educato | ×0,02 | STIMA |
| Opportunità: in casa, cucciolo | ×0,3 | STIMA |

### P5. PIPÌ — ritmo circadiano (hazard a parità di τ)

| Stato | Rapporto rispetto al giorno da sveglio | Evidenza |
|---|---|---|
| Sonno notturno (adulto) | 0,15 | STIMA (consistente con 8–10 h di notte senza uscire, [C]) |
| Sonno notturno (cucciolo < 4 mesi) | 0,35 | STIMA |
| Sonno notturno (anziano) | 0,25 | STIMA |
| Armoniche di Fourier per l'ora (k = 1, 2) | inizializzare a 0; imparare dai dati | — |

### P6. PIPÌ — soglie d'allarme (invariate rispetto a 04 § 1.4, con aggiunte)

| Segnale | Soglia |
|---|---|
| Anuria | Adulto > 12 h da sveglio → avviso; > 24 h → urgenza. Cucciolo > 8 h → urgenza |
| Sforzo senza urina | Subito (soprattutto maschi) |
| Pollachiuria | ≥ 3 minzioni a < 60 minuti l'una dall'altra in 3 h, oppure conteggio ≥ 2× baseline |
| PU/PD | Conteggio ≥ +50% per ≥ 3 giorni, oppure acqua > 100 ml/kg/die (80–100 zona grigia) |
| Nicturia nuova | ≥ 2 notti su 7 con eventi notturni in un cane prima "asciutto". **Nuovo:** indice notturno (eventi 22–06 / eventi 24 h) > 0,20 per 7 giorni |
| Con cortisonici o diuretici | PU/PD **attesa**: alzare la soglia del conteggio a ×2,5 baseline. Mantenere l'allarme su anuria e sforzo |

### P7. CACCA — intervallo di base

| Stadio | Defecazioni/die | Mediana `τ` da sveglio | σ log | Weibull k | Evidenza |
|---|---|---|---|---|---|
| 8–12 settimane | 4–6 | 240 | 0,55 | 2,3 | [C]/[R] |
| 3–6 mesi | 3–4 | 330 | 0,55 | 2,3 | [C]/[R] |
| 6–12 mesi | 2–3 | 480 | 0,55 | 2,3 | [C]/STIMA |
| Adulto | 1–3 (moda 2) | 660 | 0,60 | 2,1 | [C]/STIMA |
| Anziano | 1–2 | 780 | 0,60 | 2,1 | STIMA |

Regola di coerenza: defecazioni/die attese ≈ 0,8–1,2 × pasti/die. Se l'utente dichiara 1 solo pasto, mediana adulto 900 minuti.

### P8. CACCA — kernel di evento

| Evento | Peak (min) | FWHM (min) | OR adulto | OR cucciolo | OR anziano | Evidenza |
|---|---|---|---|---|---|---|
| Pasto, risposta precoce (colon distale) | 30 | 60 | 3 | 5 | 2,5 | [E] Sarna & Lang 1989 (finestra 0–2 h); STIMA (minuti e OR) |
| Pasto, risposta tardiva (digesta nel colon) | 300 | 360 | 1,3 | 1,5 | 1,3 | [E] Sarna & Lang 1989 (2–8 h) |
| Inizio attività o passeggiata | 10 | 20 | 6 | 6 | 4 | [E] Dapoigny & Sarna 1991 (defecazione poco dopo l'inizio dell'esercizio); STIMA (OR) |
| Seconda finestra durante la passeggiata | 25 | 20 | 1,5 | 1,5 | 1,5 | [E] Dapoigny & Sarna 1991 (seconda GMC dopo ~10 minuti, nel 40% delle prove) |
| Risveglio dal sonno notturno | 20 | 45 | 3 | 4 | 3 | [E-h] Rao 2004, Heaton 1992; STIMA |
| Risveglio da pisolino | 15 | 30 | 1,3 | 2 | 1,3 | STIMA |
| Stress acuto (viaggio, ospiti, temporale) | 60 | 120 | 1,5 (cani "sensibili") | 1,5 | 1,5 | [C]/STIMA |

### P9. CACCA — transito e "riempimento colico" (simulatore)

| Parametro | Valore | Evidenza |
|---|---|---|
| Transito totale (bocca → feci), cane < 10 kg | media 24 h, CV 0,3 | [E] Hernot 2005 (22 h barboncino nano) |
| 10–25 kg | 30 h | [E] Hernot 2005 (interpolato) |
| 25–40 kg | 40 h | [E] Hernot 2005/2006 |
| > 40 kg | 50 h | [E] Hernot 2005 (59 h schnauzer gigante) |
| Formula continua | `TTT_h ≈ 18 + 0,7·BW` (limitata a 20–60 h) | STIMA (regressione grossolana su Hernot 2005) |
| Variabilità nello stesso cane | CV 0,16 | [E] Lidbury 2012 |
| Cucciolo (razze grandi) | transito oro-cecale più lungo a 12 settimane; stomaco più veloce | [E] Weber 2002/2003 → nessuna correzione netta (STIMA) |
| Dopo ricovero o anestesia | ritardo aggiuntivo di 24–48 h | [E] Warrit 2017a, Boscan 2014 |

### P10. CACCA — moltiplicatori biologici

| Fattore | Moltiplicatore | Evidenza |
|---|---|---|
| Digeribilità della dieta ≤ 75% (rispetto a ≥ 85%) | ×1,3 | [E] principio + Brambillasca 2013; STIMA |
| Fibra aggiunta (polpe, ~7% sulla sostanza secca) | ×1,25 | [E] Brambillasca 2013 (direzione); STIMA |
| Dieta umida rispetto a secca | ×1,0 | STIMA |
| Allattamento | ×1,7 | STIMA (NRC per l'assunzione di cibo) |
| Gravidanza > 40 giorni | ×1,1 | STIMA |
| Taglia > 25 kg | ×1,0 sulla frequenza (feci più umide, transito più lungo) | [E] Weber 2017 |
| Fenobarbital (polifagia) | ×1,2 | STIMA |
| Oppioidi | ×0,6 | [C]/STIMA |
| Antibiotici | ×1,2 | [C]/STIMA |
| Lassativi (lattulosio) | ×1,7 | [C]/STIMA |
| Ambiente nuovo o paura | ×0,5 durante, poi rimbalzo | [E] McGuire 2020/2023; Warrit 2017a |
| Sonno notturno | ×0,1 | STIMA |
| Opportunità in casa (adulto educato / cucciolo) | ×0,02 / ×0,3 | STIMA |

### P11. CACCA — soglie d'allarme

| Segnale | Soglia | Urgenza |
|---|---|---|
| Nessuna cacca — adulto | > 48 h → avviso. > 72 h, oppure > 48 h con sforzo, vomito, abbattimento o addome teso → veterinario | 🟡 / 🔴 |
| Nessuna cacca — cucciolo < 6 mesi | > 24 h → avviso; > 36 h → veterinario | 🟠 / 🔴 |
| Dopo anestesia o ricovero | Tolleranza +48 h prima dell'avviso | — |
| Diarrea | Punteggio fecale ≥ 6 (scala 1–7) in ≥ 2 evacuazioni, **oppure** conteggio ≥ 2× baseline nelle 24 h | 🟠 |
| Diarrea più vomito, sangue, melena o abbattimento | Qualsiasi episodio | 🔴 |
| Cucciolo non vaccinato con diarrea e vomito | Qualsiasi episodio | 🔴 (rischio parvovirosi) |
| Tenesmo (sforzo ripetuto senza feci) | ≥ 3 tentativi in una passeggiata, o ripetuto in 24 h | 🟠 (nel maschio va distinto dall'ostruzione urinaria → 🔴 se non urina) |
| Cambio di baseline | Media mobile di 7 giorni delle defecazioni/die con scostamento ±50% per ≥ 5 giorni, senza cambi di dieta | 🟡 |

### P12. Iperparametri di apprendimento

| Parametro | Pipì | Cacca |
|---|---|---|
| Forza del prior (giorni di pseudo-dati equivalenti) | 7 | 4 |
| Emivita del peso per recenza: adulto e anziano / cucciolo | 14 d / 5 d | 14 d / 5 d |
| Emivita dopo un cambio di farmaco o di dieta | 3 d | 3 d |
| Prior ridotto (×0,5) con malattia nota | sì | sì |
| Funzione di collegamento | cloglog (consigliata) o logit | idem |
| Base dell'intervallo | Weibull su τ (k dalla tabella) + Fourier 24 h/12 h + offset di stato (sonno) | idem |
