import 'dart:math' as math;

import '../models.dart';
import 'bio_params.dart';
import 'nutrition.dart';
import 'potty_predictor.dart';

/// MODELLO DI PREVISIONE DEI BISOGNI (pipì e cacca)
///
/// Modello di rischio (hazard) a tempo discreto con passo di 15 minuti:
/// per ogni quarto d'ora stima la probabilità che il cane debba eliminare,
///   h(t) = logistic(β · x(t))
/// con covariate x(t):
///   • tempo dall'ultimo evento, normalizzato sull'intervallo tipico
///     corretto per i fattori biologici (età, taglia, dieta, calore,
///     gravidanza, farmaci, stagione) → log(τ / m) e la sua parte quadratica
///     oltre la mediana (urgenza crescente);
///   • ritmo circadiano (seno/coseno dell'ora) e finestra di sonno;
///   • finestre di effetto di risveglio, pasto (riflesso gastrocolico),
///     acqua bevuta (in ml/kg) e attività.
///
/// Apprendimento bayesiano: la conoscenza della letteratura entra come
/// pseudo-dati generati da un simulatore fisiologico (≈4-5 giorni
/// equivalenti); i dati reali del cane, pesati per recenza, li sostituiscono
/// progressivamente. Stima per massima verosimiglianza penalizzata con il
/// metodo di Newton.
///
/// Dalla curva di sopravvivenza S(t) = Π(1 − h) si ottengono: momento più
/// probabile (mediana), finestra (25°-75° percentile), uscita consigliata
/// (quantile scelto con la "prudenza") e probabilità nella prossima ora.
/// L'accuratezza viene misurata a posteriori sugli ultimi eventi reali.

const int _binMin = 15;
const int _nFeat = 16;

const featureNames = [
  'base',
  'tempo dall\'ultima volta',
  'spline −1',
  'spline −0,5',
  'spline −0,25',
  'spline 0',
  'spline +0,25',
  'spline +0,5',
  'ritmo circadiano (sin)',
  'ritmo circadiano (cos)',
  'sonno',
  'risveglio',
  'pasto',
  'acqua',
  'attività',
  'passeggiata',
];

class _Ev {
  const _Ev(this.time, [this.amount = 1, this.scheduled = false]);
  final DateTime time;
  final double amount;
  final bool scheduled;
}

/// Eventi del cane già ordinati, pronti per il calcolo delle covariate.
class _Context {
  _Context({
    required this.outings,
    required this.indoor,
    required this.meals,
    required this.waters,
    required this.wakes,
    required this.plays,
    required this.walks,
  });

  final List<DateTime> outings;
  final List<bool> indoor;
  final List<_Ev> meals;
  final List<_Ev> waters;
  final List<_Ev> wakes;
  final List<_Ev> plays;
  final List<_Ev> walks;

  static _Context fromLogs(
    Dog dog,
    Need need,
    List<LogEntry> logs,
    DateTime from,
    DateTime to,
  ) {
    // Le pipì con solo gocce non sono una minzione: non azzerano il timer
    // (revisione veterinaria 07 N5).
    final mine =
        logs
            .where(
              (l) =>
                  l.dogId == dog.id &&
                  !(l.type == LogType.pipi && l.signs.contains(Sign.gocce)),
            )
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    final outs = PottyPredictor.outings(
      mine,
      type: need.logType,
      clusterMinutes: need.clusterMinutes,
    );
    List<_Ev> evs(LogType t, [double Function(LogEntry)? amount]) => mine
        .where((l) => l.type == t)
        .map((l) => _Ev(l.time, amount?.call(l) ?? 1))
        .toList();

    final loggedWakes = evs(LogType.risveglio);
    // Risvegli: quelli registrati + l'orario abituale nei giorni senza
    // registrazione.
    final wakes = <_Ev>[...loggedWakes];
    for (
      var d = DateTime(from.year, from.month, from.day);
      d.isBefore(to);
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
      final w = DateTime(d.year, d.month, d.day, dog.wakeHour);
      final logged = loggedWakes.any(
        (e) => e.time.difference(w).inMinutes.abs() < 180,
      );
      if (!logged) wakes.add(_Ev(w, 1, true));
    }
    wakes.sort((a, b) => a.time.compareTo(b.time));
    // Acqua in "dosi" di 10 ml/kg; se la quantità non è nota si assume
    // un sorso medio (5 ml/kg).
    final waters = evs(
      LogType.acqua,
      (l) => ((l.amountMl ?? dog.weightKg * 5) / (dog.weightKg * 10)).clamp(
        0.2,
        2.5,
      ),
    );
    return _Context(
      outings: outs.map((o) => o.time).toList(),
      indoor: outs.map((o) => o.indoor).toList(),
      meals: evs(LogType.pasto),
      waters: waters,
      wakes: wakes,
      plays: evs(LogType.gioco),
      walks: evs(LogType.passeggiata),
    );
  }

  /// Ultimo evento ≤ t (indice), -1 se nessuno.
  int lastOutingIndex(DateTime t) {
    var lo = 0, hi = outings.length - 1, ans = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (!outings[mid].isAfter(t)) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }
}

double _kernelSum(
  List<_Ev> evs,
  DateTime t,
  DateTime cutoff,
  Trigger tr,
  double cap,
) {
  var s = 0.0;
  final horizon = tr.peak + 4 * tr.width;
  // Scorre all'indietro dagli eventi più recenti.
  var hi = evs.length - 1;
  while (hi >= 0 && evs[hi].time.isAfter(t)) {
    hi--;
  }
  for (var i = hi; i >= 0; i--) {
    final e = evs[i];
    final dt = t.difference(e.time).inSeconds / 60.0;
    if (dt > horizon) break;
    if (!e.scheduled && e.time.isAfter(cutoff)) continue;
    s += e.amount * BioParams.kernel(dt, tr);
  }
  return math.min(s, cap);
}

