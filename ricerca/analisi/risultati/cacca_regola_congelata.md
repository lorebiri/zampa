# Cacca v3 — regola congelata prima della verifica

*13/11/2026. Scritta e messa in un commit PRIMA di eseguire i banchi di verifica (realistico con tutti gli eventi, `realistico_nuovo`, `realistico_nuovo2`, scenari). Esplorazione fatta SOLO su `realistico`, un evento su tre (477 cacche, 32 cani).*

## Regola (codice: `lib/logic/poop_forecast.dart`, `poopCandidates`)

Origine: 1 minuto dopo la cacca precedente registrata; solo log ≤ origine.

1. **M, ancore.** Orari abituali (gruppi larghi ≤ 90 min presenti in ≥ 35% dei giorni, ultimi 14 giorni) dei pasti segnati e delle uscite (pipì segnate). Per ogni orario abituale, probabilità del cane = (cacche entro la finestra dopo l'ancora quando il colon era «pronto» + 3 × valore tipico) / (occasioni pronte + 3), ultimi 21 giorni. Finestre: pasto da +10 a +150 min, uscita da −10 a +40 min. «Pronto» = almeno 0,65 × intervallo mediano tra cacche dall'ultima cacca (con meno di 4 intervalli: mediana per età di 05 §P7). Valori tipici: pasto 0,30 (cucciolo 0,45), uscita 0,25 (0,35); ritardo pasto 40 min (25), uscita 8 min. Ancore prima della prontezza: probabilità × (tempo/pronto) × 0,5. Più una componente «spontanea»: Kaplan-Meier del tempo da sveglio dall'ultima cacca, con le cacche arrivate a un'ancora come dati censurati. M = primo orario in cui la sopravvivenza combinata scende sotto 0,5 (entro 30 h; altrimenti intervallo tipico).
2. **H, W:** «stesso orario» (ultimi 7 giorni) e «stesso giorno della settimana» (7, 14, 21 giorni), scarto minimo 0,4 × intervallo medio di tutte le cacche (< 30 h).
3. **T:** timer (intervallo medio da sveglio < 10 h, come il riferimento del banco).
4. **Orario previsto = mediana di M, H, W, T** (media dei due centrali). Nei primi 3 giorni vale M. Mai prima dell'origine.
5. **Finestre:** orario previsto + 10°-90° (80%) e 25°-75° (50%) percentile dei residui passati del cane (ultime 30 cacche, ≤ 21 giorni, previsioni rifatte con origine onesta); con meno di 8 residui −3 h/+4 h e −1 h/+2 h.

## Esplorazione (realistico, un evento su tre)

| Metodo | R/timer [IC 95%] |
|---|---|
| H «stesso orario» | 0,96 [0,84–1,08] |
| M ancore (prima versione) | 1,63 |
| M ancore (finale) | 0,91 [0,82–1,00] |
| Mediana M, H, W | 0,84 |
| Mediana H, W, T (senza pasti) | 0,76 [0,68–0,87] |
| **Mediana M, H, W, T (regola)** | **0,80 [0,72–0,88]** |

Prontezza provata a 0,35 / 0,5 / 0,65 / 0,8: v3 0,82 / 0,83 / 0,80 / 0,87; scelto 0,65. Avvertenza dichiarata prima della verifica: senza M la mediana fa un po' meglio sull'esplorazione (0,76). Tengo M nella regola perché è l'unico candidato che usa i pasti e lo stato del colon; se sui banchi di verifica la mediana senza M è migliore lo dirò, senza cambiare la regola.

## Criteri di successo fissati ora

- **Primario:** R/timer della regola ≤ 0,85 con limite superiore IC < 1,00 sul realistico (tutti gli eventi) **e** su almeno uno dei due banchi nuovi.
- Secondari: copertura della finestra all'80% tra 70% e 90%; errore con segno mediano tra −30 e +30 min.
