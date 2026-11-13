// Ciclo v3 (ricerca/28 §1 e §3): banco «a ciclo chiuso» per il cane in
// appartamento senza giardino. Qui le uscite non sono date: le decide la
// strategia in prova (orari fissi, previsione v2, piano di uscite), con i
// soli dati registrati fino a quel momento, e il cane fa la pipì solo fuori
// o in casa (incidente). Il processo del cane (vescica, colon, pasti, acqua)
// è quello di banco.dart; le aggiunte sono IPOTESI dichiarate:
//   • padroni: tempo pieno fuori casa 8:30-17:45 nei feriali, part-time
//     8:30-13:30, a casa (un terzo ciascuno); nel fine settimana a casa;
//   • tenuta: incidente quando la vescica arriva a 2,5 × il volume normale
//     (2,8 × nel sonno); cacca in casa 10 ore dopo che il colon è pronto;
//   • segnali: quando la vescica è oltre l'80% dello stimolo il cane annusa,
//     gira o è irrequieto (0,05 al minuto); oltre lo stimolo va alla porta o
//     guaisce (0,15 al minuto); prima della cacca gira e annusa (0,08 al
//     minuto); segnali «falsi» 0,4 al giorno;
//   • il padrone a casa e sveglio nota un segnale esplicito 8 volte su 10 e
//     uno lieve 5 su 10. Un segnale esplicito notato porta SEMPRE fuori il
//     cane, con o senza app (2-12 minuti). Con la funzione «segnali» il
//     padrone segna 7 segnali notati su 10 e l'app dice «Esci adesso»: esce
//     anche per i segnali lievi (2-8 minuti);
//   • un'uscita dura 12 minuti; tra due uscite decise da una strategia
//     passano almeno 60 minuti.
part of 'banco.dart';

int planDecideCalls = 0, planDecideMs = 0;

enum OwnerKind { tempoPieno, partTime, casa }

class PlanArm {
  const PlanArm(this.name, this.kind, {this.n = 4, this.signals = false});
  final String name;

  /// 'fisso', 'v2', 'piano'.
  final String kind;
  final int n;
  final bool signals;
}

class PlanDogResult {
  PlanDogResult(this.id, this.group, this.owner);
  final String id, group;
  final OwnerKind owner;
  int accPee = 0, accPoop = 0, outings = 0, days = 0;
  double predicted = 0; // incidenti attesi dal piano (solo «piano»)
  int sigLogged = 0, sigFollowed = 0;
  final sigErrV2 = <double>[], sigErrSig = <double>[];
  int get acc => accPee + accPoop;
}

OwnerSchedule ownerScheduleFor(OwnerKind k, DogSpec s) {
  final wd = (s.wakeH * 60).round(), bd = (s.bedH * 60).round();
  return OwnerSchedule(
    awayWeekdays: switch (k) {
      OwnerKind.tempoPieno => const [(510, 1065)],
      OwnerKind.partTime => const [(510, 810)],
      OwnerKind.casa => const [],
    },
    wakeWeekday: wd,
    bedWeekday: bd,
    wakeWeekend: wd + 90,
    bedWeekend: bd + 30,
  );
}

/// Orari fissi «standard» per [n] uscite: mattino, sera prima di dormire,
/// rientro, pranzo, poi metà mattina e pomeriggio, se il padrone è a casa.
List<DateTime> standardTimes(
  Dog dog,
  OwnerSchedule o,
  DateTime day,
  int n,
) {
  final w = o.wakeOn(dog, day), b = o.bedOn(dog, day);
  final away = o.awayOn(day);
  final back = away.isEmpty ? 18 * 60 : away.map((e) => e.$2).reduce(math.max);
  final cands = [
    w + 10,
    b - 30,
    math.max(18 * 60, back + 15),
    13 * 60,
    10 * 60 + 30,
    15 * 60 + 30,
    21 * 60,
    8 * 60,
  ];
  final out = <int>[];
  for (final c in cands) {
    if (out.length >= n) break;
    final t = day.add(Duration(minutes: c));
    if (!o.available(dog, t)) continue;
    if (out.any((x) => (x - c).abs() < 90)) continue;
    out.add(c);
  }
  out.sort();
  return [for (final c in out) day.add(Duration(minutes: c))];
}