class _Model {
  _Model(this.dog, this.need, this.records);
  final Dog dog;
  final Need need;
  final List<HealthRecord> records;
  final Map<int, double> _modCache = {};

  /// Fattore biologico, calcolato per ora (cambia lentamente).
  double mod(DateTime t) {
    final key = t.millisecondsSinceEpoch ~/ 3600000;
    return _modCache.putIfAbsent(
      key,
      () => BioParams.modifier(need, dog, records, t).factor,
    );
  }

  List<double> features(
    _Context c,
    DateTime t,
    DateTime last,
    DateTime cutoff,
    NeedPrior pr,
  ) {
    final mid = t.add(const Duration(minutes: _binMin ~/ 2));
    final tau = math.max(_binMin / 2, mid.difference(last).inSeconds / 60.0);
    final m = pr.median * mod(t);
    final u = math.log(tau / m);
    final h = mid.hour + mid.minute / 60.0;
    final ang = 2 * math.pi * h / 24;
    return [
      1,
      // Spline lineare a tratti di log(τ/m): permette al modello di imparare
      // una curva di rischio bassa fino al ritmo tipico e poi ripida.
      u,
      math.max(0, u + 1),
      math.max(0, u + 0.5),
      math.max(0, u + 0.25),
      math.max(0, u),
      math.max(0, u - 0.25),
      math.max(0, u - 0.5),
      math.sin(ang),
      math.cos(ang),
      PottyPredictor.inSleepWindow(dog, mid) ? 1 : 0,
      _kernelSum(c.wakes, mid, cutoff, pr.wake, 1),
      _kernelSum(c.meals, mid, cutoff, pr.meal, 1.5),
      _kernelSum(c.waters, mid, cutoff, pr.water, 2.5),
      _kernelSum(c.plays, mid, cutoff, pr.play, 1),
      _kernelSum(c.walks, mid, cutoff, pr.walk, 1),
    ];
  }
}

double _sigmoid(double z) => 1 / (1 + math.exp(-z.clamp(-30, 30)));

double _dot(List<double> a, List<double> b) {
  var s = 0.0;
  for (var i = 0; i < a.length; i++) {
    s += a[i] * b[i];
  }
  return s;
}

/// Funzione di ripartizione normale standard (approssimazione di
/// Abramowitz-Stegun 7.1.26, errore < 1.5e-7).
double _phi(double x) {
  final t = 1 / (1 + 0.3275911 * x.abs() / math.sqrt2);
  final y =
      1 -
      (((((1.061405429 * t - 1.453152027) * t) + 1.421413741) * t -
                      0.284496736) *
                  t +
              0.254829592) *
          t *
          math.exp(-x * x / 2);
  return x >= 0 ? 0.5 * (1 + y) : 0.5 * (1 - y);
}

/// Hazard (per minuto) di una log-normale.
double _lnHazard(double tau, double median, double sigma) {
  final z = (math.log(tau) - math.log(median)) / sigma;
  final pdf = math.exp(-0.5 * z * z) / (tau * sigma * math.sqrt(2 * math.pi));
  final surv = math.max(1e-9, 1 - _phi(z));
  return pdf / surv;
}

class Accuracy {
  Accuracy(this.n, this.medianAbsErrorMin, this.inWindowRate);
  final int n;
  final double medianAbsErrorMin;
  final double inWindowRate;
}

class Forecast {
  Forecast({
    required this.need,
    required this.last,
    required this.recommendedAt,
    required this.expectedAt,
    required this.windowStart,
    required this.windowEnd,
    required this.latestAt,
    required this.probNextHour,
    required this.overdue,
    required this.reason,
    required this.factors,
    required this.confidence,
    required this.learnedDays,
    required this.typicalIntervalMin,
    required this.curve,
    required this.coefficients,
    this.accuracy,
    this.usualMinutes = const [],
  });

  /// Orari abituali (minuti dalla mezzanotte) dalla previsione di base.
  final List<int> usualMinutes;

  final Need need;
  final DateTime? last;
  final DateTime recommendedAt;
  final DateTime expectedAt;
  final DateTime windowStart;
  final DateTime windowEnd;
  final DateTime? latestAt;
  final double probNextHour;
  final bool overdue;
  final String reason;

  /// Fattori biologici attivi che modificano la previsione.
  final List<String> factors;
  final Confidence confidence;

  /// Giorni di dati reali (equivalenti) su cui il modello ha imparato.
  final double learnedDays;

  /// Intervallo tipico appreso da svegli (minuti).
  final double typicalIntervalMin;

  /// Curva di probabilità cumulata (tempo, probabilità 0-1).
  final List<(DateTime, double)> curve;
  final List<double> coefficients;
  final Accuracy? accuracy;
}

class EliminationModel {
  EliminationModel({this.historyDays = 30, this.simDays = 21});

  final int historyDays;
  final int simDays;

  static DateTime _floorBin(DateTime t) =>
      DateTime(t.year, t.month, t.day, t.hour, t.minute - t.minute % _binMin);

