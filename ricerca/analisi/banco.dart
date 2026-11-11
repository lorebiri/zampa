// Banco di prova dell'accuratezza del modello di previsione (C1-5).
//
// Genera cani sintetici con un processo "vero" DIVERSO da quello del
// simulatore interno del modello (vescica che si riempie, ml/kg/h, e
// cacca guidata dagli inneschi e dall'opportunità di uscire, 05 §P2/P9),
// applica i disturbi realistici della registrazione e misura il modello
// in modo prequenziale: ogni previsione usa solo i dati registrati fino al
// momento della previsione.
//
// Solo analisi: non fa parte dell'app né della suite di test di CI.
// Uso: flutter test ricerca/analisi/<scenario>_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';
import 'package:zampa/logic/potty_predictor.dart';
import 'package:zampa/models.dart';

part 'banco2.dart';

// ---------------------------------------------------------------------------
// Scenari e cani.
// ---------------------------------------------------------------------------

class Scenario {
  const Scenario(
    this.name, {
    this.missing = false,
    this.jitter = false,
    this.sched = SchedMode.none,
    this.weekend = false,
    this.routineChange = false,
    this.polyuria = PuMode.none,
  });
  final String name;
  final bool missing;
  final bool jitter;
  final SchedMode sched;
  final bool weekend;
  final bool routineChange;
  final PuMode polyuria;
}

/// none: tutti i cani "chiedono" di uscire; all: tutti a orari decisi dal
/// padrone; mix: come da scheda del cane (circa metà e metà).
enum SchedMode { none, mix, all }

/// none: nessuna poliuria nuova; own: solo i cani della scheda; all: compare
/// in tutti i cani tra il giorno 12 e il 18.
enum PuMode { none, own, all }

const scenarios = {
  'pulito': Scenario('pulito'),
  'mancanti': Scenario('mancanti', missing: true),
  'jitter': Scenario('jitter', jitter: true),
  'orari_padrone': Scenario('orari_padrone', sched: SchedMode.all),
  'weekend': Scenario('weekend', weekend: true),
  'cambio_routine': Scenario('cambio_routine', routineChange: true),
  'poliuria': Scenario('poliuria', polyuria: PuMode.all),
  'realistico': Scenario(
    'realistico',
    missing: true,
    jitter: true,
    sched: SchedMode.mix,
    weekend: true,
    routineChange: true,
    polyuria: PuMode.own,
  ),
};

class DogSpec {
  DogSpec(
    this.id,
    this.group,
    this.ageMonths,
    this.weightKg,
    this.sex,
    this.scheduled,
    this.wakeH,
    this.bedH, {
    this.puOnset = false,
    this.chronic = false,
  });
  final String id;

  /// cucciolo, adulto, anziano, cronico (malattia dichiarata), poliuria
  /// (non dichiarata, compare durante il periodo).
  final String group;
  final double ageMonths;
  final double weightKg;
  final Sex sex;
  final bool scheduled;
  final double wakeH;
  final double bedH;
  final bool puOnset;
  final bool chronic;
}

/// 32 cani: 6 cuccioli, 14 adulti, 6 anziani, 3 con malattia cronica
/// dichiarata (diabete, poliuria stabile), 3 con poliuria che compare.
List<DogSpec> population() {
  final r = math.Random(2026);
  final specs = <DogSpec>[];
  var n = 0;
  double wake() => 6 + r.nextInt(5) * 0.5; // 6:00-8:00
  double bed(double w) => w + 15.5 + r.nextInt(3) * 0.5; // 21:30-23:30
  void add(
    String g,
    double age,
    double kg, {
    bool pu = false,
    bool chronic = false,
  }) {
    final w = wake();
    specs.add(
      DogSpec(
        'c${(n++).toString().padLeft(2, '0')}',
        g,
        age,
        kg,
        r.nextBool() ? Sex.maschio : Sex.femmina,
        n.isEven, // metà a orari decisi dal padrone
        w,
        bed(w),
        puOnset: pu,
        chronic: chronic,
      ),
    );
  }

  for (final (a, kg) in [
    (3.0, 6.0),
    (3.5, 12.0),
    (4.0, 25.0),
    (4.5, 4.0),
    (5.0, 18.0),
    (5.5, 30.0),
  ]) {
    add('cucciolo', a, kg);
  }
  for (final kg in [
    4.0,
    6.0,
    8.0,
    10.0,
    12.0,
    15.0,
    18.0,
    20.0,
    22.0,
    25.0,
    28.0,
    32.0,
    36.0,
    40.0,
  ]) {
    add('adulto', 18 + r.nextInt(72).toDouble(), kg);
  }
  for (final kg in [5.0, 9.0, 14.0, 22.0, 30.0, 38.0]) {
    add('anziano', seniorStartMonths(kg) + 6 + r.nextInt(30), kg);
  }
  for (final kg in [8.0, 20.0, 30.0]) {
    add('cronico', 60 + r.nextInt(60).toDouble(), kg, chronic: true);
  }
  for (final kg in [10.0, 24.0, 12.0]) {
    add('poliuria', 50 + r.nextInt(80).toDouble(), kg, pu: true);
  }
  return specs;
}

// ---------------------------------------------------------------------------
// Processo vero.
// ---------------------------------------------------------------------------

class Truth {
  Truth(this.spec, this.dog, this.logged, this.pees, this.poops, this.puFrom);
  final DogSpec spec;

  /// Profilo come lo compila il padrone all'inizio (non viene aggiornato).
  final Dog dog;

  /// Ciò che il padrone registra (con dati mancanti e orari approssimati).
  final List<LogEntry> logged;

  /// Eventi veri (orario esatto).
  final List<DateTime> pees;
  final List<DateTime> poops;
  final DateTime? puFrom;
}

final simStart = DateTime(2026, 9, 7); // lunedì
const simDays = 28;
const evalFromDay = 7;

double _g(math.Random r) =>
    r.nextDouble() + r.nextDouble() + r.nextDouble() - 1.5; // ≈ N(0, 0,5)

