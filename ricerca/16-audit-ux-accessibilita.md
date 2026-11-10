# Zampa: audit di UX e accessibilità (C1-9)

**Autore:** Designer UX e accessibilità · **Data:** 10 novembre 2026 · **Tipo:** solo analisi, nessuna modifica al codice
**Riferimenti:** `ricerca/08-piano-ceo.md` (§3.9 KPI, C1-9), `ricerca/07-seconda-revisione-veterinaria.md` (sezione F, compagno)

---

## 0. Sintesi

Registrare una pipì è già facile: **un tocco** dalla Home, con «Annulla». Il problema è quello che succede **prima** e **intorno** a quel tocco:

- il primo avvio chiede di leggere un'avvertenza piena di emergenze, poi propone un modulo di **22 controlli** su tre schermate;
- sul telefono il permesso per le notifiche viene chiesto **prima ancora** dell'avvertenza, senza spiegare a cosa serve;
- dal primo giorno l'utente vede tutto: statistiche del modello, 10 diari clinici, 28 tipi di evento, 5 schede «Da sapere» con citazioni;
- l'accessibilità non è stata progettata: in `lib/` **non c'è nessun `Semantics`** (il piano ne contava uno, oggi sono zero). Il compagno, l'indicatore «Bisogno» e i grafici sono muti per i lettori di schermo;
- nel **tema scuro**:
  - la scheda «Dosi da confermare» è praticamente illeggibile (contrasto circa 1,1:1);
  - la gerarchia visiva degli allarmi si inverte: ATTENZIONE è l'elemento più luminoso, OGGI il più scuro;
- l'interfaccia non è pronta per altre lingue: circa 2.400 testi italiani scritti direttamente nel codice, frasi composte con l'accordo grammaticale fisso, numeri e date in formato italiano.

**Le 5 modifiche a maggior impatto sui KPI** (dettagli al §6):

1. correggere il contrasto e la gerarchia degli allarmi, indipendente dal tema (S-M);
2. primo avvio in meno di 60 secondi con tre domande e la «prima pipì» già nel percorso; permesso delle notifiche chiesto dopo, con una spiegazione (M);
3. azioni rapide dalla notifica e canali separati per allarmi e promemoria (M);
4. rivelazione progressiva: modalità «Giorno 1» e moduli clinici mostrati solo quando servono (M);
5. accessibilità di base: etichette, ruoli, valori, riduzione del movimento e testo al 200% (M).

---

## 1. Metodo

- **Build web** di `build/web` servita in locale e aperta nel browser integrato:
  - viewport 375×812 (in parte 467 px, perché il pannello è condiviso), sistema in **tema scuro**;
  - albero di accessibilità di Flutter attivato con «Enable accessibility»;
  - testo al 200% ottenuto con la dimensione del carattere radice a 32 px;
  - misure dei bersagli prese dal DOM semantico.
- **Lettura del codice:** `lib/main.dart`, `lib/notifications.dart`, `lib/store.dart` e tutti i file in `lib/ui/`.
- **Percorsi svolti:**
  - Giulia: cane vero «Olivia», dall'avvertenza alla prima pipì;
  - cane di esempio «Luna»: Home, Bisogni, Salute, Diari, Cuore e respiro, Profilo;
  - Sara: cucciolo «Briciola», nato l'1/9/2026;
  - Franco: percorso ricostruito su Luna (dosi, diari) e sul codice per la cardiopatia.
- **Limiti:**
  - nessun telefono vero, nessuna prova con VoiceOver o TalkBack;
  - i contrasti del tema scuro sono stimati dalla tavolozza tonale di Material 3 generata dal colore seme `#2E7D6B`;
  - sul web Flutter usa bersagli «compatti» (desktop): su iOS e Android i pulsanti Material hanno un'area di tocco di 48 dp anche quando il disegno è più piccolo. Lo segnalo caso per caso.
- **Nota operativa:**
  - all'inizio ho svuotato il `localStorage` dell'origine `127.0.0.1:9123` (dati di prova del browser condiviso) prima di accorgermi che altri agenti usavano lo stesso pannello;
  - per il resto ho lavorato su un server mio (porta 9127), poi fermato.

---

## 2. Percorsi dei tre personaggi

### 2.1 Giulia, 34 anni, primo cane adulto, appartamento a Milano

| # | Passo | Note |
|---|---|---|
| 0 | *(solo telefono)* Finestra di sistema delle notifiche **all'avvio**, prima di qualsiasi spiegazione | `main.dart:19` chiama `Notifier.init()`, che su iOS (`requestAlertPermission: true`) e Android 13+ (`requestNotificationsPermission`) chiede il permesso subito |
| 1 | Legge «Prima di iniziare»: circa 120 parole, tra cui «gengive pallide o blu, addome gonfio con conati a vuoto, collasso, convulsioni, sospetto avvelenamento…» | Testo corretto ma ansiogeno come prima cosa letta |
| 2 | Spunta «Ho letto e ho capito» | |
| 3 | «Continua» | |
| 4 | «Aggiungi il tuo cane» | |
| 5 | Nome (tocco e testo) | |
| 6 | Peso (tocco e testo) | Nessuna indicazione dei campi mancanti: l'errore compare solo come messaggio temporaneo in basso («Servono almeno nome e peso») |
| 7-8 | Due scorrimenti per raggiungere «Salva» | Il modulo ha 22 controlli: nome, razza, nascita, peso, sesso, sterilizzazione, taglia, attività, alimentazione, sveglia, sonno, prudenza, 2 promemoria, anticipo, meteo, microchip, veterinario, telefono, pronto soccorso, regione, allergie, patologie |
| 9 | «Salva» | |
| 10 | «Fatta fuori» nella scheda «Prossima pipì» | **Primo evento registrato.** Compare «Pipì registrata alle 22:31 · Annulla» |

