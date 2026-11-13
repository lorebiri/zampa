import 'dart:math' as math;

import '../models.dart';
import 'bio_params.dart';
import 'pee_forecast_v2.dart' show referenceForecasts, sameTimeForecast;
import 'potty_predictor.dart';

/// PREVISIONE DELLA CACCA LEGATA AI PASTI (ricerca/28 §2)
///
/// La cacca non segue un timer: segue il riflesso gastrocolico (30-60 minuti
/// dopo un pasto, 05 §P8) e le uscite (la passeggiata la fa arrivare nei
/// primi minuti). Il modello «ad ancore» guarda le occasioni dei prossimi
/// 30 orari:
///   • ancore «pasto»: gli orari abituali dei pasti (o il pasto già segnato);
///   • ancore «uscita»: gli orari abituali delle uscite (pipì segnate).
/// Per ogni orario abituale il cane ha una sua probabilità, misurata sui
/// suoi giorni passati: quante volte, quando il colon era «pronto» (almeno
/// metà del suo intervallo tipico dall'ultima cacca), la cacca è arrivata
/// entro la finestra dopo quell'orario. Il primo orario in cui la
/// probabilità cumulata supera il 50% è la previsione dell'ancora (M).
/// Senza storia valgono i valori tipici per età (cucciolo: più pasti, più
/// probabilità, ritardo più breve).
///
/// L'orario mostrato è la MEDIANA di M, «stesso orario» (H, ultimi 7 giorni)
/// e timer (T, intervallo medio) (v3.1; la regola congelata aggiungeva lo
/// «stesso giorno della settimana», W): regola scritta
/// prima della verifica in ricerca/analisi/risultati/cacca_regola_congelata.md.
/// Nessun dato dal futuro: si usano solo i log fino a [now].

/// Tipo di ancora.
enum PoopAnchorKind { pasto, uscita }

/// Un'occasione futura di fare la cacca.
class PoopAnchor {
  const PoopAnchor(this.kind, this.at, this.slot, this.prob, this.predicted);
  final PoopAnchorKind kind;

  /// Orario dell'ancora (pasto o uscita) e orario previsto della cacca.
  final DateTime at, predicted;

  /// Orario abituale (minuti dalla mezzanotte) a cui appartiene.
  final int slot;

  /// Probabilità che la cacca arrivi dopo questa ancora, se non è già
  /// arrivata prima.
  final double prob;
}

class PoopForecast {
  const PoopForecast({
    required this.last,
    required this.expectedAt,
    required this.anchorAt,
    required this.sameTime,
    required this.sameWeekday,
    required this.anchors,
    required this.lo50,
    required this.hi50,
    required this.lo80,
    required this.hi80,
    required this.nResiduals,
    required this.mainAnchor,
  });

  final DateTime last;

  /// Orario mostrato (mediana dei tre candidati) e i candidati.
  final DateTime expectedAt, anchorAt, sameTime, sameWeekday;

  /// Le ancore dei prossimi 30 orari, in ordine.
  final List<PoopAnchor> anchors;

  /// Finestre «di solito» (50%) e all'80%, dai residui passati del cane.
  final DateTime lo50, hi50, lo80, hi80;
  final int nResiduals;

  /// L'ancora che porta la probabilità cumulata oltre il 50% (null se
  /// nessuna nei prossimi 30 orari).
  final PoopAnchor? mainAnchor;

  /// Probabilità (0-0,9) che la cacca arrivi entro [minutes] da [now].
  double probWithin(DateTime now, int minutes) {
    var s = 1.0;
    final until = now.add(Duration(minutes: minutes));
    for (final a in anchors) {
      if (a.predicted.isAfter(until)) break;
      if (a.predicted.isBefore(now.subtract(const Duration(minutes: 20)))) {
        continue;
      }
      s *= 1 - a.prob;
    }
    return (1 - s).clamp(0.0, 0.9);
  }
}

/// Parametri del modello (congelati con la regola).
class PoopModelParams {
  const PoopModelParams({
    this.historyDays = 21,
    this.slotDays = 14,
    this.slotFreq = 0.35,
    this.readyFrac = 0.65,
    this.mealWindow = const (10, 150),
    this.outWindow = const (-10, 40),
    this.pseudo = 3,
  });
  final int historyDays, slotDays;
  final double slotFreq, readyFrac;
  final (int, int) mealWindow, outWindow;
  final double pseudo;
}

