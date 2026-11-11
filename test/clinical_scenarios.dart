// Scenari che fanno scattare ogni regola clinica e ogni variante di testo.
// Usati dal test d'identità dei testi (clinical_texts_snapshot_test.dart) e
// dal controllo di copertura del catalogo (l10n_catalog_test.dart).
import 'package:zampa/models.dart';

final baseNow = DateTime(2026, 11, 10, 15);

class Scenario {
  Scenario(
    this.name, {
    Dog? dog,
    this.logs = const [],
    this.records = const [],
    this.weights = const [],
    this.repro = const [],
    this.pending = const [],
    DateTime? now,
  }) : dog = dog ?? mkDog(),
       now = now ?? baseNow;
  final String name;
  final Dog dog;
  final List<LogEntry> logs;
  final List<HealthRecord> records;
  final List<WeightEntry> weights;
  final List<ReproEvent> repro;
  final List<({HealthRecord record, DateTime at})> pending;
  final DateTime now;
}

Dog mkDog({
  Sex sex = Sex.maschio,
  bool neutered = true,
  DateTime? birth,
  double kg = 20,
  String breed = '',
  String cond = '',
  int bcs = 5,
  DietType diet = DietType.secco,
  ReproState repro = ReproState.nessuno,
  DateTime? reproSince,
  Region region = Region.centro,
  String microchip = '',
  int meals = 0,
  ActivityLevel activity = ActivityLevel.normale,
  AdultSize? adultSize,
  double? idealKg,
}) => Dog(
  id: 'd',
  name: 'Fido',
  birthDate: birth ?? DateTime(2022, 1, 1),
  sex: sex,
  neutered: neutered,
  weightKg: kg,
  breed: breed,
  conditions: cond,
  bodyCondition: bcs,
  diet: diet,
  reproState: repro,
  reproSince: reproSince,
  region: region,
  microchip: microchip,
  mealsPerDay: meals,
  activity: activity,
  adultSize: adultSize,
  idealWeightKg: idealKg,
);

Dog female({bool neutered = false, DateTime? birth, double kg = 20}) =>
    mkDog(sex: Sex.femmina, neutered: neutered, birth: birth, kg: kg);

/// Cucciolo di 3 mesi (nato il 10/8/2026).
Dog puppy({double kg = 8, Sex sex = Sex.maschio}) =>
    mkDog(birth: DateTime(2026, 8, 10), kg: kg, sex: sex, neutered: false);

/// Anziano: 12 anni, 20 kg.
Dog senior() => mkDog(birth: DateTime(2014, 1, 1));

var _n = 0;
LogEntry e(
  LogType t,
  Duration ago, {
  Set<Sign> signs = const {},
  double? value,
  String note = '',
  bool indoor = false,
  int? ml,
  DateTime? now,
}) => LogEntry(
  id: 'l${_n++}',
  dogId: 'd',
  type: t,
  time: (now ?? baseNow).subtract(ago),
  signs: signs,
  value: value,
  note: note,
  indoor: indoor,
  amountMl: ml?.toDouble(),
);

Duration h(num x) => Duration(minutes: (x * 60).round());
Duration d(num x) => Duration(minutes: (x * 24 * 60).round());

HealthRecord rec(
  RecordType t,
  String title,
  Duration ago, {
  bool done = true,
  int? everyHours,
  DrugEffect effect = DrugEffect.nessuno,
}) => HealthRecord(
  id: 'r${_n++}',
  dogId: 'd',
  type: t,
  title: title,
  date: baseNow.subtract(ago),
  done: done,
  everyHours: everyHours,
  drugEffect: effect,
);

HealthRecord drug(String title, {DrugEffect effect = DrugEffect.nessuno}) =>
    rec(RecordType.farmaco, title, d(5), everyHours: 24, effect: effect);

ReproEvent rep(ReproEventType t, Duration ago) => ReproEvent(
  id: 'p${_n++}',
  dogId: 'd',
  type: t,
  date: baseNow.subtract(ago),
);

WeightEntry w(Duration ago, double kg) => WeightEntry(
  id: 'w${_n++}',
  dogId: 'd',
  date: baseNow.subtract(ago),
  kg: kg,
);

final _diabetic = mkDog(cond: 'diabete');