  // ---------------------------------------------------------------------
  // Simulatore fisiologico per i pseudo-dati del prior.
  // ---------------------------------------------------------------------
  _Context _simulate(Dog dog, Need need, NeedPrior pr, _Model model) {
    final rnd = math.Random(42 + need.index);
    final start = DateTime(2020, 1, 6);
    final end = start.add(Duration(days: simDays));
    final meals = <_Ev>[], waters = <_Ev>[], plays = <_Ev>[];
    final walks = <_Ev>[];
    final mealsN = dog.mealsPerDay > 0
        ? dog.mealsPerDay
        : Nutrition.mealsFor(dog);
    for (var d = 0; d < simDays; d++) {
      final day = start.add(Duration(days: d));
      final wake = DateTime(day.year, day.month, day.day, dog.wakeHour);
      var sleepH = dog.sleepStartHour;
      if (sleepH <= dog.wakeHour) sleepH += 24;
      final first = wake.add(const Duration(minutes: 45));
      final lastMeal = DateTime(
        day.year,
        day.month,
        day.day,
        sleepH,
      ).subtract(const Duration(hours: 3));
      final span = lastMeal.difference(first).inMinutes;
      final drinkMl = (55 * dog.weightKg) / (mealsN + 2);
      for (var i = 0; i < mealsN; i++) {
        final t = mealsN == 1
            ? first
            : first.add(Duration(minutes: span * i ~/ (mealsN - 1)));
        final jit = Duration(minutes: rnd.nextInt(31) - 15);
        meals.add(_Ev(t.add(jit)));
        waters.add(
          _Ev(
            t.add(jit).add(const Duration(minutes: 10)),
            drinkMl / (dog.weightKg * 10),
          ),
        );
      }
      waters.add(
        _Ev(
          DateTime(day.year, day.month, day.day, 13, rnd.nextInt(60)),
          drinkMl / (dog.weightKg * 10),
        ),
      );
      waters.add(
        _Ev(
          DateTime(day.year, day.month, day.day, 17, rnd.nextInt(60)),
          drinkMl / (dog.weightKg * 10),
        ),
      );
      plays.add(
        _Ev(DateTime(day.year, day.month, day.day, 16, 30 + rnd.nextInt(60))),
      );
      // Passeggiate tipiche di chi vive in appartamento: al risveglio, a
      // metà giornata, nel tardo pomeriggio e prima di dormire.
      for (final h in [0.25, 6.0, 11.0, (sleepH - dog.wakeHour) - 0.5]) {
        walks.add(
          _Ev(
            wake.add(
              Duration(minutes: (h * 60).round() + rnd.nextInt(21) - 10),
            ),
          ),
        );
      }
    }
    walks.sort((a, b) => a.time.compareTo(b.time));
    meals.sort((a, b) => a.time.compareTo(b.time));
    waters.sort((a, b) => a.time.compareTo(b.time));
    final wakes = [
      for (var d = 0; d <= simDays; d++)
        _Ev(
          DateTime(start.year, start.month, start.day + d, dog.wakeHour),
          1,
          true,
        ),
    ];

    // Processo "vero": hazard log-normale moltiplicato dagli inneschi.
    // Un innesco (pasto, acqua, risveglio, passeggiata…) moltiplica il
    // rischio di base: anticipa il bisogno solo se la vescica/il colon sono
    // già abbastanza pieni (05 §PARAMETRI, rapporti di rischio al picco).
    // La scala dell'intervallo di base è calibrata perché l'intervallo
    // mediano da svegli risultante coincida con quello della letteratura.
    List<DateTime> run(double scale, int seed) {
      final rr = math.Random(seed);
      final outs = <DateTime>[];
      var last = start.subtract(const Duration(hours: 1));
      const step = 5;
      for (
        var t = start;
        t.isBefore(end);
        t = t.add(const Duration(minutes: step))
      ) {
        final tau = t.difference(last).inMinutes.toDouble();
        if (tau < need.clusterMinutes) continue;
        final asleep = PottyPredictor.inSleepWindow(dog, t);
        final m =
            pr.median * scale * model.mod(t) / (asleep ? pr.nightRatio : 1);
        var rate = _lnHazard(tau, m, pr.sigma);
        double trig(List<_Ev> evs, Trigger tr) {
          var amount = 0.0;
          for (final e in _window(evs, t)) {
            final dt = t.difference(e.time).inMinutes.toDouble();
            amount += e.amount.clamp(0, 2.5) * BioParams.kernel(dt, tr);
          }
          return 1 + (tr.ratio - 1) * math.min(amount, 2.5);
        }

        if (!asleep) {
          rate *=
              trig(meals, pr.meal) *
              trig(waters, pr.water) *
              trig(wakes, pr.wake) *
              trig(plays, pr.play) *
              trig(walks, pr.walk);
        }
        final cap = asleep ? pr.maxNight : pr.maxDay;
        final p = 1 - math.exp(-rate * step);
        if (tau >= cap || rr.nextDouble() < p) {
          outs.add(t);
          last = t;
        }
      }
      return outs;
    }

    double medianAwakeInterval(List<DateTime> outs) {
      final gaps = <double>[];
      for (var i = 1; i < outs.length; i++) {
        if (PottyPredictor.inSleepWindow(dog, outs[i - 1]) ||
            PottyPredictor.inSleepWindow(dog, outs[i])) {
          continue;
        }
        final g = outs[i].difference(outs[i - 1]).inMinutes.toDouble();
        if (g < pr.maxDay * 1.5) gaps.add(g);
      }
      if (gaps.isEmpty) return pr.median;
      gaps.sort();
      return gaps[gaps.length ~/ 2];
    }

    var scale = 1.0;
    var outs = run(scale, rnd.nextInt(1 << 30));
    for (var it = 0; it < 4; it++) {
      final med = medianAwakeInterval(outs);
      final ratio = pr.median / med;
      if ((ratio - 1).abs() < 0.05) break;
      scale = (scale * math.pow(ratio, 1.3)).clamp(0.5, 6.0);
      outs = run(scale, 1000 + it);
    }
    return _Context(
      outings: outs,
      indoor: List.filled(outs.length, false),
      meals: meals,
      waters: waters,
      wakes: wakes,
      plays: plays,
      walks: walks,
    );
  }

