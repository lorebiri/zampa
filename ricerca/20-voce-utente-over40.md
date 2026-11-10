# 20 – La voce dell'utente over 40: Marina

*10 novembre 2026 · prova della build web (build/web) in formato telefono 400×880 · rapporto scritto "in personaggio"*

**Chi parla.** Marina, 54 anni, impiegata comunale a Bologna. Vive in appartamento senza giardino con il marito, Giorgio. Ha Otto: meticcio di 9 anni, 18 kg, un po' in carne, prende una pastiglia per l'artrosi. Ha un Android di fascia media e lo usa per WhatsApp, Facebook, la banca e poco altro. Con l'inglese non va d'accordo, si fida del suo veterinario di sempre, porta gli occhiali da vicino e sul telefono ha il carattere ingrandito.

**Cosa ho fatto davvero.**
- Ho accettato l'avvertenza e creato Otto: nome, "meticcio", 18 kg, nato nel 2017, patologie "artrosi".
- Ho segnato una pipì e guardato le schede Oggi, Bisogni, Salute (Scadenze e Cartella), Nutrizione e Profilo.
- Ho iniziato a inserire la pastiglia (Salute › Cartella › + › Farmaco).
- Poi ho cancellato tutto e provato "Prova con un cane di esempio" (Luna).

Sono note di chi sviluppa, non di Marina:
- non ho potuto provare il "testo grande" di Android, perché la versione web ignora la dimensione del carattere del browser;
- non ho visto le notifiche vere né l'accesso con Google, che in questa build non c'è;
- per queste due parti mi baso sul codice (`lib/ui/account_screen.dart`, `lib/notifications.dart`).

---

## 1. I primi 2 minuti

**Cosa ho capito subito.** "La salute del tuo cane in un posto solo: cartella sanitaria, vaccini, farmaci, nutrizione e un modello che impara quando deve uscire per la pipì e la cacca." Chiaro. I due pulsanti grandi, "Aggiungi il tuo cane" e "Prova con un cane di esempio", sono ben fatti. Mi piace che non chieda email né password.

**Cosa mi ha messo ansia.**
- **La prima schermata ("Prima di iniziare").** Prima ancora di vedere il cane leggo: gengive pallide o blu, addome gonfio, convulsioni, avvelenamento, colpo di calore. Sono testi giusti, ma è come aprire il bugiardino prima della medicina. Mi è venuto un po' di magone. E con lo sfondo nero, a quell'ora di sera, si legge a fatica.
- **"anziano" accanto al nome di Otto**, in alto, sempre. Lo so che ha 9 anni, ma leggerlo ogni volta che apro l'app mi stringe il cuore. Preferirei "senior", oppure niente.
- **L'asterisco rosso in alto a destra.** Non sapevo cosa fosse. Ho capito dal codice che sono le "Emergenze". Un pulsante rosso senza scritta mi fa paura e non lo tocco.
- **Leggendo il codice** ho scoperto che, se un giorno mi dimentico di segnare le pipì, dopo 24 ore esce un avviso rosso "SUBITO – Nessuna pipì da 24 ore… è un'urgenza" (`lib/logic/alerts.dart`). Da sola, alle 11 di sera, mi spavento. Poi mi accorgo che era solo colpa mia, e la volta dopo non ci credo più.

**Cosa mi ha confuso.**
- **La data di nascita.** Si apre un calendario su novembre 2024 e devo capire da sola che bisogna toccare "novembre 2024 ▾" per cambiare anno. Nell'elenco degli anni compaiono anche 2027-2031, anni che devono ancora venire.
- **L'età sbagliata.** Ho messo il 10/11/2017, oggi è il 10/11/2026, e l'app dice "8 anni". Otto ne fa 9 proprio oggi! Credo dipenda dal calcolo `giorni / 30,44` di `ageInMonths` (`lib/models.dart`), che arrotonda per difetto proprio nel giorno del compleanno. Se l'app sbaglia l'età del mio cane, come faccio a fidarmi delle calorie?
- **Il peso "18.0 kg"** scritto con il punto: in Italia si scrive 18,0.
- **"Dove vive: Centro Italia".** Era già scelto e io sto a Bologna. Sono Nord o Centro? Meglio chiedermi la provincia o la città.
- **La prima previsione dice "Esci alle 06:18"**, ma io ho scritto che Otto si sveglia alle 7. Sotto c'è anche "prevedi un'uscita prima di dormire o durante la notte". E chi esce di notte con un cane di 9 anni?
- **Il messaggio "Pipì registrata alle 22:33 – Annulla" non va più via.** È rimasto in basso su tutte le schede finché non ho ricaricato la pagina. In Salute copriva il pulsante "+", e così non trovavo come aggiungere la pastiglia. L'ho trovato per caso toccando il pezzettino verde che spuntava. *(Per chi sviluppa: `lib/ui/log_sheet.dart`, SnackBar con `SnackBarAction`. Nelle versioni recenti di Flutter un messaggio con azione resta fisso finché non lo si chiude: serve `persist: false` o una `duration` esplicita.)*

