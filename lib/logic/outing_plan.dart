import 'dart:math' as math;

import '../models.dart';
import 'bio_params.dart';
import 'poop_forecast.dart';
import 'potty_predictor.dart';

/// PIANO DI USCITE (ricerca/28 §3)
///
/// Per chi ha il cane in appartamento senza giardino: dato lo storico del
/// cane e gli orari del padrone (lavoro, sonno, giorni festivi), propone gli
/// orari di N uscite (N scelto dal padrone, per esempio 3, 4 o 5) che
/// rendono minimo il numero atteso di incidenti in casa, e mostra per ogni
/// opzione il rischio stimato. Si rifà ogni giorno e dopo ogni uscita non
/// prevista, con i dati nuovi.
///
/// Modello del rischio (semplice e spiegabile):
///   • «carico» della vescica tra due uscite = minuti da sveglio + 0,4 ×
///     minuti di sonno + 40 minuti per ogni pasto (l'acqua dopo il pasto)
///     [05 §P2: di notte si produce meno urina; IPOTESI sui pesi];
///   • il cane ha una «tenuta» propria C (in minuti di carico): rischio di
///     incidente in un intervallo = P(C < carico), log-normale con σ 0,3;
///   • C si impara dallo storico: incidenti in casa (C ≈ carico), uscite
///     senza incidente (C > carico, dato censurato), partendo da 2 × il
///     tetto diurno per età (`BioParams.pee.maxDay`) [IPOTESI]. I segnali non
///     entrano nella tenuta (v3.1, ricerca/28 §3.4): servono a «Esci adesso».
/// Il tetto diurno per età e malattia resta un limite: un intervallo che lo
/// supera è penalizzato e segnalato, anche se il rischio stimato è basso.

/// Orari del padrone.
class OwnerSchedule {
  const OwnerSchedule({
    this.awayWeekdays = const [],
    this.awayWeekend = const [],
    this.wakeWeekday,
    this.bedWeekday,
    this.wakeWeekend,
    this.bedWeekend,
    this.holidays = const {},
  });

  /// Fuori casa (minuti dalla mezzanotte, inizio-fine) nei giorni feriali e
  /// nel fine settimana.
  final List<(int, int)> awayWeekdays, awayWeekend;

  /// Sveglia e ora di andare a letto (minuti); null = profilo del cane.
  final int? wakeWeekday, bedWeekday, wakeWeekend, bedWeekend;

  /// Giorni festivi (data senza ora): come il fine settimana.
  final Set<DateTime> holidays;

  bool isFree(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return day.weekday >= 6 || holidays.contains(d);
  }

  List<(int, int)> awayOn(DateTime day) =>
      isFree(day) ? awayWeekend : awayWeekdays;

  int wakeOn(Dog dog, DateTime day) =>
      (isFree(day) ? wakeWeekend : wakeWeekday) ?? dog.wakeHour * 60;

  int bedOn(Dog dog, DateTime day) {
    final b =
        (isFree(day) ? bedWeekend : bedWeekday) ?? dog.sleepStartHour * 60;
    return b < 12 * 60 ? b + 24 * 60 : b; // dopo mezzanotte
  }

  /// True se alle [t] il padrone è a casa e sveglio.
  bool available(Dog dog, DateTime t) {
    final day = DateTime(t.year, t.month, t.day);
    final m = t.hour * 60 + t.minute;
    // Notte dopo mezzanotte: vale il giorno prima.
    final prev = day.subtract(const Duration(days: 1));
    if (m + 24 * 60 < bedOn(dog, prev)) return true;
    if (m < wakeOn(dog, day) || m >= bedOn(dog, day)) return false;
    for (final (a, b) in awayOn(day)) {
      if (m >= a && m < b) return false;
    }
    return true;
  }
}

/// Un piano per un giorno.
class OutingPlan {
  const OutingPlan({
    required this.n,
    required this.times,
    required this.expectedAccidents,
    required this.overCap,
    required this.gapRisks,
  });

  /// Numero di uscite del piano (comprese quelle già fatte oggi).
  final int n;