  static List<_Ev> _window(List<_Ev> evs, DateTime t) {
    // Eventi nelle ultime 5 ore (sufficiente per tutti i trigger).
    final from = t.subtract(const Duration(hours: 5));
    return evs
        .where((e) => !e.time.isAfter(t) && e.time.isAfter(from))
        .toList();
  }

  // ---------------------------------------------------------------------
  // Costruzione delle righe di addestramento.
  // ---------------------------------------------------------------------
  void _rows(
    _Model model,
    _Context c,
    NeedPrior pr,
    DateTime from,
    DateTime to,
    double Function(DateTime) weightOf,
    Set<DateTime>? loggedDays,
    List<List<double>> xs,
    List<double> ys,
    List<double> ws,
  ) {
    if (c.outings.isEmpty) return;
    var t = _floorBin(from.isAfter(c.outings.first) ? from : c.outings.first)
        .add(const Duration(minutes: _binMin));
    final maxGap = pr.maxDay * 1.5;
    while (t.add(const Duration(minutes: _binMin)).isBefore(to) ||
        t.add(const Duration(minutes: _binMin)).isAtSameMomentAs(to)) {
      final end = t.add(const Duration(minutes: _binMin));
      final li = c.lastOutingIndex(t.subtract(const Duration(seconds: 1)));
      if (li >= 0) {
        final last = c.outings[li];
        final tau = t.difference(last).inMinutes;
        final day = DateTime(t.year, t.month, t.day);
        final asleep = PottyPredictor.inSleepWindow(model.dog, t);
        final okDay = loggedDays == null || loggedDays.contains(day);
        final okGap = asleep ? tau < pr.maxNight * 1.5 + 600 : tau < maxGap;
        if (okDay && okGap && tau >= model.need.clusterMinutes) {
          final y =
              (li + 1 < c.outings.length && c.outings[li + 1].isBefore(end))
              ? 1.0
              : 0.0;
          xs.add(model.features(c, t, last, t, pr));
          ys.add(y);
          ws.add(weightOf(t));
        }
      }
      t = end;
    }
  }

  static List<double> _fit(
    List<List<double>> xs,
    List<double> ys,
    List<double> ws, {
    double ridge = 0.1,
    int iters = 12,
  }) {
    final beta = List<double>.filled(_nFeat, 0);
    // Inizializzazione: intercetta sulla frequenza media.
    var sy = 0.0, sw = 0.0;
    for (var i = 0; i < ys.length; i++) {
      sy += ws[i] * ys[i];
      sw += ws[i];
    }
    final p0 = ((sy + 0.5) / (sw + 1)).clamp(1e-4, 0.5);
    beta[0] = math.log(p0 / (1 - p0));
    for (var it = 0; it < iters; it++) {
      final g = List<double>.filled(_nFeat, 0);
      final h = List.generate(_nFeat, (_) => List<double>.filled(_nFeat, 0));
      for (var i = 0; i < xs.length; i++) {
        final x = xs[i];
        final p = _sigmoid(_dot(beta, x));
        final r = ws[i] * (p - ys[i]);
        final v = ws[i] * p * (1 - p);
        for (var a = 0; a < _nFeat; a++) {
          g[a] += r * x[a];
          final va = v * x[a];
          for (var b = a; b < _nFeat; b++) {
            h[a][b] += va * x[b];
          }
        }
      }
      for (var a = 0; a < _nFeat; a++) {
        for (var b = 0; b < a; b++) {
          h[a][b] = h[b][a];
        }
        if (a > 0) {
          g[a] += ridge * beta[a];
          h[a][a] += ridge;
        } else {
          h[a][a] += 1e-6;
        }
      }
      final delta = _solve(h, g);
      if (delta == null) break;
      var maxStep = 0.0;
      for (var a = 0; a < _nFeat; a++) {
        final d = delta[a].clamp(-3.0, 3.0);
        beta[a] -= d;
        maxStep = math.max(maxStep, d.abs());
      }
      if (maxStep < 1e-5) break;
    }
    return beta;
  }

  /// Eliminazione di Gauss con pivot parziale.
  static List<double>? _solve(List<List<double>> a0, List<double> b0) {
    final n = b0.length;
    final a = [
      for (final r in a0) [...r],
    ];
    final b = [...b0];
    for (var c = 0; c < n; c++) {
      var p = c;
      for (var r = c + 1; r < n; r++) {
        if (a[r][c].abs() > a[p][c].abs()) p = r;
      }
      if (a[p][c].abs() < 1e-12) return null;
      final tmp = a[c];
      a[c] = a[p];
      a[p] = tmp;
      final tb = b[c];
      b[c] = b[p];
      b[p] = tb;
      for (var r = c + 1; r < n; r++) {
        final f = a[r][c] / a[c][c];
        for (var k = c; k < n; k++) {
          a[r][k] -= f * a[c][k];
        }
        b[r] -= f * b[c];
      }
    }
    final x = List<double>.filled(n, 0);
    for (var r = n - 1; r >= 0; r--) {
      var s = b[r];
      for (var k = r + 1; k < n; k++) {
        s -= a[r][k] * x[k];
      }
      x[r] = s / a[r][r];
    }
    return x;
  }