**Cosa mi è piaciuto.**
- Il cagnolino.
- I due pulsanti grandi "Fatta fuori / In casa".
- Il riquadro "Dose non confermata: Antinfiammatorio… non raddoppiare la successiva: chiedi al veterinario", visto sul cane di esempio. Questo sì che mi serve.
- Il piano dei vaccini già pronto con le date.
- "Da sapere" (veleni per lumache, leptospirosi): consigli utili, scritti come parlerebbe il mio veterinario.

## 2. Il cagnolino in pixel art

Mi piace, sì. Non mi sembra infantile, mi ricorda i videogiochi di mio nipote ma in modo tenero. Quando ho segnato la pipì è comparso il cuoricino con la scritta "Otto è contento: uscita fatta!" e ho sorriso. È la cosa che mi farebbe riaprire l'app.

Però:
- **Non somiglia a Otto.** Otto è nero focato con le orecchie che cadono. Il pennellino in basso a sinistra del riquadro è piccolissimo e non avevo capito che servisse a cambiargli l'aspetto. Scriveteci "Cambia aspetto".
- **Le cinque caselline grigie sotto "Bisogno"** non le ho capite. È un indicatore? Sono vuote, quindi va bene o va male?
- **Il simbolo in alto a destra nel riquadro** (un cuore, poi un occhio sul cane di esempio) non si capisce cosa voglia dire.
- **Non vorrei che diventasse un Tamagotchi** che "soffre" se non registro. Se il cagnolino diventa triste perché mi sono dimenticata, mi sento in colpa e disinstallo.
- **I "temi e accessori" a pagamento** per il cagnolino (piano CEO §3.4) non li comprerei mai. Pagherei solo se potessi fargli il mantello di Otto, e quello dovrebbe essere gratis.

## 3. Segnare pipì e cacca più volte al giorno

**Lo farei davvero?** Sinceramente, i primi 3-4 giorni sì, per curiosità. Poi la sera dimentico, Giorgio porta fuori Otto e non segna niente, e i dati diventano un colabrodo. Nel cane di esempio ci sono 10-12 registrazioni al giorno, compresa "Acqua · 250 ml": io l'acqua non la misuro, gli riempio la ciotola e basta.

**Per quanto?** Realisticamente una settimana di fila, poi solo quando c'è un problema (diarrea, beve tanto, fa la pipì in casa). A quel punto sì che la userei: per far vedere al veterinario "da martedì ha fatto 4 volte la cacca molle".

**Cosa mi farebbe smettere:**
1. gli allarmi rossi falsi quando mi dimentico di segnare;
2. dover segnare da sola, senza che anche mio marito possa farlo dal suo telefono;
3. dover aprire l'app, scorrere e cercare il pulsante (ci vorrebbe un tasto sul telefono o un widget);
4. i sensi di colpa ("Bisogno" vuoto, cagnolino triste).

**La previsione mi serve?** Poco. Otto ha 9 anni, esce alle 7, alle 13 con mio marito, alle 19 e alle 23: gli orari li decido io. A un cucciolo forse servirebbe. A me serve di più sapere se *cambia* qualcosa (fa più pipì, beve di più).

**Notifiche.** Al massimo 2-3 al giorno, e solo per cose vere:
- la pastiglia;
- il vaccino o l'antiparassitario in scadenza;
- un avviso di salute serio.

