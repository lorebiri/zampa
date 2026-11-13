import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';
import 'package:zampa/logic/pee_forecast_v2.dart';
import 'package:zampa/models.dart';

/// Previsione v2 della prossima pipì (ricerca/27): mediana di tre regole,
/// finestre e probabilità calibrate sugli errori passati, origine onesta.

final _start = DateTime(2026, 9, 7);

Dog _dog() => Dog(
  id: 'd',
  name: 'Test',
  birthDate: _start.subtract(const Duration(days: 365 * 4)),
  sex: Sex.femmina,
  neutered: true,
  weightKg: 18,
  wakeHour: 7,
  sleepStartHour: 23,
);

/// Pipì a orari quasi fissi (7:15, 11, 15, 19, 22:30), ±[jit] minuti.
List<LogEntry> _regular(int days, {int jit = 20, int seed = 1}) {
  final r = math.Random(seed);
  final logs = <LogEntry>[];
  var id = 0;
  for (var d = 0; d < days; d++) {
    for (final h in [7.25, 11.0, 15.0, 19.0, 22.5]) {
      final t = DateTime(
        _start.year,
        _start.month,
        _start.day + d,
      ).add(Duration(minutes: (h * 60).round() + r.nextInt(2 * jit + 1) - jit));
      logs.add(LogEntry(id: '${id++}', dogId: 'd', type: LogType.pipi, time: t));
    }
  }
  return logs;
}

PeeForecastV2 _v2(List<LogEntry> logs, DateTime now) =>
    EliminationModel()
        .fit(_dog(), Need.pipi, logs, const [], now, shadow: false)
        .forecast(now, withAccuracy: false)
        .v2!;