Truth simulateDog(DogSpec s, Scenario sc, int seed) {
  final r = math.Random(seed);
  final scheduled = switch (sc.sched) {
    SchedMode.none => false,
    SchedMode.all => true,
    SchedMode.mix => s.scheduled,
  };
  final puppy = s.ageMonths < 6;
  final senior =
      s.group == 'anziano' || s.ageMonths >= seniorStartMonths(s.weightKg);
  final kg = s.weightKg;
  final sizeScale = math.pow(kg / 15, -0.25).toDouble();
  // Volume a uno svuotamento normale (05 §P2), ml/kg.
  final vFun = puppy ? (s.ageMonths < 4 ? 3.5 : 4.5) : (senior ? 6.0 : 8.0);
  // Cacca: mediana dell'intervallo (05 §P7) e prontezza del colon.
  final poopMedian = puppy ? 300.0 : (senior ? 780.0 : 660.0);
  final puOnsetDay = switch (sc.polyuria) {
    PuMode.none => null,
    PuMode.own => s.puOnset ? 12 + r.nextInt(7) : null,
    PuMode.all => 12 + r.nextInt(7),
  };
  final puFrom = puOnsetDay == null
      ? null
      : simStart.add(Duration(days: puOnsetDay));
  final missRate = sc.missing ? 0.10 + r.nextDouble() * 0.30 : 0.0;

  final dog = Dog(
    id: s.id,
    name: s.id,
    birthDate: simStart.subtract(Duration(days: (s.ageMonths * 30.44).round())),
    sex: s.sex,
    neutered: r.nextBool(),
    weightKg: kg,
    wakeHour: s.wakeH.round(),
    sleepStartHour: s.bedH.round() % 24,
    conditions: s.chronic ? 'diabete' : '',
  );

  // Piano giornaliero: risveglio, letto, pasti, uscite programmate.
  final wakes = <DateTime>[], beds = <DateTime>[];
  final meals = <DateTime>[];
  final planned = <(DateTime, int)>[]; // (inizio, durata minuti)
  final drinks = <(DateTime, double)>[]; // (quando, ml/kg)
  DateTime at(DateTime day, double h) => DateTime(
    day.year,
    day.month,
    day.day,
  ).add(Duration(minutes: (h * 60).round()));
  for (var d = 0; d <= simDays; d++) {
    final day = simStart.add(Duration(days: d));
    final we = sc.weekend && day.weekday >= 6;
    final changed = sc.routineChange && d >= 14;
    final wake =
        s.wakeH + (we ? 1.5 : 0) + (changed && !we ? -1.0 : 0) + _g(r) * 0.4;
    final bed = s.bedH + (we ? 0.5 : 0) + _g(r) * 0.3;
    wakes.add(at(day, wake));
    beds.add(at(day, bed));
    final shift = changed ? 1.5 : 0.0;
    final dayMeals = <double>[
      wake + 0.75,
      if (puppy) 13.0 + (we ? 0.5 : 0) + shift,
      19.0 + (we ? 0.5 : 0) + shift * 0.7,
    ];
    for (final m in dayMeals) {
      meals.add(at(day, m + _g(r) * 0.4));
    }
    // Uscite decise dal padrone. Per i cani "a richiesta" restano solo la
    // passeggiata del mattino e quella della sera.
    final outs = <(double, int)>[
      (wake + 1 / 6, 15),
      if (scheduled && puppy) (10.0 + (we ? 1 : 0), 10),
      if (scheduled) (we ? 12.5 : 13.0 + shift, 15),
      if (scheduled && puppy) (16.0 + shift, 10),
      (we ? 17.5 : 18.5 + shift, we ? 60 : 30),
      if (scheduled) (bed - 0.5, 10),
    ];
    for (final (h, len) in outs) {
      planned.add((at(day, h + _g(r) * 0.5), len));
    }
    // Acqua: dopo i pasti, a caso durante il giorno.
    final waterScale = puppy ? 1.4 : 1.0;
    for (final m in meals.skip(meals.length - dayMeals.length)) {
      drinks.add((
        m.add(Duration(minutes: 5 + r.nextInt(11))),
        6.0 * waterScale,
      ));
    }
    for (var k = 0; k < 2; k++) {
      drinks.add((
        at(day, wake + 1 + r.nextDouble() * (bed - wake - 2)),
        4.0 * waterScale,
      ));
    }
  }
  planned.sort((a, b) => a.$1.compareTo(b.$1));
  meals.sort();

  bool asleepAt(DateTime t) {
    for (var d = 0; d < wakes.length; d++) {
      if (t.isBefore(wakes[d])) {
        return d == 0 || !t.isBefore(beds[d - 1]);
      }
      if (t.isBefore(beds[d])) return false;
    }
    return true;
  }

  // Simulazione al minuto.
  final pees = <DateTime>[], poops = <DateTime>[];
  final indoorPee = <DateTime>{}, indoorPoop = <DateTime>{};
  final walksDone = <DateTime>[];
  var v = 0.5 * vFun; // ml/kg in vescica
  var urge = vFun * (0.85 + r.nextDouble() * 0.4);
  var lastPoop = simStart.subtract(const Duration(hours: 10));
  var readyAt = lastPoop.add(
    Duration(minutes: (poopMedian * 0.55 * math.exp(_g(r) * 0.6)).round()),
  );
  DateTime? pendingOut; // uscita chiesta dal cane
  DateTime? outEnd; // fine dell'uscita in corso
  DateTime? outStart;
  var peedThisOut = false, poopedThisOut = false;
  var nextPlanned = 0;
  final pendingDrinks = [...drinks]..sort((a, b) => a.$1.compareTo(b.$1));
  var di = 0;
  // Acqua in transito verso la vescica: (quando bevuta, ml/kg).
  final bolus = <(DateTime, double)>[];
  final end = simStart.add(const Duration(days: simDays));
  final extraMarks = <DateTime>[];
  for (
    var t = simStart;
    t.isBefore(end);
    t = t.add(const Duration(minutes: 1))
  ) {
    final asleep = asleepAt(t);
    final pu = puFrom != null && !t.isBefore(puFrom) ? 2.2 : 1.0;
    final chronicPu = s.chronic ? 2.0 : 1.0;
    // Bevute.
    while (di < pendingDrinks.length && !pendingDrinks[di].$1.isAfter(t)) {
      bolus.add((pendingDrinks[di].$1, pendingDrinks[di].$2 * pu * chronicPu));
      di++;
    }
    // Produzione di urina: basale + 70% dell'acqua bevuta, con ritardo
    // (picco ~60 min, 05 §P2).
    var rate = (asleep ? 0.35 : 0.5) * sizeScale * pu * chronicPu / 60;
    for (final (drunkAt, ml) in bolus) {
      final dt = t.difference(drunkAt).inMinutes.toDouble();
      if (dt < 0 || dt > 240) continue;
      final k = math.exp(-0.5 * math.pow((dt - 65) / 35, 2)) / (35 * 2.5066);
      rate += 0.7 * ml * sizeScale * k;
    }
    bolus.removeWhere((b) => t.difference(b.$1).inMinutes > 240);
    v += rate;

    // Inizio di un'uscita programmata o chiesta.
    if (outEnd == null) {
      DateTime? startNow;
      var len = 10;
      if (nextPlanned < planned.length && !planned[nextPlanned].$1.isAfter(t)) {
        startNow = t;
        len = planned[nextPlanned].$2;
        nextPlanned++;
      } else if (pendingOut != null && !pendingOut.isAfter(t)) {
        startNow = t;
        len = 8;
      }
      if (startNow != null) {
        outStart = startNow;
        outEnd = startNow.add(Duration(minutes: len));
        pendingOut = null;
        peedThisOut = false;
        poopedThisOut = false;
        walksDone.add(startNow);
      }
    } else {
      // Salta le uscite programmate che cadono durante un'uscita in corso.
      while (nextPlanned < planned.length &&
          !planned[nextPlanned].$1.isAfter(t)) {
        nextPlanned++;
      }
    }

    final outside = outEnd != null && t.isBefore(outEnd);
    if (outside) {
      final into = t.difference(outStart!).inMinutes;
      if (!peedThisOut && into >= 1 + r.nextInt(3) && v >= 0.25 * vFun) {
        pees.add(t);
        v = 0.2;
        urge = vFun * (0.85 + r.nextDouble() * 0.4);
        peedThisOut = true;
        if (s.sex == Sex.maschio) {
          for (var k = 0; k < r.nextInt(3); k++) {
            extraMarks.add(t.add(Duration(minutes: 2 + r.nextInt(8))));
          }
        }
      }
      if (!poopedThisOut &&
          !t.isBefore(readyAt) &&
          into >= 3 &&
          r.nextDouble() < 0.12) {
        // Innesco della passeggiata: in media ~8 min dopo l'inizio.
        poops.add(t);
        poopedThisOut = true;
        lastPoop = t;
        readyAt = t.add(
          Duration(
            minutes: (poopMedian * 0.55 * math.exp(_g(r) * 0.6)).round(),
          ),
        );
      }
    } else if (outEnd != null) {
      outEnd = null;
    }

    if (!outside) {
      // Bisogno di pipì.
      final limit = asleep ? 2.2 * vFun : urge;
      if (v >= limit) {
        if (scheduled && v >= 2.5 * vFun) {
          // Incidente in casa.
          pees.add(t);
          indoorPee.add(t);
          v = 0.2;
          urge = vFun * (0.85 + r.nextDouble() * 0.4);
        } else if (!scheduled || (asleep && puppy)) {
          pendingOut ??= t.add(Duration(minutes: 2 + r.nextInt(18)));
        }
      }
      // Cacca: riflesso gastrocolico se il colon è pronto, oppure stimolo
      // forte 4 ore dopo che è pronto.
      if (!asleep && !t.isBefore(readyAt)) {
        final recentMeal = meals.any((m) {
          final dt = t.difference(m).inMinutes;
          return dt >= 25 && dt <= 60;
        });
        final strong = t.difference(readyAt).inMinutes > 240;
        if (!scheduled && (recentMeal && r.nextDouble() < 0.05 || strong)) {
          pendingOut ??= t.add(Duration(minutes: 2 + r.nextInt(12)));
        }
        if (scheduled && t.difference(readyAt).inMinutes > 840) {
          poops.add(t);
          indoorPoop.add(t);
          lastPoop = t;
          readyAt = t.add(
            Duration(
              minutes: (poopMedian * 0.55 * math.exp(_g(r) * 0.6)).round(),
            ),
          );
        }
      }
    }
  }

  // Registrazione da parte del padrone.
  final logged = <LogEntry>[];
  var id = 0;
  DateTime jit(DateTime t) =>
      sc.jitter ? t.add(Duration(minutes: r.nextInt(21) - 10)) : t;
  void log(LogType type, DateTime t, {bool indoor = false, double? ml}) =>
      logged.add(
        LogEntry(
          id: '${id++}',
          dogId: s.id,
          type: type,
          time: jit(t),
          indoor: indoor,
          amountMl: ml,
        ),
      );
  for (final p in pees) {
    final indoor = indoorPee.contains(p);
    if (r.nextDouble() >= (indoor ? 0.1 : missRate)) {
      log(LogType.pipi, p, indoor: indoor);
    }
  }
  for (final m in extraMarks) {
    if (r.nextDouble() < 0.3) log(LogType.pipi, m);
  }
  for (final p in poops) {
    final indoor = indoorPoop.contains(p);
    if (r.nextDouble() >= (indoor ? 0.1 : missRate * 0.6)) {
      log(LogType.cacca, p, indoor: indoor);
    }
  }
  for (final m in meals) {
    if (r.nextDouble() < (sc.missing ? 0.85 : 1.0)) log(LogType.pasto, m);
  }
  for (final (t, ml) in drinks) {
    if (r.nextDouble() < (sc.missing ? 0.25 : 1.0)) {
      log(LogType.acqua, t, ml: r.nextBool() || !sc.missing ? ml * kg : null);
    }
  }
  for (final w in wakes) {
    if (r.nextDouble() < (sc.missing ? 0.5 : 1.0)) log(LogType.risveglio, w);
  }
  for (final w in walksDone) {
    if (r.nextDouble() < (sc.missing ? 0.25 : 1.0)) {
      log(LogType.passeggiata, w);
    }
  }
  logged.sort((a, b) => a.time.compareTo(b.time));
  return Truth(s, dog, logged, pees, poops, puFrom);
}