Non voglio "tra 10 minuti porta fuori Otto" quattro volte al giorno: dopo due giorni le spengo tutte, e con loro spengo anche la pastiglia. Ho visto che "Promemoria pipì" e "Promemoria cacca" sono **già accesi** quando creo il cane. Per me dovrebbero partire spenti, con una domanda gentile dopo qualche giorno. Di notte, niente notifiche (tranne la pastiglia, se l'ho chiesto io).

## 4. Leggibilità

- **Sfondo scuro.** Si apre nero perché il mio telefono è in modalità scura di sera. Le scritte grigie piccole sul nero ("Es. 12 = due volte al giorno…", "Per i cuccioli: decide fino a quando cresce…") con gli occhiali da vicino si leggono a malapena. E molti suggerimenti sono tagliati con "…", quindi non li leggo per intero nemmeno volendo.
- **Il problema più grave:** in Oggi, nel riquadro beige "Dosi da confermare", il nome del farmaco ("Antinfiammatorio · 1/2 compressa · prevista oggi 19:35") è grigio chiaro su beige. **Non si legge quasi per niente**, e anche "Saltato" è sbiadito. È proprio la cosa più importante della giornata!
- **Testo grande.** Sul web non sono riuscita a provarlo. Sul mio Android ho il carattere al 130%. Controllate che i pulsanti "Fatta fuori / In casa" e le caselle con le etichette non si sovrappongano e che le scritte non vengano tagliate.
- **Parole tecniche che non capisco o che mi spaventano:**
  - "**Body Condition Score**" (in inglese!). E il cursore 1-9 si sposta con un dito: ho messo 7 per sbaglio.
  - "**RER 612 kcal × 1.4**", "**MER**", "energia metabolizzabile", "kcal per 100 g". Sul sacco delle crocchette di Otto le kcal non le trovo, o sono scritte piccolissime.
  - "**scala Purina 1-7**". Purina è la marca delle crocchette del supermercato! Sembra pubblicità. Scrivete "consistenza: da 1 (dura) a 7 (liquida)" con i disegnini.
  - "Valore di partenza (**letteratura**)", "Eventi caduti nella **finestra**", "**Tetto massimo per età**", "probabilità nella prossima ora 0%", "Finestra probabile". Queste righe in "Come sta imparando" per me sono arabo.
  - "**WSAVA**", "**ESCCAP**", "**NRC 2006**", "**FEDIAF**", "**AAHA**". Mi fa piacere che ci siano delle basi, ma bastava scrivere "secondo le linee guida veterinarie internazionali" con un link "per saperne di più".
  - "Esporta tutti i dati (**JSON**)". Che cos'è? E finisce "negli appunti"?
  - "Leptospirosi", "core", "Prudenza delle uscite: Equilibrata, quantile…". Almeno "Equilibrata" va bene.
- **Pulsanti piccoli:**
  - il pennellino del cagnolino;
  - il simbolo di condivisione in alto a destra in Salute, che non sapevo servisse a fare il PDF per il veterinario;
  - "Annulla" nel messaggio in basso: troppo vicino ai pulsanti di sotto, ho paura di cancellare la pipì per sbaglio;
  - il "+" di Salute, nascosto dal messaggio fisso;
  - le schede "Scadenze / Cartella / Peso / Diari", che si toccano bene ma hanno la scritta piccola.
- **Moduli lunghi.** La scheda "Nuovo cane" ha più di 20 campi (prudenza, sveglia, sonno, avviso caldo, microchip, pronto soccorso h24…). Io volevo solo nome, età, peso e la pastiglia.

## 5. Fiducia e privacy

- **Mi fido dei consigli?** Dei consigli generici sì: sono prudenti e rimandano sempre al veterinario, e questo mi piace. Dei numeri no: "856 kcal al giorno" diventano "534 kcal" se sposto un cursore, e l'età di Otto era sbagliata. Le calorie le chiederei comunque al mio dottore.
- **Cosa mi serve per fidarmi:**
  1. una riga ben visibile "**Testi rivisti dal dott./dott.ssa … , medico veterinario iscritto all'Ordine di …**", con nome e cognome veri, non sigle;
  2. che me la consigli il mio veterinario, magari con un volantino in ambulatorio;
  3. sapere chi c'è dietro: "un ricercatore italiano", e un indirizzo email a cui scrivere;
  4. recensioni nel Play Store di gente normale, non di esperti.
- **Privacy.** "I dati restano solo su questo dispositivo" mi tranquillizza molto, ed è la prima cosa che ho letto con piacere. Però mi chiedo: se mi si rompe il telefono, perdo tutto? Il "backup JSON negli appunti" non lo saprei usare.
- **L'account con Google lo creerei?** Sì, se mi spiegate in una riga cosa ci guadagno: "così non perdi i dati se cambi telefono e Giorgio vede le stesse cose". Google lo uso già per tutto, una password in più no. Mai però all'avvio: deve essere facoltativo, come dice già il testo in `account_screen.dart`, e quel testo va bene.

## 6. Prezzo

- **Pagherei?** Per quello che ho visto oggi, no. Le cose che uso (vaccini, pastiglia, PDF per il veterinario) sono già gratis nel piano, e trovo giusto che lo siano.
- **Per cosa pagherei:**
  - condividere con mio marito: è già gratis, bene;
  - un PDF completo e bello da stampare per il veterinario;
  - il backup automatico, così non perdo niente;
  - un aiuto umano (una chat o un numero) se non capisco qualcosa.
- **Quanto:**
  - **una tantum fino a 15-20 €** sì, come si compra un libro;
  - un **abbonamento annuale di 24,99 € no**, mi sembra tanto per un'app (Netflix lo pago e già mi pesa);
  - al massimo **9,99-12 €/anno**, e solo con una prova gratuita senza dover inserire la carta;
  - 3,99 €/mese mai;
  - **59 € a vita è troppo**: è il costo di una visita;
  - 29-35 € a vita forse sì, se l'app me l'ha consigliata il veterinario.
- **Per cosa non pagherei mai:** la previsione della pipì (Otto esce a orari fissi), la curva delle 12 ore, le statistiche di accuratezza, i vestitini del cagnolino.
- **Cosa mi farebbe disinstallare:**
  - pubblicità;
  - allarmi falsi;
  - notifiche continue;
  - funzioni che prima erano gratis e poi diventano a pagamento;
  - la richiesta di registrarmi per forza;
  - un abbonamento che si rinnova da solo senza avvisarmi.

## 7. Cosa manca per una come me

1. **Un promemoria della pastiglia "all'italiana".** Me lo aspetto così: "una al giorno alle 8 con il pasto, mezza compressa", con un grande "**Dato ✓**" nella notifica stessa, senza aprire l'app. Oggi devo scrivere "Ogni quante ore: 24", che è un ragionamento da ospedale, e il campo si trova solo dopo aver scelto "Farmaco" nel "+" nascosto della Cartella. Servirebbe anche il conteggio delle compresse rimaste: "ne restano 5, ricompra".
2. **La condivisione con mio marito**, così che "Dato" lo segni chi la dà e l'altro lo vede. Sapere se Giorgio gliel'ha già data è il problema numero uno a casa nostra: rischiamo di dargliela due volte.
3. **"Stampa per il veterinario"** come pulsante grande e con la scritta, non un simbolo in alto. Un foglio da portare alla visita con peso, pastiglie, vaccini e cose strane delle ultime settimane.
4. **Il libretto sanitario fotografato.** Fotografo il libretto e i bollini dei vaccini invece di scriverli a mano.
5. **Il peso dal veterinario.** "Oggi pesava 17,6": un grafico semplice che mi dica "bravo Otto, sta calando".
6. **Le cose da anziano/artrosi:** "oggi zoppica?", "ha fatto fatica con le scale?", e una tabellina dolore/mobilità da far vedere al veterinario. Ho visto che esiste un "diario anziano" in "Diari", ma non l'avrei mai trovato.
7. **Un aiuto:** un numero, una mail o almeno una pagina "Come si fa" con 5 domande e risposte e le figure. E un video di un minuto per iniziare.
8. **Una modalità semplice.** All'inizio una domanda "Vuoi la versione semplice?": solo pastiglia, vaccini, peso e "è successo qualcosa", senza curve, finestre e probabilità.
9. **La data di nascita in versione facile:** "Età circa: 9 anni" con i pulsanti + e −, invece del calendario.
10. **Un tema chiaro** e caratteri più grandi scelti dentro l'app.

## 8. Le mie 10 critiche (dalla più importante)

| # | Critica | Dove |
|---|---|---|
| 1 | Il nome della pastiglia nel riquadro "Dosi da confermare" è grigio chiaro su beige e quasi non si legge, ed è la cosa più importante della giornata | Oggi › "Dosi da confermare" |
| 2 | Il messaggio "Pipì registrata alle… Annulla" non sparisce mai: resta su tutte le schede e copre il pulsante "+" | `log_sheet.dart`; Salute › Cartella (il "+" nascosto) |
| 3 | Se mi dimentico di segnare, dopo 24 ore arriva un allarme rosso "SUBITO… è un'urgenza": mi spavento per niente e poi non mi fido più | `alerts.dart`, "Nessuna pipì da N ore" |
| 4 | Il promemoria della pastiglia è difficile da trovare e da impostare ("Ogni quante ore"), e manca il "Dato" dalla notifica | Salute › Cartella › + › Farmaco |
| 5 | Troppe parole tecniche o in inglese: Body Condition Score, RER, kcal per 100 g, scala Purina, finestra, letteratura, JSON, WSAVA/ESCCAP | Nutrizione, Bisogni › Come sta imparando, Profilo, Registra › Cacca |
| 6 | L'età di Otto è sbagliata (8 anni invece di 9 nel giorno del compleanno) e il peso è scritto all'inglese (18.0) | Intestazione Oggi, Profilo (`ageInMonths`) |
| 7 | Registrare tutto (anche l'acqua in ml) è troppo lavoro, e da sola non lo reggo più di una settimana | Oggi › "Registra con un tocco"; cane di esempio |
| 8 | La prima schermata elenca emergenze terribili prima ancora di cominciare, e c'è un'icona rossa senza nome | "Prima di iniziare"; asterisco in alto a destra in Oggi |
| 9 | La scheda "Nuovo cane" è lunghissima e il calendario per la nascita è scomodo (e permette anni futuri) | Nuovo cane |
| 10 | Il tema scuro e i suggerimenti grigi piccoli e tagliati con "…" sono faticosi per chi ha la vista calata | Tutta l'app, specie i testi d'aiuto dei moduli |

## 9. I miei 10 consigli concreti

| # | Consiglio | Dove |
|---|---|---|
| 1 | Riquadro della dose: testo nero o marrone scuro su beige, nome del farmaco grande e pulsanti "Data ✓ / Saltata" grandi e colorati. Verificate il contrasto almeno AA (4,5:1) | Oggi › Dosi da confermare |
| 2 | Far sparire il messaggio di conferma dopo 4-5 secondi (`persist: false` / `duration`) e spostare "Annulla" lontano dai pulsanti di navigazione | `log_sheet.dart` |
| 3 | Prima di un allarme "SUBITO" per mancanza di registrazioni, mandare una domanda gentile ("Non vedo pipì da ieri sera: ti sei dimenticata di segnarla, o Otto non l'ha fatta davvero?") con due pulsanti, e passare al rosso solo se rispondo "non l'ha fatta" | Allarmi pipì/cacca mancanti |
| 4 | Una procedura guidata "Ha una terapia?" alla creazione del cane, con le scelte "1 volta al giorno / 2 volte al giorno / a giorni alterni", l'orario, "Dato" direttamente nella notifica, le compresse rimaste e la condivisione con il marito | Nuovo cane; notifiche farmaci |
| 5 | Riscrivere i termini tecnici in italiano semplice: "Forma fisica: magro / giusto / in carne / grasso" con disegnini; "Cacca: dura / normale / molle / liquida"; niente "Purina"; le sigle solo in "Per saperne di più" | Nutrizione, Registra cacca, Bisogni, Profilo |
| 6 | Correggere il calcolo dell'età con gli anni compiuti per calendario e scrivere i numeri all'italiana (18,0 kg) | `models.dart`, tutta l'app |
| 7 | Aggiungere una "modalità semplice" proposta al primo avvio (pastiglia, vaccini, peso, "è successo qualcosa"), con la previsione delle uscite e i promemoria pipì/cacca spenti di partenza e attivabili dopo | Benvenuto; Nuovo cane › Promemoria |
| 8 | Nella prima schermata una frase rassicurante più l'elenco delle emergenze ripiegabile ("Quando correre dal veterinario ›"); scrivere "Emergenze" sotto l'icona rossa; usare "senior" invece di "anziano" | Prima di iniziare; intestazione Oggi |
| 9 | Nuovo cane in 3 passi corti (nome e foto/aspetto, poi età con +/−, peso, poi "altro facoltativo"); scegliere la città invece di "Centro Italia"; vietare le date future | Nuovo cane |
| 10 | Tema chiaro per impostazione predefinita, scelta "Testo più grande" dentro l'app, nessun suggerimento tagliato con "…", e un pulsante grande con la scritta "Stampa per il veterinario" | Tema in `main.dart`; Salute (icona condividi) |

---

## In una frase

**La scaricherei sì,** se me la consiglia il mio veterinario, per la pastiglia, i vaccini e il foglio da portare alla visita. **Non la pagherei** a 24,99 €/anno: al massimo 15-20 € una volta sola, o 10 €/anno se ci sono il backup e la condivisione con mio marito, perché la previsione della pipì a un cane di 9 anni con orari fissi non serve. **La consiglierei** alle amiche con il cucciolo, ma per ora non alle amiche della mia età. Prima va resa più semplice e leggibile, e bisogna togliere gli allarmi che spaventano quando ci si dimentica di segnare.
