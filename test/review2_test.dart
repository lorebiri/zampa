import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';
import 'package:zampa/models.dart';

/// Regole introdotte dalla seconda revisione veterinaria (ricerca/07).
final now = DateTime(2026, 11, 10, 15);

Dog dog({
  Sex sex = Sex.maschio,
  bool neutered = true,
  double kg = 20,
  int ageMonths = 48,
  String cond = '',
  String breed = '',
}) => Dog(
  id: 'd',
  name: 'Fido',
  birthDate: now.subtract(Duration(days: (ageMonths * 30.44).round())),
  sex: sex,
  neutered: neutered,
  weightKg: kg,
  conditions: cond,
  breed: breed,
);

LogEntry e(
  LogType t,
  Duration ago, {
  Set<Sign> signs = const {},
  double? value,
}) => LogEntry(
  id: '$t$ago$signs',
  dogId: 'd',
  type: t,
  time: now.subtract(ago),
  signs: signs,
  value: value,
);

List<HealthAlert> run(
  List<LogEntry> logs, {
  Dog? d,
  List<HealthRecord> records = const [],
  List<ReproEvent> repro = const [],
}) => AlertEngine.compute(
  dog: d ?? dog(),
  logs: logs,
  records: records,
  weights: const [],
  now: now,
  repro: repro,
);

HealthRecord drug(String title) => HealthRecord(
  id: title,
  dogId: 'd',
  type: RecordType.farmaco,
  title: title,
  date: now.subtract(const Duration(days: 2)),
  everyHours: 24,
  endDate: now.add(const Duration(days: 5)),
);

