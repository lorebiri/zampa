import 'dart:math' as math;

import '../models.dart';
import 'potty_predictor.dart';

/// PREVISIONE DELLA PROSSIMA PIPÌ, VERSIONE 2 (ricerca/27)
///
/// Tre regole semplici e trasparenti, calcolate con i soli dati registrati
/// fino a 1 minuto dopo l'ultima pipì:
///   B = previsione di base (intervallo personale da sveglio, orari
///       abituali, mattino abituale: `Forecast.expectedAt`);
///   H = «stesso orario»: quanto dopo lo stesso orario è arrivata la pipì
///       in ciascuno degli ultimi 7 giorni (mediana);
///   W = «stesso giorno della settimana»: lo stesso 7, 14 e 21 giorni fa.
/// L'orario previsto è la MEDIANA dei tre: quando una regola sbaglia (per
/// esempio il timer nei cani a orari fissi, o l'orario abituale nel fine
/// settimana) le altre due la mettono in minoranza. Se negli ultimi 3 giorni
/// il cane esce più spesso (poliuria che compare) non si va oltre la
/// previsione di base, che ha già accorciato l'intervallo.
///
/// La finestra e la probabilità sono calibrate sugli errori passati del
/// cane, ricalcolati con origine onesta (nessun dato dal futuro):
///   • intervallo all'80%: orario previsto + 7,5° e 92,5° percentile dei
///     residui degli ultimi 40 eventi (mattino e giorno separati);
///   • finestra «di solito» (50%): 25°-75° percentile;
///   • probabilità nella prossima ora: hazard empirico del cane (frequenza
///     di una pipì entro un'ora, in passato, nello stesso stato: tempo
///     dall'ultima pipì rispetto all'intervallo previsto e ora del giorno).
/// Regola congelata in ricerca/analisi/risultati/v2_regola_congelata.md.
/// Tetti, notte, prudenza e allarmi restano quelli della previsione di base.

/// Solo per il banco di prova (ricerca/27): spegne la regola di sicurezza
/// della v2.1 per misurarne il costo. Nell'app resta sempre vera.
// ignore: prefer_const_declarations
bool v2SafetyCapForBench = true;

/// Una previsione v2 fatta a un'origine (1 minuto dopo una pipì).
class V2Point {
  const V2Point({
    required this.origin,
    required this.last,
    required this.at,
    required this.base,
    required this.sameTime,
    required this.sameWeekday,
    required this.earliest,
    required this.morning,
    this.baseWindowStart,
    this.baseWindowEnd,
  });

  /// Origine della previsione e ultima pipì su cui si basa.
  final DateTime origin, last;

  /// Orario previsto (mediana dei candidati, o il più anticipato).
  final DateTime at;

  /// Candidati: previsione di base, stesso orario, stesso giorno.
  final DateTime base, sameTime, sameWeekday;

  /// True se le pipì sono più frequenti negli ultimi giorni (la previsione
  /// non va oltre quella di base).
  final bool earliest;

  /// True se è la prima pipì dopo la notte (base ≥ 5 ore dopo, altro giorno).
  final bool morning;

  /// Finestra della previsione di base (riserva con pochi dati).
  final DateTime? baseWindowStart, baseWindowEnd;
}

/// Livello di fiducia comprensibile, dato dall'ampiezza della finestra
/// «di solito» e dal numero di errori passati su cui è calcolata.
enum V2Confidence { bassa, media, alta }

class PeeForecastV2 {
  const PeeForecastV2({
    required this.point,
    required this.lo80,
    required this.hi80,
    required this.lo50,
    required this.hi50,
    required this.probNextHour,
    required this.alertAt,
    required this.nResiduals,
    required this.confidence,
  });

  final V2Point point;

  /// Orario previsto della prossima pipì.
  DateTime get expectedAt => point.at;

  /// Intervallo all'80% (per il protocollo) e finestra «di solito» (50%).
  final DateTime lo80, hi80, lo50, hi50;

  /// Probabilità di una pipì nella prossima ora (0-0,9).
  final double probNextHour;

  /// Orario dell'avviso «esci»: il primo tra l'uscita consigliata della
  /// previsione di base (con tetti e prudenza) e l'inizio della finestra
  /// «di solito». Il preavviso scelto dall'utente si toglie a parte.
  final DateTime alertAt;

  /// Errori passati del cane su cui sono calcolate le finestre (0 = finestra
  /// della previsione di base).
  final int nResiduals;
  final V2Confidence confidence;

  /// Minuti da [now] all'orario previsto (negativi se è già passato).
  int minutesUntil(DateTime now) => expectedAt.difference(now).inMinutes;
}

