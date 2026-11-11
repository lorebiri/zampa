import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';

/// Terza revisione veterinaria (ricerca/26): correzioni A1, A2, A3, A10.
final _start = DateTime(2026, 10, 1);
final _now = DateTime(2026, 10, 15, 9, 0);

Dog _dog({
  double kg = 15,
  DietType diet = DietType.secco,
  String conditions = '',
  Prudence prudence = Prudence.normale,
  int ageYears = 5,
}) => Dog(
  id: 'r',
  name: 'Rev',
  birthDate: _now.subtract(Duration(days: 365 * ageYears)),
  sex: Sex.femmina,
  weightKg: kg,
  wakeHour: 7,
  sleepStartHour: 23,
  diet: diet,
  conditions: conditions,
  prudence: prudence,
);

/// Pipì da sveglio ogni [gap] ± 20 min, dalle 7:10 alle 22:45.
List<LogEntry> _pees(int days, double gap, {String dogId = 'r'}) {
  final r = math.Random(5);
  final out = <LogEntry>[];
  var id = 0;
  for (var d = 0; d < days; d++) {
    final day = DateTime(_start.year, _start.month, _start.day + d);
    var t = day.add(const Duration(hours: 7, minutes: 10));
    final bed = day.add(const Duration(hours: 22, minutes: 45));
    while (t.isBefore(bed)) {
      out.add(
        LogEntry(id: '${id++}', dogId: dogId, type: LogType.pipi, time: t),
      );
      t = t.add(Duration(minutes: (gap + (r.nextDouble() - 0.5) * 40).round()));
    }
  }
  return out;
}

HealthRecord _drug(String title, DateTime from, {int every = 24}) =>
    HealthRecord(
      id: title,
      dogId: 'r',
      type: RecordType.farmaco,
      title: title,
      date: from,
      everyHours: every,
      endDate: _now.add(const Duration(days: 30)),
    );

Forecast _forecast(Dog dog, List<LogEntry> logs, List<HealthRecord> recs) {
  final at = logs
      .lastWhere((l) => !l.time.isAfter(_now))
      .time
      .add(const Duration(minutes: 1));
  return EliminationModel()
      .fit(dog, Need.pipi, logs, recs, at, shadow: false)
      .forecast(at, withAccuracy: false);
}