void main() {
  test('orari fissi: la v2 prevede il prossimo orario abituale', () {
    final logs = _regular(15);
    final now = DateTime(_start.year, _start.month, _start.day + 14, 12, 0);
    final day = logs.where((l) => !l.time.isAfter(now)).toList();
    final v = _v2(day, now);
    final usual = DateTime(now.year, now.month, now.day, 15);
    expect(v.expectedAt.difference(usual).inMinutes.abs(), lessThan(45));
    expect(v.lo80.isAfter(v.expectedAt), isFalse);
    expect(v.hi80.isBefore(v.expectedAt), isFalse);
    expect(v.lo50.isBefore(v.lo80), isFalse);
    expect(v.hi50.isAfter(v.hi80), isFalse);
    expect(v.probNextHour, inInclusiveRange(0.0, 0.9));
    expect(v.nResiduals, greaterThanOrEqualTo(8));
    expect(v.confidence, isNot(V2Confidence.bassa));
  });

  test('l\'orario previsto è la mediana dei tre candidati', () {
    final logs = _regular(14, jit: 40, seed: 3);
    for (final h in [9, 13, 17, 21]) {
      final now = DateTime(_start.year, _start.month, _start.day + 12, h, 10);
      final v = _v2(logs.where((l) => !l.time.isAfter(now)).toList(), now);
      final p = v.point;
      final c = [p.base, p.sameTime, p.sameWeekday]..sort();
      var expected = p.earliest ? c.first : c[1];
      if (expected.isBefore(p.origin)) expected = p.origin;
      expect(p.at, expected);
    }
  });

  test('origine onesta: i log successivi non cambiano la v2', () {
    final logs = _regular(16, jit: 30, seed: 5);
    final now = DateTime(_start.year, _start.month, _start.day + 13, 16, 30);
    final upto = logs.where((l) => !l.time.isAfter(now)).toList();
    final a = _v2(upto, now);
    final b = _v2(logs, now); // con anche 3 giorni di log futuri
    expect(b.expectedAt, a.expectedAt);
    expect(b.lo80, a.lo80);
    expect(b.hi80, a.hi80);
    expect(b.lo50, a.lo50);
    expect(b.probNextHour, closeTo(a.probNextHour, 1e-9));
  });

  test('pipì più frequenti negli ultimi giorni: vale il più anticipato', () {
    // 11 giorni ogni ~4 ore, poi 3 giorni ogni ~2 ore (poliuria).
    final logs = <LogEntry>[];
    var id = 0;
    for (var d = 0; d < 14; d++) {
      final step = d < 11 ? 240 : 120;
      for (
        var m = 7 * 60 + 15;
        m <= 22 * 60 + 30;
        m += step
      ) {
        logs.add(
          LogEntry(
            id: '${id++}',
            dogId: 'd',
            type: LogType.pipi,
            time: DateTime(
              _start.year,
              _start.month,
              _start.day + d,
            ).add(Duration(minutes: m)),
          ),
        );
      }
    }
    final now = DateTime(_start.year, _start.month, _start.day + 13, 14, 0);
    final f = EliminationModel()
        .fit(_dog(), Need.pipi, logs, const [], now, shadow: false)
        .forecast(now, withAccuracy: false);
    expect(f.adaptedRecent, isTrue);
    final p = f.v2!.point;
    expect(p.earliest, isTrue);
    final c = [p.base, p.sameTime, p.sameWeekday]..sort();
    final first = c.first.isBefore(p.origin) ? p.origin : c.first;
    expect(p.at, first);
    expect(p.at.isAfter(p.base), isFalse);
  });

  test('l\'avviso non è mai dopo l\'uscita consigliata (tetti invariati)', () {
    final logs = _regular(10, jit: 45, seed: 9);
    for (final h in [8, 12, 16, 20]) {
      final now = DateTime(_start.year, _start.month, _start.day + 9, h, 5);
      final f = EliminationModel()
          .fit(
            _dog(),
            Need.pipi,
            logs.where((l) => !l.time.isAfter(now)).toList(),
            const [],
            now,
            shadow: false,
          )
          .forecast(now, withAccuracy: false);
      expect(f.v2!.alertAt.isAfter(f.recommendedAt), isFalse);
      expect(f.v2!.alertAt.isAfter(f.v2!.lo50), isFalse);
      final cap = BioParams.forNeed(Need.pipi, _dog(), now).maxDay;
      expect(
        f.recommendedAt.difference(f.last!).inMinutes,
        lessThanOrEqualTo(cap.round() + 1),
      );
    }
  });

  test('niente v2 per la cacca e senza pipì registrate', () {
    final now = DateTime(_start.year, _start.month, _start.day + 3, 12);
    final m = EliminationModel();
    expect(
      m
          .fit(_dog(), Need.cacca, _regular(3), const [], now, shadow: false)
          .forecast(now)
          .v2,
      isNull,
    );
    expect(
      m.fit(_dog(), Need.pipi, const [], const [], now, shadow: false)
          .forecast(now)
          .v2,
      isNull,
    );
  });

  test('pochi dati: finestra della previsione di base, fiducia bassa', () {
    final logs = _regular(1);
    final now = DateTime(_start.year, _start.month, _start.day, 12);
    final v = _v2(logs.where((l) => !l.time.isAfter(now)).toList(), now);
    expect(v.nResiduals, 0);
    expect(v.confidence, V2Confidence.bassa);
    expect(v.hi80.isAfter(v.lo80), isTrue);
  });

  test('stesso orario: mediana degli scarti dei giorni passati', () {
    final past = [
      for (var d = 0; d < 4; d++) ...[
        DateTime(2026, 1, 1 + d, 8),
        DateTime(2026, 1, 1 + d, 12, d * 10),
      ],
      DateTime(2026, 1, 5, 8),
    ];
    final p = sameTimeForecast(
      past,
      past.last,
      15,
      const [1, 2, 3, 4],
      DateTime(2026, 1, 1),
      minOffset: 60,
    );
    // Scarti 4 h 00, 4 h 10, 4 h 20, 4 h 30: mediana 4 h 15.
    expect(p, DateTime(2026, 1, 5, 12, 15));
  });
}
