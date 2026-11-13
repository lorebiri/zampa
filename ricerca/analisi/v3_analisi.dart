// ignore_for_file: avoid_print
// Analisi offline del banco a candidati (ricerca/27). Legge i record di
// banco3.dart (risultati/tmp/v3_SCENARIO_K.json) e prova, cane per cane e
// in modo prequenziale, le strade 1-5: ogni previsione usa solo gli esiti
// già noti alla sua origine (pipì registrata ≤ origine).
//
// Uso: dart run ricerca/analisi/v3_analisi.dart [scenario] [reps]
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

typedef Rec = Map<String, dynamic>;

const minMs = 60000;

List<Rec> load(String scenario) {
  final out = <Rec>[];
  for (var k = 0; k < 4; k++) {
    final f = File('ricerca/analisi/risultati/tmp/v3_${scenario}_$k.json');
    if (!f.existsSync()) continue;
    out.addAll((jsonDecode(f.readAsStringSync()) as List).cast<Rec>());
  }
  return out;
}

double med(List<double> x) {
  if (x.isEmpty) return double.nan;
  final s = [...x]..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

double quant(List<double> sorted, double q) {
  if (sorted.length == 1) return sorted.first;
  final pos = q * (sorted.length - 1);
  final lo = pos.floor(), hi = pos.ceil();
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
}

Map<String, List<Rec>> byDog(List<Rec> r) {
  final m = <String, List<Rec>>{};
  for (final e in r) {
    m.putIfAbsent(e['dog'] as String, () => []).add(e);
  }
  for (final l in m.values) {
    l.sort((a, b) => (a['o'] as int).compareTo(b['o'] as int));
  }
  return m;
}

double ae(Rec e, String k) =>
    ((e['act'] as int) - (e[k] as num)).abs() / minMs;

/// R per cane: Σ errore mediano di [k] / Σ errore mediano di [ref].
double ratio(List<Rec> r, String k, String ref) {
  var a = 0.0, b = 0.0;
  for (final l in byDog(r).values) {
    a += med([for (final e in l) ae(e, k)]);
    b += med([for (final e in l) ae(e, ref)]);
  }
  return a / b;
}

double rate(List<Rec> r, bool Function(Rec) f) =>
    r.isEmpty ? double.nan : r.where(f).length / r.length;

({double est, double lo, double hi}) boot(
  List<Rec> r,
  double Function(List<Rec>) stat, {
  int reps = 1000,
  int seed = 7,
}) {
  final m = byDog(r);
  final dogs = m.keys.toList()..sort();
  final rnd = math.Random(seed);
  final vals = <double>[];
  for (var b = 0; b < reps; b++) {
    final s = <Rec>[];
    for (var k = 0; k < dogs.length; k++) {
      s.addAll(m[dogs[rnd.nextInt(dogs.length)]]!);
    }
    final v = stat(s);
    if (v.isFinite) vals.add(v);
  }
  vals.sort();
  return (
    est: stat(r),
    lo: vals[(vals.length * 0.025).floor()],
    hi: vals[(vals.length * 0.975).floor().clamp(0, vals.length - 1)],
  );
}

String f2(({double est, double lo, double hi}) x, {int dp = 2, bool pct = false}) {
  String g(double v) =>
      pct ? '${(v * 100).toStringAsFixed(dp)}%' : v.toStringAsFixed(dp);
  return '${g(x.est)} [${g(x.lo)}–${g(x.hi)}]';
}

// ---------------------------------------------------------------------------
// Metodi puntuali (strada 1) e intervalli conformi (strada 4).
// ---------------------------------------------------------------------------

bool inSleep(int wake, int sleep, DateTime t) {
  final h = t.hour + t.minute / 60.0;
  final s = sleep.toDouble(), w = wake.toDouble();
  if (s == w) return false;
  return s > w ? (h >= s || h < w) : (h >= s && h < w);
}

/// Previsione «del mattino», nota all'origine: la previsione di base cade
/// dopo la notte (almeno 5 ore dopo l'ultima pipì, in un altro giorno).
bool morningEx(Rec e) {
  final p = DateTime.fromMillisecondsSinceEpoch(e['prev'] as int);
  final b = DateTime.fromMillisecondsSinceEpoch(e['be'] as int);
  return b.difference(p).inHours >= 5 && b.day != p.day;
}

/// Esegue un metodo sequenziale su ogni cane. [point] riceve il record e i
/// record precedenti dello stesso cane con esito già noto (act ≤ origine),
/// e restituisce l'orario previsto (ms). Il risultato è salvato in e[key].
void runPoint(
  List<Rec> ev,
  String key,
  double Function(Rec e, List<Rec> done) point,
) {
  for (final l in byDog(ev).values) {
    final seen = <Rec>[];
    for (final e in l) {
      final o = e['o'] as int;
      final done = [
        for (final d in seen)
          if ((d['act'] as int) <= o) d,
      ];
      e[key] = point(e, done);
      seen.add(e);
    }
  }
}

/// Errore assoluto medio (min) di [k] sugli ultimi [n] record di [done].
double recentMae(List<Rec> done, String k, int n, {bool? morning}) {
  final xs = <double>[];
  for (var i = done.length - 1; i >= 0 && xs.length < n; i--) {
    final d = done[i];
    if (morning != null && morningEx(d) != morning) continue;
    xs.add(ae(d, k));
  }
  if (xs.isEmpty) return double.nan;
  return xs.reduce((a, b) => a + b) / xs.length;
}

double recentMedAe(List<Rec> done, String k, int n, {bool? morning}) {
  final xs = <double>[];
  for (var i = done.length - 1; i >= 0 && xs.length < n; i--) {
    final d = done[i];
    if (morning != null && morningEx(d) != morning) continue;
    xs.add(ae(d, k));
  }
  return med(xs);
}

/// Residui con segno (min, act − previsione) di [k] negli ultimi [n].
List<double> residuals(List<Rec> done, String k, int n, {bool? morning}) {
  final xs = <double>[];
  for (var i = done.length - 1; i >= 0 && xs.length < n; i--) {
    final d = done[i];
    if (morning != null && morningEx(d) != morning) continue;
    xs.add(((d['act'] as int) - (d[k] as num)) / minMs);
  }
  return xs;
}

/// Combinazione esponenziale (Hedge) dei candidati [cs]: pesi ∝
/// exp(−η · errore assoluto medio recente / 60), media pesata degli orari.
double Function(Rec, List<Rec>) hedge(
  List<String> cs, {
  double eta = 2,
  int n = 20,
  bool split = false,
  bool weightedMedian = false,
}) => (e, done) {
  final m = split ? morningEx(e) : null;
  var useDone = done;
  if (split &&
      done.where((d) => morningEx(d) == m).length < 6) {
    useDone = done;
  }
  final errs = [
    for (final c in cs)
      recentMae(useDone, c, n, morning: split && useDone == done ? m : null),
  ];
  if (errs.any((x) => x.isNaN)) {
    var s = 0.0;
    for (final c in cs) {
      s += (e[c] as num).toDouble();
    }
    return s / cs.length;
  }
  final best = errs.reduce(math.min);
  final w = [for (final x in errs) math.exp(-eta * (x - best) / 60)];
  final tw = w.reduce((a, b) => a + b);
  if (weightedMedian) {
    final idx = List.generate(cs.length, (i) => i)
      ..sort((a, b) => (e[cs[a]] as num).compareTo(e[cs[b]] as num));
    var acc = 0.0;
    for (final i in idx) {
      acc += w[i] / tw;
      if (acc >= 0.5) return (e[cs[i]] as num).toDouble();
    }
    return (e[cs[idx.last]] as num).toDouble();
  }
  var s = 0.0;
  for (var i = 0; i < cs.length; i++) {
    s += w[i] / tw * (e[cs[i]] as num).toDouble();
  }
  return s;
};

/// Correzione del ritardo: [k] spostato della mediana dei residui recenti
/// (ristretta verso 0 con [shrink] pseudo-residui nulli).
double Function(Rec, List<Rec>) debias(
  String k, {
  int n = 20,
  double shrink = 5,
  bool split = true,
  double maxShift = 120,
}) => (e, done) {
  final m = morningEx(e);
  var res = residuals(done, k, n, morning: split ? m : null);
  if (split && res.length < 6) res = residuals(done, k, n);
  final v = (e[k] as num).toDouble();
  if (res.isEmpty) return v;
  final padded = [...res, for (var i = 0; i < shrink; i++) 0.0];
  final sh = med(padded).clamp(-maxShift, maxShift);
  return v + sh * minMs;
};

/// Intervallo conforme sul punto [k]: quantili [lo] e [hi] dei residui
/// recenti (stessa parte del giorno se ce ne sono almeno [minSplit]); con
/// meno di [minN] residui usa [fallLo]-[fallHi].
void runInterval(
  List<Rec> ev,
  String k,
  String key, {
  double lo = 0.1,
  double hi = 0.9,
  int n = 40,
  int minN = 8,
  int minSplit = 8,
  String fallLo = 's10',
  String fallHi = 's90',
  double inflate = 1.0,
}) {
  for (final l in byDog(ev).values) {
    final seen = <Rec>[];
    for (final e in l) {
      final o = e['o'] as int;
      final done = [
        for (final d in seen)
          if ((d['act'] as int) <= o) d,
      ];
      final m = morningEx(e);
      var res = residuals(done, k, n, morning: m);
      if (res.length < minSplit) res = residuals(done, k, n);
      final p = (e[k] as num).toDouble();
      if (res.length < minN) {
        e['${key}_lo'] = math.min(p, (e[fallLo] as num).toDouble());
        e['${key}_hi'] = math.max(p, (e[fallHi] as num).toDouble());
      } else {
        res.sort();
        final ql = quant(res, lo) * inflate, qh = quant(res, hi) * inflate;
        e['${key}_lo'] = math.max(o.toDouble(), p + ql * minMs);
        e['${key}_hi'] = math.max(p + qh * minMs, (e['${key}_lo'] as double) + 30 * minMs);
      }
      seen.add(e);
    }
  }
}

bool inside(Rec e, String key) {
  final a = e['act'] as int;
  return a >= (e['${key}_lo'] as num) && a <= (e['${key}_hi'] as num);
}

String row(List<Rec> ev, String k, {String? interval, int reps = 1000}) {
  final rt = boot(ev, (s) => ratio(s, k, 'timer'), reps: reps);
  final rh = boot(ev, (s) => ratio(s, k, 'habit'), reps: reps);
  final e = med([for (final x in ev) ae(x, k)]);
  final signed = med([
    for (final x in ev) ((x['act'] as int) - (x[k] as num)) / minMs,
  ]);
  var s =
      '${k.padRight(18)} err ${e.toStringAsFixed(0).padLeft(3)}  '
      'R/timer ${f2(rt)}  R/stesso orario ${f2(rh)}  '
      'segno ${signed.toStringAsFixed(0)}';
  if (interval != null) {
    final c = boot(ev, (x) => rate(x, (y) => inside(y, interval)), reps: reps);
    final w = med([
      for (final x in ev)
        ((x['${interval}_hi'] as num) - (x['${interval}_lo'] as num)) / minMs,
    ]);
    s += '  copertura ${f2(c, dp: 0, pct: true)} ampiezza ${w.toStringAsFixed(0)}';
  }
  return s;
}

// ---------------------------------------------------------------------------
// Probabilità nella prossima ora (strade 3 e 4).
// ---------------------------------------------------------------------------

String calib(List<Rec> g, String pk, {String yk = 'y'}) {
  final bins = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.8, 1.0001];
  final b = StringBuffer();
  var worst = 0.0;
  var brier = 0.0, brierC = 0.0;
  for (final e in g) {
    final p = (e[pk] as num).toDouble(), y = (e[yk] as int).toDouble();
    brier += (p - y) * (p - y);
    final c = (e['pClim'] as num).toDouble();
    brierC += (c - y) * (c - y);
  }
  for (var i = 0; i + 1 < bins.length; i++) {
    final s = [
      for (final e in g)
        if ((e[pk] as num) >= bins[i] && (e[pk] as num) < bins[i + 1]) e,
    ];
    if (s.isEmpty) continue;
    final mp = s.map((e) => (e[pk] as num).toDouble()).reduce((a, c) => a + c) /
        s.length;
    final mo = s.where((e) => e[yk] == 1).length / s.length;
    final d = (mo - mp) * 100;
    if (s.length >= 50 && d.abs() > worst.abs()) worst = d;
    b.write(
      ' ${bins[i].toStringAsFixed(1)}:n${s.length},${d.toStringAsFixed(0)}',
    );
  }
  return '${pk.padRight(14)} peggiore(n≥50) ${worst.toStringAsFixed(0).padLeft(3)} '
      'BSS ${(1 - brier / brierC).toStringAsFixed(3)} |$b';
}

