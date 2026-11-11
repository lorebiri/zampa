# 21 – Voce dell'utente under 35: Luca, 28 anni, Milano

*10 novembre 2026 · prova della build web (`build/web`, 19:44-21:39) in formato telefono 400×880, dalle 22:30 alle 22:40 circa*

> Chi parla: Luca, 28 anni, sviluppatore junior in smart working. Bilocale al quarto piano senza ascensore, con la compagna. Da 10 giorni c'è Nina, Jack Russell di 12 settimane, 3,5 kg. iPhone recente; ogni giorno uso Instagram, TikTok, Strava, un'app di abitudini e Revolut. Ho anche Tractive nel carrello, lo ammetto.
>
> Cosa ho fatto: ho accettato l'avvertenza, ho creato Nina (nata il 18/08/2026, femmina, taglia piccola, Nord Italia), ho registrato una pipì "Fatta fuori" e ho girato tutte le schede: Oggi, Bisogni, Salute, Nutrizione, Profilo. Ho anche personalizzato il compagno in pixel art e aperto "Con dettagli…". Ho letto DOSSIER.md, ricerca/01 e la sezione 3.4 di ricerca/08 (prezzo). Non ho provato il cane di esempio, perché per tornarci avrei dovuto cancellare Nina.
>
> Nota per chi sviluppa: nella build che ho provato **non c'è "Account e famiglia"**. Nel codice c'è (`profile_screen.dart`, `account_screen.dart` con Apple, Google, email e codice d'invito), ma la build web è precedente, quindi su quella parte giudico i testi del codice e non l'app.

---

## 1. Prime impressioni

### I primi 30 secondi

- **Schermata "Prima di iniziare".** Un muro di testo legale su sfondo nero, con casella da spuntare e "Continua". Mi sembra il bugiardino di un farmaco. Capisco perché c'è, ma come *prima* cosa che vedo dice "app medica, attento", non "ciao Nina". **Mezzo voto boomer.** Una cosa buona c'è: "nessun account, nessun server, nessuna pubblicità" lo leggo e mi piace.
- **Benvenuto.** Zampetta, "Zampa", due pulsanti. Pulito, ma generico: potrebbe essere il template di un'app Flutter qualsiasi. Nessun cane, nessuna animazione, nessun "wow".
- **Velocità.** Una volta caricata è scattante: le schede cambiano subito e la registrazione è istantanea. Sul web il primo caricamento (canvaskit) si sente, ma su iPhone nativo non dovrebbe essere un problema.

### I primi 5 minuti

- **Modulo "Nuovo cane": il momento in cui ho pensato di chiudere.** È lunghissimo: nome, razza, nascita, peso, sesso, sterilizzazione, taglia adulta, attività, alimentazione, stato riproduttivo, sveglia, sonno, prudenza, 2 interruttori di promemoria, minuti di anticipo, meteo, microchip, veterinario, telefono, pronto soccorso h24, area geografica, allergie, patologie. **Sono 20+ campi prima di vedere il cane.** Duolingo mi fa fare la prima lezione prima ancora di chiedermi l'email.
- **Data di nascita sbagliata di default.** È "10/11/2024", cioè un cane di 2 anni. Io ho una cucciola, e il 90% di chi scarica un'app per la pipì ha un cucciolo. Il date picker di Material con la matita per scrivere a mano è da Android 2019, non da iPhone: ci ho messo tre tentativi a impostare 18/08/2026 (la prima volta il valore scritto non è stato preso). E "**Nato il**" vale anche per una femmina.
- **Dopo "Salva": il wow c'è.** Il cagnolino in pixel art su fondo verde chiaro, "Pasti 0/5", "Uscite 0/12". Ho sorriso. Ho registrato la pipì con **un tocco**: compare il cuoricino, lui scodinzola, scrive "Nina è contento: uscita fatta!" e sotto c'è un **"Esci alle 02:21"** grosso e leggibile, con finestra e motivo ("È un cucciolo: non riesce ancora a trattenerla per tutta la notte…"). **Questo è il momento migliore dell'app.**
- **Due stonature nello stesso riquadro:**
  - "Nina **sta tranquillo**", "Nina **è contento**": il cane è femmina e l'app lo sa (`lib/ui/avatar.dart:455` e `:478`). Per uno che ha appena dato un nome al suo cane è come sbagliare il nome della fidanzata;
  - prima della prima registrazione diceva "Nina sta tranquillo. Prossima uscita alle 22:33", cioè **adesso**: tranquillo e uscita immediata non stanno insieme. In più l'indicatore "Bisogno" era vuoto.
- **La snackbar "Pipì registrata alle 22:33 · Annulla" non se n'è mai andata.** È rimasta su per tutti i 7-8 minuti successivi, in tutte le schede, e copriva il pulsante flottante e il fondo delle liste. Su iOS è il tipo di bug che fa sembrare un'app "rotta".
- **"Con dettagli…"**: 24 tipi di evento, fra cui "Mammelle gonfie/calde", "Insulina", "Glicemia", "Perdite vulvari", "Ferita chirurgica". Per una cucciola di 12 settimane fa ansia: sembra la cartella di un pronto soccorso. In fondo, ben fatto, c'è "Quando: oggi 22:35" con la matita per cambiare l'ora.
- **Bisogni.** La curva delle prossime 12 ore con la linea "esci" è bella e la capisco. "Come sta imparando" è onesto ("servono almeno 4 eventi"). Ma il **"Piano consigliato di oggi (12 uscite)"**: 07:05, 08:28, 09:50, 11:13… ogni 80 minuti. Io abito al quarto piano senza ascensore: 12 uscite sono 96 rampe di scale. Forse è giusto per un cucciolo, ma presentato così fa paura. E la stessa schermata dice "Tetto massimo per età 2 h 46 min" e poi mi propone un'uscita fra 3 h 47 min: di notte va bene, ma bisogna spiegarlo lì.
- **Salute.** "12 appuntamenti consigliati", con il primo (microchip) datato oggi e la 2ª dose di vaccino a **ieri** (09/11). Quindi o sono in ritardo (ansia) o non c'entra con la realtà (sfiducia). Mi serviva prima la domanda "Quali vaccini ha già fatto?".
- **Nutrizione.** "537 kcal, ≈149 g, 5 pasti da 30 g", ma io non ho ancora detto che crocchette uso. Il numero sembra preciso ed è una stima su un alimento generico: o me lo chiedi, o me lo dici più chiaramente.
- **Profilo.** Esporta in JSON "negli appunti". Per un dev va bene, per la mia compagna no. Non c'è nessun modo di condividere il cane (in questa build).

**Cosa è "wow":** il compagno che reagisce, l'"Esci alle 02:21" con il perché, la curva, la registrazione con un tocco con "Annulla", nessun account obbligatorio, l'onestà sull'accuratezza.
**Cosa è "boomer":** l'avvertenza come prima schermata, il modulo infinito, il date picker Material, il tema scuro grigio-verde un po' spento, i blocchi di testo lunghi in "Da sapere" con le citazioni (AVSAB 2008) e i 24 sintomi.
**Cosa me la fa chiudere:** il modulo d'ingresso, se ho Nina in braccio che morde il cavo.

---

## 2. Il compagno in pixel art

- **Mi piace? Sì, molto.** È la cosa che rende Zampa diversa da 11pets e da un foglio Excel. Lo scodinzolio quando segno l'uscita è una piccola ricompensa giusta: festeggia Nina, non "me che ho fatto il compito".
- **L'editor è carino**, ma:
  - la taglia del pixel parte da "Media" anche se nel modulo ho scelto "Piccola", e i colori non tengono conto di "Jack Russell". Il primo cane che vedo **non somiglia a Nina**;
  - il mantello "Macchie" ignora il colore secondario: fa puntini grigi tipo dalmata (`avatar.dart`, `CoatPattern.macchie` usa `dark`). Per un JR bianco con macchie fulve ho dovuto ripiegare su "Pezzato";
  - il cane occupa circa metà del riquadro: in una storia Instagram resterebbe piccolo.
- **Lo condividerei nelle storie?** Oggi no, perché non c'è un pulsante. Se ci fosse, **sì**, soprattutto per i traguardi.
- **Cosa lo renderebbe irresistibile, senza trasformare la salute in un gioco:**
  1. **"Crea il tuo Nina" in 3 tocchi durante l'onboarding**, con preset per razza (Jack Russell, Labrador, Barboncino, meticcio…) e foto di riferimento. È la parte divertente: va messa *prima* del modulo noioso, non dopo;
  2. **Cartolina condivisibile 9:16** (storia IG/TikTok) con il pixel di Nina e una frase vera: "Nina: 7 giorni senza incidenti in casa", "Prima notte senza uscite", "Oggi 3 mesi". Watermark piccolo "Zampa". È anche il vostro canale di crescita gratis;
  3. **Accessori legati alla vita reale, mai alla performance**: cappottino quando a Milano fa freddo, ombrellino se piove all'ora dell'uscita, cappellino di compleanno, il "diploma" quando finisce la socializzazione;
  4. **Animazione di benvenuto** quando apro l'app di mattina (si stiracchia);
  5. **Widget con il pixel** sulla schermata di blocco (vedi sotto). È questo che lo rende "mio";
  6. **Mai** fame, tristezza o malattia del pixel per colpa mia. Va bene così com'è: lo dico perché so che qualcuno proporrà "il cane è triste se non registri". Se lo fate, disinstallo.

---

## 3. La previsione della pipì

- **Mi fido?** **Non ancora, ma mi fido più di PupIQ.** Mi fido più di uno che mi dice "Sto imparando · servono almeno 4 eventi" che di uno che dice "AI" e basta. Il motivo scritto ("È un cucciolo: non riesce ancora a trattenerla…") e "Fattori considerati: taglia piccola" sono la cosa giusta.
- **Cosa voglio vedere:**
  - **una riga di fiducia leggibile in 2 secondi**: "Su 20 uscite: 16 nella finestra (80%)", con l'andamento da una settimana all'altra. Il "±14 min" del cane di esempio è un ottimo titolo, se è vero;
  - **"Perché questo orario?"** con un tocco e 3 voci in parole semplici ("ha bevuto 20 min fa", "dopo il pasto di solito…", "di notte trattiene di più"). C'è già nei dati: va solo mostrato meglio;
  - **la verità sugli incidenti**: se segno "In casa", voglio vedere che il modello si è corretto ("Ok, anticipo di 15 min le prossime uscite");
  - **una serie (streak) solo sugli esiti buoni del cane**: "giorni senza incidenti", "notti senza uscite". Mai una streak su "hai registrato ogni giorno": se salto un giorno perché sono fuori, non voglio sensi di colpa;
  - **Live Activity / Dynamic Island**: "Prossima uscita 14:20 · tra 35 min", con barra che si riempie. **Questa da sola vale il Premium.** È il "Uber in arrivo" del mio cane;
  - **notifica con azioni rapide**: "Nina tra 10 minuti" → [Fatta fuori] [In casa] [Rimanda 15'] senza aprire l'app;
  - **widget** piccolo con pixel e orario, medio con i 2 pulsanti (iOS 17 widget interattivi);
  - **Apple Watch**: un tocco al polso mentre sono giù in cortile con il guinzaglio in una mano e il sacchetto nell'altra. Lì l'iPhone non lo tiro fuori;
  - **modalità "smart working"**: so che lavoro in casa dalle 9 alle 18. Le notifiche durante le call devono essere discrete (Focus di iOS).
- **Il piano da 12 uscite** va presentato in modo diverso: "Oggi circa 10-12 uscite: è normale a 12 settimane, a 4 mesi saranno 6-8". Con la promessa che diminuiscono, le 96 rampe le faccio.

---

## 4. Registrazione: quanti tocchi?

- **1 tocco** per pipì e cacca fuori (già così: perfetto, non toccatelo). **2 tocchi** al massimo per "in casa" o con dettagli. Oltre i 3 tocchi, non registro.
- **Dove registro davvero:**
  - nel 70% dei casi **dalla notifica** (azione rapida) o **dal widget/Live Activity**, perché sono per strada;
  - nel 20% dal **Watch**;
  - nel 10% dall'app, la sera, per correggere.
- **Mi serve "l'ho fatta 10 minuti fa"**: un pulsante "−5 / −10 / −15 min" accanto a "Fatta fuori". Ora per cambiare l'ora devo passare da "Con dettagli…" e scorrere 24 sintomi.
- **Pipì e cacca insieme** nella stessa uscita: un tocco "Entrambe".
- **"Annulla"** nella snackbar è ottimo, ma la snackbar deve sparire dopo 4 secondi (vedi bug).

---

## 5. Condivisione con la compagna, account, privacy

- **La condivisione non è un optional: è il motivo per cui la mia compagna installerebbe l'app.** Ci alterniamo: se lei porta giù Nina alle 13 e non lo segna, la previsione delle 14:30 sul mio telefono è sbagliata e la colpa è dell'app. Senza un diario condiviso **la previsione peggiora** con 2 persone.
- **Cosa mi aspetto:**
  - **Sign in with Apple** in un tocco, con l'email nascosta. Bene che nel codice ci sia; Google ed email con codice per lei che ha Android;
  - **invito con link** (iMessage/WhatsApp), non un codice da copiare a mano. Il codice di 7 giorni nel codice va bene come ripiego;
  - **chi ha fatto cosa**: "Pipì · 13:02 · Giulia". E una notifica alla persona *che è a casa*, non a tutti e due;
  - **la condivisione gratis**: il piano CEO la mette fra le funzioni gratuite e sono d'accordo. Se la mettete a pagamento, la vivo come un ricatto;
  - **account facoltativo**: perfetto così, ma proponetelo *al momento giusto* ("Vuoi che anche Giulia veda le uscite di Nina?"), non nella schermata d'ingresso.
- **Privacy:** "server in UE (Francoforte)", niente pubblicità, niente vendita di dati. **Ditelo nella scheda dello store e nell'onboarding con un'icona, non in un paragrafo.** Se in futuro userete i dati per lo studio scientifico, chiedetemelo con un opt-in chiaro: lo farei volentieri, "Nina contribuisce alla ricerca" è perfino una cosa da storia Instagram.
- **Backup:** "Esporta JSON negli appunti" non è un backup per una persona normale. Ci vuole iCloud o l'account.

---

## 6. Prezzo

**Confronto, dalla mia testa di utente** (prezzi da ricerca/01):

| App | Modello | La mia reazione |
|---|---|---|
| **PupIQ** | Gratis + a vita 29,99 $ | Prezzo onesto, ma solo inglese e "50-60% di accuratezza". A vita mi piace |
| **Puppy Routine** | Gratis | Se è gratis e spiega la finestra, è la vera concorrente "da TikTok" |
| **Pupty** | 4,99 $/settimana | Abbonamento settimanale = truffa. Disinstallo prima di finire di leggere |
| **PottyPal** | Pubblicità oppure 39,99 $/anno | La pubblicità in un'app per il cane mi irrita; 40 $ sono troppi |
| **Dogo** | Fino a 99,99 $/anno, 299,99 $ a vita | Bella e curata, ma muro di pagamento. Dopo 3 giorni l'ho tolta (ce l'ha un mio amico) |
| **Tractive** | 69 € + 72-96 €/anno | Lo pago perché è hardware e GPS: Nina scappa? La trovo. È un'altra categoria |
| **Zampa (piano)** | 24,99 €/anno · 3,99 €/mese · 59 € a vita · prova di 14 giorni | Vedi sotto |

- **Pagherei? Sì, ma solo dopo che ha funzionato su Nina per almeno una settimana.**
- **Quanto:**
  - **a vita 29-39 €** lo comprerei d'impulso il giorno in cui la previsione ci prende. **59 € a vita è sopra la soglia dell'impulso** per un cucciolo che fra 6 mesi non avrà più bisogno della previsione della pipì;
  - **annuale 19,99-24,99 €** va bene, se *nel prezzo* ci sono widget, Live Activity e Watch;
  - **mensile 3,99 €**: non lo prenderei mai (fanno 48 €/anno). Lo terrei solo come opzione "mi serve per 3 mesi di educazione": allora fate un **"Pass cucciolo" di 3 mesi a 7,99-9,99 €**, che è esattamente il mio caso d'uso.
- **Attenzione a un problema di valore:** fra 6 mesi Nina non avrà più bisogno della previsione e io disdirò. Per tenermi abbonato l'anno dopo serve dell'altro (salute, promemoria, PDF dal veterinario, peso, compagno). Detto in altro modo: **il Premium del primo anno lo vendete con la pipì, quello del secondo con la salute.**
- **Cosa mi farebbe pagare subito:**
  - Live Activity + widget interattivo + Watch dietro al Premium (è comodità vera, non sicurezza: rispetta la vostra regola);
  - prezzo "fondatori" a vita visibile già in beta;
  - un pacchetto di accessori per il pixel (ma solo estetici).
- **Cosa me la farebbe disinstallare:**
  - paywall all'avvio o prima di vedere la prima previsione;
  - qualunque abbonamento settimanale;
  - la prova di 14 giorni con rinnovo automatico non ricordato (mandatemi una notifica 2 giorni prima, come Revolut: vi amerò);
  - la condivisione con la compagna a pagamento;
  - gli allarmi di salute a pagamento (bene che il piano li tenga gratis: scrivetelo in grande, è un vantaggio di marketing).

---

## 7. Crescita: come la scoprirei e cosa me la farebbe consigliare

- **Come la scoprirei, in ordine di probabilità:**
  1. **TikTok/Reels**: un video "ho un'app che mi dice quando il mio cucciolo deve fare pipì" con lo schermo che mostra "Esci alle 14:20" e il pixel che scodinzola. 15 secondi, sottotitoli, audio di tendenza. È il formato perfetto per voi;
  2. **l'allevatore o il canile** al momento della consegna (il kit cucciolo, con QR sul libretto);
  3. **il veterinario** alla prima vaccinazione, se mi dà un foglio "scarica Zampa, poi a ogni visita mi mostri il PDF";
  4. **i gruppi di razza** su Facebook/Telegram ("Jack Russell Italia"), su Reddit (r/puppy101) e nelle chat WhatsApp delle aree cani di quartiere;
  5. **l'App Store** cercando "educazione cucciolo pipì": in italiano non c'è quasi nulla, quindi l'ASO in italiano è un vantaggio enorme.
- **Cosa me la farebbe consigliare:**
  - "**mi ha evitato una pipì sul divano**": se succede 3 volte in una settimana, lo dico a chiunque abbia un cucciolo;
  - la cartolina dei traguardi da condividere;
  - un **link d'invito per un'altra famiglia** con un vantaggio per tutti e due (es. 1 mese di Premium), senza schemi a premi aggressivi;
  - il PDF che il veterinario apprezza: se è il vet a dirmi "bella quest'app", mi fido il doppio.

---

## 8. Le mie 10 critiche, in ordine di importanza

| # | Critica | Schermata / funzione |
|---|---|---|
| 1 | **Onboarding troppo lungo**: 20+ campi (microchip, pronto soccorso h24, patologie, stato riproduttivo…) prima di vedere il cane. È il punto in cui chiudo l'app | `dog_form.dart` – "Nuovo cane" |
| 2 | **Nessuna condivisione con la compagna nella build provata.** Con 2 persone che portano fuori il cane, una previsione senza diario condiviso è sbagliata. Nel codice c'è, ma non è raggiungibile | Profilo / `account_screen.dart` |
| 3 | **Niente widget, Live Activity, Watch né azioni nella notifica**: la registrazione avviene per strada, non dentro l'app | Notifiche / sistema |
| 4 | **Il cane è sempre maschio**: "Nina sta tranquillo", "è contento", "Nato il" anche se ho scelto Femmina | `avatar.dart:455/478`, `dog_form.dart:72`, `store.dart:732` |
| 5 | **Data di nascita predefinita a 2 anni fa** e date picker Material scomodo (mi ci sono voluti tre tentativi per inserire la data). Chi ha un cucciolo deve correggerla sempre | "Nuovo cane" – Nato il |
| 6 | **La snackbar "Pipì registrata… Annulla" non scompare** e resta minuti sopra a tutte le schede, coprendo il pulsante + e il fondo delle liste | `log_sheet.dart` (SnackBar con action) |
| 7 | **Messaggi incoerenti**: "sta tranquillo. Prossima uscita alle 22:33" (cioè adesso, con l'indicatore Bisogno vuoto). Tetto per età di 2 h 46 e poi un'uscita fra 3 h 47 senza spiegare che di notte la regola cambia | Oggi (compagno) · Bisogni ("Come sta imparando") |
| 8 | **Troppo clinica per un cucciolo sano**: 24 eventi fra cui insulina, mammelle, perdite vulvari; "Da sapere" con blocchi di testo e citazioni; prima schermata = avvertenza legale. Mi fa sentire in ambulatorio, non con il cucciolo | "Con dettagli…" · Oggi "Da sapere" · avvertenza iniziale |
| 9 | **Il compagno non somiglia al mio cane al primo colpo**: taglia "Media" anche se nel modulo ho scelto Piccola, nessun preset per razza, "Macchie" ignora il colore secondario, il cane è piccolo nel riquadro, non c'è condivisione | Compagno · `avatar_editor.dart` · `avatar.dart` (macchie) |
| 10 | **Il piano di prevenzione e la nutrizione partono da ipotesi non chieste**: vaccino "2ª dose 09/11/2026" (cioè ieri) senza chiedermi cosa ha già fatto; "149 g, 5 pasti" senza sapere quali crocchette uso. Mi sento in ritardo oppure non mi fido | Salute › Scadenze · Nutrizione |

**Menzioni (bug minori):** il piano "12 uscite" con orari tipo 08:28 e 09:50 sembra fatto da una macchina (meglio arrotondare ai 5 minuti); l'esportazione "JSON negli appunti" non è un backup per persone normali; al primo tocco sul campo "Nome" l'etichetta si è sovrapposta al testo per un istante.

---

## 9. I miei 10 consigli concreti

| # | Consiglio | Schermata / funzione |
|---|---|---|
| 1 | **Onboarding in 4 schermate e 60 secondi**: nome → foto o "crea il pixel" con preset per razza → età (cursore "settimane" per i cuccioli) e peso → "Quando ha fatto l'ultima pipì?". Tutto il resto (microchip, vet, patologie, stato riproduttivo) dopo, come "completa il profilo" con una checklist e una barra di progresso | `dog_form.dart` → wizard |
| 2 | **Live Activity + widget interattivo + azioni nella notifica** ([Fatta fuori] [In casa] [Rimanda 15']) e poi Apple Watch. È la funzione da Premium che pagherei subito | iOS (ActivityKit, WidgetKit, notifiche) |
| 3 | **Famiglia gratis e in primo piano**: Sign in with Apple, invito con un link (iMessage/WhatsApp), "registrato da Giulia" su ogni evento, notifica a chi è a casa. Proporlo dopo la terza registrazione ("Chi altro porta fuori Nina?") | Profilo › Account e famiglia |
| 4 | **Genere grammaticale ovunque**: helper `d.isFemale ? 'a' : 'o'` per contento/tranquillo/Nato-Nata/sterilizzato. Costa un'ora e cambia la percezione | `avatar.dart`, `dog_form.dart`, `store.dart`, testi del modello |
| 5 | **"Fatta fuori" con orario rapido**: pressione lunga → "adesso / −5 / −10 / −15 min" e "pipì + cacca insieme". Snackbar di 4 secondi | Oggi · `log_sheet.dart` |
| 6 | **Riquadro "Quanto ci prende" in Oggi**: "Ultime 20: 16 nella finestra · ±14 min" con freccia di tendenza, "Perché questo orario?" con 3 motivi, e dopo un incidente "Ho anticipato le prossime uscite di 15 min" | Oggi · Bisogni |
| 7 | **Cartolina condivisibile 9:16** con il pixel e traguardi veri del cane (giorni senza incidenti, prima notte intera, compleanno dei mesi). Solo esiti positivi del cane, mai streak di registrazione, mai cane triste | Compagno · nuova "Condividi" |
| 8 | **Due profili d'uso: "Cucciolo" e "Salute"**. Al cucciolo sano mostrare 6-8 eventi (pipì, cacca, pasto, acqua, nanna, gioco, vomito, "qualcosa non va" → elenco completo). L'avvertenza va su una sola schermata amichevole con le 3 righe essenziali e "Leggi tutto" | "Con dettagli…" · avvertenza iniziale · "Da sapere" (schede a carosello, 2 righe + "leggi") |
| 9 | **Prezzo:** a vita a **34,99-39,99 €** (59 € è sopra l'impulso), **Pass cucciolo 3 mesi a 7,99-9,99 €**, annuale 24,99 € con widget, Live Activity e Watch. Notifica 2 giorni prima della fine della prova. Scrivere in grande "Allarmi di salute e famiglia: sempre gratis" | Paywall (ricerca/08 §3.4) |
| 10 | **Piano più umano**: "circa 10-12 uscite oggi, a 4 mesi saranno 6-8" con orari arrotondati ai 5 minuti; prevenzione che chiede prima "Cosa ha già fatto Nina?" (con la foto del libretto in futuro); nutrizione che chiede le crocchette prima di dare i grammi | Bisogni › Piano · Salute › Scadenze · Nutrizione |

---

## 10. In una frase

**La scaricherei: sì**, perché in italiano non c'è niente che mi dica "Esci alle 14:20" con un motivo e un cagnolino che scodinzola. **La pagherei: sì, ma solo dopo una settimana in cui ci prende davvero e solo per widget, Live Activity e Watch**, a vita sotto i 40 € o con un pass cucciolo; mai a settimana. **La consiglierei: non ancora**: prima voglio un onboarding da 60 secondi, la mia compagna dentro lo stesso diario e Nina chiamata al femminile. Fatte queste tre cose, la mando a tutto il gruppo "Jack Russell Milano".