void main() {
  group('A1: il fattore biologico non conta due volte', () {
    final logs = _pees(14, 240);

    test('cane piccolo sano a cibo umido con 14 giorni di dati: k = 1', () {
      final small = _forecast(_dog(kg: 4, diet: DietType.umido), logs, []);
      final plain = _forecast(_dog(), logs, []);
      expect(small.typicalIntervalMin, closeTo(plain.typicalIntervalMin, 0.5));
      // Taglia e dieta non accorciano il tetto né compaiono come causa.
      final bio = BioParams.modifier(
        Need.pipi,
        _dog(kg: 4, diet: DietType.umido),
        const [],
        _now,
      );
      expect(bio.clinical, 1.0);
      expect(bio.recent, 1.0);
      expect(bio.constitutional, lessThan(0.75));
    });

    test('diabetico noto con 14 giorni di dati: k = 1', () {
      final sick = _forecast(_dog(conditions: 'diabete'), logs, []);
      final plain = _forecast(_dog(), logs, []);
      expect(sick.typicalIntervalMin, closeTo(plain.typicalIntervalMin, 0.5));
    });

    test('furosemide iniziata 2 giorni fa: k < 1 e testo coerente', () {
      final drug = _drug(
        'Furosemide',
        _now.subtract(const Duration(days: 2, hours: 10)),
      );
      final f = _forecast(_dog(), logs, [drug]);
      final plain = _forecast(_dog(), logs, []);
      expect(f.typicalIntervalMin, lessThan(plain.typicalIntervalMin));
      expect(f.reason, contains('accorciato per'));
      expect(f.reason, contains('furosemide'));
    });

    test('furosemide da più di 14 giorni, fuori dalla finestra della dose: '
        'k = 1', () {
      final drug = _drug(
        'Furosemide',
        _now.subtract(const Duration(days: 20, hours: 10)),
      );
      final f = _forecast(_dog(), logs, [drug]);
      final plain = _forecast(_dog(), logs, []);
      expect(f.typicalIntervalMin, closeTo(plain.typicalIntervalMin, 0.5));
    });

    test('nessuna combinazione scende sotto k = 0,5', () {
      final recs = [
        _drug('Furosemide', _now.subtract(const Duration(hours: 1))),
        _drug('Prednisolone', _now.subtract(const Duration(days: 1))),
      ];
      final bio = BioParams.modifier(
        Need.pipi,
        _dog(kg: 4, diet: DietType.umido, conditions: 'diabete, cistite'),
        recs,
        _now,
      );
      expect(bio.recent, greaterThanOrEqualTo(0.5));
      final f = _forecast(
        _dog(kg: 4, diet: DietType.umido, conditions: 'diabete, cistite'),
        logs,
        recs,
      );
      final plain = _forecast(_dog(), logs, []);
      expect(
        f.typicalIntervalMin,
        greaterThanOrEqualTo(plain.typicalIntervalMin * 0.5 - 0.5),
      );
    });

    test('«Meno uscite» non è più bloccata per un adulto piccolo sano', () {
      // Il piano del giorno usa la stessa prudenza dei promemoria.
      List<DateTime> plan(Dog d) => EliminationModel()
          .fit(d, Need.pipi, logs, const [], _now, shadow: false)
          .dailyPlan(_now);
      final low = plan(
        _dog(kg: 4, diet: DietType.umido, prudence: Prudence.bassa),
      );
      final normal = plan(_dog(kg: 4, diet: DietType.umido));
      expect(low[1].isAfter(normal[1]), isTrue);
      // Per un cucciolo resta bloccata (06 §30).
      final pup = plan(_dog(prudence: Prudence.bassa, ageYears: 0));
      final pupNormal = plan(_dog(ageYears: 0));
      expect(pup[1], pupNormal[1]);
    });
  });

  test('A2: taglia e dieta non alzano la soglia «fa pipì più spesso»', () {
    // 14 giorni a 4 uscite al giorno, poi 3 giorni a 7 (×1,75 e +3).
    final logs = <LogEntry>[];
    var id = 0;
    final now = DateTime(2026, 10, 20, 12);
    for (var d = 17; d >= 1; d--) {
      final n = d <= 3 ? 7 : 4;
      final day = DateTime(now.year, now.month, now.day - d);
      for (var k = 0; k < n; k++) {
        logs.add(
          LogEntry(
            id: '${id++}',
            dogId: 'r',
            type: LogType.pipi,
            time: day.add(Duration(hours: 7, minutes: k * (900 ~/ n))),
          ),
        );
      }
    }
    List<HealthAlert> alerts(Dog d) => AlertEngine.compute(
      dog: d,
      logs: logs,
      records: const [],
      weights: const [],
      now: now,
    );
    bool more(Dog d) =>
        alerts(d).any((a) => a.title == 'Fa pipì più spesso del solito');
    expect(more(_dog()), isTrue);
    expect(more(_dog(kg: 4, diet: DietType.umido)), isTrue);
  });

  test('A3: «nessuna pipì» a 12 ore dopo un intervento', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(prefs: await SharedPreferences.getInstance());
    await s.load();
    final now = DateTime(2026, 11, 10, 10, 5);
    final d = Dog(
      id: 'op',
      name: 'Operato',
      birthDate: DateTime(2020, 1, 1),
      sex: Sex.femmina,
      weightKg: 20,
    );
    await s.upsertDog(d);
    final last = now.subtract(const Duration(hours: 2));
    await s.addLog(
      LogEntry(id: 'p', dogId: 'op', type: LogType.pipi, time: last),
    );
    Duration noPee() {
      final p = s
          .planNotifications(now)
          .firstWhere((p) => p.title.contains('nessuna pipì'));
      return p.when.difference(last);
    }

    expect(noPee().inHours, 24);
    await s.upsertRecord(
      HealthRecord(
        id: 'i',
        dogId: 'op',
        type: RecordType.intervento,
        title: 'Sterilizzazione',
        date: now.subtract(const Duration(days: 1)),
        done: true,
      ),
    );
    expect(noPee().inHours, 12);
    // Dopo 3 giorni torna a 24 ore...
    await s.upsertRecord(
      HealthRecord(
        id: 'i',
        dogId: 'op',
        type: RecordType.intervento,
        title: 'Sterilizzazione',
        date: now.subtract(const Duration(days: 5)),
        done: true,
      ),
    );
    expect(noPee().inHours, 24);
    // ...ma non dopo una chirurgia della colonna (14 giorni).
    await s.upsertRecord(
      HealthRecord(
        id: 'i',
        dogId: 'op',
        type: RecordType.intervento,
        title: 'Ernia del disco',
        date: now.subtract(const Duration(days: 5)),
        done: true,
      ),
    );
    expect(noPee().inHours, 12);
  });

  group('A10: il piano del giorno non supera mai il tetto di forecast', () {
    final cases = <(String, Dog, List<LogEntry>, List<HealthRecord>)>[
      ('adulto che trattiene 9 ore', _dog(), _pees(14, 540), const []),
      (
        'cucciolo con «Meno uscite»',
        _dog(prudence: Prudence.bassa, ageYears: 0),
        _pees(14, 200),
        const [],
      ),
      (
        'adulto in diuretico',
        _dog(),
        _pees(14, 300),
        [_drug('Furosemide', _now.subtract(const Duration(days: 20)))],
      ),
      ('senza dati', _dog(ageYears: 13), const <LogEntry>[], const []),
    ];
    for (final (name, dog, logs, recs) in cases) {
      test(name, () {
        final m = EliminationModel().fit(
          dog,
          Need.pipi,
          logs,
          recs,
          _now,
          shadow: false,
        );
        final cap = m.dayCapMinutes(_now);
        final plan = m.dailyPlan(_now);
        expect(plan, isNotEmpty);
        for (var i = 1; i < plan.length; i++) {
          expect(
            plan[i].difference(plan[i - 1]).inMinutes,
            lessThanOrEqualTo(cap.round() + 1),
            reason: '$name: ${plan[i - 1]} → ${plan[i]}, tetto $cap',
          );
        }
        // Il tetto del piano è lo stesso di forecast (solo fattori clinici).
        expect(cap, greaterThanOrEqualTo(120));
        expect(cap, lessThanOrEqualTo(m.prior.maxDay));
      });
    }
  });
}