// ---------------------------------------------------------------------------
// Valutazione prequenziale.
// ---------------------------------------------------------------------------

class EventRec {
  EventRec({
    required this.dog,
    required this.group,
    required this.scheduled,
    required this.weekend,
    required this.afterChange,
    required this.puActive,
    required this.overnight,
    required this.errModel,
    required this.errTimer,
    required this.errWeekday,
    required this.errHabit,
    required this.errModelTrue,
    required this.in50,
    required this.in50tol,
    required this.in80,
    required this.width50,
    required this.width80,
    required this.pit,
    required this.signedErr,
  });
  final String dog, group;
  final bool scheduled, weekend, afterChange, puActive, overnight;
  final double errModel, errTimer, errWeekday, errHabit, errModelTrue;
  final bool in50, in50tol, in80;
  final double width50, width80, pit, signedErr;

  Map<String, Object> toJson() => {
    'dog': dog,
    'group': group,
    'scheduled': scheduled,
    'weekend': weekend,
    'afterChange': afterChange,
    'puActive': puActive,
    'overnight': overnight,
    'errModel': errModel,
    'errTimer': errTimer,
    'errWeekday': errWeekday,
    'errHabit': errHabit,
    'errModelTrue': errModelTrue,
    'in50': in50,
    'in50tol': in50tol,
    'in80': in80,
    'width50': width50,
    'width80': width80,
    'pit': pit,
    'signedErr': signedErr,
  };
}

