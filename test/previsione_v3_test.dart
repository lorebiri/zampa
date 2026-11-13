import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/outing_plan.dart';
import 'package:zampa/logic/poop_forecast.dart';
import 'package:zampa/logic/potty_signals.dart';
import 'package:zampa/logic/study_export.dart';
import 'package:zampa/models.dart';
import 'package:zampa/ui/potty_v3.dart';

/// Test della v3 (ricerca/28): segnali, cacca legata ai pasti, piano di
/// uscite, esportazione anonima.

final _start = DateTime(2026, 9, 7); // lunedì

Dog _dog({double ageMonths = 36, double kg = 15, String name = 'Lulù'}) => Dog(
  id: 'd1',
  name: name,
  birthDate: _start.subtract(Duration(days: (ageMonths * 30.44).round())),
  sex: Sex.femmina,
  neutered: true,
  weightKg: kg,
  wakeHour: 7,
  sleepStartHour: 23,
);

var _n = 0;
LogEntry _l(LogType t, DateTime at, {bool indoor = false, Set<Sign>? signs}) =>
    LogEntry(
      id: 'l${_n++}',
      dogId: 'd1',
      type: t,
      time: at,
      indoor: indoor,
      signs: signs ?? const {},
    );

/// Cane regolare: pasti 7:45 e 19:00, pipì 7:10, 12:30, 18:00, 22:30,
/// cacca 40 minuti dopo i pasti (8:25 e 19:40).
List<LogEntry> _regularDog(int days) {
  final out = <LogEntry>[];
  for (var d = 0; d < days; d++) {
    final day = _start.add(Duration(days: d));
    DateTime at(int h, int m) => day.add(Duration(hours: h, minutes: m));
    out.add(_l(LogType.pasto, at(7, 45)));
    out.add(_l(LogType.pasto, at(19, 0)));
    for (final (h, m) in [(7, 10), (12, 30), (18, 0), (22, 30)]) {
      out.add(_l(LogType.pipi, at(h, m)));
    }
    out.add(_l(LogType.cacca, at(8, 25)));
    out.add(_l(LogType.cacca, at(19, 40)));
  }
  out.sort((a, b) => a.time.compareTo(b.time));
  return out;
}

