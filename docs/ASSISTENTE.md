# Pellovi più intelligente (blocco D)

## D1. Consigli proattivi «Oggi per <nome>» (gratis, sul dispositivo)

L'app sa già quasi tutto quello che serve. Le scadenze sono in `logic/prevention.dart`,
la stagione e la razza in `logic/seasonal.dart`, porzioni e calorie in `logic/nutrition.dart`,
gli allarmi in `logic/alerts.dart` e i bisogni in `logic/potty_predictor.dart`. Manca un livello che
scelga **3-5 cose concrete da fare oggi** e le metta in cima alla Home (vedi
`docs/design/home-*.png`).

Progetto: `lib/logic/today.dart`, una funzione pura `todayFor(dog, store, now) → List<TodayItem>`.
Ogni `TodayItem` ha `id` stabile, `tipo`, `titolo`, `perché`, `azione` (es. apri un modulo),
`priorità` e `fattoOggi`. Le regole, in ordine di priorità:

1. allarmi SUBITO/OGGI: non entrano nella lista, restano sopra come oggi; la lista si riduce a 1-2 cose;
2. dosi di oggi da confermare;
3. scadenze entro 7 giorni (vaccini, richiami, antiparassitari, test filariosi) e superate;
4. stagione e zona (processionaria, forasacchi, zecche, caldo all'ora dell'uscita);
5. peso: non pesato da oltre 30 giorni (14 nel cucciolo), o fuori dall'intervallo della razza;
6. pappa: porzione del giorno dalla nutrizione già calcolata;
7. attività consigliata per età, taglia, brachicefalia e meteo;
8. un segnale da tenere d'occhio dai diari (es. acqua in aumento sotto la soglia d'allarme).

Spunte «fatto» salvate per giorno. Testi brevi, del tu, emoji solo fuori dagli allarmi, **nessun
testo clinico nuovo** senza passare dalla revisione veterinaria (catalogo `docs/clinica`).
Test: scenari in `test/clinical_scenarios.dart` più un test per regola.

Non è implementato in questa sessione: qui Flutter non si installa e il codice non si potrebbe
né compilare né testare.

## D2. Assistente con l'API di Claude (progetto, NON attivato)

### Architettura

```
App (web/Android) ──HTTPS + JWT utente──▶ Supabase Edge Function «chiedi-a-lulu» ──▶ API Claude
                                              │  • verifica login e limiti d'uso
                                              │  • legge il contesto del cane (solo quel cane)
                                              │  • allarmi attivi calcolati dall'app
                                              └─ registra solo i contatori (non le domande)
```

- **La chiave API non entra mai nell'app.** Sta nei segreti della Edge Function
  (`ANTHROPIC_API_KEY`). Funzione in TypeScript (Deno) con l'SDK ufficiale `@anthropic-ai/sdk`.
- **Solo con l'account** (serve per i limiti e per la sicurezza della chiave).
- **Contesto**: l'app manda un riassunto strutturato del cane che ha già calcolato: età, razza,
  sesso e sterilizzazione, peso e andamento, terapie, scadenze, diari degli ultimi 14 giorni e
  **allarmi attivi con il loro testo rivisto dai veterinari**. Niente foto, niente nome del
  proprietario, niente posizione precisa.
- **Allarme in corso → niente modello.** Se c'è un allarme SUBITO, l'app non chiama l'assistente:
  mostra l'allarme e i pulsanti «Chiama il veterinario» ed «Emergenze». Lo stesso fa la funzione
  se riceve parole d'emergenza (respira male, gengive blu, convulsioni, addome gonfio, ha mangiato
  veleno…): risponde con il testo fisso EMG-022 del catalogo.
- **Risposta in streaming**, `max_tokens` 1.500, testo semplice.

### Modello e parametri

