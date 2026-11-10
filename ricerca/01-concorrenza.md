# Zampa: analisi della concorrenza

*Ricerca svolta il 10 novembre 2026. Fonti consultate: schede App Store e Google Play, siti dei produttori, comunicati stampa, recensioni di terzi.*

## Come leggere questo rapporto

- **[F]** indica un **fatto verificato**, con l'URL della fonte. "Verificato" significa che l'ho letto nella fonte citata. Molte fonti sono schede degli store o pagine dei produttori, quindi riportano ciò che il produttore dichiara, non una prova indipendente.
- **[I]** indica una **mia inferenza** o valutazione.
- **[?]** indica un dato non confermato o contraddittorio tra le fonti.
- Prezzi e valutazioni cambiano spesso e variano da paese a paese. Le schede degli store spesso non mostrano l'anno degli aggiornamenti.

---

## 1. Sintesi in breve

1. **Prevedere la pipì non è più un'idea nuova.** Nel 2025-2026 sono uscite almeno 8-10 app che dichiarano di prevedere la prossima uscita imparando dai dati registrati: PupIQ, pupdate, Puppy Routine, Pupty, PottyPal, Puppy Potty Trainer, DogsLife, Pawpy, Pawty. **[F]** (fonti nella sezione 3)
2. **Tutte puntano sul cucciolo da educare**, quasi tutte sono solo in inglese e quasi tutte sono piccole app indipendenti con poche decine di recensioni. Nessuna che ho trovato si rivolge al **cane adulto o anziano che vive in appartamento**, né usa i dati della pipì come **segnale di salute**. **[F]/[I]**
3. **Nessuna unisce in modo convincente previsione della pipì e cartella sanitaria completa.** Le app di salute generaliste (11pets, DogLog, Doggy Time) registrano la pipì ma non la prevedono. Le app di previsione non gestiscono la salute. **[I]**
4. **In Italia l'offerta è debole e frammentata.** Ci sono app piccole o datate (Joppys, Doggami, MyLav for Pets, PawsPet, Dog Health) e i servizi pubblici (SINAC per l'anagrafe, ricetta elettronica veterinaria su VetInfo) non hanno un'app per il cittadino di livello moderno. **[F]/[I]**
5. **I collari smart misurano molto, ma non la pipì.** Tractive, Fi e Invoxia misurano parametri vitali, sonno, attività, grattamento o comportamenti, ma nessuno dichiara di rilevare la minzione. Tractive dal maggio 2026 è di proprietà dell'italiana Bending Spoons. **[F]**

---

## 2. Contesto di mercato in Italia

- **[F]** In Italia ci sono circa **9 milioni di cani** secondo il Rapporto Assalco-Zoomark 2025, all'interno di oltre 65 milioni di animali da compagnia. Fonte: https://www.panorama.it/tempo-libero/cultura/giornata-del-cane-i-dati-che-non-conosci-e-le-mete-da-sogno-per-viaggiare-insieme e il riassunto del rapporto: https://www.zoomark.it/media/zoomark/pressrelease/2025/comunicati%20stampa/Assalco_-_Zoomark_Report_2025_-_Summary.pdf
- **[F]** Il settore degli animali domestici vale circa 5,3 miliardi di euro di spesa annua. Fonte: https://quifinanza.it/lifestyle/pet-economy/animali-domestici-spesa-italia-2025/996227/
- **[F]** **Anagrafe SINAC.** È destinata a diventare l'anagrafe nazionale unica, ma nel 2026 Legambiente chiede ancora che sia resa pienamente operativa in tutte le regioni. In Piemonte, dal 10 marzo 2025, i cittadini possono fare segnalazioni online sul portale. Non ho trovato un'app nazionale per i cittadini. Fonti: https://www.regione.piemonte.it/web/temi/sanita/veterinaria-salute-alimentare/animali-compagnia-attiva-nuova-anagrafe-nazionale e https://www.legambiente.it/wp-content/uploads/2026/07/AC26_XVReport_def-1.pdf
- **[F]** **Ricetta elettronica veterinaria (REV).** È obbligatoria e gestita sul sistema VetInfo. Il proprietario usa il numero di ricetta, un PIN di 4 cifre e il codice fiscale. C'è un'app per i veterinari ("Ricetta Elettronica Vet") e una funzione "cerca ricetta" per i cittadini. Le fonti trovate sono datate (2017-2022). Fonti: https://lentepubblica.it/cittadini-e-imprese/ricetta-veterinaria-elettronica/ e https://www.corrierecomunicazioni.it/pa-digitale/e-health/ricetta-elettronica-scatta-lobbligo-per-i-veterinari-italia-prima-in-europa
- **[F]** PagoPA prevede modelli di servizio "animali domestici" erogabili tramite l'app IO dagli enti. Fonte: https://docs.pagopa.it/i-modelli-dei-servizi/ambiente-e-animali/animali-domestici
- **[I]** Non ho trovato API pubbliche di SINAC o REV utilizzabili da un'app privata. Un'integrazione diretta va quindi verificata con il Ministero e l'IZS Teramo. Nell'immediato è realistico importare il PDF o la foto della ricetta e del libretto.
- **[?]** Un'indagine ANMVI secondo cui il 35% dei cani non avrebbe il libretto aggiornato è citata solo da un sito commerciale e non l'ho potuta verificare.