  // ---------------------------------------------------------------------
  // API pubblica.
  // ---------------------------------------------------------------------

  /// Addestra il modello del cane per il bisogno [need].
  FittedModel fit(
    Dog dog,
    Need need,
    List<LogEntry> logs,
    List<HealthRecord> records,
    DateTime now,
  ) {
    final model = _Model(dog, need, records);
    final literature = BioParams.forNeed(need, dog, now);
    final from = now.subtract(Duration(days: historyDays));
    final ctx = _Context.fromLogs(
      dog,
      need,
      logs,
      from,
      now.add(const Duration(days: 2)),
    );
    final halfLife = dog.ageInMonths(now) < 6 ? 5.0 : 14.0;

    // 0) Bayes empirico: il centro del prior si sposta dal valore di
    //    letteratura al ritmo osservato del cane, in proporzione ai dati
    //    (media dei log-intervalli da svegli, ristretta con 6
    //    pseudo-intervalli verso la letteratura e limitata a ×0,5–×2).
    var sumW = 0.0, sumLog = 0.0;
    for (var i = 1; i < ctx.outings.length; i++) {
      final a = ctx.outings[i - 1], b = ctx.outings[i];
      if (a.isBefore(from)) continue;
      if (PottyPredictor.inSleepWindow(dog, a) ||
          PottyPredictor.inSleepWindow(dog, b)) {
        continue;
      }
      final g = b.difference(a).inMinutes.toDouble();
      if (g < need.clusterMinutes || g > literature.maxDay * 1.5) continue;
      final w = math
          .pow(0.5, now.difference(b).inMinutes / 1440 / halfLife)
          .toDouble();
      // Rimuove l'effetto dei fattori biologici per confrontare a parità.
      sumW += w;
      sumLog += w * math.log(g / model.mod(b));
    }
    const k = 6.0;
    final logM = (sumLog + k * math.log(literature.median)) / (sumW + k);
    final pr = literature.withMedian(
      math.exp(logM).clamp(literature.median * 0.5, literature.median * 2),
    );
    final xs = <List<double>>[];
    final ys = <double>[];
    final ws = <double>[];

    // 1) Prior: pseudo-dati dal simulatore, peso totale ≈ priorDays giorni.
    final sim = _simulate(dog, need, pr, model);
    final simW = pr.priorDays / simDays;
    _rows(
      model,
      sim,
      pr,
      DateTime(2020, 1, 6, dog.wakeHour),
      DateTime(2020, 1, 6).add(Duration(days: simDays)),
      (_) => simW,
      null,
      xs,
      ys,
      ws,
    );
    final nPrior = xs.length;

    // 2) Dati reali pesati per recenza (emivita più breve nei cuccioli,
    //    che cambiano in fretta).
    final loggedDays = {
      for (final t in ctx.outings)
        if (t.isAfter(from)) DateTime(t.year, t.month, t.day),
    };
    _rows(
      model,
      ctx,
      pr,
      from,
      _floorBin(now),
      (t) => math
          .pow(0.5, now.difference(t).inMinutes / 1440 / halfLife)
          .toDouble(),
      loggedDays,
      xs,
      ys,
      ws,
    );
    var realW = 0.0;
    for (var i = nPrior; i < ws.length; i++) {
      realW += ws[i];
    }
    final beta = _fit(xs, ys, ws);
    return FittedModel._(
      model,
      ctx,
      pr,
      beta,
      realW * _binMin / 1440,
      loggedDays.length,
    );
  }
}

String _dur(double m) {
  final h = m ~/ 60, mm = (m % 60).round();
  if (h == 0) return '$mm min';
  if (mm == 0) return h == 1 ? '1 ora' : '$h ore';
  return '$h h $mm min';
}

class FittedModel {
  FittedModel._(
    this._model,
    this._ctx,
    this.prior,
    this.beta,
    this.learnedDays,
    this.daysWithData,
  );

  final _Model _model;
  final _Context _ctx;
  final NeedPrior prior;
  final List<double> beta;
  final double learnedDays;
  final int daysWithData;

  Dog get dog => _model.dog;
  Need get need => _model.need;

  /// Orari abituali dei pasti (minuti dalla mezzanotte) negli ultimi 14 giorni.
  List<int> habitualMealMinutes(DateTime now) {
    final recent =
        _ctx.meals
            .where((e) => now.difference(e.time).inDays < 14)
            .map((e) => e.time.hour * 60 + e.time.minute)
            .toList()
          ..sort();
    if (recent.isEmpty) return const [];
    final days = {
      for (final e in _ctx.meals)
        if (now.difference(e.time).inDays < 14)
          DateTime(e.time.year, e.time.month, e.time.day),
    }.length;
    final clusters = <List<int>>[];
    for (final m in recent) {
      if (clusters.isEmpty || m - clusters.last.last > 90) {
        clusters.add([m]);
      } else {
        clusters.last.add(m);
      }
    }
    return [
      for (final c in clusters)
        if (c.length >= math.max(2, days * 0.4)) c[c.length ~/ 2],
    ];
  }

