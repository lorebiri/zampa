# 22 — Direzione visiva: "Libretto e passeggiata"

*10 novembre 2026 · visual designer · ramo `worktree-agent-a282cfa00ff6312ff`*

Il fondatore ha detto che l'app "ha una grafica bruttina". Aveva ragione: era il tema Material di default (colore seme verde acqua, carattere di sistema, schede grigie tutte uguali), con tre problemi veri sopra l'estetica:

- la scheda «Dosi da confermare» era **illeggibile in tema scuro** (testo chiaro su crema fisso, circa 1,1:1);
- in scuro la **gerarchia degli allarmi si invertiva** (ATTENZIONE più luminosa di OGGI, SUBITO rosa chiaro);
- il compagno in pixel art, cioè la cosa che fa sorridere sia Marina (54 anni, rapporto 20) sia Nina (28 anni, rapporto 21), era piccolo dentro un riquadro grigio, con un pennello da 18 px che nessuno trovava.

Questo documento descrive la nuova identità, cosa è stato applicato nel codice e cosa resta.

---

## 1. Idea

**L'app è un libretto sanitario che esce a passeggio.** Due mondi convivono e non si confondono:

| Mondo | Cosa ci sta | Come appare |
|---|---|---|
| **Il libretto** (fiducia) | cartella, scadenze, dosi, allarmi, emergenze | blu inchiostro, carta chiara, forme più squadrate quanto più la cosa è seria |
| **La passeggiata** (calore) | previsione dell'uscita, registrazione rapida, compagno | senape del sole del mattino, salvia del parco, forme morbide |

La regola che tiene tutto insieme: **più una cosa è seria, più è squadrata.** Gli allarmi hanno raggio 10, le schede 18, la previsione 24, il compagno 28. Il pulsante Emergenze e gli allarmi SUBITO sono gli unici blocchi rossi pieni dell'app.

Il punto di audacia è uno solo: la **console del compagno** (corpo salvia, schermo LCD incassato con cornice) e, subito sotto, l'orario **«Esci alle 07:05»** in cifre grandi. Tutto il resto è quieto.

## 2. Tavolozza

### Chiaro

| Ruolo | Nome | Codice | Uso |
|---|---|---|---|
| Primario | Blu libretto | `#22406A` | titoli attivi, pulsanti principali, icone; 10,4:1 su bianco |
| Contenitore primario | Blu carta | `#DCE6F4` / testo `#0F2747` | scheda della previsione |
| Calore | Senape | `#F2B53A` / chiaro `#FCEBC2` / testo `#4A3300` | indicatore della barra, iniziale del cane, previsione imminente, pulsante «Registra» |
| Compagno | Salvia | `#3D6A4C` / chiaro `#DDEAD8` / testo `#12301D` | corpo della console, convalescenza |
| Fondo | Carta salvia | `#F2F4EF` | sfondo delle pagine (volutamente non crema) |
| Schede | Bianco | `#FFFFFF`, bordo `#D3DAD1` | nessuna ombra |
| Testo | Inchiostro | `#18212E` (14,6:1), secondario `#4A5566` (6,8:1) | |

### Scuro: la passeggiata serale

| Ruolo | Codice |
|---|---|
| Fondo | `#0F1722` (blu notte, non nero) |
| Schede | `#172131`, rilievo `#1F2B3D`, bordo `#34425A` |
| Testo | `#E7EBF2`, secondario `#AEB8C8` (8,1:1 sulle schede) |
| Primario | `#A9C6F0` |
| Senape | `#F2C064`, contenitore `#4A3812` |
| Salvia | `#A6D1B1`, contenitore `#24402F` |

### Livelli di allarme (colori propri, non derivati dal seme)

| Livello | Forma | Chiaro (fondo / testo / accento) | Scuro | Contrasto testo |
|---|---|---|---|---|
| **SUBITO** | blocco rosso pieno, bordo 3 dp, icona 30, parola 18 pt | `#B42318` / bianco / `#7A1209` | uguale (rosso pieno in entrambi) | 6,6:1 |
| **OGGI** | banda sinistra 8 dp + bordo, icona 26, parola 16 pt | `#FDE6E0` / `#6E1A0D` / `#C0391B` | `#41201A` / `#FFD9CF` / `#FF8F6E` | 9,7 / 11,1 |
| **ATTENZIONE** | banda sinistra 5 dp, bordo sottile, icona 24 | `#FFF2CC` / `#4D3700` / `#A36F00` | `#3A3014` / `#FBE6AC` / `#F2C064` | 10,1 / 10,6 |
| **INFO** | nessuna banda, nessuna parola | `#E6EDF7` / `#1B355A` / `#3D6AA8` | `#1C2A3E` / `#D5E2F5` / `#8DB3E8` | 10,5 / 11,1 |

