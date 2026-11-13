# Lulù — Testi clinici, versione 1 (v1)

**Documento di revisione per il medico veterinario abilitato.**  
Estratto il 10/11/2026 dal codice dell'app (cartella `lib/`, sola lettura). Versione dei testi: **v1**.  
Preparato dalla redazione di Lulù. Chi l'ha preparato **non è un medico veterinario abilitato**: questo documento serve a raccogliere la revisione e la firma di un professionista iscritto all'Ordine.  
Gemello in formato tabella: `docs/clinica/testi-clinici-v1.csv` (stesse righe, stessi ID).

## Terza revisione veterinaria (ricerca/26, 11/11/2026): approvate con modifica, da firmare

Il veterinario-revisore del progetto (non il veterinario abilitato: la firma resta quella della Parte «Firma della revisione») ha rivisto la v1.0-rc in `ricerca/26`. Nessuna proposta è respinta. I testi qui sotto sono già nell'app; in ogni voce sono segnati con «**Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare**». Il testo «Testo» di ogni voce resta quello della v1, come per le proposte v1.0-rc. Nessuna soglia e nessuna condizione degli avvisi è cambiata.

| ID | Correzione | Cosa cambia |
|---|---|---|
| VIA-004 | — | Approvata senza modifiche |
| VIA-005 | A8 | Testo: il trattamento lo fa e lo registra il veterinario; «da 1 a 5 giorni» |
| EMG-019 | A8 | Variante Italia: «Non provocare il vomito», partire subito con segni neurologici o respiratori |
| ALR-LIV-005 (nuova) | A8 | Frase d'azione comune «chiama prima» (ACT-CALL-FIRST) per ALR-TOX-001, ALR-DIA-002, ALR-DIA-005, ALR-FAR-001, ALR-FAR-004, ALR-GI-007a |
| ALR-DIA-002, ALR-DIA-005 | A8 | Testo completato |
| ALR-FAR-001 | A4 | Trilostano: non dare la prossima dose prima di aver sentito il veterinario |
| ALR-FAR-004, ALR-GI-007a | A5 | Testi separati per FANS e cortisone |
| ALR-URI-006 | A9 | Testo urgente a livello SUBITO |
| UI-DOS-001, UI-DOS-002 (nuove) | A7 | Dialogo «Saltato» e promemoria a 2 ore: testi per insulina e antiepilettici |
| ALR-PES-007 | B7 | Variante per il cane in crescita |
| ALR-REP-008 | B8 | Varianti per la femmina sterilizzata |
| ALR-RES-002 | B10 | Raffreddare solo dopo caldo o sforzo |
| ALR-URI-008 | B11 | Testo nuovo, nessuna frase d'azione |
| TOS-004 | C4 | Testo con le quantità |
| MET-002, STG-003 | C5 | Soglie prudenziali; «circa 3 su 4» al posto del 74% |

Non ancora fatte (non sono solo testi, o toccano la previsione): A1, A2, A3, A10, B1-B6, B9, C1-C3, C6 (PRV-001, in attesa del parere legale), C7. Il nuovo passo «Prende medicine?» della procedura guidata (A6) non è un testo clinico da firmare.

## Versione v1.0-rc (11/11/2026): modifiche proposte, da approvare

Questa revisione è la **v1.0-rc da far firmare al veterinario**. I testi qui sotto restano quelli della v1; le modifiche sono segnate in ogni voce con «**v1.0-rc — proposta, da approvare**». Nessuna soglia clinica è cambiata. Nessun testo è «approvato» finché il veterinario non firma.

| ID | Modifica proposta (da approvare) |
|---|---|
| VIA-004 | Norma vigente: Reg. (UE) 2016/429 e Reg. delegato (UE) 2026/131, dal 22/4/2026 |
| VIA-005 | Testo prudente: «Paesi indenni», elenco da verificare con il veterinario |
| EMG-019 | Numero del CAV di Milano (Niguarda) 02 6610 1029, **solo se il Paese del cane è l'Italia**, con chiamata diretta; verificato il 10/11/2026 |
| ALR-TOX-001, ALR-DIA-002, ALR-DIA-005, ALR-FAR-001, ALR-FAR-004, ALR-GI-007a | Frase d'azione specifica: «Chiama subito il veterinario; se non risponde, vai al pronto soccorso veterinario.» al posto di quella del livello SUBITO |
| ALR-URI-006 | Frase d'azione del livello SUBITO quando l'avviso sale a SUBITO |