List<Scenario> alertScenarios() {
  final s = <Scenario>[];
  void add(
    String name, {
    Dog? dog,
    List<LogEntry> logs = const [],
    List<HealthRecord> records = const [],
    List<WeightEntry> weights = const [],
    List<ReproEvent> repro = const [],
    List<({HealthRecord record, DateTime at})> pending = const [],
    DateTime? now,
  }) => s.add(
    Scenario(
      name,
      dog: dog,
      logs: logs,
      records: records,
      weights: weights,
      repro: repro,
      pending: pending,
      now: now,
    ),
  );
  final pee = LogType.pipi;

  add('nessun dato');
  // Vie urinarie.
  add(
    'maschio, sforzo a urinare',
    logs: [
      e(pee, h(1), signs: {Sign.sforzo}),
    ],
  );
  add(
    'femmina, due sforzi in 24 ore',
    dog: female(),
    logs: [
      e(pee, h(1), signs: {Sign.sforzo}),
      e(pee, h(3), signs: {Sign.gocce}),
    ],
  );
  add(
    'femmina, uno sforzo',
    dog: female(),
    logs: [
      e(pee, h(1), signs: {Sign.sforzo}),
    ],
  );
  add('cucciolo senza pipì da 7 ore', dog: puppy(), logs: [e(pee, h(7))]);
  add('adulto senza pipì da 30 ore', logs: [e(pee, h(30))]);
  add('adulto senza pipì da 14 ore', logs: [e(pee, h(14))]);
  add(
    'maschio, sforzo 14 ore fa e poi niente',
    logs: [
      e(pee, h(14), signs: {Sign.sforzo}),
    ],
  );
  add(
    'senza pipì da 14 ore dopo chirurgia della colonna',
    logs: [e(pee, h(14))],
    records: [rec(RecordType.intervento, 'Ernia del disco', d(5))],
  );
  add(
    'sangue nelle urine con vomito',
    logs: [
      e(pee, h(1), signs: {Sign.sangue}),
      e(LogType.vomito, h(2)),
    ],
  );
  add(
    'sangue durante il calore',
    dog: mkDog(
      sex: Sex.femmina,
      neutered: false,
      repro: ReproState.calore,
      reproSince: baseNow.subtract(d(5)),
    ),
    logs: [
      e(pee, h(1), signs: {Sign.sangue}),
    ],
  );
  add(
    'sangue nelle urine',
    logs: [
      e(pee, h(1), signs: {Sign.sangue}),
    ],
  );
  add(
    'pipì piccole e frequenti',
    logs: [for (var i = 0; i < 4; i++) e(pee, Duration(minutes: 20 + 25 * i))],
  );

  // Gastrointestinale.
  add('addome gonfio', logs: [e(LogType.addomeGonfio, h(1))]);
  add(
    'conati',
    logs: [
      e(LogType.vomito, h(1), signs: {Sign.conati}),
    ],
  );
  add('collasso', logs: [e(LogType.collasso, h(1))]);
  add(
    'cucciolo con vomito e diarrea',
    dog: puppy(),
    logs: [
      e(LogType.vomito, h(1)),
      e(LogType.cacca, h(2), signs: {Sign.diarrea}),
    ],
  );
  add(
    'cucciolo con vomito e diarrea con sangue',
    dog: puppy(),
    logs: [
      e(LogType.vomito, h(1)),
      e(LogType.cacca, h(2), signs: {Sign.diarrea, Sign.sangue}),
    ],
  );
  add('diabetico con vomito', dog: _diabetic, logs: [e(LogType.vomito, h(1))]);
  add(
    'diabetico con vomito e abbattimento',
    dog: _diabetic,
    logs: [e(LogType.vomito, h(1)), e(LogType.abbattimento, h(2))],
  );
  add(
    'Cushing con vomito',
    logs: [e(LogType.vomito, h(1))],
    records: [drug('Vetoryl', effect: DrugEffect.trilostano)],
  );
  add(
    'FANS e inappetenza',
    logs: [e(LogType.inappetenza, h(1))],
    records: [drug('Metacam', effect: DrugEffect.fans)],
  );
  add(
    'FANS e cortisone insieme',
    records: [
      drug('Metacam', effect: DrugEffect.fans),
      drug('Prednisolone', effect: DrugEffect.cortisonico),
    ],
  );
  add(
    'vomito con sangue',
    logs: [
      e(LogType.vomito, h(1), signs: {Sign.sangue}),
    ],
  );
  add(
    'FANS e vomito',
    logs: [e(LogType.vomito, h(1))],
    records: [drug('Metacam', effect: DrugEffect.fans)],
  );
  add(
    'cane piccolo, due vomiti',
    dog: mkDog(kg: 4),
    logs: [e(LogType.vomito, h(1)), e(LogType.vomito, h(3))],
  );
  add(
    'tre vomiti',
    logs: [
      e(LogType.vomito, h(1)),
      e(LogType.vomito, h(3)),
      e(LogType.vomito, h(5)),
    ],
  );
  add('un vomito', logs: [e(LogType.vomito, h(1))]);
  add(
    'feci nere con FANS',
    logs: [
      e(LogType.cacca, h(1), signs: {Sign.nero}),
    ],
    records: [drug('Metacam', effect: DrugEffect.fans)],
  );
  add(
    'feci nere',
    logs: [
      e(LogType.cacca, h(1), signs: {Sign.nero}),
    ],
  );
  add(
    'cucciolo con sangue nelle feci',
    dog: puppy(),
    logs: [
      e(LogType.cacca, h(1), signs: {Sign.sangue}),
    ],
  );
  add(
    'sangue nelle feci con vomito',
    logs: [
      e(LogType.cacca, h(1), signs: {Sign.sangue}),
      e(LogType.vomito, h(2)),
    ],
  );
  add(
    'sangue nelle feci',
    logs: [
      e(LogType.cacca, h(1), signs: {Sign.sangue}),
    ],
  );
  add(
    'cucciolo con diarrea',
    dog: puppy(),
    logs: [
      e(LogType.cacca, h(1), signs: {Sign.diarrea}),
      e(LogType.cacca, h(3), signs: {Sign.diarrea}),
    ],
  );
  add(
    'tre diarree',
    logs: [
      for (var i = 0; i < 3; i++)
        e(LogType.cacca, h(1 + 2 * i), signs: {Sign.diarrea}),
    ],
  );
  add(
    'diarrea e vomito',
    logs: [
      e(LogType.cacca, h(1), signs: {Sign.diarrea}),
      e(LogType.vomito, h(2)),
    ],
  );
  add('nessuna cacca da 50 ore', logs: [e(LogType.cacca, h(50)), e(pee, h(1))]);
  add('nessuna cacca da 80 ore', logs: [e(LogType.cacca, h(80)), e(pee, h(1))]);
  add('feci molto dure', logs: [e(LogType.cacca, h(1), value: 1)]);

  // Frequenza della pipì e acqua.
  List<LogEntry> moreUrine() => [
    for (var day = 4; day <= 17; day++)
      for (final hr in [8, 18]) e(pee, d(day) - h(hr - 15)),
    for (var day = 1; day <= 3; day++)
      for (final hr in [7, 10, 12, 14, 16, 19]) e(pee, d(day) - h(hr - 15)),
  ];
  add('fa pipì più spesso', logs: moreUrine());
  add('diabetico, fa pipì più spesso', dog: _diabetic, logs: moreUrine());
  add(
    'beve molto',
    logs: [
      for (var day = 1; day <= 3; day++) e(LogType.acqua, d(day), ml: 2500),
    ],
  );
  add(
    'beve poco con le crocchette',
    logs: [
      for (var day = 1; day <= 3; day++) e(LogType.acqua, d(day), ml: 200),
    ],
  );

  // Utero.
  add(
    'piometra dopo il calore',
    dog: female(),
    logs: [e(LogType.vomito, h(1))],
    repro: [rep(ReproEventType.calore, d(30))],
  );
  add(
    'femmina intera, un segno',
    dog: female(),
    logs: [e(LogType.vomito, h(1))],
  );
  add(
    'femmina intera, due segni',
    dog: female(),
    logs: [e(LogType.vomito, h(1)), e(LogType.inappetenza, h(2))],
  );

  add(
    'pipì in casa ripetute',
    logs: [e(pee, d(1), indoor: true), e(pee, d(2), indoor: true)],
  );

  // Peso.
  add(
    'il cucciolo non cresce',
    dog: puppy(),
    weights: [w(d(20), 8), w(d(1), 8)],
  );
  add(
    'dimagrisce troppo in fretta',
    dog: mkDog(bcs: 7),
    weights: [w(d(14), 22), w(d(1), 20)],
  );
  add('calo di peso del 12%', weights: [w(d(60), 20), w(d(1), 17.6)]);
  add('calo di peso del 6%', weights: [w(d(60), 20), w(d(1), 18.8)]);
  add('aumento di peso del 12%', weights: [w(d(60), 20), w(d(1), 22.4)]);
  add('sottopeso', dog: mkDog(bcs: 3));
  add('sovrappeso', dog: mkDog(bcs: 8));
  add('leggermente sovrappeso', dog: mkDog(bcs: 6));

  // Ingestione.
  add(
    'ha ingerito cioccolato',
    logs: [e(LogType.ingestione, h(1), note: 'cioccolato')],
  );
  add('ha ingerito qualcosa', logs: [e(LogType.ingestione, h(1))]);
  add(
    'sorveglianza dopo ingestione con nota',
    logs: [e(LogType.ingestione, d(2), note: 'topicida')],
  );
  add('sorveglianza dopo ingestione', logs: [e(LogType.ingestione, d(2))]);

  // Gengive e respiro.
  add(
    'gengive pallide',
    logs: [
      e(LogType.gengive, h(1), signs: {Sign.gengivePallide}),
    ],
  );
  add(
    'gengive rosse',
    logs: [
      e(LogType.gengive, h(1), signs: {Sign.gengiveRosse}),
    ],
  );
  add(
    'gengive gialle',
    logs: [
      e(LogType.gengive, h(1), signs: {Sign.gengiveGialle}),
    ],
  );
  add(
    'cardiopatico, 44 respiri',
    dog: mkDog(cond: 'cardiopatia'),
    logs: [e(LogType.respiro, h(1), value: 44)],
  );
  add('44 respiri', logs: [e(LogType.respiro, h(1), value: 44)]);
  add(
    'due misure sopra 30',
    logs: [
      e(LogType.respiro, h(5), value: 34),
      e(LogType.respiro, h(1), value: 33),
    ],
  );
  add(
    'respiri in aumento',
    logs: [
      e(LogType.respiro, d(20), value: 20),
      e(LogType.respiro, d(10), value: 22),
      e(LogType.respiro, d(4), value: 31),
      e(LogType.respiro, h(1), value: 32),
    ],
  );
  add(
    'fatica a respirare',
    logs: [
      e(LogType.tosse, h(1), signs: {Sign.dispnea}),
    ],
  );
  add(
    'tosse in un cardiopatico',
    dog: mkDog(cond: 'cardiopatia'),
    logs: [e(LogType.tosse, h(1))],
  );
  add(
    'tosse in un Cavalier',
    dog: mkDog(breed: 'Cavalier King', kg: 8),
    logs: [e(LogType.tosse, h(1))],
  );
  add(
    'tosse da più giorni',
    logs: [e(LogType.tosse, d(4)), e(LogType.tosse, h(1))],
  );

  // Diabete.
  add(
    'glicemia 50',
    dog: _diabetic,
    logs: [e(LogType.glicemia, h(1), value: 50)],
  );
  add(
    'glicemia 70',
    dog: _diabetic,
    logs: [e(LogType.glicemia, h(1), value: 70)],
  );
  add(
    'glicemia 450',
    dog: _diabetic,
    logs: [e(LogType.glicemia, h(1), value: 450)],
  );
  add(
    'glicemia 450 e non mangia',
    logs: [e(LogType.glicemia, h(1), value: 450), e(LogType.inappetenza, h(2))],
  );
  add(
    'due dosi di insulina ravvicinate',
    dog: _diabetic,
    logs: [e(LogType.insulina, h(3)), e(LogType.insulina, h(1))],
  );
  add(
    'insulina senza pasto',
    dog: _diabetic,
    logs: [
      e(LogType.insulina, h(1), signs: {Sign.nonHaMangiato}),
    ],
  );

  // Neurologico.
  add(
    'cagna che allatta trema',
    dog: mkDog(
      sex: Sex.femmina,
      neutered: false,
      repro: ReproState.allattamento,
      reproSince: baseNow.subtract(d(10)),
    ),
    logs: [e(LogType.neuro, h(1))],
  );
  add('cucciolo che trema', dog: puppy(kg: 3), logs: [e(LogType.neuro, h(1))]);
  add(
    'convulsione in un diabetico',
    dog: _diabetic,
    logs: [e(LogType.convulsione, h(1), value: 2)],
  );
  add('convulsione lunga', logs: [e(LogType.convulsione, h(1), value: 6)]);
  add(
    'due convulsioni',
    logs: [
      e(LogType.convulsione, h(1), value: 2),
      e(LogType.convulsione, h(5), value: 2),
    ],
  );
  add('prima convulsione', logs: [e(LogType.convulsione, h(1), value: 2)]);
  add(
    'crisi più frequenti questo mese',
    logs: [
      e(LogType.convulsione, d(90)),
      e(LogType.convulsione, d(60)),
      e(LogType.convulsione, d(35)),
      e(LogType.convulsione, d(3)),
      e(LogType.convulsione, d(5)),
      e(LogType.convulsione, d(7)),
    ],
  );
  add('diabetico che trema', dog: _diabetic, logs: [e(LogType.neuro, h(1))]);
  add('tremori', logs: [e(LogType.neuro, h(1))]);
  add(
    'tremori improvvisi',
    logs: [
      e(LogType.neuro, h(1), signs: {Sign.improvviso}),
    ],
  );

  // Temperatura.
  add('41,2 °C', logs: [e(LogType.temperatura, h(1), value: 41.2)]);
  add('36,5 °C', logs: [e(LogType.temperatura, h(1), value: 36.5)]);
  add('39,8 °C', logs: [e(LogType.temperatura, h(1), value: 39.8)]);

  // Appetito e abbattimento.
  add(
    'diabetico non mangia',
    dog: _diabetic,
    logs: [e(LogType.inappetenza, h(1))],
  );
  add(
    'anziano non mangia',
    dog: senior(),
    logs: [e(LogType.inappetenza, h(1))],
  );
  add(
    'ha saltato i pasti',
    logs: [e(LogType.inappetenza, h(1)), e(LogType.inappetenza, h(8))],
  );
  add(
    'abbattuto con altri segni',
    logs: [
      e(LogType.abbattimento, h(1)),
      e(LogType.cacca, h(2), signs: {Sign.diarrea}),
    ],
  );
  add(
    'cucciolo abbattuto',
    dog: puppy(kg: 8),
    logs: [e(LogType.abbattimento, h(1))],
  );
  add(
    'anziano abbattuto',
    dog: senior(),
    logs: [e(LogType.abbattimento, h(1))],
  );
  add('abbattuto', logs: [e(LogType.abbattimento, h(1))]);

  // Urina scura (con e senza stagione delle zecche).
  add(
    'urina scura',
    logs: [
      e(pee, h(1), signs: {Sign.urinaScura}),
    ],
  );
  add(
    'urina scura e abbattimento',
    logs: [
      e(pee, h(1), signs: {Sign.urinaScura}),
      e(LogType.abbattimento, h(2)),
    ],
  );
  final dec = DateTime(2026, 12, 15, 15);
  add(
    'urina scura a dicembre',
    now: dec,
    logs: [
      e(pee, h(1), signs: {Sign.urinaScura}, now: dec),
    ],
  );
  add(
    'urina scura e febbre a dicembre',
    now: dec,
    logs: [
      e(pee, h(1), signs: {Sign.urinaScura}, now: dec),
      e(LogType.temperatura, h(2), value: 39.8, now: dec),
    ],
  );

  add(
    'loperamide in un Border Collie',
    dog: mkDog(breed: 'Border Collie'),
    records: [drug('Imodium', effect: DrugEffect.antidiarroico)],
  );

  // Riproduzione.
  add(
    'febbre dopo il parto',
    dog: female(),
    logs: [e(LogType.temperatura, h(1), value: 39.8)],
    repro: [rep(ReproEventType.parto, d(3))],
  );
  add('mammelle', dog: female(), logs: [e(LogType.mammelle, h(1))]);
  add(
    'temperatura calata, parto atteso',
    dog: female(),
    logs: [e(LogType.temperatura, h(5), value: 37.2)],
    repro: [rep(ReproEventType.accoppiamento, d(60))],
  );
  add(
    'perdite purulente',
    dog: female(),
    logs: [
      e(LogType.perditeVulvari, h(1), signs: {Sign.pus}),
    ],
  );
  add(
    'sterilizzata con perdite',
    dog: female(neutered: true),
    logs: [e(LogType.perditeVulvari, h(1))],
  );
  add(
    'sterilizzata con perdite purulente',
    dog: female(neutered: true),
    logs: [
      e(LogType.perditeVulvari, h(1), signs: {Sign.pus}),
    ],
  );
  add(
    'gravidanza oltre i 70 giorni',
    dog: female(),
    repro: [rep(ReproEventType.accoppiamento, d(75))],
  );
  add(
    'parto vicino',
    dog: female(),
    repro: [rep(ReproEventType.accoppiamento, d(60))],
  );
  add(
    'calore lungo',
    dog: female(),
    repro: [rep(ReproEventType.calore, d(35))],
  );

  // Arti, pelle, denti, perdite.
  add(
    'non appoggia la zampa',
    logs: [
      e(LogType.zoppia, h(1), signs: {Sign.nonCarica}),
    ],
  );
  add(
    'zoppia da più giorni',
    logs: [e(LogType.zoppia, d(4)), e(LogType.zoppia, h(1))],
  );
  add('prurito', logs: [e(LogType.pelle, h(1))]);
  add(
    'denti',
    logs: [
      e(LogType.denti, h(1), signs: {Sign.alitosi}),
    ],
  );
  add(
    'spazzolature',
    logs: [
      e(LogType.denti, h(1), signs: {Sign.spazzolati}),
    ],
  );
  add('perdite a riposo', logs: [e(LogType.perditaRiposo, h(1))]);
  add(
    'pipì di notte',
    logs: [
      e(pee, d(16)),
      e(pee, d(1) + h(12)), // ieri alle 3
      e(pee, d(2) + h(12)),
    ],
  );

  // Dosi, ferite, intervento.
  final pending = rec(RecordType.farmaco, 'Metacam', d(5), everyHours: 24);
  add(
    'dose non confermata',
    pending: [(record: pending, at: baseNow.subtract(h(3)))],
  );
  add(
    'ferita aperta',
    logs: [
      e(LogType.ferita, h(1), signs: {Sign.deiscenza}),
    ],
  );
  add(
    'ferita arrossata',
    logs: [
      e(LogType.ferita, h(1), signs: {Sign.arrossamento}),
    ],
  );
  add(
    'non mangia dopo l\'intervento',
    logs: [e(pee, h(1))],
    records: [rec(RecordType.intervento, 'Sterilizzazione', d(3))],
  );
  final june = DateTime(2026, 6, 15, 15);
  add(
    'forasacco',
    now: june,
    logs: [
      e(LogType.pelle, h(1), signs: {Sign.starnuti}, now: june),
    ],
  );

  // Scadenze.
  add(
    'cucciolo con vaccino core scaduto',
    dog: puppy(),
    records: [
      rec(RecordType.vaccino, 'Vaccino core – 2ª dose', d(3), done: false),
    ],
  );
  add(
    'tre scadenze superate',
    records: [
      rec(RecordType.vaccino, 'Leptospirosi', d(3), done: false),
      rec(RecordType.visita, 'Visita di controllo annuale', d(4), done: false),
      rec(RecordType.esame, 'Esame delle feci', d(5), done: false),
    ],
  );
  return s;
}

