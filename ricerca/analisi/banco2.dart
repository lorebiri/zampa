// Ciclo 2 (ricerca/23): banco della previsione di base e del modello in
// ombra. Parte di banco.dart (condivide generatore e riferimenti).
part of 'banco.dart';

/// Record di un evento valutato con un motore (base oppure ombra).
class Rec2 {
  Rec2(this.m);
  final Map<String, Object> m;
  String get dog => m['dog']! as String;
  String get group => m['group']! as String;
  bool b(String k) => m[k]! as bool;
  double d(String k) => (m[k]! as num).toDouble();
}

/// Valuta un cane con origine onesta, una sola volta per evento:
/// - `base`: la previsione mostrata (expectedAt; finestra windowStart-End);
/// - `ombra`: il modello in ombra (mediana; intervalli 10-90 e 25-75; PIT).
/// Con [shadow] falso il modello non viene addestrato (veloce).
({
  List<Rec2> base,
  List<Rec2> ombra,
  List<GridRec> grid,
  List<ShadowRecord> history,
})
evaluatePair(
  Truth tr,
  Need need, {
  int every = 1,
  bool shadow = true,
  int gridStepH = 0,
}) {
  final cluster = need.clusterMinutes;
  final outs = PottyPredictor.outings(
    tr.logged,
    type: need.logType,
    clusterMinutes: cluster,
  ).map((o) => o.time).toList();
  final trueOuts = _cluster(need == Need.pipi ? tr.pees : tr.poops, cluster);
  final evalFrom = simStart.add(const Duration(days: evalFromDay));
  final changeAt = simStart.add(const Duration(days: 14));
  final engine = EliminationModel();
  final base = <Rec2>[], ombra = <Rec2>[];
  final grid = <GridRec>[];
  // R6: previsioni in ombra registrate, ripassate al modello (R4, R5).
  final history = <ShadowRecord>[];
  // Origini: dopo ogni evento valutato (indice i) e, con [gridStepH], a
  // orari fissi (indice -1), in ordine di tempo.
  final origins = <(DateTime, int)>[];
  var idx = 0;
  for (var i = 1; i < outs.length; i++) {
    if (outs[i].isBefore(evalFrom)) continue;
    if (idx++ % every != 0) continue;
    origins.add((outs[i - 1].add(const Duration(minutes: 1)), i));
  }
  if (gridStepH > 0) {
    for (var d = evalFromDay; d < simDays; d++) {
      final day = simStart.add(Duration(days: d));
      for (var h = tr.dog.wakeHour + 2; h <= 21; h += gridStepH) {
        origins.add((DateTime(day.year, day.month, day.day, h), -1));
      }
    }
  }
  origins.sort((a, b) => a.$1.compareTo(b.$1));
  for (final (origin, i) in origins) {
    if (i < 0) {
      final visible = tr.logged.where((l) => !l.time.isAfter(origin)).toList();
      final f = engine
          .fit(tr.dog, need, visible, const [], origin)
          .forecast(origin, withAccuracy: false, history: history);
      final until = origin.add(const Duration(minutes: 60));
      final y = outs.any((o) => o.isAfter(origin) && !o.isAfter(until)) ? 1 : 0;
      final yt = trueOuts.any((o) => o.isAfter(origin) && !o.isAfter(until))
          ? 1
          : 0;
      var hit = 0, n = 0;
      for (var k = 1; k <= 14; k++) {
        final o2 = origin.subtract(Duration(days: k));
        if (o2.isBefore(simStart)) continue;
        n++;
        final u2 = o2.add(const Duration(minutes: 60));
        if (outs.any((o) => o.isAfter(o2) && !o.isAfter(u2))) hit++;
      }
      grid.add(
        GridRec(
          tr.spec.id,
          tr.spec.group,
          f.shadow?.probNextHour ?? f.probNextHour,
          (hit + 0.5) / (n + 1),
          y,
          yt,
        ),
      );
      continue;
    }
    final actual = outs[i];
    final prev = outs[i - 1];
    final visible = tr.logged.where((l) => !l.time.isAfter(origin)).toList();
    // T1: nessun log futuro nella previsione.
    if (visible.any((l) => l.time.isAfter(origin))) {
      throw StateError('T1: log futuro visibile');
    }
    final prior = BioParams.forNeed(need, tr.dog, origin);
    final f = engine
        .fit(tr.dog, need, visible, const [], origin, shadow: shadow)
        .forecast(origin, withAccuracy: false, history: history);
    if (f.shadow != null) history.add(f.shadow!.record);

    // Riferimenti (come in evaluateEvents).
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
    final minOff = 0.4 * mean;
    final first = simStart.isBefore(tr.logged.first.time)
        ? simStart
        : tr.logged.first.time;
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
    final weekday =
        _habitPrediction(
          past,
          prev,
          cluster,
          [7, 14, 21],
          first,
          minOffset: minOff,
        ) ??
        habit;
    final trueNext =
        _nextAfter(trueOuts, origin.add(const Duration(minutes: 11))) ?? actual;
    double ae(DateTime x) => actual.difference(x).inMinutes.abs().toDouble();
    bool inside(DateTime a, DateTime b) =>
        !actual.isBefore(a) && !actual.isAfter(b);
    final common = <String, Object>{
      'dog': tr.spec.id,
      'group': tr.spec.group,
      'scheduled': _isScheduled(tr),
      'weekend': actual.weekday >= 6,
      'afterChange': !actual.isBefore(changeAt),
      'puActive': tr.puFrom != null && !actual.isBefore(tr.puFrom!),
      'puDays': tr.puFrom == null
          ? -1.0
          : actual.difference(tr.puFrom!).inMinutes / 1440,
      'overnight':
          actual.difference(prev).inHours >= 6 && actual.day != prev.day,
      'errTimer': ae(timer),
      'errHabit': ae(habit),
      'errWeekday': ae(weekday),
      // T15: tetto di sicurezza da sveglio. Se il tetto cade di notte vale
      // la logica della notte (uscita prima di dormire o al risveglio).
      'capOk': _capOk(tr.dog, f, prior.maxDay, origin),
    };
    final e = f.expectedAt;
    base.add(
      Rec2({
        ...common,
        'errModel': ae(e),
        'signedErr': actual.difference(e).inMinutes.toDouble(),
        'errModelTrue': trueNext.difference(e).inMinutes.abs().toDouble(),
        'inWin': inside(f.windowStart, f.windowEnd),
        'widthWin': f.windowEnd.difference(f.windowStart).inMinutes.toDouble(),
      }),
    );
    final s = f.shadow;
    if (s != null) {
      ombra.add(
        Rec2({
          ...common,
          'errModel': ae(s.expectedAt),
          'signedErr': actual.difference(s.expectedAt).inMinutes.toDouble(),
          'errModelTrue': trueNext
              .difference(s.expectedAt)
              .inMinutes
              .abs()
              .toDouble(),
          'inWin': inside(s.q10, s.q90),
          'widthWin': s.q90.difference(s.q10).inMinutes.toDouble(),
          'in50': inside(s.q25, s.q75),
          'pit': _pitOf(s, actual),
        }),
      );
    }
  }
  return (base: base, ombra: ombra, grid: grid, history: history);
}