  /// Contesto con i pasti futuri attesi (abitudini) a partire da [now].
  _Context _withFuture(DateTime now, {DateTime? extraOuting}) {
    final meals = [..._ctx.meals];
    for (final mm in habitualMealMinutes(now)) {
      for (var d = 0; d <= 1; d++) {
        final t = DateTime(now.year, now.month, now.day + d, mm ~/ 60, mm % 60);
        if (!t.isAfter(now)) continue;
        final already = _ctx.meals.any(
          (e) => e.time.difference(t).inMinutes.abs() < 90,
        );
        if (!already) meals.add(_Ev(t, 1, true));
      }
    }
    meals.sort((a, b) => a.time.compareTo(b.time));
    final outs = [..._ctx.outings];
    final indoor = [..._ctx.indoor];
    if (extraOuting != null) {
      outs.add(extraOuting);
      indoor.add(false);
    }
    return _Context(
      outings: outs,
      indoor: indoor,
      meals: meals,
      waters: _ctx.waters,
      wakes: _ctx.wakes,
      plays: _ctx.plays,
      walks: _ctx.walks,
    );
  }

  double _hazard(_Context c, DateTime t, DateTime last, DateTime cutoff) =>
      _sigmoid(_dot(beta, _model.features(c, t, last, cutoff, prior)));

  /// Quantili del tempo al prossimo evento a partire dall'ultimo [last],
  /// sapendo che fino a [now] non è successo.
  ({
    Map<double, DateTime> q,
    double pastProb,
    double probNextHour,
    List<(DateTime, double)> curve,
  })
  _quantiles(
    _Context c,
    DateTime last,
    DateTime now,
    List<double> qs, {
    int horizonHours = 36,
  }) {
    // Probabilità già "accumulata" tra l'ultimo evento e adesso.
    var sPast = 1.0;
    for (
      var t = EliminationModel._floorBin(last)
          .add(const Duration(minutes: _binMin));
      t.isBefore(EliminationModel._floorBin(now));
      t = t.add(const Duration(minutes: _binMin))
    ) {
      sPast *= 1 - _hazard(c, t, last, now);
    }
    final pastProb = 1 - sPast;
    final res = <double, DateTime>{};
    for (final q in qs) {
      if (pastProb >= q) res[q] = now;
    }
    final curve = <(DateTime, double)>[];
    var sFut = 1.0;
    var probNextHour = 0.0;
    var t = EliminationModel._floorBin(now);
    final end = now.add(Duration(hours: horizonHours));
    while (t.isBefore(end) && res.length < qs.length) {
      sFut *= 1 - _hazard(c, t, last, now);
      final tEnd = t.add(const Duration(minutes: _binMin));
      final cdf = 1 - sPast * sFut;
      curve.add((tEnd, cdf));
      if (!tEnd.isAfter(now.add(const Duration(minutes: 60)))) {
        probNextHour = 1 - sFut;
      }
      for (final q in qs) {
        if (!res.containsKey(q) && cdf >= q) {
          // Interpolazione lineare all'interno del quarto d'ora.
          final prev = curve.length > 1 ? curve[curve.length - 2].$2 : pastProb;
          final frac = cdf > prev ? ((q - prev) / (cdf - prev)).clamp(0, 1) : 1;
          final at = t.add(Duration(seconds: (frac * _binMin * 60).round()));
          res[q] = at.isBefore(now) ? now : at;
        }
      }
      t = tEnd;
    }
    // Prosegue la curva per il grafico (fino a 12 ore).
    final plotEnd = now.add(const Duration(hours: 12));
    while (t.isBefore(plotEnd)) {
      sFut *= 1 - _hazard(c, t, last, now);
      t = t.add(const Duration(minutes: _binMin));
      curve.add((t, 1 - sPast * sFut));
    }
    for (final q in qs) {
      res.putIfAbsent(q, () => end);
    }
    return (
      q: res,
      pastProb: pastProb,
      probNextHour: probNextHour,
      curve: curve.where((p) => !p.$1.isAfter(plotEnd)).toList(),
    );
  }

