# Attivare gli account di Zampa (Supabase, server UE)

Gli account sono **facoltativi**: senza questa configurazione l'app funziona
come prima, con i dati solo sul telefono. Questi passaggi li fai tu, perché
richiedono i tuoi account e le tue chiavi.

## 1. Progetto Supabase (gratuito per partire)
1. Crea un account su <https://supabase.com> e un nuovo progetto.
2. **Region: Central EU (Frankfurt)**: i dati restano nell'UE (GDPR).
3. Nel progetto apri **SQL Editor**, incolla tutto `supabase/schema.sql` ed esegui.
4. In **Project Settings › API** copia *Project URL* e la chiave *publishable* (anon).

## 2. Accesso con email (codice a 6 cifre)
- **Authentication › Providers › Email**: attivo.
- **Authentication › Email Templates › Magic Link**: inserisci `{{ .Token }}` nel testo,
  così l'email contiene il codice da digitare nell'app.

## 3. Accedi con Apple (obbligatorio su iPhone se c'è Google)
Serve l'**Apple Developer Program** (99 €/anno).
1. developer.apple.com › Identifiers: sull'App ID `it.zampa.zampa` attiva *Sign in with Apple*.
2. In Xcode (`ios/Runner.xcworkspace`) › Runner › *Signing & Capabilities*: aggiungi *Sign in with Apple*.
3. Supabase › Authentication › Providers › **Apple**: attiva e aggiungi `it.zampa.zampa`
   tra i *Client IDs*.

## 4. Continua con Google
1. <https://console.cloud.google.com> › APIs & Services › Credentials: crea
   - un *OAuth client ID* di tipo **Web** (serve a Supabase),
   - uno di tipo **iOS** (bundle `it.zampa.zampa`) e uno **Android** (con l'impronta SHA-1).
2. Supabase › Providers › **Google**: attiva, incolla il *Client ID* e il *Secret* del client Web,
   e attiva *Skip nonce check* solo se richiesto per iOS.
3. iOS: in `ios/Runner/Info.plist` aggiungi lo *URL scheme* invertito del client iOS
   (`com.googleusercontent.apps.yyyyyyyy`).

## 5. Collegare l'app
Copia `config/supabase.example.json` in `config/supabase.json` (questo file **non** va
condiviso né caricato su GitHub: è già escluso) e inserisci i valori. Poi:

```bash
flutter run --dart-define-from-file=config/supabase.json
```

## Come funziona
- **Offline prima di tutto:** l'app lavora sempre sui dati locali e sincronizza qualche
  secondo dopo ogni modifica, quando c'è rete.
- **Famiglia:** Profilo › Account e famiglia › *Invita un familiare* crea un codice
  valido 7 giorni; chi lo inserisce vede e aggiorna i dati di quel cane.
- **Sicurezza:** regole a livello di riga (RLS): ogni utente vede solo i cani di cui è membro.
- **Eliminazione account:** dall'app (richiesto da Apple e dal GDPR); i cani di cui
  l'utente è proprietario vengono cancellati dal server, anche per i familiari.
- **Foto:** per ora restano sul telefono e non vengono sincronizzate.

## Da fare prima della pubblicazione
- Informativa privacy e termini (bozza in `docs/PRIVACY.md`), nomina di Supabase come
  responsabile del trattamento (DPA di Supabase).
- Provare l'accesso Apple/Google su dispositivo vero.