int _mod(DateTime t) => t.hour * 60 + t.minute;

double _median(List<double> x) {
  final s = [...x]..sort();
  final n = s.length;
  if (n == 0) return double.nan;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// Orari abituali (minuti dalla mezzanotte) di [times] negli ultimi
/// [days] giorni prima di [now]: gruppi di orari larghi al massimo 90
/// minuti presenti in almeno [freq] dei giorni osservati.
List<int> habitualSlots(
  List<DateTime> times,
  DateTime now, {
  int days = 14,
  double freq = 0.35,
}) {
  final from = now.subtract(Duration(days: days));
  final recent = [
    for (final t in times)
      if (t.isAfter(from) && !t.isAfter(now)) t,
  ];
  if (recent.isEmpty) return const [];
  final dayCount = math.max(
    1,
    math.min(days, now.difference(recent.first).inHours / 24).ceil(),
  );
  final mins = recent.map(_mod).toList()..sort();
  final groups = <List<int>>[];
  for (final m in mins) {
    if (groups.isNotEmpty && m - groups.last.first <= 90) {
      groups.last.add(m);
    } else {
      groups.add([m]);
    }
  }
  final out = <int>[];
  for (final g in groups) {
    if (g.length >= freq * dayCount && g.length >= 2) {
      out.add(_median(g.map((e) => e.toDouble()).toList()).round());
    }
  }
  return out;
}

int? _nearestSlot(List<int> slots, int m, {int tol = 90}) {
  int? best;
  var bd = tol + 1;
  for (final s in slots) {
    var d = (s - m).abs();
    if (d > 720) d = 1440 - d;
    if (d < bd) {
      bd = d;
      best = s;
    }
  }
  return best;
}

/// Previsione «ad ancore» della prossima cacca a [now] (≤ 30 ore).
/// [logs] contiene solo registrazioni fino a [now] (non si controlla qui).
({DateTime at, List<PoopAnchor> anchors, PoopAnchor? main}) anchorForecast(
  Dog dog,
  List<LogEntry> logs,
  DateTime now, {
  PoopModelParams p = const PoopModelParams(),
}) {
  final poops = PottyPredictor.outings(
    logs,
    type: LogType.cacca,
    clusterMinutes: Need.cacca.clusterMinutes,
  ).map((o) => o.time).where((t) => !t.isAfter(now)).toList();
  final last = poops.isEmpty ? now : poops.last;
  final meals = [
    for (final l in logs)
      if (l.type == LogType.pasto && !l.time.isAfter(now)) l.time,
  ]..sort();
  final outs = PottyPredictor.outings(
    logs,
    type: LogType.pipi,
    clusterMinutes: Need.pipi.clusterMinutes,
  ).map((o) => o.time).where((t) => !t.isAfter(now)).toList();

  final age = dog.ageInMonths(now);
  final puppy = age < 6;
  final prior = BioParams.forNeed(Need.cacca, dog, now);
  // Intervallo tipico da sveglio tra due cacche (mediana), per la prontezza.
  final gaps = <double>[];
  for (var k = 1; k < poops.length; k++) {
    if (poops[k].isBefore(now.subtract(Duration(days: p.historyDays)))) {
      continue;
    }
    final g = poops[k].difference(poops[k - 1]).inMinutes.toDouble();
    if (g < 30 * 60) gaps.add(g);
  }
  final typical = gaps.length >= 4 ? _median(gaps) : prior.median;
  final ready = p.readyFrac * typical;

  final mealSlots = habitualSlots(
    meals,
    now,
    days: p.slotDays,
    freq: p.slotFreq,
  );
  final outSlots = habitualSlots(outs, now, days: p.slotDays, freq: p.slotFreq);

  // Valori tipici senza storia [STIMA, 05 §P8]: pasto, risposta precoce con
  // picco a 30 minuti (cucciolo 20); passeggiata nei primi 10 minuti.
  final p0Meal = puppy ? 0.45 : 0.3;
  final p0Out = puppy ? 0.35 : 0.25;
  final lag0Meal = puppy ? 25.0 : 40.0;
  const lag0Out = 8.0;

  // Apprendimento per orario abituale: occasioni passate «pronte» (tempo
  // dall'ultima cacca ≥ ready) e cacca entro la finestra.
  final histFrom = now.subtract(Duration(days: p.historyDays));
  DateTime? lastPoopBefore(DateTime t) {
    DateTime? r;
    for (final q in poops) {
      if (q.isBefore(t)) {
        r = q;
      } else {
        break;
      }
    }
    return r;
  }

  DateTime? firstPoopIn(DateTime a, DateTime b) {
    for (final q in poops) {
      if (q.isAfter(a) && !q.isAfter(b)) return q;
      if (q.isAfter(b)) break;
    }
    return null;
  }

  ({double prob, double lag}) learn(
    List<DateTime> occ,
    List<int> slots,
    int slot,
    (int, int) win,
    double p0,
    double lag0,
  ) {
    var hits = 0, n = 0;
    final lags = <double>[];
    for (final o in occ) {
      if (o.isBefore(histFrom)) continue;
      final end = o.add(Duration(minutes: win.$2));
      if (end.isAfter(now)) continue; // esito non ancora noto
      if (_nearestSlot(slots, _mod(o)) != slot) continue;
      final lp = lastPoopBefore(o.add(Duration(minutes: win.$1)));
      if (lp != null && o.difference(lp).inMinutes < ready) continue;
      n++;
      final q = firstPoopIn(o.add(Duration(minutes: win.$1)), end);
      if (q != null) {
        hits++;
        lags.add(q.difference(o).inMinutes.toDouble());
      }
    }
    final prob = (hits + p.pseudo * p0) / (n + p.pseudo);
    final lag = lags.length >= 3 ? _median(lags) : lag0;
    return (prob: prob.clamp(0.02, 0.95), lag: lag);
  }

  final learned = <(PoopAnchorKind, int), ({double prob, double lag})>{};
  for (final s in mealSlots) {
    learned[(PoopAnchorKind.pasto, s)] = learn(
      meals,
      mealSlots,
      s,
      p.mealWindow,
      p0Meal,
      lag0Meal,
    );
  }
  for (final s in outSlots) {
    learned[(PoopAnchorKind.uscita, s)] = learn(
      outs,
      outSlots,
      s,
      p.outWindow,
      p0Out,
      lag0Out,
    );
  }

  // Ancore future: per i prossimi 30 orari ogni orario abituale; se un pasto
  // dello stesso orario è già stato segnato oggi, vale l'orario vero.
  final anchors = <PoopAnchor>[];
  final horizon = now.add(const Duration(hours: 30));
  final d0 = DateTime(now.year, now.month, now.day);
  for (var d = -1; d <= 2; d++) {
    final day = DateTime(d0.year, d0.month, d0.day + d);
    void add(PoopAnchorKind kind, int slot) {
      var at = day.add(Duration(minutes: slot));
      if (kind == PoopAnchorKind.pasto) {
        for (final m in meals) {
          if ((m.difference(at).inMinutes).abs() <= 90) at = m;
        }
      }
      final l = learned[(kind, slot)]!;
      final pred = at.add(Duration(minutes: l.lag.round()));
      if (!pred.isAfter(now) || pred.isAfter(horizon)) return;
      if (!at.isAfter(last)) return; // ancora già «usata» dall'ultima cacca
      // Niente filtro del sonno: l'orario abituale è osservato, quindi il cane
      // a quell'ora è sveglio anche se il profilo dice altro.
      var prob = l.prob;
      // Colon non ancora pronto: probabilità ridotta in proporzione.
      final since = pred.difference(last).inMinutes;
      if (poops.isNotEmpty && since < ready) prob *= (since / ready) * 0.5;
      anchors.add(PoopAnchor(kind, at, slot, prob, pred));
    }

    for (final s in mealSlots) {
      add(PoopAnchorKind.pasto, s);
    }
    for (final s in outSlots) {
      add(PoopAnchorKind.uscita, s);
    }
  }
  anchors.sort((a, b) => a.predicted.compareTo(b.predicted));

  // Cacca «spontanea» (stimolo forte senza un'occasione abituale): curva di
  // sopravvivenza di Kaplan-Meier del tempo da sveglio dall'ultima cacca,
  // con le cacche arrivate a un'occasione abituale come dati censurati.
  int awake(DateTime a, DateTime b) {
    var n = 0;
    for (var t = a; t.isBefore(b); t = t.add(const Duration(minutes: 15))) {
      if (!PottyPredictor.inSleepWindow(dog, t)) n += 15;
    }
    return n;
  }

  bool anchored(DateTime q) {
    for (final m in meals) {
      final d = q.difference(m).inMinutes;
      if (d >= p.mealWindow.$1 &&
          d <= p.mealWindow.$2 &&
          _nearestSlot(mealSlots, _mod(m), tol: 45) != null) {
        return true;
      }
    }
    for (final o in outs) {
      final d = q.difference(o).inMinutes;
      if (d >= p.outWindow.$1 &&
          d <= p.outWindow.$2 &&
          _nearestSlot(outSlots, _mod(o), tol: 45) != null) {
        return true;
      }
    }
    return false;
  }

  final durs = <(int, bool)>[];
  for (var k = 1; k < poops.length; k++) {
    if (poops[k].isBefore(histFrom)) continue;
    final g = poops[k].difference(poops[k - 1]);
    if (g.inHours >= 30) continue;
    durs.add((awake(poops[k - 1], poops[k]), !anchored(poops[k])));
  }
  durs.sort((a, b) => a.$1.compareTo(b.$1));
  double sSpont(int d) {
    if (durs.length < 6) return 1.0;
    var s = 1.0, atRisk = durs.length;
    for (final (x, ev) in durs) {
      if (x > d) break;
      if (ev) s *= 1 - 1 / atRisk;
      atRisk--;
    }
    return math.max(s, 0.02);
  }

  final s0 = sSpont(poops.isEmpty ? 0 : awake(last, now));
  var ai = 0;
  var sAnchor = 1.0;
  var awakeSince = poops.isEmpty ? 0 : awake(last, now);
  for (
    var t = now.add(const Duration(minutes: 15));
    !t.isAfter(horizon);
    t = t.add(const Duration(minutes: 15))
  ) {
    if (!PottyPredictor.inSleepWindow(dog, t)) awakeSince += 15;
    PoopAnchor? hit;
    while (ai < anchors.length && !anchors[ai].predicted.isAfter(t)) {
      sAnchor *= 1 - anchors[ai].prob;
      hit = anchors[ai];
      ai++;
    }
    final s = sAnchor * sSpont(awakeSince) / s0;
    if (s <= 0.5) {
      final at = hit?.predicted ?? t;
      return (at: at, anchors: anchors, main: hit);
    }
  }
  // Nessuna occasione basta: intervallo tipico dall'ultima cacca, al
  // risveglio se cade nel sonno.
  var at = last.add(Duration(minutes: typical.round()));
  if (!at.isAfter(now)) at = now.add(const Duration(minutes: 30));
  if (PottyPredictor.inSleepWindow(dog, at)) {
    at = PottyPredictor.nextWake(dog, at).add(const Duration(minutes: 30));
  }
  return (at: at, anchors: anchors, main: null);
}

double _q(List<double> s, double q) {
  if (s.length == 1) return s.first;
  final pos = q * (s.length - 1);
  final lo = pos.floor(), hi = pos.ceil();
  return s[lo] + (s[hi] - s[lo]) * (pos - lo);
}

/// Candidati alla prossima cacca dopo l'ultima di [logs] (origine = [now]).
({DateTime m, DateTime h, DateTime w, DateTime t, DateTime at, DateTime last})?
poopCandidates(
  Dog dog,
  List<LogEntry> logs,
  DateTime now, {
  PoopModelParams p = const PoopModelParams(),
}) {
  final poops = PottyPredictor.outings(
    logs,
    type: LogType.cacca,
    clusterMinutes: Need.cacca.clusterMinutes,
  ).map((o) => o.time).where((t) => !t.isAfter(now)).toList();
  if (poops.isEmpty) return null;
  final m = anchorForecast(dog, logs, now, p: p).at;
  final refs = referenceForecasts(
    dog,
    poops,
    Need.cacca.clusterMinutes,
    BioParams.forNeed(Need.cacca, dog, now).median,
  );
  final t = refs.timer;
  // «Stesso orario» e «stesso giorno» per la cacca: lo scarto minimo è 0,4
  // volte l'intervallo medio di TUTTE le cacche (non solo quelle sotto le
  // 10 ore, come per la pipì), per non prendere come «prossima» la seconda
  // cacca della stessa passeggiata.
  final gaps = <double>[];
  for (var k = 1; k < poops.length; k++) {
    final g = poops[k].difference(poops[k - 1]).inMinutes.toDouble();
    if (g < 30 * 60) gaps.add(g);
  }
  final mean = gaps.isEmpty
      ? BioParams.forNeed(Need.cacca, dog, now).median
      : gaps.reduce((a, b) => a + b) / gaps.length;
  final f = poops.first;
  final firstDay = DateTime(f.year, f.month, f.day);
  final cl = Need.cacca.clusterMinutes;
  final h =
      sameTimeForecast(
        poops,
        poops.last,
        cl,
        const [1, 2, 3, 4, 5, 6, 7],
        firstDay,
        minOffset: 0.4 * mean,
      ) ??
      m;
  final w =
      sameTimeForecast(
        poops,
        poops.last,
        cl,
        const [7, 14, 21],
        firstDay,
        minOffset: 0.4 * mean,
      ) ??
      h;
  // v3.1 (ricerca/analisi/risultati/cacca_regola_congelata.md, correzione
  // dichiarata dopo la verifica): mediana di ancora, «stesso orario» e timer.
  // «Stesso giorno della settimana» è il candidato peggiore su tutti i banchi
  // e resta solo come riferimento. (Regola congelata: mediana di M, H, W, T.)
  final c = [m, h, t]..sort();
  var at = c[1];
  // Primi 3 giorni: «stesso orario» non ha storia, vale l'ancora.
  if (now.difference(poops.first).inDays < 3) at = m;
  if (at.isBefore(now)) at = now;
  return (m: m, h: h, w: w, t: t, at: at, last: poops.last);
}

/// Previsione completa della cacca a [now], con finestre calibrate sugli
/// errori passati del cane (previsioni rifatte 1 minuto dopo ciascuna
/// cacca passata, con i soli dati di allora).
PoopForecast? poopForecast(
  Dog dog,
  List<LogEntry> logs,
  DateTime now, {
  PoopModelParams p = const PoopModelParams(),
  int nResidual = 30,
}) {
  final visible = [
    for (final l in logs)
      if (!l.time.isAfter(now)) l,
  ]..sort((a, b) => a.time.compareTo(b.time));
  final cur = poopCandidates(dog, visible, now, p: p);
  if (cur == null) return null;
  final poops = PottyPredictor.outings(
    visible,
    type: LogType.cacca,
    clusterMinutes: Need.cacca.clusterMinutes,
  ).map((o) => o.time).toList();
  final res = <double>[];
  for (var i = poops.length - 1; i >= 1 && res.length < nResidual; i--) {
    final origin = poops[i - 1].add(const Duration(minutes: 1));
    if (now.difference(origin) > const Duration(days: 21)) break;
    final upto = [
      for (final l in visible)
        if (!l.time.isAfter(origin)) l,
    ];
    final c = poopCandidates(dog, upto, origin, p: p);
    if (c == null) continue;
    res.add(poops[i].difference(c.at).inMinutes.toDouble());
  }
  res.sort();
  final at = cur.at;
  DateTime sh(double m) => at.add(Duration(minutes: m.round()));
  DateTime lo50, hi50, lo80, hi80;
  if (res.length >= 8) {
    lo80 = sh(_q(res, 0.1));
    hi80 = sh(_q(res, 0.9));
    lo50 = sh(_q(res, 0.25));
    hi50 = sh(_q(res, 0.75));
  } else {
    lo80 = at.subtract(const Duration(hours: 3));
    hi80 = at.add(const Duration(hours: 4));
    lo50 = at.subtract(const Duration(hours: 1));
    hi50 = at.add(const Duration(hours: 2));
  }
  if (lo80.isBefore(now)) lo80 = now;
  if (lo50.isBefore(now)) lo50 = now;
  if (hi50.difference(lo50).inMinutes < 30) {
    hi50 = lo50.add(const Duration(minutes: 30));
  }
  if (hi80.isBefore(hi50)) hi80 = hi50;
  final af = anchorForecast(dog, visible, now, p: p);
  return PoopForecast(
    last: cur.last,
    expectedAt: at,
    anchorAt: cur.m,
    sameTime: cur.h,
    sameWeekday: cur.w,
    anchors: af.anchors,
    lo50: lo50,
    hi50: hi50,
    lo80: lo80,
    hi80: hi80,
    nResiduals: res.length >= 8 ? res.length : 0,
    mainAnchor: af.main,
  );
}
