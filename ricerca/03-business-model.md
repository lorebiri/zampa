# Zampa: quando può portare soldi? Modello di business, costi e scenari

*Business analyst, 10 novembre 2026. Il documento distingue i **[FATTO]** (dati da fonte citata) dalle **[STIMA]** (ipotesi mie, ragionate ma non verificate). Le fonti sono in fondo, numerate [n].*

---

## 0. Risposta breve

- **Coprire le spese vive** (abbonamenti a servizi, store, commercialista) è un traguardo vicino. Nello scenario realistico arriva **circa 16 mesi dopo il lancio**: se si lancia ad aprile 2027, intorno all'**estate 2028**.
- **Recuperare tutto quello che si è speso** arriva **circa 30 mesi dopo il lancio**, verso **fine 2029**.
- **Guadagnare in modo significativo** (almeno 1.000 € netti al mese) **non succede nei 3 anni** dello scenario realistico. Succede solo nello scenario ottimista, dopo circa 13 mesi, e quello scenario corrisponde al 5% migliore delle app.
- **Il tempo del fondatore non rientra mai** nei primi 3 anni, salvo nello scenario ottimista. Nello scenario realistico rende circa 1-2 € l'ora.
- **Prima dei numeri va chiarito un punto.** Lorenzo è dipendente pubblico (CNR) e ha un reddito da lavoro dipendente. Questo può limitare sia la possibilità di aprire una partita IVA sia l'accesso al regime forfettario (sezione 7). Va risolto **prima** di incassare il primo euro.

---

## 1. Dimensione del mercato

