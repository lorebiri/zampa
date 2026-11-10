import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';
import 'package:zampa/models.dart';
import 'banco.dart';

/// Diagnosi: cosa prevede il modello per la cacca subito dopo la cacca
/// precedente (generatore del test attuale, seme 3)?
Truth _adult(DateTime start, int days, int seed) {
  final r = math.Random(seed);
  final dog = Dog(
    id: 'd',
    name: 'Test',
    birthDate: start.subtract(const Duration(days: 365 * 4)),
    sex: Sex.maschio,
    neutered: true,
    weightKg: 20,
    wakeHour: 7,
    sleepStartHour: 23,
  );
  final logs = <LogEntry>[];
  var id = 0;
  void log(LogType t, DateTime when, {double? ml}) => logs.add(
    LogEntry(id: '${id++}', dogId: 'd', type: t, time: when, amountMl: ml),
  );
  double g() => r.nextDouble() + r.nextDouble() + r.nextDouble() - 1.5;
  final allPees = <DateTime>[], allPoops = <DateTime>[];
  for (var d = 0; d < days; d++) {
    final day = start.add(Duration(days: d));
    DateTime at(double h) => DateTime(
      day.year,
      day.month,
      day.day,
    ).add(Duration(minutes: (h * 60).round()));
    final wake = at(7 + g() * 0.5);
    log(LogType.risveglio, wake);
    final pees = <DateTime>[wake.add(Duration(minutes: 10 + r.nextInt(6)))];
    final meals = [at(8 + g() * 0.3), at(19 + g() * 0.3)];
    for (final m in meals) {
      log(LogType.pasto, m);
      log(LogType.acqua, m.add(const Duration(minutes: 5)), ml: 250);
    }
    final bed = at(22.75);
    var t = pees.first;
    while (true) {
      var next = t.add(Duration(minutes: (220 + g() * 50).round()));
      for (final m in meals) {
        final trig = m.add(Duration(minutes: 25 + r.nextInt(10)));
        if (trig.isAfter(t.add(const Duration(minutes: 40))) &&
            trig.isBefore(next)) {
          next = trig;
        }
      }
      if (next.isAfter(bed)) break;
      pees.add(next);
      t = next;
    }
    pees.add(bed);
    for (final p in pees) {
      log(LogType.pipi, p);
    }
    allPees.addAll(pees);
    final c1 = meals[0].add(Duration(minutes: 30 + r.nextInt(15)));
    log(LogType.cacca, c1);
    allPoops.add(c1);
    if (r.nextDouble() < 0.67) {
      final c2 = meals[1].add(Duration(minutes: 35 + r.nextInt(15)));
      log(LogType.cacca, c2);
      allPoops.add(c2);
    }
  }
  logs.sort((a, b) => a.time.compareTo(b.time));
  final spec = DogSpec('d', 'adulto', 48, 20, Sex.maschio, false, 7, 23);
  return Truth(spec, dog, logs, allPees, allPoops, null);
}

void main() {
  test('diagnosi cacca', () {
    final start = DateTime(2026, 9, 1);
    final tr = _adult(start, 21, 3);
    final poops = tr.logged.where((l) => l.type == LogType.cacca).toList();
    final b = StringBuffer('## Diagnosi cacca (seme 3)\n');
    for (final p in poops.where((p) => p.time.isAfter(start.add(const Duration(days: 15)))).take(4)) {
      final origin = p.time.add(const Duration(minutes: 1));
      final vis = tr.logged.where((l) => !l.time.isAfter(origin)).toList();
      final fm = EliminationModel().fit(tr.dog, Need.cacca, vis, const [], origin);
      final f = fm.forecast(origin, withAccuracy: false);
      final next = poops.firstWhere((x) => x.time.isAfter(origin)).time;
      b.writeln('- origine $origin: prevista ${f.expectedAt}, finestra '
          '${f.windowStart}–${f.windowEnd}, vera $next; '
          'mediana appresa ${fm.prior.median.round()} min, intervallo tipico '
          '${f.typicalIntervalMin.round()} min, pasti abituali '
          '${fm.habitualMealMinutes(origin)}');
      final pts = f.curve.where((c) => c.$1.minute == 0 && c.$1.hour % 2 == 0);
      b.writeln('  curva: ${pts.map((c) => "${c.$1.hour}h ${(c.$2 * 100).round()}%").join(", ")}');
      b.writeln('  coeff: ${f.coefficients.map((c) => c.toStringAsFixed(2)).join(" ")}');
    }
    // ignore: avoid_print
    print(b);
    saveText('diagnosi_cacca', b.toString());
  }, timeout: Timeout.none);
}