/// Probabilità condizionata dal punto [k] dell'evento con la stessa pipì
/// precedente e dai residui di [k] noti all'origine della griglia:
/// P(T ≤ o + 60 | T > o), T = punto + residuo, residui lisciati con un
/// nucleo di [bw] minuti. Con pochi residui usa [fallback].
void gridProb(
  List<Rec> ev,
  List<Rec> grid,
  String k,
  String key, {
  int n = 40,
  double bw = 20,
  int minN = 8,
  String fallback = 'pCal',
  double cap = 0.9,
  double floor = 0.0,
}) {
  final evDog = byDog(ev);
  for (final entry in byDog(grid).entries) {
    final evs = evDog[entry.key] ?? const <Rec>[];
    final byPrev = {for (final e in evs) e['prev'] as int: e};
    for (final gr in entry.value) {
      final o = gr['o'] as int;
      final src = byPrev[gr['prev'] as int];
      final done = [
        for (final d in evs)
          if ((d['act'] as int) <= o) d,
      ];
      if (src == null || done.length < minN) {
        gr[key] = (gr[fallback] as num).toDouble();
        continue;
      }
      final m = morningEx(src);
      var res = residuals(done, k, n, morning: m);
      if (res.length < minN) res = residuals(done, k, n);
      final p = (src[k] as num).toDouble();
      double cdf(double tMs) {
        final x = (tMs - p) / minMs;
        var s = 0.0;
        for (final r in res) {
          s += _phi((x - r) / bw);
        }
        return s / res.length;
      }

      final f0 = cdf(o.toDouble()), f1 = cdf(o + 60.0 * minMs);
      final surv = 1 - f0;
      final pr = surv < 1e-3 ? cap : ((f1 - f0) / surv);
      gr[key] = pr.clamp(floor, cap);
    }
  }
}

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

