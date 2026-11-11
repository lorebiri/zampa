import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';
import 'package:zampa/logic/potty_predictor.dart';
import 'package:zampa/models.dart';

/// Ciclo 2, C2-3: previsione di base (piano CEO 11.3, ricerca/12 §7).
Dog _dog(DateTime now) => Dog(
  id: 'b',
  name: 'Base',
  birthDate: now.subtract(const Duration(days: 365 * 5)),
  sex: Sex.femmina,
  weightKg: 15,
  wakeHour: 7,
  sleepStartHour: 23,
);

/// Pipì da sveglio a intervalli [gapFor](giorno) ± 20 min, dalle 7:10 alle 22:45.
List<LogEntry> _pees(DateTime start, int days, double Function(int) gapFor) {
  final r = math.Random(11);
  final out = <LogEntry>[];
  var id = 0;
  for (var d = 0; d < days; d++) {
    final day = DateTime(start.year, start.month, start.day + d);
    var t = day.add(const Duration(hours: 7, minutes: 10));
    final bed = day.add(const Duration(hours: 22, minutes: 45));
    while (t.isBefore(bed)) {
      out.add(LogEntry(id: '${id++}', dogId: 'b', type: LogType.pipi, time: t));
      t = t.add(
        Duration(minutes: (gapFor(d) + (r.nextDouble() - 0.5) * 40).round()),
      );
    }
    out.add(LogEntry(id: '${id++}', dogId: 'b', type: LogType.pipi, time: bed));
  }
  return out;
}

void main() {
  final start = DateTime(2026, 10, 1);

  test('T14: poliuria che compare, la previsione non resta in ritardo', () {
    // 10 giorni a ~4 ore, poi dal giorno 10 a ~2 ore.
    final logs = _pees(start, 16, (d) => d < 10 ? 240 : 120);
    final dog = _dog(start);
    final events = logs.map((l) => l.time).toList();
    final signed = <double>[];
    for (var i = 1; i < events.length; i++) {
      final actual = events[i];
      // Eventi con poliuria in corso da almeno 4 giorni.
      if (actual.isBefore(DateTime(2026, 10, 14))) continue;
      final prev = events[i - 1];
      if (PottyPredictor.inSleepWindow(dog, actual) ||
          actual.difference(prev).inHours > 6) {
        continue;
      }
      final now = prev.add(const Duration(minutes: 1));
      final visible = logs.where((l) => !l.time.isAfter(prev)).toList();
      final f = EliminationModel()
          .fit(dog, Need.pipi, visible, const [], now)
          .forecast(now, withAccuracy: false);
      signed.add(actual.difference(f.expectedAt).inMinutes.toDouble());
    }
    signed.sort();
    final med = signed[signed.length ~/ 2];
    // ignore: avoid_print
    print('T14 n=${signed.length} errore con segno mediano=$med min');
    expect(med, greaterThanOrEqualTo(-20));
  });

  test('T15: tetto di sicurezza invariato da sveglio', () {
    final now = DateTime(2026, 10, 20, 9, 0);
    final dog = _dog(now);
    // Un cane che di solito trattiene a lungo (~9 ore).
    final logs = _pees(start, 19, (_) => 540);
    final fitted = EliminationModel().fit(dog, Need.pipi, logs, const [], now);
    for (var h = 0; h < 14; h++) {
      final at = now.add(Duration(hours: h));
      final visible = logs.where((l) => !l.time.isAfter(at)).toList();
      final f = EliminationModel()
          .fit(dog, Need.pipi, visible, const [], at)
          .forecast(at, withAccuracy: false);
      if (f.last == null ||
          PottyPredictor.inSleepWindow(dog, f.recommendedAt)) {
        continue;
      }
      final cap = f.last!.add(
        Duration(minutes: fitted.prior.maxDay.round() + 1),
      );
      // Se il tetto è già passato l'uscita consigliata è «adesso».
      final limit = cap.isAfter(at) ? cap : at;
      expect(
        f.recommendedAt.isAfter(limit),
        isFalse,
        reason: 'alle $at: consigliato ${f.recommendedAt}, limite $limit',
      );
    }
  });

  test('orari abituali: un cane portato fuori sempre alle stesse ore', () {
    final logs = <LogEntry>[];
    var id = 0;
    for (var d = 0; d < 14; d++) {
      for (final hm in [(7, 15), (13, 0), (18, 30), (22, 30)]) {
        logs.add(
          LogEntry(
            id: '${id++}',
            dogId: 'b',
            type: LogType.pipi,
            time: DateTime(2026, 10, 1 + d, hm.$1, hm.$2 + (d % 3) * 5),
          ),
        );
      }
    }
    final now = DateTime(2026, 10, 15, 7, 30);
    final f = EliminationModel()
        .fit(
          _dog(now),
          Need.pipi,
          [
            ...logs,
            LogEntry(
              id: 'x',
              dogId: 'b',
              type: LogType.pipi,
              time: DateTime(2026, 10, 15, 7, 15),
            ),
          ],
          const [],
          now,
        )
        .forecast(now, withAccuracy: false);
    expect(f.usualMinutes.length, greaterThanOrEqualTo(3));
    // Prossima uscita all'orario abituale delle 13, non prima delle 12:30.
    expect(f.recommendedAt.hour, anyOf(12, 13));
  });

  test('nessuna percentuale né «affidabilità» nella previsione mostrata', () {
    for (final path in [
      'lib/ui/home_screen.dart',
      'lib/ui/potty_screen.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src.contains('probNextHour'), isFalse, reason: path);
      expect(src.contains('Affidabilità'), isFalse, reason: path);
      expect(src.contains('accuracy'), isFalse, reason: path);
      expect(src.contains('.curve'), isFalse, reason: path);
    }
  });
}
