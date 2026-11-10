# Zampa: funzionalità oltre il nucleo e roadmap

*Rapporto di product strategy. Data: 10 novembre 2026. Mercato: Italia, poi UE.*

Nucleo già deciso (qui non si rivaluta): cartella sanitaria (vaccini, antiparassitari, farmaci, visite, esami, allergie, microchip, peso), promemoria, nutrizione (fabbisogno calorico, razioni, pasti), tracker pipì/cacca con previsione della prossima uscita.

Convenzione: **[F]** indica un fatto con una fonte citata. **[I]** indica una mia inferenza o valutazione, senza fonte diretta. Le difficoltà sono pensate per un team Flutter piccolo con un backend (per esempio Supabase o Firebase).

---

## 1. Contesto: i fatti che cambiano le scelte

### 1.1 Integrazioni pubbliche italiane (SINAC, anagrafi regionali, REV)

- **[F]** La ricetta elettronica veterinaria (REV) è obbligatoria dal 16 aprile 2019 (L. 167/2017 art. 3, modificata dalla L. 108/2018). I web service REST del Sistema Informativo Nazionale della Farmacosorveglianza sono documentati, ma servono ai **gestionali delle strutture veterinarie**. Per collegarsi, il gestionale va autocertificato e usa l'autenticazione forte del veterinario (OAuth2 e id-sessione). Fonti: [certifico.com, ricetta veterinaria elettronica](https://www.certifico.com/news/new-generali/ricetta-veterinaria-elettronica); [Regione Piemonte, processo di autocertificazione dei gestionali](https://servizi.regione.piemonte.it/media/3334/download); [FNOVI, autenticazione forte Vetinfo](https://fnovi.it/sites/default/files/Autenticazione%20forte%20vetinfo_signed.pdf).
- **[F]** SINAC (anagrafe nazionale degli animali da compagnia, su vetinfo) offre una ricerca pubblica del detentore a partire dal microchip a 15 cifre. Le funzioni per il proprietario (denuncia di smarrimento, furto o ritrovamento) risultano attive per i soli residenti in Piemonte. Fonti: [Regione Veneto, anagrafe canina](https://www.regione.veneto.it/web/rete-degli-urp-del-veneto/anagrafe-canina); [ASL VCO](https://www.aslvco.it/?p=142459); [Agenda Digitale, SINAC e nodi privacy](https://www.agendadigitale.eu/cultura-digitale/sinac-lanagrafe-degli-animali-da-compagnia-opportunita-e-nodi-privacy/).
- **[F]** Dal 1° luglio 2026 anche i gatti vanno registrati in SINAC, con sanzioni da 150 a 900 euro ([my-personaltrainer.it](https://www.my-personaltrainer.it/mypet/gatti-scattano-nuovi-obblighi-e-multe-pesantissime-per-i-proprietari.html)). Il fondo per le spese veterinarie (DM 30/04/2025) richiede che l'animale sia registrato in SINAC o in una banca dati regionale ([DM su fiscoetasse.com](https://www.fiscoetasse.com/files/20395/dm-salute30042025spese-veterinarie.pdf)).
- **[I]** **Non ho trovato API pubbliche per app di terze parti rivolte al proprietario**, né per SINAC né per la REV né per le anagrafi regionali. Le interfacce esistenti sono riservate a veterinari, ASL e gestionali accreditati. Conseguenza: per l'MVP l'integrazione "vera" non è fattibile. Si può fare (a) un deep link alla ricerca pubblica del microchip, (b) l'inserimento manuale o via OCR dei dati della REV (numero di ricetta, PIN, farmaco, posologia), (c) un'interlocuzione con il Ministero o vetinfo nel medio periodo. Da verificare con una richiesta formale a vetinfo prima di escluderla del tutto.

### 1.2 Viaggi UE: il quadro normativo è cambiato nel 2026

- **[F]** Dal 22 aprile 2026 il Reg. (UE) 576/2013 non si applica più. I movimenti non commerciali di cani, gatti e furetti sono regolati dal **Reg. delegato (UE) 2026/131** e dalle modifiche al 2020/688 (Reg. delegato 2026/133). L'impianto resta lo stesso: microchip conforme, antirabbica a partire da 12 settimane di età, validità dopo 21 giorni dal ciclo primario; il ciclo riparte da zero se il richiamo arriva dopo la scadenza. Per Irlanda, Malta e Finlandia serve il trattamento anti-Echinococcus da 1 a 5 giorni prima dell'ingresso, annotato sul passaporto. Fonti: [EUR-Lex 2026/132](https://eur-lex.europa.eu/eli/reg_del/2026/132/oj); [FVE/UEVP](https://uevp.fve.org/news/new-eu-pet-travel-rules-enter-into-force); [EASVO](https://easvo.fve.org/from-22-april-2026-new-rules-for-the-non-commercial-movement-of-dogs-cats-and-ferrets-will-apply/); [ildiritto.it](https://ildiritto.it/amministrativo/animali-da-compagnia-le-regole-per-spostarli-in-ue/); [sicurauto.it](https://www.sicurauto.it/news/codice-della-strada/viaggiare-con-cani-e-gatti-nuove-regole-ue-dal-22-aprile-2026-cosa-cambia/).
- **[F]** Le fonti secondarie non concordano del tutto sulla numerazione degli atti collegati (2026/131, 2026/132, 2026/133). L'elenco dei Paesi terzi (Reg. di esecuzione 2026/636) è già stato modificato ([zoovettravel.com](https://zoovettravel.com/atlas/union-europea-it.html)). **[I]** La logica "viaggi" va quindi tenuta in tabelle di regole aggiornabili lato server, non scritta nel codice, e va riverificata su EUR-Lex prima dello sviluppo.

### 1.3 Regolamentazione: dispositivo medico, AI Act, GDPR, telemedicina

- **[F]** Il Regolamento UE sui dispositivi medici (MDR 2017/745) riguarda solo l'uso umano. I dispositivi solo veterinari non richiedono la marcatura CE come dispositivi medici ([Maven, veterinary medical devices in Europe](https://www.mavenrs.com/blog/veterinary-medical-device-registration-europe-guidelines-compliance)). **[I]** Un software veterinario con "red flags" non è quindi un dispositivo medico ai sensi dell'MDR. Resta però il rischio di responsabilità civile e di esercizio abusivo della professione se l'app "diagnostica".
- **[F]** Secondo fonti secondarie, l'IA veterinaria non rientra nelle categorie ad alto rischio dell'AI Act. Restano gli obblighi di trasparenza per i chatbot che interagiscono con persone, cioè dichiarare di essere un'IA ([First AI Movers](https://articles.firstaimovers.com/articles/ai-governance-veterinary-animal-health-smes-eu-2026/); [Orrick](https://www.orrick.com/en/Insights/2024/09/The-EU-AI-Act-What-Life-Sciences-and-Digital-Health-Companies-Should-Know)). Da verificare sul testo dell'AI Act (art. 50).
- **[F]** GDPR e Codice privacy non si applicano agli animali, ma ai dati del proprietario sì. Le coordinate GPS non sono considerate anonime ([lentepubblica.it](https://lentepubblica.it/?p=413821); [Kippy privacy policy](https://www.kippy.eu/res/uploads/Kippy_Privacy_Policy_it.pdf)). **[I]** I dati sanitari del cane non sono "categorie particolari" (art. 9), ma diventano dati personali perché legati a una persona. Orari di uscita, posizioni delle passeggiate e indirizzo del veterinario rivelano abitudini e luogo di residenza. Rischio di stalking o furto (assenza da casa) con la condivisione e la community.
- **[F]** FNOVI ha linee guida sulla telemedicina veterinaria. Riconoscono che manca una definizione normativa e ribadiscono che la responsabilità e l'appropriatezza restano in capo al medico veterinario ([FNOVI, Telemedicina](https://mail.fnovi.it/sites/default/files/Telemedicina.pdf)).

### 1.4 Dati clinici utili per le "red flags"

- **[F]** Nel cane la polidipsia si definisce come assunzione sostenuta di acqua oltre 100 ml/kg/giorno. Il valore normale è circa 40-60 ml/kg/giorno, con una zona grigia tra 60 e 100. Cause frequenti: diabete mellito, Cushing, insufficienza renale cronica. Esiste anche una polidipsia psicogena ([AKC](https://www.akc.org/expert-advice/health/why-is-my-dog-drinking-so-much-water/); [Elwood Vet](https://www.elwoodvet.net/increased-thirst-and-urination); [Whole Dog Journal](https://www.whole-dog-journal.com/health/what-causes-excessive-thirst-and-urination-in-dogs/)).
- **[I]** Zampa ha un vantaggio unico: il tracker pipì produce già una **baseline individuale** della frequenza. Un aumento persistente rispetto alla baseline (per esempio +50% su 7 giorni, soglia da validare con veterinari) è un segnale utile da girare al veterinario. Va presentato come "variazione da segnalare", mai come diagnosi.

### 1.5 Ambiente, stagionalità, caldo

- **[F]** Leishmaniosi: i flebotomi adulti sono attivi soprattutto da giugno a ottobre, a volte anche in autunno. La malattia, storicamente centro-meridionale e costiera, si è estesa al Nord (Emilia-Romagna, Piemonte, Valle d'Aosta, Lombardia, Veneto, Trentino, Friuli). Il 21/05/2026 è stato adottato in Conferenza Stato-Regioni un nuovo piano nazionale di controllo ([AUSL Modena](https://www.ausl.mo.it/media/leismhania_agg_2013-1.pdf); [Regione Piemonte 2026](https://www.regione.piemonte.it/governo/bollettino/abbonati/2026/31/attach/dda1400000485_11200.pdf); [greenme.it](https://www.greenme.it/pet/cani/leishmaniosi-cani-come-prevenire/)).
- **[F]** Processionaria del pino: il periodo di massimo rischio va da fine febbraio a fine aprile, a seconda della quota e del clima. Il DM 30/10/2007 sulla lotta obbligatoria è stato abrogato dal DM 6/12/2021 ([ATS Insubria](https://comuneolgiateolona.it/sites/default/files/2023-03/ATS_Insubria_REGISTRO_UFFICIALE_2023_0000955.pdf); [Regione VdA](https://regione.vda.it/allegato.aspx?pk=44887)).
- **[F]** Studi VetCompass (RVC) sul colpo di calore: il 74% dei casi è da sforzo (passeggiate, gioco), più di quelli in auto. I brachicefali sono più a rischio e hanno una mortalità circa 3 volte superiore. La temperatura media dei casi era 16,9 °C ([PubMed 32751913](https://pubmed.ncbi.nlm.nih.gov/32751913/); [BVA](https://www.bva.co.uk/news-and-blog/blog-article/dogs-die-in-hot-cars-and-on-hot-walks-new-evidence-on-heat-related-illness-in-uk-dogs/); [vetsurgeon.org](https://vetsurgeon.org/b/veterinary-news/posts/study-reveals-most-common-cause-of-heatstroke-in-dogs)).
- **[I]** L'avviso caldo non deve essere una soglia fissa di temperatura. Deve pesare razza (brachicefalo), peso, età, umidità, ora del giorno e tipo di attività. È un ottimo abbinamento con la previsione della prossima uscita: "la prossima uscita prevista è alle 14: 31 °C, anticipa alle 7:30".

### 1.6 Ecosistema tecnico

- **[F]** Tractive (il collare GPS più diffuso in Europa) **non ha un'API pubblica documentata**. Esistono solo client non ufficiali, che possono rompersi in qualsiasi momento, e un'integrazione ufficiale con Homey ([Home Assistant, integrazione Tractive](https://www.home-assistant.io/integrations/tractive/); [repo non ufficiale](https://github.com/dominique-boerner/unofficial-tractive-rest-api); [Tractive blog](https://tractive.com/blog/en/tech/do-pet-trackers-integrate-with-smart-home-devices)).
- **[F]** HealthKit non ha tipi di dato per gli animali. Le app per animali registrano le passeggiate come allenamenti del proprietario ([PawKeep](https://apps.apple.com/us/app/id6761656742); [PetAssistant](https://apps.apple.com/se/app/petasssistant/id1110083343)). Non ho trovato una fonte Apple ufficiale che lo escluda esplicitamente; da confermare sulla documentazione.
- **[F]** In Flutter le Live Activity si fanno con pacchetti come `live_activities`. Serve comunque un'estensione Widget scritta in Swift, iOS 16.1 o successivo, e non funzionano nel simulatore. Su Android ci sono le notifiche "ongoing" o le Live Updates di Android 16 ([pub.dev live_activities](https://pub.dev/packages/live_activities/versions/2.5.0); [pub.dev live_activity_kit](https://pub.dev/packages/live_activity_kit); [flutter_activity_kit](https://pub.dev/packages/flutter_activity_kit)).
- **[F]** Detrazione delle spese veterinarie (730/2026): 19% sulla parte tra 129,11 e 550 euro, cioè al massimo circa 80 euro. Il limite è per contribuente, non per animale. Servono pagamento tracciabile e documento "parlante" ([QuiFinanza](https://quifinanza.it/fisco-tasse/modello-730-2026-spese-veterinarie-limite-massimo/975901/); [Money.it](https://www.money.it/detrazione-spese-veterinarie-730-2026-limiti-istruzioni)).
- **[F]** Concorrenti in Italia: 11pets (cartella e condivisione con il veterinario), The Dog Diary, Doggami (multi-cane, condivisione con il veterinario), Teradog, Joppys. Dogo è un'app di addestramento ([macitynet](https://www.macitynet.it/The-Dog-Diary-lapp-per-chi-ama-il-proprio-cane/); [App Store Joppys](https://apps.apple.com/it/app/joppys/id1543777185); [App Store Doggami](https://apps.apple.com/mx/app/doggami/id1615789928)). **[I]** Nessuno di quelli trovati combina il tracker delle uscite con la previsione e i segnali sanitari derivati: è questo il differenziale da difendere.
- **[F]** I symptom checker AI per animali si moltiplicano e si dichiarano "educativi, non diagnostici". Gli studi indipendenti ne trovano un'accuratezza disomogenea. Gli assicuratori li stanno adottando, per esempio Joii/Vet-AI nel Regno Unito ([Computer Weekly](https://www.computerweekly.com/news/366632710/Pet-insurers-fuel-AI-take-up-in-veterinary-sector); [IJACSA 2026](https://thesai.org/Downloads/Volume17No8/Paper_100-Evaluating_AI_Based_Veterinary_Symptom_Assessment_Chatbots.pdf)).
- **[F]** Scala di qualità della vita HHHHHMM (Villalobos): 7 voci da 0 a 10. Sotto circa 35 la situazione va discussa con il veterinario. L'autrice stessa la definisce uno strumento di conversazione, non diagnostico ([Merck Vet Manual](https://merckvetmanual.com/multimedia/table/the-hhhhhmm-scale); [DoveLewis PDF](https://dovelewis.org/sites/default/files/resource-files/Canine%20QOL%20Scale%20formatted.pdf); [Tufts](https://tuftsyourdog.com/?p=6137)).

---

## 2. Schede delle funzionalità

Legenda: **Valore** = beneficio per l'utente. **Diff.** = difficoltà tecnica. **Rischi** = privacy, responsabilità medica e regolamentazione. **Priorità** = MVP / v1.x / v2 / futuro.

### A. Condivisione e collaborazione

| # | Funzionalità | Valore | Diff. | Rischi | Priorità |
|---|---|---|---|---|---|
| A1 | **Multi-utente famiglia** (co-proprietari con pari diritti; log pipì/pasti di chiunque, sincronizzati) | Altissimo. Il tracker e la previsione funzionano solo se registra chi porta fuori il cane, e in famiglia sono più persone. Evita doppi pasti e doppie dosi di farmaco. | Media (sync, conflitti, inviti, ruoli) | GDPR: chi è titolare dei dati condivisi; revoca dell'accesso; dati di un minore in famiglia | **MVP** |
| A2 | **Accesso temporaneo dog sitter / pensione** (link o QR con scadenza; vede istruzioni, pasti, farmaci, contatti d'emergenza; può registrare uscite) | Alto | Media | Minimizzazione: niente indirizzo né storico oltre il necessario; scadenza automatica | v1.x |
| A3 | **Condivisione con il veterinario** (link in sola lettura a tempo, o PDF; il veterinario non deve installare nulla) | Alto | Bassa con link e PDF; alta con un portale veterinario | Link indovinabili: token lunghi e scadenza. Nessuna responsabilità aggiuntiva per Zampa | Link e PDF **MVP**; portale veterinario v2 |
| A4 | **Export PDF della cartella clinica** (riepilogo per una nuova visita, vaccini, terapie, allergie, curva del peso, grafico pipì) | Alto: è la "moneta" con cui l'utente parla al veterinario | Bassa (pacchetto `pdf` di Dart) | Il PDF esce dal controllo dell'app: avvertenza sul contenuto | **MVP** |
| A5 | **Export dati completo (JSON/CSV) e cancellazione account** | Medio per l'utente; obbligatorio per GDPR (artt. 17 e 20) | Bassa | Obbligo legale | **MVP** |

### B. Documenti, burocrazia, integrazioni pubbliche

| # | Funzionalità | Valore | Diff. | Rischi | Priorità |
|---|---|---|---|---|---|
| B1 | **Archivio documenti** (foto e PDF di referti, libretto, fatture; collegati a una visita) | Alto | Bassa | Archiviazione cifrata; i documenti contengono nome, indirizzo e codice fiscale del proprietario | **MVP** |
| B2 | **OCR di libretti, etichette vaccinali e referti** (on-device con ML Kit o Vision; estrae data, prodotto, lotto, scadenza; l'utente conferma) | Alto: elimina l'attrito dell'inserimento iniziale, che è il punto in cui queste app perdono utenti | Media per le etichette vaccinali; alta per i referti di laboratorio (formati eterogenei, unità di misura) | Errori di estrazione con conseguenze (data del richiamo sbagliata): sempre conferma umana. OCR in cloud o LLM = trasferimento di dati personali, da mettere nell'informativa | Etichette e libretto **v1.x**; referti v2 |
| B3 | **Passaporto europeo e assistente viaggi** (checklist per Paese: antirabbica valida, 21 giorni, Echinococcus 1-5 giorni prima per IE/MT/FI; promemoria a ritroso dalla data di partenza) | Alto per una parte degli utenti; molto distintivo in UE | Media (motore di regole aggiornabile lato server) | Normativa cambiata ad aprile 2026: un errore = cane respinto alla frontiera. Disclaimer "verifica con l'ASL" e data dell'ultimo aggiornamento delle regole | v1.x (Paesi UE); Paesi terzi v2 |
| B4 | **Microchip e anagrafe**: campo microchip con validazione (15 cifre, ISO 11784/11785), link alla ricerca pubblica SINAC, guida regione per regione per il cambio di residenza o proprietà | Medio | Bassa | Nessun accesso a banche dati; solo link | **MVP** (campo, nel nucleo) + link v1.x |
| B5 | **Integrazione diretta SINAC / anagrafi regionali** | Alto in teoria | Alta / **non fattibile oggi**: nessuna API per terzi trovata | Accreditamento istituzionale | futuro (dopo un contatto con Ministero/vetinfo) |
| B6 | **REV**: registrazione della ricetta (numero e PIN, farmaco, posologia) con OCR del promemoria cartaceo o della mail, poi piano terapeutico e promemoria delle dosi | Alto per terapie lunghe | Media | Non si integra con il sistema REV (riservato ai gestionali). Responsabilità: l'app ricorda, non prescrive | v1.x (manuale + OCR); integrazione futuro |
| B7 | **Spese veterinarie e detrazione 730** (registro spese per contribuente, totale annuo, export per il CAF, avviso "documento non parlante") | Medio-alto in Italia; nessun concorrente trovato lo fa | Bassa | Dati fiscali del proprietario: minimizzazione | v1.x |
| B8 | **Assicurazione animali** (polizza, massimali, rimborsi, export documenti per sinistri) | Medio | Bassa (manuale); alta (integrazione con l'assicuratore) | Nessun rischio rilevante se resta manuale | v2; partnership futuro |

### C. Salute proattiva e "red flags"

| # | Funzionalità | Valore | Diff. | Rischi | Priorità |
|---|---|---|---|---|---|
| C1 | **Segnali di cambiamento dal tracker** (frequenza della pipì sopra la baseline personale, notti con uscite, feci anomale (scala di consistenza fecale da 1 a 7), assenza di feci > 48 h). Messaggio: "variazione rispetto al solito di Fido, valuta di sentire il veterinario" | Altissimo e **unico**: sfrutta i dati del nucleo | Media (statistica sulla baseline, soglie prudenti) | **Responsabilità medica**: mai nominare malattie nel messaggio principale; nessun "va tutto bene"; soglie validate con veterinari; registro delle soglie per audit. Non è un dispositivo medico (MDR solo uso umano) | **MVP** (versione semplice: 2-3 regole) |
| C2 | **Diario acqua e appetito** (ciotola misurata, o "ha bevuto di più/meno") per calcolare ml/kg/giorno rispetto alla soglia di 100 ml/kg/giorno | Alto in combinazione con C1 (pipì + sete = diabete/Cushing/rene) | Bassa | Come C1 | v1.x |
| C3 | **Diario sintomi** (vomito, diarrea, tosse, zoppia, prurito, foto, video) con timeline da mostrare al veterinario | Alto | Bassa | Video e foto possono contenere persone: informativa | **MVP** (versione base) |
| C4 | **Triage "quando andare subito dal veterinario"**: lista statica e curata di sintomi d'emergenza (dilatazione-torsione gastrica, avvelenamento, colpo di calore, difficoltà respiratoria, sforzo senza urinare) con il numero del pronto soccorso veterinario più vicino | Molto alto quando serve | Bassa (contenuto) + media (mappa pronto soccorso) | Contenuto revisionato da veterinari, con data di revisione | v1.x |
| C5 | **Andamento del peso e del Body Condition Score** collegato alla nutrizione (allarme per perdita di peso non voluta > 10%) | Alto | Bassa | Come C1 | **MVP** (nel nucleo, con l'avviso aggiunto) |
| C6 | **Dolore e qualità della vita**: scala HHHHHMM periodica, grafico nel tempo, export per il veterinario. Per il dolore, una scala per il proprietario (per esempio il Canine Brief Pain Inventory, da verificare per la licenza) | Altissimo emotivamente per gli anziani; nessuna app italiana trovata lo fa bene | Bassa | Delicatezza: non suggerire mai l'eutanasia; testo "da discutere con il veterinario". Verificare i diritti d'uso delle scale (CBPI, Glasgow, ecc.) | v1.x |
| C7 | **Modalità cane anziano e cure palliative** (promemoria terapie multiple, mobilità, giorni buoni e cattivi, preparazione al fine vita, supporto al lutto) | Alto per una nicchia ad alta fedeltà | Bassa-media | Tono e contenuti curati con professionisti | v1.x |
| C8 | **Interazioni e duplicati di farmaci/antiparassitari** (per esempio due prodotti con la stessa molecola) | Alto | Alta (serve un database dei farmaci veterinari italiani) | Responsabilità elevata: un falso negativo è grave | futuro |

### D. Ambiente e prevenzione territoriale

| # | Funzionalità | Valore | Diff. | Rischi | Priorità |
|---|---|---|---|---|---|
| D1 | **Meteo e caldo per le uscite**: indice di rischio personalizzato (brachicefalo, peso, età, umidità, ora); suggerimento di anticipare o posticipare l'uscita prevista dal tracker; avviso asfalto caldo | Altissimo d'estate; si integra con la previsione delle uscite | Bassa-media (API meteo, per esempio Open-Meteo, gratuita) | Posizione approssimata (comune) basta: niente GPS preciso. Disclaimer | **MVP** (versione base) |
| D2 | **Calendario parassiti e rischi per zona e stagione** (pappataci/leishmaniosi giugno-ottobre, zecche, filaria, processionaria febbraio-aprile, forasacchi estivi) con promemoria preventivi | Alto | Media: contenuto curato per regione, aggiornamento annuale | Dati epidemiologici non in tempo reale: "rischio stagionale tipico", non "allerta" | v1.x |
| D3 | **Segnalazioni della community** (processionaria, bocconi avvelenati, forasacchi) su mappa | Alto, ma a doppio taglio | Alta (moderazione) | Diffamazione, falsi allarmi, privacy della posizione; obblighi del DSA per le piattaforme | futuro |
| D4 | **Mappa servizi** (veterinari, pronto soccorso H24, aree cani, fontanelle) | Medio | Media (dati OSM + inserimenti) | Bassi | v2 |

### E. Attività, comportamento, dispositivi

| # | Funzionalità | Valore | Diff. | Rischi | Priorità |
|---|---|---|---|---|---|
| E1 | **Passeggiate**: durata, distanza, pipì e cacca durante l'uscita, con un solo tap (diventa il modo principale di alimentare il tracker) | Alto | Media (GPS in background su iOS e Android, batteria) | **Privacy forte**: i percorsi rivelano la casa. Default: solo durata, GPS opzionale; cifratura; non condivisibile in pubblico per default | Timer di uscita **MVP**; GPS v1.x |
| E2 | **Diario comportamentale** (ansia da separazione, reattività, paure da botti, obiettivi di addestramento) | Medio-alto | Bassa | Bassi | v1.x |
| E3 | **HealthKit / Health Connect**: le passeggiate come allenamento del proprietario (anelli Attività) | Medio (motivazione del proprietario) | Bassa-media | HealthKit non ha tipi per animali: i dati sono del proprietario, dati sanitari umani (art. 9 GDPR) se letti. Scrivere senza leggere riduce il rischio | v2 |
| E4 | **Collari GPS/smart** (Tractive, Kippy, Fi) | Medio | Alta: nessuna API pubblica Tractive; quelle non ufficiali sono fragili | Termini d'uso dei produttori; affidabilità | futuro (solo con partnership) |
| E5 | **Ciotole e distributori smart** (consumo d'acqua automatico per C2) | Alto in teoria | Alta (ecosistemi chiusi) | Come E4 | futuro |

### F. Piattaforma e superfici

| # | Funzionalità | Valore | Diff. | Rischi | Priorità |
|---|---|---|---|---|---|
| F1 | **Widget home** (prossima uscita prevista, prossimo farmaco; tasto rapido "fatto pipì") | Alto: riduce l'attrito del log, che è la cosa che decide la qualità della previsione | Media (`home_widget`, codice nativo per il layout) | Bassi | **MVP** (un widget) |
| F2 | **Live Activity / Dynamic Island** (conto alla rovescia alla prossima uscita; durante la passeggiata, timer con tasti pipì/cacca) e notifica "ongoing" su Android | Alto, molto visibile | Media-alta (estensione Swift, solo su dispositivo fisico, limiti di aggiornamento) | Bassi | v1.x |
| F3 | **Apple Watch / Wear OS** (log con un tocco dal polso durante l'uscita) | Alto per chi lo usa | Alta (Flutter non supporta bene watchOS: serve SwiftUI nativo) | Bassi | v2 |
| F4 | **Alexa / Google Home / Siri Shortcuts** ("Alexa, chiedi a Zampa quando è l'ultima pipì") | Medio | Media (gli App Intents/Shortcuts su iOS sono la parte più facile) | Annunci vocali in casa: informazioni visibili a ospiti | Shortcuts v1.x; Alexa v2 |
| F5 | **Offline-first** (log senza rete, poi sincronizzazione) | Alto: in passeggiata la rete manca | Media (database locale + sync) | Bassi | **MVP** (requisito architetturale) |
| F6 | **Multi-cane** (profili separati, log rapido "chi ha fatto cosa", previsioni per cane) | Alto: le famiglie con più cani sono un segmento rilevante e fedele | Bassa se previsto dal modello dati; costosa se aggiunta dopo | Bassi | **MVP** (nel modello dati) |
| F7 | **Localizzazione UE** (IT, poi EN, DE, FR, ES; unità di misura; regole nazionali) | Necessario per l'espansione | Media | Contenuti sanitari da rivalidare per Paese | v1.x (EN), v2 (altre) |
| F8 | **Accessibilità** (dimensione testo, VoiceOver/TalkBack, contrasto) | Alto per proprietari anziani, che sono molti | Bassa se fatta subito | European Accessibility Act: da verificare se si applica (in vigore da giugno 2025, soprattutto per e-commerce) | **MVP** |

### G. AI, community, coinvolgimento

| # | Funzionalità | Valore | Diff. | Rischi | Priorità |
|---|---|---|---|---|---|
| G1 | **Assistente AI** (domande su alimentazione, comportamento, uso dell'app, sintesi della cartella prima della visita). Limiti: niente diagnosi né dosaggi; rimando al veterinario per sintomi; nessuna risposta su farmaci umani | Alto e atteso dagli utenti nel 2026 | Media (LLM via API + RAG su contenuti curati + guardrail) | **Il rischio maggiore del prodotto**: allucinazioni su tossicità e dosi, responsabilità civile, AI Act art. 50 (dichiarare l'IA), trasferimento di dati verso il fornitore dell'LLM (DPA, server in UE), costi variabili. Lo stesso settore riconosce accuratezza disomogenea | v2 (dopo che C1-C4 sono solidi); solo "sintesi per il veterinario" in v1.x |
| G2 | **Gamification leggera** (serie di giorni con log completi, badge "prevenzione in regola", progressi nell'addestramento) | Medio: aumenta la costanza del log, che migliora la previsione | Bassa | Evitare di premiare comportamenti scorretti (per esempio "fai più passi" per un cane cardiopatico) | v1.x |
| G3 | **Community / social** (feed, gruppi per razza, incontri al parco) | Medio | Alta (moderazione, abusi) | DSA, contenuti illeciti, privacy delle posizioni, costo di moderazione; allontana dal focus "salute" | futuro (o mai) |
| G4 | **Contenuti educativi curati** (schede brevi revisionate da veterinari: alimenti tossici, primo soccorso, cuccioli, sterilizzazione) | Alto, crea fiducia e posizionamento | Bassa (contenuti) | Revisione periodica, firma del revisore | v1.x |
| G5 | **Profilo d'emergenza e "cane smarrito"** (QR sulla medaglietta con pagina pubblica minima: nome, contatto, allergie, farmaci salvavita; poster "cane smarrito" generato in un tap) | Alto | Bassa-media | Pagina pubblica: l'utente sceglie cosa mostrare; niente indirizzo di casa | v1.x |
| G6 | **Cucciolo**: piano vaccinale tipo, socializzazione per settimane, crescita, educazione alla pulizia (il tracker pipì è perfetto per insegnare a sporcare fuori) | Alto: il momento d'ingresso più naturale per un'app del genere | Bassa | Il piano vaccinale tipo va presentato come indicativo, deciso dal veterinario | v1.x |

### H. Lato professionisti e modello economico (potenzialità)

| # | Funzionalità | Valore | Diff. | Rischi | Priorità |
|---|---|---|---|---|---|
| H1 | **Portale veterinario** (il veterinario riceve la cartella e i grafici, aggiunge visite e richiami che arrivano direttamente nell'app) | Molto alto: rete di distribuzione via ambulatori | Alta | Il veterinario diventa titolare/contitolare dei dati; integrazione con i gestionali | v2 |
| H2 | **Integrazione con i gestionali veterinari italiani** (che già comunicano con la REV) | Alto | Alta, dipende dalla disponibilità dei fornitori | Accordi commerciali | futuro |
| H3 | **Prenotazione visite** | Medio | Alta | Intermediazione | futuro |
| H4 | **Dati aggregati anonimi per la ricerca** (opt-in esplicito, per esempio con università) | Medio per l'utente, alto per la missione | Media | Anonimizzazione vera (i percorsi GPS non sono anonimizzabili facilmente); consenso separato | futuro |

---

## 3. Rischi trasversali e regole di design

1. **Mai diagnosticare.** **[I]** Ogni avviso parla di "variazioni rispetto al solito" e "da valutare con il veterinario". I nomi di malattie appaiono solo in contenuti educativi separati, mai come conclusione su un cane specifico. Testi d'emergenza e soglie revisionati da almeno un medico veterinario iscritto all'Ordine, con data di revisione visibile. Coerente con le linee guida FNOVI, che lasciano la responsabilità clinica al veterinario.
2. **Privacy by design.** **[I]** Posizione al livello di comune per meteo e parassiti; GPS solo su richiesta e con cifratura; condivisioni a tempo; nessuna vendita di dati; fornitori in UE; DPIA consigliata per GPS e AI; informativa chiara sulla posizione e sugli orari (abitudini di casa).
3. **Regole normative come dati, non codice.** **[I]** Viaggi, calendari dei parassiti e piani vaccinali stanno in tabelle versionate lato server, con data di validità e fonte. Il caso del Reg. 576/2013, sostituito nel 2026, lo dimostra.
4. **AI con perimetro stretto.** **[I]** Prima l'AI che *riassume i dati dell'utente* (basso rischio, alto valore), poi quella che *risponde a domande* con RAG su contenuti curati, dichiarazione esplicita di essere un'IA e blocco degli argomenti di dosaggio e diagnosi.
5. **Dipendenze da terzi.** **[F/I]** Niente integrazioni basate su API non ufficiali (Tractive). Le integrazioni pubbliche italiane (SINAC, REV) vanno trattate come obiettivo istituzionale di medio periodo, non come requisito.

---

## 4. Roadmap in fasi

### Fase 0: MVP (lancio Italia)
Obiettivo: il nucleo più ciò che lo rende usabile ogni giorno e lo differenzia.
- Nucleo: cartella sanitaria, promemoria, nutrizione, tracker pipì/cacca con previsione.
- **A1** Multi-utente famiglia (sincronizzato).
- **F6** Multi-cane nel modello dati.
- **F5** Offline-first.
- **F1** Un widget home (prossima uscita + log rapido).
- **E1** Timer di uscita con log pipì/cacca (senza GPS).
- **C1** Segnali di cambiamento dal tracker (2-3 regole prudenti, testi rivisti da un veterinario).
- **C3** Diario sintomi base con foto.
- **C5** Peso/BCS con avviso di calo.
- **D1** Avviso caldo personalizzato collegato all'uscita prevista.
- **A3 + A4** Export PDF e link in sola lettura a tempo per il veterinario.
- **B1** Archivio documenti.
- **B4** Campo microchip validato.
- **A5** Export dati e cancellazione account (GDPR). **F8** Accessibilità di base.

### Fase 1: v1.x (3-9 mesi dopo il lancio)
- **A2** Accesso temporaneo per il dog sitter. **G5** QR d'emergenza e poster "cane smarrito".
- **B2** OCR di etichette vaccinali e libretto. **B6** Terapie da REV (manuale + OCR) con promemoria delle dosi.
- **B3** Assistente viaggi UE (Reg. 2026/131). **B7** Spese veterinarie e detrazione 730.
- **C2** Diario acqua (ml/kg/giorno). **C4** Guida alle emergenze + pronto soccorso H24. **C6** Qualità della vita HHHHHMM. **C7** Modalità cane anziano.
- **D2** Calendario parassiti e rischi per regione (leishmaniosi, zecche, processionaria, forasacchi).
- **E1** GPS delle passeggiate (opzionale). **E2** Diario comportamentale. **G6** Percorso cucciolo.
- **F2** Live Activity e notifica ongoing. **F4** Siri Shortcuts/App Intents. **F7** Inglese.
- **G2** Gamification leggera. **G4** Contenuti curati. **G1-lite** AI "sintesi per il veterinario".

### Fase 2: v2 (espansione UE, 9-18 mesi)
- **H1** Portale veterinario (bidirezionale). **G1** Assistente AI conversazionale con RAG e guardrail.
- **F3** Apple Watch / Wear OS. **F4** Alexa / Google Home. **E3** HealthKit / Health Connect (solo scrittura).
- **B2** OCR dei referti di laboratorio con andamento dei valori. **B3** Paesi terzi. **B8** Assicurazioni (manuale).
- **D4** Mappa servizi. **F7** DE, FR, ES con regole nazionali.

### Fase 3: futuro (dipende da partner e istituzioni)
- **B5** SINAC e anagrafi regionali; integrazione REV; **H2** gestionali veterinari (accordi istituzionali e commerciali).
- **E4/E5** Collari e ciotole smart (solo con API ufficiali o partnership).
- **C8** Interazioni tra farmaci (con un database dei farmaci veterinari licenziato).
- **D3/G3** Community e segnalazioni geolocalizzate (solo con un piano di moderazione).
- **H3** Prenotazioni; **H4** dati anonimi per la ricerca.

---

## 5. Cose da verificare prima di decidere

1. Richiesta formale a vetinfo e Ministero della Salute: esistono o sono previste API per app del proprietario (SINAC, REV)? **[I]** Oggi nessuna trovata.
2. Testo ufficiale del Reg. delegato (UE) 2026/131 e degli atti collegati su EUR-Lex (numerazione non univoca nelle fonti secondarie).
3. Parere legale su: formulazione degli avvisi C1/C2, assistente AI (AI Act art. 50, responsabilità), condivisione delle posizioni (DPIA).
4. Licenze d'uso delle scale cliniche (HHHHHMM, CBPI, Glasgow, scala fecale) dentro un'app.
5. Validazione delle soglie delle red flags con un panel di veterinari (falsi positivi = ansia e abbandono dell'app; falsi negativi = rischio reputazionale).
6. Documentazione Apple su HealthKit (assenza di tipi di dato per animali) e politiche App Store per le app che danno informazioni sanitarie.