class GridRec {
  GridRec(this.dog, this.group, this.p, this.pClim, this.y, this.yTrue);
  final String dog, group;
  final double p, pClim;
  final int y, yTrue;
}

/// Quantile [q] della curva cumulata (interpolazione lineare); null se la
/// curva non lo raggiunge entro il suo orizzonte (12 ore).
DateTime? curveQuantile(
  List<(DateTime, double)> curve,
  DateTime now,
  double q,
) {
  var prevT = now, prevP = 0.0;
  for (final (t, p) in curve) {
    if (p >= q) {
      final f = p > prevP ? ((q - prevP) / (p - prevP)).clamp(0.0, 1.0) : 1.0;
      return prevT.add(
        Duration(seconds: (t.difference(prevT).inSeconds * f).round()),
      );
    }
    prevT = t;
    prevP = p;
  }
  return null;
}

double curveCdf(List<(DateTime, double)> curve, DateTime now, DateTime x) {
  var prevT = now, prevP = 0.0;
  if (!x.isAfter(now)) return 0;
  for (final (t, p) in curve) {
    if (!x.isAfter(t)) {
      final span = t.difference(prevT).inSeconds;
      final f = span == 0 ? 1.0 : x.difference(prevT).inSeconds / span;
      return prevP + (p - prevP) * f;
    }
    prevT = t;
    prevP = p;
  }
  return 1.0; // oltre l'orizzonte della curva
}

double _median(List<double> x) {
  if (x.isEmpty) return double.nan;
  final s = [...x]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// Prossimo evento dopo [from] in [outs] (ordinati).
DateTime? _nextAfter(List<DateTime> outs, DateTime from) {
  for (final o in outs) {
    if (o.isAfter(from)) return o;
  }
  return null;
}

/// Riferimento "stesso orario": per ciascuno dei giorni passati indicati,
/// quanto dopo lo stesso orario è arrivato il primo evento; previsione =
/// mediana degli scarti.
DateTime? _habitPrediction(
  List<DateTime> visibleOuts,
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
    final n = _nextAfter(
      visibleOuts,
      ref.add(Duration(minutes: math.max(cluster, minOffset).round())),
    );
    if (n == null || !n.isBefore(prev)) continue;
    final off = n.difference(ref).inMinutes.toDouble();
    if (off > 18 * 60) continue;
    offsets.add(off);
  }
  if (offsets.isEmpty) return null;
  return prev.add(Duration(minutes: _median(offsets).round()));
}

List<DateTime> _cluster(List<DateTime> ts, double minutes) {
  final s = [...ts]..sort();
  final out = <DateTime>[];
  for (final t in s) {
    if (out.isNotEmpty && t.difference(out.last).inMinutes < minutes) continue;
    out.add(t);
  }
  return out;
}

