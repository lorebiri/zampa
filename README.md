# Pellovi

App per la salute del cane (Flutter): web app installabile (PWA, anche per iPhone) e APK Android: cartella sanitaria, prevenzione,
nutrizione, allarmi clinici rivisti da veterinari, previsione di pipì e cacca con un modello
bayesiano, compagno in pixel art, account facoltativi con sincronizzazione (Supabase UE).

- **Piano e decisioni:** [`ricerca/08-piano-ceo.md`](ricerca/08-piano-ceo.md) (il CEO decide priorità e cicli).
- **Panoramica:** [`DOSSIER.md`](DOSSIER.md) · rapporti di ricerca in [`ricerca/`](ricerca/).
- **Account:** [`supabase/LEGGIMI.md`](supabase/LEGGIMI.md) · privacy (beta, da completare): [`docs/PRIVACY.md`](docs/PRIVACY.md).

## Sviluppo

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome                                   # senza account
flutter run --dart-define-from-file=config/supabase.json  # con account (file non nel repo)
tool/build_web.sh                                       # web app per l'hosting (vedi INSTALLA.md)
flutter build apk --release                             # APK Android
```

Installazione e pubblicazione: [`INSTALLA.md`](INSTALLA.md) · web app e APK: [`LULU-WEB-REPORT.md`](LULU-WEB-REPORT.md).

Pellovi non è un dispositivo medico e non sostituisce il veterinario.