- Proposta: **`claude-opus-5-5`** (il modello più capace per le regole di sicurezza), con
  `output_config.effort: "low"` (domande brevi; l'effort basso riduce i costi) e
  `fallbacks: "default"` (beta `server-side-fallback-2026-07-01`): se un filtro di sicurezza
  rifiuta, la richiesta passa da sola a un modello adatto.
- Alternative più economiche, da valutare con una prova sulle stesse domande:
  `claude-sonnet-5-5` o `claude-haiku-5-5`. La scelta spetta a Lorenzo (tabella costi sotto).
- **Prompt caching** sul prompt di sistema (identico per tutti): costa circa 1/20.

### Prompt di sistema (bozza)

```
Sei l'assistente di Pellovi, un'app italiana che aiuta i proprietari a prendersi cura del cane.
Parli in italiano, dai del tu, frasi brevi e concrete, tono caldo ma serio.

Cosa fai:
- Rispondi a domande sul cane descritto in <cane>, usando solo quei dati e conoscenze generali
  affidabili di cura del cane (alimentazione, attività, prevenzione, comportamento, igiene).
- Spieghi le scadenze, le porzioni e gli avvisi che l'app ha già calcolato, con parole semplici.
- Se un dato manca, dillo e suggerisci come registrarlo nell'app.

Cosa non fai mai:
- Non fai diagnosi e non dici quale malattia ha il cane.
- Non indichi farmaci, dosi o cambi di terapia: per questo serve il veterinario.
- Non contraddici né ammorbidisci gli avvisi in <allarmi>: sono stati rivisti da medici
  veterinari. Se una domanda tocca un avviso, riportalo così com'è e invita a seguirne l'azione.
- Non rassicuri su sintomi nuovi o che peggiorano: suggerisci di sentire il veterinario.

Urgenze: se l'utente descrive fatica a respirare, gengive pallide o blu, addome gonfio con
conati a vuoto, convulsioni, collasso, sospetto avvelenamento, trauma, sangue abbondante,
sforzo a urinare senza urina (soprattutto nel maschio) o un cucciolo abbattuto con vomito e
diarrea: rispondi solo con «Vai subito dal veterinario o al pronto soccorso veterinario, anche
di notte.» e ricorda il pulsante Emergenze dell'app. Nient'altro.

Niente emoji quando parli di salute o di sintomi. Chiudi le risposte su un tema di salute con:
«Pellovi non sostituisce il veterinario.»
```

L'app aggiunge poi `<cane>…</cane>` e `<allarmi>…</allarmi>` come dati, dopo il prompt in cache.
Le domande dell'utente sono dati, non istruzioni.

### Limiti d'uso

- **20 domande al giorno e 200 al mese per utente** (tabella `assistente_uso` con RLS e un
  contatore atomico nella funzione); oltre, messaggio gentile.
- Domanda massima 1.000 caratteri; storia della conversazione massima 6 messaggi.
- Limite globale di spesa nella Console Anthropic, più un avviso via email al 50% e all'80%.
- **Registri**: solo conteggi e token, mai il testo delle domande (privacy).

### Costo stimato per utente al mese

Ipotesi per domanda: prompt di sistema ~3.000 token (in cache), dati del cane e conversazione
~3.000 token, risposta con ragionamento ~700 token. Prezzi API attuali per milione di token.

| Modello | $/domanda (circa) | Uso medio, 20 domande/mese | Uso intenso, 100 domande/mese |
|---|---|---|---|
| Claude Opus 5.5 ($4 in / $20 out, cache $0,20) | ~0,027 $ | ~0,55 $ | ~2,70 $ |
| Claude Sonnet 5.5 ($2 / $10, cache $0,10) | ~0,013 $ | ~0,27 $ | ~1,30 $ |
| Claude Haiku 5.5 ($0,10 / $0,50) | ~0,001 $ | ~0,02 $ | ~0,10 $ |

Sono stime da verificare con una prova reale (`usage` nelle risposte). Il tetto di 200 domande
limita il caso peggiore a ~5,40 $/mese per utente con Opus 5.5.

### Privacy e regole

Novità nel trattamento: i dati sanitari del cane vanno ad Anthropic (fornitore extra-UE).
Bisogna aggiornare informativa, DPIA e registro dei trattamenti, e chiedere un **consenso
separato**, disattivato di default. Da valutare l'elaborazione in UE (`inference_geo`) se
disponibile. Va chiesta anche una revisione veterinaria del prompt di sistema, con una batteria di
domande di prova (urgenze, dosi, diagnosi richieste esplicitamente) da usare come test prima del
lancio.

### Decisioni di Lorenzo

1. Attivarlo sì o no, e con quale modello (costo in tabella).
2. Gratis con i limiti sopra, oppure solo in un piano a pagamento.
3. Chiave API e limite di spesa nella Console Anthropic (non chiesti in questa sessione).