/// Strada 2: previsioni aggiornate dopo un innesco registrato. Per ogni
/// record 'tr' la previsione «vecchia» è quella del metodo [k] fatta dopo
/// l'ultima pipì (record 'ev' con la stessa pipì precedente), portata
/// all'origine se già passata. Candidati aggiornati: modello in ombra
/// riaddestrato con l'innesco, regola «ritardo tipico dopo l'innesco» del
/// cane (mediana dei ritardi passati, solo anticipo), e la loro media.
String triggerReport(List<Rec> ev, List<Rec> trig, String k, {int reps = 300}) {
  final evDog = byDog(ev);
  final b = StringBuffer();
  for (final entry in byDog(trig).entries) {
    final evs = evDog[entry.key] ?? const <Rec>[];
    final byPrev = {for (final e in evs) e['prev'] as int: e};
    final seen = <Rec>[];
    for (final t in entry.value) {
      final o = (t['o'] as int).toDouble();
      final src = byPrev[t['prev'] as int];
      if (src == null) continue;
      final stale = math.max(o, (src[k] as num).toDouble());
      t['stale'] = stale;
      t['upd_se'] = math.max(o, (t['se'] as int).toDouble());
      // Ritardo tipico del cane dopo questo tipo di innesco (esiti noti).
      final delays = [
        for (final d in seen)
          if (d['trig'] == t['trig'] && (d['act'] as int) <= o)
            ((d['act'] as int) - (d['o'] as int)) / minMs,
      ];
      final dly = delays.length >= 5 ? med(delays.reversed.take(20).toList()) : null;
      t['upd_rule'] = dly == null ? stale : math.min(stale, o + dly * minMs);
      t['upd_mix'] = (stale + (t['upd_se'] as double)) / 2;
      // Aggiornamento col passare del tempo: mediana di T dato T > origine,
      // T = punto + residuo (residui del cane noti all'origine).
      final done = [
        for (final d in evs)
          if ((d['act'] as int) <= o) d,
      ];
      final res = residuals(done, k, 40)..sort();
      var cond = stale;
      if (res.length >= 8) {
        final p = (src[k] as num).toDouble();
        final x0 = (o - p) / minMs;
        final after = [for (final r in res) if (r > x0) r];
        if (after.length >= 3) cond = p + med(after) * minMs;
      }
      t['upd_cond'] = math.max(o, cond);
      t['upd_condrule'] = dly == null
          ? t['upd_cond']
          : math.min(t['upd_cond'] as double, o + dly * minMs);
      t['use'] = true;
      seen.add(t);
    }
  }
  final used = [
    for (final t in trig)
      if (t['use'] == true) t,
  ];
  for (final type in ['acqua', 'pasto', 'risveglio', 'tutti']) {
    final s = [
      for (final t in used)
        if (type == 'tutti' || t['trig'] == type) t,
    ];
    if (s.length < 30) continue;
    b.writeln('  innesco $type (n=${s.length}):');
    for (final u in [
      'stale',
      'upd_se',
      'upd_rule',
      'upd_mix',
      'upd_cond',
      'upd_condrule',
    ]) {
      final r = boot(s, (x) => ratio(x, u, 'stale'), reps: reps);
      final e = med([for (final x in s) ae(x, u)]);
      final sg = med([
        for (final x in s) ((x['act'] as int) - (x[u] as num)) / minMs,
      ]);
      b.writeln(
        '    ${u.padRight(9)} err ${e.toStringAsFixed(0).padLeft(3)} '
        'R/vecchia ${f2(r)} segno ${sg.toStringAsFixed(0)}',
      );
    }
  }
  return b.toString();
}