| Dato | Valore | Tipo | Fonte |
|---|---|---|---|
| Cani in Italia (dati 2024) | **9,0 milioni** | FATTO | FEDIAF Facts & Figures 2026 [1] |
| Cani in Europa, 41 Paesi (2024) | **91,2 milioni** | FATTO | FEDIAF 2026 [1] |
| Cani nell'UE-27 (2024) | circa **69,6 milioni** | FATTO (fonte secondaria su dati FEDIAF) | [2] |
| Famiglie italiane con almeno un cane | circa **22%** | FATTO (tabella FEDIAF; ho dedotto l'ordine delle colonne cane/gatto) | [1] |
| Famiglie italiane con cane, in valore assoluto | circa **5,5-5,8 milioni** | STIMA (22% di circa 26 milioni di famiglie) | — |
| Mercato pet food e pet care in Italia (2025) | **5,3 miliardi €**, +2,5% | FATTO | Rapporto Assalco-Zoomark 2026, via QuiFinanza [3] |
| Pet food per cani e gatti in Italia (2024) | circa 3,1 miliardi €; canale online 451 milioni € (+8,2%) | FATTO | Assalco-Zoomark 2025 [3][4] |
| Spesa media per cane | circa **900 €/anno** (75 €/mese) | FATTO (elaborazione Unipol) | [3] |
| Mercato delle polizze pet in Italia | circa 650-750 milioni € (2024-2025) | FATTO, ma le fonti divergono | QuiFinanza [5] |
| Penetrazione delle polizze salute pet in Italia | bassa. Nell'osservatorio Segugio il 15,5% dei richiedenti sceglie una copertura salute; in Svezia sono assicurati il 90% dei cani | FATTO (campione del comparatore, non nazionale) | [5][6] |
| Strutture veterinarie in Italia | **oltre 6.500**; circa 36.500 veterinari iscritti all'Ordine | FATTO (dichiarazione del presidente ANMVI) | Il Sole 24 Ore [7] |
| Mercato globale delle app pet care (2025) | circa 2-3 miliardi $ | STIMA di società di ricerca, poco affidabile | [8] |
| Quota di proprietari che usano un'app pet | **dato affidabile non trovato.** Il "68%" che circola non cita un'indagine. | — | [8] |

**Cosa ne ricavo [STIMA]:**
- In Italia ci sono circa 5,5 milioni di famiglie con cane e spendono circa 900 € l'anno per cane. Il mercato è grande, ma i soldi vanno quasi tutti in cibo, veterinario e prodotti, non in software.
- Un'app che arrivasse allo 0,5% delle famiglie con cane avrebbe circa 28.000 utenti installati.
- La concorrenza in Italia è già affollata e quasi tutta gratuita: MyVet (legata alle cliniche), Joppys, 11pets, Veton, Pet Care Tracker [9]. 11pets in Italia ha un voto di 2,8/5 su 49 recensioni [10]. Le app ci sono, ma sono mediocri: c'è spazio per la qualità, non per l'esclusività.
- **Il tracker pipì predittivo con promemoria per chi vive senza giardino è il vero elemento distintivo.** Non ho trovato concorrenti diretti. È anche l'unica funzione che giustifica un abbonamento, perché porta l'utente ad aprire l'app ogni giorno.

---

## 2. Quanto guadagnano le app in abbonamento

### 2.1 Prezzi dei concorrenti [FATTO]

| Prodotto | Prezzo | Fonte |
|---|---|---|
| 11pets (Italia) | acquisti in-app da 1,99 € e 19,99 € | App Store IT [10] |
| PawPrint Vault | Pro circa 19,99 $/anno, lifetime 49,99 $ | [11] |
| PawLog / PawProof (app per la salute del pet) | 39,99 $/anno | [11] |
| PawLedger | Premium 29,99 $/anno | [11] |
| Tractive GPS (abbonamento legato a hardware) | Basic 72-84 €/anno; Premium 96-108 €/anno; 5 anni 240-300 € | tractive.com/it [12] |
| Kippy GPS | circa 5,83 €/mese con piano annuale | [13] |
| PetDesk (B2B, USA, app per clinica) | da 199 $/mese | [14] |
| Vetstoria (B2B, prenotazioni online) | circa 149-449 €/mese (dati di aggregatori) | [14] |

**[STIMA]** Un'app solo software (senza hardware) in Europa si vende a **20-40 € l'anno**. Il prezzo che consiglio per Zampa Premium è **24,99 €/anno o 3,99 €/mese**, con un'opzione "a vita" a 49-59 €.

### 2.2 Benchmark di conversione e retention [FATTO, RevenueCat]

| Metrica | Valore | Fonte |
|---|---|---|
| Da download a pagante (giorno 35), **freemium** | mediana **2,1%** (2026); 2,18% (2025) | RevenueCat SOSA 2026 / 2025 [15][16] |
| Da download a pagante (giorno 35), **paywall rigido** | mediana 10,7% (2026); 12,1% (2025) | [15][16] |
| Da prova a pagante, categoria Salute e Fitness | mediana 39,9%; 10% migliore 68,3% | SOSA 2025 [16] |
| Ricavo per installazione a 60 giorni, Salute e Fitness | mediana 0,63 $; 10% migliore 4,19 $ | SOSA 2025 [16] |
| Ricavo per installazione a 60 giorni, tutte le categorie | mediana 0,31 $ | [16] |
| Abbonati annuali ancora attivi dopo 1 anno | 44,1% (SOSA 2025); **27-28%** (SOSA 2026, definizione e coorte diverse) | [15][16] |
| Abbonati mensili ancora attivi dopo 1 anno | 17,0% | [16] |
| App nuove che arrivano a 1.000 $ di ricavi totali in 2 anni | **circa 20%** | [16] |
| App nuove che arrivano a 10.000 $ in 2 anni | **circa 5%** | [16] |
| Differenza tra le app migliori e le peggiori | il 25% migliore cresce l'MRR di oltre l'80% in un anno; il 25% peggiore cala di oltre il 33% | [17] |

**Questo è il numero più importante del documento:** l'80% delle app in abbonamento **non incassa nemmeno 1.000 $ in due anni** [16]. Gli scenari della sezione 5 sono calibrati su questa base.

### 2.3 Commissioni degli store e IVA [FATTO, con alcune incertezze]

- **Apple, Small Business Program: commissione del 15%** sotto 1 milione $ di ricavi annui. Bisogna iscriversi. Sugli abbonamenti dal secondo anno la commissione è comunque del 15% [18].
- **Google Play: 15%** sugli abbonamenti e sul primo milione $. Dal 30 giugno 2026 nello Spazio Economico Europeo la struttura sarebbe cambiata in "10% di servizio + 5% di fatturazione", con un totale invariato del 15%. Le fonti non concordano: va verificato sulla Play Console [18].
- **IVA:** per le vendite ai consumatori dell'UE il venditore verso il cliente è lo store, che versa l'IVA. Lo sviluppatore riceve il prezzo **al netto dell'IVA e della commissione**. Con l'IVA italiana al 22%: 24,99 € / 1,22 × 0,85 = **17,41 € netti per abbonato all'anno**. Questo calcolo è alla base di tutti gli scenari.
- **Digital Services Act:** per vendere nell'UE bisogna dichiararsi "trader" sull'App Store. Indirizzo, telefono ed email del venditore diventano **pubblici** sulla scheda dell'app [FATTO, regola Apple dal 2025]. Va considerato per la privacy di Lorenzo.

---

## 3. Modelli di ricavo: cosa è realistico per una persona sola

| Modello | Potenziale | Fattibilità per una persona sola | Giudizio |
|---|---|---|---|
| **Freemium + Premium in abbonamento** (gratis: cartella sanitaria, 1 cane, promemoria base; Premium: tracker predittivo avanzato, più cani, famiglia condivisa, esportazione PDF per il veterinario, backup) | Medio-basso, ma prevedibile | **Alta**: RevenueCat è gratuito fino a 2.500 $ di ricavi mensili tracciati | **Modello principale** |
| **Acquisto "a vita"** (49-59 €) accanto all'abbonamento | Fa incassare prima; RevenueCat segnala che consumabili e lifetime migliorano ricavi e retention [16] | Alta | **Sì, come opzione** |
| **App a pagamento una tantum** (prezzo al download) | Basso: in Italia un'app sanitaria per il cane a pagamento non trova utenti | Alta | No |
| **Paywall rigido** (prova gratuita, poi si paga) | Converte circa 5 volte più del freemium [15] | Alta | **Da provare sul solo tracker pipì**: la cartella sanitaria deve restare gratuita, per fiducia e passaparola |
| **B2B per cliniche veterinarie** (pagina con il marchio della clinica, promemoria vaccini mandati dalla clinica, portale) | Alto per singolo cliente: PetDesk parte da 199 $/mese [14]. In Italia il prezzo realistico è 19-49 €/mese [STIMA] | **Bassa all'inizio**: vendita lunga, assistenza, integrazione con i gestionali (MyVet è già lì) | **Fase 2**, dopo 12-18 mesi, solo come pilota con 3-5 cliniche della zona |
| **Affiliazione cibo** | Zooplus su Awin: **3% sui primi 3 ordini, poi 1%** [19]. Su un ordine da 50 € sono circa 1,5 € | Alta tecnicamente, ricavo minimo | Sì, ma vale pochi centesimi per utente al mese |
| **Affiliazione assicurazioni pet** | Mercato in crescita (650-750 milioni €) e penetrazione bassa [5]. Commissione per segnalazione stimata 10-30 € [STIMA, nessun programma pubblico trovato] | **Attenzione:** proporre polizze può configurare **intermediazione assicurativa**, che richiede l'iscrizione al RUI dell'IVASS. La semplice segnalazione è una zona grigia. | Solo con un accordo scritto con una compagnia o un broker che si assuma la parte regolamentata |
| **Partnership con produttori di cibo** (sponsor, contenuti sulla nutrizione) | Solo oltre circa 50.000 utenti attivi al mese | Media | Più avanti. Rischio per la credibilità: i consigli nutrizionali devono restare indipendenti |
| **Vendita di dati aggregati anonimi** | Vale qualcosa solo su larga scala (oltre 100.000 cani) | **Bassa**: serve una vera anonimizzazione (GDPR, considerando 26), con informativa e base giuridica. Le abitudini di passeggiata e i dati di geolocalizzazione dicono molto della **persona**, non solo del cane. | **Sconsigliato** come fonte di ricavo: rischio legale e per la fiducia maggiore del guadagno. Al massimo collaborazioni di ricerca con università e IZS, con consenso esplicito (opt-in) |
| **Marketplace di dog sitter** | Alto sulla carta | **Molto bassa**: mercato a due lati, pagamenti (regole PSD2, Stripe Connect), responsabilità e assicurazione, verifica dei sitter, concorrenti già finanziati (Rover, Pawshake) | **No** |
| **Pubblicità** (banner) | Molto basso ai volumi italiani | Alta | No: rovina un'app che tratta la salute |

---

## 4. Costi

### 4.1 Costi fissi e variabili [FATTO dove indicata la fonte, altrimenti STIMA]

| Voce | Costo | Note |
|---|---|---|
| Apple Developer Program | **99 €/anno** (circa 8,25 €/mese) | FATTO, listino Apple |
| Google Play Console | **25 $ una volta sola** | FATTO, listino Google |
| Backend Supabase | gratis all'inizio; **Pro 25 $/mese** (circa 23 €), con 100.000 utenti attivi al mese inclusi, poi 0,00325 $ per utente in più | FATTO [20]. Il piano gratuito mette in pausa i progetti inattivi: per la produzione serve il Pro dal lancio |
| Firebase Cloud Messaging / APNs (notifiche push) | **0 €** | FATTO (gratuiti). Le notifiche locali programmate sul dispositivo (promemoria vaccini, pipì) non costano nulla e funzionano senza rete |
| RevenueCat | 0 € fino a 2.500 $ di ricavi mensili tracciati, poi circa l'1% | FATTO (listino RevenueCat) |
| Dominio | circa 15 €/anno | STIMA |
| Privacy policy, cookie, termini (es. generatore iubenda) | circa 30-120 €/anno | STIMA |
| Consulenza legale una tantum per GDPR e termini sanitari ("non sostituisce il veterinario") | 0-500 € | STIMA |
| Commercialista (se c'è la partita IVA) | **800-1.200 €/anno** | STIMA |
| Diritto camerale / INAIL | non dovuti per la gestione separata | STIMA, da verificare |
| Marketing a pagamento | vedi 4.2 | — |

**Totale fisso [STIMA]:** circa **20 €/mese senza partita IVA** e circa **130 €/mese con partita IVA e commercialista**. Il commercialista è la voce più pesante.

### 4.2 Costo di acquisizione degli utenti (pubblicità)

- **[FATTO, ma da prendere come indicazione]** Il costo per installazione su Meta in Italia, categorie salute e benessere, va da circa 12 a 36 (valuta non chiara) secondo un unico aggregatore [21]. Le medie globali generiche sono circa 3,7 $ su Android e 4,7 $ su iOS [21].
- **[STIMA] Valore di un'installazione nello scenario realistico:** 2,5% di conversione × 17,41 € × (1 + 0,40 + 0,32 di rinnovi) ≈ **0,75 €**. Nello scenario ottimista ≈ **1,60 €**. Il benchmark di settore conferma l'ordine di grandezza: 0,63 $ a 60 giorni per Salute e Fitness [16].
- **Conclusione [STIMA]:** con un costo per installazione realistico di 2-5 € e un valore di 0,75-1,60 €, **la pubblicità a pagamento fa perdere soldi**. La crescita deve essere **organica**: ottimizzazione della scheda sugli store, contenuti, comunità, veterinari, canili e associazioni. Al massimo una piccola prova con Apple Search Ads sulle parole chiave "pipì cane" e "libretto vaccini cane".

---

## 5. I tre scenari

### 5.1 Ipotesi comuni

- **Il lancio è previsto ad aprile 2027.** Il "mese 0" degli scenari è il lancio; oggi siamo a circa 5 mesi dal lancio.
- **Paganti attivi** = nuovi paganti degli ultimi 12 mesi + rinnovi al secondo anno (tasso r) + rinnovi al terzo anno (r × 0,8). Ogni mese, i nuovi paganti sono le nuove installazioni moltiplicate per la conversione.
- **Ricavo dagli abbonamenti** = paganti attivi × netto annuo / 12. È un valore ricorrente mensile spalmato: gli abbonamenti annuali entrano in cassa in anticipo, ma vanno letti su 12 mesi.
- **Netto annuo per abbonato** = prezzo / 1,22 (IVA) × 0,85 (commissione store del 15%).
- **Utenti attivi al mese** = 20-25% delle installazioni cumulate [STIMA, tipica per un'app di utilità].
- **Imposte e contributi** (se c'è la partita IVA in forfettario, sezione 7) ≈ **18,6% dei ricavi**: 67% di redditività × (24% INPS + 5% di imposta sostitutiva sulla base al netto dei contributi). Con l'imposta al 15% invece del 5% si sale a circa il 24%.
- **Il tempo del fondatore non è contato come costo** (vedi 5.5).
- Calcolo fatto con uno script Python, ricalcolabile a richiesta.

### 5.2 Parametri per scenario

| | **Pessimista** (circa la mediana delle app) | **Realistico** (ben fatta, circa il 20% migliore) | **Ottimista** (circa il 5% migliore, con espansione UE) |
|---|---|---|---|
| Installazioni cumulate a 6 / 12 / 24 / 36 mesi | 300 / 800 / 2.000 / 3.000 | 1.500 / 5.000 / 15.000 / 30.000 | 5.000 / 20.000 / 70.000 / 150.000 |
| Quota delle famiglie italiane con cane a 36 mesi | 0,05% | 0,5% | 2,6% (in parte da altri Paesi UE) |
| Conversione da download a pagante | 1,5% | 2,5% | 4,0% |
| Prezzo annuale | 19,99 € | 24,99 € | 29,99 € |
| Netto per abbonato all'anno | 13,93 € | 17,41 € | 20,89 € |
| Rinnovo al primo anno | 30% | 40% | 50% |
| Affiliazioni (€ per utente attivo al mese) | 0 | 0,01 | 0,02 |
| B2B cliniche | — | — | dal mese 18, +2 cliniche al mese fino a 30, a 39 €/mese |
| Marketing | 0 € | 100 €/mese | 300 €/mese |
| Partita IVA e commercialista | no (vedi nota) | sì (80 €/mese) | sì |
| Costi fissi totali al mese | circa 18 € | circa 230 € | circa 430 € |

### 5.3 Risultati: ricavi, costi e utile per mese (€)

**Pessimista**

| Mese | Installazioni | Utenti attivi | Paganti | Ricavi | Costi | Utile netto del mese | Utile cumulato |
|---|---|---|---|---|---|---|---|
| 6 | 300 | 60 | 4 | 5 | 18 | -12 | -87 |
| 12 | 800 | 160 | 12 | 14 | 18 | -4 | -130 |
| 24 | 2.000 | 400 | 22 | 25 | 18 | +8 | -93 |
| 36 | 3.000 | 600 | 23 | 27 | 18 | +10 | +11 |

Ricavi annui: 80 € / 246 € / 314 €. **Con un commercialista l'app non andrebbe mai in pari.** In questo scenario non conviene aprire la partita IVA. Resta però il problema di come incassare legalmente (sezione 7).

**Realistico**

| Mese | Installazioni | Utenti attivi | Paganti | Ricavi abbonamenti | Altri ricavi | Ricavi totali | Costi | Imposte | Utile netto | Utile cumulato |
|---|---|---|---|---|---|---|---|---|---|---|
| 6 | 1.500 | 375 | 38 | 54 | 4 | 58 | 230 | 11 | -183 | -1.217 |
| 12 | 5.000 | 1.250 | 125 | 181 | 12 | 194 | 230 | 36 | -73 | -1.930 |
| 18 | 10.000 | 2.500 | 228 | 330 | 25 | 355 | 230 | 66 | +59 | -1.906 |
| 24 | 15.000 | 3.750 | 300 | 435 | 38 | 473 | 230 | 88 | +154 | -1.220 |
| 30 | 22.500 | 5.625 | 410 | 594 | 56 | 650 | 230 | 121 | +299 | +212 |
| 36 | 30.000 | 7.500 | 515 | 747 | 75 | 822 | 230 | 153 | +439 | +2.495 |

Ricavi annui: 1.027 € / 4.270 € / 7.962 €. Utile netto annuo: -1.931 € / +709 € / +3.716 €.

**Ottimista**

| Mese | Installazioni | Utenti attivi | Paganti | Ricavi abbonamenti | Affiliazioni + B2B | Ricavi totali | Costi | Imposte | Utile netto | Utile cumulato |
|---|---|---|---|---|---|---|---|---|---|---|
| 6 | 5.000 | 1.250 | 200 | 348 | 25 | 373 | 430 | 69 | -127 | -1.520 |
| 12 | 20.000 | 5.000 | 800 | 1.393 | 100 | 1.493 | 430 | 278 | +785 | +910 |
| 18 | 45.000 | 11.250 | 1.700 | 2.960 | 303 | 3.263 | 430 | 607 | +2.226 | +10.503 |
| 24 | 70.000 | 17.500 | 2.400 | 4.179 | 896 | 5.075 | 430 | 944 | +3.700 | +29.019 |
| 36 | 150.000 | 37.500 | 4.520 | 7.870 | 1.920 | 9.790 | 430 | 1.821 | +7.539 | +99.560 |

Ricavi annui: 7.464 € / 40.878 € / 93.006 €. **Nel terzo anno si supera la soglia del forfettario (85.000 €)**: dall'anno dopo si passa al regime ordinario o a una società.

**Calcolo d'esempio** (scenario realistico, mese 24):
- 15.000 installazioni × 2,5% = 375 paganti acquisiti in totale.
- Paganti attivi: 250 acquisiti negli ultimi 12 mesi + 40% dei 125 dell'anno precedente = 300.
- Ricavi abbonamenti: 300 × 17,41 € / 12 = **435 €/mese**.
- Altri ricavi: 3.750 utenti attivi × 0,01 € = 38 €.
- Utile: 473 − 230 − 88 (imposte e contributi) = **+154 €/mese**.

### 5.4 Le date: quando si guadagna

| Traguardo | Pessimista | Realistico | Ottimista |
|---|---|---|---|
| Utile mensile positivo (si coprono le spese vive) | mese 16, ma solo senza partita IVA; con il commercialista mai | **mese 16 → circa ago 2028** | mese 7 → circa nov 2027 |
| Recuperato tutto ciò che si è speso | circa mese 36 (cifre di pochi euro) | **mese 30 → circa ott 2029** | mese 12 → circa apr 2028 |
| **Almeno 1.000 € netti al mese** | mai | **non entro 36 mesi** (al ritmo del +30-40% annuo, circa 2030-2031) | **mese 13 → circa mag 2028** |
| Utile cumulato a 36 mesi | circa +10 € | circa +2.500 € | circa +100.000 € |

Prima del lancio vanno aggiunti circa 150-300 € di costi (account Apple e Google, dominio, documenti legali), più il tempo di sviluppo.

### 5.5 Il tempo del fondatore

**[STIMA]** Supponiamo 8-10 ore a settimana per 3 anni, cioè circa 1.400 ore.
- Realistico: 2.500 € / 1.400 ore ≈ **1,8 € l'ora**.
- Ottimista: circa **70 € l'ora**.
- Pessimista: circa 0.

Se l'obiettivo è il **guadagno economico**, il progetto va trattato come un'opzione con pochi soldi a rischio e un esito molto sbilanciato: perdite contenute, piccola probabilità di un risultato buono. Non è un reddito su cui contare.

---

## 6. Cosa accorcia i tempi e cosa li allunga

### Cosa accorcia i tempi
1. **Lanciare presto un prodotto minimo** fatto di tracker pipì, promemoria e cartella sanitaria base. Ogni mese di ritardo sposta tutte le date di un mese.
2. **Paywall nel posto giusto.** Il tracker predittivo con una prova di 7-14 giorni, poi a pagamento; la cartella sanitaria resta gratuita. Le prove di 17-32 giorni convertono al 42-46%, quelle di 4 giorni o meno al 25-27% [15][16].
3. **Spingere il piano annuale e l'opzione a vita.** Si incassa subito e la retention è molto più alta di quella mensile (44% contro 17% [16]).
4. **Internazionalizzare presto** (inglese, spagnolo, tedesco, francese). Il mercato passa da 9 milioni a 69-91 milioni di cani [1][2] a costo quasi zero, grazie alla traduzione con l'AI. È la leva più forte per passare dallo scenario realistico all'ottimista.
5. **Canali gratuiti con molti potenziali utenti:**
   - veterinari, che ricevono un PDF con il marchio della clinica da dare ai clienti;
   - canili e associazioni (ogni adozione è un nuovo utente);
   - gruppi Facebook e Reddit di proprietari di cani in città, contenuti TikTok o Instagram sul problema della pipì in appartamento;
   - ottimizzazione della scheda sugli store per parole chiave come "pipì cane", "libretto vaccini", "promemoria antiparassitario".
6. **Il "cane di famiglia" condiviso** tra più persone: un invito porta un nuovo utente senza costi di acquisizione.
7. **Costi fissi quasi a zero:**
   - notifiche locali invece che dal server;
   - Supabase gratuito o Pro, niente server propri;
   - niente commercialista finché non è chiaro il regime fiscale.

### Cosa li allunga
1. **Pubblicità a pagamento prima di aver dimostrato la retention.** Ogni installazione costa più di quanto rende (sezione 4.2).
2. **Freemium troppo generoso**, cioè tutto gratis: si resta sul 2% di conversione o meno.
3. **Fare tutto subito:** marketplace di sitter, vendita di dati, B2B, nutrizione avanzata. Così non si lancia.
4. **Funzioni "mediche" che diventano consulenza veterinaria.** Rischio di responsabilità e di rifiuto dagli store. Servono avvertenze del tipo "non sostituisce il veterinario".
5. **Solo Italia e solo iOS.** Su Android la conversione è circa la metà [16], ma la quota di utenti Android in Italia è alta. Serve il multipiattaforma, ma con un prezzo pensato per ciascuno store.
6. **Sottovalutare i pagamenti falliti su Google Play:** sono il 31% delle cancellazioni, contro il 14% su iOS [17]. Va attivato il periodo di tolleranza (grace period).
7. **Bloccarsi sul regime fiscale o sul CNR dopo il lancio**, invece di chiarirlo prima.

---

## 7. Fisco e inquadramento in Italia (panoramica generale, non è consulenza personalizzata)

1. **Lavoro al CNR [FATTO normativo, applicazione al caso da verificare].**
   - L'art. 53 del d.lgs. 165/2001 vieta ai dipendenti pubblici a tempo pieno le attività commerciali e professionali non autorizzate.
   - Il comma 6 esclude dall'autorizzazione l'"utilizzazione economica da parte dell'autore o inventore di opere dell'ingegno" [22].
   - Non è chiaro se vendere abbonamenti in modo continuativo tramite gli store rientri in questa esclusione o sia un'attività d'impresa.
   - Va chiarito anche se il CNR può rivendicare diritti su un software sviluppato da un dipendente: regolamento sulla proprietà intellettuale dell'ente, uso o meno di risorse e orario di lavoro.
   - **Da fare:** sentire l'ufficio del personale del CNR e un commercialista **prima di incassare**.
   - Strade possibili da valutare con loro: autorizzazione dell'ente; cessione in licenza dei diritti d'autore a un soggetto terzo; società in cui Lorenzo è solo socio di capitale.
2. **Regime forfettario [FATTO].**
   - Soglia di ricavi: 85.000 €/anno. Sopra 100.000 € si esce subito.
   - Chi ha redditi da lavoro dipendente sopra i **35.000 €** nell'anno precedente è escluso. La soglia è confermata per il 2026 dalla Legge di Bilancio 2026; dal 2027 tornerebbe a 30.000 € salvo proroga [23].
   - **Per un ricercatore con reddito sopra la soglia, il forfettario potrebbe non essere possibile**: si applicherebbe il regime ordinario, con IRPEF all'aliquota marginale, probabilmente 35-43%, più l'IVA.
3. **Se il forfettario è possibile [FATTO e STIMA]:**
   - coefficiente di redditività per l'ATECO 62.xx (software) pari a circa il **67%** (da verificare nell'allegato 4 della L. 190/2014) [24];
   - imposta sostitutiva al 15%, oppure al **5% per i primi 5 anni** se l'attività è nuova e ha i requisiti;
   - contributi INPS in gestione separata al 24% per chi ha già un'altra copertura previdenziale obbligatoria, altrimenti circa il 26%.
   - **Peso totale stimato: circa il 19-24% dei ricavi.**
4. **Fatturazione agli store [STIMA, da verificare con il commercialista].**
   - I ricavi arrivano da Apple e Google, che sono soggetti esteri dell'UE (Irlanda).
   - Di norma si emette fattura verso lo store con le regole per i servizi intra-UE.
   - Servono probabilmente l'iscrizione al VIES e la gestione dei documenti di pagamento mensili.
5. **Assicurazioni:** proporre polizze può richiedere l'iscrizione al RUI dell'IVASS. Vedi sezione 3.

---

## 8. Raccomandazione del business analyst

1. **Prima del lancio:** chiarire la posizione con il CNR e il regime fiscale. Lanciare con un **prezzo in euro, Premium a 24,99 €/anno, 3,99 €/mese o 49 € a vita**, e una prova di 14 giorni sul tracker predittivo.
2. **Mesi 0-6:**
   - zero pubblicità a pagamento;
   - misurare la retention a 30 giorni (obiettivo: almeno il 25% degli utenti ancora attivi) e la conversione (obiettivo: almeno il 2,5%).
3. **Mese 6, primo bivio:**
   - se la conversione è sotto l'1,5% e la retention a 30 giorni sotto il 15%, siamo nello **scenario pessimista**: tenere Zampa come progetto personale o open source, a costo quasi zero;
   - se si è sopra, tradurre in inglese, spagnolo e tedesco.
4. **Mese 12-18, secondo bivio:**
   - con più di 300 paganti, pilota B2B con 3-5 cliniche;
   - affiliazione assicurativa solo tramite un partner regolamentato.
5. **Cosa non fare:** vendita di dati, marketplace di sitter, pubblicità a pagamento senza prova che rende.

---

## Fonti

1. FEDIAF, *Facts & Figures 2026* (dati 2024): https://www.zzf.de/fileadmin/ZZF/Dokumente/Heimtiermarkt/FEDIAF_Facts_Figures_2026.pdf, statistiche: https://europeanpetfood.org/about/statistics/
2. Le Grand Continent, cani e gatti nell'UE (dati FEDIAF 2024): https://legrandcontinent.eu/fr/2025/07/12/dans-lunion-il-y-a-six-fois-plus-de-chats-et-de-chiens-domestiques-que-denfants-en-bas-age-cartographie-inedite-dune-nouvelle-tendance/
3. QuiFinanza, Rapporto Assalco-Zoomark 2026: https://quifinanza.it/lifestyle/pet-economy/animali-domestici-spesa-italia-2025/996227/
4. Zoomark, rassegna Rapporto Assalco-Zoomark 2025: https://www.zoomark.it/media/zoomark/diconodinoi/2025/2507_-_GreenLine_luglio.pdf
5. QuiFinanza, assicurazioni per cani e gatti: https://quifinanza.it/lifestyle/pet-economy/assicurazioni-per-animali-costi/929168/ e https://quifinanza.it/lifestyle/pet-economy/assicurazione-cani-gatti-bilancio-familiare/962878/
6. Segugio.it, osservatorio polizze pet: https://assicurazioni.segugio.it/news-assicurazioni/in-estate-cresce-l-attenzione-alla-responsabilita-civile-nelle-polizze-per-cani-e-gatti-00047575.html
7. Il Sole 24 Ore Lab24, pet economy (strutture e veterinari): https://lab24.ilsole24ore.com/italia-paese-per-cani-pet-economy-inverno-demografico/
8. Stime sul mercato delle app pet (bassa affidabilità): https://www.marketresearch.com/VPA-Research-v4245/Pet-Care-Apps-Size-Share-40857803 ; https://datahorizzonresearch.com/pet-care-apps-market-51480
9. Concorrenti in Italia: MyVet https://mwm.ai/it/apps/myvet/6463804287 ; Joppys https://apps.apple.com/it/app/joppys/id1543777185 ; 11pets su TechPrincess https://techprincess.it/?p=38976
10. 11pets su App Store Italia: https://apps.apple.com/it/app/11pets-pet-care/id1232470530
11. Prezzi delle app per la salute del pet: https://appshunter.io/ios/app/pawprint-vault/id6759038805 ; https://apps.apple.com/app/id6782466968 ; https://marlvel.ai/apps/pawproof-pet-vaccine-tracker
12. Piani Tractive Italia: https://tractive.com/it/c/plans
13. Prezzi Kippy: https://kippy.eu/pages/pricing
14. PetDesk: https://petdesk.com/blog/petdesk-announces-petdesk-starter-a-veterinary-client-engagement-starter-pack-starting-at-99-mo ; https://www.costbench.com/software/veterinary-software/petdesk/ ; Vetstoria: https://www.saasworthy.com/product/vetstoria/pricing
15. RevenueCat, *State of Subscription Apps 2026*: https://www.revenuecat.com/state-of-subscription-apps-2026/ ; https://www.revenuecat.com/sosa-26-insights
16. RevenueCat, *State of Subscription Apps 2025*: https://www.revenuecat.com/state-of-subscription-apps-2025/ ; Athletech News (Salute e Fitness): https://athletechnews.com/fitness-apps-monetizable-winner-take-all-or-most/
17. RevenueCat blog, benchmark 2026: https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026.md
18. Small Business Program Apple e Google: https://www.revenuecat.com/blog/engineering/small-business-program.md ; https://appbot.co/blog/app-developers-apple-google-small-business-programs/ ; https://splitmetrics.com/blog/google-play-apple-app-store-fees/
19. Programma di affiliazione Zooplus Italia (Awin): https://ui.awin.com/merchant-profile/9500
20. Prezzi Supabase: https://supabase.com/docs/pricing ; https://toolradar.com/tools/supabase/pricing
21. Costo per installazione in Italia (Meta, aggregatore): https://www.superads.ai/facebook-ads-costs/cost-per-app-install/wellness-holistic-health/italy ; https://mapendo.co/blog/cost-per-install-2025-the-ultimate-report-to-grow-your-app-worldwide
22. Art. 53 d.lgs. 165/2001: https://www.uniroma1.it/sites/default/files/allegati/art53DLgsn165-01.pdf ; partita IVA del dipendente pubblico (CNDCEC): https://www.fiscoetasse.com/rassegna-stampa/33345-commercialista-dipendente-pubblico-chiarimenti-su-professione-e-piva.html
23. Forfettario 2026, soglia di 35.000 € per i redditi da lavoro dipendente: https://www.fisco7.it/2026/01/legge-di-bilancio-forfettari-le-novita-del-2026/ ; https://www.informazionefiscale.it/Regime-forfettario-2026-limite-redditi-dipendenti-pensionati
24. Coefficienti di redditività del forfettario: https://quickfisco.it/blog/regime-forfettario/regime-forfettario-e-coefficiente-di-redditivita/

**Limiti di questa analisi:**
- Non ho trovato un dato nazionale affidabile sulla quota di proprietari che usano un'app pet, né il totale ufficiale SINAC dei cani iscritti all'anagrafe nel 2025.
- I benchmark RevenueCat sono globali, non specifici per l'Italia o per le app pet.
- Le installazioni degli scenari sono ipotesi calibrate sui benchmark di RevenueCat, non previsioni.