  Forecast forecast(DateTime now, {bool withAccuracy = true}) {
    final c = _withFuture(now);
    final li = c.lastOutingIndex(now);
    final reasons = BioParams.modifier(need, dog, _model.records, now).reasons;
    final noun = need.label;
    if (li < 0) {
      return Forecast(
        need: need,
        last: null,
        recommendedAt: now,
        expectedAt: now,
        windowStart: now,
        windowEnd: now.add(Duration(minutes: prior.median.round())),
        latestAt: null,
        probNextHour: 0.5,
        overdue: false,
        reason:
            'Non ho ancora nessuna $noun registrata: segna la prossima e '
            'inizio a imparare il ritmo di ${dog.name}.',
        factors: reasons,
        confidence: Confidence.bassa,
        learnedDays: 0,
        typicalIntervalMin: prior.median,
        curve: const [],
        coefficients: beta,
      );
    }
    final last = c.outings[li];
    final accidents = _ctx.indoor.indexed
        .where((e) => e.$2 && now.difference(_ctx.outings[e.$1]).inDays <= 14)
        .length;
    final bio = BioParams.modifier(need, dog, _model.records, now);
    var prudence = dog.prudence;
    // "Meno uscite" solo per adulti sani (revisione veterinaria 06 §30).
    if (prudence == Prudence.bassa &&
        (lifeStageOf(dog, now) != LifeStage.adulto ||
            dog.conditions.trim().isNotEmpty ||
            bio.factor < 0.95)) {
      prudence = Prudence.normale;
    }
    var qRec = prudence.quantile;
    if (need == Need.pipi && accidents > 0) qRec = math.min(qRec, 0.15);
    // Il modello resta calcolato "in ombra" (curva e coefficienti, per il
    // banco di prova), ma ciò che si mostra viene dalla previsione di base
    // finché il modello non supera il collaudo (piano CEO 11.3, ricerca/12).
    final r = _quantiles(c, last, now, [qRec, 0.25, 0.5, 0.75]);
    final base = Baseline.compute(
      dog: dog,
      times: [
        for (final t in _ctx.outings)
          if (!t.isAfter(now)) t,
      ],
      now: now,
      fallbackMin: prior.median * bio.factor,
      prudenceQuantile: qRec,
      maxGapMin: prior.maxDay * 1.5,
      minGapMin: need.clusterMinutes.toDouble(),
    );
    // Farmaci o malattie che aumentano la pipì: l'intervallo personale si
    // accorcia subito, senza aspettare 3 giorni di dati (verso prudente).
    final k =
        need == Need.pipi &&
            bio.factor < 1 &&
            base.nIntervals >= 4 &&
            !base.adaptedRecent
        ? bio.factor
        : 1.0;
    DateTime at(double m) => last.add(Duration(minutes: (m * k).round()));
    var recommended = at(base.recommendedAfterMin);
    var expected = at(base.intervalMin);
    var wStart = at(base.windowStartMin);
    var wEnd = at(base.windowEndMin);
    String hm(int m) =>
        '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
    final usual = base.habitualMinutes.map(hm).join(', ');
    var reason = base.nIntervals < 4
        ? 'Sto ancora imparando il ritmo di ${dog.name}: per ora uso valori '
              'tipici per età e taglia.'
        : 'In base al suo intervallo abituale da sveglio '
              '(circa ${_dur(base.intervalMin)}).';
    if (need == Need.cacca) {
      // Per la cacca nessun orario puntuale: solo le abitudini (11.3).
      final h = base.nextHabitual(now);
      if (h != null) {
        recommended = h;
        expected = h;
        wStart = h.subtract(const Duration(minutes: 30));
        wEnd = h.add(const Duration(minutes: 45));
      }
      reason = usual.isEmpty
          ? 'Registra qualche giorno di cacche per vedere i suoi orari abituali.'
          : 'Di solito la fa verso le $usual.';
    } else {
      final h = base.nextHabitual(
        last.add(Duration(minutes: (base.intervalMin * 0.4).round())),
      );
      if (h != null && h.isAfter(now) && h.isBefore(recommended)) {
        recommended = h;
        reason = 'È uno dei suoi orari abituali di uscita.';
      } else if (base.adaptedRecent) {
        reason =
            'Negli ultimi giorni fa pipì più spesso del solito: ho '
            'accorciato l\'intervallo.';
      }
    }
    final overdue = !recommended.isAfter(now);
    if (overdue) {
      recommended = now;
      if (need == Need.pipi) {
        reason = 'È ora: è passato il suo intervallo abituale.';
      }
    }
    if (expected.isBefore(recommended)) expected = recommended;

    // Tetti di sicurezza (solo pipì) e gestione della notte.
    // Il tetto per età si accorcia con malattie e farmaci che aumentano la
    // pipì, mai sotto i 120 minuti (revisione veterinaria 06 §27-28).
    DateTime? latest;
    final f = bio.factor < 1 ? bio.factor : 1.0;
    final dayCapMin = math.max(120.0, prior.maxDay * f);
    final nightCapMin = math.max(180.0, prior.maxNight * f);
    String dur(double m) => _dur(m);

    if (need == Need.pipi) {
      latest = last.add(Duration(minutes: dayCapMin.round()));
      final asleep = PottyPredictor.inSleepWindow(dog, recommended);
      if (!asleep && recommended.isAfter(latest)) {
        // Il tetto vale anche se è già superato (07 N8).
        final passed = !latest.isAfter(now);
        recommended = passed ? now : latest;
        reason = passed
            ? 'Ha superato ${dur(dayCapMin)} dall\'ultima pipì: portalo fuori adesso.'
            : f < 1 && bio.reasons.isNotEmpty
            ? 'Con ${bio.reasons.join(', ')} ha bisogno di uscire più spesso: '
                  'non farlo aspettare oltre ${dur(dayCapMin)}.'
            : 'Non conviene aspettare oltre: è il limite consigliato per '
                  'la sua età (un tetto, non un obiettivo).';
      }
    }
    if (PottyPredictor.inSleepWindow(dog, recommended)) {
      final wake = PottyPredictor.nextWake(dog, recommended);
      final nightCap = last.add(Duration(minutes: nightCapMin.round()));
      // Inizio della finestra di sonno che contiene "recommended".
      var bed = DateTime(
        recommended.year,
        recommended.month,
        recommended.day,
        dog.sleepStartHour,
      );
      if (bed.isAfter(recommended)) bed = bed.subtract(const Duration(days: 1));
      final beforeBed = bed.subtract(const Duration(minutes: 15));
      if (need == Need.pipi && nightCap.isBefore(wake)) {
        final puppy = dog.ageInMonths(now) < 6;
        if (!puppy &&
            beforeBed.isAfter(now) &&
            beforeBed.isAfter(last) &&
            wake.difference(beforeBed).inMinutes <= nightCapMin) {
          recommended = beforeBed;
          latest = bed;
          reason =
              'Dall\'ultima pipì passerebbero più di ${dur(nightCapMin)}: '
              'fallo uscire prima di dormire. Se di notte chiede di uscire, '
              'assecondalo.';
        } else {
          recommended = nightCap.subtract(const Duration(minutes: 15));
          if (recommended.isBefore(now)) recommended = now;
          latest = nightCap;
          reason = puppy
              ? 'È un cucciolo: non riesce ancora a trattenerla per tutta '
                    'la notte. Prevedi un\'uscita notturna.'
              : 'Dall\'ultima pipì passerebbero più di ${dur(nightCapMin)}: '
                    'prevedi un\'uscita prima di dormire o durante la notte.';
        }
        if (expected.isBefore(recommended)) expected = recommended;
      } else {
        recommended = wake.add(Duration(minutes: prior.wake.peak.round()));
        if (expected.isBefore(recommended)) expected = recommended;
        if (wStart.isBefore(wake)) wStart = wake;
        if (wEnd.isBefore(expected)) {
          wEnd = expected.add(const Duration(minutes: 45));
        }
        reason = 'Di notte dorme: prima uscita al risveglio.';
      }
    }

    // Note cliniche sui promemoria (07, tabella I).
    if (need == Need.pipi && bio.reasons.contains('cistite')) {
      reason += ' Non ridurre l\'acqua: bere aiuta.';
    }
    final postOp = _model.records.any(
      (r) =>
          r.dogId == dog.id &&
          r.type == RecordType.intervento &&
          r.done &&
          !r.date.isAfter(now) &&
          now.difference(r.date).inDays < 14,
    );
    if (postOp) {
      reason =
          'Dopo l\'intervento: uscita breve al guinzaglio solo per i '
          'bisogni. $reason';
    }
    if (dog.ageInMonths(now) < 6 &&
        PottyPredictor.inSleepWindow(dog, recommended)) {
      reason +=
          ' Se dorme tranquillo nel trasportino puoi aspettare il suo '
          'segnale.';
    }

    final acc = withAccuracy ? accuracy(now) : null;
    final conf = learnedDays < 2
        ? Confidence.bassa
        : (acc != null && acc.n >= 8 && acc.inWindowRate >= 0.55)
        ? Confidence.alta
        : Confidence.media;
    return Forecast(
      need: need,
      last: last,
      recommendedAt: recommended,
      expectedAt: expected.isBefore(recommended) ? recommended : expected,
      windowStart: wStart,
      windowEnd: wEnd,
      latestAt: latest,
      probNextHour: r.probNextHour,
      overdue: overdue,
      reason: reason,
      factors: reasons,
      confidence: conf,
      learnedDays: learnedDays,
      typicalIntervalMin: base.intervalMin * k,
      curve: r.curve,
      coefficients: beta,
      accuracy: acc,
      usualMinutes: base.habitualMinutes,
    );
  }

