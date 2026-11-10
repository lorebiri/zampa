import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';
import 'package:zampa/models.dart';

/// Validazione del modello su cani sintetici il cui comportamento "vero"
/// è generato da regole DIVERSE da quelle del simulatore interno del
/// modello: il modello deve impararle dai dati.
///
/// Protocollo: 14 giorni di addestramento, 7 di verifica. Per ogni evento
/// di verifica il modello prevede usando solo le informazioni disponibili
/// in quel momento (l'ultimo evento registrato prima dell'evento vero:
/// pipì precedente, pasto, acqua, risveglio...). Confronto con un timer
/// fisso pari all'intervallo medio osservato (ciò che fanno molte app).

class _Truth {
  _Truth(this.dog, this.logs);
  final Dog dog;
  final List<LogEntry> logs;
}

_Truth _adult(DateTime start, int days, int seed) {
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
  for (var d = 0; d < days; d++) {
    final day = start.add(Duration(days: d));
    DateTime at(double h) => DateTime(
      day.year,
      day.month,
      day.day,
    ).add(Duration(minutes: (h * 60).round()));
    final wake = at(7 + g() * 0.5);
    log(LogType.risveglio, wake);
    // Questo cane: pipì 10' dopo il risveglio, poi ritmo proprio di ~3h40'
    // (più breve dei 5h del prior adulto), e pipì 25' dopo il pasto.
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
    // Cacca: 30-45' dopo colazione quasi sempre, dopo cena 2 volte su 3.
    log(LogType.cacca, meals[0].add(Duration(minutes: 30 + r.nextInt(15))));
    if (r.nextDouble() < 0.67) {
      log(LogType.cacca, meals[1].add(Duration(minutes: 35 + r.nextInt(15))));
    }
  }
  return _Truth(dog, logs);
}

({double model, double timer, double inWindow, int n, double width}) _evaluate(
  _Truth truth,
  Need need,
  DateTime testFrom,
) {
  final engine = EliminationModel();
  final type = need.logType;
  final events =
      truth.logs.where((l) => l.type == type).map((l) => l.time).toList()
        ..sort();
  final errModel = <double>[];
  final errTimer = <double>[];
  var inWin = 0;
  final widths = <double>[];
  for (var i = 1; i < events.length; i++) {
    final actual = events[i];
    if (actual.isBefore(testFrom)) continue;
    // Momento della previsione: subito dopo l'ultima informazione
    // registrata prima dell'evento vero.
    final known = truth.logs
        .where((l) => l.time.isBefore(actual))
        .map((l) => l.time)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final now = known.add(const Duration(minutes: 1));
    final visible = truth.logs.where((l) => !l.time.isAfter(known)).toList();
    final fitted = engine.fit(truth.dog, need, visible, const [], now);
    final f = fitted.forecast(now, withAccuracy: false);
    errModel.add(actual.difference(f.expectedAt).inMinutes.abs().toDouble());
    widths.add(f.windowEnd.difference(f.windowStart).inMinutes.toDouble());
    if (!actual.isBefore(f.windowStart.subtract(const Duration(minutes: 15))) &&
        !actual.isAfter(f.windowEnd.add(const Duration(minutes: 15)))) {
      inWin++;
    }
    // Timer fisso: intervallo medio osservato da sveglio nei dati visibili.
    final prev = events.lastWhere((e) => !e.isAfter(known));
    final past = events.where((e) => !e.isAfter(known)).toList();
    final gaps = <double>[];
    for (var k = 1; k < past.length; k++) {
      final gap = past[k].difference(past[k - 1]).inMinutes.toDouble();
      if (gap < 600) gaps.add(gap);
    }
    final mean = gaps.isEmpty
        ? 300
        : gaps.reduce((a, b) => a + b) / gaps.length;
    var timer = prev.add(Duration(minutes: mean.round()));
    if (timer.hour >= 23 || timer.hour < 7) {
      timer = DateTime(
        timer.year,
        timer.month,
        timer.day + (timer.hour >= 23 ? 1 : 0),
        7,
        15,
      );
    }
    errTimer.add(actual.difference(timer).inMinutes.abs().toDouble());
  }
  double med(List<double> x) => (x..sort())[x.length ~/ 2];
  return (
    model: med(errModel),
    timer: med(errTimer),
    inWindow: inWin / errModel.length,
    n: errModel.length,
    width: med(widths),
  );
}

void main() {
  final start = DateTime(2026, 9, 1);
  final truth = _adult(start, 21, 3);
  final testFrom = start.add(const Duration(days: 14));

  test('pipì: il modello batte il timer fisso', () {
    final r = _evaluate(truth, Need.pipi, testFrom);
    // ignore: avoid_print
    print(
      'PIPÌ  n=${r.n}  errore mediano modello=${r.model} min  '
      'timer=${r.timer} min  nella finestra=${(r.inWindow * 100).round()}% '
      '(ampiezza mediana ${r.width} min)',
    );
    expect(r.model, lessThan(r.timer));
    expect(r.model, lessThan(45));
  });

  test('cacca: il modello batte il timer fisso', () {
    final r = _evaluate(truth, Need.cacca, testFrom);
    // ignore: avoid_print
    print(
      'CACCA n=${r.n}  errore mediano modello=${r.model} min  '
      'timer=${r.timer} min  nella finestra=${(r.inWindow * 100).round()}% '
      '(ampiezza mediana ${r.width} min)',
    );
    expect(r.model, lessThan(r.timer));
    expect(r.model, lessThan(45));
  });

  test('senza dati usa i valori della letteratura', () {
    final dog = truth.dog;
    final f = EliminationModel()
        .fit(dog, Need.pipi, const [], const [], start)
        .forecast(start);
    expect(f.last, isNull);
    expect(f.confidence.name, 'bassa');
  });

  test('il cortisonico accorcia l\'intervallo previsto', () {
    final now = testFrom;
    final visible = truth.logs.where((l) => l.time.isBefore(now)).toList();
    final base = EliminationModel()
        .fit(truth.dog, Need.pipi, visible, const [], now)
        .typicalInterval(now);
    final drug = HealthRecord(
      id: 'x',
      dogId: 'd',
      type: RecordType.farmaco,
      title: 'Prednisolone',
      date: now.subtract(const Duration(days: 1)),
      everyHours: 24,
      endDate: now.add(const Duration(days: 5)),
    );
    final withDrug = EliminationModel()
        .fit(truth.dog, Need.pipi, visible, [drug], now)
        .typicalInterval(now);
    expect(withDrug, lessThan(base));
  });

  test(
    'anziano: ultima pipì alle 18 → uscita prima di dormire, non al mattino',
    () {
      final now = DateTime(2026, 11, 10, 21, 30);
      final old = Dog(
        id: 'o',
        name: 'Vecchio',
        birthDate: now.subtract(const Duration(days: 365 * 13)),
        sex: Sex.femmina,
        weightKg: 12,
        wakeHour: 7,
        sleepStartHour: 23,
      );
      final logs = [
        LogEntry(
          id: '1',
          dogId: 'o',
          type: LogType.pipi,
          time: DateTime(2026, 11, 10, 18),
        ),
      ];
      final f = EliminationModel()
          .fit(old, Need.pipi, logs, const [], now)
          .forecast(now);
      expect(
        f.recommendedAt.isBefore(DateTime(2026, 11, 10, 23, 1)),
        isTrue,
        reason: 'consigliato ${f.recommendedAt} – ${f.reason}',
      );
    },
  );
}