/// Simula un cane con la strategia [arm]. [evalFrom]: giorno da cui contare.
PlanDogResult simulatePlan(
  DogSpec s,
  int index,
  PlanArm arm, {
  int seed = 0,
  int evalFrom = 7,
}) {
  const sc = Scenario(
    'appartamento',
    missing: true,
    jitter: false,
    sched: SchedMode.none,
    weekend: true,
    routineChange: true,
    polyuria: PuMode.own,
  );
  // Padroni mescolati anche quando si prende un cane su tre.
  final owner = OwnerKind.values[(index + index ~/ 3 + seed) % 3];
  final res = PlanDogResult(s.id, s.group, owner);
  // Stessi pasti, bevute e orari in tutte le strategie (numeri casuali
  // comuni): r1 per il piano della giornata, r2 per i minuti.
  final r1 = math.Random(5000 + index + seed * 7919);
  final r2 = math.Random(9000 + index + seed * 7919);
  final puppy = s.ageMonths < 6;
  final senior =
      s.group == 'anziano' || s.ageMonths >= seniorStartMonths(s.weightKg);
  final kg = s.weightKg;
  final sizeScale = math.pow(kg / 15, -0.25).toDouble();
  final vFun = puppy ? (s.ageMonths < 4 ? 3.5 : 4.5) : (senior ? 6.0 : 8.0);
  final poopMedian = puppy ? 300.0 : (senior ? 780.0 : 660.0);
  final puFrom = s.puOnset
      ? simStart.add(Duration(days: 12 + r1.nextInt(7)))
      : null;
  final missRate = 0.10 + r1.nextDouble() * 0.30;
  final dog = Dog(
    id: s.id,
    name: s.id,
    birthDate: simStart.subtract(Duration(days: (s.ageMonths * 30.44).round())),
    sex: s.sex,
    neutered: r1.nextBool(),
    weightKg: kg,
    wakeHour: s.wakeH.round(),
    sleepStartHour: s.bedH.round() % 24,
    conditions: s.chronic ? 'diabete' : '',
  );
  final os = ownerScheduleFor(owner, s);

  final wakes = <DateTime>[], beds = <DateTime>[], meals = <DateTime>[];
  final drinks = <(DateTime, double)>[];
  DateTime at(DateTime day, double h) =>
      DateTime(day.year, day.month, day.day)
          .add(Duration(minutes: (h * 60).round()));
  for (var d = 0; d <= simDays; d++) {
    final day = simStart.add(Duration(days: d));
    final we = sc.weekend && day.weekday >= 6;
    final changed = sc.routineChange && d >= 14;
    final wake =
        s.wakeH + (we ? 1.5 : 0) + (changed && !we ? -1.0 : 0) + _g(r1) * 0.4;
    final bed = s.bedH + (we ? 0.5 : 0) + _g(r1) * 0.3;
    wakes.add(at(day, wake));
    beds.add(at(day, bed));
    final shift = changed ? 1.0 : 0.0;
    final dayMeals = <double>[
      wake + 0.75,
      if (puppy) 13.0 + (we ? 0.5 : 0),
      19.0 + (we ? 0.5 : 0) + shift * 0.7,
    ];
    for (final m in dayMeals) {
      meals.add(at(day, m + _g(r1) * 0.4));
    }
    final waterScale = puppy ? 1.4 : 1.0;
    for (final m in meals.skip(meals.length - dayMeals.length)) {
      drinks.add((m.add(Duration(minutes: 5 + r1.nextInt(11))), 6.0 * waterScale));
    }
    for (var k = 0; k < 2; k++) {
      drinks.add((
        at(day, wake + 1 + r1.nextDouble() * (bed - wake - 2)),
        4.0 * waterScale,
      ));
    }
  }
  meals.sort();
  drinks.sort((a, b) => a.$1.compareTo(b.$1));

  bool ownerHome(DateTime t) {
    if (t.weekday >= 6) return true;
    final m = t.hour * 60 + t.minute;
    for (final (a, b) in os.awayWeekdays) {
      if (m >= a && m < b) return false;
    }
    return true;
  }

  // Tabelle al minuto, uguali in tutte le strategie (più veloce).
  const total = simDays * 24 * 60;
  final asleepArr = List<bool>.filled(total, false);
  final homeArr = List<bool>.filled(total, true);
  final mealArr = List<bool>.filled(total, false);
  final rateArr = List<double>.filled(total, 0);
  {
    var wi = 0;
    for (var i = 0; i < total; i++) {
      final t = simStart.add(Duration(minutes: i));
      while (wi < wakes.length && !t.isBefore(beds[wi])) {
        wi++;
      }
      // Sveglio tra wakes[wi] e beds[wi].
      asleepArr[i] = wi >= wakes.length || t.isBefore(wakes[wi]);
      homeArr[i] = ownerHome(t);
      final pu = puFrom != null && !t.isBefore(puFrom) ? 2.2 : 1.0;
      final chronicPu = s.chronic ? 2.0 : 1.0;
      rateArr[i] =
          (asleepArr[i] ? 0.35 : 0.5) * sizeScale * pu * chronicPu / 60;
    }
    for (final m in meals) {
      final i0 = m.difference(simStart).inMinutes;
      for (var i = i0 + 25; i <= i0 + 60; i++) {
        if (i >= 0 && i < total) mealArr[i] = true;
      }
    }
    for (final (drunkAt, ml0) in drinks) {
      final i0 = drunkAt.difference(simStart).inMinutes;
      for (var dt = 0; dt <= 240; dt++) {
        final i = i0 + dt;
        if (i < 0 || i >= total) continue;
        final t = simStart.add(Duration(minutes: i));
        final pu = puFrom != null && !t.isBefore(puFrom) ? 2.2 : 1.0;
        final ml = ml0 * pu * (s.chronic ? 2.0 : 1.0);
        final k = math.exp(-0.5 * math.pow((dt - 65) / 35, 2)) / (35 * 2.5066);
        rateArr[i] += 0.7 * ml * sizeScale * k;
      }
    }
  }

  final logged = <LogEntry>[];
  var id = 0;
  void log(LogType type, DateTime t, {bool indoor = false, Set<Sign>? signs}) =>
      logged.add(LogEntry(
        id: '${id++}',
        dogId: s.id,
        type: type,
        time: t,
        indoor: indoor,
        signs: signs ?? const {},
      ));

  final evalStart = simStart.add(Duration(days: evalFrom));
  bool counting(DateTime t) => !t.isBefore(evalStart);

  // Stato.
  var v = 0.5 * vFun;
  var urge = vFun * (0.85 + r2.nextDouble() * 0.4);
  var readyAt = simStart.add(
    Duration(minutes: (poopMedian * 0.55 * math.exp(_g(r2) * 0.6)).round()),
  );
  DateTime? outEnd, outStart, pendingOut;
  var peed = false, pooped = false;
  var mi = 0;
  DateTime? lastPolicyOut;
  // Decisione della strategia: prossimo orario.
  DateTime? next;
  var plan = <DateTime>[];
  var needReplan = true;
  var lastDay = -1;
  DateTime? lastTruePee;
  final end = simStart.add(const Duration(days: simDays));

  DateTime lastLoggedPee(DateTime now) {
    DateTime? r;
    for (final l in logged) {
      if (l.type == LogType.pipi && !l.time.isAfter(now)) r = l.time;
    }
    return r ?? wakes[0];
  }

  DateTime? decideImpl(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    switch (arm.kind) {
      case 'fisso':
        final ts = standardTimes(dog, os, day, arm.n);
        for (final t in ts) {
          if (!t.isBefore(now.subtract(const Duration(minutes: 1)))) return t;
        }
        return null;
      case 'v2':
        final vis = [for (final l in logged) if (!l.time.isAfter(now)) l];
        if (!vis.any((l) => l.type == LogType.pipi)) {
          return now.add(const Duration(minutes: 1));
        }
        final f = EliminationModel()
            .fit(dog, Need.pipi, vis, const [], now, shadow: false)
            .forecast(now, withAccuracy: false);
        return f.v2?.alertAt ?? f.recommendedAt;
      case 'piano':
        if (needReplan) {
          final vis = [for (final l in logged) if (!l.time.isAfter(now)) l];
          final hm = HoldModel.fit(dog, vis, now, owner: os);
          final wake = day.add(Duration(minutes: os.wakeOn(dog, day)));
          final done = PottyPredictor.outings(vis, type: LogType.pipi)
              .where((o) => !o.indoor && !o.time.isBefore(wake))
              .length;
          final pd = planDay(hm, os, now, arm.n,
              lastPee: lastLoggedPee(now), done: done);
          plan = pd.times;
          needReplan = false;
        }
        for (final t in plan) {
          if (!t.isBefore(now.subtract(const Duration(minutes: 1)))) return t;
        }
        return null;
    }
    return null;
  }

  DateTime? decide(DateTime now) {
    planDecideCalls++;
    final sw = Stopwatch()..start();
    final r = decideImpl(now);
    planDecideMs += sw.elapsedMilliseconds;
    return r;
  }

  // Per la valutazione dei segnali (orario del segnale, previsione v2).
  final openSignals = <(DateTime, DateTime?)>[];

  var mIdx = -1;
  for (var t = simStart; t.isBefore(end); t = t.add(const Duration(minutes: 1))) {
    mIdx++;
    final asleep = asleepArr[mIdx];
    final home = homeArr[mIdx];
    final avail = home && !asleep;
    final dIdx = t.difference(simStart).inDays;
    if (dIdx != lastDay && !asleep && t.hour >= 4) {
      lastDay = dIdx;
      needReplan = true;
      next = decide(t);
      if (counting(t)) res.days++;
      if (arm.kind == 'piano' && counting(t)) {
        final vis = [for (final l in logged) if (!l.time.isAfter(t)) l];
        final hm = HoldModel.fit(dog, vis, t, owner: os);
        final pd = planDay(hm, os, t, arm.n, lastPee: lastLoggedPee(t));
        res.predicted += pd.expectedAccidents;
        plan = pd.times;
        needReplan = false;
        next = decide(t);
      }
    }
    while (mi < meals.length && !meals[mi].isAfter(t)) {
      if (r2.nextDouble() < 0.85) log(LogType.pasto, meals[mi]);
      mi++;
    }
    final rate = rateArr[mIdx];
    v += rate;

    final outside = outEnd != null && t.isBefore(outEnd);
    if (!outside && outEnd != null) {
      outEnd = null;
      // Dopo un'uscita la strategia decide di nuovo.
      if (arm.kind != 'fisso') next = decide(t);
    }

    if (outside) {
      final into = t.difference(outStart!).inMinutes;
      if (!peed && into >= 1 + r2.nextInt(3) && v >= 0.25 * vFun) {
        peed = true;
        v = 0.2;
        urge = vFun * (0.85 + r2.nextDouble() * 0.4);
        lastTruePee = t;
        if (r2.nextDouble() >= missRate) log(LogType.pipi, t);
      }
      final strong = t.difference(readyAt).inMinutes > 240;
      if (!pooped &&
          !t.isBefore(readyAt) &&
          into >= 3 &&
          r2.nextDouble() < (strong ? 0.3 : 0.12)) {
        pooped = true;
        readyAt = t.add(Duration(
            minutes: (poopMedian * 0.55 * math.exp(_g(r2) * 0.6)).round()));
        if (r2.nextDouble() >= missRate * 0.6) log(LogType.cacca, t);
      }
      continue;
    }

    // Segnali del cane.
    Sign? sig;
    var explicit = false;
    if (!asleep) {
      if (v >= urge && r2.nextDouble() < 0.15) {
        sig = r2.nextBool() ? Sign.allaPorta : Sign.guaisce;
        explicit = true;
      } else if (v >= 0.8 * urge && r2.nextDouble() < 0.05) {
        sig = [Sign.annusaTerra, Sign.giraSuSe, Sign.irrequieto][r2.nextInt(3)];
      } else if (!t.isBefore(readyAt)) {
        final recentMeal = mealArr[mIdx];
        final strong = t.difference(readyAt).inMinutes > 240;
        if ((recentMeal || strong) && r2.nextDouble() < 0.08) {
          sig = r2.nextBool() ? Sign.giraSuSe : Sign.annusaTerra;
        }
      }
      if (sig == null && r2.nextDouble() < 0.4 / (16 * 60)) {
        sig = [Sign.annusaTerra, Sign.giraSuSe, Sign.irrequieto][r2.nextInt(3)];
      }
    } else if (puppy && v >= 2.2 * vFun && r2.nextDouble() < 0.15) {
      sig = Sign.guaisce;
      explicit = true;
    }
    if (sig != null) {
      final notice = (avail && r2.nextDouble() < (explicit ? 0.8 : 0.5)) ||
          (asleep && home && explicit && puppy && r2.nextDouble() < 0.5);
      if (notice) {
        var logs = false;
        if (arm.signals && r2.nextDouble() < 0.7) {
          logs = true;
          log(LogType.segnale, t, signs: {sig});
          if (counting(t)) res.sigLogged++;
          openSignals.add((t, null));
        }
        if (explicit) {
          pendingOut ??= t.add(Duration(minutes: 2 + r2.nextInt(11)));
        } else if (logs) {
          final a = signalAlert(logged, t);
          if (a != null && a.goNow) {
            pendingOut ??= t.add(Duration(minutes: 2 + r2.nextInt(7)));
          }
        }
      }
    }

    // Incidenti.
    if (v >= (asleep ? 2.8 : 2.5) * vFun) {
      v = 0.2;
      urge = vFun * (0.85 + r2.nextDouble() * 0.4);
      lastTruePee = t;
      if (counting(t)) res.accPee++;
      if (r2.nextDouble() < 0.9) log(LogType.pipi, t, indoor: true);
      needReplan = true;
      if (arm.kind != 'fisso') next = decide(t);
    }
    if (!asleep && t.difference(readyAt).inMinutes > 600) {
      readyAt = t.add(Duration(
          minutes: (poopMedian * 0.55 * math.exp(_g(r2) * 0.6)).round()));
      if (counting(t)) res.accPoop++;
      if (r2.nextDouble() < 0.9) log(LogType.cacca, t, indoor: true);
    }

    // Inizio di un'uscita: chiesta dal cane o decisa dalla strategia.
    var go = false;
    if (pendingOut != null && !pendingOut.isAfter(t) && (avail || asleep && home)) {
      go = true;
      // Un'uscita non prevista dal piano: si rifà il piano.
      needReplan = true;
    }
    final due = next != null && !next.isAfter(t);
    final spaced = lastPolicyOut == null ||
        t.difference(lastPolicyOut).inMinutes >= 60;
    if (!go && due && avail && spaced) {
      go = true;
      lastPolicyOut = t;
    }
    if (go) {
      pendingOut = null;
      outStart = t;
      outEnd = t.add(const Duration(minutes: 12));
      peed = false;
      pooped = false;
      if (counting(t)) res.outings++;
      if (arm.kind == 'fisso' && due) {
        next = decide(t.add(const Duration(minutes: 13)));
      }
    } else if (due && !avail && arm.kind == 'fisso') {
      // Orario fisso caduto mentre il padrone non c'è: si salta.
      next = decide(t.add(const Duration(minutes: 1)));
    }
  }
  // Errori della previsione al momento del segnale (solo per la misura).
  for (final (st, _) in openSignals) {
    if (!counting(st)) continue;
    DateTime? nextPee;
    for (final l in logged) {
      if ((l.type == LogType.pipi || l.type == LogType.cacca) &&
          l.time.isAfter(st)) {
        nextPee = l.time;
        break;
      }
    }
    if (nextPee != null && nextPee.difference(st).inMinutes <= 30) {
      res.sigFollowed++;
    }
  }
  lastTruePee;
  return res;
}

