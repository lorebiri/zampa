// Ciclo 3 (ricerca/27): banco «a candidati». Per ogni origine onesta salva
// tutte le previsioni disponibili in quel momento (previsione di base,
// modello in ombra, timer, «stesso orario», «stesso giorno della
// settimana») e l'esito, così che combinazioni, calibrazioni e regole si
// possano provare in pochi secondi senza riaddestrare il modello.
//
// Origini, in ordine di tempo, con la stessa storia R6 del banco v2:
// - 'ev': 1 minuto dopo ogni pipì registrata (l'origine del collaudo);
// - 'gr': orari fissi ogni 4 ore da sveglio (probabilità nella prossima ora);
// - 'tr': 1 minuto dopo ogni innesco registrato (acqua, pasto, risveglio,
//   gioco), se dopo l'ultima pipì: la previsione «aggiornata» della strada 2.
// T1: nessuna previsione vede un log successivo alla sua origine.
part of 'banco.dart';

int _ms(DateTime t) => t.millisecondsSinceEpoch;

/// Riferimenti per la prossima pipì dopo [prev] con le sole uscite [past].
({DateTime timer, DateTime habit, DateTime weekday}) _refs3(
  Truth tr,
  List<DateTime> past,
  DateTime prev,
  double cluster,
  double priorMedian,
) {
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
      ? priorMedian
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
  return (timer: timer, habit: habit, weekday: weekday);
}

/// Valuta un cane e restituisce i record grezzi ('ev', 'gr', 'tr').
List<Map<String, Object?>> dumpDog(
  Truth tr, {
  Need need = Need.pipi,
  bool grid = true,
  bool triggers = true,
  bool shadow = true,
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
  final history = <ShadowRecord>[];
  const trigTypes = {
    LogType.acqua: 'acqua',
    LogType.pasto: 'pasto',
    LogType.risveglio: 'risveglio',
    LogType.gioco: 'gioco',
  };
  // (origine, tipo, indice evento o -1, nome innesco)
  final origins = <(DateTime, String, int, String)>[];
  for (var i = 1; i < outs.length; i++) {
    if (outs[i].isBefore(evalFrom)) continue;
    origins.add((outs[i - 1].add(const Duration(minutes: 1)), 'ev', i, ''));
  }
  if (grid) {
    for (var d = evalFromDay; d < simDays; d++) {
      final day = simStart.add(Duration(days: d));
      for (var h = tr.dog.wakeHour + 2; h <= 21; h += 4) {
        origins.add((DateTime(day.year, day.month, day.day, h), 'gr', -1, ''));
      }
    }
  }
  if (triggers) {
    for (final l in tr.logged) {
      final name = trigTypes[l.type];
      if (name == null || l.time.isBefore(evalFrom)) continue;
      origins.add((l.time.add(const Duration(minutes: 1)), 'tr', -1, name));
    }
  }
  origins.sort((a, b) => a.$1.compareTo(b.$1));
  final out = <Map<String, Object?>>[];
  for (final (origin, kind, _, trig) in origins) {
    final visible = tr.logged.where((l) => !l.time.isAfter(origin)).toList();
    final past = outs.where((e) => !e.isAfter(origin)).toList();
    if (past.isEmpty) continue;
    final prev = past.last;
    // Esito: prossima pipì registrata dopo l'origine.
    final next = _nextAfter(outs, origin);
    if (next == null) continue;
    if (kind == 'tr' && next.difference(origin).inHours >= 24) continue;
    final prior = BioParams.forNeed(need, tr.dog, origin);
    final f = engine
        .fit(tr.dog, need, visible, const [], origin, shadow: shadow)
        .forecast(origin, withAccuracy: false, history: history);
    if (kind == 'ev' && f.shadow != null) history.add(f.shadow!.record);
    final refs = _refs3(tr, past, prev, cluster, prior.median);
    final trueNext =
        _nextAfter(trueOuts, origin.add(const Duration(minutes: 11))) ?? next;
    final s = f.shadow;
    final until = origin.add(const Duration(minutes: 60));
    var hit = 0, n = 0;
    if (kind == 'gr') {
      for (var k = 1; k <= 14; k++) {
        final o2 = origin.subtract(Duration(days: k));
        if (o2.isBefore(simStart)) continue;
        n++;
        final u2 = o2.add(const Duration(minutes: 60));
        if (outs.any((o) => o.isAfter(o2) && !o.isAfter(u2))) hit++;
      }
    }
    out.add({
      'k': kind,
      if (trig.isNotEmpty) 'trig': trig,
      'dog': tr.spec.id,
      'group': tr.spec.group,
      'scheduled': _isScheduled(tr),
      'weekend': next.weekday >= 6,
      'afterChange': !next.isBefore(changeAt),
      'puActive': tr.puFrom != null && !next.isBefore(tr.puFrom!),
      'puDays': tr.puFrom == null
          ? -1.0
          : next.difference(tr.puFrom!).inMinutes / 1440,
      'overnight': next.difference(prev).inHours >= 6 && next.day != prev.day,
      'wake': tr.dog.wakeHour,
      'sleep': tr.dog.sleepStartHour,
      'o': _ms(origin),
      'prev': _ms(prev),
      'act': _ms(next),
      'tru': _ms(trueNext),
      'y': next.isAfter(until) ? 0 : 1,
      'yt': trueOuts.any((o) => o.isAfter(origin) && !o.isAfter(until))
          ? 1
          : 0,
      if (kind == 'gr') 'pClim': (hit + 0.5) / (n + 1),
      'timer': _ms(refs.timer),
      'habit': _ms(refs.habit),
      'weekday': _ms(refs.weekday),
      'be': _ms(f.expectedAt),
      'bws': _ms(f.windowStart),
      'bwe': _ms(f.windowEnd),
      'brec': _ms(f.recommendedAt),
      'blat': f.latestAt == null ? null : _ms(f.latestAt!),
      'capOk': _capOk(tr.dog, f, prior.maxDay, origin),
      'pRaw': f.probNextHour,
      if (s != null) ...{
        'se': _ms(s.expectedAt),
        'sm': _ms(s.median),
        's10': _ms(s.q10),
        's25': _ms(s.q25),
        's75': _ms(s.q75),
        's90': _ms(s.q90),
        'r10': _ms(s.record.q10),
        'r50': _ms(s.record.median),
        'r90': _ms(s.record.q90),
        'pCal': s.probNextHour,
        'pPast': s.pastProb,
      },
      'nIntervals': f.measuredIntervals,
      'typ': f.typicalIntervalMin,
    });
  }
  // T1 è garantito dal filtro `visible` (nessun log dopo l'origine).
  return out;
}

/// Esegue [scenario] sui cani con indice ≡ [shard] (mod [of]) e salva in
/// `risultati/tmp/v3_SCENARIO_SHARD.json`.
void runDumpShard(
  String scenario,
  int shard,
  int of, {
  bool grid = true,
  bool triggers = true,
  bool shadow = true,
}) {
  final dir = Directory('${outDir()}/tmp')..createSync(recursive: true);
  final bench = buildBench(scenarios[scenario]!);
  final recs = <Map<String, Object?>>[];
  for (var i = shard; i < bench.length; i += of) {
    recs.addAll(
      dumpDog(bench[i], grid: grid, triggers: triggers, shadow: shadow),
    );
    // ignore: avoid_print
    print('v3 $scenario ${bench[i].spec.id}');
  }
  File('${dir.path}/v3_${scenario}_$shard.json').writeAsStringSync(
    jsonEncode(recs),
  );
}