void main(List<String> args) {
  final scenario = args.isNotEmpty ? args[0] : 'realistico';
  final reps = args.length > 1 ? int.parse(args[1]) : 300;
  final all = load(scenario);
  final ev = [
    for (final e in all)
      if (e['k'] == 'ev') e,
  ];
  final grid = [
    for (final e in all)
      if (e['k'] == 'gr') e,
  ];
  final trig = [
    for (final e in all)
      if (e['k'] == 'tr') e,
  ];
  print('$scenario: ${ev.length} eventi, ${grid.length} griglia, '
      '${trig.length} inneschi, ${byDog(ev).length} cani');

  final phase = args.length > 2 ? args[2] : 'tutto';
  // Strada 1: riferimenti e combinazioni.
  runPoint(ev, 'avgBS', (e, _) => ((e['be'] as int) + (e['se'] as int)) / 2);
  runPoint(ev, 'med3', medianOf(['be', 'se', 'habit']));
  runPoint(ev, 'med4', medianOf(['be', 'se', 'habit', 'weekday']));
  runPoint(ev, 'med5', medianOf(['be', 'se', 'habit', 'weekday', 'timer']));
  runPoint(ev, 'med3T', medianOf(['be', 'se', 'timer']));
  runPoint(ev, 'med3W', medianOf(['be', 'se', 'weekday']));
  runPoint(ev, 'medBH', medianOf(['be', 'habit']));
  runPoint(ev, 'medSH', medianOf(['se', 'habit']));
  runPoint(ev, 'med4noS', medianOf(['be', 'habit', 'weekday', 'timer']));
  runPoint(ev, 'med3noS', medianOf(['be', 'habit', 'weekday']));
  runPoint(ev, 'hedgeBSH2.0', hedge(['be', 'se', 'habit']));
  runPoint(ev, 'hedgeBSHwm', hedge(['be', 'se', 'habit'], weightedMedian: true));
  runPoint(ev, 'deb_med3', debias('med3'));
  runPoint(ev, 'deb_med3_10', debias('med3', shrink: 10, maxShift: 60));
  final points = [
    'be',
    'se',
    'habit',
    'timer',
    'weekday',
    'avgBS',
    'med3',
    'med4',
    'med5',
    'med3T',
    'med3W',
    'medBH',
    'medSH',
    'med4noS',
    'med3noS',
    'hedgeBSH2.0',
    'hedgeBSHwm',
    'deb_med3',
    'deb_med3_10',
  ];
  if (phase == 'tutto' || phase == 'punti') {
    for (final k in points) {
      print(row(ev, k, reps: reps));
    }
  }

  // Strada 4: intervalli conformi sul punto scelto.
  final best = args.length > 3 ? args[3] : 'med5';
  for (final e in ev) {
    e['base_lo'] = e['bws'];
    e['base_hi'] = e['bwe'];
    e['sh_lo'] = e['s10'];
    e['sh_hi'] = e['s90'];
  }
  if (phase == 'tutto' || phase == 'intervalli') {
    print(row(ev, 'be', interval: 'base', reps: reps));
    print(row(ev, 'se', interval: 'sh', reps: reps));
    for (final (lo, hi, n) in [
      (0.1, 0.9, 40),
      (0.075, 0.925, 40),
      (0.075, 0.925, 60),
      (0.06, 0.94, 40),
      (0.05, 0.95, 40),
    ]) {
      final key = 'cf${lo}_$n';
      runInterval(ev, best, key, lo: lo, hi: hi, n: n);
      print(row(ev, best, interval: key, reps: reps));
    }
  }
  runInterval(ev, best, 'cf', lo: 0.075, hi: 0.925, n: 40);

  // Probabilità nella prossima ora: hazard empirico del cane (strade 3-4).
  if (phase == 'tutto' || phase == 'griglia') {
    print(calib(grid, 'pRaw'));
    print(calib(grid, 'pCal'));
    for (final (rel, bw, k0, hb) in [
      (true, 0.25, 3.0, 0.0),
      (true, 0.25, 10.0, 0.0),
      (true, 0.25, 10.0, 180.0),
      (true, 0.25, 20.0, 180.0),
      (false, 30.0, 10.0, 0.0),
      (false, 30.0, 10.0, 180.0),
      (false, 30.0, 20.0, 180.0),
      (false, 45.0, 20.0, 180.0),
    ]) {
      final key = 'hz${rel ? "R" : "A"}${bw}_${k0}_$hb';
      hazardProb(ev, grid, best, key, bw: bw, prior: k0, relative: rel,
          hourBw: hb);
      print(calib(grid, key));
    }
  }

  if (phase == 'tutto' || phase == 'sottogruppi') {
    print('Sottogruppi ($best, intervallo cf):');
    for (final (name, f) in <(String, bool Function(Rec))>[
      ('cucciolo', (e) => e['group'] == 'cucciolo'),
      ('adulto', (e) => e['group'] == 'adulto'),
      ('anziano', (e) => e['group'] == 'anziano'),
      ('cronico', (e) => e['group'] == 'cronico'),
      ('poliuria', (e) => e['group'] == 'poliuria'),
      ('orari padrone', (e) => e['scheduled'] == true),
      ('a richiesta', (e) => e['scheduled'] == false),
      ('fine settimana', (e) => e['weekend'] == true),
      ('dopo il cambio', (e) => e['afterChange'] == true),
      ('prima del mattino', (e) => e['overnight'] == true),
      ('di giorno', (e) => e['overnight'] == false),
    ]) {
      final s = ev.where(f).toList();
      print('  $name (n=${s.length})');
      print('    ${row(s, best, interval: 'cf', reps: reps)}');
      print('    ${row(s, 'be', interval: 'base', reps: reps)}');
    }
    final pu = ev.where((e) => (e['puDays'] as num) >= 4).toList();
    print('  poliuria ≥ 4 giorni: n ${pu.length}, segno $best '
        '${med([for (final x in pu) ((x['act'] as int) - (x[best] as num)) / minMs]).toStringAsFixed(0)}');
  }

  if (phase == 'tutto' || phase == 'inneschi') {
    print('Strada 2, inneschi (previsione vecchia = $best):');
    print(triggerReport(ev, trig, best, reps: reps));
    print('  solo cani a richiesta:');
    print(triggerReport(
      ev,
      [for (final t in trig) if (t['scheduled'] == false) t],
      best,
      reps: reps,
    ));
  }
}