**Dove stanno i testi.** Dal Ciclo 2 i testi non sono più nel codice: sono nel catalogo `lib/l10n/app_it.arb`, una voce per ID (la chiave è l'ID in camelCase: ALR-URI-001 → `alrUri001Title`, `alrUri001Text`, `alrUri001Action`). I riferimenti `file:riga` di questo documento sono quelli dell'estrazione v1. Le parti condizionali sono ora frasi intere per variante (`select` ICU), con lo stesso testo di prima. Un test d'identità (`test/clinical_texts_snapshot_test.dart`) confronta tutti i testi prodotti dalle regole con un'istantanea: ogni modifica futura si vede nel diff.

**Avvisi duplicati.** Si eliminano per ID e non più per titolo (vedi «Come leggere»).

**Osservazioni per il veterinario e lo sviluppatore** (nessuna modifica fatta):
- ALR-REP-006a («Temperatura calata da oltre 24 ore senza parto») con la logica attuale non scatta mai: la temperatura è letta solo nelle ultime 24 ore.
- ALR-CIB-003a, variante «in un cane diabetico»: non scatta mai, perché un diabetico abbattuto riceve già ALR-DIA-001.
- I punti di `ricerca/15` §3.2 (ALR-RES-002, ALR-ALT-006, ALR-REP-008, ALR-URI-008, ALR-PES-007, TOS-004, MET-002, STG-003, PRV-001, fonti) restavano domande per il veterinario: `ricerca/26` §6 ha risposto. Testi cambiati: vedi «Terza revisione veterinaria» sopra.

**Nuovi ID tecnici nel catalogo** (testi non clinici, già nell'app, invariati, non da firmare): NUT-FAT-001…013 (motivo del fabbisogno in Nutrizione), LAB-001…017 (nomi degli esami suggeriti), UI-EMG-001…011 (titoli della scheda Emergenze e righe del promemoria EMG-021).

## Come leggere questo documento

- **Ordine di revisione.** Parte 1 Emergenze, Parte 2 SUBITO, Parte 3 OGGI: è la parte prioritaria (tempo stimato 2½-3 ore). Le parti 4-7 si possono rivedere in un secondo momento.
- **Testo esatto.** I testi sono copiati dal codice e confrontati in automatico con il sorgente. Le parti tra parentesi graffe sono valori che l'app inserisce: `{nome}` = nome del cane, `{ore}`, `{n}` = numeri calcolati.
- **Parti condizionali.** `[se …: «…»]` indica una frase che compare solo in quella condizione. Le varianti dello stesso testo sono separate da « / ».
- **Livelli.** SUBITO, OGGI, ATTENZIONE, INFO. Alcuni avvisi cambiano livello secondo la situazione («variabile»): sono messi nella parte del livello più alto.
- **Frase d'azione.** Sotto ogni avviso l'app aggiunge la frase fissa del suo livello (Parte 0), salvo dove è scritto «nessuna frase d'azione».
- **Esito.** Per ogni voce: ☐ Approvato, ☐ Modificare (scrivere il testo nuovo nelle note), ☐ Eliminare. Si possono annotare anche le soglie in «Quando scatta».
- **Avvisi duplicati.** Se lo stesso avviso (stesso ID) scatta due volte, l'app lo mostra una volta sola, con il livello più alto. Fino al catalogo v1 il confronto era sul titolo.

## Conteggio

Il file `lib/logic/alerts.dart` contiene **99 chiamate `add(`** che producono un avviso: tutte sono estratte qui (verifica automatica: 99/99). Sei chiamate hanno due testi alternativi e sono divise in due schede (suffisso a/b), per un totale di **105 schede di avviso**.

| Parte | Contenuto | Voci |
|---|---|---|
| 0 | Frasi d'azione dei livelli | 5 |
| 1 | Scheda Emergenze e avvertenza | 22 |
| 2 | SUBITO: avvisi automatici 27, altri testi 6 | 33 |
| 3 | OGGI: avvisi automatici 36, altri testi 1 | 37 |
| 4 | ATTENZIONE: avvisi automatici 31, altri testi 4 | 35 |
| 5 | INFO: avvisi automatici 11, altri testi 0 | 11 |
| 6 | Altri testi informativi (prevenzione, nutrizione, stagioni, razze, viaggi, promemoria, diari) | 75 |
| 7 | Tabelle: alimenti pericolosi (21) e scale di valutazione (33) | 54 |
| | **Totale** | **272** |

---

## Parte 0 — Frasi d'azione dei livelli

#### ALR-LIV-001 · SUBITO

- **Quando scatta:** Sotto ogni avviso di livello SUBITO, salvo dove la colonna «Frase d'azione» dice «nessuna».
- **Testo:** «Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.»
- **Fonte:** ricerca/06 §35 · `lib/logic/alerts.dart:14`
- **Nota per la traduzione:** «Pronto soccorso veterinario h24»: servizio e nome diversi per paese.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-LIV-002 · OGGI

- **Quando scatta:** Sotto ogni avviso di livello OGGI, salvo dove la colonna «Frase d'azione» dice «nessuna».
- **Testo:** «Contatta il veterinario oggi stesso.»
- **Fonte:** ricerca/06 §35 · `lib/logic/alerts.dart:15`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-LIV-003 · ATTENZIONE

- **Quando scatta:** Sotto ogni avviso di livello ATTENZIONE, salvo dove la colonna «Frase d'azione» dice «nessuna».
- **Testo:** «Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.»
- **Fonte:** ricerca/06 §35 · `lib/logic/alerts.dart:17`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-LIV-004 · INFO

- **Quando scatta:** Sotto ogni avviso di livello INFO, salvo dove la colonna «Frase d'azione» dice «nessuna».
- **Testo:** «Parlane alla prossima visita.»
- **Fonte:** ricerca/06 §35 · `lib/logic/alerts.dart:18`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-LIV-005 · SUBITO (frase comune «chiama prima»)

- **Quando scatta:** Sotto gli avvisi SUBITO in cui la prima azione utile è una telefonata: ALR-TOX-001, ALR-DIA-002, ALR-DIA-005, ALR-FAR-001, ALR-FAR-004, ALR-GI-007a, al posto della frase del livello SUBITO. Chiave della revisione: ACT-CALL-FIRST.
- **Testo:** «Chiama subito il veterinario. Se non risponde entro pochi minuti, o se il cane peggiora, vai al pronto soccorso veterinario, anche di notte.»
- **Fonte:** ricerca/26 §3.4 (sostituisce la proposta v1.0-rc «Chiama subito il veterinario; se non risponde, vai al pronto soccorso veterinario.») · `lib/logic/alerts.dart`
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** testo esatto della revisione (A8).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

## Parte 1 — Scheda Emergenze

La scheda Emergenze è sempre raggiungibile dall'app. Oggi **non mostra alcun numero di centro antiveleni** (tolto in attesa di verifica, rapporto 07 N35). L'esito della verifica è in `ricerca/15-verifiche-cliniche-esterne.md`: la decisione se inserirlo spetta al revisore.

#### EMG-001 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Addome gonfio, conati a vuoto, agitazione»
- **Testo:** «Possibile torsione/dilatazione dello stomaco: ogni minuto conta.»
- **Fonte:** ricerca/06 aggiunta 1 · `lib/ui/emergency_screen.dart:15`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-002 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Fatica a respirare, respiro rumoroso, lingua o gengive blu»
- **Testo:** «Tienilo calmo e al fresco durante il trasporto.»
- **Fonte:** ricerca/06 aggiunta 1 · `lib/ui/emergency_screen.dart:19`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-003 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Gengive pallide o bianche, collasso, debolezza improvvisa»
- **Testo:** «Può indicare un'emorragia interna o uno shock.»
- **Fonte:** ricerca/06 aggiunta 1 · `lib/ui/emergency_screen.dart:23`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-004 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Convulsioni oltre 5 minuti, oppure 2 o più in 24 ore»
- **Testo:** «Non mettere le mani in bocca; allontana gli oggetti; cronometra.»
- **Fonte:** IVETF 2015 · `lib/ui/emergency_screen.dart:27`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-005 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Colpo di calore: ansima molto, barcolla, gengive rosso scuro»
- **Testo:** «Raffreddalo subito: bagnalo abbondantemente con acqua fresca o fredda e fai aria. Non coprirlo con asciugamani bagnati. Poi vai subito dal veterinario continuando a raffreddarlo in auto, anche se sembra riprendersi.»
- **Fonte:** «Cool first, transport second»: Hall et al. 2023 Vet Sci 10:465; Carter et al. 2024 J Therm Biol 121:103827 · `lib/ui/emergency_screen.dart:31`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-006 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Sospetto avvelenamento, morso di vipera, contatto con processionaria»
- **Testo:** «Porta la confezione o una foto. Non provocare il vomito di tua iniziativa (niente sale o acqua ossigenata).»
- **Fonte:** ricerca/06 · `lib/ui/emergency_screen.dart:38`
- **Nota per la traduzione:** Vipera e processionaria: fauna mediterranea; adattare per paese (es. rospi, serpenti locali).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-007 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Sforzo a urinare senza risultato, o nessuna pipì da 24 ore»
- **Testo:** «Nel maschio un blocco urinario è un'emergenza.»
- **Fonte:** ricerca/04 §4 · `lib/ui/emergency_screen.dart:43`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-008 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Cucciolo con vomito e diarrea, soprattutto se non vaccinato»
- **Testo:** «Va esclusa la parvovirosi; la disidratazione è rapida.»
- **Fonte:** ricerca/06 · `lib/ui/emergency_screen.dart:47`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-009 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Cucciolo di taglia toy debole, tremante o che non risponde»
- **Testo:** «Possibile ipoglicemia: solo se è cosciente, un po' di miele sulle gengive, poi subito dal veterinario.»
- **Fonte:** ricerca/06 §20 · `lib/ui/emergency_screen.dart:51`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-010 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Femmina non sterilizzata abbattuta, che beve molto o ha perdite dalla vulva, settimane dopo il calore»
- **Testo:** «Possibile piometra (infezione dell'utero).»
- **Fonte:** ricerca/06 · `lib/ui/emergency_screen.dart:56`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-011 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Parto difficile»
- **Testo:** «Oltre 30 minuti di contrazioni forti senza cucciolo, oltre 2 ore tra un cucciolo e l'altro, perdite verdi o nere, gravidanza oltre i 70 giorni.»
- **Fonte:** ricerca/06 · `lib/ui/emergency_screen.dart:61`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-012 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Cagna che allatta e trema, barcolla o è agitata»
- **Testo:** «Possibile eclampsia (calcio basso).»
- **Fonte:** ricerca/06 · `lib/ui/emergency_screen.dart:67`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-013 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Traumi (investimento, caduta, morsi), sanguinamenti, feci nere»
- **Testo:** «Anche se sembra stare bene: le lesioni interne non si vedono.»
- **Fonte:** ricerca/06 · `lib/ui/emergency_screen.dart:71`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-014 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Dolore intenso, guaisce se toccato, non si alza»
- **Testo:** «Non dare farmaci per persone: molti sono tossici per il cane.»
- **Fonte:** ricerca/06 · `lib/ui/emergency_screen.dart:75`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-015 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Ha ingerito un oggetto, ossa, pannocchie, batterie o farmaci»
- **Testo:** «Chiama prima di fare qualsiasi cosa.»
- **Fonte:** ricerca/06 · `lib/ui/emergency_screen.dart:79`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-016 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Reazione allergica grave: muso o palpebre gonfie, orticaria diffusa, vomito o fatica a respirare dopo puntura, farmaco o vaccino»
- **Testo:** «Il gonfiore del muso può chiudere le vie respiratorie: vai subito.»
- **Fonte:** ricerca/07 N1 (scheda) · `lib/ui/emergency_screen.dart:83`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-017 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Occhio sporgente, ferito, molto dolente o perdita improvvisa della vista»
- **Testo:** «Impedisci che si gratti; non mettere colliri di tua iniziativa.»
- **Fonte:** ricerca/07 N1 (scheda) · `lib/ui/emergency_screen.dart:88`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-018 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze, sezione «Vai subito dal veterinario se…».
- **Titolo:** «Ustioni, folgorazione (cavi elettrici) o quasi-annegamento»
- **Testo:** «Anche se sembra stare bene: i danni a polmoni e cuore possono comparire nelle ore successive.»
- **Fonte:** ricerca/07 N1 (scheda) · `lib/ui/emergency_screen.dart:92`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-019 · EMERGENZE

- **Quando scatta:** Sempre, nella scheda Emergenze (riquadro fisso).
- **Titolo:** «Sospetto avvelenamento»
- **Testo:** «Chiama subito il tuo veterinario o il pronto soccorso h24: sapranno contattare un centro antiveleni. Tieni a portata la confezione o una foto dell'etichetta.»
- **Fonte:** ricerca/07 N35 (numero del CAV tolto) · `lib/ui/emergency_screen.dart:157`
- **Nota per la traduzione:** Qui andrà il numero del centro antiveleni del paese, se verificato (vedi ricerca/15).
- **v1.0-rc — proposta, da approvare:** Solo se il Paese del cane è l'Italia: «Chiama subito il tuo veterinario o il pronto soccorso veterinario. Per sapere quanto è pericoloso ciò che ha ingerito puoi chiamare anche il Centro Antiveleni di Milano (Ospedale Niguarda), 02 6610 1029, 24 ore su 24: risponde anche per gli animali e ti chiederà nome e recapiti. Tieni a portata la confezione o una foto dell'etichetta.» Il riquadro diventa toccabile e chiama il numero. Numero verificato il 10/11/2026 (centroantiveleni.org, ospedaleniguarda.it); da riverificare a ogni rilascio pubblico e almeno ogni 6 mesi (un test lo impone). Negli altri Paesi resta il testo v1. (piano CEO 10.5; ricerca/15 §3.1 punto 3)
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (A8) Variante Italia: «Chiama subito il tuo veterinario o il pronto soccorso veterinario. Per sapere quanto è pericoloso ciò che ha ingerito puoi chiamare anche il Centro Antiveleni di Milano (Ospedale Niguarda), {telefono}, 24 ore su 24: risponde anche per gli animali e ti chiederà nome e recapiti. Non provocare il vomito di tua iniziativa. Tieni a portata la confezione o una foto dell'etichetta. Se ha convulsioni, respira male o non è ben sveglio, parti subito per il pronto soccorso veterinario e chiama durante il tragitto.» Altri Paesi: invariato.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-020 · EMERGENZE

- **Quando scatta:** Scheda Emergenze, se nel profilo mancano i numeri del veterinario e del pronto soccorso.
- **Titolo:** «Aggiungi i numeri utili»
- **Testo:** «Nel profilo del cane inserisci il telefono del tuo veterinario e di un pronto soccorso h24: li troverai qui.»
- **Fonte:** — · `lib/ui/emergency_screen.dart:127`
- **Nota per la traduzione:** «Pronto soccorso veterinario h24»: servizio e nome diversi per paese.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-021 · EMERGENZE

- **Quando scatta:** Scheda Emergenze, riquadro «Cosa dire al telefono» (generato dal profilo).
- **Titolo:** «Cosa dire al telefono»
- **Testo:** «• {nome}, {maschio|femmina}[se sterilizzato: « sterilizzato/a»], {età}, {peso} kg[se razza: «, {razza}»].<br>• [se ingestione nelle 24 ore: «Ha ingerito: {nota o "(descrivi cosa e quanto)"} alle {ora}.»]<br>• Farmaci in corso: {elenco o "nessuno"}.<br>• [se presenti: «Patologie note: {…}.»]<br>• [se presenti: «Allergie: {…}.»]<br>• Cosa è successo e da quando; come respira; colore delle gengive.»
- **Fonte:** ricerca/07 aggiunta N16 · `lib/ui/emergency_screen.dart:243`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### EMG-022 · EMERGENZE

- **Quando scatta:** In fondo alla scheda Emergenze e in altre schermate (costante «disclaimer» in lib/ui/common.dart).
- **Testo:** «Lulù aiuta a osservare e organizzare: non fa diagnosi e non sostituisce la visita veterinaria. In emergenza (fatica a respirare, gengive pallide o blu, addome gonfio con conati a vuoto, collasso, convulsioni, sospetto avvelenamento, sforzo a urinare senza risultato, colpo di calore) contatta subito il veterinario o il pronto soccorso veterinario più vicino.»
- **Fonte:** ricerca/06 · `lib/ui/common.dart:242`
- **Nota per la traduzione:** Testo con valore legale: far rivedere anche da un legale per ogni paese.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

## Parte 2 — SUBITO

#### ALR-URI-001 · SUBITO

- **Quando scatta:** Maschio (intero o castrato) con almeno 1 pipì segnata «sforzo» o «gocce» nelle ultime 12 ore.
- **Titolo:** «Sforzo a urinare: possibile urgenza»
- **Testo:** «Se {nome} si mette in posizione e non esce urina, o escono solo poche gocce, contatta subito il veterinario o un pronto soccorso veterinario, anche di notte. Nel maschio un blocco delle vie urinarie è un'emergenza: non aspettare il giorno dopo. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/04 §4; ricerca/06 · `lib/logic/alerts.dart:117`
- **Nota per la traduzione:** «Pronto soccorso veterinario»: servizio con nome diverso per paese.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-004 · SUBITO

- **Quando scatta:** Cucciolo (fase «cucciolo» dell'app) sveglio, senza una pipì vera (le pipì «solo gocce» non contano) da 6 ore da sveglio se ha meno di 4 mesi, da 8 ore se ha 4 mesi o più; ultima pipì entro 72 ore.
- **Titolo:** «Cucciolo senza pipì da {ore} ore da sveglio»
- **Testo:** «Un cucciolo sveglio urina molto più spesso. Se non è una registrazione mancante, contatta subito il veterinario. Se escono solo gocce, conta come se non avesse urinato.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/07 N9 · `lib/logic/alerts.dart:154`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-005 · SUBITO

- **Quando scatta:** Qualsiasi cane: nessuna pipì vera da 24 a 72 ore (oltre 72 ore l'app presume dati mancanti e tace).
- **Titolo:** «Nessuna pipì da {ore} ore»
- **Testo:** «Se {nome} non ha davvero urinato (e non è solo una registrazione mancante), è un'urgenza, specie nei maschi. Se escono solo gocce, conta come se non avesse urinato.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/04 §4; ricerca/07 N5 · `lib/logic/alerts.dart:163`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-006 · SUBITO o ATTENZIONE (variabile)

- **Quando scatta:** Nessuna pipì da 12 a 24 ore, con il cane sveglio da almeno 4 ore oppure entro 14 giorni da un intervento. SUBITO se è un maschio con sforzo nelle 24 ore, altrimenti ATTENZIONE. La frase sulla colonna compare se c'è un intervento con «colonna/ernia/disc/spin» nel titolo negli ultimi 14 giorni.
- **Titolo:** «Nessuna pipì registrata da {ore} ore»
- **Testo:** «[se intervento alla colonna negli ultimi 14 giorni: «Dopo una chirurgia della colonna, se non riesce a urinare da solo chiama il veterinario oggi: alcuni cani devono essere aiutati a svuotare la vescica. »]Portalo fuori e osserva: se prova a urinare senza riuscirci, è abbattuto o vomita, contatta subito il veterinario. Se non urina entro 24 ore in totale è comunque un'urgenza.»
- **Frase d'azione sotto l'avviso:** (nessuna frase d'azione)
- **Fonte:** ricerca/07 N8-N9 · `lib/logic/alerts.dart:180`
- **v1.0-rc — proposta, da approvare:** Quando sale a SUBITO (maschio con sforzo nelle 24 ore) compare la frase d'azione del livello: «Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.». A livello ATTENZIONE resta senza frase d'azione. (ricerca/15 §3.1 punto 5)
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (A9) A livello SUBITO (maschio con sforzo o gocce nelle 24 ore) testo urgente al posto di «Portalo fuori e osserva…»: «{nome} è un maschio, si è sforzato a urinare nelle ultime 24 ore e da {ore} ore non risulta nessuna pipì: può essere un blocco delle vie urinarie. Non aspettare di vedere se la fa: è un'urgenza, anche di notte. Se escono solo gocce, conta come se non avesse urinato.» Con un intervento alla colonna negli ultimi 14 giorni segue la frase «Dopo una chirurgia della colonna, se non riesce a urinare da solo chiama il veterinario oggi: alcuni cani devono essere aiutati a svuotare la vescica.» Frase d'azione: quella del livello SUBITO. A livello ATTENZIONE: testo invariato, nessuna frase d'azione.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-001 · SUBITO

- **Quando scatta:** Nelle ultime 24 ore: segno «conati» o «addome gonfio», oppure evento «Addome gonfio».
- **Titolo:** «Conati a vuoto o addome gonfio»
- **Testo:** «Conati senza riuscire a vomitare, addome gonfio, agitazione e salivazione possono indicare una torsione/dilatazione dello stomaco: è un'emergenza in cui ogni minuto conta.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/06; ricerca/07 · `lib/logic/alerts.dart:267`
- **Nota per la traduzione:** Torsione/dilatazione gastrica: usare il termine corrente nella lingua (GDV, Magendrehung, torsion d'estomac).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-NEU-001 · SUBITO

- **Quando scatta:** Evento «Collasso» nelle ultime 24 ore.
- **Titolo:** «Collasso o svenimento»
- **Testo:** «Un collasso o uno svenimento va sempre valutato subito, anche se si è ripreso: può dipendere da cuore, emorragia o calo di zuccheri.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/07 aggiunta N2 · `lib/logic/alerts.dart:277`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-002 · SUBITO o OGGI (variabile)

- **Quando scatta:** Cucciolo con, nelle ultime 24 ore, vomito e diarrea insieme, oppure vomito o diarrea con abbattimento o inappetenza. SUBITO se ci sono feci con sangue (48 ore) o l'evento «Abbattimento»; altrimenti OGGI.
- **Titolo:** «Cucciolo con vomito o diarrea»
- **Testo:** «Nei cuccioli vomito e diarrea insieme, o con abbattimento o inappetenza, richiedono una visita oggi stesso: la disidratazione è rapida e va esclusa la parvovirosi, soprattutto se non ha completato i vaccini. Subito se è molto abbattuto, ha sangue nelle feci o non trattiene l'acqua.»
- **Frase d'azione sotto l'avviso:** SUBITO: «Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.» / OGGI: «Contatta il veterinario oggi stesso.»
- **Fonte:** ricerca/06; ricerca/07 N1-N4 · `lib/logic/alerts.dart:290`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-DIA-001 · SUBITO o OGGI (variabile)

- **Quando scatta:** Cane diabetico con vomito o abbattimento nelle 24 ore. SUBITO se ci sono entrambi, altrimenti OGGI.
- **Titolo:** «Diabetico con vomito o abbattimento»
- **Testo:** «Non fare l'insulina senza aver sentito il veterinario. Vomito e abbattimento in un cane diabetico vanno valutati oggi stesso; subito se è molto debole, respira in modo strano o non beve.»
- **Frase d'azione sotto l'avviso:** SUBITO: «Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.» / OGGI: «Contatta il veterinario oggi stesso.»
- **Fonte:** ricerca/07 N2 · `lib/logic/alerts.dart:303`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-FAR-001 · SUBITO

- **Quando scatta:** Terapia in corso con trilostano e, nelle 24 ore, vomito, diarrea, abbattimento o inappetenza.
- **Titolo:** «Malessere durante la terapia per il Cushing»
- **Testo:** «Durante la terapia per il Cushing questi segni possono indicare un calo eccessivo del cortisolo: sospendi la prossima dose solo se te lo dice il veterinario e chiamalo subito.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/07 · `lib/logic/alerts.dart:314`
- **Nota per la traduzione:** «Cushing»: in alcune lingue «iperadrenocorticismo».
- **v1.0-rc — proposta, da approvare:** Frase d'azione specifica: «Chiama subito il veterinario; se non risponde, vai al pronto soccorso veterinario.» (il testo dice di chiamare; ricerca/15 §3.1 punto 4)
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (A4, A8) Testo: «Durante la terapia per il Cushing questi segni possono indicare un calo eccessivo del cortisolo. Non dare la prossima dose finché non hai parlato con il veterinario, e chiamalo subito.» Frase d'azione: «Chiama subito il veterinario. Se non risponde entro pochi minuti, o se il cane peggiora, vai al pronto soccorso veterinario, anche di notte.» (ALR-LIV-005, frase comune). Da confrontare con il foglietto illustrativo vigente di Vetoryl prima della firma.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-FAR-004 · SUBITO

- **Quando scatta:** Terapia con FANS o cortisone in corso e almeno un vomito nelle 24 ore.
- **Titolo:** «Vomito durante la terapia con antinfiammatori o cortisone»
- **Testo:** «Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non sospendere né aggiungere farmaci di tua iniziativa.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:352`
- **v1.0-rc — proposta, da approvare:** Frase d'azione specifica: «Chiama subito il veterinario; se non risponde, vai al pronto soccorso veterinario.» (il testo dice di chiamare; ricerca/15 §3.1 punto 4)
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (A5, A8) Testo secondo la terapia. Solo FANS: «Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non dare la prossima dose di antinfiammatorio finché non l'hai sentito, e non aggiungere altri farmaci (mai antidolorifici per persone).» Solo cortisone: «Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non sospendere il cortisone di colpo e non aggiungere altri farmaci: chiedi a lui cosa fare.» Entrambi (testo composto dalle due varianti approvate, da verificare alla firma): «Chiama subito il veterinario: può essere un effetto collaterale sullo stomaco. Non dare la prossima dose di antinfiammatorio finché non l'hai sentito, non sospendere il cortisone di colpo e non aggiungere altri farmaci (mai antidolorifici per persone).» Frase d'azione: «Chiama subito il veterinario. Se non risponde entro pochi minuti, o se il cane peggiora, vai al pronto soccorso veterinario, anche di notte.» (ALR-LIV-005, frase comune).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-007a · SUBITO

- **Quando scatta:** Feci nere nelle ultime 48 ore durante una terapia con FANS o cortisone.
- **Titolo:** «Feci nere»
- **Testo:** «Feci nere durante una terapia con antinfiammatori o cortisone: chiama subito il veterinario, potrebbe trattarsi di un sanguinamento dello stomaco.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:388`
- **v1.0-rc — proposta, da approvare:** Frase d'azione specifica: «Chiama subito il veterinario; se non risponde, vai al pronto soccorso veterinario.» (il testo dice di chiamare; ricerca/15 §3.1 punto 4)
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (A5, A8) Testo: «Feci nere durante una terapia con antinfiammatori o cortisone: potrebbe essere un sanguinamento dello stomaco. Chiama subito il veterinario[se c'è un FANS: «; non dare la prossima dose di antinfiammatorio finché non l'hai sentito»].» Frase d'azione: «Chiama subito il veterinario. Se non risponde entro pochi minuti, o se il cane peggiora, vai al pronto soccorso veterinario, anche di notte.» (ALR-LIV-005, frase comune).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-TOX-001 · SUBITO

- **Quando scatta:** Evento «Ha ingerito qualcosa» nelle ultime 12 ore.
- **Titolo:** «Ha ingerito qualcosa[se c'è una nota: «: »]{nota}»
- **Testo:** «Chiama subito il veterinario o un centro antiveleni, anche se sta bene. Non provocare il vomito di tua iniziativa. Tieni a portata la confezione o una foto dell'etichetta.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/06; ricerca/07 N19 · `lib/logic/alerts.dart:723`
- **Nota per la traduzione:** «Centro antiveleni»: servizio e numero diversi per paese; non tradurre con un numero.
- **v1.0-rc — proposta, da approvare:** Frase d'azione specifica: «Chiama subito il veterinario; se non risponde, vai al pronto soccorso veterinario.» (al posto di «Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.»). Per un'ingestione si chiama prima: il veterinario o il centro antiveleni dicono se e dove andare. (ricerca/15 §3.1 punto 4)
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (A8) Testo invariato. Frase d'azione: «Chiama subito il veterinario. Se non risponde entro pochi minuti, o se il cane peggiora, vai al pronto soccorso veterinario, anche di notte.» (ALR-LIV-005, frase comune).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-001 · SUBITO

- **Quando scatta:** Colore gengive «pallide» o «blu» registrato nelle ultime 24 ore.
- **Titolo:** «Gengive pallide o blu»
- **Testo:** «Possono indicare un problema di circolazione, respirazione o un'emorragia: è un'emergenza.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:749`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-002 · SUBITO

- **Quando scatta:** Colore gengive «rosso scuro» nelle ultime 24 ore (se non sono anche pallide o blu).
- **Titolo:** «Gengive rosso scuro»
- **Testo:** «Gengive rosso scuro, soprattutto dopo caldo o sforzo, possono indicare un colpo di calore o uno shock: raffreddalo con acqua (vedi Emergenze) e vai subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:757`
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (B10) Testo: «Gengive rosso scuro possono indicare un colpo di calore, un'infezione grave o uno shock. Se ha preso caldo o ha fatto sforzi, inizia subito a raffreddarlo con acqua fresca (vedi Emergenze) e poi parti; negli altri casi parti subito per il veterinario.»
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-004 · SUBITO

- **Quando scatta:** Ultima misura dei respiri nel sonno (entro 24 ore) sopra 40/min e almeno uno tra: cane cardiopatico, fatica a respirare nelle 12 ore, gengive blu, misura precedente entro 30 minuti anch'essa sopra 40.
- **Titolo:** «Respira molto veloce nel sonno ({n}/min)»
- **Testo:** «Oltre 40 respiri al minuto a riposo: possibile difficoltà respiratoria o cardiaca.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ACVIM 2019 (Keene et al., JVIM 33:1127); ricerca/07 N14 · `lib/logic/alerts.dart:794`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-008 · SUBITO

- **Quando scatta:** Tosse registrata con il segno «fatica a respirare» nelle ultime 12 ore.
- **Titolo:** «Fatica a respirare»
- **Testo:** «Respiro affannoso a riposo, bocca aperta o lingua scura: tienilo calmo e al fresco e vai subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:845`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-DIA-002 · SUBITO

- **Quando scatta:** Ultima glicemia (entro 6 ore) sotto 60 mg/dL.
- **Titolo:** «Glicemia bassa ({n} mg/dL)»
- **Testo:** «Possibile ipoglicemia. Se è cosciente strofina miele o glucosio sulle gengive (mai liquidi in bocca a un cane incosciente) e chiama subito il veterinario. Non fare la prossima insulina senza averlo sentito.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** AAHA 2018 (diabete); ricerca/07 N2 · `lib/logic/alerts.dart:893`
- **Nota per la traduzione:** mg/dL: in molti paesi si usa mmol/L (÷ 18). Le soglie vanno convertite, non solo l'etichetta.
- **v1.0-rc — proposta, da approvare:** Frase d'azione specifica: «Chiama subito il veterinario; se non risponde, vai al pronto soccorso veterinario.» (il testo dice di chiamare; ricerca/15 §3.1 punto 4)
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (A8) Testo: «Possibile ipoglicemia. Se è cosciente strofina miele o glucosio sulle gengive (mai liquidi in bocca a un cane incosciente) e chiama subito il veterinario. Se trema, barcolla, ha convulsioni o non è ben sveglio, vai direttamente al pronto soccorso veterinario. Non fare la prossima insulina senza averlo sentito.» Frase d'azione: «Chiama subito il veterinario. Se non risponde entro pochi minuti, o se il cane peggiora, vai al pronto soccorso veterinario, anche di notte.» (ALR-LIV-005, frase comune).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-DIA-005 · SUBITO

- **Quando scatta:** Due dosi di insulina registrate a meno di (intervallo prescritto − 4 ore, minimo 6 ore) di distanza, l'ultima entro 12 ore.
- **Titolo:** «Due dosi di insulina ravvicinate»
- **Testo:** «Due dosi di insulina registrate a {x} ore di distanza. Se le hai fatte davvero, chiama subito il veterinario: rischio di ipoglicemia. Se è un errore di registrazione, cancellane una.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/07 aggiunta N2 · `lib/logic/alerts.dart:932`
- **v1.0-rc — proposta, da approvare:** Frase d'azione specifica: «Chiama subito il veterinario; se non risponde, vai al pronto soccorso veterinario.» (il testo dice di chiamare; ricerca/15 §3.1 punto 4)
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (A8) Testo: «Due dosi di insulina registrate a {x} ore di distanza. Se le hai fatte davvero, chiama subito il veterinario: rischio di ipoglicemia. Intanto offrigli il suo pasto e non lasciarlo solo. Se è un errore di registrazione, cancellane una.» Frase d'azione: «Chiama subito il veterinario. Se non risponde entro pochi minuti, o se il cane peggiora, vai al pronto soccorso veterinario, anche di notte.» (ALR-LIV-005, frase comune).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-003 · SUBITO

- **Quando scatta:** Femmina in allattamento (o parto negli ultimi 50 giorni) con tremori/barcollamento o convulsione nelle 24 ore.
- **Titolo:** «Tremori in una cagna che allatta»
- **Testo:** «Possibile eclampsia (calcio basso dopo il parto): è un'emergenza. Allontana i cuccioli e vai subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:960`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-NEU-002 · SUBITO

- **Quando scatta:** Cucciolo sotto 5 kg o sotto 4 mesi con tremori, convulsione o evento «Abbattimento» nelle 24 ore.
- **Titolo:** «Cucciolo debole o tremante»
- **Testo:** «Nei cuccioli piccoli può essere un'ipoglicemia. Se è cosciente strofina un po' di miele sulle gengive, poi vai subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:969`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-NEU-003 · SUBITO

- **Quando scatta:** Convulsione nelle 24 ore in un cane diabetico.
- **Titolo:** «Convulsione in un cane diabetico»
- **Testo:** «Può essere un'ipoglicemia. Se è cosciente strofina un po' di miele o glucosio sulle gengive (mai liquidi in bocca a un cane incosciente) e vai subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/07 · `lib/logic/alerts.dart:982`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-NEU-004a · SUBITO

- **Quando scatta:** Convulsione nelle 24 ore lunga 5 minuti o più, oppure segnata «non si riprende».
- **Titolo:** «Convulsione lunga o senza ripresa»
- **Testo:** «Crisi oltre 5 minuti, crisi a grappolo o mancata ripresa sono un'emergenza.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** IVETF 2015 · `lib/logic/alerts.dart:992`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-NEU-004b · SUBITO

- **Quando scatta:** 2 o più convulsioni nelle 24 ore (crisi brevi con ripresa).
- **Titolo:** «{n} convulsioni in 24 ore»
- **Testo:** «Crisi oltre 5 minuti, crisi a grappolo o mancata ripresa sono un'emergenza.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** IVETF 2015 · `lib/logic/alerts.dart:993`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-DIA-006 · SUBITO

- **Quando scatta:** Cane diabetico con tremori/barcollamento/testa inclinata nelle 24 ore, senza convulsioni.
- **Titolo:** «Possibile ipoglicemia»
- **Testo:** «Tremori o barcollamento in un cane diabetico: se è cosciente strofina miele o glucosio sulle gengive e vai subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** AAHA 2018 · `lib/logic/alerts.dart:1027`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-NEU-007 · SUBITO o OGGI (variabile)

- **Quando scatta:** Tremori, barcollamento o testa inclinata nelle 24 ore (non diabetico, non in allattamento, non cucciolo piccolo). SUBITO se segnato «improvviso», altrimenti OGGI.
- **Titolo:** «Tremori, barcollamento o testa inclinata»
- **Testo:** «Segni neurologici: se sono comparsi all'improvviso è un'urgenza. Pensa anche a possibili sostanze ingerite.»
- **Frase d'azione sotto l'avviso:** SUBITO: «Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.» / OGGI: «Contatta il veterinario oggi stesso.»
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1038`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-TMP-001a · SUBITO

- **Quando scatta:** Ultima temperatura rettale (24 ore) ≥ 41 °C.
- **Titolo:** «Temperatura {t} °C»
- **Testo:** «Temperatura molto alta: possibile colpo di calore. Raffreddalo subito con acqua fresca o fredda e fai aria, poi vai subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** Hall et al. 2023 (VetCompass); Bruchim et al. 2017 · `lib/logic/alerts.dart:1056`
- **Nota per la traduzione:** °C: nei paesi che usano °F (fuori UE) convertire anche le soglie.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-TMP-001b · SUBITO

- **Quando scatta:** Ultima temperatura rettale (24 ore) sotto 37 °C.
- **Titolo:** «Temperatura {t} °C»
- **Testo:** «Temperatura troppo bassa: tienilo al caldo e vai subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1059`
- **Nota per la traduzione:** Temperature in °C: nei mercati con °F convertire anche le soglie.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### UI-LOG-001 · SUBITO

- **Quando scatta:** Quando si sceglie l'evento «Ha ingerito qualcosa» (riquadro rosso, apre le Emergenze).
- **Titolo:** «Chiama subito il veterinario o un centro antiveleni»
- **Testo:** «Non provocare il vomito di tua iniziativa»
- **Fonte:** ricerca/06 · `lib/ui/log_sheet.dart:270`
- **Nota per la traduzione:** Vedi EMG-019.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### UI-DIA-002 · SUBITO

- **Quando scatta:** Diario «Insulina e glicemie», riquadro rosso fisso.
- **Testo:** «Se non ha mangiato o ha vomitato, non fare l'insulina senza aver sentito il veterinario.<br>Ipoglicemia (debolezza, tremori, barcollamento, convulsioni): se è cosciente strofina miele o glucosio sulle gengive, mai liquidi in bocca a un cane incosciente, poi subito dal veterinario.»
- **Fonte:** AAHA 2018 · `lib/ui/diaries_screen.dart:309`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### UI-DIA-004 · SUBITO

- **Quando scatta:** Diario «Convulsioni», sempre.
- **Testo:** «Durante una crisi: non mettere le mani in bocca, allontana gli oggetti, abbassa le luci e cronometra. Oltre 5 minuti, oppure 2 crisi in 24 ore: subito dal veterinario (IVETF 2015).»
- **Fonte:** IVETF 2015 (Berendt et al., BMC Vet Res 11:182) · `lib/ui/diaries_screen.dart:391`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### UI-DIA-005 · SUBITO

- **Quando scatta:** Diario «Riproduzione», se il parto è previsto entro 5 giorni.
- **Titolo:** «Scheda parto»
- **Testo:** «Scheda parto: prepara la cassa parto in un luogo tranquillo e caldo. Chiama subito il veterinario se le contrazioni forti durano oltre 30 minuti senza cuccioli, se passano oltre 2 ore tra un cucciolo e l'altro, se ci sono perdite verdi o nere senza cuccioli, o se la gravidanza supera i 70 giorni. Dopo il parto: tremori o agitazione possono indicare eclampsia (subito dal veterinario).»
- **Fonte:** ricerca/06 · `lib/ui/diaries_screen.dart:501`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### NUT-001 · SUBITO

- **Quando scatta:** Femmina in allattamento.
- **Testo:** «In allattamento il fabbisogno arriva a 4-8 volte quello di riposo: lascia il cibo a disposizione (alimento per cuccioli) e acqua fresca sempre. Se trema, ansima, è agitata o barcolla, chiama subito il veterinario.»
- **Fonte:** NRC 2006 · `lib/logic/nutrition.dart:163`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### NUT-007 · SUBITO

- **Quando scatta:** Schermata Nutrizione, sotto l'elenco degli alimenti pericolosi (sempre).
- **Testo:** «Se ne ha mangiato: contatta subito il veterinario o un centro antiveleni, anche se sta bene. Non provocare il vomito di tua iniziativa (niente sale, acqua ossigenata o dita in gola) se non te lo dice il veterinario. Porta con te la confezione o una foto dell'etichetta.»
- **Fonte:** ricerca/06 · `lib/ui/nutrition_screen.dart:171`
- **Nota per la traduzione:** Vedi EMG-019.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

## Parte 3 — OGGI

#### ALR-URI-002 · OGGI

- **Quando scatta:** Femmina con 2 o più pipì con sforzo o a gocce nelle ultime 24 ore.
- **Titolo:** «Sforzo a urinare ripetuto»
- **Testo:** «Più tentativi con sforzo o poche gocce in 24 ore. Contatta il veterinario oggi stesso; subito se non esce urina. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/04 §4; ricerca/06 · `lib/logic/alerts.dart:126`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-007 · OGGI

- **Quando scatta:** Pipì con sangue nelle ultime 48 ore, insieme a vomito o abbattimento nelle 48 ore.
- **Titolo:** «Sangue nelle urine con malessere»
- **Testo:** «Sangue nelle urine insieme a vomito o abbattimento richiede una visita oggi stesso.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:205`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-FAR-002 · OGGI

- **Quando scatta:** Terapia in corso con FANS o cortisone, senza vomito, con inappetenza o abbattimento nelle 24 ore.
- **Titolo:** «Non mangia o è abbattuto durante antinfiammatori/cortisone»
- **Testo:** «Può essere un effetto collaterale sullo stomaco: chiama il veterinario oggi. Non sospendere né aggiungere farmaci di tua iniziativa.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:324`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-003 · OGGI

- **Quando scatta:** Vomito con sangue nelle ultime 24 ore.
- **Titolo:** «Vomito con sangue»
- **Testo:** «Sangue o materiale scuro "a fondi di caffè" nel vomito: visita oggi stesso; subito se è abbattuto o ha le gengive pallide.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:343`
- **Nota per la traduzione:** «A fondi di caffè»: espressione idiomatica, tradurre con l'equivalente medico locale (coffee-ground).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-004 · OGGI

- **Quando scatta:** Cucciolo o cane sotto 5 kg con 2 o più vomiti nelle 24 ore (se non scatta già un avviso più specifico).
- **Titolo:** «Vomito ripetuto in un cane piccolo»
- **Testo:** «Nei cuccioli e nei cani sotto i 5 kg disidratazione e ipoglicemia arrivano in fretta.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:361`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-007b · OGGI

- **Quando scatta:** Feci nere nelle ultime 48 ore, senza FANS o cortisone.
- **Titolo:** «Feci nere»
- **Testo:** «Feci nere come catrame possono indicare sangue digerito: serve una visita oggi.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:393`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-008 · OGGI

- **Quando scatta:** Cucciolo con feci con sangue nelle 48 ore (se non scatta già ALR-GI-002).
- **Titolo:** «Cucciolo con sangue nelle feci»
- **Testo:** «Nei cuccioli la diarrea con sangue richiede una visita oggi stesso (va esclusa la parvovirosi, soprattutto se non ha completato i vaccini).»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:401`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-009 · OGGI

- **Quando scatta:** Adulto con feci con sangue (48 ore) e vomito o abbattimento (24 ore).
- **Titolo:** «Sangue nelle feci con vomito o abbattimento»
- **Testo:** «Questa combinazione richiede una visita oggi stesso.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:409`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-011 · OGGI

- **Quando scatta:** Cucciolo con 2 o più diarree nelle 24 ore, senza sangue.
- **Titolo:** «Cucciolo con diarrea»
- **Testo:** «Nei cuccioli la disidratazione è rapida e va esclusa la parvovirosi: subito se vomita o è abbattuto.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:424`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-013 · OGGI o ATTENZIONE (variabile)

- **Quando scatta:** Nessuna cacca da 24 ore (cucciolo) o 48 ore (adulto), fino a 120 ore, con altre attività registrate dopo l'ultima cacca e nessun intervento nelle ultime 72 ore. OGGI se ≥ 36 h nel cucciolo, ≥ 72 h nell'adulto o se c'è vomito; altrimenti ATTENZIONE.
- **Titolo:** «Nessuna cacca da {ore} ore»
- **Testo:** «Se non è una registrazione mancante: controlla che beva e si muova. Se si sforza senza risultato, vomita o è abbattuto, senti il veterinario. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.»
- **Frase d'azione sotto l'avviso:** OGGI: «Contatta il veterinario oggi stesso.» / ATTENZIONE: «Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.»
- **Fonte:** ricerca/04 §4 · `lib/logic/alerts.dart:459`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-001 · OGGI

- **Quando scatta:** Femmina intera, 14-84 giorni dopo l'inizio dell'ultimo calore registrato, con almeno un segno: beve molto, pipì più frequente, vomito, abbattimento, inappetenza, perdite vulvari (7 giorni).
- **Titolo:** «Attenzione all'utero (piometra)»
- **Testo:** «In una femmina non sterilizzata, nelle settimane dopo il calore, sete e pipì aumentate, perdite dalla vulva, vomito o abbattimento possono indicare un'infezione dell'utero (piometra), che è un'urgenza.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:558`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-002 · OGGI o ATTENZIONE (variabile)

- **Quando scatta:** Femmina intera di almeno 12 mesi senza calori registrati, con almeno un segno tra: beve molto, pipì più frequente, vomito, abbattimento, inappetenza, perdite vulvari. OGGI con 2 o più segni, ATTENZIONE con 1.
- **Titolo:** «Femmina non sterilizzata: attenzione all'utero»
- **Testo:** «Se è stata in calore negli ultimi 2-3 mesi può trattarsi di un'infezione dell'utero (piometra), che è un'urgenza: [se 2 o più segni: «contatta il veterinario oggi stesso»][se 1 segno: «osservala e senti il veterinario se compaiono altri segni»]. Registra i calori nella sezione Riproduzione: Lulù potrà avvisarti meglio.»
- **Frase d'azione sotto l'avviso:** OGGI: «Contatta il veterinario oggi stesso.» / ATTENZIONE: «Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.»
- **Fonte:** ricerca/07 N6 · `lib/logic/alerts.dart:582`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-003 · OGGI

- **Quando scatta:** Colore gengive «gialle» nelle ultime 24 ore.
- **Titolo:** «Gengive gialle»
- **Testo:** «Il colore giallo (ittero) va valutato dal veterinario oggi stesso.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:766`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-005 · OGGI

- **Quando scatta:** Ultima misura dei respiri nel sonno sopra 40/min, senza le condizioni di ALR-RES-004.
- **Titolo:** «Respiri nel sonno oltre 40/min»
- **Testo:** «Rimisura tra 15-30 minuti mentre dorme tranquillo. Se resta sopra 40, o respira con fatica a bocca aperta, vai subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ACVIM 2019; ricerca/07 N14 · `lib/logic/alerts.dart:802`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-006 · OGGI

- **Quando scatta:** Due misure consecutive (entro 48 ore) dei respiri nel sonno sopra 30/min.
- **Titolo:** «Respiri nel sonno sopra 30/min»
- **Testo:** «Due misure di fila sopra 30 respiri al minuto: segnalalo al veterinario oggi, soprattutto se ha una malattia di cuore.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ACVIM 2019; Porciello et al. 2016 · `lib/logic/alerts.dart:811`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-007 · OGGI

- **Quando scatta:** Media dei respiri nel sonno degli ultimi 7 giorni sopra 30/min e almeno il 25% sopra la media dei 30 giorni precedenti.
- **Titolo:** «Respiri nel sonno in aumento»
- **Testo:** «Media della settimana {x}/min contro {y}/min del mese precedente: segnalalo al veterinario oggi.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 (baseline del cane) · `lib/logic/alerts.dart:832`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-009 · OGGI

- **Quando scatta:** Tosse nelle ultime 24 ore in un cane cardiopatico.
- **Titolo:** «Tosse in un cane con malattia di cuore»
- **Testo:** «Nei cardiopatici la tosse va segnalata al veterinario oggi.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ACVIM 2019 · `lib/logic/alerts.dart:859`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-DIA-003 · OGGI

- **Quando scatta:** Ultima glicemia (entro 6 ore) tra 60 e 79 mg/dL.
- **Titolo:** «Glicemia al limite basso ({n} mg/dL)»
- **Testo:** «Segnalala al veterinario oggi, prima della prossima insulina.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** AAHA 2018; ricerca/07 N2 · `lib/logic/alerts.dart:903`
- **Nota per la traduzione:** Vedi ALR-DIA-002 (unità).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-DIA-004 · OGGI o ATTENZIONE (variabile)

- **Quando scatta:** Ultima glicemia (entro 6 ore) sopra 400 mg/dL. OGGI se vomita, è abbattuto o non mangia; altrimenti ATTENZIONE.
- **Titolo:** «Glicemia alta ({n} mg/dL)»
- **Testo:** «Segnalala al veterinario: la terapia potrebbe andare rivista. Se vomita, è abbattuto o non mangia, oggi stesso.»
- **Frase d'azione sotto l'avviso:** OGGI: «Contatta il veterinario oggi stesso.» / ATTENZIONE: «Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.»
- **Fonte:** AAHA 2018; ricerca/07 N2 · `lib/logic/alerts.dart:909`
- **Nota per la traduzione:** Vedi ALR-DIA-002 (unità).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-NEU-005 · OGGI

- **Quando scatta:** Prima convulsione in assoluto registrata, nelle ultime 24 ore, breve e con ripresa.
- **Titolo:** «Prima convulsione»
- **Testo:** «Una prima crisi va sempre valutata dal veterinario. Annota durata e cosa è successo prima e dopo.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** IVETF 2015 · `lib/logic/alerts.dart:1001`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-TMP-002 · OGGI

- **Quando scatta:** Ultima temperatura rettale (24 ore) tra 39,5 e 40,9 °C.
- **Titolo:** «Febbre ({t} °C)»
- **Testo:** «Normale 38,0-39,2 °C. Non dare antipiretici per persone (sono tossici).»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1065`
- **Nota per la traduzione:** Separatore decimale: virgola in IT, punto in EN.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-CIB-001a · OGGI

- **Quando scatta:** Pasti saltati in modo «urgente» (vedi nota) in un cane diabetico, se non scattano già ALR-DIA-001 o ALR-GI-002. Urgente = nelle 48 ore saltati almeno 2 giorni di pasti; o cucciolo/sotto 5 kg con 2 pasti saltati in 24 ore; o cucciolo abbattuto; o anziano/diabetico/in FANS-cortisone con 1 pasto saltato.
- **Titolo:** «Non mangia»
- **Testo:** «Se non ha mangiato o ha vomitato, non fare l'insulina senza aver sentito il veterinario.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 N7 · `lib/logic/alerts.dart:1086`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-CIB-001b · OGGI

- **Quando scatta:** Come ALR-CIB-001a, in un cane non diabetico.
- **Titolo:** «Non mangia»
- **Testo:** «Pasti saltati: serve una visita oggi.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 N7 · `lib/logic/alerts.dart:1090`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-CIB-003a · OGGI

- **Quando scatta:** Evento «Abbattimento» nelle 24 ore insieme a vomito, diarrea o inappetenza, oppure in un cucciolo, diabetico o anziano (se non scattano già ALR-GI-002 o ALR-DIA-001).
- **Titolo:** «Abbattuto»
- **Testo:** «Abbattimento [se altri segni: «insieme ad altri segni»][altrimenti: «in un cane »]{cucciolo|diabetico|anziano}: contatta il veterinario oggi.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 N18 · `lib/logic/alerts.dart:1107`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-DIA-007 · OGGI

- **Quando scatta:** Cane diabetico: insulina segnata «non ha mangiato» nelle ultime 12 ore.
- **Titolo:** «Insulina fatta senza che abbia mangiato»
- **Testo:** «Chiama ora il veterinario e chiedi come comportarti. Nelle prossime ore offrigli il suo pasto e osservalo: se compaiono debolezza, tremori o barcollamento strofina miele sulle gengive e vai subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 N15 · `lib/logic/alerts.dart:1128`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-015 · OGGI o ATTENZIONE (variabile)

- **Quando scatta:** Pipì segnata «urina scura» nelle 48 ore. OGGI con abbattimento o febbre (≥ 39,5 °C); altrimenti ATTENZIONE. La frase sulle zecche compare da marzo a novembre.
- **Titolo:** «Urina scura o color caffè»
- **Testo:** «Urine scure, soprattutto con abbattimento, possono indicare una distruzione dei globuli rossi (es. malattie trasmesse dalle zecche come la babesiosi) o un danno muscolare. [se marzo-novembre: «Hai trovato zecche di recente? Dillo al veterinario. »][se abbattuto o febbre: «Con abbattimento o febbre serve una visita oggi.»][altrimenti: «Se si ripete, senti il veterinario.»]»
- **Frase d'azione sotto l'avviso:** OGGI: «Contatta il veterinario oggi stesso.» / ATTENZIONE: «Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.»
- **Fonte:** ricerca/07 aggiunta N6 · `lib/logic/alerts.dart:1145`
- **Nota per la traduzione:** Stagione delle zecche: dipende dal clima del paese.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-004 · OGGI

- **Quando scatta:** Parto negli ultimi 7 giorni con febbre (≥ 39,5 °C), perdite maleodoranti o purulente (48 ore) o abbattimento.
- **Titolo:** «Malessere nella prima settimana dopo il parto»
- **Testo:** «Febbre, perdite maleodoranti o abbattimento dopo il parto possono indicare un'infezione dell'utero: contatta il veterinario oggi.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 aggiunta N3 · `lib/logic/alerts.dart:1184`
- **Nota per la traduzione:** Temperature in °C: nei mercati con °F convertire anche le soglie. Decimali con la virgola: adattare al formato locale.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-005 · OGGI

- **Quando scatta:** Femmina con evento «mammelle» nelle 24 ore.
- **Titolo:** «Mammelle gonfie, calde o dolenti»
- **Testo:** «Può essere una mastite: contatta il veterinario oggi. Non spremere le mammelle.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 aggiunta N3 · `lib/logic/alerts.dart:1193`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-006a · OGGI

- **Quando scatta:** Parto previsto entro 7 giorni e una temperatura sotto 37,5 °C misurata più di 24 ore fa.
- **Titolo:** «Temperatura calata da oltre 24 ore senza parto»
- **Testo:** «Il calo di temperatura sotto 37,5 °C precede il parto: se dopo 24 ore non è iniziato il travaglio, chiama il veterinario.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 aggiunta N3 · `lib/logic/alerts.dart:1206`
- **Nota per la traduzione:** Temperature in °C: nei mercati con °F convertire anche le soglie. Decimali con la virgola: adattare al formato locale.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-ALT-001 · OGGI

- **Quando scatta:** Zoppia con il segno «non carica l'arto» nelle ultime 24 ore.
- **Titolo:** «Non appoggia la zampa»
- **Testo:** «Non caricare l'arto è un segno di dolore importante: visita oggi. Non dare antidolorifici per persone.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1229`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-007 · OGGI

- **Quando scatta:** Perdite vulvari purulente o maleodoranti (7 giorni) in una femmina intera, fuori dalla finestra 14-84 giorni dopo il calore (o senza calori registrati, o maschio/sterilizzata per errore di registrazione).
- **Titolo:** «Perdite purulente»
- **Testo:** «Perdite purulente in una femmina non sterilizzata possono indicare un'infezione dell'utero: contatta il veterinario oggi stesso.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1306`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-008 · OGGI o ATTENZIONE (variabile)

- **Quando scatta:** Perdite vulvari (7 giorni) fuori dal calore (più di 21 giorni dall'inizio). OGGI se purulente (in femmina sterilizzata), altrimenti ATTENZIONE.
- **Titolo:** «Perdite vulvari»
- **Testo:** «Perdite fuori dal calore vanno valutate dal veterinario entro 1-2 giorni; oggi stesso se è abbattuta, beve molto o le perdite sono purulente.»
- **Frase d'azione sotto l'avviso:** OGGI: «Contatta il veterinario oggi stesso.» / ATTENZIONE: «Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.»
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1314`
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (B8) In una femmina sterilizzata. OGGI (perdite con pus o cattivo odore): «In una femmina sterilizzata, perdite con pus o cattivo odore possono indicare un'infezione della vagina o di ciò che resta dell'utero: contatta il veterinario oggi.» ATTENZIONE: «Perdite dalla vulva in una femmina sterilizzata vanno fatte vedere nei prossimi giorni. Se sono sangue e lei si comporta come in calore, dillo al veterinario: a volte resta un pezzetto di ovaio. Oggi stesso se è abbattuta, beve molto o compaiono pus o cattivo odore.» Femmina intera: invariato. Livelli e condizioni invariati.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-009 · OGGI

- **Quando scatta:** Gravidanza registrata oltre i 70 giorni dall'accoppiamento senza parto.
- **Titolo:** «Gravidanza oltre i 70 giorni»
- **Testo:** «Il parto non è ancora avvenuto: contatta il veterinario oggi.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1358`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-CHI-001 · OGGI

- **Quando scatta:** Ferita con punti aperti o sanguinamento nelle ultime 48 ore.
- **Titolo:** «Ferita aperta o che sanguina»
- **Testo:** «Punti aperti o sanguinamento della ferita: copri con una garza pulita, impedisci che si lecchi e contatta il veterinario oggi. Subito se il sanguinamento è abbondante o si vede tessuto interno.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 aggiunta N8 · `lib/logic/alerts.dart:1431`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-CHI-003 · OGGI

- **Quando scatta:** Intervento negli ultimi 14 giorni, almeno 48 ore fa, nessun pasto registrato da allora (ma altre registrazioni sì).
- **Titolo:** «Non ha ancora mangiato dopo l'intervento»
- **Testo:** «L'appetito di solito torna entro 24-48 ore dall'intervento: contatta il veterinario oggi.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 aggiunta N8 · `lib/logic/alerts.dart:1461`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-ALT-006 · OGGI

- **Quando scatta:** Da maggio ad agosto: nelle 24 ore otite con esordio improvviso, oppure starnuti.
- **Titolo:** «Possibile forasacco»
- **Testo:** «In stagione dei forasacchi, scuotere la testa o starnutire all'improvviso dopo un prato richiede una visita oggi: prima si toglie, meno danni fa.»
- **Frase d'azione sotto l'avviso:** Contatta il veterinario oggi stesso.
- **Fonte:** ricerca/07 aggiunta N9 · `lib/logic/alerts.dart:1480`
- **Nota per la traduzione:** «Forasacco» (grass awn / foxtail): stagione e diffusione diverse per paese.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### UI-LOG-007 · OGGI

- **Quando scatta:** Quando si registra un'insulina (riquadro in evidenza).
- **Testo:** «Se non ha mangiato o ha vomitato, non fare l'insulina senza aver sentito il veterinario.»
- **Fonte:** AAHA 2018 · `lib/ui/log_sheet.dart:361`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

## Parte 4 — ATTENZIONE

#### ALR-URI-003 · ATTENZIONE

- **Quando scatta:** Femmina con 1 sola pipì con sforzo o a gocce nelle ultime 24 ore.
- **Titolo:** «Pipì con sforzo o a gocce»
- **Testo:** «Osserva le prossime pipì. Se non riesce a urinare affatto, contatta subito il veterinario. Lo sforzo per urinare e quello per defecare si confondono facilmente: se non sei sicuro, consideralo un problema urinario.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/04 §4; ricerca/06 · `lib/logic/alerts.dart:133`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-009 · ATTENZIONE

- **Quando scatta:** Pipì con sangue nelle ultime 48 ore, senza malessere e fuori dal calore.
- **Titolo:** «Sangue nelle urine»
- **Testo:** «Va sempre valutato dal veterinario entro 24-48 ore: può essere un segno di cistite o calcoli (solo il veterinario può dirlo). Se possibile raccogli un campione di urina.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:220`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-010 · ATTENZIONE

- **Quando scatta:** Nelle ultime 2 ore: 4 o più pipì (tranne nel maschio intero, dove la marcatura è normale), oppure 3 o più pipì di cui almeno una con un segno.
- **Titolo:** «Pipì piccole e frequenti»
- **Testo:** «{n} pipì in 2 ore. Può essere un segno di cistite (solo il veterinario può dirlo): sentilo entro 24-48 ore, subito se c'è sforzo senza urina.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/04 §4 (pollachiuria) · `lib/logic/alerts.dart:238`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-FAR-003 · ATTENZIONE

- **Quando scatta:** FANS e cortisone in corso contemporaneamente.
- **Titolo:** «Antinfiammatori e cortisone insieme»
- **Testo:** «Antinfiammatori e cortisone insieme aumentano il rischio di ulcere: verifica col veterinario che sia voluto.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:334`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-005 · ATTENZIONE

- **Quando scatta:** 3 o più vomiti nelle 24 ore, oppure almeno 1 vomito con abbattimento.
- **Titolo:** «Vomito ripetuto»
- **Testo:** «{n} episodi in 24 ore. Senti il veterinario entro 24 ore; subito se non trattiene nemmeno l'acqua o è molto abbattuto.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:368`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-010 · ATTENZIONE

- **Quando scatta:** Feci con sangue nelle 48 ore, senza vomito né abbattimento.
- **Titolo:** «Sangue rosso nelle feci»
- **Testo:** «Se si ripete, se c'è diarrea abbondante o se cambia il suo comportamento, senti il veterinario entro 24-48 ore.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:415`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-012 · ATTENZIONE

- **Quando scatta:** Cane non cucciolo e non diabetico con 3 o più diarree nelle 24 ore, oppure almeno 1 diarrea con vomito.
- **Titolo:** «Diarrea[se c'è vomito: « e vomito»] nelle ultime 24 ore»
- **Testo:** «Assicurati che beva. Se persiste oltre 24-48 ore, se è abbattuto o vomita ripetutamente, senti il veterinario.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:433`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-011 · ATTENZIONE

- **Quando scatta:** Media delle uscite per pipì degli ultimi 3 giorni ≥ 1,5 volte (2,5 con farmaci o malattie che aumentano la pipì) la media dei 14 giorni precedenti e almeno 2 uscite in più al giorno; servono dati in almeno il 60% dei giorni.
- **Titolo:** «Fa pipì più spesso del solito»
- **Testo:** «Negli ultimi 3 giorni {x} uscite al giorno contro {y} abituali. Può essere un segno di infezione urinaria, diabete o problemi renali (solo il veterinario può dirlo): parlane entro qualche giorno.[se diabetico: « In un cane diabetico segnalalo al veterinario: la terapia potrebbe andare rivista.»]»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 §PU · `lib/logic/alerts.dart:492`
- **Nota per la traduzione:** Decimali con la virgola: adattare al formato locale.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-012 · ATTENZIONE

- **Quando scatta:** Acqua registrata in almeno 2 dei 3 giorni precedenti, con media oltre 100 ml/kg al giorno.
- **Titolo:** «Beve molto»
- **Testo:** «In media {ml} ml al giorno, oltre i 100 ml/kg. La sete eccessiva può essere un segno di malattie da approfondire (solo il veterinario può dirlo). Non ridurre l'acqua: parlane con il veterinario.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/04 §5.3 (PU/PD) · `lib/logic/alerts.dart:519`
- **Nota per la traduzione:** ml/kg: unità SI, valida ovunque.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-013 · ATTENZIONE

- **Quando scatta:** Dieta secca, acqua registrata in almeno 2 dei 3 giorni precedenti, media sotto 20 ml/kg al giorno.
- **Titolo:** «Beve poco»
- **Testo:** «Con le crocchette {ml} ml al giorno sono pochi (meno di 20 ml/kg). Se non è una registrazione incompleta e mangia poco o è abbattuto, senti il veterinario.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/04 · `lib/logic/alerts.dart:528`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-014 · ATTENZIONE

- **Quando scatta:** Cane adulto o anziano con 2 o più pipì in casa negli ultimi 7 giorni.
- **Titolo:** «Pipì in casa ripetute»
- **Testo:** «{n} incidenti in 7 giorni in un cane adulto. Le cause possibili sono infezione urinaria, aumento della sete, incontinenza (frequente nelle femmine sterilizzate di taglia media e grande), declino cognitivo nell'anziano, oppure intervalli troppo lunghi tra le uscite. Vale la pena parlarne con il veterinario. Se le perdite avvengono mentre dorme o riposa, registrale come "Perdita di urina a riposo".»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:601`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-PES-001 · ATTENZIONE

- **Quando scatta:** Cane in crescita (sotto 6 mesi, o sotto 9 mesi se pesa almeno 10 kg) con peso fermo o in calo rispetto a una pesata di almeno 14 giorni prima.
- **Titolo:** «Il cucciolo non cresce»
- **Testo:** «Un cucciolo dovrebbe aumentare di peso ogni settimana: se il peso è fermo da 2 settimane o cala, senti il veterinario; subito se mangia poco, vomita o ha diarrea.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:628`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-PES-002 · ATTENZIONE

- **Quando scatta:** Adulto (≥ 12 mesi) con BCS ≥ 7 che perde più del 2% del peso a settimana.
- **Titolo:** «Sta dimagrendo troppo in fretta»
- **Testo:** «Oltre il 2% a settimana: un dimagrimento troppo rapido non è sano. Senti il veterinario per rivedere la dieta.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** WSAVA/AAHA (gestione del peso) · `lib/logic/alerts.dart:653`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-PES-003 · ATTENZIONE

- **Quando scatta:** Adulto con calo di peso ≥ 10% in 90 giorni, oppure ≥ 5% se anziano.
- **Titolo:** «Calo di peso del {n}%»
- **Testo:** «Un calo di peso non voluto merita una visita, soprattutto nel cane anziano.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:661`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-PES-006 · ATTENZIONE

- **Quando scatta:** Cane di almeno 12 mesi con BCS ≤ 3/9.
- **Titolo:** «Sottopeso»
- **Testo:** «Prima di aumentare la razione fallo visitare, per escludere cause mediche.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** WSAVA BCS · `lib/logic/alerts.dart:684`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-TOX-002 · ATTENZIONE

- **Quando scatta:** Evento «Ha ingerito qualcosa» tra 12 ore e 5 giorni fa.
- **Titolo:** «Sorveglianza dopo un'ingestione»
- **Testo:** «Il {giorno/mese} ha ingerito[se c'è una nota: «: »]{nota}. Alcuni veleni (es. topicidi) danno sintomi dopo giorni: sangue dal naso o dalle gengive, lividi, debolezza, vomito o pipì scarsa → subito dal veterinario.»
- **Frase d'azione sotto l'avviso:** (nessuna frase d'azione)
- **Fonte:** ricerca/07 N19 · `lib/logic/alerts.dart:732`
- **Nota per la traduzione:** Formato data giorno/mese: adattare al paese.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-010 · ATTENZIONE

- **Quando scatta:** Tosse nelle ultime 24 ore in un Cavalier King (non cardiopatico registrato).
- **Titolo:** «Tosse in un Cavalier King»
- **Testo:** «Il Cavalier è predisposto alla malattia della valvola mitrale: segnala la tosse al veterinario e conta i respiri nel sonno.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ACVIM 2019 · `lib/logic/alerts.dart:865`
- **Nota per la traduzione:** Nome di razza: usare il nome FCI locale.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-RES-011 · ATTENZIONE

- **Quando scatta:** Tosse nelle ultime 24 ore, con prima tosse della settimana da almeno 3 giorni o con abbattimento.
- **Titolo:** «Tosse da più giorni»
- **Testo:** «Tosse che dura da più di 3 giorni o con abbattimento: senti il veterinario entro 24-48 ore. Evita il contatto con altri cani.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:872`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-NEU-006 · ATTENZIONE

- **Quando scatta:** Ultimi 4 mesi completi di dati: nel mese corrente almeno 2 crisi e più di 1,5 volte la media dei 3 mesi precedenti; nessuna crisi nelle ultime 24 ore.
- **Titolo:** «Crisi più frequenti questo mese»
- **Testo:** «{n} crisi questo mese contro una media di {x}: parlane con il veterinario, la terapia potrebbe andare rivista.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** IVETF 2015 · `lib/logic/alerts.dart:1015`
- **Nota per la traduzione:** Decimali con la virgola: adattare al formato locale.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-CIB-002 · ATTENZIONE

- **Quando scatta:** Saltati nelle 24 ore tanti pasti quanti ne fa al giorno, senza le condizioni urgenti.
- **Titolo:** «Ha saltato i pasti»
- **Testo:** «Se non mangia da 24 ore senti il veterinario entro 1-2 giorni; prima se vomita o è abbattuto.»
- **Frase d'azione sotto l'avviso:** (nessuna frase d'azione)
- **Fonte:** ricerca/07 N7 · `lib/logic/alerts.dart:1095`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-CIB-003b · ATTENZIONE

- **Quando scatta:** Evento «Abbattimento» nelle 24 ore senza altri segni, in un adulto sano.
- **Titolo:** «Abbattuto»
- **Testo:** «Osservalo: se non torna vivace entro la giornata, o compaiono vomito, diarrea, febbre o gengive pallide, senti il veterinario.»
- **Frase d'azione sotto l'avviso:** (nessuna frase d'azione)
- **Fonte:** ricerca/07 N18 · `lib/logic/alerts.dart:1115`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-FAR-005 · ATTENZIONE

- **Quando scatta:** Antidiarroico (loperamide) in corso in una razza con possibile mutazione MDR1 (collie, pastore australiano, shetland, bobtail, whippet, silken, pastore svizzero, McNab, pastore scozzese…).
- **Titolo:** «Loperamide in una razza a rischio MDR1»
- **Testo:** «Nelle razze con possibile mutazione MDR1 la loperamide può dare effetti neurologici: verifica con il veterinario.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/07 N49 · `lib/logic/alerts.dart:1163`
- **Nota per la traduzione:** MDR1 (ABCB1): sigla internazionale, non tradurre. Nomi di razza: elenco da adattare (riconoscimento per parola chiave italiana).
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-ALT-002 · ATTENZIONE

- **Quando scatta:** Zoppia registrata da almeno 3 giorni (prima zoppia della settimana).
- **Titolo:** «Zoppia da più giorni»
- **Testo:** «Una zoppia che dura da 3-5 giorni va vista dal veterinario.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1236`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-ALT-003 · ATTENZIONE

- **Quando scatta:** Evento «pelle/orecchie/prurito» nelle ultime 48 ore.
- **Titolo:** «Prurito, pelle o orecchie»
- **Testo:** «Senti il veterinario entro qualche giorno; prima se si gratta fino a ferirsi o scuote molto la testa.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1243`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-ALT-004 · ATTENZIONE

- **Quando scatta:** Denti negli ultimi 7 giorni con alitosi, gengive che sanguinano o fatica a masticare.
- **Titolo:** «Problema ai denti»
- **Testo:** «Alito cattivo, gengive che sanguinano o fatica a masticare: controllo dentale al prossimo appuntamento, prima se mangia poco.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** AAHA 2019 (dentale) · `lib/logic/alerts.dart:1261`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-016 · ATTENZIONE

- **Quando scatta:** Evento «Perdita di urina a riposo» negli ultimi 7 giorni.
- **Titolo:** «Perdite di urina a riposo»
- **Testo:** «Perdite mentre dorme o riposa: spesso è un problema curabile (incontinenza). Parlane con il veterinario. Non ridurre l'acqua.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1285`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-URI-017 · ATTENZIONE

- **Quando scatta:** Cane non cucciolo con pipì notturne in almeno 2 delle ultime 7 notti e in nessuna delle 14 notti precedenti (dati da almeno 14 giorni).
- **Titolo:** «Pipì di notte, prima non succedeva»
- **Testo:** «Due o più notti su 7 con pipì notturna: può essere un segno di sete aumentata o di un problema urinario. Prenota una visita.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/04 §1.4 (nicturia) · `lib/logic/alerts.dart:1345`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-011 · ATTENZIONE

- **Quando scatta:** Calore registrato che dura da oltre 4 settimane.
- **Titolo:** «Calore che dura da oltre 4 settimane»
- **Testo:** «Un calore persistente va valutato dal veterinario. Se è già finito, registra "Fine calore".»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1375`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-FAR-006 · ATTENZIONE

- **Quando scatta:** Una dose di terapia programmata non confermata da oltre 2 ore.
- **Titolo:** «Dose non confermata: {farmaco}»
- **Testo:** «Prevista alle {hh:mm}. Se l'hai saltata, non raddoppiare la successiva: chiedi al veterinario cosa fare.»
- **Frase d'azione sotto l'avviso:** (nessuna frase d'azione)
- **Fonte:** ricerca/07 · `lib/logic/alerts.dart:1388`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-CHI-002 · ATTENZIONE

- **Quando scatta:** Ferita arrossata, gonfia o con secrezione nelle ultime 48 ore.
- **Titolo:** «Ferita arrossata, gonfia o con secrezione»
- **Testo:** «Può essere un'infiammazione o un'infezione della ferita: mantieni il collare elisabettiano e senti il veterinario entro 1-2 giorni; prima se peggiora o compare febbre.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** ricerca/07 aggiunta N8 · `lib/logic/alerts.dart:1445`
- **Nota per la traduzione:** «Collare elisabettiano»: in EN «e-collar/cone».
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-PRV-001 · ATTENZIONE

- **Quando scatta:** Cucciolo con un vaccino «core» in ritardo.
- **Titolo:** «Ciclo vaccinale non completo»
- **Testo:** «Finché non è completo, evita aree frequentate da cani sconosciuti e chiama il veterinario per fissare la dose.»
- **Frase d'azione sotto l'avviso:** Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.
- **Fonte:** WSAVA 2024 · `lib/logic/alerts.dart:1501`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### UI-DIA-006 · ATTENZIONE

- **Quando scatta:** Scala qualità della vita (HHHHHMM): totale sotto 35/70.
- **Testo:** «Punteggio sotto 35: parlane con il veterinario. Esistono molte possibilità per controllare dolore e disagio.»
- **Fonte:** Scala HHHHHMM (Villalobos) · `lib/ui/diaries_screen.dart:611`
- **Nota per la traduzione:** Scala HHHHHMM: nome dell'autrice, non tradurre la sigla.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### UI-DIA-008 · ATTENZIONE

- **Quando scatta:** Punteggio di massa muscolare: perdita moderata o grave (ATTENZIONE) / lieve (INFO).
- **Testo:** «Perdita muscolare moderata o grave: parlane con il veterinario nei prossimi giorni. / Perdita lieve: segnalala alla prossima visita.»
- **Fonte:** WSAVA Muscle Condition Score · `lib/ui/diaries_screen.dart:1139`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### UI-DIA-009 · ATTENZIONE

- **Quando scatta:** Checklist cognitiva: totale ≥ 3 o almeno una voce con 2.
- **Testo:** «Ci sono cambiamenti da segnalare: parlane con il veterinario. Alcuni possono dipendere da dolore, problemi di vista o udito, o malattie curabili, non solo dall'età.»
- **Fonte:** — · `lib/ui/diaries_screen.dart:1198`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### MET-002 · ATTENZIONE

- **Quando scatta:** Temperatura percepita all'ora dell'uscita ≥ 27 °C (≥ 24 °C per cani a rischio: brachicefali, anziani, BCS ≥ 7, ≥ 50 kg, malattie di cuore o respiratorie), oppure 2 °C sotto la soglia con umidità ≥ 70%.
- **Testo:** «Alle {ora}:00 sono previsti {t} °C percepiti[se umidità ≥ 70%: « con umidità alta»]. [se a rischio: «{nome} è più a rischio di colpo di calore. »]Fai un'uscita breve all'ombra, porta acqua, evita asfalto e sforzi; la passeggiata lunga nelle ore fresche. Asfalto: se non riesci a tenerci il dorso della mano per 7 secondi è troppo caldo per le zampe.»
- **Fonte:** ricerca/06 aggiunta 20; Hall et al. 2020 (fattori di rischio) · `lib/logic/weather.dart:97`
- **Nota per la traduzione:** Soglie in °C; «regola dei 7 secondi» è un consiglio divulgativo, non uno studio.
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (C5) In coda al testo: «Sono soglie prudenziali, non un limite sicuro: anche sotto, osserva come respira.» Soglie invariate.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

## Parte 5 — INFO

#### ALR-URI-008 · INFO

- **Quando scatta:** Pipì con sangue nelle ultime 48 ore in una femmina in calore, senza sforzo e senza malessere.
- **Titolo:** «Sangue durante il calore»
- **Testo:** «In calore è normale una perdita di sangue dalla vulva. Se il sangue è nelle urine stesse, se si sforza o se il calore dura più di 3-4 settimane, senti il veterinario.»
- **Frase d'azione sotto l'avviso:** Parlane alla prossima visita.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:212`
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (B11) Testo: «Durante il calore è normale una perdita di sangue dalla vulva, che può macchiare la pipì. Senti il veterinario nei prossimi giorni se il calore dura più di 3-4 settimane o se la pipì resta rossa anche dopo; oggi stesso se si sforza a urinare, va molto spesso o è abbattuta.» Frase d'azione: nessuna. Livello INFO invariato.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-006 · INFO

- **Quando scatta:** Un solo vomito nelle 24 ore, senza altri segni.
- **Titolo:** «Ha vomitato una volta»
- **Testo:** «Osserva: se si ripete, se è abbattuto o compaiono altri segni, senti il veterinario.»
- **Frase d'azione sotto l'avviso:** Parlane alla prossima visita.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:376`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-PES-004 · INFO

- **Quando scatta:** Adulto con calo di peso tra 5% e 10% in 90 giorni e BCS sotto 7.
- **Titolo:** «Calo di peso del {n}%»
- **Testo:** «Tienilo d'occhio: se continua senza che tu abbia cambiato la dieta, senti il veterinario.»
- **Frase d'azione sotto l'avviso:** Parlane alla prossima visita.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:668`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-PES-005 · INFO

- **Quando scatta:** Adulto con aumento di peso ≥ 10% in 90 giorni.
- **Titolo:** «Aumento di peso del {n}%»
- **Testo:** «Controlla razione e snack nella sezione Nutrizione.»
- **Frase d'azione sotto l'avviso:** Parlane alla prossima visita.
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:675`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-PES-007 · INFO

- **Quando scatta:** BCS ≥ 7/9.
- **Titolo:** «Sovrappeso»
- **Testo:** «Body Condition Score {bcs}/9: la razione in Nutrizione è calcolata per un dimagrimento graduale. Prima di iniziare fai visitare il cane.»
- **Frase d'azione sotto l'avviso:** Parlane alla prossima visita.
- **Fonte:** WSAVA BCS · `lib/logic/alerts.dart:691`
- **Nota per la traduzione:** «Body Condition Score»: termine tecnico, lasciare in inglese con spiegazione.
- **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (B7) Se non ha finito di crescere (fine crescita dalla taglia adulta o dal peso, come in Nutrizione): «Body Condition Score {bcs}/9: per un cucciolo è sopra l'ideale. Non ridurre il cibo da solo: durante la crescita la razione va decisa con il veterinario, controllando la curva di crescita.» Adulti: invariato.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-PES-008 · INFO

- **Quando scatta:** BCS = 6/9.
- **Titolo:** «Leggermente sovrappeso»
- **Testo:** «Riduci gli snack e ricontrolla tra un mese.»
- **Frase d'azione sotto l'avviso:** Parlane alla prossima visita.
- **Fonte:** WSAVA BCS · `lib/logic/alerts.dart:699`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-006b · INFO

- **Quando scatta:** Parto previsto entro 7 giorni e temperatura sotto 37,5 °C nelle ultime 24 ore.
- **Titolo:** «Parto atteso entro circa 24 ore»
- **Testo:** «La temperatura sotto 37,5 °C di solito precede il parto di circa 24 ore. Prepara la cassa parto.»
- **Frase d'azione sotto l'avviso:** (nessuna frase d'azione)
- **Fonte:** ricerca/07 aggiunta N3 · `lib/logic/alerts.dart:1207`
- **Nota per la traduzione:** Temperature in °C: nei mercati con °F convertire anche le soglie. Decimali con la virgola: adattare al formato locale.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-ALT-005 · INFO

- **Quando scatta:** Il proprietario registra le spazzolature e negli ultimi 7 giorni sono meno di 3.
- **Titolo:** «Denti: {n} spazzolature in 7 giorni»
- **Testo:** «Ideale ogni giorno, almeno 3 volte a settimana (AAHA 2019).»
- **Frase d'azione sotto l'avviso:** Parlane alla prossima visita.
- **Fonte:** AAHA 2019 (dentale) · `lib/logic/alerts.dart:1273`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-REP-010 · INFO

- **Quando scatta:** Gravidanza tra 58 e 70 giorni dall'accoppiamento.
- **Titolo:** «Parto vicino (presunto il {giorno/mese})»
- **Testo:** «Prepara la cassa parto. Chiama subito il veterinario se: contrazioni forti per oltre 30 minuti senza cuccioli, oltre 2 ore tra un cucciolo e l'altro, perdite verdi o nere senza cuccioli.»
- **Frase d'azione sotto l'avviso:** (nessuna frase d'azione)
- **Fonte:** ricerca/06 · `lib/logic/alerts.dart:1364`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-GI-014 · INFO

- **Quando scatta:** Feci con punteggio 1 della scala Purina nelle 48 ore.
- **Titolo:** «Feci molto dure»
- **Testo:** «Punteggio 1 della scala fecale: controlla che beva abbastanza. Se si sforza senza risultato, senti il veterinario.»
- **Frase d'azione sotto l'avviso:** Parlane alla prossima visita.
- **Fonte:** Scala fecale Purina 1-7 · `lib/logic/alerts.dart:1401`
- **Nota per la traduzione:** «Scala Purina»: nome proprio, non tradurre.
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

#### ALR-PRV-002 · INFO

- **Quando scatta:** Almeno una scadenza (vaccino, antiparassitario, visita…) superata.
- **Titolo:** «Una scadenza superata / {n} scadenze superate»
- **Testo:** «{titoli delle prime 3 scadenze}»
- **Frase d'azione sotto l'avviso:** (nessuna frase d'azione)
- **Fonte:** — · `lib/logic/alerts.dart:1510`
- **Esito:** ☐ Approvato ☐ Modificare ☐ Eliminare
- **Note del veterinario:** ______________________________________________

## Parte 6 — Altri testi informativi

### Inserimento eventi

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| UI-LOG-002 | Campo durata della convulsione (testo d'aiuto). | **Durata (minuti)** — Oltre 5 minuti è un'emergenza | IVETF 2015 · `lib/ui/log_sheet.dart:205` | ☐A ☐M ☐E | |
| UI-LOG-003 | Campo temperatura (testo d'aiuto). | **Temperatura rettale (°C)** — Normale 38,0-39,2 °C | ricerca/06 · `lib/ui/log_sheet.dart:207` | ☐A ☐M ☐E | |
| UI-LOG-004 | Campo respiri (testo d'aiuto). | **Respiri in un minuto (durante il sonno)** — Usa il timer in Salute › Diari, oppure conta per 30" e raddoppia | ACVIM 2019 · `lib/ui/log_sheet.dart:200` | ☐A ☐M ☐E | |
| UI-LOG-005 | Campo insulina (testo d'aiuto). | **Unità somministrate** — Come prescritte dal veterinario: l'app non calcola dosi | ricerca/07 · `lib/ui/log_sheet.dart:210` | ☐A ☐M ☐E | |
| UI-LOG-006 | Campo glicemia (testo d'aiuto). | **Glicemia (mg/dL)** — Solo come registro per il veterinario | ricerca/07 · `lib/ui/log_sheet.dart:214` | ☐A ☐M ☐E | |
| UI-LOG-008 | Controllo di plausibilità della temperatura. | Sembra in °F: inserisci i gradi Celsius (°F − 32) × 5/9. / Temperatura non plausibile (30-45 °C). | ricerca/07 N21 · `lib/ui/log_sheet.dart:464` | ☐A ☐M ☐E | |
| UI-LOG-009 | Controllo di plausibilità di respiri, durata crisi e glicemia. | Valore non plausibile (4-150 respiri al minuto). / Durata non plausibile (0-60 minuti). / Valore molto basso: se è in mmol/L moltiplica per 18 (mg/dL). | ricerca/07 N21 · `lib/ui/log_sheet.dart:467` | ☐A ☐M ☐E | |

### Diari

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| UI-DIA-001 | Diario «Cuore e respiro», sempre. | **Cuore e respiro** — Conta i respiri mentre dorme tranquillo (non dopo il gioco né al caldo): ogni volta che il torace si alza tocca il pulsante. Con il timer da 30 secondi il risultato viene raddoppiato. Normale sotto 30 al minuto (ACVIM 2019). | ACVIM 2019; Porciello et al. 2016 · `lib/ui/diaries_screen.dart:194` | ☐A ☐M ☐E | |
| UI-DIA-003 | Diario «Insulina e glicemie», sempre. | Le unità sono quelle prescritte dal veterinario: Lulù le registra, non le calcola. Acqua, pipì e peso sono gli indicatori di controllo (AAHA 2018). | AAHA 2018 · `lib/ui/diaries_screen.dart:317` | ☐A ☐M ☐E | |
| UI-DIA-007 | Esami di laboratorio, sempre. | Lulù non interpreta gli esami: mostra l'andamento e segnala i valori fuori dall'intervallo indicato dal laboratorio. L'interpretazione spetta al veterinario. | — · `lib/ui/diaries_screen.dart:691` | ☐A ☐M ☐E | |
| UI-DIA-010 | Muscoli e cognitivo, sempre (nota a piè di pagina). | Questionari validati come CBPI (dolore), LOAD (artrosi) e CCDR (disfunzione cognitiva) sono protetti da copyright: il veterinario può somministrarli in visita. | — · `lib/ui/diaries_screen.dart:1240` | ☐A ☐M ☐E | |

### Home e terapie

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| UI-HOM-001 | Home, sotto le dosi da confermare. | Se hai saltato una dose non raddoppiare la successiva: chiedi al veterinario cosa fare. | ricerca/07 · `lib/ui/home_screen.dart:162` | ☐A ☐M ☐E | |
| UI-HOM-002 | Terapia diuretica con dose serale (dalle 18). | Non spostare né saltare il diuretico per ridurre le uscite notturne: chiedi al veterinario se si può dare al mattino. | ricerca/07 tabella I · `lib/ui/home_screen.dart:188` | ☐A ☐M ☐E | |
| UI-HOM-003 | Nei 14 giorni dopo un intervento (scheda «Convalescenza: giorno N di 14»). | **Convalescenza: giorno {n} di 14** — • Riposo: uscite brevi al guinzaglio solo per i bisogni, niente corse, salti o scale.<br>• Collare elisabettiano (o body) finché il veterinario non dice di toglierlo: non deve leccare la ferita.<br>• Controlla la ferita due volte al giorno e registrala.<br>• Prima pipì entro 24 ore; appetito di solito entro 24-48 ore.<br>• Somministra solo i farmaci prescritti. | ricerca/07 aggiunta N8 · `lib/ui/home_screen.dart:526` | ☐A ☐M ☐E | |
| UI-DOS-001 | Home, dialogo di conferma di «Saltato» su una dose (titolo «Dose saltata?»). | Generale: «Confermi che questa dose non è stata data? Non raddoppiare la prossima: chiedi al veterinario cosa fare.» / Insulina (nome con insulin, caninsulin, vetsulin, prozinc, lantus, glargin): «Confermi che l'insulina non è stata fatta? Non farla in ritardo e non raddoppiare la prossima senza aver sentito il veterinario. Se non sei sicuro che sia stata fatta, non rifarla.» / Antiepilettici (fenobarbital, levetiracetam, bromuro di potassio o di sodio, imepitoina, zonisamide e nomi commerciali): «Confermi che la dose non è stata data? Con i farmaci per le convulsioni una dose saltata può far tornare le crisi: chiama il veterinario oggi per sapere se darla adesso.» **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare (A7).** | ricerca/26 §5.1; AAHA 2018; ACVIM 2016 · `lib/ui/home_screen.dart` (`_DoseCard`) | ☐A ☐M ☐E | |
| UI-DOS-002 | Notifica 2 ore dopo una dose non confermata (al massimo 3 per cane). | Generale (invariato): **💊 Dose confermata per {nome}?** — Apri Lulù e segna "Dato" o "Saltato". Se l'hai saltata non raddoppiare la successiva: chiedi al veterinario. / Insulina: **💉 Insulina di {nome}: segnata?** — Se è stata fatta, segna "Dato". Se non sei sicuro che sia stata fatta, non rifarla: chiedi al veterinario. **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare (A7).** / Antiepilettici: **💊 Dose confermata per {nome}?** — Apri Lulù e segna "Dato" o "Saltato". Con i farmaci per le convulsioni una dose saltata può far tornare le crisi: se l'hai saltata, chiama il veterinario oggi per sapere se darla adesso. **Testo ricavato dal testo approvato del dialogo (ricerca/26 §5.1), da firmare.** | ricerca/26 §5.1, §5.3 · `lib/store.dart` (`planNotifications`) | ☐A ☐M ☐E | |

### Promemoria uscite

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| PRM-001 | Previsione pipì: superato il tetto diurno per l'età. | Ha superato {durata} dall'ultima pipì: portalo fuori adesso. | ricerca/04 §1; ricerca/07 N8 · `lib/logic/elimination_model.dart:1006` | ☐A ☐M ☐E | |
| PRM-002 | Previsione pipì: tetto ridotto da farmaci o malattie. | Con {cause} ha bisogno di uscire più spesso: non farlo aspettare oltre {durata}. | ricerca/05 · `lib/logic/elimination_model.dart:1008` | ☐A ☐M ☐E | |
| PRM-003 | Previsione pipì: si raggiunge il tetto diurno. | Non conviene aspettare oltre: è il limite consigliato per la sua età (un tetto, non un obiettivo). | ricerca/04 §5.2 (mesi + 1) · `lib/logic/elimination_model.dart:1010` | ☐A ☐M ☐E | |
| PRM-004 | Previsione notturna: si supererebbe il tetto notturno (adulto / cucciolo). | Dall'ultima pipì passerebbero più di {durata}: fallo uscire prima di dormire. Se di notte chiede di uscire, assecondalo. / È un cucciolo: non riesce ancora a trattenerla per tutta la notte. Prevedi un'uscita notturna. / Dall'ultima pipì passerebbero più di {durata}: prevedi un'uscita prima di dormire o durante la notte. | ricerca/04 · `lib/logic/elimination_model.dart:1043` | ☐A ☐M ☐E | |
| PRM-005 | Cane con cistite tra i fattori registrati. | Non ridurre l'acqua: bere aiuta. | ricerca/07 tabella I · `lib/logic/elimination_model.dart:1062` | ☐A ☐M ☐E | |
| PRM-006 | Nei 14 giorni dopo un intervento. | Dopo l'intervento: uscita breve al guinzaglio solo per i bisogni. | ricerca/07 aggiunta N8 · `lib/logic/elimination_model.dart:1074` | ☐A ☐M ☐E | |
| PRM-007 | Cucciolo sotto 6 mesi, uscita prevista di notte. | Se dorme tranquillo nel trasportino puoi aspettare il suo segnale. | ricerca/07 · `lib/logic/elimination_model.dart:1080` | ☐A ☐M ☐E | |

### Meteo

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| MET-001 | Allerte meteo attive, temperatura percepita all'ora dell'uscita sotto 0 °C. | Alle {ora}:00 sono previsti {t} °C percepiti: uscita breve[se sotto 10 kg: «, cappottino»], asciugalo al rientro e sciacqua i polpastrelli dal sale antighiaccio. | ricerca/06 aggiunta 20 · `lib/logic/weather.dart:89` | ☐A ☐M ☐E | |

### Consigli di stagione

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| STG-001 | Febbraio-maggio. | **Stagione della processionaria** — Evita le pinete e i nidi bianchi sui pini. Se il cane la tocca con la bocca (salivazione, lingua gonfia): subito dal veterinario, senza strofinare. | ricerca/06 · `lib/logic/seasonal.dart:21` | ☐A ☐M ☐E | |
| STG-002 | Maggio-agosto. | **Stagione dei forasacchi** — Dopo i prati controlla orecchie, zampe (tra le dita) e narici. Se scuote la testa o starnutisce all'improvviso, senti il veterinario. | ricerca/07 aggiunta N9 · `lib/logic/seasonal.dart:32` | ☐A ☐M ☐E | |
| STG-003 | Giugno-settembre; la prima frase solo per brachicefali, anziani, BCS ≥ 7 o cardiopatici. | **Caldo: rischio colpo di calore** — [se a rischio: «Per {nome} il rischio è più alto. »]Passeggiate nelle ore fresche, mai lasciarlo in auto, sempre acqua fresca. Il 74% dei colpi di calore avviene durante lo sforzo. **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (C5) L'ultima frase diventa: «Nel Regno Unito circa 3 colpi di calore su 4 avvengono durante lo sforzo: nei giorni caldi, passeggiate brevi e nelle ore fresche.» | Hall, Carter, O'Neill 2020, Animals 10:1324 (74,2% da sforzo, Regno Unito) · `lib/logic/seasonal.dart:49` | ☐A ☐M ☐E | |
| STG-004 | Ottobre-aprile. | **Veleni per lumache e topi** — In questa stagione sono più usati nei giardini e negli orti: tienilo al guinzaglio vicino a coltivazioni e cantine. | ricerca/06 · `lib/logic/seasonal.dart:57` | ☐A ☐M ☐E | |
| STG-005 | Giugno-novembre. | **Acqua stagnante e leptospirosi** — Non farlo bere da pozzanghere, fossi e stagni: la leptospirosi si trasmette con l'urina dei topi ed è trasmissibile all'uomo. Vomito, abbattimento e sete dopo un bagno in acque ferme → veterinario oggi. | ricerca/06 · `lib/logic/seasonal.dart:66` | ☐A ☐M ☐E | |
| STG-006 | Dicembre-febbraio; la prima frase per cani sotto 10 kg, anziani o cuccioli. | **Freddo** — [se fragile: «Per {nome} il freddo pesa di più. »]Uscite brevi quando gela, cappottino per i cani a pelo raso o piccoli; asciugalo dopo la pioggia; attenzione al sale antighiaccio sui polpastrelli (sciacquali al rientro). | — · `lib/logic/seasonal.dart:83` | ☐A ☐M ☐E | |
| STG-007 | Centro-Sud: tutto l'anno; Nord: marzo-novembre. | **Zecche** — Al Centro-Sud le zecche sono presenti tutto l'anno: mantieni la protezione e controlla il pelo dopo le passeggiate. / Stagione delle zecche (marzo-novembre): controlla il pelo dopo le passeggiate. | ESCCAP Italia · `lib/logic/seasonal.dart:95` | ☐A ☐M ☐E | |
| STG-008 | Dal 20 dicembre al 2 gennaio. | **Botti di Capodanno** — Tienilo in casa, con una zona tranquilla e finestre chiuse; controlla che la medaglietta sia aggiornata. Se è molto pauroso, parlane prima con il veterinario. | — · `lib/logic/seasonal.dart:106` | ☐A ☐M ☐E | |

### Predisposizioni di razza

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| RAZ-001 | Razze a torace profondo (alano, pastore tedesco, setter, weimaraner, dobermann, bovaro, san bernardo, terranova, basset, bloodhound, levriero tranne piccolo levriero, akita) o peso ≥ 35 kg. | **Torace profondo: attenzione alla torsione gastrica** — Pasti divisi, niente corse subito dopo mangiato. Addome gonfio con conati a vuoto è un'emergenza. | ricerca/06 · `lib/logic/seasonal.dart:158` | ☐A ☐M ☐E | |
| RAZ-002 | Razze brachicefale (bulldog, carlino, boxer, shih tzu, pechinese, boston, cavalier, dogue, bouledogue). | **Razza brachicefala** — Respira peggio con caldo e sforzo: evita le ore calde e segnala al veterinario russare forte o affanno. | ricerca/06 · `lib/logic/seasonal.dart:167` | ☐A ☐M ☐E | |
| RAZ-003 | Razze con possibile mutazione MDR1. | **Possibile mutazione MDR1** — Chiedi al veterinario il test MDR1 prima di usare alcuni antiparassitari e farmaci (es. ivermectina ad alte dosi). | ricerca/06 · `lib/logic/seasonal.dart:188` | ☐A ☐M ☐E | |
| RAZ-004 | Dalmata. | **Dalmata: calcoli di urati** — Acqua abbondante e dieta concordata con il veterinario; segnala sforzo o sangue nelle urine. | ricerca/06 · `lib/logic/seasonal.dart:197` | ☐A ☐M ☐E | |
| RAZ-005 | Bassotto, dachshund, corgi, basset. | **Schiena lunga** — Evita salti da divani e scale ripide. Dolore alla schiena o zampe posteriori deboli: subito dal veterinario. | ricerca/06 · `lib/logic/seasonal.dart:206` | ☐A ☐M ☐E | |
| RAZ-006 | Yorkshire, chihuahua, pomerania, volpino, razze «toy». | **Razza toy: trachea e zuccheri** — Predisposta al collasso tracheale (tosse "a clacson": usa la pettorina, non il collare) e, da cucciolo, all'ipoglicemia: pasti frequenti. | ricerca/06 · `lib/logic/seasonal.dart:215` | ☐A ☐M ☐E | |
| RAZ-007 | Schnauzer nano. | **Schnauzer nano: pancreatite** — Evita avanzi e cibi grassi; vomito e dolore addominale dopo un pasto grasso vanno visti dal veterinario. | ricerca/06 · `lib/logic/seasonal.dart:225` | ☐A ☐M ☐E | |
| RAZ-008 | Dobermann. | **Dobermann: cuore** — Predisposto alla cardiomiopatia dilatativa: chiedi al veterinario dei controlli cardiologici periodici (ECG Holter, ecografia). | ricerca/06 · `lib/logic/seasonal.dart:234` | ☐A ☐M ☐E | |
| RAZ-009 | Cocker. | **Cocker: orecchie** — Predisposto alle otiti: controlla e asciuga le orecchie dopo bagni e passeggiate sotto la pioggia. | ricerca/06 · `lib/logic/seasonal.dart:243` | ☐A ☐M ☐E | |
| RAZ-010 | Bulldog francese. | **Bulldog francese: schiena** — Predisposto all'ernia del disco: dolore alla schiena o zampe posteriori deboli vanno visti subito. | ricerca/06 · `lib/logic/seasonal.dart:252` | ☐A ☐M ☐E | |
| RAZ-011 | Cavalier King. | **Cavalier King: cuore** — Predisposto alla malattia della valvola mitrale: conta i respiri nel sonno ogni settimana (sezione Diari). | ACVIM 2019 · `lib/logic/seasonal.dart:261` | ☐A ☐M ☐E | |
| RAZ-012 | Cane non sterilizzato di taglia grande/gigante o ≥ 25 kg, fino a 24 mesi. | **Sterilizzazione nelle taglie grandi** — Per alcune razze grandi gli studi indicano che l'età della sterilizzazione può influire su articolazioni e alcuni tumori (Hart et al. 2020). Non esiste un'età giusta per tutti: parlane con il veterinario. | Hart et al. 2020, Front Vet Sci 7:388 · `lib/logic/seasonal.dart:279` | ☐A ☐M ☐E | |

### Cucciolo

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| CUC-001 | Cucciolo fino a 16 settimane. | **Finestra di socializzazione (fino a ~14 settimane)** — Fagli conoscere con calma persone, rumori, superfici e cani vaccinati e sani, anche prima della fine dei vaccini, in ambienti controllati (AVSAB 2008). Finché i vaccini non sono completi evita parchi e aree con feci di cani sconosciuti; sì a cani sani e vaccinati, case di amici e classi per cuccioli con protocollo igienico. Abitualo a trasportino e manipolazione. | AVSAB 2008 (position statement) · `lib/logic/seasonal.dart:294` | ☐A ☐M ☐E | |
| CUC-002 | Cucciolo fino a 26 settimane. | **Educazione al bisogno** — Premia subito, fuori, appena ha fatto. Non punire gli incidenti: pulisci con un detergente enzimatico. Lulù ti dice quando portarlo fuori. | — · `lib/logic/seasonal.dart:303` | ☐A ☐M ☐E | |

### Prevenzione (proposte in cartella)

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| PRV-001 | Microchip non inserito nel profilo. Data proposta: 60 giorni dalla nascita o oggi. | **Microchip e iscrizione all'anagrafe canina** — Obbligatoria per legge (L. 281/1991, O.M. 6/8/2008, anagrafe SINAC): entro 60 giorni dalla nascita e comunque prima della cessione. Se hai adottato il cane, verifica che sia intestato a te. | L. 281/1991; O.M. 6/8/2008; D.M. 2/11/2023 (SINAC) · `lib/logic/prevention.dart:62` | ☐A ☐M ☐E | |
| PRV-002 | Microchip presente. Proposta tra 14 giorni. | **Verifica che l'anagrafe sia intestata a te** — Controlla sul portale dell'anagrafe canina della tua Regione (o SINAC) che il microchip {numero} sia intestato a te e che indirizzo e telefono siano aggiornati. | D.M. 2/11/2023 (SINAC) · `lib/logic/prevention.dart:71` | ☐A ☐M ☐E | |
| PRV-003 | Cucciolo sotto 16 settimane: 1ª, 2ª e 3ª dose core a 8, 12, 16 settimane. | **Vaccino core (cimurro, epatite, parvovirosi) – 1ª / 2ª / 3ª dose** — WSAVA: prima dose a 6-8 settimane. / Ogni 2-4 settimane fino a 16 settimane o più. / L'ultima dose non prima delle 16 settimane. | WSAVA 2024 · `lib/logic/prevention.dart:85` | ☐A ☐M ☐E | |
| PRV-004 | Cane di 16 settimane o più senza vaccino core registrato. | **Vaccino core (cimurro, epatite, parvovirosi) – verifica il libretto** — Nessun vaccino core registrato. Se non trovi il libretto, il veterinario può fare una dose (WSAVA considera protettiva una dose dei vaccini core vivi attenuati nell'adulto) oppure dosare gli anticorpi. | WSAVA 2024 · `lib/logic/prevention.dart:104` | ☐A ☐M ☐E | |
| PRV-005 | Cane sotto 26 settimane. | **Vaccino core (cimurro, epatite, parvovirosi) – richiamo** — WSAVA 2024: richiamo a 26 settimane (oppure a 12 mesi secondo il veterinario), poi ogni 3 anni se il vaccino usato lo prevede. | WSAVA 2024 · `lib/logic/prevention.dart:115` | ☐A ☐M ☐E | |
| PRV-006 | Cane sotto 26 settimane senza leptospirosi registrata. | **Leptospirosi – 1ª dose / 2ª dose** — Consigliata in Italia: 2 dosi a 2-4 settimane di distanza, poi richiamo annuale. / Completa l'avvio vaccinale. | WSAVA 2024; ricerca/07 N10 · `lib/logic/prevention.dart:126` | ☐A ☐M ☐E | |
| PRV-007 | Cane di 26 settimane o più senza leptospirosi registrata. | **Leptospirosi** — Se non è mai stato vaccinato servono 2 dosi a 2-4 settimane; poi richiamo annuale. Verifica il libretto. | WSAVA 2024 · `lib/logic/prevention.dart:140` | ☐A ☐M ☐E | |
| PRV-008 | Cucciolo sotto 6 mesi. | **Sverminazione cucciolo** — Ogni 2 settimane fino a 2 settimane dopo lo svezzamento, poi ogni mese fino a 6 mesi. | ESCCAP GL1 · `lib/logic/prevention.dart:151` | ☐A ☐M ☐E | |
| PRV-009 | Cane di 6 mesi o più. | **Esame delle feci** — Da 1 a 4 volte l'anno secondo lo stile di vita (o sverminazione periodica secondo il veterinario). | ESCCAP GL1 · `lib/logic/prevention.dart:159` | ☐A ☐M ☐E | |
| PRV-010 | In stagione (da aprile al Sud, da maggio altrove, fino a ottobre), non protetto negli ultimi 45 giorni, almeno 6 settimane di vita. | **Prevenzione filariosi (stagione {anno})** — ESCCAP Italia: profilassi mensile fino a dicembre (un mese dopo la fine della stagione delle zanzare). Se non era protetto, chiedi al veterinario se serve prima un test. | ESCCAP Italia · `lib/logic/prevention.dart:179` | ☐A ☐M ☐E | |
| PRV-011 | Novembre-dicembre, non protetto negli ultimi 45 giorni, almeno 7 mesi. | **Filariosi: chiedi al veterinario se fare una dose ora e il test** — Se non era protetto quest'estate, il veterinario valuterà un test (antigene + microfilarie) prima di iniziare; il test affidabile si fa in primavera. | ESCCAP Italia · `lib/logic/prevention.dart:190` | ☐A ☐M ☐E | |
| PRV-012 | Cane che avrà almeno 7 mesi all'inizio della prossima stagione; proposta il 15 del mese prima. | **Test filariosi e leishmaniosi annuale ({anno})** — Prima di iniziare la profilassi: antigene della filaria e, nelle zone a rischio, test per la leishmania. | ESCCAP Italia · `lib/logic/prevention.dart:200` | ☐A ☐M ☐E | |
| PRV-013 | Inizio della prossima stagione (cane con almeno 6 settimane a quella data). Frase sul Sud solo per cani al Sud. | **Inizio profilassi filariosi {anno}** — Mensile fino a dicembre[se Sud: « (al Sud valuta con il veterinario la copertura tutto l'anno)»]. Nel cucciolo dalle 6-8 settimane, secondo il prodotto. Esistono anche iniezioni a lento rilascio da 6 o 12 mesi. | ESCCAP Italia · `lib/logic/prevention.dart:210` | ☐A ☐M ☐E | |
| PRV-014 | Sempre; data 1° aprile (dell'anno dopo se la stagione è finita). | **Repellente anti-pappataci (leishmaniosi) {anno}** — Da aprile a novembre per tutti i cani, anche al Nord: la leishmaniosi è ormai presente in molte aree. Il collare dura secondo il prodotto, lo spot-on 3-4 settimane. Gli spot-on e alcuni collari per cani contengono permetrina, molto tossica per i gatti: se in casa c'è un gatto chiedi al veterinario un prodotto adatto e tienili separati finché il prodotto è asciutto. | ESCCAP Italia; ricerca/07 N29 · `lib/logic/prevention.dart:225` | ☐A ☐M ☐E | |
| PRV-015 | Sempre; data oggi. | **Antiparassitario esterno (zecche e pulci)** — Frequenza secondo il prodotto (1-3 mesi). Al Centro-Sud anche tutto l'anno. Gli spot-on e alcuni collari per cani contengono permetrina, molto tossica per i gatti: se in casa c'è un gatto chiedi al veterinario un prodotto adatto e tienili separati finché il prodotto è asciutto. | ESCCAP Italia · `lib/logic/prevention.dart:233` | ☐A ☐M ☐E | |
| PRV-016 | Sempre; tra 30 giorni (anziano: controllo semestrale). | **Visita di controllo annuale / Controllo geriatrico semestrale** — Visita generale, peso, denti, richiami. / Per i cani anziani: visita ed esami del sangue e delle urine ogni 6 mesi. | AAHA/WSAVA (età della vita) · `lib/logic/prevention.dart:246` | ☐A ☐M ☐E | |

### Prevenzione

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| PRV-017 | Schermata Salute › Prevenzione, sempre. | WSAVA (vaccini) ed ESCCAP Italia (parassiti). Le date vanno confermate con il veterinario. | — · `lib/ui/health_screen.dart:126` | ☐A ☐M ☐E | |

### Nutrizione

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| NUT-002 | Pasti impostati dal proprietario meno di quelli consigliati per l'età (5 sotto 3 mesi e 5 kg, 4 sotto 4 mesi, 3 sotto 6 mesi). | Per la sua età sono consigliati {n} pasti al giorno: nei cuccioli piccoli pochi pasti possono causare ipoglicemia. | AAHA 2019; ricerca/06 §20 · `lib/logic/nutrition.dart:171` | ☐A ☐M ☐E | |
| NUT-003 | Cucciolo di taglia grande o gigante (o stimata ≥ 25 kg) ancora in crescita. | Cucciolo di taglia grande: usa un alimento specifico "puppy large breed" e non aggiungere integratori di calcio. Mantienilo snello (BCS 4-5): crescere più in fretta non lo fa diventare più grande, aumenta il rischio di problemi alle articolazioni. | ricerca/06 §22 · `lib/logic/nutrition.dart:181` | ☐A ☐M ☐E | |
| NUT-004 | Programma di dimagrimento (BCS ≥ 7). L'ultima frase solo se ci sono patologie registrate. | Per dimagrire con questa quota di calorie è consigliato un alimento dietetico specifico: riducendo molto la razione del cibo normale si rischiano carenze. Prima di iniziare fai visitare il cane: alcune malattie ormonali causano aumento di peso. Pesalo ogni 2 settimane.[se patologie: « Con le patologie registrate la dieta va decisa con il veterinario.»] | WSAVA/AAHA (peso) · `lib/logic/nutrition.dart:189` | ☐A ☐M ☐E | |
| NUT-005 | Sottopeso (BCS ≤ 3). | Sottopeso: prima fallo visitare per escludere cause mediche, poi aumenta la razione gradualmente in 1-2 settimane. | WSAVA · `lib/logic/nutrition.dart:198` | ☐A ☐M ☐E | |
| NUT-006 | Schermata Nutrizione con BCS ≥ 7. | Obiettivo: perdere l'1-2% del peso a settimana, con il controllo del veterinario. | WSAVA/AAHA (peso) · `lib/ui/nutrition_screen.dart:139` | ☐A ☐M ☐E | |

### Viaggi (checklist)

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| VIA-001 | Checklist viaggio, sempre. | **Età minima** — Antirabbico da 12 settimane + 21 giorni: in genere non si viaggia prima delle 15 settimane di età. | Reg. (UE) 2016/429; Reg. delegato (UE) 2026/131; Reg. delegato (UE) 2020/688 all. VII · `lib/logic/modules.dart:172` | ☐A ☐M ☐E | |
| VIA-002 | Checklist viaggio, sempre. | **Microchip registrato** — Obbligatorio e impiantato prima del vaccino antirabbico. | vedi VIA-001 · `lib/logic/modules.dart:178` | ☐A ☐M ☐E | |
| VIA-003 | Checklist viaggio, sempre. | **Vaccino antirabbico valido** — Nessun antirabbico in cartella. / La prima vaccinazione è valida dopo 21 giorni; i richiami fatti in tempo valgono subito. Durata 1-3 anni secondo la scheda tecnica (ultimo: {data}). | vedi VIA-001; ricerca/07 N51 · `lib/logic/modules.dart:185` | ☐A ☐M ☐E | |
| VIA-004 | Checklist viaggio, sempre. | **Passaporto europeo per animali** — Rilasciato dal veterinario ASL o autorizzato. Regole UE: Reg. (UE) 576/2013 e successive modifiche; verifica prima di partire sul sito del Ministero della Salute. **v1.0-rc — proposta, da approvare:** Testo: «Rilasciato dal veterinario ASL o autorizzato. Regole UE: Reg. (UE) 2016/429 e Reg. delegato (UE) 2026/131, in vigore dal 22 aprile 2026; i passaporti rilasciati prima restano validi. Verifica prima di partire sul sito del Ministero della Salute.» (norma vigente; ricerca/15 §3.1 punto 1) **Approvata senza modifiche dal veterinario-revisore (ricerca/26 §3.1), da firmare (la parte normativa resta di competenza legale).** | ricerca/07 §18 · `lib/logic/modules.dart:193` | ☐A ☐M ☐E | |
| VIA-005 | Checklist viaggio, sempre. | **Trattamento contro Echinococcus** — Obbligatorio 24-120 h prima dell'ingresso in Regno Unito, Irlanda, Finlandia, Norvegia e Malta. **v1.0-rc — proposta, da approvare:** Testo: «Obbligatorio 24-120 ore prima dell'ingresso nei Paesi indenni (verifica l'elenco aggiornato con il veterinario).» (elenco dei Paesi non verificato; ricerca/15 §3.1 punto 2) **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (A8) **Trattamento contro la tenia Echinococcus** — «Va fatto da un veterinario e registrato sul passaporto 24-120 ore (da 1 a 5 giorni) prima dell'ingresso nei Paesi indenni. Verifica l'elenco aggiornato prima di partire, con il veterinario o sul sito del Ministero della Salute.» | Reg. delegato (UE) 2026/131 art. 8 · `lib/logic/modules.dart:200` | ☐A ☐M ☐E | |
| VIA-006 | Checklist viaggio, sempre. | **Rischi parassitari della destinazione** — Chiedi al veterinario: filaria, leishmania e zecche variano molto tra paesi. | — · `lib/logic/modules.dart:205` | ☐A ☐M ☐E | |
| VIA-007 | Checklist viaggio, nota in fondo. | Le regole cambiano spesso e variano per paese: verifica sempre con il veterinario e sul sito del Ministero della Salute prima di partire. | — · `lib/ui/diaries_screen.dart:912` | ☐A ☐M ☐E | |

## Parte 7 — Tabelle

### Alimenti e sostanze pericolose (schermata Nutrizione)

Ogni riga mostra: alimento — pericolo · rischio (grave, moderata, lieve). Fonte: ricerca/06 §25; `lib/logic/nutrition.dart`.

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| TOS-001 | Sempre, schermata Nutrizione. | **Xilitolo (gomme e dolci "senza zucchero", dentifricio per persone, burro di arachidi light, integratori)** — ipoglicemia e danno al fegato anche a piccole dosi · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:237` | ☐A ☐M ☐E | |
| TOS-002 | Sempre, schermata Nutrizione. | **Uva e uvetta** — insufficienza renale acuta, dose imprevedibile · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:242` | ☐A ☐M ☐E | |
| TOS-003 | Sempre, schermata Nutrizione. | **Cioccolato e cacao (più è fondente, più è pericoloso)** — teobromina: vomito, agitazione, aritmie, convulsioni · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:247` | ☐A ☐M ☐E | |
| TOS-004 | Sempre, schermata Nutrizione. | **Cipolla, aglio, porro, erba cipollina (anche cotti o in polvere)** — anemia: alterazioni del sangue da circa 5 g/kg, effetto cumulativo · rischio grave **Approvata con modifica dal veterinario-revisore (ricerca/26), da firmare:** (C4) **Cipolla, aglio, porro, erba cipollina (anche cotti, in polvere o nei sughi)** — «possono causare anemia. Già da circa 5 g di cipolla per kg di peso, cioè mezza cipolla piccola per un cane di 10 kg, e meno per l'aglio. Piccole quantità ripetute si sommano. I segni possono comparire dopo 1-5 giorni.» · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:252` | ☐A ☐M ☐E | |
| TOS-005 | Sempre, schermata Nutrizione. | **Farmaci per persone: paracetamolo, ibuprofene, naprossene, ketoprofene, aspirina** — ulcere, danno a reni e fegato, anemia · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:258` | ☐A ☐M ☐E | |
| TOS-006 | Sempre, schermata Nutrizione. | **Altri farmaci umani: antidepressivi, farmaci per ADHD, farmaci per il cuore** — agitazione, aritmie, convulsioni · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:263` | ☐A ☐M ☐E | |
| TOS-007 | Sempre, schermata Nutrizione. | **Veleni per topi (anticoagulanti, colecalciferolo)** — emorragie anche dopo 3-5 giorni; danno renale · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:268` | ☐A ☐M ☐E | |
| TOS-008 | Sempre, schermata Nutrizione. | **Lumachicidi a base di metaldeide** — tremori e convulsioni gravi in poco tempo · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:273` | ☐A ☐M ☐E | |
| TOS-009 | Sempre, schermata Nutrizione. | **Antigelo (glicole etilenico), insetticidi, bocconi avvelenati** — insufficienza renale, sintomi neurologici · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:278` | ☐A ☐M ☐E | |
| TOS-010 | Sempre, schermata Nutrizione. | **Processionaria del pino (febbraio-maggio)** — necrosi di lingua e bocca: subito dal veterinario, non strofinare · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:283` | ☐A ☐M ☐E | |
| TOS-011 | Sempre, schermata Nutrizione. | **Cannabis / THC** — barcollamento, perdita di urina, letargia · rischio moderata | ricerca/06 §25 · `lib/logic/nutrition.dart:289` | ☐A ☐M ☐E | |
| TOS-012 | Sempre, schermata Nutrizione. | **Piante: oleandro, Cycas revoluta, tasso, mughetto, azalea, ricino, bulbi** — effetti su cuore, fegato o sistema nervoso · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:294` | ☐A ☐M ☐E | |
| TOS-013 | Sempre, schermata Nutrizione. | **Funghi selvatici, alghe tossiche in acqua stagnante** — danno al fegato, sintomi neurologici · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:299` | ☐A ☐M ☐E | |
| TOS-014 | Sempre, schermata Nutrizione. | **Rospi e morsi di vipera** — salivazione, gonfiore, collasso: subito dal veterinario · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:304` | ☐A ☐M ☐E | |
| TOS-015 | Sempre, schermata Nutrizione. | **Noci di macadamia** — debolezza, tremori, febbre · rischio moderata | ricerca/06 §25 · `lib/logic/nutrition.dart:309` | ☐A ☐M ☐E | |
| TOS-016 | Sempre, schermata Nutrizione. | **Alcol e impasti lievitati crudi** — intossicazione, dilatazione dello stomaco · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:314` | ☐A ☐M ☐E | |
| TOS-017 | Sempre, schermata Nutrizione. | **Caffeina (caffè, tè, energy drink), noce moscata, luppolo** — agitazione, tachicardia, ipertermia, convulsioni · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:319` | ☐A ☐M ☐E | |
| TOS-018 | Sempre, schermata Nutrizione. | **Cibo ammuffito e compost** — tremori e convulsioni (micotossine) · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:324` | ☐A ☐M ☐E | |
| TOS-019 | Sempre, schermata Nutrizione. | **Batterie a bottone, magneti, pannocchie, noccioli, ossa cotte** — ustioni interne, ostruzioni e perforazioni · rischio grave | ricerca/06 §25 · `lib/logic/nutrition.dart:329` | ☐A ☐M ☐E | |
| TOS-020 | Sempre, schermata Nutrizione. | **Avocado** — disturbi gastrointestinali; il nocciolo causa ostruzioni · rischio lieve | ricerca/06 §25 · `lib/logic/nutrition.dart:334` | ☐A ☐M ☐E | |
| TOS-021 | Sempre, schermata Nutrizione. | **Cibi molto grassi (avanzi, fritti) e sale in eccesso** — pancreatite; vomito e convulsioni da sale · rischio moderata | ricerca/06 §25 · `lib/logic/nutrition.dart:339` | ☐A ☐M ☐E | |

### Scale di valutazione

| ID | Quando | Testo | Fonte · file:riga | Esito (A/M/E) | Note |
|---|---|---|---|---|---|
| SCA-BCS-1 | Mostrata durante la compilazione. | **Body Condition Score (1-9) — voce 1** — Emaciato: costole, vertebre e bacino visibili a distanza. | — · `lib/logic/nutrition.dart:223` | ☐A ☐M ☐E | |
| SCA-BCS-2 | Mostrata durante la compilazione. | **Body Condition Score (1-9) — voce 2** — Molto magro: costole facilmente visibili, nessun grasso palpabile. | — · `lib/logic/nutrition.dart:224` | ☐A ☐M ☐E | |
| SCA-BCS-3 | Mostrata durante la compilazione. | **Body Condition Score (1-9) — voce 3** — Magro: costole facilmente palpabili, vita evidente. | — · `lib/logic/nutrition.dart:225` | ☐A ☐M ☐E | |
| SCA-BCS-4 | Mostrata durante la compilazione. | **Body Condition Score (1-9) — voce 4** — Sottile: costole palpabili con poco grasso, vita ben visibile. | — · `lib/logic/nutrition.dart:226` | ☐A ☐M ☐E | |
| SCA-BCS-5 | Mostrata durante la compilazione. | **Body Condition Score (1-9) — voce 5** — Ideale: costole palpabili senza eccesso di grasso, vita visibile da sopra. | — · `lib/logic/nutrition.dart:227` | ☐A ☐M ☐E | |
| SCA-BCS-6 | Mostrata durante la compilazione. | **Body Condition Score (1-9) — voce 6** — Leggermente sovrappeso: costole palpabili con lieve grasso in più. | — · `lib/logic/nutrition.dart:228` | ☐A ☐M ☐E | |
| SCA-BCS-7 | Mostrata durante la compilazione. | **Body Condition Score (1-9) — voce 7** — Sovrappeso: costole palpabili a fatica, vita poco visibile. | — · `lib/logic/nutrition.dart:229` | ☐A ☐M ☐E | |
| SCA-BCS-8 | Mostrata durante la compilazione. | **Body Condition Score (1-9) — voce 8** — Obeso: costole non palpabili, nessuna vita, addome disteso. | — · `lib/logic/nutrition.dart:230` | ☐A ☐M ☐E | |
| SCA-BCS-9 | Mostrata durante la compilazione. | **Body Condition Score (1-9) — voce 9** — Obesità grave: depositi di grasso su collo, arti e base della coda. | — · `lib/logic/nutrition.dart:231` | ☐A ☐M ☐E | |
| SCA-COG-1 | Mostrata durante la compilazione. | **Checklist cognitiva (6 voci, 0-2 ciascuna) — voce 1** — Disorientamento — Si perde in casa, resta bloccato negli angoli, non riconosce persone note. | — · `lib/ui/diaries_screen.dart:1080` | ☐A ☐M ☐E | |
| SCA-COG-2 | Mostrata durante la compilazione. | **Checklist cognitiva (6 voci, 0-2 ciascuna) — voce 2** — Interazione — Cerca meno (o molto di più) la compagnia, reagisce diversamente. | — · `lib/ui/diaries_screen.dart:1084` | ☐A ☐M ☐E | |
| SCA-COG-3 | Mostrata durante la compilazione. | **Checklist cognitiva (6 voci, 0-2 ciascuna) — voce 3** — Sonno-veglia — Dorme di giorno, è sveglio o agitato di notte. | — · `lib/ui/diaries_screen.dart:1086` | ☐A ☐M ☐E | |
| SCA-COG-4 | Mostrata durante la compilazione. | **Checklist cognitiva (6 voci, 0-2 ciascuna) — voce 4** — Pulizia in casa — Sporca in casa pur essendo educato, non chiede di uscire. | — · `lib/ui/diaries_screen.dart:1089` | ☐A ☐M ☐E | |
| SCA-COG-5 | Mostrata durante la compilazione. | **Checklist cognitiva (6 voci, 0-2 ciascuna) — voce 5** — Attività — Gironzola senza scopo, lecca in modo ripetitivo, gioca meno. | — · `lib/ui/diaries_screen.dart:1093` | ☐A ☐M ☐E | |
| SCA-COG-6 | Mostrata durante la compilazione. | **Checklist cognitiva (6 voci, 0-2 ciascuna) — voce 6** — Ansia — Più pauroso, agitato quando resta solo, vocalizza. | — · `lib/ui/diaries_screen.dart:1095` | ☐A ☐M ☐E | |
| SCA-MCS-1 | Mostrata durante la compilazione. | **Massa muscolare (4 livelli) — voce 1** — Normale — Muscoli pieni su schiena, scapole, cranio e cosce. | — · `lib/ui/diaries_screen.dart:1071` | ☐A ☐M ☐E | |
| SCA-MCS-2 | Mostrata durante la compilazione. | **Massa muscolare (4 livelli) — voce 2** — Perdita lieve — Si sente un po' di più la colonna o il cranio. | — · `lib/ui/diaries_screen.dart:1072` | ☐A ☐M ☐E | |
| SCA-MCS-3 | Mostrata durante la compilazione. | **Massa muscolare (4 livelli) — voce 3** — Perdita moderata — Ossa di schiena, scapole e bacino ben palpabili. | — · `lib/ui/diaries_screen.dart:1073` | ☐A ☐M ☐E | |
| SCA-MCS-4 | Mostrata durante la compilazione. | **Massa muscolare (4 livelli) — voce 4** — Perdita grave — Ossa molto evidenti, muscoli assottigliati ovunque. | — · `lib/ui/diaries_screen.dart:1074` | ☐A ☐M ☐E | |
| SCA-PUR-1 | Mostrata durante la compilazione. | **Scala fecale Purina (1-7) — voce 1** — Molto dure e secche, a palline; richiedono sforzo | — · `lib/ui/log_sheet.dart:97` | ☐A ☐M ☐E | |
| SCA-PUR-2 | Mostrata durante la compilazione. | **Scala fecale Purina (1-7) — voce 2** — Compatte ma non dure, segmentate; raccolte non lasciano residui (ideale) | — · `lib/ui/log_sheet.dart:98` | ☐A ☐M ☐E | |
| SCA-PUR-3 | Mostrata durante la compilazione. | **Scala fecale Purina (1-7) — voce 3** — A tronchetto, umide in superficie; lasciano un segno ma restano intere | — · `lib/ui/log_sheet.dart:99` | ☐A ☐M ☐E | |
| SCA-PUR-4 | Mostrata durante la compilazione. | **Scala fecale Purina (1-7) — voce 4** — Molto umide, a tronchetto; lasciano residuo e si disfano se raccolte | — · `lib/ui/log_sheet.dart:100` | ☐A ☐M ☐E | |
| SCA-PUR-5 | Mostrata durante la compilazione. | **Scala fecale Purina (1-7) — voce 5** — Molto umide, a mucchietti con una forma riconoscibile | — · `lib/ui/log_sheet.dart:101` | ☐A ☐M ☐E | |
| SCA-PUR-6 | Mostrata durante la compilazione. | **Scala fecale Purina (1-7) — voce 6** — Consistenza presente ma nessuna forma, a mucchietti o chiazze | — · `lib/ui/log_sheet.dart:102` | ☐A ☐M ☐E | |
| SCA-PUR-7 | Mostrata durante la compilazione. | **Scala fecale Purina (1-7) — voce 7** — Liquide, senza consistenza, a pozza | — · `lib/ui/log_sheet.dart:103` | ☐A ☐M ☐E | |
| SCA-QOL-1 | Mostrata durante la compilazione. | **Qualità della vita HHHHHMM (7 voci, 0-10) — voce 1** — Dolore (Hurt) — Il dolore è controllato? Respira bene? 10 = nessun dolore | — · `lib/logic/modules.dart:214` | ☐A ☐M ☐E | |
| SCA-QOL-2 | Mostrata durante la compilazione. | **Qualità della vita HHHHHMM (7 voci, 0-10) — voce 2** — Fame (Hunger) — Mangia abbastanza? 10 = appetito normale | — · `lib/logic/modules.dart:216` | ☐A ☐M ☐E | |
| SCA-QOL-3 | Mostrata durante la compilazione. | **Qualità della vita HHHHHMM (7 voci, 0-10) — voce 3** — Idratazione — Beve abbastanza? 10 = sì | — · `lib/logic/modules.dart:217` | ☐A ☐M ☐E | |
| SCA-QOL-4 | Mostrata durante la compilazione. | **Qualità della vita HHHHHMM (7 voci, 0-10) — voce 4** — Igiene — Si mantiene pulito, niente piaghe? 10 = sì | — · `lib/logic/modules.dart:218` | ☐A ☐M ☐E | |
| SCA-QOL-5 | Mostrata durante la compilazione. | **Qualità della vita HHHHHMM (7 voci, 0-10) — voce 5** — Felicità — Interagisce, gioca, risponde? 10 = come sempre | — · `lib/logic/modules.dart:219` | ☐A ☐M ☐E | |
| SCA-QOL-6 | Mostrata durante la compilazione. | **Qualità della vita HHHHHMM (7 voci, 0-10) — voce 6** — Mobilità — Si alza e cammina da solo? 10 = sì | — · `lib/logic/modules.dart:220` | ☐A ☐M ☐E | |
| SCA-QOL-7 | Mostrata durante la compilazione. | **Qualità della vita HHHHHMM (7 voci, 0-10) — voce 7** — Più giorni buoni che cattivi — 10 = quasi tutti buoni | — · `lib/logic/modules.dart:221` | ☐A ☐M ☐E | |

---

## Firma della revisione

Ho rivisto i testi della versione v1 indicati come «Approvato» e ho annotato le modifiche richieste.

- Parti rivedute: ☐ 0 ☐ 1 ☐ 2 ☐ 3 ☐ 4 ☐ 5 ☐ 6 ☐ 7
- Nome e cognome: ______________________________
- Ordine dei Medici Veterinari della provincia di: ______________  n. iscrizione: ________
- Data: ____/____/________   Firma: ______________________________
- Consenso a essere citato nell'app («Testi rivisti da Dott./Dott.ssa … il …»): ☐ Sì ☐ No