/// «Stesso orario» (come `_habitPrediction` di ricerca/analisi/banco.dart):
/// per ciascuno dei giorni [daysBack] prima di [prev], quanto dopo lo
/// stesso orario è arrivata la prima uscita (almeno [minOffset] minuti dopo);
/// previsione = [prev] + mediana degli scarti. Null senza dati.
DateTime? sameTimeForecast(
  List<DateTime> past,
  DateTime prev,
  double cluster,
  Iterable<int> daysBack,
  DateTime firstDay, {
  double minOffset = 0,
}) {
  final offsets = <double>[];
  for (final k in daysBack) {
    final ref = prev.subtract(Duration(days: k));
    if (ref.isBefore(firstDay)) continue;
    final from = ref.add(
      Duration(minutes: math.max(cluster, minOffset).round()),
    );
    DateTime? n;
    for (final o in past) {
      if (o.isAfter(from)) {
        n = o;
        break;
      }
    }
    if (n == null || !n.isBefore(prev)) continue;
    final off = n.difference(ref).inMinutes.toDouble();
    if (off > 18 * 60) continue;
    offsets.add(off);
  }
  if (offsets.isEmpty) return null;
  offsets.sort();
  final m = offsets.length;
  final medOff = m.isOdd
      ? offsets[m ~/ 2]
      : (offsets[m ~/ 2 - 1] + offsets[m ~/ 2]) / 2;
  return prev.add(Duration(minutes: medOff.round()));
}

/// Riferimenti «stesso orario» e «stesso giorno della settimana» per la
/// pipì dopo l'ultima di [past] (uscite ≤ origine, in ordine). [fallback] è
/// l'orario del timer per età e taglia, usato senza storia.
({DateTime sameTime, DateTime sameWeekday, DateTime timer}) referenceForecasts(
  Dog dog,
  List<DateTime> past,
  double cluster,
  double priorMedian,
) {
  final prev = past.last;
  final gaps = <double>[];
  for (var k = 1; k < past.length; k++) {
    final g = past[k].difference(past[k - 1]).inMinutes.toDouble();
    if (g < 600 &&
        !PottyPredictor.inSleepWindow(dog, past[k]) &&
        !PottyPredictor.inSleepWindow(dog, past[k - 1])) {
      gaps.add(g);
    }
  }
  final mean = gaps.isEmpty
      ? priorMedian
      : gaps.reduce((a, b) => a + b) / gaps.length;
  var timer = prev.add(Duration(minutes: mean.round()));
  if (PottyPredictor.inSleepWindow(dog, timer)) {
    timer = PottyPredictor.nextWake(
      dog,
      timer,
    ).add(const Duration(minutes: 15));
  }
  final f = past.first;
  final firstDay = DateTime(f.year, f.month, f.day);
  final minOff = 0.4 * mean;
  final sameTime =
      sameTimeForecast(
        past,
        prev,
        cluster,
        const [1, 2, 3, 4, 5, 6, 7],
        firstDay,
        minOffset: minOff,
      ) ??
      timer;
  final sameWeekday =
      sameTimeForecast(
        past,
        prev,
        cluster,
        const [7, 14, 21],
        firstDay,
        minOffset: minOff,
      ) ??
      sameTime;
  return (sameTime: sameTime, sameWeekday: sameWeekday, timer: timer);
}

/// Orario previsto v2 dai candidati (regola congelata, punto 2).
V2Point combineV2({
  required Dog dog,
  required List<DateTime> past,
  required DateTime origin,
  required DateTime base,
  required bool adaptedRecent,
  required double cluster,
  required double priorMedian,
  DateTime? baseWindowStart,
  DateTime? baseWindowEnd,
}) {
  final last = past.last;
  final refs = referenceForecasts(dog, past, cluster, priorMedian);
  final c = [base, refs.sameTime, refs.sameWeekday]
    ..sort((a, b) => a.compareTo(b));
  // v2.1 (ricerca/27 §3.4): con pipì più frequenti negli ultimi giorni la
  // mediana non va oltre la previsione di base, che è già accorciata. (La
  // regola congelata prendeva il più anticipato dei tre: troppo presto.)
  var at = c[1];
  // Strada 5: nei primi 3 giorni «stesso orario» e «stesso giorno» non hanno
  // ancora storia (sono il timer): vale la sola previsione di base.
  final young = origin.difference(past.first).inDays < 3;
  if (young) at = base;
  if (v2SafetyCapForBench && adaptedRecent && base.isBefore(at)) at = base;
  if (at.isBefore(origin)) at = origin;
  return V2Point(
    origin: origin,
    last: last,
    at: at,
    base: base,
    sameTime: refs.sameTime,
    sameWeekday: refs.sameWeekday,
    earliest: adaptedRecent,
    morning: base.difference(last).inHours >= 5 && base.day != last.day,
    baseWindowStart: baseWindowStart,
    baseWindowEnd: baseWindowEnd,
  );
}