/// Valuta il bisogno [need] su un cane: una previsione subito dopo ogni
/// evento registrato (origine = evento precedente + 1 minuto).
/// Con [leakyOrigin] usa invece l'origine del test di validazione attuale
/// (ultimo evento registrato di QUALSIASI tipo prima dell'evento vero).
List<EventRec> evaluateEvents(
  Truth tr,
  Need need, {
  bool leakyOrigin = false,
  int every = 1,
  DateTime? from,
  bool skipModel = false,
}) {
  final cluster = need.clusterMinutes;
  final outs = PottyPredictor.outings(
    tr.logged,
    type: need.logType,
    clusterMinutes: cluster,
  ).map((o) => o.time).toList();
  final trueOuts = _cluster(need == Need.pipi ? tr.pees : tr.poops, cluster);
  final evalFrom = from ?? simStart.add(const Duration(days: evalFromDay));
  final changeAt = simStart.add(const Duration(days: 14));
  final engine = EliminationModel();
  final recs = <EventRec>[];
  var idx = 0;
  for (var i = 1; i < outs.length; i++) {
    final actual = outs[i];
    if (actual.isBefore(evalFrom)) continue;
    if (idx++ % every != 0) continue;
    final prev = outs[i - 1];
    DateTime origin;
    if (leakyOrigin) {
      final known = tr.logged
          .where((l) => l.time.isBefore(actual))
          .map((l) => l.time)
          .reduce((a, b) => a.isAfter(b) ? a : b);
      origin = known.add(const Duration(minutes: 1));
    } else {
      origin = prev.add(const Duration(minutes: 1));
    }
    final visible = tr.logged.where((l) => !l.time.isAfter(origin)).toList();
    final prior = BioParams.forNeed(need, tr.dog, origin);
    final f = skipModel
        ? null
        : engine
              .fit(tr.dog, need, visible, const [], origin)
              .forecast(origin, withAccuracy: false);
    final expectedAt = f?.expectedAt ?? origin;
    final err = actual.difference(expectedAt).inMinutes.toDouble();
    final q10 = f == null ? null : curveQuantile(f.curve, origin, 0.10);
    final q90 = f == null ? null : curveQuantile(f.curve, origin, 0.90);
    final in80 =
        q10 != null &&
        !actual.isBefore(q10) &&
        (q90 == null ? true : !actual.isAfter(q90));
    final wS = f?.windowStart ?? origin, wE = f?.windowEnd ?? origin;
    final in50 = !actual.isBefore(wS) && !actual.isAfter(wE);
    final in50tol =
        !actual.isBefore(wS.subtract(const Duration(minutes: 15))) &&
        !actual.isAfter(wE.add(const Duration(minutes: 15)));

    // Timer fisso sull'intervallo medio da svegli osservato finora.
    final past = outs.where((e) => !e.isAfter(origin)).toList();
    final gaps = <double>[];
    for (var k = 1; k < past.length; k++) {
      final g = past[k].difference(past[k - 1]).inMinutes.toDouble();
      if (g < 600 &&
          !PottyPredictor.inSleepWindow(tr.dog, past[k]) &&
          !PottyPredictor.inSleepWindow(tr.dog, past[k - 1])) {
        gaps.add(g);
      }
    }
    final mean = gaps.isEmpty
        ? prior.median
        : gaps.reduce((a, b) => a + b) / gaps.length;
    var timer = prev.add(Duration(minutes: mean.round()));
    if (PottyPredictor.inSleepWindow(tr.dog, timer)) {
      timer = PottyPredictor.nextWake(
        tr.dog,
        timer,
      ).add(const Duration(minutes: 15));
    }
    // "Orario abituale": il primo evento dei giorni passati che arriva
    // almeno 0,4 intervalli medi dopo lo stesso orario (evita di prendere
    // come "prossimo" il doppione di pochi minuti dopo).
    final minOff = 0.4 * mean;
    final first = simStart.isBefore(tr.logged.first.time)
        ? simStart
        : tr.logged.first.time;
    final weekday =
        _habitPrediction(
          past,
          prev,
          cluster,
          [7, 14, 21],
          first,
          minOffset: minOff,
        ) ??
        _habitPrediction(
          past,
          prev,
          cluster,
          [1, 2, 3, 4, 5, 6, 7],
          first,
          minOffset: minOff,
        ) ??
        timer;
    final habit =
        _habitPrediction(
          past,
          prev,
          cluster,
          [1, 2, 3, 4, 5, 6, 7],
          first,
          minOffset: minOff,
        ) ??
        timer;
    // Evento vero successivo: oltre il margine del jitter (±10 min).
    final trueNext =
        _nextAfter(trueOuts, origin.add(const Duration(minutes: 11))) ?? actual;
    recs.add(
      EventRec(
        dog: tr.spec.id,
        group: tr.spec.group,
        scheduled: _isScheduled(tr),
        weekend: actual.weekday >= 6,
        afterChange: !actual.isBefore(changeAt),
        puActive: tr.puFrom != null && !actual.isBefore(tr.puFrom!),
        overnight:
            actual.difference(prev).inHours >= 6 && actual.day != prev.day,
        errModel: err.abs(),
        errTimer: actual.difference(timer).inMinutes.abs().toDouble(),
        errWeekday: actual.difference(weekday).inMinutes.abs().toDouble(),
        errHabit: actual.difference(habit).inMinutes.abs().toDouble(),
        // Senza modello: scarto con segno tra evento vero e registrato.
        errModelTrue: skipModel
            ? trueNext.difference(actual).inMinutes.toDouble()
            : trueNext.difference(expectedAt).inMinutes.abs().toDouble(),
        in50: in50,
        in50tol: in50tol,
        in80: in80,
        width50: wE.difference(wS).inMinutes.toDouble(),
        width80: (q10 == null || q90 == null)
            ? 720
            : q90.difference(q10).inMinutes.toDouble(),
        pit: f == null ? double.nan : curveCdf(f.curve, origin, actual),
        signedErr: err,
      ),
    );
  }
  return recs;
}

final Map<String, bool> _schedFlag = {};
bool _isScheduled(Truth tr) => _schedFlag[tr.spec.id] ?? false;

/// Probabilità nella prossima ora a orari fissi (ogni [stepH] ore, da
/// sveglio): per il Brier score e la calibrazione.
List<GridRec> evaluateGrid(Truth tr, Need need, {int stepH = 2}) {
  final cluster = need.clusterMinutes;
  final outs = PottyPredictor.outings(
    tr.logged,
    type: need.logType,
    clusterMinutes: cluster,
  ).map((o) => o.time).toList();
  final trueOuts = _cluster(need == Need.pipi ? tr.pees : tr.poops, cluster);
  final engine = EliminationModel();
  final recs = <GridRec>[];
  for (var d = evalFromDay; d < simDays; d++) {
    final day = simStart.add(Duration(days: d));
    for (var h = tr.dog.wakeHour + 2; h <= 21; h += stepH) {
      final origin = DateTime(day.year, day.month, day.day, h, 0);
      final visible = tr.logged.where((l) => !l.time.isAfter(origin)).toList();
      final f = engine
          .fit(tr.dog, need, visible, const [], origin)
          .forecast(origin, withAccuracy: false);
      final until = origin.add(const Duration(minutes: 60));
      final y = outs.any((o) => o.isAfter(origin) && !o.isAfter(until)) ? 1 : 0;
      final yt = trueOuts.any((o) => o.isAfter(origin) && !o.isAfter(until))
          ? 1
          : 0;
      // Climatologia del cane: quota dei 14 giorni precedenti con un evento
      // registrato nella stessa ora.
      var hit = 0, n = 0;
      for (var k = 1; k <= 14; k++) {
        final o2 = origin.subtract(Duration(days: k));
        if (o2.isBefore(simStart)) continue;
        n++;
        final u2 = o2.add(const Duration(minutes: 60));
        if (outs.any((o) => o.isAfter(o2) && !o.isAfter(u2))) hit++;
      }
      final pClim = (hit + 0.5) / (n + 1);
      recs.add(
        GridRec(tr.spec.id, tr.spec.group, f.probNextHour, pClim, y, yt),
      );
    }
  }
  return recs;
}