void main() {
  group('Segnali', () {
    test('un segnale recente dopo l\'ultima pipì fa scattare «Esci adesso»',
        () {
      final now = _start.add(const Duration(hours: 10));
      final logs = [
        _l(LogType.pipi, now.subtract(const Duration(hours: 3))),
        _l(LogType.segnale, now.subtract(const Duration(minutes: 3)),
            signs: {Sign.allaPorta}),
      ];
      final a = signalAlert(logs, now)!;
      expect(a.goNow, isTrue);
      expect(a.kind, Sign.allaPorta);
      expect(a.prob30, closeTo(0.8, 1e-9)); // valore tipico, nessuna storia
      expect(probWithSignal(0.1, a), greaterThan(0.8));
      final x = signalTexts(a, now, 'Lulù')!;
      expect(x.title, 'Esci adesso con Lulù');
      expect(x.body, contains('alla porta'));
    });

    test('dopo la pipì il segnale non vale più; dopo 20 minuti niente «adesso»',
        () {
      final now = _start.add(const Duration(hours: 10));
      final sig = _l(LogType.segnale, now.subtract(const Duration(minutes: 10)),
          signs: {Sign.annusaTerra});
      expect(
        signalAlert([sig, _l(LogType.pipi, now.subtract(const Duration(minutes: 2)))],
            now),
        isNull,
      );
      final old = _l(LogType.segnale, now.subtract(const Duration(minutes: 25)),
          signs: {Sign.annusaTerra});
      expect(signalAlert([old], now)!.goNow, isFalse);
      expect(probWithSignal(0.2, signalAlert([old], now)), 0.2);
    });

    test('la probabilità si impara sul cane', () {
      final now = _start.add(const Duration(days: 10));
      final logs = <LogEntry>[];
      // 10 volte «irrequieto» seguito da una pipì dopo 10 minuti.
      for (var d = 0; d < 10; d++) {
        final t = _start.add(Duration(days: d, hours: 15));
        logs.add(_l(LogType.segnale, t, signs: {Sign.irrequieto}));
        logs.add(_l(LogType.pipi, t.add(const Duration(minutes: 10))));
      }
      final lp = learnedSignalProb(logs, now, Sign.irrequieto);
      expect(lp.n, 10);
      expect(lp.p, greaterThan(0.8)); // da 0,4 tipico a (10 + 1,6) / 14
      // Un tipo diverso resta al valore tipico.
      expect(learnedSignalProb(logs, now, Sign.guaisce).p, closeTo(0.8, 1e-9));
    });
  });

  group('Cacca legata ai pasti', () {
    test('cane regolare: dopo la cacca del mattino prevede quella dopo cena',
        () {
      final logs = _regularDog(14);
      final day = _start.add(const Duration(days: 14));
      final origin = day.add(const Duration(hours: 8, minutes: 26));
      final visible = [
        ...logs,
        _l(LogType.pasto, day.add(const Duration(hours: 7, minutes: 45))),
        _l(LogType.pipi, day.add(const Duration(hours: 7, minutes: 10))),
        _l(LogType.cacca, day.add(const Duration(hours: 8, minutes: 25))),
      ];
      final f = poopForecast(_dog(), visible, origin)!;
      final err = f.expectedAt
          .difference(day.add(const Duration(hours: 19, minutes: 40)))
          .inMinutes
          .abs();
      expect(err, lessThanOrEqualTo(45));
      expect(f.mainAnchor, isNotNull);
      expect(f.nResiduals, greaterThanOrEqualTo(8));
      expect(poopTexts(f, origin, 'Lulù')!.title, startsWith('Prossima cacca'));
    });

    test('origine onesta: i log successivi all\'origine non cambiano nulla',
        () {
      final logs = _regularDog(20);
      final origin = _start.add(const Duration(days: 12, hours: 8, minutes: 26));
      final past = [
        for (final l in logs)
          if (!l.time.isAfter(origin)) l,
      ];
      final a = poopForecast(_dog(), past, origin)!;
      final b = poopForecast(_dog(), logs, origin)!;
      expect(b.expectedAt, a.expectedAt);
      expect(b.lo50, a.lo50);
      expect(b.hi80, a.hi80);
    });

    test('senza cacche registrate nessuna previsione', () {
      expect(poopForecast(_dog(), const [], _start), isNull);
    });
  });

  group('Piano di uscite', () {
    final owner = const OwnerSchedule(
      awayWeekdays: [(510, 1065)], // 8:30-17:45
      wakeWeekday: 420,
      bedWeekday: 1380,
      wakeWeekend: 480,
      bedWeekend: 1410,
    );

    test('le uscite cadono solo quando il padrone è a casa e sveglio', () {
      final logs = _regularDog(14);
      final now = _start.add(const Duration(days: 14, hours: 7));
      for (final p in planOptions(_dog(), logs, owner, now)) {
        for (final t in p.times) {
          expect(owner.available(_dog(), t), isTrue, reason: '$t');
        }
        // Distanza minima di un'ora tra due uscite.
        for (var i = 1; i < p.times.length; i++) {
          expect(p.times[i].difference(p.times[i - 1]).inMinutes,
              greaterThanOrEqualTo(60));
        }
      }
    });

    test('più uscite, rischio non più alto; cucciolo più a rischio', () {
      final now = _start.add(const Duration(days: 14, hours: 7));
      final adult = planOptions(_dog(), _regularDog(14), owner, now);
      for (var i = 1; i < adult.length; i++) {
        expect(adult[i].expectedAccidents,
            lessThanOrEqualTo(adult[i - 1].expectedAccidents + 1e-9));
      }
      final pup = planOptions(_dog(ageMonths: 4), _regularDog(14), owner, now);
      expect(pup.first.expectedAccidents, greaterThan(adult.first.expectedAccidents));
      // Un cucciolo con 8 ore e tre quarti fuori casa supera il suo limite.
      expect(pup.first.overCap, isTrue);
    });

    test('gli incidenti registrati abbassano la tenuta stimata', () {
      final logs = _regularDog(14);
      final now = _start.add(const Duration(days: 14, hours: 7));
      final h0 = HoldModel.fit(_dog(), logs, now);
      final withAcc = [
        ...logs,
        for (var d = 7; d < 14; d++)
          _l(LogType.pipi, _start.add(Duration(days: d, hours: 11)),
              indoor: true),
      ]..sort((a, b) => a.time.compareTo(b.time));
      final h1 = HoldModel.fit(_dog(), withAcc, now);
      expect(h1.medianHold, lessThan(h0.medianHold));
    });

    test('rischio a parole senza frasi di accuratezza', () {
      expect(riskWords(0.1), 'rischio molto basso');
      expect(riskWords(3), 'rischio alto');
    });

    test('giorni festivi come il fine settimana', () {
      final hol = DateTime(2026, 12, 8); // martedì
      final o = OwnerSchedule(awayWeekdays: const [(510, 1065)], holidays: {hol});
      expect(o.available(_dog(), hol.add(const Duration(hours: 12))), isTrue);
      expect(
        o.available(_dog(), hol.add(const Duration(days: 1, hours: 12))),
        isFalse,
      );
    });
  });

  group('Esportazione anonima', () {
    test('senza consenso non esporta nulla', () {
      expect(
        buildStudyExport(
          dog: _dog(),
          logs: _regularDog(10),
          now: _start.add(const Duration(days: 10)),
          pid: newStudyPid(math.Random(1)),
          consent: false,
        ),
        isNull,
      );
    });

    test('niente nome, orari o date: solo giorni relativi e minuti arrotondati',
        () {
      final logs = [
        ..._regularDog(10),
        _l(LogType.segnale, _start.add(const Duration(days: 9, hours: 12, minutes: 20)),
            signs: {Sign.allaPorta}),
      ];
      final e = buildStudyExport(
        dog: _dog(name: 'Fufi Rossi'),
        logs: logs,
        now: _start.add(const Duration(days: 10)),
        pid: newStudyPid(math.Random(1)),
        consent: true,
        garden: false,
      )!;
      final s = jsonEncode({...e}..remove('version'));
      expect(s, isNot(contains('Fufi')));
      expect(s, isNot(contains('2026')));
      expect(s, isNot(contains('d1'))); // id del cane
      final ev = (e['events'] as List).cast<Map<String, Object?>>();
      expect(ev, isNotEmpty);
      for (final x in ev) {
        for (final k in x.keys.where((k) => k.startsWith('err'))) {
          expect((x[k] as int) % 5, 0);
        }
      }
      expect(ev.any((x) => x['signal_before'] == true), isTrue);
      expect(RegExp(r'^[0-9a-f-]{36}$').hasMatch(e['pid'] as String), isTrue);
    });
  });
}