  /// Intervallo mediano previsto da sveglio senza inneschi (ore centrali).
  double typicalInterval(DateTime now) {
    final base = DateTime(now.year, now.month, now.day, 10);
    final c = _Context(
      outings: [base],
      indoor: const [false],
      meals: const [],
      waters: const [],
      wakes: const [],
      plays: const [],
      walks: const [],
    );
    final r = _quantiles(c, base, base, [0.5], horizonHours: 24);
    return r.q[0.5]!.difference(base).inMinutes.toDouble();
  }

  /// Verifica a posteriori: per ciascuno degli ultimi eventi reali,
  /// cosa avrebbe previsto il modello subito dopo l'evento precedente?
  Accuracy? accuracy(DateTime now) {
    final outs = _ctx.outings;
    final errors = <double>[];
    var inWindow = 0;
    for (var i = math.max(1, outs.length - 20); i < outs.length; i++) {
      final prev = outs[i - 1];
      final actual = outs[i];
      if (now.difference(actual).inDays > 14) continue;
      final gap = actual.difference(prev).inMinutes;
      if (gap > prior.maxDay * 1.5 + 600) continue;
      final from = prev.add(const Duration(minutes: 1));
      final r = _quantiles(_ctx, prev, from, [
        0.25,
        0.5,
        0.75,
      ], horizonHours: 30);
      final med = r.q[0.5]!;
      errors.add(actual.difference(med).inMinutes.abs().toDouble());
      if (!actual.isBefore(r.q[0.25]!.subtract(const Duration(minutes: 15))) &&
          !actual.isAfter(r.q[0.75]!.add(const Duration(minutes: 15)))) {
        inWindow++;
      }
    }
    if (errors.length < 3) return null;
    errors.sort();
    return Accuracy(
      errors.length,
      errors[errors.length ~/ 2],
      inWindow / errors.length,
    );
  }

  /// Piano delle uscite consigliate per la giornata di [day].
  List<DateTime> dailyPlan(DateTime day) {
    final wake = DateTime(day.year, day.month, day.day, dog.wakeHour);
    var t = wake.add(Duration(minutes: prior.wake.peak.round()));
    final plan = <DateTime>[t];
    var guard = 0;
    while (guard++ < 20) {
      final c = _withFuture(t, extraOuting: t);
      final r = _quantiles(c, t, t, [dog.prudence.quantile], horizonHours: 24);
      var next = r.q[dog.prudence.quantile]!;
      if (need == Need.pipi) {
        final cap = t.add(Duration(minutes: prior.maxDay.round()));
        if (next.isAfter(cap)) next = cap;
      }
      if (next.difference(t).inMinutes < 30) {
        next = t.add(const Duration(minutes: 30));
      }
      if (PottyPredictor.inSleepWindow(dog, next)) break;
      plan.add(next);
      t = next;
    }
    if (need == Need.pipi) {
      final bedH = dog.sleepStartHour;
      final bed = DateTime(day.year, day.month, day.day, bedH)
          .add(Duration(days: bedH < dog.wakeHour ? 1 : 0))
          .subtract(const Duration(minutes: 15));
      if (bed.difference(plan.last).inMinutes > 60) plan.add(bed);
    }
    return plan;
  }
}