// ---------------------------------------------------------------------------
// Statistiche con bootstrap per cane (cluster bootstrap).
// ---------------------------------------------------------------------------

typedef Stat = double Function(List<EventRec>);

({double est, double lo, double hi}) bootstrap(
  List<EventRec> recs,
  Stat stat, {
  int reps = 2000,
  int seed = 7,
}) {
  final byDog = <String, List<EventRec>>{};
  for (final e in recs) {
    byDog.putIfAbsent(e.dog, () => []).add(e);
  }
  final dogs = byDog.keys.toList();
  final r = math.Random(seed);
  final vals = <double>[];
  for (var b = 0; b < reps; b++) {
    final sample = <EventRec>[];
    for (var k = 0; k < dogs.length; k++) {
      sample.addAll(byDog[dogs[r.nextInt(dogs.length)]]!);
    }
    final v = stat(sample);
    if (v.isFinite) vals.add(v);
  }
  vals.sort();
  return (
    est: stat(recs),
    lo: vals[(vals.length * 0.025).floor()],
    hi: vals[(vals.length * 0.975).floor().clamp(0, vals.length - 1)],
  );
}

({double est, double lo, double hi}) bootstrapGrid(
  List<GridRec> recs,
  double Function(List<GridRec>) stat, {
  int reps = 2000,
  int seed = 11,
}) {
  final byDog = <String, List<GridRec>>{};
  for (final e in recs) {
    byDog.putIfAbsent(e.dog, () => []).add(e);
  }
  final dogs = byDog.keys.toList();
  final r = math.Random(seed);
  final vals = <double>[];
  for (var b = 0; b < reps; b++) {
    final sample = <GridRec>[];
    for (var k = 0; k < dogs.length; k++) {
      sample.addAll(byDog[dogs[r.nextInt(dogs.length)]]!);
    }
    vals.add(stat(sample));
  }
  vals.sort();
  return (
    est: stat(recs),
    lo: vals[(vals.length * 0.025).floor()],
    hi: vals[(vals.length * 0.975).floor()],
  );
}

double medOf(List<EventRec> r, double Function(EventRec) f) =>
    _median(r.map(f).toList());
double rateOf(List<EventRec> r, bool Function(EventRec) f) =>
    r.isEmpty ? double.nan : r.where(f).length / r.length;

/// Statistica primaria L2: rapporto tra la media sui cani dell'errore
/// mediano del modello e quella del timer (ogni cane pesa uguale).
double perDogRatio(List<EventRec> r, double Function(EventRec) base) {
  final byDog = <String, List<EventRec>>{};
  for (final e in r) {
    byDog.putIfAbsent(e.dog, () => []).add(e);
  }
  var m = 0.0, t = 0.0;
  for (final l in byDog.values) {
    m += medOf(l, (e) => e.errModel);
    t += medOf(l, base);
  }
  return m / t;
}

double fracDogsBetter(List<EventRec> r, double Function(EventRec) base) {
  final byDog = <String, List<EventRec>>{};
  for (final e in r) {
    byDog.putIfAbsent(e.dog, () => []).add(e);
  }
  var w = 0;
  for (final l in byDog.values) {
    if (medOf(l, (e) => e.errModel) < medOf(l, base)) w++;
  }
  return w / byDog.length;
}

String fmt(
  ({double est, double lo, double hi}) x, {
  int dp = 0,
  bool pct = false,
}) {
  String f(double v) =>
      pct ? '${(v * 100).toStringAsFixed(dp)}%' : v.toStringAsFixed(dp);
  return '${f(x.est)} [${f(x.lo)}–${f(x.hi)}]';
}

/// Riepilogo standard degli eventi.
Map<String, String> summarize(List<EventRec> r) {
  if (r.isEmpty) return {'n': '0'};
  final dogs = r.map((e) => e.dog).toSet().length;
  return {
    'n eventi / cani': '${r.length} / $dogs',
    'errore mediano modello (min)': fmt(
      bootstrap(r, (s) => medOf(s, (e) => e.errModel)),
    ),
    'errore mediano timer (min)': fmt(
      bootstrap(r, (s) => medOf(s, (e) => e.errTimer)),
    ),
    'errore mediano stesso giorno sett. (min)': fmt(
      bootstrap(r, (s) => medOf(s, (e) => e.errWeekday)),
    ),
    'errore mediano stesso orario 7 gg (min)': fmt(
      bootstrap(r, (s) => medOf(s, (e) => e.errHabit)),
    ),
    'rapporto modello/timer (per cane)': fmt(
      bootstrap(r, (s) => perDogRatio(s, (e) => e.errTimer)),
      dp: 2,
    ),
    'rapporto modello/stesso giorno sett.': fmt(
      bootstrap(r, (s) => perDogRatio(s, (e) => e.errWeekday)),
      dp: 2,
    ),
    'rapporto modello/stesso orario 7 gg': fmt(
      bootstrap(r, (s) => perDogRatio(s, (e) => e.errHabit)),
      dp: 2,
    ),
    'cani in cui il modello batte il timer': fmt(
      bootstrap(r, (s) => fracDogsBetter(s, (e) => e.errTimer)),
      pct: true,
    ),
    'cani in cui batte stesso orario 7 gg': fmt(
      bootstrap(r, (s) => fracDogsBetter(s, (e) => e.errHabit)),
      pct: true,
    ),
    'errore mediano vs evento VERO (min)': fmt(
      bootstrap(r, (s) => medOf(s, (e) => e.errModelTrue)),
    ),
    'copertura finestra 25-75% (nominale 50%)': fmt(
      bootstrap(r, (s) => rateOf(s, (e) => e.in50)),
      pct: true,
    ),
    'copertura 25-75% ±15 min (come in app)': fmt(
      bootstrap(r, (s) => rateOf(s, (e) => e.in50tol)),
      pct: true,
    ),
    'copertura intervallo 10-90% (nominale 80%)': fmt(
      bootstrap(r, (s) => rateOf(s, (e) => e.in80)),
      pct: true,
    ),
    'ampiezza mediana 25-75% (min)': medOf(
      r,
      (e) => e.width50,
    ).toStringAsFixed(0),
    'ampiezza mediana 10-90% (min)': medOf(
      r,
      (e) => e.width80,
    ).toStringAsFixed(0),
    'errore con segno mediano (+ = in ritardo sul modello)': medOf(
      r,
      (e) => e.signedErr,
    ).toStringAsFixed(0),
    'PIT: quota < 0,1 / > 0,9 (attese 10%/10%)':
        '${(rateOf(r, (e) => e.pit < 0.1) * 100).toStringAsFixed(0)}% / '
        '${(rateOf(r, (e) => e.pit > 0.9) * 100).toStringAsFixed(0)}%',
  };
}