  /// Orari delle uscite ancora da fare.
  final List<DateTime> times;

  /// Incidenti attesi da adesso fino alla prima uscita di domani.
  final double expectedAccidents;

  /// True se almeno un intervallo supera il tetto per età e salute.
  final bool overCap;

  /// Rischio di ciascun intervallo (dopo l'ultima uscita, poi tra le uscite,
  /// l'ultimo è la notte).
  final List<double> gapRisks;

  /// Incidenti attesi a settimana, se ogni giorno fosse come oggi.
  double get perWeek => expectedAccidents * 7;
}

/// Parametri del modello di rischio (congelati con la regola, ricerca/28).
class PlanParams {
  const PlanParams({
    this.sleepWeight = 0.4,
    this.mealLoad = 40,
    this.sigma = 0.3,
    this.priorFactor = 2.0,
    this.priorSd = 0.35,
    this.signalFactor = 2.0,
    this.capPenalty = 0.3,
    this.step = 15,
    this.historyDays = 21,
    this.signalsInHold = false,
    this.poopWeight = 0.5,
    this.poopWait = 240,
  });

  /// v3.1: costo (incidenti attesi) di un intervallo senza uscite che copre
  /// tutta la finestra della cacca attesa (dall'orario previsto a [poopWait]
  /// minuti dopo) [IPOTESI].
  final double poopWeight;
  final int poopWait;

  /// Regola congelata: i segnali entravano nella tenuta («C ≈ 2 × carico»).
  /// Sul banco gonfiavano il rischio stimato di 4 volte (segnali lievi,
  /// falsi e della cacca): ora i segnali servono solo a «Esci adesso».
  final bool signalsInHold;
  final double sleepWeight, mealLoad, sigma, priorFactor, priorSd;
  final double signalFactor, capPenalty;
  final int step, historyDays;
}

