# Prima di rendere pubblico il repository (e GitHub Pages)

Controllo fatto il 13/11/2026 su tutto il codice e su **tutta la cronologia git** (94 commit, tutti i
branch). Nessuna azione è stata fatta: decide Lorenzo.

## Segreti: niente da ruotare

Cercati nel codice e in ogni versione passata dei file: chiavi Supabase di servizio (`sb_secret_`,
`service_role`, token JWT), chiavi private (`BEGIN … PRIVATE KEY`), chiavi Google (`AIza…`), token
GitHub, Slack, Anthropic e Stripe, password, file `.env`, `config/*.json`, keystore Android
(`.jks`, `.keystore`, `key.properties`), `google-services.json` e certificati Apple.

**Esito: nessun segreto, oggi e in passato.** L'unico file di configurazione mai salvato è
`config/supabase.example.json`, che contiene solo segnaposti. `config/supabase.json` è in
`.gitignore`. Non c'è niente da ruotare.

Da ricordare:
- la chiave `anon`/publishable di Supabase e la chiave **pubblica** VAPID possono stare nella web
  app: sono pubbliche per natura;
- la chiave `service_role`, la chiave **privata** VAPID, `CRON_SECRET` e il keystore Android
  vanno solo nei segreti di Supabase o di GitHub, mai nel repository;
- la CI controlla già a ogni push che non entrino segreti (`ci.yml`, «Nessun segreto nel codice»).

## Dati personali che diventerebbero pubblici

| Cosa | Dove | Proposta |
|---|---|---|
| Email personale di Lorenzo come autore di 59 commit | Cronologia git (intestazioni dei commit) | Per i commit futuri usare l'email «noreply» di GitHub. Per quelli passati serve riscrivere la cronologia (vedi sotto) |
| Percorso del computer con nome utente e «OneDrive-CNR» | `.claude/launch.json` | Toglierlo dal repository e aggiungerlo a `.gitignore` |
| Dossier su lavoro al CNR e fisco | `ricerca/14-cnr-e-fisco.md` | Non pubblicarlo |
| Piano economico, stime di guadagno, scelte del CEO | `ricerca/03-business-model.md`, `ricerca/08-piano-ceo.md`, `DOSSIER.md` §2 | Probabilmente non pubblicarli |
| Ricerche su marchi e concorrenti | `ricerca/01`, `ricerca/13`, `ricerca/25` | A scelta |
| Bozza di contratto con il veterinario | `docs/clinica/lettera-incarico-veterinario.md` | A scelta |
| Nome di Lorenzo come titolare del trattamento | `docs/PRIVACY.md` e documenti privacy | Va bene: l'informativa deve dirlo |

## Come pubblicare senza esporre questi file

Togliere un file oggi non basta: resta nella cronologia, visibile a tutti. Ci sono due strade:

1. **Consigliata: un repository pubblico nuovo per l'app.** Questo resta privato, con ricerca e
   documenti interni. Il nuovo parte da un solo commit con il codice dell'app (`lib/`, `web/`,
   `android/`, `ios/`, `test/`, `tool/`, `supabase/`, `.github/`, `docs/` senza i documenti
   interni). Pages si attiva lì. Nessuna riscrittura di cronologia, e nulla si perde.
2. **Rendere pubblico questo** dopo aver riscritto la cronologia con `git filter-repo`, togliendo i
   file della tabella e cambiando l'email degli autori. È distruttivo: cambia tutti gli
   identificativi dei commit, e chi ha copie del repository deve riclonarlo.

## GitHub Pages

- Workflow: `.github/workflows/pages.yml`. Pubblica a ogni push su `main` e a ogni tag `v*`, su
  `https://lorebiri.github.io/<nome-repo>/`, oppure sul dominio della variabile `PAGES_DOMAIN`.
- Una volta sola: Settings › Pages › Source: «GitHub Actions».
- La pagina di download punta a `releases/latest/download/pellovi.apk`, cioè all'APK dell'ultima
  Release creata dal workflow «Rilascio». Funziona solo con il repository pubblico.
- Facoltative, come variabili del repository: `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
  `VAPID_PUBLIC_KEY`, per avere account e promemoria nella web app pubblicata.
- Provato in locale con lo stesso indirizzo (`/zampa/`): app, service worker, apertura offline e
  link all'APK funzionano.