bool _capOk(Dog dog, Forecast f, double maxDay, DateTime origin) {
  if (f.last == null) return true;
  final cap = f.last!.add(Duration(minutes: maxDay.round() + 1));
  // Se tra l'ultima pipì e il tetto c'è la notte vale la logica della notte
  // (tetto notturno, uscita prima di dormire o al risveglio).
  for (
    var t = f.last!;
    !t.isAfter(cap);
    t = t.add(const Duration(minutes: 15))
  ) {
    if (PottyPredictor.inSleepWindow(dog, t)) return true;
  }
  if (PottyPredictor.inSleepWindow(dog, cap)) return true;
  final limit = cap.isAfter(origin) ? cap : origin;
  return !f.recommendedAt.isAfter(limit);
}

/// PIT approssimato per interpolazione lineare tra i quantili previsti.
double _pitOf(ShadowForecast s, DateTime x) {
  final qs = [
    (s.q10, 0.1),
    (s.q25, 0.25),
    (s.median, 0.5),
    (s.q75, 0.75),
    (s.q90, 0.9),
  ];
  if (x.isBefore(qs.first.$1)) return 0.05;
  if (x.isAfter(qs.last.$1)) return 0.95;
  for (var k = 1; k < qs.length; k++) {
    final (a, pa) = qs[k - 1];
    final (b, pb) = qs[k];
    if (!x.isAfter(b)) {
      final span = b.difference(a).inSeconds;
      final f = span == 0 ? 1.0 : x.difference(a).inSeconds / span;
      return pa + (pb - pa) * f;
    }
  }
  return 0.95;
}

GridRec gridFromJson(Map<String, dynamic> j) => GridRec(
  j['dog'] as String,
  j['group'] as String,
  (j['p'] as num).toDouble(),
  (j['pClim'] as num).toDouble(),
  j['y'] as int,
  j['yTrue'] as int,
);