---

## 3. App per il potty training e la previsione della pipì (il cuore di Zampa)

### 3.1 Le app trovate

| App | Piattaforme | Prezzo | Prevede la prossima pipì? Come | Valutazioni | Italiano | Fonte |
|---|---|---|---|---|---|---|
| **PupIQ – Puppy Potty Log** | iOS | Gratis; Premium a vita 29,99 $ | Sì. "Rileva schemi dai log", metodo non spiegato | 4,5★ (83 voti, USA) | No (solo inglese) | https://apps.apple.com/us/app/puppy-potty-log-pupiq/id6756012049 |
| **pupdate** | iPhone + Apple Watch + widget | Gratis | Sì. "Impara il ritmo" dai log; conto alla rovescia nel widget; risponde a domande sui log | n.d. | Non dichiarato | https://pupdate.app/ |
| **Puppy Routine: Potty Training** | iOS | Gratis | Sì. Finestra prevista con conto alla rovescia, **livello di confidenza e spiegazione in parole semplici** | n.d. | Non dichiarato | https://chrome-stats.com/d/id6809403926 |
| **Pupty – Puppy Potty Log** (Lionary LLC) | iOS | Gratis + Premium (4,99 $/settimana o 19,99 $/anno secondo una recensione) | Sì. "AI", conto alla rovescia, avviso 15 minuti prima | Poche (circa 100 installazioni) | n.d. | https://appgoblin.info/apps/6757993434 |
| **Puppy Potty Trainer** (Alex Sonne / Wagabond) | iPhone, iPad, Watch, Mac | 2,99 $ una tantum (0,99 $ secondo un'altra fonte) | Sì. Impara dai log, fasce orarie con confidenza, avviso 15 minuti prima | 5★ (11 voti) | n.d. | https://www.wagabondpets.com/blog/best-puppy-potty-training-apps e https://appfelstrudel.com/id/6755253203/puppy-potty-trainer.html |
| **PottyPal** | Android, iOS, web | Tutto gratis con pubblicità; 3,99 $/mese o 39,99 $/anno per toglierla | Sì. "Algoritmo che impara gli schemi", promemoria prima dell'uscita | n.d. | Non dichiarato | https://www.potty-pal.com/ |
| **DogsLife: Puppy Potty Training** | Android | n.d. | Sì, ma con dichiarazioni contraddittorie (dopo 30 giorni oppure dopo 1-2 giorni) [?] | n.d. | n.d. | https://play.google.com/store/apps/details?id=com.mrbooz.dogslife |
| **Pawpy** | Android | n.d. | "Modalità cucciolo" che prevede quando deve uscire | n.d. | n.d. | https://play.google.com/store/apps/details?id=app.pawpy |
| **Pawty App** | iOS | n.d. | Dichiara di prevedere pipì, cacca, pasti e acqua in base alle abitudini | n.d. | n.d. | https://apps.apple.com/no/app/pawty-app/id1578820198 |
| **Puddle: Puppy Potty Log** | iOS | Acquisto una tantum | Previsione basata sulle **linee guida AKC** (regola fissa, non apprendimento) | n.d. | n.d. | https://apps.apple.com/us/app/id6764225310 |
| **PuppyOnTrack** | iPhone | Gratis | **Modello generico** basato su età, peso e abitudini medie, non sui dati del cane | "Pochissimi" voti | n.d. | https://www.wagabondpets.com/blog/best-puppy-potty-training-apps |
| **Doggy Time** | iOS, Android, Watch, Wear OS | Gratis + Premium (2,99 $/mese, 19,99 $/anno, oppure 44,99-79,99 $ una tantum) | **No.** Promemoria a intervallo fisso dall'ultimo evento. Premium mostra statistiche (per esempio "quanto dopo il risveglio fa pipì") e una mappa di calore | 4,6★ iOS, 4,3★ Android | **Sì** (12 lingue) | https://www.doggytime.app/ |
| **Dogo** | iOS, Android | Premium da 3,99 $ a 99,99 $; a vita 299,99 $ | **No.** Promemoria generici | Migliaia di voti | Sì (app internazionale) | https://www.wagabondpets.com/blog/best-puppy-potty-training-apps |
| **Barksy** | iOS, Android | Da 4,99 $ a 9,99 $ a settimana; a vita 49,99 $ | **No.** Intervalli manuali da 90 minuti a 24 ore | n.d. | n.d. | idem |
| **Puppr** | iOS, Android | Circa 9,99 $/mese | **No.** Promemoria dentro un percorso di addestramento | n.d. | n.d. | idem |

### 3.2 Come fanno la previsione

- **[F]** Ci sono tre approcci:
  1. **Timer fissi o manuali:** Doggy Time, Barksy, Dogo, Puppr.
  2. **Regole generiche** per età e peso o linee guida AKC: PuppyOnTrack, Puddle.
  3. **Apprendimento dai log del singolo cane:** PupIQ, pupdate, Puppy Routine, Pupty, PottyPal, Puppy Potty Trainer.

  Fonte principale: https://www.wagabondpets.com/blog/best-puppy-potty-training-apps (agosto 2026, aggiornata settembre 2026).
- **[F]** Nessuno descrive pubblicamente l'algoritmo. Al massimo dichiarano "confidenza", "intensità dello schema", "AI", oppure "elaborazione sul dispositivo" (Sprout). La guida Wagabond parla di "statistical clustering" per Puppy Potty Trainer, ma è il blog dello stesso sviluppatore.
- **[F]** **Precisione percepita:** un recensore di PupIQ riporta circa il **50-60% di accuratezza dopo diverse settimane**. Fonte: https://apps.apple.com/us/app/puppy-potty-log-pupiq/id6756012049
- **[I]** È un segnale importante: per l'utente, una previsione sbagliata è peggio di un timer fisso, perché fa perdere fiducia. Zampa deve mostrare una **finestra** con un livello di confidenza, non un orario puntuale, e spiegare perché.

### 3.3 Lamentele ricorrenti nelle recensioni (potty e diari)

- **[F]** **Abbonamenti cari o a settimana** (Dogo "inutilizzabile senza abbonamento da 90 $", Barksy e Pupty a settimana). Fonti: https://apptail.io/app/dogo-dog-puppy-training-ghk/malta e https://www.wagabondpets.com/blog/best-puppy-potty-training-apps
- **[F]** **Funzioni utili bloccate dal pagamento**, per esempio l'esportazione in PupIQ. Fonte: idem.
- **[F]** **Mancano il registro degli "incidenti" in casa e la consistenza delle feci** (richieste ricorrenti su PupIQ). Fonte: https://apps.apple.com/us/app/puppy-potty-log-pupiq/id6756012049
- **[F]** **Perdita di dati** cambiando telefono: un recensore di DogLog dichiara di aver perso 5 anni di dati, dicembre 2025. Fonte: https://apps.apple.com/it/app/doglog-track-your-dogs-life/id1229529595
- **[F]** **Troppe notifiche e promemoria "arbitrari"** (Dogo). Fonte: https://www.wagabondpets.com/blog/best-puppy-potty-training-apps
- **[F]** **Blocchi e lentezza all'apertura**, che ritardano la registrazione (PupIQ). Fonte: https://apps.apple.com/us/app/puppy-potty-log-pupiq/id6756012049
- **[I]** Le cose apprezzate sono speculari: nessun account obbligatorio, condivisione in famiglia, esportazione, registrazione in 1-2 tocchi, widget e Apple Watch.

---

## 4. App di cartella sanitaria e diario

### 4.1 Internazionali

| App | Piattaforme | Modello | Funzioni chiave | Punti deboli | Italia / italiano | Fonte |
|---|---|---|---|---|---|---|
| **11pets** | iOS, Android, web "Business" | Freemium; acquisti da 1,99 € e 19,99 € | Libretto, vaccini, farmaci, peso, documenti, condivisione col veterinario, versione per professionisti | **2,8★ (49 voti) in Italia**; un aggregatore riporta 2,1★ su 5.700 voti; registrazione che fallisce, assistenza introvabile | Scheda iOS solo in inglese ("tornano più lingue") | https://apps.apple.com/it/app/11pets-pet-care/id1232470530 |
| **DogLog** | iOS, Android | Gratis + Premium 4,49 €/mese o 43,99 €/anno | Pasti, acqua, passeggiate, **pipì**, sonno, farmaci, vaccini, statistiche, condivisione "Pack", esportazione | Perdita di dati, assistenza lenta; **non prevede** | **Solo inglese**; 4,0★ (4 voti in Italia) | https://apps.apple.com/it/app/doglog-track-your-dogs-life/id1229529595 |
| **Doggy Time** | iOS, Android, smartwatch | Freemium | Diario completo di 50 tipi di animali, assistente AI "Tibbs", documenti con scadenze, GPS delle passeggiate | Non prevede; prezzi poco chiari; pensata soprattutto per i cuccioli | **Sì, italiano** | https://www.doggytime.app/ |
| **PetDesk** | iOS, Android | Gratis per il proprietario, pagato dalle cliniche (USA) | Promemoria, appuntamenti, storico dei farmaci della clinica | Recensioni delle cliniche: problemi con promemoria e messaggi | **Non presente in Italia** [I] | https://www.capterra.com/p/166086/PetDesk/ |
| **Pawprint → Great Pet Care** | iOS | Gratis; Premium da circa 5 $/mese [?] | Recupera i documenti dal veterinario per conto dell'utente (anche via fax), promemoria vaccini | Versione gratuita limitata a 30 giorni [?] | Solo USA [I] | https://apps.apple.com/us/app/greatpetcare/id934948619 e https://www.fiercepharma.com/r-d/pawprint-looks-to-make-its-mark-emr-based-mobile-app-for-pet-owners |
| **Dogo** | iOS, Android | Abbonamento | Addestramento, clicker, alcune funzioni di diario | Prezzo | Sì | https://apps.apple.com/au/app/id1153294767 |
| **Puppr** | iOS, Android | Abbonamento | Addestramento, registro di pipì e sonno, chat con addestratori | La parte potty è marginale | n.d. | https://apps.appfollow.io/ios/puppr-dog-training-tricks/1199338956?country=us |
| **Pet First Aid** (Croce Rossa americana) | iOS, Android | Gratis | Primo soccorso offline | Contenuti americani | No | https://www.redcross.org/about-us/news-and-events/news/2023/pet-first-aid-awareness-app.html |
| **Pelo** | Android | Gratis, niente account né abbonamento | Vaccini, farmaci, promemoria | n.d. | n.d. (aggiornata il 18 ottobre 2026) | https://play.google.com/store/apps/details?id=tomlab.pelo |

- **Pupford:** non ho trovato un'app "Pupford" con tracciamento della pipì nelle fonti consultate. Pupford è noto soprattutto come marchio di snack e corsi [?].
- **MyPet** e **Petme:** le ricerche non hanno restituito app con questi nomi rilevanti per il mercato italiano. Esistono app generiche omonime (per esempio "My Pet App for Health Tracking", https://apps.apple.com/us/app/id1576667292), ma marginali.
- **Animalia:** non ho trovato un'app con questo nome rilevante per l'Italia. "Petme" potrebbe essere confuso con **Patme.it** (servizi), che ha recensioni su Trustpilot: https://it.trustpilot.com/review/patme.it [?]

### 4.2 Italiane

| App | Chi | Funzioni | Modello | Note | Fonte |
|---|---|---|---|---|---|
| **Joppys – Pet Care** | Joppys srl, Capannori (LU) | Libretto (visite, vaccini, peso, documenti), calendario, promemoria per cure e farmaci, **diario con urine e feci**, frequenza respiratoria, ricerca di professionisti, volantino per animale smarrito | Gratis; 1,49 € per ogni animale in più; donazioni | 4,5★ (18 voti); solo iOS; solo italiano. **È il concorrente italiano più vicino**, ma senza previsione | https://apps.apple.com/it/app/joppys/id1543777185 |
| **MyLav for Pets** | MyLav srl, Alessano (LE) | Cartella clinica con **referti del laboratorio e della struttura veterinaria inviati in app**, diario sanitario, condivisione con permessi revocabili, consulti online in chat, marketplace | Gratis + servizi a pagamento (per esempio 12 € per la condivisione con la struttura) | 4,2★ (9 voti); circa 1.200 strutture affiliate secondo techprincess; problemi di registrazione | https://apps.apple.com/it/app/mylav-for-pets/id6468529251 e https://techprincess.it/mylav-for-pets-app/ |
| **Doggami** | Doggami (nata come sito di incontri tra cani) | Sezione Salute: cartella, promemoria per vaccini e visite, parametri vitali (temperatura, respiro, mucose), condivisione col veterinario | Gratis | Lanciata nel 2022; stato attuale incerto [?] | https://www.fortuneita.com/?p=274533 e https://apps.apple.com/mx/app/doggami/id1615789928 |
| **PawsPet** | n.d. | Scheda sanitaria, promemoria per vaccini e terapie, più animali | n.d. | In italiano | https://apps.apple.com/mx/app/pawspet/id6624310639 |
| **Dog Health** | n.d. | Libretto e promemoria per vaccini e antiparassitari | Gratis | Citata da Aranzulla e Quotidiano.net; nessuna valutazione trovata | https://www.aranzulla.it/app-per-cani-1022722.html |
| **MyVet / MyVetApp** | n.d. | Libretto elettronico e promemoria; aiuto sui sintomi | n.d. | Multilingue, incluso l'italiano | https://apps.apple.com/py/app/myvet/id6463804287 |
| **ZampaVet** | n.d. | Cartella clinica con diagnosi, trattamenti e prescrizioni | n.d. | **Attenzione al nome: è simile a "Zampa"** | https://apps.apple.com/ca/app/zampavet/id6469046472 |
| **Bocconi avvelenati** | Con Ministero della Salute e Istituti Zooprofilattici | Segnalazione di esche avvelenate | Gratis | Non è una cartella sanitaria, ma è un possibile partner o integrazione | https://www.smartworld.it/guide/migliori-app-per-chi-ha-cane-o-gatto.html |

- **[F]** **Catene veterinarie italiane:** non ho trovato un'app per i clienti di Ca' Zampa con accesso alla cartella clinica. Fonte: ricerca e https://medvet.unipg.it/files/orientamento_tutorato/2024/presentazione_cazampa_2024_-_uniperugia_-_student.pdf (nessuna menzione di un'app). AniCura e le altre catene non sono emerse con app italiane per i proprietari [I, non verificato a fondo].
- **[I]** **Nome:** esistono già "ZampaVet", l'app regionale lombarda "Zampa a Zampa" (2016) e la catena "Ca' Zampa". **Prima del lancio serve una verifica del marchio** (EUIPO e UIBM).

---

## 5. Collari e dispositivi smart

| Dispositivo | Cosa misura della salute | Prezzo | Italia | Fonte |
|---|---|---|---|---|
| **Tractive DOG 6 / DOG 6 XL** | GPS; **frequenza cardiaca e respiratoria a riposo** (soglia personale dopo 7 giorni); sonno, attività, abbaio; **monitoraggio del grattamento** (2026); avvisi se i valori si discostano a lungo; riassunti AI settimanali | Dispositivo da 69 €; abbonamento Basic 13 €/mese oppure 72 €/anno, Premium 96 €/anno | **Sì, sito e app in italiano.** Acquisita da **Bending Spoons** (chiusura il 18/05/2026) | https://tractive.com/it/pd/gps-tracker-dog ; https://tractive.com/blog/?p=166932 (05/2025); https://tractive.com/blog/en/press/tractive-launches-new-cat-and-dog-trackers-and-features (08/04/2026); https://tractive.com/blog/?p=191290 |
| **Fi Series 3+** | GPS; attività e sonno; rilevamento AI di **grattarsi, leccarsi, abbaiare, mangiare, bere** (accuratezza "fino all'80%" secondo il produttore) | Attivazione 20 €; abbonamento 19 €/mese, 99 €/6 mesi o 189 €/anno; minimo 6 mesi | Arrivato in UE nel marzo 2026 (38 paesi a giugno 2026) | https://www.businesswire.com/news/home/20260302231233/en/ ; https://support.fitracking.com/hc/nl-nl/articles/7048727038995 ; https://getcoai.com/news/barking-rad-ai-powered-fi-series-3-smart-dog-collar-detects-behavior |
| **Invoxia Minitailz / Biotracker 2026** | Frequenza cardiaca e respiratoria a riposo, **variabilità cardiaca**, GPS in tempo reale, attività | Circa 99 $; abbonamento circa 8-10 $/mese; in UE 3 anni inclusi secondo la pagina EU [?] | Venduto in UE (azienda francese) | https://www.invoxia.com/blog/petcare/new-biotracker-2026-edition/ ; https://invoxia.com/eu/pet-tracker |
| **Halo Collar 5** | Soprattutto recinto virtuale e addestramento; sulla salute le fonti si contraddicono [?] | Collare circa 524-999 $ più abbonamento [?] | Marginale in UE [I] | https://pawpathpicks.pages.dev/articles/tractive-dog-6-vs-fi-series-3-vs-halo-collar-5-gps-tracker-2026 |
| **Whistle** | — | — | **Chiuso il 31/08/2025** dopo l'acquisizione da parte di Tractive | https://hotairtag.pages.dev/whistle-gps-pet-trackers |
| **Furbo** (telecamera) | Avvisi AI ("Furbo Nanny") su abbaio e attività; non è una cartella sanitaria | Dog Nanny circa 6,99 $/mese (USA); piani cambiati da novembre 2025 | Sito in italiano | https://furbo.com/us/pages/furbo-nanny-updates ; https://furbo.com/eu-it/bundles |
| **Petcube** | Telecamera, **chat con il veterinario 24 ore su 24** (9,99 $/mese secondo la pagina USA) | Abbonamento | Marginale [I] | https://petcube.com/vet-chat/ |

- **[F]** **Nessuno di questi dispositivi dichiara di rilevare la minzione.** Tractive non menziona pipì, acqua o bisogni nei comunicati 2025-2026. Fi rileva "bere" e "mangiare", non la pipì.
- **[I]** È una nicchia libera: i collari hanno i dati di attività che servirebbero a dedurre le uscite (per esempio GPS fuori casa), ma non li usano per questo scopo.
- **[I]** **Opportunità:** importare da Tractive o Fi gli orari delle passeggiate tramite le loro API, se disponibili. Non l'ho verificato: Tractive non ha un'API pubblica documentata che io abbia trovato.

---

## 6. App di nutrizione e calcolo della razione

| App o strumento | Cosa fa | Modello | Fonte |
|---|---|---|---|
| **Pet Feeding Calculator** (iOS) | Calorie per peso, età e obiettivo; divisione in 2-4 pasti; secco, umido e snack in grammi, tazze o lattine | Freemium | https://apps.apple.com/us/app/id6758133817 |
| **PetCal** (iOS) | Riconoscimento AI del cibo (oltre 500 marche e cibo casalingo), conteggio delle calorie | Pro 24,99 $/anno | https://apps.apple.com/app/id6757409844 |
| **PawBuddy AI** (iOS) | Conteggio delle calorie | 69,99 $/anno | https://apps.apple.com/app/id6758735847 |
| **Dog Meal – Homemade recipes** (iOS, marzo 2026) | Ricette casalinghe generate dall'AI, con valori nutrizionali | n.d. | https://apps.apple.com/us/app/-/id6758262045 |
| **TopiBowl** (DE) | Dieta casalinga, circa 1.000 ingredienti, ricette che si adattano al cane | n.d. | https://apps.apple.com/de/app/topibowl/id6463721235 |
| **DietPaw** (web) | Fabbisogni secondo NRC 2006 e dati USDA | Gratis | https://dietpaw.pages.dev/tools/nutrition-calculator |
| **Tractive × mammaly** | Partnership per ottimizzare la salute del cane con i dati del collare (integratori) | Commerciale | https://tractive.com/blog/en/press/mammaly-tractive-partnership |

- **[F]** Diverse fonti avvertono che **calcolare le calorie non basta per una dieta casalinga completa**: il rapporto calcio/fosforo richiede un veterinario nutrizionista. Fonte: https://www.caninebible.com/?p=96244
- **[I]** Le app di nutrizione sono separate da quelle di salute. Le marche di cibo (Royal Canin, Purina) offrono calcolatori sui loro siti, legati ai propri prodotti. Zampa può integrare un calcolatore neutrale (fabbisogno a riposo RER e fabbisogno giornaliero MER, con razione in grammi dall'etichetta del cibo), **senza promettere diete casalinghe complete**.

---

## 7. Tabella comparativa finale

Legenda: ✔ presente · ◐ parziale · ✘ assente · ? non verificato

| | Cartella sanitaria | Promemoria vaccini e farmaci | Peso | Nutrizione | Registro pipì | **Previsione della pipì** | Cane adulto o anziano | Allarme salute dai bisogni | Italiano | Android + iOS + web | Modello |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Zampa (obiettivo)** | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ (apprende dai dati) | ✔ | ✔ | ✔ | ✔ | da definire |
| 11pets | ✔ | ✔ | ✔ | ◐ | ? | ✘ | ✔ | ✘ | ✘ (iOS IT) | ✔ | freemium |
| DogLog | ◐ | ✔ | ✔ | ◐ | ✔ | ✘ | ✔ | ✘ | ✘ | ◐ (no web) | abbonamento |
| Doggy Time | ◐ | ✔ | ✔ | ◐ | ✔ | ✘ (timer e statistiche) | ◐ | ✘ | ✔ | ◐ | abbonamento |
| PupIQ | ✘ | ✘ | ✘ | ✘ | ✔ | ✔ | ✘ (cucciolo) | ✘ | ✘ | ✘ (iOS) | a vita 29,99 $ |
| pupdate | ✘ | ✘ | ✘ | ✘ | ✔ | ✔ | ✘ | ✘ | ? | ✘ (iOS) | gratis |
| Puppy Routine | ✘ | ✘ | ✘ | ✘ | ✔ | ✔ (con spiegazione) | ✘ | ✘ | ? | ✘ (iOS) | gratis |
| PottyPal | ✘ | ◐ (farmaci) | ✘ | ◐ | ✔ | ✔ | ◐ | ✘ | ? | ✔ | pubblicità / 39,99 $ |
| Dogo / Puppr | ✘ | ✘ | ✘ | ✘ | ◐ | ✘ | ✘ | ✘ | ✔ / ? | ◐ | abbonamento |
| Joppys | ✔ | ✔ | ✔ | ✘ | ✔ (diario) | ✘ | ✔ | ✘ | ✔ | ✘ (iOS) | gratis |
| MyLav for Pets | ✔ (referti dal veterinario) | ✔ | ✔ | ◐ | ✘ | ✘ | ✔ | ✘ | ✔ | ◐ | servizi a pagamento |
| Tractive | ◐ (parametri vitali) | ✘ | ✘ | ✘ | ✘ | ✘ | ✔ | ◐ (parametri vitali) | ✔ | ✔ + collare | dispositivo + abbonamento |
| Fi Series 3+ | ◐ | ✘ | ✘ | ◐ (mangiare e bere) | ✘ | ✘ | ✔ | ◐ | ? | ✔ + collare | dispositivo + abbonamento |

---

## 8. Buchi di mercato

1. **Previsione della pipì per il cane adulto e anziano in appartamento.** Tutte le app di previsione trovate parlano solo di cuccioli e addestramento. Per un cane adulto il bisogno è diverso: pianificare le uscite intorno a lavoro, orari e pasti, e accorgersi se qualcosa cambia. [I, basato sulle schede di sezione 3]
2. **I bisogni come segnale di salute.** Le fonti veterinarie concordano che **i cambiamenti improvvisi della frequenza** (per esempio da 3 a 12 uscite al giorno) siano campanelli d'allarme per diabete o malattie renali. Fonti: https://www.purina.com/articles/dog/behavior/understanding-dogs/how-often-do-dogs-need-to-pee e https://paw-champ.com/journal/why-is-my-dog-peeing-so-much. **Nessuna app trovata trasforma il registro della pipì in un avviso di salute.** [F per i dati clinici, I per l'assenza nelle app]
3. **Una sola app che unisce cartella sanitaria e routine quotidiana.** Oggi chi vuole entrambe deve installare 2-3 app. [I]
4. **Italiano e contesto normativo italiano.** Le app internazionali migliori sono in inglese. Nessuna gestisce microchip e anagrafe, il libretto italiano, la ricetta elettronica veterinaria o i promemoria per la leishmaniosi e la filaria, che in Italia sono rilevanti. [I]
5. **Android e web.** Quasi tutte le app di previsione sono solo iOS. [F, sezione 3.1]
6. **Fiducia nei dati.** Perdite di dati, account che non funzionano e abbonamenti a settimana sono lamentele ricorrenti. [F, sezione 3.3]
7. **Trasparenza dell'algoritmo.** Nessuno spiega come prevede, e l'accuratezza percepita è modesta (50-60%). [F/I]

---

## 9. Cosa deve fare Zampa per differenziarsi (raccomandazioni) [I]

1. **Posizionamento:** non "un'altra app per il potty training", ma **"sappi quando deve uscire, e accorgiti se qualcosa cambia"**, per cani di tutte le età, con il cane adulto in appartamento al centro.
2. **Algoritmo di previsione onesto:**
   - mostrare una **finestra temporale** con un livello di confidenza ("tra le 13:10 e le 13:50, confidenza media") e il motivo ("di solito 40-60 minuti dopo il pranzo");
   - usare variabili come pasti, acqua, risveglio, passeggiata e giorno feriale o festivo;
   - partire con regole basate su età e peso finché i dati sono pochi, poi passare all'apprendimento sul singolo cane;
   - avvisare **prima** della finestra, non all'inizio;
   - misurare e mostrare all'utente la propria accuratezza;
   - lavorare sul dispositivo e funzionare offline.
3. **Avviso di salute dai bisogni:** segnalare scostamenti dalla soglia personale (frequenza, incidenti in casa, sforzo, colore o consistenza delle feci) con un invito a sentire il veterinario. Non deve essere una diagnosi: va formulato con cautela, senza rientrare nei dispositivi medici [I, da verificare la normativa UE].
4. **Registrazione in un tocco:** widget, smartwatch (Apple Watch e Wear OS), notifica con azioni rapide ("fatto: pipì, cacca"), registrazione vocale in italiano e **condivisione in famiglia** senza costi aggiuntivi.
5. **Cartella sanitaria pensata per l'Italia:**
   - microchip e anagrafe;
   - vaccini, compresa la rabbia per il passaporto UE;
   - antiparassitari, con calendari per filaria, zecche e leishmaniosi;
   - ricetta elettronica veterinaria (importazione di foto o PDF; in futuro, se possibile, collegamento a VetInfo);
   - esportazione in PDF per il veterinario.
6. **Peso e nutrizione:** curva del peso con condizione corporea e calcolatore della razione dall'etichetta del cibo. Niente diete casalinghe "complete" senza un veterinario.
7. **Modello di business che non irriti** (le lamentele su Dogo, Barksy e Pupty sono un monito):
   - parte gratuita generosa, con registrazione illimitata e previsione di base;
   - Premium annuale accessibile o acquisto a vita;
   - **niente abbonamenti settimanali, niente pubblicità invasiva**;
   - esportazione dei dati sempre gratuita.
8. **Affidabilità dei dati:** backup e sincronizzazione chiari, account facoltativo, esportazione completa, conformità al GDPR con server in UE.
9. **Integrazioni future:** importare le passeggiate da Tractive (ora di Bending Spoons, italiana) e Fi, la salute da Apple Health e Health Connect dove pertinente, e portali veterinari come MyLav.
10. **Nome:** verificare il marchio "Zampa" rispetto a ZampaVet, Ca' Zampa e Zampa a Zampa prima di investire nel marchio.

---

## 10. Limiti della ricerca

- Molti dati vengono da schede degli store e da aggregatori (appgoblin, marlvel.ai, subger, mwm.ai) o da blog di affiliazione. Le dichiarazioni sulle funzioni AI sono dei produttori e non sono state provate.
- Alcune pagine di Google Play non erano leggibili (DogsLife, Pawpy, PottyPal, Pelo): i dettagli vengono da snippet di ricerca.
- Non ho installato né provato le app.
- Valutazioni e prezzi differiscono tra paesi. Dove possibile ho indicato quelli italiani (in euro).
- Non ho trovato conferma dell'esistenza delle app "Petme", "Animalia", "MyPet" (in senso rilevante) né di un'app "Pupford" con tracciamento della pipì.
