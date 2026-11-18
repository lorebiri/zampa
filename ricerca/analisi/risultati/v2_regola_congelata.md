# Previsione v2 — regola congelata prima della verifica fuori banco

*13/11/2026. Scritta e messa in un commit dopo l'esplorazione sul banco realistico (semi standard) e **prima** di eseguire il banco nuovo (`realistico_nuovo`, semi mai usati) e gli altri 7 scenari con il codice dell'app. Non si cambia dopo aver visto quei risultati: se fallisce, si scrive che fallisce.*

## Regola

1. **Candidati** all'origine (1 minuto dopo l'ultima pipì registrata), con i soli dati registrati fino a quel momento:
   - B = orario atteso della previsione di base (quella mostrata oggi, `Forecast.expectedAt`);
   - H = «stesso orario»: per ciascuno degli ultimi 7 giorni, quanto dopo lo stesso orario è arrivata la prima pipì (almeno 0,4 intervalli medi dopo); mediana degli scarti;
   - W = «stesso giorno della settimana»: lo stesso con 7, 14 e 21 giorni prima; se manca, H.
2. **Orario previsto** = mediana di B, H e W. **Sicurezza:** se la previsione di base ha accorciato l'intervallo per gli ultimi 3 giorni (`adaptedRecent`, pipì più frequenti), vale il più anticipato dei tre. Mai prima dell'origine.
3. **Intervallo all'80%** = orario previsto + 7,5° e 92,5° percentile dei residui (pipì vera − orario previsto v2), ricalcolati con origine onesta sugli ultimi 40 eventi del cane (mattino e giorno separati se ce ne sono almeno 8 dello stesso tipo); con meno di 8 residui, la finestra della previsione di base. Inizio non prima dell'origine, ampiezza minima 30 min. **Finestra «di solito» (50%)**: 25°-75° percentile degli stessi residui.
4. **Probabilità nella prossima ora** = hazard empirico del cane: per gli ultimi 60 eventi con esito noto, pseudo-origini ogni 15 minuti da sveglio tra una pipì e la successiva (solo se origine + 60 min ≤ adesso); stato = log(tempo dall'ultima pipì / intervallo previsto v2); frequenza di una pipì entro 60 minuti, pesata con un nucleo gaussiano di 0,25 sullo stato e di 180 minuti sull'ora del giorno, più 10 pseudo-osservazioni alla frequenza media del cane. Massimo 90%. Con meno di 8 eventi o 20 pseudo-origini: la probabilità del modello in ombra se c'è, altrimenti 60/intervallo tipico (5-50%).
5. Tetti, notte, prudenza, allarmi e testi clinici **invariati**: l'uscita consigliata (`recommendedAt`) resta quella della previsione di base, al più anticipata (mai posticipata).

## Verifica prevista

- Banco realistico standard, codice dell'app: soglie di `ricerca/23` §3.3 (R/timer ≤ 0,85; R/«stesso orario» ≤ 1,00; copertura 80% tra 75 e 88%; fasce con n ≥ 50 entro ±10 punti), più T14 (poliuria, errore con segno ≥ −20) e T15 (tetto).
- **Banco nuovo** (`realistico_nuovo`): stesse soglie. È la prova che conta per l'adattamento al banco.
- Altri 7 scenari: R/timer e copertura, descrittivi.
- Riferimento secondario, non usato per decidere: mediana di cinque candidati (B, modello in ombra, H, W, timer).

## Esito della regola congelata e correzione v2.1 (13/11/2026, dopo la verifica)

La regola qui sopra, eseguita con il codice dell'app (`risultati/v2fin_*`), **non supera** la soglia R/timer: 0,87 [0,80–0,94] sul realistico e 0,88 [0,79–0,96] sul banco nuovo. Causa: la regola di sicurezza (punto 2, «il più anticipato») scatta nel 18-21% degli eventi e li anticipa di circa 80 minuti; nell'analisi esplorativa non c'era.

**v2.1, decisa dopo aver visto il banco nuovo** (quindi il banco nuovo non vale più come prova indipendente): punto 2 diventa «se la previsione di base ha accorciato l'intervallo per gli ultimi 3 giorni, l'orario previsto non va oltre quello della previsione di base». Il resto è invariato. Prova indipendente: un terzo banco mai eseguito (`realistico_nuovo2`, seme 2), con le stesse soglie, più lo scenario poliuria per T14.

## v2.2 (13/11/2026): partenza a freddo

Esito v2.1 (`risultati/v21_*`): realistico R/timer 0,84 [0,77–0,90], banco nuovo 0,86, terzo banco 0,87 [0,82–0,92]; R/«stesso orario» 0,98 / 0,95 / 1,00; copertura 80% 81% / 81% / 80%; calibrazione entro ±9 punti in tutte le fasce con n ≥ 50; T14 −4; T15 sempre. Senza la regola di sicurezza la poliuria va in ritardo (−31 min nel sottogruppo del realistico): la regola resta.

Aggiunta (strada 5, decisa sui giorni 1-7, che non entrano nel collaudo): con meno di 3 giorni di storia l'orario previsto è quello della previsione di base. Giorni 1-3: R/timer 0,97 → 0,78.