double Function(Rec, List<Rec>) medianOf(List<String> ks) => (e, _) {
  final x = [for (final k in ks) (e[k] as num).toDouble()]..sort();
  final n = x.length;
  return n.isOdd ? x[n ~/ 2] : (x[n ~/ 2 - 1] + x[n ~/ 2]) / 2;
};

/// Hazard empirico del cane (strada 3): per ogni pipì passata con esito
/// noto, pseudo-origini ogni 15 minuti da sveglio tra la pipì precedente e
/// quella dopo; stato x = minuti rispetto all'orario previsto [k]; esito =
/// pipì entro 60 minuti. P(x) = media pesata con un nucleo di [bw] minuti
/// (o di [bw] in scala log(τ/intervallo) se [relative]), con [prior]
/// pseudo-osservazioni alla frequenza media del cane. Fuori campione per
/// costruzione: si usano solo le pseudo-origini con t + 60 ≤ origine.
void hazardProb(
  List<Rec> ev,
  List<Rec> grid,
  String k,
  String key, {
  double bw = 30,
  double prior = 3,
  bool relative = false,
  int nEvents = 60,
  double cap = 0.9,
  double hourBw = 0,
}) {
  final evDog = byDog(ev);
  for (final entry in byDog(grid).entries) {
    final evs = evDog[entry.key] ?? const <Rec>[];
    final byPrev = {for (final e in evs) e['prev'] as int: e};
    for (final gr in entry.value) {
      final o = gr['o'] as int;
      final src = byPrev[gr['prev'] as int];
      final done = [
        for (final d in evs)
          if ((d['act'] as int) <= o) d,
      ];
      if (src == null || done.length < 8) {
        gr[key] = (gr['pRaw'] as num).toDouble();
        continue;
      }
      final wake = gr['wake'] as int, sleep = gr['sleep'] as int;
      double state(Rec d, int t) {
        if (!relative) return (t - (d[k] as num)) / minMs;
        final tau = math.max(5.0, (t - (d['prev'] as int)) / minMs);
        final m = math.max(15.0, ((d[k] as num) - (d['prev'] as int)) / minMs);
        return math.log(tau / m);
      }

      final xs = <double>[], ys = <double>[], hs = <double>[];
      double hourOf(int t) {
        final d = DateTime.fromMillisecondsSinceEpoch(t);
        return d.hour * 60.0 + d.minute;
      }
      for (final d in done.reversed.take(nEvents)) {
        final a = d['act'] as int;
        for (var t = (d['prev'] as int) + 15 * minMs; t < a; t += 15 * minMs) {
          if (t + 60 * minMs > o) break;
          if (inSleep(wake, sleep, DateTime.fromMillisecondsSinceEpoch(t))) {
            continue;
          }
          xs.add(state(d, t));
          hs.add(hourOf(t));
          ys.add(a <= t + 60 * minMs ? 1 : 0);
        }
      }
      if (xs.length < 20) {
        gr[key] = (gr['pRaw'] as num).toDouble();
        continue;
      }
      final base = ys.reduce((a, b) => a + b) / ys.length;
      final x0 = state(src, o);
      final h0 = hourOf(o);
      var sw = prior, sy = prior * base;
      for (var i = 0; i < xs.length; i++) {
        final z = (xs[i] - x0) / bw;
        var w = math.exp(-0.5 * z * z);
        if (hourBw > 0) {
          var dh = (hs[i] - h0).abs();
          if (dh > 720) dh = 1440 - dh;
          final zh = dh / hourBw;
          w *= math.exp(-0.5 * zh * zh);
        }
        sw += w;
        sy += w * ys[i];
      }
      gr[key] = (sy / sw).clamp(0.0, cap);
    }
  }
}