double _phi(double x) {
  // Funzione di ripartizione normale (Abramowitz-Stegun 7.1.26).
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

/// Modello della tenuta del cane, imparato dallo storico fino a [now].
class HoldModel {
  HoldModel._(this.dog, this.mu, this.p, this.meals, this.capMin, this.n);

  final Dog dog;

  /// log della tenuta mediana (minuti di carico).
  final double mu;
  final PlanParams p;

  /// Orari abituali dei pasti (minuti dalla mezzanotte).
  final List<int> meals;

  /// Tetto diurno per età e salute (minuti), dalla previsione di base.
  final double capMin;

  /// Intervalli usati per imparare.
  final int n;

  double get medianHold => math.exp(mu);

  static List<int> _mealSlots(List<LogEntry> logs, DateTime now) {
    final from = now.subtract(const Duration(days: 14));
    final mins = [
      for (final l in logs)
        if (l.type == LogType.pasto &&
            l.time.isAfter(from) &&
            !l.time.isAfter(now))
          l.time.hour * 60 + l.time.minute,
    ]..sort();
    final groups = <List<int>>[];
    for (final m in mins) {
      if (groups.isNotEmpty && m - groups.last.first <= 90) {
        groups.last.add(m);
      } else {
        groups.add([m]);
      }
    }
    final days = math.max(
      1,
      mins.isEmpty
          ? 1
          : math.min(
              14,
              now
                  .difference(
                    logs
                        .where((l) => l.type == LogType.pasto)
                        .map((l) => l.time)
                        .reduce((a, b) => a.isBefore(b) ? a : b),
                  )
                  .inDays,
            ),
    );
    return [
      for (final g in groups)
        if (g.length >= 0.35 * days && g.length >= 2) g[g.length ~/ 2],
    ];
  }

  /// Carico della vescica tra [a] e [b] (minuti equivalenti).
  double load(DateTime a, DateTime b, {OwnerSchedule? owner}) {
    var s = 0.0;
    for (var t = a; t.isBefore(b); t = t.add(Duration(minutes: p.step))) {
      final dt = math.min(p.step, b.difference(t).inMinutes).toDouble();
      final asleep = owner != null
          ? _asleep(owner, t)
          : PottyPredictor.inSleepWindow(dog, t);
      s += dt * (asleep ? p.sleepWeight : 1.0);
    }
    // Pasti abituali (o segnati) nell'intervallo, almeno 30 minuti prima di b.
    final d0 = DateTime(a.year, a.month, a.day);
    for (var d = 0; d <= b.difference(d0).inDays; d++) {
      for (final m in meals) {
        final t = d0.add(Duration(days: d, minutes: m));
        if (t.isAfter(a) &&
            t.isBefore(b.subtract(const Duration(minutes: 30)))) {
          s += p.mealLoad;
        }
      }
    }
    return s;
  }

  /// Minuti da sveglio tra [a] e [b].
  int awakeMinutes(DateTime a, DateTime b, OwnerSchedule? owner) {
    var s = 0;
    for (var t = a; t.isBefore(b); t = t.add(Duration(minutes: p.step))) {
      final asleep = owner != null
          ? _asleep(owner, t)
          : PottyPredictor.inSleepWindow(dog, t);
      if (!asleep) s += math.min(p.step, b.difference(t).inMinutes);
    }
    return s;
  }

  bool _asleep(OwnerSchedule o, DateTime t) {
    final day = DateTime(t.year, t.month, t.day);
    final m = t.hour * 60 + t.minute;
    final prev = day.subtract(const Duration(days: 1));
    if (m + 24 * 60 < o.bedOn(dog, prev)) return false;
    return m < o.wakeOn(dog, day) || m >= o.bedOn(dog, day);
  }

  /// Rischio di incidente in un intervallo di carico [l].
  double riskOfLoad(double l) =>
      l <= 0 ? 0 : _phi((math.log(l) - mu) / p.sigma);

  static HoldModel fit(
    Dog dog,
    List<LogEntry> logs,
    DateTime now, {
    PlanParams p = const PlanParams(),
    OwnerSchedule? owner,
  }) {
    final visible = [
      for (final l in logs)
        if (!l.time.isAfter(now)) l,
    ]..sort((a, b) => a.time.compareTo(b.time));
    final prior = BioParams.pee(dog, now);
    final bio = BioParams.modifier(Need.pipi, dog, const [], now);
    final f = bio.clinical < 1 ? bio.clinical : 1.0;
    final cap = math.max(120.0, prior.maxDay * f);
    final meals = _mealSlots(visible, now);
    final tmp = HoldModel._(dog, 0, p, meals, cap, 0);
    final pees = PottyPredictor.outings(visible, type: LogType.pipi);
    final from = now.subtract(Duration(days: p.historyDays));
    // (carico, è un incidente?, peso)
    final obs = <(double, bool, double)>[];
    for (var k = 1; k < pees.length; k++) {
      final a = pees[k - 1].time, b = pees[k].time;
      if (b.isBefore(from)) continue;
      if (b.difference(a).inHours > 20) continue; // pipì non registrate
      final l = tmp.load(a, b, owner: owner);
      final age = now.difference(b).inHours / 24;
      final w = math.pow(0.5, age / 7).toDouble(); // emivita 7 giorni
      obs.add((l, pees[k].indoor, w));
    }
    // Segnali: il cane chiede a circa metà della sua tenuta [IPOTESI].
    for (final s in visible.where(
      (l) => p.signalsInHold && l.type == LogType.segnale,
    )) {
      if (s.time.isBefore(from)) continue;
      DateTime? before;
      for (final q in pees) {
        if (q.time.isBefore(s.time)) before = q.time;
      }
      if (before == null) continue;
      final l = tmp.load(before, s.time, owner: owner) * p.signalFactor;
      final age = now.difference(s.time).inHours / 24;
      obs.add((l, true, 0.5 * math.pow(0.5, age / 7).toDouble()));
    }
    final mu0 = math.log(p.priorFactor * cap);
    double logPost(double mu) {
      var s = -0.5 * math.pow((mu - mu0) / p.priorSd, 2);
      for (final (l, ev, w) in obs) {
        final z = (math.log(math.max(1, l)) - mu) / p.sigma;
        if (ev) {
          s += w * (-0.5 * z * z);
        } else {
          s += w * math.log(math.max(1e-12, 1 - _phi(z)));
        }
      }
      return s;
    }

    var best = mu0, bestV = -double.infinity;
    for (var mu = mu0 - 1.5; mu <= mu0 + 1.0; mu += 0.025) {
      final v = logPost(mu);
      if (v > bestV) {
        bestV = v;
        best = mu;
      }
    }
    return HoldModel._(dog, best, p, meals, cap, obs.length);
  }
}

/// Piano con [n] uscite per il giorno di [now], a partire da [now].
/// [done] = uscite già fatte oggi; [lastPee] = ultima pipì (o uscita).
OutingPlan planDay(
  HoldModel hm,
  OwnerSchedule owner,
  DateTime now,
  int n, {
  required DateTime lastPee,
  int done = 0,
  DateTime? poopDue,
}) {
  final dog = hm.dog;
  final p = hm.p;
  final day = DateTime(now.year, now.month, now.day);
  final bed = day.add(Duration(minutes: owner.bedOn(dog, day)));
  final tomorrow = day.add(const Duration(days: 1));
  final nextFirst = tomorrow.add(
    Duration(minutes: owner.wakeOn(dog, tomorrow) + 10),
  );
  // Orari possibili: ogni 15 minuti, padrone a casa e sveglio.
  final slots = <DateTime>[];
  var t0 = now.add(const Duration(minutes: 5));
  t0 = t0.add(Duration(minutes: (p.step - t0.minute % p.step) % p.step));
  for (var t = t0; t.isBefore(bed); t = t.add(Duration(minutes: p.step))) {
    if (owner.available(dog, t)) slots.add(t);
  }
  final remaining = math.max(0, n - done);
  final k = math.min(remaining, slots.length);

  double costOf(double l, double awake) {
    var c = hm.riskOfLoad(l);
    // Tetto diurno per età e salute: solo per il tempo da sveglio.
    if (awake > hm.capMin) c += p.capPenalty * (awake / hm.capMin - 1);
    return c;
  }

  double gapCost(DateTime a, DateTime b) =>
      costOf(hm.load(a, b, owner: owner), hm.awakeMinutes(a, b, owner).toDouble());

  // Carico cumulato su una griglia di 15 minuti da t0 alla prima uscita di
  // domani: il costo di un intervallo tra due orari è una differenza.
  final grid = <DateTime>[];
  for (var t = t0; t.isBefore(nextFirst); t = t.add(Duration(minutes: p.step))) {
    grid.add(t);
  }
  grid.add(nextFirst);
  final cl = List<double>.filled(grid.length, 0);
  final ca = List<double>.filled(grid.length, 0);
  final mealAt = <int>{};
  for (var d = -1; d <= 1; d++) {
    for (final m in hm.meals) {
      final t = day.add(Duration(days: d, minutes: m + 30));
      if (t.isBefore(t0) || !t.isBefore(nextFirst)) continue;
      mealAt.add(t.difference(t0).inMinutes ~/ p.step + 1);
    }
  }
  for (var g = 1; g < grid.length; g++) {
    cl[g] = cl[g - 1] +
        hm.load(grid[g - 1], grid[g], owner: owner) +
        (mealAt.contains(g) ? p.mealLoad : 0);
    ca[g] = ca[g - 1] + hm.awakeMinutes(grid[g - 1], grid[g], owner);
  }
  final l0 = hm.load(lastPee, t0, owner: owner);
  final a0 = hm.awakeMinutes(lastPee, t0, owner).toDouble();
  int gi(DateTime t) => t.difference(t0).inMinutes ~/ p.step;
  final slotG = [for (final t in slots) gi(t)];
  final lastG = grid.length - 1;
  // Cacca attesa: un intervallo che copre tutta la sua finestra costa.
  final poopEnd = poopDue?.add(Duration(minutes: p.poopWait));
  double poopCost(DateTime a, DateTime b) =>
      poopDue != null && !a.isAfter(poopDue) && b.isAfter(poopEnd!)
      ? p.poopWeight
      : 0;
  double costIdx(int h, int i) =>
      (h < 0
          ? costOf(l0 + cl[i], a0 + ca[i])
          : costOf(cl[i] - cl[h], ca[i] - ca[h])) +
      poopCost(h < 0 ? lastPee : grid[h], grid[i]);

  if (k == 0) {
    final r = hm.riskOfLoad(hm.load(lastPee, nextFirst, owner: owner));
    return OutingPlan(
      n: n,
      times: const [],
      expectedAccidents: r,
      overCap: false,
      gapRisks: [r],
    );
  }
  // Programmazione dinamica: best[j][i] = costo minimo con j+1 uscite, la
  // j-esima all'orario slots[i].
  final m = slots.length;
  final inf = double.infinity;
  final best = List.generate(k, (_) => List.filled(m, inf));
  final from = List.generate(k, (_) => List.filled(m, -1));
  for (var i = 0; i < m; i++) {
    best[0][i] = costIdx(-1, slotG[i]);
  }
  for (var j = 1; j < k; j++) {
    for (var i = j; i < m; i++) {
      for (var h = j - 1; h < i; h++) {
        if (best[j - 1][h] == inf) continue;
        if (slots[i].difference(slots[h]).inMinutes < 60) continue;
        final v = best[j - 1][h] + costIdx(slotG[h], slotG[i]);
        if (v < best[j][i]) {
          best[j][i] = v;
          from[j][i] = h;
        }
      }
    }
  }
  var bi = -1;
  var bv = inf;
  for (var i = 0; i < m; i++) {
    if (best[k - 1][i] == inf) continue;
    final v = best[k - 1][i] + costIdx(slotG[i], lastG);
    if (v < bv) {
      bv = v;
      bi = i;
    }
  }
  if (bi < 0) {
    // Meno orari possibili del necessario (uscite a meno di un'ora).
    return planDay(hm, owner, now, n - 1,
        lastPee: lastPee, done: done, poopDue: poopDue);
  }
  final idx = <int>[];
  for (var j = k - 1, i = bi; j >= 0; j--) {
    idx.add(i);
    i = from[j][i];
  }
  final times = [for (final i in idx.reversed) slots[i]];
  final risks = <double>[];
  var over = false;
  var prev = lastPee;
  for (final t in [...times, nextFirst]) {
    final l = hm.load(prev, t, owner: owner);
    risks.add(hm.riskOfLoad(l));
    if (t != nextFirst && gapCost(prev, t) > hm.riskOfLoad(l) + 1e-9) {
      over = true;
    }
    prev = t;
  }
  return OutingPlan(
    n: n,
    times: times,
    expectedAccidents: risks.fold(0.0, (a, b) => a + b),
    overCap: over,
    gapRisks: risks,
  );
}

/// Le opzioni da mostrare (per esempio 3, 4 e 5 uscite), dallo stesso
/// istante.
List<OutingPlan> planOptions(
  Dog dog,
  List<LogEntry> logs,
  OwnerSchedule owner,
  DateTime now, {
  List<int> options = const [3, 4, 5],
  PlanParams p = const PlanParams(),
}) {
  final hm = HoldModel.fit(dog, logs, now, p: p, owner: owner);
  final pees = PottyPredictor.outings([
    for (final l in logs)
      if (!l.time.isAfter(now)) l,
  ], type: LogType.pipi);
  final day = DateTime(now.year, now.month, now.day);
  final wake = day.add(Duration(minutes: owner.wakeOn(dog, day)));
  final last = pees.isEmpty ? wake : pees.last.time;
  final done = pees.where((o) => !o.indoor && !o.time.isBefore(wake)).length;
  final due = poopCandidates(dog, [
    for (final l in logs)
      if (!l.time.isAfter(now)) l,
  ], now)?.at;
  return [
    for (final n in options)
      planDay(hm, owner, now, n, lastPee: last, done: done, poopDue: due),
  ];
}