Ogni livello si riconosce da **quattro segnali ridondanti**: posizione (SUBITO e OGGI sopra il compagno), forma (blocco, banda spessa, banda sottile, niente), **parola grande** e **icona** diversa. Il colore è il quinto. In scuro OGGI ha ora una banda più spessa e un bordo pieno: non può più sembrare meno importante di ATTENZIONE. I contrasti sono verificati in un test automatico (`test/visual_a11y_test.dart`).

Il compagno **non usa mai** i colori o le icone degli allarmi (rapporto 16, §5.4). L'uscita imminente usa la senape del brand, non l'arancione: un'uscita vicina non è un problema di salute.

## 3. Tipografia

**Atkinson Hyperlegible Next** (Braille Institute, licenza SIL OFL 1.1), inclusa in `assets/fonts/` con il file `OFL.txt` e dichiarata in `pubspec.yaml`: nessun download a runtime.

Perché questo carattere: è disegnato per chi vede poco (I, l e 1 non si confondono; 0 e O nemmeno; aperture larghe), quindi serve Marina con gli occhiali da vicino. Allo stesso tempo è un grottesco contemporaneo con un disegno riconoscibile, non il Roboto di default, e non sembra "app per anziani". Una sola famiglia, sei pesi.

| Stile | Corpo / interlinea | Peso | Uso |
|---|---|---|---|
| displayMedium | 48 / 1,05, spaziatura −1,2 | 800 | l'orario dell'uscita |
| displaySmall | 40 | 800 | nome dell'app nel benvenuto |
| headlineMedium | 28 / 1,18 | 700 | nome del cane, titoli di pagina |
| titleLarge | 21 / 1,25 | 700 | titoli di sezione (intestazioni semantiche) |
| titleMedium | 17 / 1,3 | 600 | titoli di scheda e di allarme |
| bodyLarge | **17** / 1,45 | 400 | testo principale (prima 16) |
| bodyMedium | **15,5** / 1,45 | 400 | testo delle schede (prima 14) |
| bodySmall | 13,5 / 1,4 | 400 | note, sempre ≥ 6,8:1 |
| labelLarge | 15,5 | 600 | pulsanti |

Le parole dei livelli (SUBITO, OGGI, ATTENZIONE, IN RITARDO) restano in maiuscolo perché sono un segnale clinico, non un'etichetta decorativa; altrove non c'è maiuscoletto.

## 4. Forme, spaziature, componenti

- **Griglia da 4**: 4, 8, 12, 16, 24, 32; margine di pagina 16; fondo pagina 112 per non finire sotto il pulsante «Registra».
- **Raggi**: allarmi 10 · chip 12 · campi 14 · schede 18 · previsione 24 · compagno 28 · pulsanti a pillola.
- **Nessuna ombra.** Le schede bianche si staccano dal fondo salvia con un bordo da 1 px; i blocchi importanti (previsione, compagno, allarmi) sono pieni di colore. Così non si ha la "griglia di schede tutte uguali".
- **Pulsanti** alti 52 dp (56 per «Fatta fuori» e «In casa»), area di tocco minima 48 dp su tutte le piattaforme (`MaterialTapTargetSize.padded`).
- **Registrazione rapida**: i chip sono diventati pulsanti da 48 dp (i lettori di schermo li annunciavano come caselle di controllo).
- **Barra in basso**: indicatore a pillola senape, etichette sempre visibili; con testo oltre il 130% resta l'etichetta della sola voce attiva, così non viene tagliata (pronta anche per lingue più lunghe). Icone più parlanti: sole per Oggi, battito per Salute, ciotola per Nutrizione.
- **Schede di Salute** scorrevoli (reggono il tedesco e il testo grande).
- **Campi**: riempiti, bordo da 14, aiuto fino a 4 righe (prima i suggerimenti venivano tagliati con «…»).

## 5. Il compagno in pixel art

- vive in una **console**: corpo salvia (in scuro blu rilievo), schermo LCD verde incassato con cornice; di notte lo schermo diventa blu notte, come prima;
- il cane è più grande (200 px invece di 170) e il riquadro è a tutta larghezza;
- il messaggio è sotto lo schermo, allineato a sinistra, più leggibile;
- **«Cambia aspetto»** è un pulsante con la parola (prima un pennello da 18 px che Marina non aveva capito);
- gli indicatori sono **valori da leggere, non barre da riempire** (07 N42), impaginati come righe di un libretto (etichetta a sinistra, valore a destra, reggono testo grande e lingue lunghe): «Ultima pipì · 1 h 20 min fa», «Pasti · 2/2», «Uscite oggi · 4». L'indicatore «Bisogno» a quadratini, che nessuno capiva, è sostituito dal tempo dall'ultima pipì;
- **riduci movimento**: con l'impostazione di sistema attiva il cane resta fermo e non scodinzola al tocco;
- **lettori di schermo**: il disegno è escluso, la console si legge come «Luna, il tuo compagno. [messaggio]» e ogni indicatore come «Uscite oggi: 4»;
- con un allarme SUBITO la console sparisce e lascia il posto al blocco rosso statico (regola 07 N39, invariata).