List<Scenario> preventionScenarios() => [
  Scenario(
    'cucciolo di 4 settimane, nord',
    dog: mkDog(
      birth: DateTime(2026, 10, 13),
      region: Region.nord,
      neutered: false,
    ),
  ),
  Scenario(
    'cucciolo di 3 mesi, sud',
    dog: mkDog(
      birth: DateTime(2026, 8, 10),
      region: Region.sud,
      neutered: false,
    ),
  ),
  Scenario(
    'adulto senza libretto, con microchip',
    dog: mkDog(microchip: '380260000000001'),
  ),
  Scenario('anziano', dog: senior()),
  Scenario(
    'adulto a giugno, vaccinato',
    dog: mkDog(region: Region.sud),
    now: DateTime(2026, 6, 10, 15),
    records: [
      rec(RecordType.vaccino, 'Vaccino core', d(100)),
      rec(RecordType.vaccino, 'Leptospirosi', d(100)),
    ],
  ),
  Scenario(
    'giovane di 8 mesi a marzo',
    dog: mkDog(birth: DateTime(2025, 7, 1)),
    now: DateTime(2026, 3, 10, 15),
  ),
];

List<Scenario> nutritionScenarios() => [
  Scenario('adulto sterilizzato', dog: mkDog()),
  Scenario('adulto non sterilizzato', dog: mkDog(neutered: false)),
  Scenario('anziano', dog: senior()),
  Scenario('sedentario', dog: mkDog(activity: ActivityLevel.bassa)),
  Scenario('molto attivo', dog: mkDog(activity: ActivityLevel.alta)),
  Scenario('da lavoro', dog: mkDog(activity: ActivityLevel.lavoro)),
  Scenario('sovrappeso', dog: mkDog(bcs: 8)),
  Scenario('sovrappeso con patologie', dog: mkDog(bcs: 8, cond: 'artrosi')),
  Scenario('sottopeso', dog: mkDog(bcs: 3)),
  Scenario(
    'cucciolo di 2 mesi, toy, 2 pasti',
    dog: mkDog(birth: DateTime(2026, 9, 10), kg: 1.5, meals: 2),
  ),
  Scenario(
    'cucciolo di 5 mesi, taglia grande',
    dog: mkDog(
      birth: DateTime(2026, 6, 10),
      kg: 20,
      adultSize: AdultSize.grande,
    ),
  ),
  Scenario(
    'gravidanza iniziale',
    dog: mkDog(
      sex: Sex.femmina,
      neutered: false,
      repro: ReproState.gravidanza,
      reproSince: baseNow.subtract(d(20)),
    ),
  ),
  Scenario(
    'gravidanza avanzata',
    dog: mkDog(
      sex: Sex.femmina,
      neutered: false,
      repro: ReproState.gravidanza,
      reproSince: baseNow.subtract(d(50)),
    ),
  ),
  Scenario(
    'allattamento',
    dog: mkDog(
      sex: Sex.femmina,
      neutered: false,
      repro: ReproState.allattamento,
      reproSince: baseNow.subtract(d(10)),
    ),
  ),
];

