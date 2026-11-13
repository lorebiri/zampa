# Consenso separato allo studio sull'accuratezza (telemetria) e ai rapporti di errore

> **Stato:** testo per la beta (C2-7, 11/11/2026). Da usare nell'app così com'è, o con
> ritocchi solo di forma. Specifica tecnica di riferimento: `ricerca/12-protocollo-accuratezza.md` §5.
> Se cambia cosa si invia, va cambiato **prima** questo testo e va chiesto di nuovo il consenso.

## Regole per lo sviluppatore (non è testo per l'utente)

Il consenso è valido solo se è **libero, specifico, informato e inequivocabile**
(art. 4.11 e art. 7 GDPR; Linee guida EDPB 05/2020 sul consenso). In pratica:

1. **Due interruttori separati**, entrambi **spenti** all'inizio: "Studio sull'accuratezza"
   e "Rapporti di errore". Nessuna casella già spuntata, nessun "accetta tutto" che li
   accenda insieme a qualcos'altro.
2. **Non è una condizione**: se l'utente dice no, l'app funziona esattamente uguale.
   Niente richiami insistenti: si chiede una volta (dopo qualche giorno d'uso, non al
   primo avvio), poi resta in Profilo › Privacy.
3. **Due pulsanti dello stesso peso**: "Sì, partecipo" e "No, grazie". Stesso colore e
   stessa dimensione.
4. **Ritiro facile quanto il consenso** (art. 7.3): un tocco in Profilo › Privacy.
   Al ritiro l'app smette subito di inviare e manda la richiesta di cancellazione per il
   `pid` (vedi `ricerca/12` §5.3).
5. **Prova del consenso** (art. 7.1): sul telefono si salvano data, ora e versione del
   testo accettato (`consentVersion`, per esempio `tele-2026-11`). Il server riceve solo la
   versione del testo insieme ai record, non chi ha accettato.
6. **Età**: si chiede solo a chi ha confermato di avere almeno 14 anni (art. 2-quinquies
   del Codice privacy).
7. **Il cane di esempio non partecipa mai.** Nessun invio da build di sviluppo verso la
   tabella dello studio.
8. Il testo breve qui sotto è il **primo livello**; il link "Cosa inviamo, nel dettaglio"
   apre il secondo livello (approccio a più livelli raccomandato da EDPB e CNIL).

---

## Testo per l'utente: primo livello (schermata di richiesta)

### Ci aiuti a capire se le previsioni funzionano?

Pellovi prova a prevedere quando il tuo cane avrà bisogno di uscire. Per sapere se ci
riesce davvero, ci servono i numeri di tanti cani veri.

Se partecipi, **una volta al giorno** il telefono calcola quanto la previsione si è
avvicinata alla realtà e ci manda **solo quei numeri**.

**Inviamo:** di quanti minuti la previsione ha sbagliato, se l'uscita era dentro la
finestra prevista, e poche informazioni generali sul cane (fascia d'età, fascia di peso,
sesso).

**Non inviamo mai:** il diario, il nome del cane, le note, le foto, gli orari, le date,
la tua città, la tua email o il tuo account.

I numeri sono legati a un **codice casuale** creato sul telefono, che non è collegato al
tuo account. Li conserviamo in UE fino a 12 mesi dopo la fine della beta.

Puoi smettere quando vuoi da **Profilo › Privacy**: cancelliamo i tuoi numeri entro
30 giorni. Se dici di no, Pellovi funziona uguale.

[ Sì, partecipo ]   [ No, grazie ]