/// Esegue le strategie su tutti i cani (o uno su [every]).
String runPlanBench(List<PlanArm> arms, {int every = 1, int seed = 0, int reps = 1000}) {
  final specs = population(seed);
  final b = StringBuffer('## Banco del piano di uscite (seme $seed, un cane su $every)\n\n'
      '| Strategia | Incidenti/settimana [IC] | Uscite/giorno [IC] | Incidenti pipì / cacca | Previsti dal piano/sett. | Segnali segnati, seguiti da un bisogno entro 30 min |\n|---|---|---|---|---|---|\n');
  final all = <String, List<PlanDogResult>>{};
  for (final arm in arms) {
    final rs = <PlanDogResult>[];
    for (var i = 0; i < specs.length; i += every) {
      rs.add(simulatePlan(specs[i], i, arm, seed: seed));
    }
    all[arm.name] = rs;
    double accW(List<PlanDogResult> x) =>
        x.fold(0.0, (a, e) => a + e.acc) / x.fold(0.0, (a, e) => a + e.days) * 7;
    double outD(List<PlanDogResult> x) =>
        x.fold(0.0, (a, e) => a + e.outings) / x.fold(0.0, (a, e) => a + e.days);
    final ra = _bootDogs(rs, accW, reps), ro = _bootDogs(rs, outD, reps);
    final days = rs.fold(0, (a, e) => a + e.days);
    final pee = rs.fold(0, (a, e) => a + e.accPee);
    final poo = rs.fold(0, (a, e) => a + e.accPoop);
    final pred = rs.fold(0.0, (a, e) => a + e.predicted) / days * 7;
    final sl = rs.fold(0, (a, e) => a + e.sigLogged);
    final sf = rs.fold(0, (a, e) => a + e.sigFollowed);
    b.writeln('| ${arm.name} | ${fmt(ra, dp: 2)} | ${fmt(ro, dp: 1)} | $pee / $poo | '
        '${arm.kind == 'piano' ? pred.toStringAsFixed(2) : '—'} | '
        '${sl == 0 ? '—' : '$sl, ${(sf / sl * 100).toStringAsFixed(0)}%'} |');
  }
  b.writeln('\nPer gruppo e padrone (incidenti/settimana, uscite/giorno):\n');
  b.writeln('| Strategia | ${[
    'cucciolo',
    'adulto',
    'anziano',
    'cronico',
    'poliuria',
    'tempoPieno',
    'partTime',
    'casa',
  ].join(' | ')} |');
  b.writeln('|---|---|---|---|---|---|---|---|---|');
  for (final e in all.entries) {
    String cell(bool Function(PlanDogResult) f) {
      final x = e.value.where(f).toList();
      if (x.isEmpty) return '—';
      final d = x.fold(0, (a, r) => a + r.days);
      final a = x.fold(0, (a, r) => a + r.acc) / d * 7;
      final o = x.fold(0, (a, r) => a + r.outings) / d;
      return '${a.toStringAsFixed(2)} / ${o.toStringAsFixed(1)}';
    }

    b.writeln('| ${e.key} | ${[
      for (final g in ['cucciolo', 'adulto', 'anziano', 'cronico', 'poliuria'])
        cell((r) => r.group == g),
      for (final o in OwnerKind.values) cell((r) => r.owner == o),
    ].join(' | ')} |');
  }
  return b.toString();
}

({double est, double lo, double hi}) _bootDogs(
  List<PlanDogResult> rs,
  double Function(List<PlanDogResult>) stat,
  int reps,
) {
  final r = math.Random(17);
  final vals = <double>[];
  for (var k = 0; k < reps; k++) {
    final s = [for (var i = 0; i < rs.length; i++) rs[r.nextInt(rs.length)]];
    vals.add(stat(s));
  }
  vals.sort();
  return (
    est: stat(rs),
    lo: vals[(reps * 0.025).floor()],
    hi: vals[(reps * 0.975).floor()],
  );
}