double brier(List<GridRec> g, {bool clim = false, bool truth = false}) {
  var s = 0.0;
  for (final x in g) {
    final p = clim ? x.pClim : x.p;
    final y = truth ? x.yTrue : x.y;
    s += (p - y) * (p - y);
  }
  return s / g.length;
}

Map<String, String> summarizeGrid(List<GridRec> g) {
  final out = <String, String>{
    'n previsioni / cani':
        '${g.length} / ${g.map((e) => e.dog).toSet().length}',
    'frequenza osservata': (g.where((e) => e.y == 1).length / g.length)
        .toStringAsFixed(3),
    'Brier modello': fmt(bootstrapGrid(g, brier), dp: 3),
    'Brier climatologia del cane (stessa ora, 14 gg)': fmt(
      bootstrapGrid(g, (s) => brier(s, clim: true)),
      dp: 3,
    ),
    'Brier skill score vs climatologia': fmt(
      bootstrapGrid(g, (s) => 1 - brier(s) / brier(s, clim: true)),
      dp: 2,
    ),
    'Brier modello vs eventi VERI': brier(g, truth: true).toStringAsFixed(3),
  };
  // Calibrazione per fasce.
  final bins = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.8, 1.0001];
  var ece = 0.0;
  for (var b = 0; b + 1 < bins.length; b++) {
    final s = g.where((e) => e.p >= bins[b] && e.p < bins[b + 1]).toList();
    if (s.isEmpty) continue;
    final mp = s.map((e) => e.p).reduce((a, c) => a + c) / s.length;
    final mo = s.where((e) => e.y == 1).length / s.length;
    ece += s.length / g.length * (mp - mo).abs();
    final ci = bootstrapGrid(
      s,
      (x) => x.where((e) => e.y == 1).length / x.length,
      reps: 1000,
    );
    out['fascia ${bins[b].toStringAsFixed(1)}-${math.min(1, bins[b + 1]).toStringAsFixed(1)}'] =
        'n=${s.length} dichiarata ${(mp * 100).toStringAsFixed(0)}% '
        'osservata ${(mo * 100).toStringAsFixed(0)}% '
        '[${(ci.lo * 100).toStringAsFixed(0)}–${(ci.hi * 100).toStringAsFixed(0)}%] '
        'scarto ${((mo - mp) * 100).toStringAsFixed(0)} punti';
  }
  out['ECE (errore medio di calibrazione)'] =
      '${(ece * 100).toStringAsFixed(1)} punti';
  return out;
}

// ---------------------------------------------------------------------------
// Esecuzione e salvataggio.
// ---------------------------------------------------------------------------

List<Truth> buildBench(Scenario sc) {
  final specs = population();
  final out = <Truth>[];
  for (var i = 0; i < specs.length; i++) {
    final s = specs[i];
    _schedFlag[s.id] = switch (sc.sched) {
      SchedMode.none => false,
      SchedMode.all => true,
      SchedMode.mix => s.scheduled,
    };
    out.add(simulateDog(s, sc, 1000 + i));
  }
  return out;
}

String outDir() {
  final d = Directory('ricerca/analisi/risultati');
  if (!d.existsSync()) d.createSync(recursive: true);
  return d.path;
}

void saveEvents(String name, List<EventRec> r) {
  File('${outDir()}/$name.json').writeAsStringSync(
    const JsonEncoder.withIndent(' ')
        .convert(r.map((e) => e.toJson()).toList()),
  );
}

void saveText(String name, String text) {
  File('${outDir()}/$name.txt').writeAsStringSync(text);
}

String render(String title, Map<String, String> m) {
  final b = StringBuffer('## $title\n');
  m.forEach((k, v) => b.writeln('- $k: $v'));
  return b.toString();
}

/// Statistiche descrittive del banco (per verificare il realismo).
String describeBench(List<Truth> bench) {
  final b = StringBuffer('## Descrizione del banco\n');
  for (final t in bench) {
    final days = simDays.toDouble();
    final pees = _cluster(t.pees, 15).length / days;
    final poops = t.poops.length / days;
    final logged = t.logged.where((l) => l.type == LogType.pipi).length / days;
    b.writeln(
      '- ${t.spec.id} ${t.spec.group} ${t.spec.ageMonths.toStringAsFixed(0)} '
      'mesi ${t.spec.weightKg} kg ${t.spec.sex.name} '
      '${_isScheduled(t) ? "orari-padrone" : "a-richiesta"}: '
      'pipì vere/die ${pees.toStringAsFixed(1)}, registrate/die '
      '${logged.toStringAsFixed(1)}, cacca/die ${poops.toStringAsFixed(1)}'
      '${t.puFrom != null ? ", poliuria dal ${t.puFrom!.day}/${t.puFrom!.month}" : ""}',
    );
  }
  return b.toString();
}