Map<String, Object> gridToJson(GridRec g) => {
  'dog': g.dog,
  'group': g.group,
  'p': g.p,
  'pClim': g.pClim,
  'y': g.y,
  'yTrue': g.yTrue,
};

double _med2(List<Rec2> r, String k) => _median(r.map((e) => e.d(k)).toList());
double _rate2(List<Rec2> r, String k) =>
    r.isEmpty ? double.nan : r.where((e) => e.b(k)).length / r.length;

Map<String, List<Rec2>> _byDog(List<Rec2> r) {
  final byDog = <String, List<Rec2>>{};
  for (final e in r) {
    byDog.putIfAbsent(e.dog, () => []).add(e);
  }
  return byDog;
}

/// R per cane: somma degli errori mediani del motore / del riferimento.
double ratio2(List<Rec2> r, String baseKey) {
  var m = 0.0, t = 0.0;
  for (final l in _byDog(r).values) {
    m += _med2(l, 'errModel');
    t += _med2(l, baseKey);
  }
  return m / t;
}

double fracBetter2(List<Rec2> r, String baseKey) {
  final byDog = _byDog(r);
  var w = 0;
  for (final l in byDog.values) {
    if (_med2(l, 'errModel') < _med2(l, baseKey)) w++;
  }
  return w / byDog.length;
}

