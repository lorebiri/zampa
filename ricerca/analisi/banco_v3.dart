// Ciclo v3 (ricerca/28): banco della cacca legata ai pasti.
//
// Origine onesta: 1 minuto dopo la cacca precedente registrata; si vedono
// solo i log con orario ≤ origine (T1 controllato a ogni previsione).
// Bersaglio: la cacca successiva registrata (giorni 8-28).
part of 'banco.dart';

class PoopRec {
  PoopRec(this.dog, this.group, this.scheduled, this.errs, this.signed,
      this.in50, this.in80);
  final String dog, group;
  final bool scheduled;

  /// Errore assoluto (min) per candidato: timer, H, W, M, base, v3.
  final Map<String, double> errs;
  final double signed;
  final bool in50, in80;
}

/// Valuta la cacca su un cane. Con [full] calcola anche le finestre (più
/// lento: rifà le previsioni passate).
List<PoopRec> evaluatePoop(
  Truth tr, {
  int every = 1,
  bool full = false,
  bool base = false,
  PoopModelParams p = const PoopModelParams(),
}) {
  const cluster = 30.0;
  final outs = PottyPredictor.outings(
    tr.logged,
    type: LogType.cacca,
    clusterMinutes: cluster,
  ).map((o) => o.time).toList();
  final evalFrom = simStart.add(const Duration(days: evalFromDay));
  final recs = <PoopRec>[];
  final engine = EliminationModel();
  var idx = 0;
  for (var i = 1; i < outs.length; i++) {
    final actual = outs[i];
    if (actual.isBefore(evalFrom)) continue;
    if (idx++ % every != 0) continue;
    final prev = outs[i - 1];
    final origin = prev.add(const Duration(minutes: 1));
    final visible = tr.logged.where((l) => !l.time.isAfter(origin)).toList();
    if (visible.any((l) => l.time.isAfter(origin))) {
      throw StateError('T1: log futuro visibile');
    }
    final past = outs.where((e) => !e.isAfter(origin)).toList();
    final prior = BioParams.forNeed(Need.cacca, tr.dog, origin);
    final r = _refs3(tr, past, prev, cluster, prior.median);
    final c = poopCandidates(tr.dog, visible, origin, p: p)!;
    double e(DateTime t) => actual.difference(t).inMinutes.abs().toDouble();
    final errs = <String, double>{
      'timer': e(r.timer),
      'H': e(r.habit),
      'W': e(r.weekday),
      'M': e(c.m),
      'v3': e(c.at),
      'medMH': e(DateTime.fromMillisecondsSinceEpoch(
          (c.m.millisecondsSinceEpoch + c.h.millisecondsSinceEpoch) ~/ 2)),
      'min3': e([c.m, c.h, c.w].reduce((a, b) => a.isBefore(b) ? a : b)),
      'medMHT': e(_medT([c.m, c.h, r.timer])),
      'medHWT': e(_medT([c.h, c.w, r.timer])),
      'med4': e(_medT([c.m, c.h, c.w, r.timer])),
    };
    if (base) {
      final f = engine
          .fit(tr.dog, Need.cacca, visible, const [], origin, shadow: false)
          .forecast(origin, withAccuracy: false, v2: false);
      errs['base'] = e(f.expectedAt);
    }
    var in50 = false, in80 = false;
    if (full) {
      final f = poopForecast(tr.dog, visible, origin, p: p)!;
      in50 = !actual.isBefore(f.lo50) && !actual.isAfter(f.hi50);
      in80 = !actual.isBefore(f.lo80) && !actual.isAfter(f.hi80);
    }
    recs.add(PoopRec(tr.spec.id, tr.spec.group, _isScheduled(tr), errs,
        actual.difference(c.at).inMinutes.toDouble(), in50, in80));
  }
  return recs;
}

