# Materiali della beta di Lulù (v3)

*13/11/2026. Piano di riferimento: `ricerca/27-previsione-pipi-v2.md` §6, con
`ricerca/12` §4-5 e `ricerca/23` §4. Privacy: `ricerca/24`, `docs/PRIVACY.md`,
`docs/CONSENSO-TELEMETRIA.md`, `docs/DPIA.md`, `lib/consent.dart`.*

**Stato: BOZZA.** Nessun testo è pronto per l'uso.
- Le parti privacy (`consenso-studio.md`, la nota privacy di `adesione.html`) vanno fatte
  rivedere a un **legale** (il progetto non ha un DPO: `docs/PRIVACY.md` §2).
- Le parti cliniche (`istruzioni-partecipanti.md` §5 e §7) vanno fatte rivedere al
  **veterinario**. I testi clinici citati non sono ancora firmati.
- Tutti i testi vanno controllati contro le frasi vietate di `ricerca/08` §11.3.

## Obiettivi della beta

- **90 cani reclutati, almeno 60 inclusi**, di cui **almeno 30 in appartamento senza giardino**.
- **8 settimane**. Composizione minima: ≥ 10 cuccioli, ≥ 25 adulti, ≥ 12 anziani, ≥ 8 cronici.
- Funzioni nuove della v3: segnali a un tocco, previsione della cacca legata ai pasti,
  piano di uscite (3, 4 o 5) con rischio stimato, azioni rapide nelle notifiche.

## I file

| File | Cosa contiene | Per chi |
|---|---|---|
| `invito.md` | invito lungo (email), breve (social, WhatsApp), variante per educatori e veterinari | pubblico, staff |
| `adesione.html` | modulo di adesione: pagina autonoma, nessuna rete, riepilogo da copiare, email già pronta, file `.json`. Nota per lo staff in un commento in cima | pubblico, staff |
| `consenso-studio.md` | consenso informato allo studio, separato, versione `studio-v3-2026-11`: riassunto in 5 righe e testo completo; in fondo «Cose da aggiornare» nei documenti privacy | partecipanti, legale, sviluppatore |
| `istruzioni-partecipanti.md` | installazione, procedura guidata, cosa registrare, segnali, piano di uscite, incidenti, veterinario, questionari, esportazione, ritiro, FAQ, tabella Android / iPhone / computer | partecipanti |

## Cosa manca prima di partire

1. **Titolare definitivo** (oggi Lorenzo Birindelli nei documenti), indirizzo ed email privacy.
   Chiarire la questione CNR (`ricerca/24` §6).
2. **Casella dedicata della beta** in UE al posto di `beta@ESEMPIO.invalid` (in
   `adesione.html`, anche nella costante `MAIL_TO`), e **foglio ad accesso limitato** per
   le adesioni.
3. **Commit firmato del protocollo**: `ricerca/12` §4, `ricerca/23` §4 e `ricerca/27` §6
   (`ricerca/27` §6.6, settimana 0). Prima, un **emendamento datato** che copra le
   funzioni nuove della v3 (vedi sotto, «Incoerenze»).
4. **Consenso nell'app**: testo approvato, poi `ConsentStore.studyVersion` a
   `studio-v3-2026-11` in `lib/consent.dart`.
5. **Esportazione anonima** finita e allineata alla tabella di `consenso-studio.md` §5.
   Decidere se c'è anche l'invio automatico.
6. `createdAt` e avviso v2 nello store (`ricerca/27` §6.6).
7. **Distribuzione**: link Android (test chiuso Play o file di installazione), indirizzo
   della app web per iPhone, verifica delle notifiche web su iOS ≥ 16.4.
8. **Questionari** a 4 e 8 settimane: strumento e modo per tenerli separati dai contatti.
9. **Nome definitivo** dell'app (`ricerca/13`: «Lulù» a rischio alto). Il manifest web
   (`web/manifest.json`) dice ancora «zampa» e «A new Flutter project»: è il nome che
   compare sotto l'icona su iPhone.
10. **Date** di apertura e chiusura del reclutamento e di inizio della prova.
11. Aggiornare `docs/REGISTRO-TRATTAMENTI.md`, `docs/DPIA.md`, `docs/PRIVACY.md`,
    `docs/CONSENSO-TELEMETRIA.md` (elenco in `consenso-studio.md`, «Cose da aggiornare»).
12. Rilettura legale e veterinaria; firma della DPIA (`docs/DPIA.md` §7).

## Incoerenze trovate nei documenti esistenti

- **Obiettivo «zero incidenti».** L'obiettivo di prodotto per la beta («zero incidenti in
  casa con il minor numero di uscite») non va comunicato così: «niente più incidenti in
  casa» è una frase vietata (`08` §11.3) e il veterinario ha già tolto «mai incidenti»
  (`06` §30). Nei materiali è scritto come domanda dello studio.
- **Il protocollo non copre la v3.** Le ipotesi H1-H6 (`ricerca/12` §4.1) e D1-D3
  (`ricerca/27` §6.5) riguardano l'accuratezza della pipì. Piano di uscite, rischio
  stimato, segnali e numero di uscite non hanno un'ipotesi né un campo in `ricerca/12`
  §5.2. Serve un emendamento prima dei dati.
- **Giardino libero.** `ricerca/27` §6.1 esclude dall'analisi primaria i cani con accesso
  libero al giardino; `ricerca/12` §4.4 li mette nell'analisi primaria (sottogruppo
  «a richiesta»).
- **Segnali.** `ricerca/27` §6.4 dice che gli inneschi non escono; l'esportazione v3
  contiene «segnale sì/no» per evento: va detto nel consenso (fatto) e nel protocollo.
- **Età.** Documenti privacy: 14 anni. Beta: 18.
- **Canale email.** `docs/CONSENSO-TELEMETRIA.md` promette «non inviamo mai… la tua
  email» e un invio automatico; il file mandato per email lega il codice a un indirizzo.
- **iPhone.** `ricerca/08` prevede TestFlight; qui iPhone usa la app web. Le notifiche web
  richiedono di norma un server push, mentre il registro dice «nessun server di notifiche
  push».
- **Parte della giornata.** `ricerca/12` §5.2: «notte-mattino / giorno / sera»;
  `docs/CONSENSO-TELEMETRIA.md`: «mattino, giorno, sera».
- **Traversina.** Nel modello dati una pipì sulla traversina conta come «in casa»
  (`lib/models.dart`): i cani misti traversina/fuori gonfiano gli incidenti. Da decidere
  nel protocollo.
- **Posizione.** Nel ramo c'è `lib/logic/outing_geofence.dart` (recinto intorno a casa,
  cita `ricerca/28`, file che non esiste ancora). `docs/PRIVACY.md` §3 dice che l'app non
  usa il GPS e non chiede il permesso di posizione: se il geofence entra nella beta,
  informativa, registro e DPIA vanno aggiornati prima.