void main() {
  test('N1 cucciolo con 1 vomito + 1 diarrea → oggi (non più solo info)', () {
    final a = run([
      e(LogType.vomito, const Duration(hours: 2)),
      e(LogType.cacca, const Duration(hours: 3), signs: {Sign.diarrea}),
    ], d: dog(kg: 6, ageMonths: 4));
    expect(a.first.level, AlertLevel.oggi);
    expect(a.any((x) => x.title == 'Ha vomitato una volta'), isFalse);
  });
  test('N2 glicemia 50 mg/dL → subito', () {
    final a = run([
      e(LogType.glicemia, const Duration(hours: 1), value: 50),
    ], d: dog(cond: 'diabete'));
    expect(a.first.level, AlertLevel.subito);
  });
  test('N3 cagna che allatta con tremori → subito (eclampsia)', () {
    final d = dog(sex: Sex.femmina, neutered: false)
      ..reproState = ReproState.allattamento
      ..reproSince = now.subtract(const Duration(days: 15));
    final a = run([e(LogType.neuro, const Duration(minutes: 30))], d: d);
    expect(a.first.title, contains('allatta'));
    expect(a.first.level, AlertLevel.subito);
  });
  test('N3 cucciolo toy abbattuto → subito (ipoglicemia)', () {
    final a = run([
      e(LogType.abbattimento, const Duration(minutes: 30)),
    ], d: dog(kg: 1.5, ageMonths: 3));
    expect(a.first.level, AlertLevel.subito);
  });
  test(
    'N4 diabetico con vomito → oggi; con vomito e abbattimento → subito',
    () {
      expect(
        run([
          e(LogType.vomito, const Duration(hours: 1)),
        ], d: dog(cond: 'diabete')).first.level,
        AlertLevel.oggi,
      );
      expect(
        run([
          e(LogType.vomito, const Duration(hours: 1)),
          e(LogType.abbattimento, const Duration(hours: 1)),
        ], d: dog(cond: 'diabete')).first.level,
        AlertLevel.subito,
      );
    },
  );
  test('N5 una pipì "a gocce" non azzera l\'anuria', () {
    final a = run([
      e(LogType.pipi, const Duration(hours: 26)),
      e(LogType.pipi, const Duration(hours: 1), signs: {Sign.gocce}),
    ], d: dog(sex: Sex.femmina));
    expect(a.any((x) => x.title.startsWith('Nessuna pipì da')), isTrue);
  });
  test('N9 cucciolo: la notte non conta per le 8 ore', () {
    // Ultima pipì alle 22 di ieri, ora sono le 9: sveglio da 2 ore.
    final d = dog(kg: 5, ageMonths: 5);
    final logs = [
      LogEntry(
        id: 'p',
        dogId: 'd',
        type: LogType.pipi,
        time: DateTime(2026, 11, 9, 22),
      ),
    ];
    final a = AlertEngine.compute(
      dog: d,
      logs: logs,
      records: const [],
      weights: const [],
      now: DateTime(2026, 11, 10, 9),
    );
    expect(a.any((x) => x.title.startsWith('Cucciolo senza pipì')), isFalse);
  });
  test('N11 nomi commerciali: Metacam = FANS, Vetoryl = trilostano', () {
    expect(DrugEffectLabel.guess('Metacam 1,5 mg/ml'), DrugEffect.fans);
    expect(DrugEffectLabel.guess('Vetoryl 30 mg'), DrugEffect.trilostano);
    final a = run(
      [e(LogType.vomito, const Duration(hours: 2))],
      records: [drug('Vetoryl')],
    );
    expect(a.first.level, AlertLevel.subito);
  });
  test('N12 gengive rosso scuro → subito', () {
    expect(
      run([
        e(
          LogType.gengive,
          const Duration(minutes: 5),
          signs: {Sign.gengiveRosse},
        ),
      ]).first.level,
      AlertLevel.subito,
    );
  });
  test('N14 respiri 44 in un cane sano → oggi (rimisura), in un cardiopatico → subito', () {
    expect(
      run([e(LogType.respiro, const Duration(minutes: 10), value: 44)])
          .first
          .level,
      AlertLevel.oggi,
    );
    expect(
      run([
        e(LogType.respiro, const Duration(minutes: 10), value: 44),
      ], d: dog(cond: 'cardiopatia mitralica')).first.level,
      AlertLevel.subito,
    );
  });
  test('N6 femmina intera senza calori registrati con 2 segni → oggi', () {
    final a = run([
      e(LogType.vomito, const Duration(hours: 2)),
      e(LogType.inappetenza, const Duration(hours: 3)),
    ], d: dog(sex: Sex.femmina, neutered: false));
    expect(
      a.any((x) => x.title.contains('utero') && x.level == AlertLevel.oggi),
      isTrue,
    );
  });
  test('N19 ingestione di 2 giorni fa → sorveglianza', () {
    final a = run([e(LogType.ingestione, const Duration(days: 2))]);
    expect(a.any((x) => x.title.startsWith('Sorveglianza')), isTrue);
  });
  test('aggiunta N2: doppia insulina ravvicinata → subito', () {
    final a = run([
      e(LogType.insulina, const Duration(hours: 3), value: 5),
      e(LogType.insulina, const Duration(minutes: 20), value: 5),
    ], d: dog(cond: 'diabete'));
    expect(a.first.title, contains('insulina'));
    expect(a.first.level, AlertLevel.subito);
  });
  test('aggiunta N4: collasso → subito', () {
    expect(
      run([e(LogType.collasso, const Duration(minutes: 5))]).first.level,
      AlertLevel.subito,
    );
  });
  test('N25 a parità di livello prima la torsione gastrica', () {
    final a = run([
      e(LogType.ingestione, const Duration(minutes: 30)),
      e(LogType.addomeGonfio, const Duration(minutes: 10)),
    ]);
    expect(a.first.title, contains('Conati'));
  });
  test('N8 tetto superato → uscita adesso', () {
    final d = dog();
    final logs = [
      LogEntry(
        id: 'p',
        dogId: 'd',
        type: LogType.pipi,
        time: now.subtract(const Duration(hours: 9)),
      ),
    ];
    final f = EliminationModel()
        .fit(d, Need.pipi, logs, const [], now)
        .forecast(now, withAccuracy: false);
    expect(f.recommendedAt.difference(now).inMinutes.abs(), lessThan(2));
  });
}