double poopRatio(List<PoopRec> r, String a, String b) {
  final byDog = <String, List<PoopRec>>{};
  for (final e in r) {
    byDog.putIfAbsent(e.dog, () => []).add(e);
  }
  var x = 0.0, y = 0.0;
  for (final l in byDog.values) {
    x += _median(l.map((e) => e.errs[a]!).toList());
    y += _median(l.map((e) => e.errs[b]!).toList());
  }
  return x / y;
}

({double est, double lo, double hi}) bootPoop(
  List<PoopRec> recs,
  double Function(List<PoopRec>) stat, {
  int reps = 1000,
}) {
  final byDog = <String, List<PoopRec>>{};
  for (final e in recs) {
    byDog.putIfAbsent(e.dog, () => []).add(e);
  }
  final dogs = byDog.keys.toList();
  final r = math.Random(7);
  final vals = <double>[];
  for (var b = 0; b < reps; b++) {
    final s = <PoopRec>[];
    for (var k = 0; k < dogs.length; k++) {
      s.addAll(byDog[dogs[r.nextInt(dogs.length)]]!);
    }
    final v = stat(s);
    if (v.isFinite) vals.add(v);
  }
  vals.sort();
  return (
    est: stat(recs),
    lo: vals[(vals.length * 0.025).floor()],
    hi: vals[(vals.length * 0.975).floor().clamp(0, vals.length - 1)],
  );
}

String reportPoop(String label, List<PoopRec> r, {int reps = 1000}) {
  final b = StringBuffer('## $label (n = ${r.length}, cani = '
      '${r.map((e) => e.dog).toSet().length})\n');
  final keys = r.first.errs.keys.toList();
  for (final k in keys) {
    final med = _median(r.map((e) => e.errs[k]!).toList());
    final rt = bootPoop(r, (s) => poopRatio(s, k, 'timer'), reps: reps);
    final rh = poopRatio(r, k, 'H');
    b.writeln('- $k: errore mediano ${med.toStringAsFixed(0)} min, '
        'R/timer ${fmt(rt, dp: 2)}, R/H ${rh.toStringAsFixed(2)}');
  }
  b.writeln('- v3 errore con segno mediano: '
      '${_median(r.map((e) => e.signed).toList()).toStringAsFixed(0)}');
  if (r.any((e) => e.in80 || e.in50)) {
    b.writeln('- v3 copertura 50%: '
        '${(rateOfP(r, (e) => e.in50) * 100).toStringAsFixed(0)}%, '
        '80%: ${(rateOfP(r, (e) => e.in80) * 100).toStringAsFixed(0)}%');
  }
  for (final (t, f) in [
    ('orari decisi dal padrone', (PoopRec e) => e.scheduled),
    ('a richiesta', (PoopRec e) => !e.scheduled),
    ('cuccioli', (PoopRec e) => e.group == 'cucciolo'),
    ('adulti', (PoopRec e) => e.group == 'adulto'),
    ('anziani', (PoopRec e) => e.group == 'anziano'),
  ]) {
    final s = r.where(f).toList();
    if (s.length < 20) continue;
    b.writeln('- $t (n=${s.length}), R/timer: ' +
        [for (final k in keys) '$k ${poopRatio(s, k, 'timer').toStringAsFixed(2)}']
            .join(', '));
  }
  return b.toString();
}

double rateOfP(List<PoopRec> r, bool Function(PoopRec) f) =>
    r.isEmpty ? double.nan : r.where(f).length / r.length;

String runPoopBench(String scenario,
    {int every = 1,
    bool full = false,
    bool base = false,
    int reps = 1000,
    PoopModelParams p = const PoopModelParams()}) {
  final bench = buildBench(scenarios[scenario]!);
  final r = <PoopRec>[];
  for (final t in bench) {
    r.addAll(evaluatePoop(t, every: every, full: full, base: base, p: p));
  }
  return reportPoop('cacca $scenario (un evento su $every)', r, reps: reps);
}

DateTime _medT(List<DateTime> x) {
  final s = x.map((t) => t.millisecondsSinceEpoch.toDouble()).toList();
  return DateTime.fromMillisecondsSinceEpoch(_median(s).round());
}
