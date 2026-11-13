# Checklist del DPA di Supabase (per Lorenzo)

> C2-7, 11/11/2026. Da fare **quando crei il progetto Supabase** (azione 5 del piano CEO
> §11.6), prima che entri qualunque dato vero. Tempo: circa 30 minuti.
> Si collega a `ricerca/11-sicurezza-backend.md` §6 (checklist tecnica).

## Come si conclude il DPA, oggi

Dalla pagina ufficiale (`supabase.com/legal/dpa`, **versione 1 del 1° agosto 2026**):
- il DPA integra le condizioni d'uso di Supabase e vale per i dati dei clienti;
- **accettare le condizioni d'uso equivale a firmare le clausole contrattuali standard**
  (clausola 12.2). Quindi di norma **non c'è un documento da firmare a mano**;
- in passato Supabase faceva firmare il DPA con PandaDoc dal pannello
  (Organization › Legal Documents). Se nel pannello trovi ancora quel percorso, usalo:
  una copia firmata è una prova migliore.

L'art. 28.9 GDPR chiede che il contratto sia **per iscritto, anche in formato
elettronico**: l'accettazione online va bene, purché tu ne conservi la prova.

## Checklist

### A. Prima di creare il progetto

- [ ] Crea l'organizzazione Supabase **a nome tuo, come persona fisica**, con un'email
      personale o del progetto, **non quella del CNR**.
- [ ] Attiva la **verifica in due passaggi** sull'account Supabase.
- [ ] Crea il progetto nella regione **Central EU (Frankfurt)**. Non si cambia dopo.

### B. Il DPA

- [ ] Apri **supabase.com/legal/dpa** e scarica il **PDF** della versione in vigore
      (ultimo trovato: `Supabase DPA 260601.pdf`; la pagina web indica la versione del
      1/8/2026: prendi la più recente).
- [ ] Nel pannello, cerca **Organization › Settings › Legal Documents** (o voce simile).
      Se c'è un DPA da firmare, firmalo e scarica la copia firmata.
- [ ] Controlla nel documento che ci siano:
  - [ ] **Supabase come responsabile** (processor) e tu come **titolare** (controller), clausola 2;
  - [ ] istruzioni documentate, riservatezza del personale, misure di sicurezza
        (allegato: cifratura AES-256 a riposo, TLS in transito, backup);
  - [ ] **clausole contrattuali standard, modulo 2** (titolare → responsabile), legge
        e foro irlandesi;
  - [ ] **sub-responsabili**: autorizzazione generale, preavviso di **30 giorni** per i
        cambi, **5 giorni** per opporsi (clausola 6);
  - [ ] **violazioni**: notifica senza ritardo e, se possibile, **entro 48 ore**
        (clausola 10). Ti serve per rispettare le tue 72 ore verso il Garante;
  - [ ] **audit**: rapporti o certificazioni su richiesta (clausola 9);
  - [ ] **restituzione e cancellazione**: 30 giorni dopo la fine del contratto, poi
        cancellazione anche presso i sub-responsabili (clausola 11);
  - [ ] **regione**: se scegli una regione, Supabase conserva e tratta i dati
        "principalmente" lì (clausola 6.1). "Principalmente" vuol dire che restano
        possibili accessi da fuori (assistenza): è il motivo delle clausole standard.
- [ ] Rinomina e conserva i file: `2026-12-XX_Supabase_DPA.pdf` e uno screenshot del
      pannello con la regione e la data. Mettili fuori dal repository (sono documenti
      tuoi, non del codice), per esempio in una cartella "Pellovi – legale".

### C. Sub-responsabili e trasferimenti

- [ ] Scarica l'**elenco dei sub-responsabili** in vigore (ultimo trovato:
      `supabase.com/legal/subprocessor-list/June-1-2026.pdf`).
- [ ] **Iscriviti agli avvisi** di modifica dei sub-responsabili: senza iscrizione non
      ricevi il preavviso di 30 giorni.
- [ ] Copia nell'informativa (`docs/PRIVACY.md` §5) i sub-responsabili che toccano i
      dati degli utenti: almeno il fornitore cloud (AWS, Francoforte) e quello delle
      email (oggi Postmark), se non usi un SMTP tuo.
- [ ] Scarica la **valutazione d'impatto sul trasferimento** (TIA) di Supabase, se
      disponibile (`Supabase TIA ...pdf`), e conservala con il DPA.

### D. Limiti da rispettare

- [ ] Nessun dato sanitario di **persone** nel database (il DPA vieta i dati "PHI" USA
      senza un accordo a parte). Pellovi tratta dati del cane: va bene, ma non aggiungere
      campi sulla salute del proprietario.
- [ ] La chiave `service_role` resta solo nel pannello o in un gestore di password.

### E. Dopo la firma

- [ ] Completa in `docs/PRIVACY.md` i segnaposto: sub-responsabili, giorni dei backup,
      giorni dei registri tecnici del piano scelto.
- [ ] Aggiorna `docs/REGISTRO-TRATTAMENTI.md` (T1, T2) con le stesse informazioni.
- [ ] Applica la checklist tecnica di `ricerca/11` §6 (regione, limiti email, CAPTCHA,
      backup, advisor).
- [ ] Segna in calendario un controllo **annuale** del DPA e dell'elenco dei
      sub-responsabili.

## Fonti

- Supabase, *Data Processing Addendum*: https://supabase.com/legal/dpa
- Supabase, DPA in PDF (giugno 2026): https://supabase.com/downloads/docs/Supabase+DPA+260601.pdf
- Supabase, elenco dei sub-responsabili (1/6/2026): https://supabase.com/legal/subprocessor-list/June-1-2026.pdf
- GDPR, art. 28 e art. 46: https://eur-lex.europa.eu/eli/reg/2016/679/oj
