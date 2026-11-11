import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/logic/nutrition.dart';
import 'package:zampa/logic/prevention.dart';
import 'package:zampa/main.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';

Dog _dog({
  double kg = 20,
  int bcs = 5,
  bool neutered = true,
  int ageMonths = 48,
}) => Dog(
  id: 'd',
  name: 'Fido',
  birthDate: DateTime(
    2026,
    11,
    10,
  ).subtract(Duration(days: (ageMonths * 30.44).round())),
  sex: Sex.maschio,
  neutered: neutered,
  weightKg: kg,
  bodyCondition: bcs,
);

void main() {
  final now = DateTime(2026, 11, 10, 12);

  group('Nutrizione', () {
    test('RER = 70 × kg^0,75', () {
      expect(Nutrition.rer(10), closeTo(393.6, 0.5));
    });
    test('adulto sterilizzato: fattore 1,6', () {
      final p = Nutrition.plan(_dog(), now);
      expect(p.factor, 1.6);
      expect(p.kcalPerDay, closeTo(Nutrition.rer(20) * 1.6, 0.1));
    });
    test('sovrappeso: RER del peso ideale × 1,0', () {
      final p = Nutrition.plan(_dog(kg: 24, bcs: 7), now);
      expect(p.idealWeightKg, closeTo(20, 0.01));
      expect(p.kcalPerDay, closeTo(Nutrition.rer(20), 0.1));
    });
    test('cucciolo sotto 4 mesi: fattore 3', () {
      expect(Nutrition.plan(_dog(kg: 5, ageMonths: 3), now).factor, 3.0);
    });
  });

  group('Prevenzione', () {
    test('cucciolo: piano vaccinale completo', () {
      final s = PreventionPlanner.suggest(
        _dog(kg: 4, ageMonths: 2),
        const [],
        now,
      );
      expect(
        s.where((r) => r.type == RecordType.vaccino).length,
        greaterThanOrEqualTo(4),
      );
      expect(s.every((r) => !r.done), isTrue);
    });
    test('le scadenze sostituite non compaiono', () {
      final a = HealthRecord(
        id: 'a',
        dogId: 'd',
        type: RecordType.vaccino,
        title: 'Leptospirosi',
        date: DateTime(2025, 1, 1),
        nextDue: DateTime(2026, 1, 1),
      );
      final b = HealthRecord(
        id: 'b',
        dogId: 'd',
        type: RecordType.vaccino,
        title: 'Leptospirosi',
        date: DateTime(2026, 1, 2),
        nextDue: DateTime(2027, 1, 2),
      );
      final due = dueItems([a, b], 'd');
      expect(due.length, 1);
      expect(due.single.record.id, 'b');
    });
  });

  group('Allarmi', () {
    List<HealthAlert> run(List<LogEntry> logs, {Dog? dog}) =>
        AlertEngine.compute(
          dog: dog ?? _dog(),
          logs: logs,
          records: const [],
          weights: const [],
          now: now,
        );
    LogEntry e(LogType t, Duration ago, {Set<Sign> signs = const {}}) =>
        LogEntry(
          id: '$t$ago',
          dogId: 'd',
          type: t,
          time: now.subtract(ago),
          signs: signs,
        );

    Dog female({bool neutered = true}) => _dog()
      ..sex = Sex.femmina
      ..neutered = neutered;
    bool anyLevel(List<HealthAlert> a, AlertLevel l) =>
        a.any((x) => x.level == l);

    test('nessuna pipì da 25 ore → subito', () {
      final a = run([e(LogType.pipi, const Duration(hours: 25))]);
      expect(a.first.level, AlertLevel.subito);
    });
    test('maschio: UN solo sforzo a urinare → subito (ostruzione)', () {
      final a = run([
        e(LogType.pipi, const Duration(hours: 1), signs: {Sign.sforzo}),
      ]);
      expect(a.first.level, AlertLevel.subito);
    });
    test('femmina: uno sforzo → attenzione, due → oggi', () {
      final one = run([
        e(LogType.pipi, const Duration(hours: 1), signs: {Sign.sforzo}),
      ], dog: female());
      expect(one.first.level, AlertLevel.attenzione);
      final two = run([
        e(LogType.pipi, const Duration(hours: 1), signs: {Sign.sforzo}),
        e(LogType.pipi, const Duration(hours: 2), signs: {Sign.gocce}),
      ], dog: female());
      expect(two.first.level, AlertLevel.oggi);
    });
    test('nessuna pipì da 14 ore anche senza altri eventi registrati', () {
      final a = run([e(LogType.pipi, const Duration(hours: 14))]);
      expect(a.any((x) => x.title.contains('Nessuna pipì')), isTrue);
    });
    test('conati a vuoto → subito (torsione gastrica)', () {
      final a = run([
        e(LogType.vomito, const Duration(minutes: 20), signs: {Sign.conati}),
      ]);
      expect(a.first.level, AlertLevel.subito);
    });
    test('feci nere in terapia con FANS → subito', () {
      final a = AlertEngine.compute(
        dog: _dog(),
        logs: [
          e(LogType.cacca, const Duration(hours: 2), signs: {Sign.nero}),
        ],
        records: [
          HealthRecord(
            id: 'm',
            dogId: 'd',
            type: RecordType.farmaco,
            title: 'Meloxicam',
            date: now.subtract(const Duration(days: 2)),
            everyHours: 24,
            endDate: now.add(const Duration(days: 3)),
          ),
        ],
        weights: const [],
        now: now,
      );
      expect(a.first.level, AlertLevel.subito);
    });
    test('cucciolo con diarrea ripetuta → oggi', () {
      final a = run([
        e(LogType.cacca, const Duration(hours: 1), signs: {Sign.diarrea}),
        e(LogType.cacca, const Duration(hours: 3), signs: {Sign.diarrea}),
      ], dog: _dog(kg: 4, ageMonths: 3));
      expect(anyLevel(a, AlertLevel.oggi), isTrue);
    });
    test('piometra: femmina intera dopo il calore con vomito → oggi', () {
      final d = female(neutered: false)
        ..reproState = ReproState.calore
        ..reproSince = now.subtract(const Duration(days: 40));
      final a = run([e(LogType.vomito, const Duration(hours: 3))], dog: d);
      expect(a.any((x) => x.title.contains('piometra')), isTrue);
    });
    test('diario normale → nessun allarme', () {
      final a = run([
        e(LogType.pipi, const Duration(hours: 2)),
        e(LogType.cacca, const Duration(hours: 5)),
      ]);
      expect(a.where((x) => x.level != AlertLevel.info), isEmpty);
    });
  });

  group('Prevenzione (revisione veterinaria)', () {
    test('a novembre non propone di iniziare la filariosi', () {
      final s = PreventionPlanner.suggest(_dog(), const [], now);
      expect(
        s.any((r) => r.title.startsWith('Prevenzione filariosi')),
        isFalse,
      );
      expect(
        s.any((r) => r.title.contains('Inizio profilassi filariosi 2027')),
        isTrue,
      );
    });
    test('vaccino leishmania: richiamo annuale', () {
      final r = HealthRecord(
        id: 'l',
        dogId: 'd',
        type: RecordType.vaccino,
        title: 'Leishmaniosi',
        date: now,
      );
      expect(PreventionPlanner.suggestedInterval(r)!.inDays, 365);
    });
    test('leptospirosi: 1ª dose nessuna scadenza fissa, 2ª dose → richiamo annuale', () {
      HealthRecord r(String t) => HealthRecord(
        id: 'l',
        dogId: 'd',
        type: RecordType.vaccino,
        title: t,
        date: now,
      );
      expect(
        PreventionPlanner.suggestedInterval(r('Leptospirosi – 1ª dose')),
        isNull,
      );
      expect(
        PreventionPlanner.suggestedInterval(r('Leptospirosi – 2ª dose'))!
            .inDays,
        365,
      );
    });
    test('sverminazione: ogni 14 giorni sotto le 10 settimane', () {
      final pup = _dog(kg: 3, ageMonths: 2);
      final r = HealthRecord(
        id: 's',
        dogId: 'd',
        type: RecordType.antiparassitario,
        title: 'Sverminazione cucciolo',
        date: now,
      );
      expect(PreventionPlanner.suggestedInterval(r, dog: pup)!.inDays, 14);
    });
  });

  group('Nutrizione (revisione veterinaria)', () {
    test('cucciolo toy: pasti automatici = 5', () {
      expect(Nutrition.plan(_dog(kg: 2, ageMonths: 2), now).meals, 5);
    });
    test('allattamento: cibo a disposizione', () {
      final d = _dog()
        ..sex = Sex.femmina
        ..reproState = ReproState.allattamento
        ..reproSince = now.subtract(const Duration(days: 10));
      final p = Nutrition.plan(d, now);
      expect(p.freeFeeding, isTrue);
      expect(p.factor, greaterThanOrEqualTo(4));
    });
  });

  test('microchip: 15 cifre', () {
    expect(microchipProblem('380260000123456'), isNull);
    expect(microchipProblem('12345'), isNotNull);
  });

  test('persistenza: salva e ricarica', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s1 = AppStore(prefs: prefs);
    await s1.load();
    await s1.loadDemo();
    final s2 = AppStore(prefs: prefs);
    await s2.load();
    expect(s2.dogs.single.name, 'Luna');
    expect(s2.logs.length, s1.logs.length);
    expect(s2.records.length, s1.records.length);
  });

  testWidgets('l\'app si apre con il cane di esempio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(prefs: await SharedPreferences.getInstance());
    await store.load();
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    await tester.pumpWidget(ZampaApp(store: store));
    expect(find.text('Prima di iniziare'), findsOneWidget);
    await tester.tap(find.text('Ho letto e ho capito'));
    await tester.pump();
    await tester.tap(find.text('Continua'));
    await tester.runAsync(() async {});
    await tester.pump();
    expect(find.text('Prova con un cane di esempio'), findsOneWidget);
    await tester.runAsync(store.loadDemo);
    await tester.pump();
    expect(find.text('Luna'), findsWidgets);
    expect(find.text('Prossima pipì'), findsOneWidget);
    expect(find.text('ESEMPIO'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Prossima cacca'),
      300,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    expect(find.text('Prossima cacca'), findsOneWidget);
    for (final tab in ['Bisogni', 'Salute', 'Nutrizione', 'Profilo']) {
      await tester.tap(find.text(tab));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}