- **Totale:** 10 azioni sul telefono (9 sul web) più 2 scorrimenti. Tempo stimato: 60-90 s se salta tutto il facoltativo, 3-5 minuti se compila il modulo (cosa probabile, perché nulla dice che è facoltativo).
- **Cosa vede dopo la prima pipì:** «Esci alle 07:05 · Finestra probabile 07:01–07:10 · probabilità nella prossima ora 0%», con il chip «Sto imparando». È un orario preciso al minuto **ricavato da un solo dato** (P8).
- **Cose che Giulia non dovrebbe vedere il primo giorno:**
  - «Prudenza delle uscite»;
  - «Avvisami prima di»;
  - microchip;
  - «Dove vive» (zanzare e pappataci);
  - le statistiche del modello in «Bisogni» («Errore tipico sulle ultime 20 ± 14 min», «Tetto massimo per età», «Valore di partenza (letteratura)»);
  - i diari Diabete, Epilessia, «Calori e riproduzione», Qualità della vita (scala HHHHHMM);
  - i 28 chip di «Con dettagli…».

### 2.2 Franco, 68 anni, cane anziano cardiopatico

| # | Passo | Note |
|---|---|---|
| 0-4 | Come Giulia | Testo piccolo, probabilmente con caratteri di sistema grandi (vedi P12) |
| 5 | Data di nascita (12 anni fa) | Calendario: tocco sulla riga, sul mese e anno, sull'anno nella griglia, frecce, giorno, OK, cioè **6-7 tocchi**. Il calendario propone anche anni **futuri, fino al 2031** (`common.dart:230`) |
| 6-7 | Nome e peso | |
| 8 | Scorre fino a «Patologie note» e scrive «cardiopatia» | Testo libero: il riconoscimento della cardiopatia dipende dalle parole chiave `cardi|mitral|valvol|soffio|mvd` (`modules.dart:37`). Funziona, ma l'utente non sa se è stato capito |
| 9 | Veterinario e telefono (per l'emergenza) | |
| 10 | «Salva» | |
| 11 | Primo evento: «Fatta fuori» | **11-13 azioni**, più 3 o 4 scorrimenti |
| — | Misurare i respiri nel sonno (l'azione quotidiana più importante per lui) | Salute, poi Diari, poi «Cuore e respiro»: **3 tocchi**, mai proposti in Home. Il diario è evidenziato **solo con una tinta di sfondo** (`diaries_screen.dart:35`) |
| — | Confermare la dose del diuretico | In tema scuro il testo della dose è quasi invisibile (P1); al 200% il nome del farmaco si spezza a metà parola (P12) |

- **Cose che Franco non dovrebbe vedere:**
  - l'indicatore «Uscite 1/4», che chiede di «riempire» le uscite a un cane cardiopatico (07 N42);
  - i diari Diabete, Epilessia e Riproduzione.

### 2.3 Sara, cucciolo di 10 settimane

| # | Passo | Note |
|---|---|---|
| 0-4 | Come Giulia | |
| 5 | Data di nascita (1/9/2026): **7 tocchi** nel calendario | Se la salta, la data predefinita è «2 anni fa» (`dog_form.dart:30`) e il cucciolo viene trattato **da adulto senza alcun avviso**: niente uscite da cucciolo, soglie diverse |
| 6 | «Taglia adulta prevista» (per i cuccioli serve, ma è un menu con «Non so / già adulto» preselezionato) | Il testo d'aiuto è troncato: «Per i cuccioli: decide fino a quando cresce e il tipo di…» |
| 7-9 | Nome, peso, «Salva» (con scorrimenti) | |
| 10 | «Fatta fuori» | **10-12 azioni** |

- **Home del cucciolo:**
  - «Uscite 0/14» e «Pasti 0/5»: una frazione da 14 il primo giorno è un compito, non un'informazione;
  - 5 schede «Da sapere» lunghe: socializzazione (AVSAB 2008), educazione, veleni per lumache e topi, leptospirosi «trasmissibile all'uomo», zecche;
  - «Nessuna scadenza – Crea il piano di prevenzione nella sezione Salute», proprio quando i vaccini del cucciolo sono la cosa più urgente.
- **Rischio di falso allarme:** se Sara non registra una pipì per 6 ore (è al lavoro), parte la notifica rossa «🔴 Briciola: nessuna pipì da 6 ore? … è un'urgenza» (`store.dart:526-550`). Vedi P3.

### 2.4 Tocchi per registrare una pipì

| Situazione | Tocchi | Note |
|---|---|---|
| Fuori, dalla Home | **1** | Più «Annulla» nel messaggio in basso. Ottimo |
| In casa, dalla Home | **1** | |
| Con un dettaglio (sangue, sforzo) | 3-4 | «Con dettagli…» (si apre già su Pipì), poi chip, poi scorrimento, poi «Salva» |
| Dalla notifica | **impossibile** | Nessuna azione nella notifica, e il tocco non porta alla scheda giusta (P10). Servono almeno: apri, sblocca, «Fatta fuori» |
| Retrodatata («l'ha fatta 20 minuti fa») | 4-6 | «Con dettagli…», «Quando», data, ora, OK, «Salva» |

---

## 3. Problemi, in ordine di impatto sui KPI

Legenda della gravità:

- **Critica:** rischio per la sicurezza o blocco;
- **Alta:** colpisce attivazione, retention o fiducia negli allarmi;
- **Media:** attrito o esclusione di una parte degli utenti;
- **Bassa:** rifinitura.

Difficoltà della correzione: S (meno di 1 giorno), M (2-5 giorni), L (più di 1 settimana).

### P1 · Critica · Home, «Dosi da confermare»: testo illeggibile in tema scuro

- **Evidenza:**
  - `home_screen.dart:129-131` dà alla scheda lo sfondo fisso `Color(0xFFFFE9C7)` (crema) quando la dose è in ritardo di 2 ore, ma lascia il colore del testo del tema;
  - in tema scuro il testo è quasi bianco: **contrasto stimato circa 1,1:1** (WCAG chiede 4,5:1);
  - anche «Saltato», un TextButton verde acqua, è intorno a 1,4:1;
  - schermata di Luna in tema scuro: «Antinfiammatorio · 1/2 compressa / prevista oggi 19:33» si legge a fatica.
- **KPI:** sicurezza clinica, aderenza alle terapie (Franco).
- **Proposta:**
  - usare le coppie del tema (`tertiaryContainer` e `onTertiaryContainer`) oppure fissare anche il colore del testo;
  - aggiungere l'etichetta testuale «IN RITARDO» e un'icona, così il ritardo non è affidato al solo colore;
  - controllo automatico del contrasto in un test dei widget (`meetsGuideline(textContrastGuideline)`) per i due temi. **S**

### P2 · Alta · Livelli di allarme: in tema scuro la gerarchia si inverte e le differenze sono quasi solo di colore

- **Evidenza** (`common.dart:63-162`):
  - SUBITO usa `colorScheme.error`, che nel tema scuro è un **rosa chiaro** (tono 80);
  - OGGI usa `errorContainer`, che nel tema scuro è **rosso scuro** (tono 30);
  - ATTENZIONE usa il crema fisso `#FFE9C7`, che nel tema scuro è **l'elemento più luminoso dello schermo**;
  - INFO usa `secondaryContainer`, **senza etichetta**;
  - l'unica differenza testuale è una parola di 11 px (SUBITO, OGGI, ATTENZIONE). Le icone sono diverse ma piccole e dello stesso colore del testo;
  - altrove il livello è **solo colore**:
    - respiri >30 e >40 nella lista delle misure, con la sola icona arancione o rossa (`diaries_screen.dart:236-243`);
    - diario pertinente evidenziato con la sola tinta (`diaries_screen.dart:35`);
    - previsione «urgente» (≤15 min), con il solo passaggio da `primaryContainer` a `tertiaryContainer` (`home_screen.dart:350-356`).
- **KPI:** utilità degli allarmi, sicurezza clinica.
- **Proposta:** una gerarchia con 4 segnali ridondanti (§5.4):
  - posizione;
  - forma (bordo spesso, banda piena);
  - parola grande;
  - colore costante in entrambi i temi (colori «semantici» propri, non derivati dal colore seme);
  - più il valore scritto (es. «42 respiri/min · sopra 40: chiama il veterinario oggi»). **M**

### P3 · Alta · Notifica rossa «nessuna pipì da N ore» quando l'utente ha solo dimenticato di registrare

- **Evidenza:**
  - `store.dart:526-550` programma, a partire dall'**ultima pipì registrata**, una notifica «🔴 {nome}: nessuna pipì da 24 ore? Se non ha davvero urinato è un'urgenza»;
  - il ritardo è di 6 ore per i cuccioli sotto i 4 mesi, 8 ore sotto i 6 mesi, 12 ore nel maschio con sforzo;
  - la mancata registrazione non è una mancata pipì: chi registra a metà (la maggior parte, nelle prime settimane) riceverà avvisi rossi frequenti;
  - Sara li riceverà quasi ogni giorno lavorativo.
- **KPI:** utilità degli allarmi (soglia «troppi falsi allarmi» sotto il 50%), retention a 7 e 30 giorni, ansia.
- **Proposta (UX; la soglia clinica resta del veterinario, 07 N13):**
  - primo passo come **domanda neutra**, non rossa: «Hai segnato tutte le pipì di Briciola da stamattina?», con le azioni «Sì, nessuna da 6 h», «L'ha fatta (segna ora)» e «L'ha fatta prima…»;
  - si sale a 🔴 SUBITO **solo** se l'utente conferma «nessuna pipì», oppure se c'erano segni di sforzo o gocce;
  - registrare quante volte la risposta è «l'ha fatta», per misurare i falsi allarmi. **M**
- *Da far validare a C1-8 o al veterinario del Ciclo 2.*

### P4 · Alta · Primo avvio: modulo unico, valori predefiniti silenziosi, permesso chiesto a freddo

- **Evidenza:**
  - 22 controlli in un'unica pagina (`dog_form.dart:56-331`), con «Salva» fuori schermo;
  - errori solo come messaggio temporaneo, senza evidenziare il campo;
  - data di nascita predefinita «2 anni fa» (rischio clinico per Sara) e sesso predefinito «Maschio» (Olivia è diventata «maschio» senza che lo scegliessi);
  - il calendario accetta date future;
  - permesso delle notifiche chiesto in `main()` prima dei termini (`notifications.dart:39-58`).
- **KPI:** attivazione (≥ 3 eventi nelle prime 24 h), notifiche consentite (soglia ≥ 70%).
- **Proposta:** flusso in 3 schermate da meno di 60 secondi (§5.2):
  - età per fasce («cucciolo, adulto, anziano», poi la data solo se serve);
  - nessun sesso preselezionato;
  - permesso delle notifiche chiesto **dopo** la prima registrazione, con una schermata che spiega il beneficio;
  - tutto il resto si rimanda («Completa il profilo» in Profilo e al giorno 3). **M**

### P5 · Alta · Lettori di schermo: nessuna etichetta progettata

- **Evidenza:**
  - `grep -i semantic lib/` non trova nulla;
  - nell'albero di accessibilità della Home di Olivia:
    - il compagno in pixel art (`PixelDogView`, `GestureDetector` con tocco) **non ha nome né ruolo**;
    - il gruppo legge «Bisogno» **senza valore**, perché i 5 quadratini colorati non hanno testo (`avatar.dart:762-803`);
    - gli `ActionChip` «Pasto», «Acqua», «Con dettagli…» sono annunciati come **«casella di controllo»**;
    - il chip informativo «Sto imparando» / «Affidabilità alta» è annunciato come **casella di controllo**, cioè come un comando;
    - i titoli di sezione (`SectionTitle`) non sono intestazioni, quindi non si può navigare per titoli;
  - i grafici sono `CustomPaint` senza descrizione:
    - probabilità e ultimi 14 giorni (`potty_screen.dart:69,166`);
    - peso (`health_screen.dart:335`);
    - diari (`diaries_screen.dart:329,396,642,709`);
  - il contatore dei respiri cambia testo («12 / 23s») senza annunci né vibrazione: chi conta guardando il cane non riceve conferma del tocco.
- **KPI:** qualità (voto negli store), inclusione degli utenti anziani e ipovedenti (Franco).
- **Proposta:** pacchetto di accessibilità di base (§6, modifica 5). **M**

### P6 · Media-Alta · Il cane di esempio si mescola ai dati veri e invia notifiche vere

- **Evidenza:**
  - `store.loadDemo` aggiunge «Luna» (con antinfiammatorio, scadenze e un antiparassitario scaduto) come un cane normale;
  - nessun banner «Esempio», nessun «Esci dall'esempio» (`grep -i demo lib/ui` trova solo il pulsante);
  - `_reschedule()` programma le notifiche per **tutti** i cani: sul telefono partiranno promemoria di dosi e il 🔴 «nessuna pipì» per un cane che non esiste;
  - chi poi aggiunge il proprio cane si ritrova un secondo cane, e il pulsante per cambiare cane compare in Home.
- **KPI:** attivazione (la metrica «cane creato» viene falsata dal cane di esempio), fiducia.
- **Proposta:**
  - esempio in sola lettura, con banner fisso «Stai guardando un esempio · Crea il tuo cane»;
  - nessuna notifica dal cane di esempio;
  - cancellazione automatica dell'esempio quando si crea il primo cane vero. **S**

### P7 · Media · Troppo da vedere il primo giorno

- **Evidenza:**
  - Home del cucciolo: 3 indicatori, 2 schede di previsione, 6 chip, scadenze, 5 schede «Da sapere» (circa 4 schermate);
  - Bisogni: tabella «Come sta imparando» con 7 statistiche e un paragrafo tecnico, coperto in parte dal pulsante «Registra»;
  - Diari: 11 moduli per tutti, con sigle non spiegate (ACVIM, WSAVA, ESCCAP, HHHHHMM, «range del laboratorio»);
  - foglio «Con dettagli»: **28 chip** in 4 gruppi, dove «Collasso/svenimento» sta accanto a «Denti».
- **KPI:** attivazione, retention a 1 giorno.
- **Proposta:** rivelazione progressiva (§5.1). **M**

### P8 · Media · Falsa precisione nelle prime previsioni

- **Evidenza:** dopo **una** sola pipì la scheda mostra in grande «Esci alle 07:05», poi «Finestra probabile 07:01–07:10 · probabilità nella prossima ora 0%». «0%» si legge come «non la farà».
- **KPI:** accuratezza percepita, retention a 7 giorni (prime previsioni sbagliate, quindi abbandono).
- **Proposta:**
  - con confidenza bassa mostrare un **intervallo arrotondato al quarto d'ora** («verso le 7-7:30») e nascondere la percentuale;
  - mostrare la finestra precisa solo con confidenza media o alta;
  - non scrivere mai «0%»: usare «poco probabile». **S**

### P9 · Media · Regole del compagno (07 F) applicate solo in parte; nessuna riduzione del movimento

| Regola | Stato | Evidenza |
|---|---|---|
| N38: niente posa felice con ATTENZIONE | ✅ | Luna con dose mancata: posa ferma, icona «occhio», «C'è qualcosa da tenere d'occhio: leggi qui sotto.» |
| N39: niente gioia toccando un cane preoccupato; scheda rossa statica con SUBITO | ✅ | `avatar.dart:376-379`, `544-560` |
| N40: posa felice solo senza segni | ✅ | `avatar.dart:442-457` |
| N41: niente «ha fame» nei casi a rischio; testo «È l'ora del suo pasto abituale» | ✅ | `avatar.dart:466-520` |
| N42: indicatore «Bisogno» con etichetta onesta | ❌ | Si chiama ancora «Bisogno» invece di «Tempo dall'ultima pipì», e il valore non è leggibile (solo quadratini) |
| N42: «Uscite oggi: 5» come numero, non come obiettivo | ⚠️ | Mostrato come frazione «1/4», «0/14», che resta un obiettivo da riempire |
| N42: nascondere le uscite in caso di riposo | ⚠️ | L'espressione `riposo|ernia|frattura` **non contiene «gabbia»** (richiesta da N42) e non considera la cardiopatia (Franco) |
| N43: «È la sua ora di riposo» | ✅ | |
| Accordo grammaticale | ❌ | «Olivia sta tranquillo», «Luna è contento»: messaggi sempre al maschile (`avatar.dart:455,478`) |
| Riduzione del movimento | ❌ | `AnimationController(...)..repeat()` sempre attivo (`avatar.dart:353-356`); non legge `MediaQuery.disableAnimationsOf` |

- **Proposta:**
  - completare N42 (etichetta, numero senza obiettivo, «gabbia», nascondere le uscite con la cardiopatia: da confermare col veterinario);
  - messaggi accordati al sesso;
  - con «Riduci movimento» del sistema: posa ferma e nessuna animazione al tocco. **S**

### P10 · Media · Notifiche senza azioni e tutte su un unico canale

- **Evidenza** (`notifications.dart:61-71`):
  - un solo canale Android «Promemoria» per uscite, dosi, scadenze **e** allarmi 🔴 SUBITO;
  - se l'utente silenzia i promemoria delle uscite (succede spesso), perde anche gli allarmi;
  - nessuna `AndroidNotificationAction` né categoria iOS, quindi non si registra dalla notifica;
  - nessuna gestione del tocco: si apre la Home, non la scheda pertinente;
  - la notifica della dose dice «Apri Zampa e segna "Dato" o "Saltato"»: due passaggi che potrebbero essere un tocco solo.
- **KPI:** registrazioni (≥ 3 al giorno), aderenza alle dosi, notifiche consentite.
- **Proposta:** §5.3. **M**

### P11 · Media · Bersagli piccoli e ravvicinati dove l'errore costa

- **Evidenza** (misure dal DOM semantico, web):
  - chip di registrazione **34 px** di altezza con 6 px di spazio;
  - «Fatta fuori», «In casa», «Dato», «Saltato», «Tutte» e «Salva» del foglio: **32 px**;
  - «Saltato» è un pulsante di solo testo attaccato a «Dato»;
  - su iOS e Android Material allarga l'area di tocco a 48 dp, ma il disegno resta da 32-34 px e i bersagli si toccano;
  - sul web e sul desktop (dove la versione web è già in uso) l'area resta 32-34 px;
  - per Franco (presa incerta) toccare «Saltato» invece di «Dato», o «Collasso» invece di «Addome gonfio», è un errore con conseguenze.
- **Proposta:**
  - `materialTapTargetSize: padded` su tutte le piattaforme;
  - «Fatta fuori» e «In casa» alti 56 dp;
  - «Dato» e «Saltato» come due pulsanti separati da almeno 8 dp, con «Saltato» che chiede conferma;
  - chip dei sintomi gravi separati (§5.1). **S**

### P12 · Media · Testo al 200% e testi troncati

- **Evidenza:**
  - al 200% la riga della dose spezza le parole («Antinfiammat / orio / 1/2 / compressa») perché due pulsanti fissi le rubano spazio;
  - il chip «Affidabilità alta» occupa metà della riga e «Prossima pipì» va a capo;
  - le icone (14-18 px) non crescono con il testo, quindi gli indicatori del compagno diventano scritte senza simbolo;
  - **già al 100%** alcuni testi d'aiuto sono troncati con «…»:
    - «Per i cuccioli: decide fino a quando cresce e il tipo di…»;
    - «Pronto soccorso veterinario h24 di rifer…»;
    - «Es. diabete, Cushing, malattia renale, cistite: il model…».
- **Proposta:**
  - `helperMaxLines` ed etichette su più righe ovunque;
  - riga della dose che sopra i 130% passa a colonna (testo sopra, pulsanti sotto);
  - chip della confidenza sotto il titolo;
  - icone dimensionate con `MediaQuery.textScalerOf`;
  - prova automatica con `textScaler: TextScaler.linear(2.0)` su Home, foglio di registrazione, Emergenze e modulo. **M**

### P13 · Media (Alta se si va in Europa) · L'interfaccia non è pronta per altre lingue

- **Evidenza:**
  - nessun file di localizzazione (`lib/l10n` assente, nessun `intl` o `gen-l10n` in `pubspec.yaml`), circa 2.400 stringhe italiane nel codice;
  - `locale: const Locale('it')` fisso (`main.dart:74`);
  - frasi composte che **già in italiano** sbagliano l'accordo: `'${type.label} registrata'` produce «Pasto registrata», «Risveglio registrata», «Inizio passeggiata registrata» (`log_sheet.dart:33`); «è contento», «sterilizzato/a»;
  - numeri con il punto («12.0 kg», 24 usi di `toStringAsFixed`);
  - date `dd/mm/yyyy` e ore `hh:mm` scritte a mano (`store.dart:948-949`);
  - contenuti legati all'Italia:
    - URL di Google Maps «pronto+soccorso+veterinario» (`emergency_screen.dart:141`);
    - «In Italia diagnosi e prescrizione…»;
    - microchip «inizia con 380»;
    - regioni Nord, Centro, Sud;
    - ESCCAP Italia;
    - testo del colpo di calore.
- **Punti che si romperebbero con il tedesco** (testi dal 30 al 40% più lunghi, parole composte non sillabate):

| Punto | Perché si rompe |
|---|---|
| Barra in basso (5 voci da circa 75 px): «Nutrizione» → «Ernährung», «Bisogni» → «Geschäftchen»/«Gassi» | Etichette tagliate o ridotte; con 5 voci non c'è margine |
| Schede di Salute (`TabBar` fissa a 4): «Scadenze» → «Fälligkeiten», «Diari» → «Tagebücher» | `isScrollable` non è impostato, quindi le etichette vengono troncate |
| Riga del titolo di previsione: «Prossima pipì» con il chip «Affidabilità alta» → «Nächstes Pipi» con «Zuverlässigkeit hoch» | Già al limite in italiano al 200% |
| «Esci alle 07:05» in `displaySmall` → «Geh um 07:05 raus» | Va a capo nel numero grande |
| Indicatori del compagno (`_Count`/`_Meter`: `Row` con icona ed etichetta senza `Flexible`): «Uscite» → «Spaziergänge», «Pasti» → «Mahlzeiten» | Possibile banda di overflow gialla e nera su schermi da 360 dp |
| Riga della dose con «Dato»/«Saltato» → «Gegeben»/«Ausgelassen» | Il testo del farmaco si riduce a una lettera per riga (come al 200%) |
| Pulsante segmentato «Maschio/Femmina», «30 secondi/60 secondi» → «Rüde/Hündin», «30 Sekunden» | Taglio dentro il segmento |
| Etichette dei menu nel modulo («Pronto soccorso veterinario h24 di riferimento») | Già troncate in italiano |
| Etichetta dell'allarme fissa a 11 px con spaziatura 1,2 («ATTENZIONE» → «ACHTUNG», ma in francese «ATTENTION REQUISE») | Regge, ma va sostituita con un'icona più una parola grande (P2) |
| Frasi composte con concatenazioni e pronomi (`'${dog.name} è contento'`) | Impossibili da tradurre con il genere corretto: servono messaggi ICU con `{sex, select, …}` |
| Unità e formati: kg con il punto, °C, ml, mg/dL, 24 h, date | Servono `NumberFormat` e `DateFormat` della lingua; nel Regno Unito servono lb e °F, in Germania mmol/L |
| Contenuti clinici e numeri di emergenza per paese | Vanno spostati nel livello dei contenuti, non dell'interfaccia: soglie e numeri cambiano per paese |

- **Proposta:**
  - estrarre le stringhe con `gen-l10n` (ARB), con le regole di plurale e genere;
  - formattare con `intl`;
  - pseudo-localizzazione (+40% di lunghezza, accenti) e test d'oro a 360 dp;
  - schede di Salute scorrevoli;
  - barra in basso a 4 voci (§5.1). **L** (meccanica; la parte clinica è da rivedere per ogni paese)

### P14 · Bassa · Rifiniture con impatto sulla fiducia

- **Emergenze:**
  - la scheda «Aggiungi i numeri utili» **non è toccabile**: non porta al modulo, è un vicolo cieco proprio quando serve;
  - le 18 voci «Vai subito dal veterinario se…» sono tutte uguali (icona rossa), senza ricerca né raggruppamento;
  - il pulsante Emergenze in Home è un'icona «asterisco» rosa senza testo: il nome si vede solo come tooltip.
- **Avvertenza iniziale:** la prima cosa letta è un elenco di emergenze. Proposta: una frase («Zampa aiuta a osservare; non sostituisce il veterinario») e «In caso di emergenza: tasto rosso in alto, sempre», con l'elenco completo nella scheda Emergenze.
- **Profilo:** «Esporta tutti i dati (JSON)» e «Copia un backup… negli appunti» sono termini tecnici; «Elimina» e «Cancella tutti i dati» stanno subito sotto «Esporta» (con conferma: va bene).
- **Pulsante «Registra»** in Bisogni e Salute: copre l'ultima riga di testo e la scheda «Fatta fuori (14 giorni)».

---

## 4. Riepilogo per KPI

| KPI (08 §3.9) | Problemi | Effetto atteso della correzione |
|---|---|---|
| Attivazione (≥ 3 eventi nelle prime 24 h) | P4, P6, P7, P8 | Primo evento in meno di 60 s; secondo e terzo dalla notifica |
| Notifiche consentite (≥ 70%) | P4, P10 | Permesso chiesto con una spiegazione dopo il primo valore |
| Registrazioni (≥ 3 al giorno) | P10, P11 | Un tocco dalla notifica |
| Retention a 7 e 30 giorni | P3, P7, P8 | Meno ansia e falsi allarmi, prime previsioni oneste |
| Utilità degli allarmi (≥ 70%) | P2, P3, P10 | Gerarchia chiara, niente 🔴 per una dimenticanza |
| Sicurezza clinica | P1, P2, P9, P11 | Dosi leggibili, livelli non solo a colori, compagno coerente |
| Qualità e voto | P5, P12, P13 | Accessibilità di base, pronti per la localizzazione |

---

## 5. Proposte

### 5.1 Rivelazione progressiva: cosa nascondere e quando mostrarlo

Principio: **il primo giorno si fa una cosa sola, segnare pipì e cacca.** Le altre funzioni compaiono quando ci sono i dati o il bisogno. Ogni sezione nascosta resta raggiungibile da «Tutte le funzioni» in Profilo: nulla diventa irraggiungibile.

| Elemento | Giorno 1 | Quando compare |
|---|---|---|
| Tasto Emergenze | **Sempre**, con testo «SOS» e icona | — |
| Allarmi SUBITO e OGGI | **Sempre in cima** | — |
| Schede Pipì e Cacca con «Fatta fuori»/«In casa» | Sì | — |
| Previsione oraria precisa | No: «Sto imparando: segna le prossime 3 pipì» con una barra 1/3 | Dopo 3 pipì (fascia oraria); finestra precisa con confidenza media |
| Compagno | Sì, ma più piccolo, senza indicatori | Indicatori dal giorno 2; «Uscite» senza obiettivo |
| Chip rapidi | 3 (Passeggiata, Pasto, Altro…) | Gli altri dentro «Altro…» |
| «Con dettagli…» (28 chip) | Diviso: «Pipì/cacca con dettagli» e «Sintomo» (gravi in cima, separati, con l'avviso rosso) | — |
| «Da sapere» | 1 sola scheda (la più rilevante per età e stagione) | Una nuova al giorno; il resto in «Guide» |
| Scadenze e piano di prevenzione | Cucciolo: **sì dal giorno 1** («I vaccini di Briciola»). Adulto: no | Adulto: giorno 3, «Ricordiamo vaccini e antiparassitari?» |
| Scheda Nutrizione | No (5 voci in barra sono troppe) | Unita a Salute, oppure quando si registra il cibo; barra a 4: **Oggi · Bisogni · Salute · Profilo** |
| Bisogni › «Come sta imparando» (statistiche) | No | Dietro «Come calcola Zampa?» (chiuso) |
| Diari clinici | Solo quelli pertinenti (cardiopatia → Respiri; diabete → Insulina; anziano → Qualità della vita) | Gli altri in «Altri diari»; Respiri in **Home** se è cardiopatico |
| Modulo del cane: microchip, regione, prudenza, anticipo, meteo, allergie | No | «Completa il profilo (2 min)» al giorno 2-3, con il motivo di ogni campo |
| Statistiche numeriche (± min, %) | No | Solo in «Come calcola Zampa?» |

**Wireframe: Home il giorno 1 (adulto)**

```
┌───────────────────────────────────┐
│ O  Olivia · adulta        [ SOS ] │  ← Emergenze: testo + icona, 48dp
├───────────────────────────────────┤
│ (spazio riservato agli allarmi)   │  ← vuoto se non ce ne sono
├───────────────────────────────────┤
│   [compagno piccolo, fermo]       │
│   «Ciao! Segna le prossime pipì:  │
│    imparo il ritmo di Olivia.»    │
├───────────────────────────────────┤
│ 💧 Pipì     Sto imparando  ●○○    │  ← 1 su 3
│ ┌──────────────┐ ┌──────────────┐ │
│ │ ✓ FATTA FUORI│ │ ⌂  IN CASA   │ │  ← 56dp
│ └──────────────┘ └──────────────┘ │
│ 🌿 Cacca    Sto imparando  ○○○    │
│ [ ✓ FATTA FUORI ] [ ⌂ IN CASA ]   │
├───────────────────────────────────┤
│ [Passeggiata] [Pasto] [Altro…]    │
└───────────────────────────────────┘
  Oggi · Bisogni · Salute · Profilo
```

### 5.2 Primo avvio in meno di 60 secondi

Obiettivo: dal tocco sull'icona al primo evento in **meno di 60 s e 8 tocchi o meno**, senza scorrimenti.

```
[1] Benvenuto                      [2] Il tuo cane
┌───────────────────────────┐      ┌───────────────────────────┐
│ Zampa                     │      │ Come si chiama?           │
│ Impara quando deve uscire │      │ [ Olivia               ]  │
│ e ti ricorda la salute.   │      │ È…  (●) Femmina ( ) Maschio│  ← nessun predefinito
│ Non sostituisce il        │      │ Età:                      │
│ veterinario. In emergenza:│      │ [Cucciolo][Adulto][Anziano]│  ← un tocco
│ tasto SOS, sempre.        │      │  ↳ Cucciolo: «Quante      │
│ ☐ Ho capito (dettagli ›)  │      │    settimane?» [‹ 10 ›]   │  ← selettore numerico
│ [ Inizia ]                │      │ Peso circa: [ 12 ] kg     │
│ Provo con un esempio ›    │      │  (o «non so»: [Piccolo]   │
└───────────────────────────┘      │   [Medio][Grande])        │
                                   │ [ Avanti ]                │
                                   └───────────────────────────┘
[3] La prima pipì                  [4] (dopo il 1° evento)
┌───────────────────────────┐      ┌───────────────────────────┐
│ Quando ha fatto l'ultima  │      │ Ti avviso io quando è ora │
│ pipì?                     │      │ di uscire?                │
│ [Adesso][1 h fa][2-3 h fa]│      │ Esempio: «Olivia: esci tra│
│ [Non lo so]               │      │ 10 min»  [Fatta] [15']    │
│                           │      │ [ Sì, avvisami ] [ Dopo ] │  ← poi finestra di sistema
└───────────────────────────┘      └───────────────────────────┘
```

- **Tempi stimati:** [1] 10 s, [2] 25 s, [3] 5 s, cioè circa 40 s e 7 tocchi; il permesso viene dopo il primo valore.
- **Cucciolo:** le settimane danno la data di nascita senza calendario (Sara: da 7 tocchi a 1-2). Per l'anziano: «Quanti anni?» con un selettore numerico.
- **Patologie:** domanda facoltativa al giorno 2 con chip («Cuore», «Diabete», «Reni», «Epilessia», «Altro…») invece del testo libero, così il modulo pertinente si attiva in modo affidabile (Franco).
- **Esempio:** in sola lettura, con un banner (P6).

### 5.3 Azioni rapide dalla notifica

| Notifica | Azioni (Android `AndroidNotificationAction`, iOS `DarwinNotificationCategory`) | Senza aprire l'app? |
|---|---|---|
| «Olivia: esci tra 10 minuti» | **Fatta fuori** · **In casa** · **Tra 15'** | Sì: registra con l'ora del tocco e mostra la conferma «Pipì segnata alle 7:12 · Annulla» |
| «💊 Pimobendan per Fido, ore 8» | **Dato** · **Più tardi (30')** | «Saltato» solo aprendo l'app, con l'avviso «non raddoppiare» |
| Promemoria pipì mancata (P3) | **L'ha fatta (adesso)** · **L'ha fatta prima…** · **No, nessuna** | «No, nessuna» apre la scheda dell'allarme |
| 🔴 SUBITO (allarme) | **Chiama il veterinario** · **Apri** | Mai azioni che chiudono o «rimandano» un allarme SUBITO |

- **Canali separati** (Android) e livelli di interruzione (iOS):
  - «Allarmi salute», importanza massima, interruzione `timeSensitive`;
  - «Dosi»;
  - «Uscite» (importanza predefinita, silenziabile);
  - «Scadenze» (bassa).
- Chi silenzia le uscite non perde gli allarmi.
- **Tocco sul corpo della notifica:** apre direttamente la scheda pertinente.
- **Widget e azioni rapide sull'icona** (Ciclo 4): «Pipì fuori» e «Pipì in casa» dalla schermata Home del telefono.

### 5.4 Gerarchia degli allarmi separata dal compagno

Regole (rispettano 07 F e «SUBITO sempre sopra»):

1. **Zona allarmi** fissa sotto l'intestazione, prima del compagno, con lo stesso ordine sempre: SUBITO, poi OGGI, poi ATTENZIONE. INFO va in fondo alla pagina, mai in zona allarmi.
2. **Il compagno non usa mai i colori degli allarmi** (rosso, arancione, ambra) né le loro icone. Il suo fumetto rimanda alla zona allarmi («leggi qui sopra», «leggi qui sotto»), senza ripeterla.
3. **Quattro segnali ridondanti per livello:**

| Livello | Forma | Parola (≥ 16 sp, grassetto) | Icona | Colore (uguale in chiaro e scuro) | Azione |
|---|---|---|---|---|---|
| SUBITO | Banda piena a tutta larghezza, bordo 3 dp, **sostituisce il compagno** | «SUBITO dal veterinario» | ⛑ emergenza, 32 dp | Rosso pieno `#B3261E` con testo bianco (contrasto ≥ 6:1) | [Chiama veterinario] [Pronto soccorso] |
| OGGI | Scheda con bordo sinistro spesso 8 dp | «OGGI: chiama il veterinario» | 🏥, 28 dp | Arancione scuro, testo bianco | [Chiama] |
| ATTENZIONE | Scheda con bordo tratteggiato | «Da tenere d'occhio» | 👁, 24 dp | Ambra chiaro con testo marrone scuro, **anche in tema scuro** con bordo e testo calibrati | [Cosa osservare] |
| INFO | Riga semplice, nessun bordo | (nessuna parola di livello) | ⓘ | Neutro | — |

4. **Lettori di schermo:**
   - SUBITO viene annunciato all'arrivo (`SemanticsService.announce`, `liveRegion`) e ha il ruolo di intestazione;
   - l'etichetta letta è la frase completa: «Allarme livello subito: …».
5. **Movimento:**
   - con SUBITO e OGGI il compagno è sostituito o fermo;
   - nessuna animazione nella zona allarmi;
   - con «Riduci movimento» il compagno è sempre fermo.

```
┌───────────────────────────────────┐
│ F  Fido · anziano          [ SOS ]│
├═══════════════════════════════════┤
│▌⛑ SUBITO dal veterinario          │  ← banda rossa, statica
│▌ Respiri a riposo 46/min (> 40)   │
│▌ [ Chiama il veterinario ] [ PS ] │
├───────────────────────────────────┤
│ ┆👁 Da tenere d'occhio            │  ← ATTENZIONE, bordo tratteggiato
│ ┆ Dose delle 8 non confermata     │
├───────────────────────────────────┤
│ (compagno sostituito dalla banda) │
└───────────────────────────────────┘
```

### 5.5 Accessibilità: requisiti minimi (criteri di accettazione)

- **Etichette:**
  - `Semantics(label: 'Olivia, il tuo compagno. Sta tranquilla. Prossima uscita alle 22:31', button: true, onTapHint: 'Accarezza')` sul compagno, oppure `ExcludeSemantics` per il disegno, con il messaggio come testo;
  - per l'indicatore: «Tempo dall'ultima pipì: 2 ore su circa 4».
- **Ruoli:**
  - chip rapidi come pulsanti (`Semantics(button: true)` o `FilledButton.tonal`);
  - il chip della confidenza come testo;
  - `SectionTitle` con `header: true`.
- **Grafici:** riassunto testuale («Ultimi 14 giorni: da 3 a 5 pipì al giorno, media 4») ed eventuale tabella accessibile.
- **Contatore dei respiri:** vibrazione leggera a ogni tocco, annuncio a fine misura; schermo scuro in modalità notte, per non svegliare il cane.
- **Contrasti:** test automatici con `textContrastGuideline` e `androidTapTargetGuideline`/`iOSTapTargetGuideline` sulle schermate principali, in **entrambi i temi**.
- **Testo al 200%:** test d'oro a 360 dp con `TextScaler.linear(2.0)`, senza overflow.
- **Riduzione del movimento:** `MediaQuery.disableAnimationsOf(context)`, così il compagno resta fermo e l'animazione al tocco non parte.

---

## 6. Piano per il Ciclo 3

Ordinato per impatto sui KPI e poi per costo. La difficoltà è stimata per lo sviluppatore Flutter del progetto.

| # | Intervento | Problemi | Difficoltà | KPI | Criterio di fine |
|---|---|---|---|---|---|
| **1** | **Contrasto e gerarchia degli allarmi indipendenti dal tema**: colori semantici propri; correggere la scheda delle dosi; etichetta grande con icona; nessun livello affidato al solo colore (respiri, diari, previsione urgente) | P1, P2 | **S-M** | Sicurezza, utilità degli allarmi | Test di contrasto superati nei due temi; revisione del veterinario sulla scala dei livelli |
| **2** | **Primo avvio in meno di 60 s**: 3 schermate, età per fasce o settimane, nessun sesso predefinito, «prima pipì», permesso dopo il primo valore con spiegazione; «Completa il profilo» rimandato | P4, P8 | **M** | Attivazione, notifiche consentite | 5 utenti nuovi: mediana ≤ 60 s e ≤ 8 tocchi fino al primo evento |
| **3** | **Notifiche con azioni e canali separati** (uscite, dosi, allarmi, scadenze); tocco che apre la scheda giusta; promemoria pipì mancata a due passi (P3, con il veterinario) | P3, P10 | **M** | Registrazioni al giorno, utilità degli allarmi | Registrare una pipì dalla notifica con 1 tocco su iOS e Android; il silenzio delle uscite non tocca gli allarmi |
| **4** | **Rivelazione progressiva**: Home «Giorno 1», barra a 4 voci, statistiche e diari non pertinenti nascosti, foglio dei sintomi diviso, «Da sapere» 1 al giorno, vaccini del cucciolo dal giorno 1 | P7, P8 | **M** | Retention a 1 e 7 giorni | Home del giorno 1 entro 1,5 schermate a 375×812 |
| **5** | **Accessibilità di base**: etichette e ruoli, intestazioni, grafici descritti, contatore con vibrazione e annuncio, bersagli ≥ 48 dp ovunque, testo al 200% senza rotture, riduzione del movimento | P5, P9, P11, P12 | **M** | Qualità, inclusione | Percorso completo con VoiceOver e TalkBack (registra pipì, conferma dose, apri Emergenze) senza aiuto visivo |
| 6 | Cane di esempio in sola lettura, con banner e senza notifiche | P6 | S | Attivazione (metrica pulita) | L'esempio non compare tra i cani né nelle notifiche |
| 7 | Completare 07 N42 («Tempo dall'ultima pipì», uscite senza obiettivo, «gabbia», cardiopatia) e messaggi del compagno accordati al sesso | P9 | S | Sicurezza | Revisione del veterinario |
| 8 | Emergenze: «Aggiungi i numeri» toccabile, SOS con testo, voci raggruppate e cercabili; avvertenza iniziale in due livelli | P14 | S | Fiducia | — |
| 9 | **Preparazione alla localizzazione**: `gen-l10n`, ARB, `intl` per numeri e date, messaggi ICU per genere e plurale, pseudo-localizzazione +40%, schede scorrevoli, contenuti clinici per paese in un livello separato | P13 | **L** | Espansione in Europa | Pseudo-lingua senza overflow a 360 dp; zero stringhe nel codice (`grep` in CI) |

**Ordine consigliato:**

- **subito** 1 e 6 (S, rischio clinico e metrica falsata);
- **in parallelo** 2 e 4 (progettazione condivisa), poi 3;
- **trasversale** 5, a ogni schermata toccata;
- **solo se il CEO conferma l'Europa** 9, avviato **prima** di 2 e 4 per non riscrivere due volte i testi nuovi.

**Da validare prima del Ciclo 3:** test con 5 persone (2 «Giulia», 2 «Franco» con 65 anni o più, 1 «Sara»), registrando il tempo e i tocchi fino al primo evento e le frasi che preoccupano. È un'ora a persona, anche a distanza con la versione web.
