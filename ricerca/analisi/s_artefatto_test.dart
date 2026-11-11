import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/models.dart';
import 'banco.dart';

/// Il "3 minuti" della cacca in test/model_validation_test.dart è un
/// artefatto? Stesso generatore del test (copiato), 20 semi invece di 1,
/// due origini della previsione:
///  A) come nel test: 1 minuto dopo l'ultimo evento registrato di qualsiasi
///     tipo prima dell'evento vero (spesso pochi minuti prima);
///  B) prequenziale onesta: 1 minuto dopo l'evento precedente dello stesso
///     tipo (ciò che serve per un promemoria).
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
  test('artefatto della cacca', () {
    final start = DateTime(2026, 9, 1);
    final b = StringBuffer('## Artefatto: generatore del test attuale\n');
    for (final need in Need.values) {
      for (final leaky in [true, false]) {
        final all = <EventRec>[];
        final seed3 = <EventRec>[];
        final gapsBefore = <double>[];
        for (var seed = 1; seed <= 10; seed++) {
          final tr = _adult(start, 21, seed);
          final recs = evaluateEvents(
            tr,
            need,
            leakyOrigin: leaky,
            from: start.add(const Duration(days: 14)),
          );
          // rinomina il cane per il bootstrap per seme
          for (final e in recs) {
            all.add(
              EventRec(
                dog: 's$seed',
                group: e.group,
                scheduled: false,
                weekend: e.weekend,
                afterChange: false,
                puActive: false,
                overnight: e.overnight,
                errModel: e.errModel,
                errTimer: e.errTimer,
                errWeekday: e.errWeekday,
                errHabit: e.errHabit,
                errModelTrue: e.errModelTrue,
                in50: e.in50,
                in50tol: e.in50tol,
                in80: e.in80,
                width50: e.width50,
                width80: e.width80,
                pit: e.pit,
                signedErr: e.signedErr,
              ),
            );
          }
          if (seed == 3) seed3.addAll(recs);
          if (leaky) {
            // distanza tra l'origine e l'evento vero
            final outs = tr.logged
                .where((l) => l.type == need.logType)
                .map((l) => l.time)
                .toList();
            for (final a in outs) {
              if (a.isBefore(start.add(const Duration(days: 14)))) continue;
              final known = tr.logged
                  .where((l) => l.time.isBefore(a))
                  .map((l) => l.time)
                  .reduce((x, y) => x.isAfter(y) ? x : y);
              gapsBefore.add(a.difference(known).inMinutes.toDouble());
            }
          }
        }
        final title =
            '${need.name}, origine ${leaky ? "A (come il test attuale)" : "B (evento precedente + 1 min)"}';
        b.writeln(render('$title — 10 semi', summarize(all)));
        b.writeln(
          '- seme 3 (quello del test): errore mediano modello '
          '${medOf(seed3, (e) => e.errModel)} min, timer '
          '${medOf(seed3, (e) => e.errTimer)} min, n=${seed3.length}',
        );
        if (leaky) {
          gapsBefore.sort();
          b.writeln(
            '- minuti tra l\'origine A e l\'evento vero: mediana '
            '${gapsBefore[gapsBefore.length ~/ 2]}, 90° percentile '
            '${gapsBefore[(gapsBefore.length * 0.9).floor()]}',
          );
        }
      }
    }
    saveText('artefatto', b.toString());
    // ignore: avoid_print
    print(b);
  }, timeout: Timeout.none);
}