double _quantile(List<double> sorted, double q) {
  if (sorted.length == 1) return sorted.first;
  final pos = q * (sorted.length - 1);
  final lo = pos.floor(), hi = pos.ceil();
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

/// Previsione v2 completa a [now].
///
/// [outings]: uscite registrate ≤ [now], in ordine. [pointAt] restituisce la
/// previsione v2 fatta 1 minuto dopo l'uscita di indice i-1 (per la pipì di
/// indice i) con i soli dati di allora; l'ultima (i = outings.length) è la
/// previsione corrente. [recommendedAt] è l'uscita consigliata della
/// previsione di base. [fallbackProb] è la probabilità oraria di riserva.
PeeForecastV2 buildV2({
  required Dog dog,
  required List<DateTime> outings,
  required DateTime now,
  required V2Point Function(int i) pointAt,
  required DateTime recommendedAt,
  required double fallbackProb,
  int nResidual = 40,
  int nHazard = 60,
}) {
  final n = outings.length;
  final current = pointAt(n);
  // Previsioni passate con esito noto (le più recenti per prime).
  final past = <(V2Point, DateTime)>[];
  for (var i = n - 1; i >= 1 && past.length < nHazard; i--) {
    past.add((pointAt(i), outings[i]));
  }
  double res(V2Point p, DateTime actual) =>
      actual.difference(p.at).inSeconds / 60.0;
  // Gli ultimi [nResidual] dello stesso tipo (mattino o giorno), se almeno
  // 8; altrimenti gli ultimi [nResidual] di qualsiasi tipo.
  var rs = [
    for (final (p, a) in past)
      if (p.morning == current.morning) res(p, a),
  ].take(nResidual).toList();
  if (rs.length < 8) {
    rs = [for (final (p, a) in past.take(nResidual)) res(p, a)];
  }
  rs.sort();

  final at = current.at;
  DateTime shift(double m) => at.add(Duration(seconds: (m * 60).round()));
  DateTime lo80, hi80, lo50, hi50;
  if (rs.length >= 8) {
    lo80 = shift(_quantile(rs, 0.075));
    hi80 = shift(_quantile(rs, 0.925));
    lo50 = shift(_quantile(rs, 0.25));
    hi50 = shift(_quantile(rs, 0.75));
  } else {
    lo80 = current.baseWindowStart ?? at.subtract(const Duration(hours: 1));
    hi80 = current.baseWindowEnd ?? at.add(const Duration(hours: 1));
    if (lo80.isAfter(at)) lo80 = at;
    if (hi80.isBefore(at)) hi80 = at;
    lo50 = at.subtract(Duration(minutes: at.difference(lo80).inMinutes ~/ 2));
    hi50 = at.add(Duration(minutes: hi80.difference(at).inMinutes ~/ 2));
  }
  final origin = current.origin;
  if (lo80.isBefore(origin)) lo80 = origin;
  if (lo50.isBefore(origin)) lo50 = origin;
  if (hi80.difference(lo80).inMinutes < 30) {
    hi80 = lo80.add(const Duration(minutes: 30));
  }
  if (hi50.difference(lo50).inMinutes < 15) {
    hi50 = lo50.add(const Duration(minutes: 15));
  }

  final p = _hazardNextHour(dog, current, past, now) ?? fallbackProb;
  final alert = recommendedAt.isBefore(lo50) ? recommendedAt : lo50;
  final w50 = hi50.difference(lo50).inMinutes;
  final conf = rs.length >= 20 && w50 <= 90
      ? V2Confidence.alta
      : rs.length >= 8 && w50 <= 180
      ? V2Confidence.media
      : V2Confidence.bassa;
  return PeeForecastV2(
    point: current,
    lo80: lo80,
    hi80: hi80,
    lo50: lo50,
    hi50: hi50,
    probNextHour: p,
    alertAt: alert,
    nResiduals: rs.length >= 8 ? rs.length : 0,
    confidence: conf,
  );
}

/// Hazard empirico (regola congelata, punto 4). Null con pochi dati.
double? _hazardNextHour(
  Dog dog,
  V2Point current,
  List<(V2Point, DateTime)> past,
  DateTime now,
) {
  if (past.length < 8) return null;
  double state(V2Point p, DateTime t) {
    final tau = math.max(5.0, t.difference(p.last).inSeconds / 60.0);
    final m = math.max(15.0, p.at.difference(p.last).inSeconds / 60.0);
    return math.log(tau / m);
  }

  double hourOf(DateTime t) => t.hour * 60.0 + t.minute;
  final xs = <double>[], hs = <double>[], ys = <double>[];
  final limit = now.subtract(const Duration(minutes: 60));
  for (final (p, actual) in past) {
    for (
      var t = p.last.add(const Duration(minutes: 15));
      t.isBefore(actual);
      t = t.add(const Duration(minutes: 15))
    ) {
      if (t.isAfter(limit)) break;
      if (PottyPredictor.inSleepWindow(dog, t)) continue;
      xs.add(state(p, t));
      hs.add(hourOf(t));
      ys.add(actual.difference(t).inMinutes <= 60 ? 1 : 0);
    }
  }
  if (xs.length < 20) return null;
  final base = ys.reduce((a, b) => a + b) / ys.length;
  const prior = 10.0, bw = 0.25, hourBw = 180.0;
  final x0 = state(current, now), h0 = hourOf(now);
  var sw = prior, sy = prior * base;
  for (var i = 0; i < xs.length; i++) {
    final z = (xs[i] - x0) / bw;
    var dh = (hs[i] - h0).abs();
    if (dh > 720) dh = 1440 - dh;
    final zh = dh / hourBw;
    final w = math.exp(-0.5 * (z * z + zh * zh));
    sw += w;
    sy += w * ys[i];
  }
  return (sy / sw).clamp(0.0, 0.9);
}