/// Esegue uno scenario e salva il riepilogo.
void runScenario(
  String name, {
  Need need = Need.pipi,
  bool grid = false,
  bool leaky = false,
  int every = 1,
  String? tag,
}) {
  final sc = scenarios[name]!;
  final bench = buildBench(sc);
  final label = tag ?? '${name}_${need.name}${grid ? "_griglia" : ""}';
  final b = StringBuffer();
  if (need == Need.pipi && !grid && !leaky) b.writeln(describeBench(bench));
  if (grid) {
    final g = <GridRec>[];
    for (final t in bench) {
      g.addAll(evaluateGrid(t, need, stepH: need == Need.pipi ? 4 : 6));
      // ignore: avoid_print
      print('$label ${t.spec.id}');
    }
    b.writeln(render('$label (tutti)', summarizeGrid(g)));
    for (final grp in [
      'cucciolo',
      'adulto',
      'anziano',
      'cronico',
      'poliuria',
    ]) {
      final s = g.where((e) => e.group == grp).toList();
      if (s.isEmpty) continue;
      b.writeln(
        '- $grp: Brier ${brier(s).toStringAsFixed(3)} vs clim '
        '${brier(s, clim: true).toStringAsFixed(3)} (n=${s.length})',
      );
    }
  } else {
    final r = <EventRec>[];
    for (final t in bench) {
      r.addAll(evaluateEvents(t, need, leakyOrigin: leaky, every: every));
      // ignore: avoid_print
      print('$label ${t.spec.id}');
    }
    saveEvents(label, r);
    b.writeln(render('$label (tutti)', summarize(r)));
    void sub(String title, bool Function(EventRec) f) {
      final s = r.where(f).toList();
      if (s.length < 20) return;
      b.writeln(render('$label — $title', summarize(s)));
    }

    for (final grp in [
      'cucciolo',
      'adulto',
      'anziano',
      'cronico',
      'poliuria',
    ]) {
      sub('gruppo $grp', (e) => e.group == grp);
    }
    sub('orari decisi dal padrone', (e) => e.scheduled);
    sub('a richiesta', (e) => !e.scheduled);
    sub('fine settimana', (e) => e.weekend);
    sub('giorni feriali', (e) => !e.weekend);
    sub('dopo il cambio di routine (g. 15-28)', (e) => e.afterChange);
    sub('prima del cambio (g. 8-14)', (e) => !e.afterChange);
    sub('poliuria in corso', (e) => e.puActive);
    sub('solo di giorno (no notte)', (e) => !e.overnight);
    sub('prima pipì del mattino (dopo la notte)', (e) => e.overnight);
  }
  saveText(label, b.toString());
  // ignore: avoid_print
  print(b);
}

EventRec eventFromJson(Map<String, dynamic> j) => EventRec(
  dog: j['dog'] as String,
  group: j['group'] as String,
  scheduled: j['scheduled'] as bool,
  weekend: j['weekend'] as bool,
  afterChange: j['afterChange'] as bool,
  puActive: j['puActive'] as bool,
  overnight: j['overnight'] as bool,
  errModel: (j['errModel'] as num).toDouble(),
  errTimer: (j['errTimer'] as num).toDouble(),
  errWeekday: (j['errWeekday'] as num).toDouble(),
  errHabit: (j['errHabit'] as num).toDouble(),
  errModelTrue: (j['errModelTrue'] as num).toDouble(),
  in50: j['in50'] as bool,
  in50tol: j['in50tol'] as bool,
  in80: j['in80'] as bool,
  width50: (j['width50'] as num).toDouble(),
  width80: (j['width80'] as num).toDouble(),
  pit: (j['pit'] as num).toDouble(),
  signedErr: (j['signedErr'] as num).toDouble(),
);

/// Riepilogo completo con i sottogruppi.
String reportEvents(String label, List<EventRec> r) {
  final b = StringBuffer(render('$label (tutti)', summarize(r)));
  void sub(String title, bool Function(EventRec) f) {
    final s = r.where(f).toList();
    if (s.length < 20) return;
    b.writeln(render('$label — $title', summarize(s)));
  }

  for (final grp in ['cucciolo', 'adulto', 'anziano', 'cronico', 'poliuria']) {
    sub('gruppo $grp', (e) => e.group == grp);
  }
  sub('orari decisi dal padrone', (e) => e.scheduled);
  sub('a richiesta', (e) => !e.scheduled);
  sub('fine settimana', (e) => e.weekend);
  sub('giorni feriali', (e) => !e.weekend);
  sub('dopo il cambio di routine (g. 15-28)', (e) => e.afterChange);
  sub('prima del cambio (g. 8-14)', (e) => !e.afterChange);
  sub('poliuria in corso', (e) => e.puActive);
  sub('solo di giorno (no notte)', (e) => !e.overnight);
  sub('prima pipì del mattino (dopo la notte)', (e) => e.overnight);
  return b.toString();
}

/// Ricalcola i riferimenti (senza il modello) e li unisce agli errori del
/// modello già salvati in risultati/<label>.json.
String mergeBaselines(
  String label,
  String scenario,
  Need need, {
  bool leaky = false,
  int every = 1,
}) {
  final f = File('${outDir()}/$label.json');
  if (!f.existsSync()) return '';
  final saved = (jsonDecode(f.readAsStringSync()) as List)
      .cast<Map<String, dynamic>>()
      .map(eventFromJson)
      .toList();
  final bench = buildBench(scenarios[scenario]!);
  final base = <EventRec>[];
  for (final t in bench) {
    base.addAll(
      evaluateEvents(
        t,
        need,
        leakyOrigin: leaky,
        every: every,
        skipModel: true,
      ),
    );
  }
  if (base.length != saved.length) {
    return '## $label: lunghezze diverse (${base.length} vs ${saved.length})\n';
  }
  final merged = [
    for (var i = 0; i < saved.length; i++)
      EventRec(
        dog: saved[i].dog,
        group: saved[i].group,
        scheduled: saved[i].scheduled,
        weekend: saved[i].weekend,
        afterChange: saved[i].afterChange,
        puActive: saved[i].puActive,
        overnight: saved[i].overnight,
        errModel: saved[i].errModel,
        errTimer: base[i].errTimer,
        errWeekday: base[i].errWeekday,
        errHabit: base[i].errHabit,
        errModelTrue: (base[i].errModelTrue + saved[i].signedErr).abs(),
        in50: saved[i].in50,
        in50tol: saved[i].in50tol,
        in80: saved[i].in80,
        width50: saved[i].width50,
        width80: saved[i].width80,
        pit: saved[i].pit,
        signedErr: saved[i].signedErr,
      ),
  ];
  saveEvents('${label}_finale', merged);
  final txt = reportEvents('${label}_finale', merged);
  saveText('${label}_finale', txt);
  return txt;
}