[Cosa inviamo, nel dettaglio](#secondo-livello) · [Informativa privacy](PRIVACY.md)

---

### Rapporti di errore

Se l'app si blocca o va in errore, può mandarci una descrizione tecnica del problema
per aiutarci a correggerlo.

**Contiene:** il punto del codice dove è avvenuto l'errore, la versione di Pellovi, il
modello del telefono e la versione del sistema.

**Non contiene:** i dati dei tuoi cani, il diario, la tua email, il tuo indirizzo IP,
schermate o registrazioni dello schermo.

I rapporti vanno a Sentry, su server in UE (Francoforte), e sono cancellati al massimo
dopo 90 giorni. Puoi spegnerli quando vuoi da **Profilo › Privacy**.

[ Sì, invia i rapporti ]   [ No, grazie ]

---

## Secondo livello: cosa inviamo, nel dettaglio

**Chi:** Lorenzo Birindelli, titolare del trattamento (contatti nell'informativa).

**Perché:** valutare e migliorare l'accuratezza delle previsioni di Pellovi. Non usiamo
questi dati per pubblicità, non li vendiamo e non li usiamo per decisioni su di te.

**Base giuridica:** il tuo consenso (art. 6.1.a GDPR), che puoi ritirare in ogni momento.

**Come funziona:** il calcolo avviene sul telefono. Ogni giorno il telefono rifà le
previsioni del giorno prima, le confronta con le uscite che hai registrato e invia solo
il risultato.

**Cosa esce dal telefono:**

| Gruppo | Dati | Come sono resi meno precisi |
|---|---|---|
| Per ogni pipì o cacca valutata | tipo (pipì o cacca); giorno dello studio (0, 1, 2...); feriale o weekend; parte della giornata (mattino, giorno, sera); errore della previsione e di tre metodi semplici di confronto; se era nella finestra prevista; ampiezza della finestra; se il cane l'aveva chiesta o l'hai portato tu; se è successo in casa | minuti arrotondati a 5 o a 15; nessun orario e nessuna data |
| Più volte al giorno | probabilità prevista per l'ora successiva e se poi è successo | arrotondata al 5% |
| Sul cane, ogni 2 settimane | fascia d'età (cucciolo, adulto, anziano); fascia di peso; sesso e sterilizzazione; se ha una malattia cronica (sì/no) e di che tipo (urinaria, endocrina, renale, intestinale, altra); se prende farmaci che cambiano i bisogni (sì/no); numero di pasti; media delle pipì al giorno; versione dell'app | solo fasce e categorie, nessun testo libero |

**Cosa non esce mai:** nome del cane, razza scritta da te, note, foto, testo delle
malattie, orari e date, data di nascita, città o coordinate, veterinario, sintomi e
eventi clinici (vomito, convulsioni...), farmaci e dosi, account, email, identificativi
pubblicitari.

**Il codice casuale:** è creato sul telefono quando dai il consenso, uno per ogni cane.
Non deriva dal tuo account e la corrispondenza tra codice e cane resta solo sul
telefono. Per noi è difficile risalire a te, ma la legge considera questi dati comunque
personali (pseudonimi), e li trattiamo come tali.

**Dove:** in una tabella separata, su server Supabase in UE (Francoforte). L'invio non
usa il tuo account. Il tuo indirizzo IP non viene salvato nella tabella dello studio;
i registri tecnici del server lo conservano al massimo 7 giorni.

**Quanto a lungo:** fino a 12 mesi dopo la fine della beta. Poi restano solo tabelle
riassuntive, in cui nessuna casella descrive meno di 5 cani.

**Se smetti:** il telefono smette subito di inviare, chiede la cancellazione dei numeri
già inviati (entro 30 giorni) e dimentica il codice. Se disinstalli l'app senza
spegnere lo studio, il codice si perde e non possiamo più trovare i tuoi numeri: in quel
caso restano fino alla scadenza dei 12 mesi. Per evitarlo, spegni lo studio prima di
disinstallare.

**I tuoi diritti:** accesso, cancellazione, limitazione, reclamo al Garante. Vedi
l'informativa privacy.

---

## Testo breve per Profilo › Privacy

- **Studio sull'accuratezza** — Invia ogni giorno solo numeri calcolati sul telefono,
  senza diario, nomi, orari o posizione. [interruttore] · [Dettagli]
- **Rapporti di errore** — Invia una descrizione tecnica quando l'app va in errore,
  senza i dati dei cani. [interruttore] · [Dettagli]

Messaggio al ritiro dello studio: «Fatto. Non inviamo più nulla e abbiamo chiesto la
cancellazione dei numeri già inviati.»
