# Piano di uscite — regola, esito e correzione dichiarata

*13/11/2026.*

## Regola v3.0 (parametri scritti prima di qualsiasi esecuzione, `PlanParams` nel commit `5cd8b36`; nessuna taratura)

Tenuta log-normale σ 0,3 imparata da incidenti (eventi), uscite senza incidente (censurati) e segnali («C ≈ 2 × carico», peso 0,5); partenza 2 × tetto diurno; carico = sveglio + 0,4 × sonno + 40 min per pasto; programmazione dinamica su orari ogni 15 min con padrone a casa e sveglio, ≥ 60 min tra uscite; penalità 0,3 oltre il tetto.

Esito (tutti i 32 cani, `v3piano_s0_*.txt`, `v3piano_s1_*.txt`): vedi `ricerca/28` §3.3. Due difetti visti sui banchi dei semi 0 e 1:
1. con i segnali il rischio stimato è 4 volte quello vero (3,5-4,2 incidenti di pipì a settimana previsti contro 0,9 veri): segnali lievi, falsi e della cacca abbassano la tenuta stimata;
2. il piano ignora la cacca: con 3 uscite le cacche in casa aumentano (103 contro 92 degli orari fissi, seme 0).

## Correzione v3.1 (dichiarata DOPO aver visto i semi 0 e 1)

1. I segnali non entrano più nella tenuta (`signalsInHold = false`): servono solo a «Esci adesso».
2. Termine per la cacca: un intervallo senza uscite che copre tutta la finestra della cacca attesa (orario previsto dalla cacca v3.1 → +4 ore) costa 0,5 incidenti attesi [IPOTESI].

**Verifica su un banco mai eseguito: seme 2**, tutte le strategie. Criterio fissato ora: con lo stesso numero di uscite (± 0,3 al giorno) il piano ha meno incidenti degli orari fissi, oppure lo stesso numero di incidenti (IC sovrapposti) con almeno 0,5 uscite al giorno in meno.