({double est, double lo, double hi}) boot2(
  List<Rec2> recs,
  double Function(List<Rec2>) stat, {
  int reps = 500,
  int seed = 7,
}) {
  final byDog = _byDog(recs);
  final dogs = byDog.keys.toList();
  final r = math.Random(seed);
  final vals = <double>[];
  for (var b = 0; b < reps; b++) {
    final sample = <Rec2>[];
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

Map<String, String> summarize2(List<Rec2> r, {bool shadow = false}) {
  if (r.isEmpty) return {'n': '0'};
  final pu = r.where((e) => e.d('puDays') >= 4).toList();
  String pct(bool Function(Rec2) f) =>
      '${(r.where(f).length / r.length * 100).toStringAsFixed(0)}%';
  return {
    'n eventi / cani': '${r.length} / ${r.map((e) => e.dog).toSet().length}',
    'errore mediano (min)': fmt(boot2(r, (s) => _med2(s, 'errModel'))),
    'errore mediano timer (min)': fmt(boot2(r, (s) => _med2(s, 'errTimer'))),
    'errore mediano stesso orario 7 gg (min)': fmt(
      boot2(r, (s) => _med2(s, 'errHabit')),
    ),
    'R / timer (per cane)': fmt(boot2(r, (s) => ratio2(s, 'errTimer')), dp: 2),
    'R / stesso orario 7 gg': fmt(
      boot2(r, (s) => ratio2(s, 'errHabit')),
      dp: 2,
    ),
    'R / stesso giorno sett.': fmt(
      boot2(r, (s) => ratio2(s, 'errWeekday')),
      dp: 2,
    ),
    'cani in cui batte il timer': fmt(
      boot2(r, (s) => fracBetter2(s, 'errTimer')),
      pct: true,
    ),
    shadow
        ? 'copertura intervallo 10-90% (nominale 80%)'
        : 'copertura della finestra mostrata': fmt(
      boot2(r, (s) => _rate2(s, 'inWin')),
      pct: true,
    ),
    if (shadow)
      'copertura 25-75% (nominale 50%)': fmt(
        boot2(r, (s) => _rate2(s, 'in50')),
        pct: true,
      ),
    'ampiezza mediana della finestra (min)': _med2(
      r,
      'widthWin',
    ).toStringAsFixed(0),
    'errore con segno mediano (− = in ritardo)': _med2(
      r,
      'signedErr',
    ).toStringAsFixed(0),
    'errore mediano vs evento VERO (min)': _med2(
      r,
      'errModelTrue',
    ).toStringAsFixed(0),
    if (pu.isNotEmpty)
      'poliuria da ≥ 4 giorni: n / errore con segno mediano':
          '${pu.length} / ${_med2(pu, 'signedErr').toStringAsFixed(0)}',
    if (shadow)
      'PIT < 0,1 / > 0,9 (attese 10%/10%)':
          '${pct((e) => e.d('pit') < 0.1)} / ${pct((e) => e.d('pit') > 0.9)}',
    'tetto da sveglio rispettato (T15)':
        '${r.where((e) => e.b('capOk')).length}/${r.length}',
  };
}

String report2(String label, List<Rec2> r, {bool shadow = false}) {
  final b = StringBuffer(
    render('$label (tutti)', summarize2(r, shadow: shadow)),
  );
  void sub(String title, bool Function(Rec2) f) {
    final s = r.where(f).toList();
    if (s.length < 20) return;
    b.writeln(render('$label — $title', summarize2(s, shadow: shadow)));
  }

  for (final grp in ['cucciolo', 'adulto', 'anziano', 'cronico', 'poliuria']) {
    sub('gruppo $grp', (e) => e.group == grp);
  }
  sub('orari decisi dal padrone', (e) => e.b('scheduled'));
  sub('a richiesta', (e) => !e.b('scheduled'));
  sub('fine settimana', (e) => e.b('weekend'));
  sub('dopo il cambio di routine (g. 15-28)', (e) => e.b('afterChange'));
  sub('poliuria in corso', (e) => e.b('puActive'));
  sub('solo di giorno (no notte)', (e) => !e.b('overnight'));
  sub('prima pipì del mattino (dopo la notte)', (e) => e.b('overnight'));
  return b.toString();
}

/// Un lavoro del banco v2: scenario, bisogno, passo, griglia.
class Job {
  const Job(
    this.scenario, {
    this.need = Need.pipi,
    this.every = 1,
    this.grid = false,
  });
  final String scenario;
  final Need need;
  final int every;
  final bool grid;
  String get label =>
      '${scenario}_${need.name}${grid ? "_griglia" : ""}'
      '${every > 1 ? "_e$every" : ""}';
}

/// Esegue i [jobs] sui cani con indice ≡ [shard] (mod [of]) e salva i
/// record grezzi in `risultati/tmp/TAG_LABEL_SHARD.json`.
void runShard(
  String tag,
  List<Job> jobs,
  int shard,
  int of, {
  bool shadow = true,
}) {
  final dir = Directory('${outDir()}/tmp')..createSync(recursive: true);
  for (final j in jobs) {
    final bench = buildBench(scenarios[j.scenario]!);
    final base = <Map<String, Object>>[], ombra = <Map<String, Object>>[];
    final grid = <Map<String, Object>>[];
    for (var i = shard; i < bench.length; i += of) {
      // Con la griglia gli eventi e gli orari fissi si valutano insieme,
      // in ordine di tempo, con la stessa storia delle previsioni (R6).
      final r = evaluatePair(
        bench[i],
        j.need,
        every: j.every,
        shadow: shadow,
        gridStepH: j.grid ? (j.need == Need.pipi ? 4 : 6) : 0,
      );
      base.addAll(r.base.map((e) => e.m));
      ombra.addAll(r.ombra.map((e) => e.m));
      grid.addAll(r.grid.map(gridToJson));
      // ignore: avoid_print
      print('$tag ${j.label} ${bench[i].spec.id}');
    }
    File('${dir.path}/${tag}_${j.label}_$shard.json').writeAsStringSync(
      jsonEncode({'base': base, 'ombra': ombra, 'grid': grid}),
    );
  }
}

/// Unisce i frammenti e scrive `risultati/TAG_LABEL.txt`.
String mergeShards(String tag, List<Job> jobs, int of) {
  final all = StringBuffer();
  for (final j in jobs) {
    final base = <Rec2>[], ombra = <Rec2>[];
    final grid = <GridRec>[];
    var missing = 0;
    for (var k = 0; k < of; k++) {
      final f = File('${outDir()}/tmp/${tag}_${j.label}_$k.json');
      if (!f.existsSync()) {
        missing++;
        continue;
      }
      final m = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
      Rec2 rec(dynamic x) =>
          Rec2((x as Map<String, dynamic>).cast<String, Object>());
      base.addAll((m['base'] as List).map(rec));
      ombra.addAll((m['ombra'] as List).map(rec));
      grid.addAll(
        (m['grid'] as List).map((x) => gridFromJson(x as Map<String, dynamic>)),
      );
    }
    if (missing == of) continue;
    final b = StringBuffer();
    if (missing > 0) b.writeln('ATTENZIONE: $missing frammenti mancanti');
    if (grid.isNotEmpty) {
      b.writeln(render('$tag ${j.label} ombra (tutti)', summarizeGrid(grid)));
    }
    if (base.isNotEmpty) b.writeln(report2('$tag ${j.label} BASE', base));
    if (ombra.isNotEmpty) {
      b.writeln(report2('$tag ${j.label} OMBRA', ombra, shadow: true));
    }
    saveText('${tag}_${j.label}', b.toString());
    all.write(b);
  }
  return all.toString();
}
