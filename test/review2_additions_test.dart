import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/logic/seasonal.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/pdf_export.dart';

/// Aggiunte di priorità media e bassa della revisione 07.
final now = DateTime(2026, 7, 10, 15);

Dog dog({
  String breed = '',
  double kg = 20,
  bool neutered = true,
  int ageMonths = 48,
}) => Dog(
  id: 'd',
  name: 'Fido',
  birthDate: now.subtract(Duration(days: (ageMonths * 30.44).round())),
  sex: Sex.maschio,
  neutered: neutered,
  weightKg: kg,
  breed: breed,
);

LogEntry e(LogType t, Duration ago, {Set<Sign> signs = const {}}) => LogEntry(
  id: '$t$ago',
  dogId: 'd',
  type: t,
  time: now.subtract(ago),
  signs: signs,
);

HealthRecord surgery(Duration ago) => HealthRecord(
  id: 's',
  dogId: 'd',
  type: RecordType.intervento,
  title: 'Sterilizzazione',
  date: now.subtract(ago),
);

List<HealthAlert> run(
  List<LogEntry> logs, {
  Dog? d,
  List<HealthRecord> records = const [],
}) => AlertEngine.compute(
  dog: d ?? dog(),
  logs: logs,
  records: records,
  weights: const [],
  now: now,
);

void main() {
  // Il PDF carica Atkinson dagli asset (C2-9).
  TestWidgetsFlutterBinding.ensureInitialized();
  test('N8 ferita con punti aperti → oggi; arrossata → attenzione', () {
    final r = [surgery(const Duration(days: 3))];
    expect(
      run([
        e(LogType.ferita, const Duration(hours: 1), signs: {Sign.deiscenza}),
      ], records: r).first.level,
      AlertLevel.oggi,
    );
    expect(
      run([
        e(LogType.pasto, const Duration(hours: 5)),
        e(LogType.ferita, const Duration(hours: 1), signs: {Sign.arrossamento}),
      ], records: r).first.level,
      AlertLevel.attenzione,
    );
  });
  test('N8 nessun pasto 2 giorni dopo l\'intervento → oggi', () {
    final a = run(
      [e(LogType.pipi, const Duration(hours: 2))],
      records: [surgery(const Duration(hours: 60))],
    );
    expect(
      a.any((x) => x.title.contains('mangiato dopo l\'intervento')),
      isTrue,
    );
  });
  test('N9 starnuti violenti a luglio → forasacco oggi', () {
    final a = run([
      e(LogType.pelle, const Duration(hours: 1), signs: {Sign.starnuti}),
    ]);
    expect(
      a.any(
        (x) => x.title == 'Possibile forasacco' && x.level == AlertLevel.oggi,
      ),
      isTrue,
    );
  });
  test('N12 consiglio leptospirosi in estate; N13 freddo in inverno', () {
    expect(
      SeasonalTips.forDog(
        dog(),
        now,
      ).any((t) => t.title.contains('leptospirosi')),
      isTrue,
    );
    expect(
      SeasonalTips.forDog(
        dog(),
        DateTime(2027, 1, 10),
      ).any((t) => t.title == 'Freddo'),
      isTrue,
    );
  });
  test('N17 predisposizioni: Dobermann cuore, Yorkshire trachea', () {
    expect(
      Breeds.predispositions(dog(breed: 'Dobermann'))
          .any((t) => t.title.contains('cuore')),
      isTrue,
    );
    expect(
      Breeds.predispositions(dog(breed: 'Yorkshire terrier', kg: 3))
          .any((t) => t.title.contains('trachea')),
      isTrue,
    );
  });
  test(
    'N18 informazione sterilizzazione solo per grandi taglie intere giovani',
    () {
      expect(
        Breeds.neuteringInfo(dog(kg: 30, neutered: false, ageMonths: 10), now),
        isNotNull,
      );
      expect(
        Breeds.neuteringInfo(dog(kg: 8, neutered: false, ageMonths: 10), now),
        isNull,
      );
    },
  );
  test('N14 PDF con conferme delle dosi', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(prefs: await SharedPreferences.getInstance());
    await s.load();
    await s.loadDemo();
    final d = s.dog!;
    final r = s.records.firstWhere((x) => x.type == RecordType.farmaco);
    await s.confirmDose(
      r,
      DateTime.now().subtract(const Duration(hours: 1)),
      DoseStatus.dato,
    );
    final bytes = await buildPdf(s, d, DateTime.now());
    expect(bytes.length, greaterThan(2000));
  });
}