List<Scenario> seasonalScenarios() => [
  for (var m = 1; m <= 12; m++) ...[
    Scenario(
      'mese $m, adulto al centro',
      dog: mkDog(),
      now: DateTime(2026, m, m == 12 ? 24 : 1, 15),
    ),
    Scenario(
      'mese $m, anziano brachicefalo piccolo al nord',
      dog: mkDog(
        birth: DateTime(2014, 1, 1),
        breed: 'Carlino',
        kg: 8,
        region: Region.nord,
      ),
      now: DateTime(2026, m, m == 12 ? 24 : 1, 15),
    ),
  ],
  for (final breed in [
    'Alano',
    'Piccolo levriero italiano',
    'Bulldog francese',
    'Border Collie',
    'Dalmata',
    'Bassotto',
    'Yorkshire',
    'Schnauzer nano',
    'Dobermann',
    'Cocker',
    'Cavalier King',
  ])
    Scenario('razza $breed', dog: mkDog(breed: breed, kg: 15)),
  Scenario('cane di 40 kg', dog: mkDog(kg: 40)),
  Scenario(
    'taglia grande intera di 10 mesi',
    dog: mkDog(birth: DateTime(2026, 1, 10), kg: 28, neutered: false),
  ),
  Scenario(
    'cucciolo di 10 settimane',
    dog: mkDog(birth: DateTime(2026, 9, 1), kg: 5, neutered: false),
  ),
  Scenario(
    'cucciolo di 20 settimane',
    dog: mkDog(birth: DateTime(2026, 6, 23), kg: 10, neutered: false),
  ),
];

List<(String, Dog?)> emergencyDogs() => [
  ('nessun cane', null),
  ('cane senza numeri', mkDog()),
  (
    'cane con numeri',
    Dog(
      id: 'd',
      name: 'Fido',
      birthDate: DateTime(2022, 1, 1),
      sex: Sex.maschio,
      vetName: 'Dott. Rossi',
      vetPhone: '055 000000',
      emergencyPhone: '055 111111',
      conditions: 'artrosi',
      allergies: 'pollo',
      breed: 'Meticcio',
    ),
  ),
];
