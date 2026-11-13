# Valutazione d'impatto leggera (DPIA) — Lulù beta

> **Stato:** versione 1, 11/11/2026 (C2-7). Riferimenti: art. 35 GDPR; Linee guida
> WP248 rev.01 (fatte proprie dall'EDPB); elenco del Garante dei trattamenti soggetti a
> DPIA (provv. n. 467 dell'11/10/2018). Da rivedere prima del lancio in UE, prima di
> aggiungere funzioni nuove (GPS, foto sul server, condivisione con il veterinario) e se
> gli utenti superano qualche migliaio.

## 1. Serve davvero una DPIA?

Le linee guida WP248 indicano nove criteri; con due o più, di solito la DPIA serve.

| Criterio WP248 | Lulù | Presente? |
|---|---|---|
| 1. Valutazione o punteggio | previsioni sul **cane**, non sulla persona | no |
| 2. Decisioni automatiche con effetti giuridici | no | no |
| 3. Monitoraggio sistematico | il diario registra orari delle uscite, ma lo scrive l'utente, per sé e per la famiglia | in parte |
| 4. Dati sensibili o molto personali | dati sanitari del cane: **non** art. 9. Orari e città possono dire molto delle abitudini | in parte |
| 5. Larga scala | beta: decine o centinaia di utenti | no |
| 6. Incrocio di insiemi di dati | no | no |
| 7. Interessati vulnerabili | no (età minima 14 anni) | no |
| 8. Tecnologie nuove | modello predittivo sul telefono, ma su dati del cane | no |
| 9. Impedisce di usare un servizio | no: account e consensi sono facoltativi | no |

Nessuna voce dell'elenco del Garante si applica (la geolocalizzazione vi compare solo
nel rapporto di lavoro). **Conclusione:** la DPIA **non è obbligatoria**. La facciamo
in forma leggera per due motivi: i criteri 3 e 4 sono in parte presenti, e il progetto
vuole poter dimostrare le sue scelte (art. 5.2 e art. 25).

## 2. Descrizione del trattamento

Vedi `docs/REGISTRO-TRATTAMENTI.md` (T1-T6). Il punto chiave: **senza account, il
titolare non riceve nulla**. Con l'account, Supabase a Francoforte riceve tutti i dati
dei cani, incluso il diario con data e ora.

## 3. Il punto delicato: dati del cane, informazioni sulla persona

I dati sanitari del cane **non sono dati sanitari** ai sensi dell'art. 4.15 GDPR, che
parla di "persona fisica". Ma alcuni dati del cane, messi insieme, diventano dati
personali **del proprietario** e possono rivelare cose sulla sua vita:

| Dato | Cosa può rivelare della persona |
|---|---|
| Orari di pipì, passeggiate, pasti, risveglio | quando la persona si sveglia, quando esce, quando è in casa e quando no (per esempio vacanze o turni di lavoro); utile anche a un malintenzionato |
| Città e coordinate del comune | dove vive, con la precisione del comune |
| "Uscita decisa dal padrone", pipì in casa | ritmi della persona, tempo che passa fuori casa |
| Cambi bruschi nel diario (registrazioni che si fermano, orari notturni) | malattia, ricovero, lutto, cambi di lavoro |
| Microchip | è legato all'anagrafe canina regionale, dove compare il nome del proprietario: identifica la persona |
| Veterinario, telefono di emergenza | dati di terze persone |
| Farmaci per il cane, costi | in parte la situazione economica |
| Familiari invitati | composizione della famiglia |

Non deduciamo dati dell'art. 9 sulla persona e non facciamo profilazione. Il rischio
principale è la **riservatezza**: una fuga di dati, o un familiare con cui il cane non
dovrebbe più essere condiviso (per esempio dopo una separazione), saprebbe quando la
casa è vuota.

## 4. Necessità e proporzionalità

| Principio | Come lo rispettiamo |
|---|---|
| Minimizzazione | niente GPS; città solo se si attiva l'avviso caldo; foto solo sul telefono; telemetria solo con metriche arrotondate, senza orari né date; rapporti di errore senza IP e senza schermate |
| Limitazione della finalità | niente pubblicità né profilazione; i dati dello studio non tornano sull'account |
| Base giuridica | contratto per il servizio chiesto; consenso separato per studio e crash |
| Conservazione | definita per ogni trattamento (registro); eliminazione dell'account dall'app |
| Trasparenza | informativa a due livelli; testi del consenso; schede degli store coerenti |
| Diritti | esportazione JSON, eliminazione in app e per email, ritiro del consenso in un tocco |
| Responsabili | DPA con Supabase e Sentry; dati in UE; clausole standard per gli accessi dagli USA |

## 5. Rischi e misure

Probabilità e gravità: 1 bassa, 2 media, 3 alta. Rischio = probabilità × gravità.

| # | Rischio | P | G | Rischio iniziale | Misure (fatte / da fare) | Residuo |
|---|---|---|---|---|---|---|
| R1 | Accesso di un estraneo ai dati di un altro utente per un errore nelle regole del database | 2 | 3 | 6 | **Fatto:** RLS, 79 test, difetti S1-S15 corretti (`ricerca/11`). **Da fare:** prove a mano sul progetto vero (B6), Security Advisor | 2 |
| R2 | Il telefono passa di mano e i dati di un familiare finiscono nell'account di un altro (richiesta A2 di `ricerca/11`) | 2 | 2 | 4 | **Da fare (P0):** correzione A2 prima di aprire gli account. Fino ad allora: account solo a beta tester noti | 2 |
| R3 | Un ex familiare continua a vedere le abitudini della casa | 2 | 2 | 4 | Il proprietario può togliere un familiare. **Da fare:** mostrare nell'app l'elenco dei familiari, con "Togli" ben visibile (A12) | 2 |
| R4 | Fuga di dati presso il fornitore o furto della chiave `service_role` | 1 | 3 | 3 | DPA (notifica entro 48 h); chiave segreta mai in git né nell'app; rotazione se esposta; MFA sull'account Supabase di Lorenzo | 2 |
| R5 | Furto dell'account email dell'utente (accesso con codice) | 2 | 2 | 4 | Codice monouso con scadenza breve; limiti di invio; CAPTCHA quando l'app lo supporta | 2 |
| R6 | Reidentificazione dei dati dello studio | 1 | 2 | 2 | `pid` casuale per cane; nessun orario, data o posizione; fasce; celle ≥ 5; IP non salvato | 1 |
| R7 | I rapporti di errore contengono dati personali per caso (nomi del cane nei messaggi d'errore, URL con parametri) | 2 | 1 | 2 | `sendDefaultPii = false`; nessuna schermata né replay; filtro `beforeSend` che toglie testi e URL di Supabase; IP non salvato | 1 |
| R8 | Il backup JSON resta negli appunti e altre app lo leggono | 2 | 2 | 4 | Avviso nell'informativa. **Proposta allo sviluppatore:** salvare su file con il foglio di condivisione invece degli appunti, o svuotare gli appunti dopo un minuto | 2 |
| R9 | Perdita dei dati (piano gratuito senza backup) | 2 | 2 | 4 | Esportazione JSON; **da fare:** piano con backup prima di utenti veri (`ricerca/11` §6 punto 8) | 2 |
| R10 | Open-Meteo collega la città all'IP del telefono | 2 | 1 | 2 | Solo città, non GPS; funzione spenta di serie; Svizzera adeguata; registri 90 giorni | 1 |
| R11 | Un utente minore di 14 anni dà il consenso | 1 | 1 | 1 | Domanda sull'età prima del consenso; nessun dato dell'art. 9 | 1 |
| R12 | Il titolare non riesce a rispondere a una richiesta o a una violazione entro i termini (persona sola) | 2 | 2 | 4 | Casella privacy dedicata; procedura scritta in `ricerca/24`; registro delle violazioni pronto | 2 |

Tutti i rischi residui sono **bassi** (≤ 2) se le misure "da fare" vengono completate
prima di aprire gli account a utenti che non sono beta tester noti. Non serve la
consultazione preventiva del Garante (art. 36).

## 6. Condizioni per aprire gli account al pubblico

1. A1 e A2 di `ricerca/11` corretti e provati.
2. Progetto Supabase a Francoforte, DPA accettato e salvato, checklist `ricerca/11` §6
   applicata (`docs/DPA-SUPABASE-CHECKLIST.md`).
3. Informativa pubblicata con i segnaposto completati e link nell'app e negli store.
4. Studio e crash spenti di serie, con i testi di `docs/CONSENSO-TELEMETRIA.md`.
5. Indirizzo per le richieste (email o pagina web) che funziona senza accedere all'app.

## 7. Firma

| Ruolo | Nome | Data | Esito |
|---|---|---|---|
| Titolare | Lorenzo Birindelli | `[[data]]` | `[[approvata / da rivedere]]` |
| Redatta da | esperto privacy del progetto (agente) | 11/11/2026 | bozza |