I testi di `PetMood` non sono stati toccati: li sta correggendo il coordinatore sul ramo principale (accordo di genere).

## 6. Prima e dopo

Schermate in `ricerca/design/`, formato telefono 400×880, build web di rilascio, cane di esempio. Erano le 23 passate, quindi il compagno è nella posa notturna.

| Prima | Dopo |
|---|---|
| `prima-1-avvertenza.jpg`: testo centrato su tre blocchi grigi, Roboto, icona verde acqua | `dopo-1-avvertenza-chiaro.jpg`: testo a sinistra, avvertenza in un riquadro informativo, due punti con icona, casella di conferma in un riquadro da 56 dp |
| (benvenuto: zampa verde, testo centrato) | `dopo-1-benvenuto-chiaro.jpg`: il compagno nella sua console apre l'app, frase guida in blu libretto |
| `prima-2-oggi-chiaro.jpg`: tema Material, compagno piccolo in un riquadro grigio, «Bisogno» a quadratini, Emergenze come asterisco rosa | `dopo-2-oggi-chiaro.jpg`: console salvia, indicatori come righe di libretto, «Cambia aspetto», pulsante «Emergenze» rosso con parola, ATTENZIONE con banda |
| `prima-3-dosi-scuro.jpg`: dose in ritardo illeggibile (crema fisso, testo chiaro), «Saltato» sbiadito | `dopo-4-dosi-scuro.jpg`: dose in ritardo con tono ATTENZIONE scuro, parola «IN RITARDO», «Dato» e «Saltato» separati |
| | `dopo-3-previsione-scuro.jpg`: «Esci alle **07:05**» con l'orario in 48 pt, affidabilità come testo e non come chip |

Nota sul carattere: lo zero di Atkinson Hyperlegible ha la barra («0»), voluta dal disegno per non confonderlo con la O. Si nota negli orari; è una scelta di leggibilità e si può discutere.

## 7. Cosa è stato chiuso dei rapporti 16, 20 e 21

| Punto | Stato |
|---|---|
| P1 dosi illeggibili in scuro; altre schede crema fisse (nutrizione, diari) | **Chiuso**: tutte su `NoticeCard` con colori del tema, testo ≥ 9:1 |
| P2 gerarchia e livelli non solo colore | **Chiuso** per le schede (forma, parola, icona, colore); respiri nel diario: anche l'icona cambia forma |
| SnackBar che non spariva | **Chiuso**: 4 s, `persist: false` |
| P11 bersagli ≥ 48 dp | **Chiuso** per dosi, registrazione rapida, pennello, campioni colore, barra; «Saltato» con conferma **non fatto** (è un cambio di comportamento) |
| P5 intestazioni e etichette | **In parte**: titoli di sezione come intestazioni, compagno e indicatori etichettati, allarmi annunciati; grafici ancora senza riassunto testuale |
| P9 riduci movimento | **Chiuso** per il compagno; il cambio di scheda ha una dissolvenza di 160 ms che si azzera con la stessa impostazione |
| N42 indicatori | **Chiuso** lato presentazione (numeri, «Uscite oggi», niente barra) |
| P14 Emergenze con etichetta | **Chiuso**: pulsante rosso «Emergenze»; con testo grande va su una riga sua |
| P12 testo al 200% | **In parte**: riga della dose, previsione, intestazione, indicatori, barra e schede di Salute reggono (test automatico al 200% su 400×880 senza overflow); le etichette dei campi del modulo possono ancora essere tagliate |
| P13 lingue | Layout più robusti; l'estrazione delle stringhe non è compito di questo lavoro |
| 21: tema scuro «grigio-verde spento» | **Chiuso**: blu notte con senape e salvia |
| 21: avvertenza «bugiardino» | **Migliorato** visivamente; il contenuto (legale/clinico) non è cambiato |

## 8. Cosa resta da fare

1. **Riassunti testuali dei grafici** (curva di probabilità, ultimi 14 giorni, peso, diari) per i lettori di schermo.
2. **Modulo del cane** (`dog_form.dart`): eredita il tema ma resta lungo; serve la procedura guidata del rapporto 21 (lavoro di prodotto, non solo di aspetto). Etichette dei campi lunghe ancora tagliabili.
3. **Icona dell'app e splash** coerenti (senape + profilo del cane in pixel): non toccati, aspettano il nome definitivo.
4. **Illustrazioni leggere** per gli stati vuoti (nessuna scadenza, nessuna registrazione) con il compagno in pixel: non fatte.
5. **PDF per il veterinario**: usa ancora Helvetica senza «–»; andrebbe incluso Atkinson anche lì.
6. **Prova su telefono vero** del carattere a 130-200% di sistema (sul web il testo del browser non viene ingrandito).
7. Quando il nome sarà scelto: cambiare `appName` in `lib/brand.dart` e la voce `name`/titoli in `web/` e nei manifest nativi.
