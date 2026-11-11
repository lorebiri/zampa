# Zampa (nome provvisorio)

App per la salute del cane (Flutter: iOS, Android, web): cartella sanitaria, prevenzione,
nutrizione, allarmi clinici rivisti da veterinari, previsione di pipì e cacca con un modello
bayesiano, compagno in pixel art, account facoltativi con sincronizzazione (Supabase UE).

- **Piano e decisioni:** [`ricerca/08-piano-ceo.md`](ricerca/08-piano-ceo.md) (il CEO decide priorità e cicli).
- **Panoramica:** [`DOSSIER.md`](DOSSIER.md) · rapporti di ricerca in [`ricerca/`](ricerca/).
- **Account:** [`supabase/LEGGIMI.md`](supabase/LEGGIMI.md) · privacy (bozza): [`docs/PRIVACY.md`](docs/PRIVACY.md).

## Sviluppo

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome                                   # senza account
flutter run --dart-define-from-file=config/supabase.json  # con account (file non nel repo)
```

Per iOS compilare da una copia fuori da OneDrive (gli attributi estesi dei file
sincronizzati possono rompere la firma del codice).

Zampa non è un dispositivo medico e non sostituisce il veterinario.
