// Modelli dati di Zampa. Tutto è serializzabile in JSON per la persistenza
// locale (nessun dato lascia il dispositivo nella versione attuale).

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
    '${_counter++}';
int _counter = 0;

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);
String? _iso(DateTime? d) => d?.toIso8601String();

enum Sex { maschio, femmina }

/// Macro-area italiana, per la stagionalità di zanzare, flebotomi e zecche.
enum Region { nord, centro, sud }

enum AdultSize { piccola, media, grande, gigante }

extension AdultSizeX on AdultSize {
  String get label => switch (this) {
    AdultSize.piccola => 'Piccola (< 10 kg)',
    AdultSize.media => 'Media (10-25 kg)',
    AdultSize.grande => 'Grande (25-45 kg)',
    AdultSize.gigante => 'Gigante (> 45 kg)',
  };

  /// Mese di fine crescita (AAHA 2019).
  int get growthEndMonths => switch (this) {
    AdultSize.piccola => 12,
    AdultSize.media => 12,
    AdultSize.grande => 15,
    AdultSize.gigante => 21,
  };
}

extension RegionLabel on Region {
  String get label => switch (this) {
    Region.nord => 'Nord Italia',
    Region.centro => 'Centro Italia',
    Region.sud => 'Sud e isole',
  };
}

enum ActivityLevel { bassa, normale, alta, lavoro }

/// Tipo di alimentazione: il cibo umido (~75-80% di acqua) aumenta il
/// volume urinario; la fibra aumenta numero e volume delle feci.
enum DietType { secco, misto, umido, casalingo }

extension DietTypeLabel on DietType {
  String get label => switch (this) {
    DietType.secco => 'Crocchette',
    DietType.misto => 'Misto secco/umido',
    DietType.umido => 'Umido (scatolette)',
    DietType.casalingo => 'Casalinga/cotta',
  };
}

/// Stato riproduttivo (solo femmine): modifica sete e frequenza urinaria.
enum ReproState { nessuno, calore, gravidanza, allattamento }

extension ReproStateLabel on ReproState {
  String get label => switch (this) {
    ReproState.nessuno => 'Nessuno',
    ReproState.calore => 'In calore',
    ReproState.gravidanza => 'Gravidanza',
    ReproState.allattamento => 'Allattamento',
  };
}

/// Quanto anticipare le uscite: probabilità di "arrivare tardi" accettata.
enum Prudence { alta, normale, bassa }

extension PrudenceLabel on Prudence {
  String get label => switch (this) {
    Prudence.alta => 'Massima (meno incidenti)',
    Prudence.normale => 'Equilibrata',
    Prudence.bassa => 'Meno uscite (solo adulti sani)',
  };
  double get quantile => switch (this) {
    Prudence.alta => 0.12,
    Prudence.normale => 0.25,
    Prudence.bassa => 0.40,
  };
}

/// Effetto noto di un farmaco sui bisogni (per il modello di previsione).
enum DrugEffect {
  fans,
  trilostano,
  nessuno,
  diuretico,
  cortisonico,
  poliuria,
  lassativo,
  antidiarroico,
}

extension DrugEffectLabel on DrugEffect {
  String get label => switch (this) {
    DrugEffect.nessuno => 'Nessun effetto noto',
    DrugEffect.diuretico => 'Diuretico (es. furosemide)',
    DrugEffect.cortisonico => 'Cortisonico (es. prednisolone)',
    DrugEffect.poliuria => 'Aumenta sete/pipì (es. fenobarbital)',
    DrugEffect.lassativo => 'Lassativo (es. lattulosio)',
    DrugEffect.antidiarroico => 'Rallenta l\'intestino',
    DrugEffect.fans => 'Antinfiammatorio (FANS)',
    DrugEffect.trilostano => 'Terapia per il Cushing (trilostano)',
  };

  /// Riconosce i principi attivi più comuni dal nome del farmaco.
  static DrugEffect guess(String name) {
    final n = name.toLowerCase();
    bool any(List<String> k) => k.any(n.contains);
    // Nomi commerciali veterinari più diffusi in Italia (revisione 07 N11).
    if (any(['trilostan', 'vetoryl', 'lysodren', 'mitotan'])) {
      return DrugEffect.trilostano;
    }
    if (any([
      'metacam',
      'meloxidyl',
      'loxicom',
      'inflacam',
      'rimadyl',
      'carprodyl',
      'rycarfa',
      'norocarp',
      'previcox',
      'onsior',
      'cimalgex',
      'trocoxil',
      'galliprant',
      'aspirin',
    ])) {
      return DrugEffect.fans;
    }
    if (any(['prednicortone', 'medrol', 'dexadreson', 'cortavance'])) {
      return DrugEffect.cortisonico;
    }
    if (any(['lasix', 'dimazon', 'upcard', 'prilactone'])) {
      return DrugEffect.diuretico;
    }
    if (any(['soriphen', 'epiphen', 'libromide'])) {
      return DrugEffect.poliuria;
    }
    if (any([
      'furosemide',
      'torasemide',
      'spironolatton',
      'idroclorotiazide',
      'diuretic',
    ])) {
      return DrugEffect.diuretico;
    }
    if (any([
      'prednisol',
      'prednison',
      'metilpred',
      'desametason',
      'dexamethason',
      'cortison',
      'betametason',
      'triamcinolon',
    ])) {
      return DrugEffect.cortisonico;
    }
    if (any(['fenobarbital', 'phenobarbital', 'bromuro di potassio'])) {
      return DrugEffect.poliuria;
    }
    if (any(['lattulosio', 'lactulose', 'lassativ', 'paraffina'])) {
      return DrugEffect.lassativo;
    }
    if (any([
      'meloxicam',
      'carprofen',
      'robenacoxib',
      'firocoxib',
      'cimicoxib',
      'mavacoxib',
      'grapiprant',
      'antinfiammator',
      'fans',
    ])) {
      return DrugEffect.fans;
    }
    if (any(['loperamide', 'antidiarr', 'oppioid', 'tramadol', 'codeina'])) {
      return DrugEffect.antidiarroico;
    }
    return DrugEffect.nessuno;
  }
}

class Dog {
  Dog({
    required this.id,
    required this.name,
    required this.birthDate,
    required this.sex,
    this.breed = '',
    this.neutered = false,
    this.weightKg = 10,
    this.idealWeightKg,
    this.bodyCondition = 5,
    this.activity = ActivityLevel.normale,
    this.microchip = '',
    this.vetName = '',
    this.vetPhone = '',
    this.allergies = '',
    this.conditions = '',
    this.foodName = '',
    this.foodKcalPer100g = 360,
    this.mealsPerDay = 0,
    this.region = Region.centro,
    this.adultSize,
    this.emergencyPhone = '',
    this.city = '',
    this.lat,
    this.lon,
    this.heatAlertsOn = false,
    this.sleepStartHour = 23,
    this.wakeHour = 7,
    this.pottyRemindersOn = true,
    this.reminderLeadMinutes = 10,
    this.diet = DietType.secco,
    this.reproState = ReproState.nessuno,
    this.reproSince,
    this.prudence = Prudence.normale,
    this.poopRemindersOn = true,
    AvatarLook? look,
  }) : look = look ?? AvatarLook.forWeight(weightKg);

  final String id;
  String name;
  DateTime birthDate;
  Sex sex;
  String breed;
  bool neutered;
  double weightKg;
  double? idealWeightKg;

  /// Body Condition Score su scala 1-9 (5 = ideale).
  int bodyCondition;
  ActivityLevel activity;
  String microchip;
  String vetName;
  String vetPhone;
  String allergies;
  String conditions;
  String foodName;
  double foodKcalPer100g;

  /// 0 = automatico in base all'età.
  int mealsPerDay;
  Region region;

  /// Taglia adulta prevista (per la crescita dei cuccioli, 07 N32).
  AdultSize? adultSize;
  String emergencyPhone;

  /// Città per l'avviso caldo (meteo Open-Meteo, solo se attivato).
  String city;
  double? lat;
  double? lon;
  bool heatAlertsOn;

  /// Aspetto del compagno in pixel art (personalizzabile).
  AvatarLook look;

  /// Finestra di sonno notturno: nessun promemoria pipì in questo intervallo
  /// (tranne che per i cuccioli molto giovani, vedi PottyPredictor).
  int sleepStartHour;
  int wakeHour;
  bool pottyRemindersOn;
  int reminderLeadMinutes;
  DietType diet;
  ReproState reproState;
  DateTime? reproSince;
  Prudence prudence;
  bool poopRemindersOn;

  /// Stato riproduttivo effettivo a una data (il calore dura ~3 settimane,
  /// la gravidanza ~9 settimane, l'allattamento ~7 settimane).
  ReproState reproAt(DateTime t) {
    if (sex != Sex.femmina || reproSince == null) return ReproState.nessuno;
    final days = t.difference(reproSince!).inDays;
    final limit = switch (reproState) {
      ReproState.calore => 21,
      ReproState.gravidanza => 72,
      ReproState.allattamento => 50,
      ReproState.nessuno => -1,
    };
    return (days >= 0 && days <= limit) ? reproState : ReproState.nessuno;
  }

  double ageInMonths([DateTime? now]) {
    final n = now ?? DateTime.now();
    return n.difference(birthDate).inDays / 30.44;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'birthDate': _iso(birthDate),
    'sex': sex.name,
    'breed': breed,
    'neutered': neutered,
    'weightKg': weightKg,
    'idealWeightKg': idealWeightKg,
    'bodyCondition': bodyCondition,
    'activity': activity.name,
    'microchip': microchip,
    'vetName': vetName,
    'vetPhone': vetPhone,
    'allergies': allergies,
    'conditions': conditions,
    'foodName': foodName,
    'foodKcalPer100g': foodKcalPer100g,
    'mealsPerDay': mealsPerDay,
    'region': region.name,
    'adultSize': adultSize?.name,
    'emergencyPhone': emergencyPhone,
    'city': city,
    'lat': lat,
    'lon': lon,
    'heatAlertsOn': heatAlertsOn,
    'look': look.toJson(),
    'sleepStartHour': sleepStartHour,
    'wakeHour': wakeHour,
    'pottyRemindersOn': pottyRemindersOn,
    'reminderLeadMinutes': reminderLeadMinutes,
    'diet': diet.name,
    'reproState': reproState.name,
    'reproSince': _iso(reproSince),
    'prudence': prudence.name,
    'poopRemindersOn': poopRemindersOn,
  };

  factory Dog.fromJson(Map<String, Object?> j) => Dog(
    id: j['id'] as String,
    name: j['name'] as String,
    birthDate: _date(j['birthDate'])!,
    sex: Sex.values.byName(j['sex'] as String),
    breed: (j['breed'] as String?) ?? '',
    neutered: (j['neutered'] as bool?) ?? false,
    weightKg: (j['weightKg'] as num).toDouble(),
    idealWeightKg: (j['idealWeightKg'] as num?)?.toDouble(),
    bodyCondition: (j['bodyCondition'] as int?) ?? 5,
    activity: ActivityLevel.values.byName(
      (j['activity'] as String?) ?? 'normale',
    ),
    microchip: (j['microchip'] as String?) ?? '',
    vetName: (j['vetName'] as String?) ?? '',
    vetPhone: (j['vetPhone'] as String?) ?? '',
    allergies: (j['allergies'] as String?) ?? '',
    conditions: (j['conditions'] as String?) ?? '',
    foodName: (j['foodName'] as String?) ?? '',
    foodKcalPer100g: ((j['foodKcalPer100g'] as num?) ?? 360).toDouble(),
    mealsPerDay: (j['mealsPerDay'] as int?) ?? 0,
    region: Region.values.byName((j['region'] as String?) ?? 'centro'),
    adultSize: j['adultSize'] == null
        ? null
        : AdultSize.values.byName(j['adultSize'] as String),
    emergencyPhone: (j['emergencyPhone'] as String?) ?? '',
    city: (j['city'] as String?) ?? '',
    lat: (j['lat'] as num?)?.toDouble(),
    lon: (j['lon'] as num?)?.toDouble(),
    heatAlertsOn: (j['heatAlertsOn'] as bool?) ?? false,
    look: j['look'] == null
        ? null
        : AvatarLook.fromJson((j['look'] as Map).cast<String, Object?>()),
    sleepStartHour: (j['sleepStartHour'] as int?) ?? 23,
    wakeHour: (j['wakeHour'] as int?) ?? 7,
    pottyRemindersOn: (j['pottyRemindersOn'] as bool?) ?? true,
    reminderLeadMinutes: (j['reminderLeadMinutes'] as int?) ?? 10,
    diet: DietType.values.byName((j['diet'] as String?) ?? 'secco'),
    reproState: ReproState.values.byName(
      (j['reproState'] as String?) ?? 'nessuno',
    ),
    reproSince: _date(j['reproSince']),
    prudence: Prudence.values.byName((j['prudence'] as String?) ?? 'normale'),
    poopRemindersOn: (j['poopRemindersOn'] as bool?) ?? true,
  );
}

/// Eventi del diario quotidiano. Le minzioni sono quelle che l'algoritmo
/// impara; gli altri eventi (pasto, acqua, risveglio, gioco) anticipano il
/// bisogno e vengono usati come "inneschi".
enum LogType {
  pipi,
  cacca,
  pasto,
  acqua,
  risveglio,
  gioco,
  passeggiata,
  vomito,
  inappetenza,
  abbattimento,
  respiro,
  tosse,
  gengive,
  convulsione,
  zoppia,
  pelle,
  neuro,
  temperatura,
  perditaRiposo,
  perditeVulvari,
  ingestione,
  insulina,
  glicemia,
  denti,
  collasso,
  addomeGonfio,
  mammelle,
  ferita,
}

extension LogTypeLabel on LogType {
  String get label => switch (this) {
    LogType.pipi => 'Pipì',
    LogType.cacca => 'Cacca',
    LogType.pasto => 'Pasto',
    LogType.acqua => 'Acqua',
    LogType.risveglio => 'Risveglio',
    LogType.gioco => 'Gioco/attività',
    LogType.passeggiata => 'Inizio passeggiata',
    LogType.vomito => 'Vomito',
    LogType.inappetenza => 'Non ha mangiato',
    LogType.abbattimento => 'Abbattuto/letargico',
    LogType.respiro => 'Respiri nel sonno',
    LogType.tosse => 'Tosse/respiro affannoso',
    LogType.gengive => 'Colore gengive',
    LogType.convulsione => 'Convulsione',
    LogType.zoppia => 'Zoppia',
    LogType.pelle => 'Pelle/orecchie/prurito',
    LogType.neuro => 'Tremori/barcolla',
    LogType.temperatura => 'Temperatura',
    LogType.perditaRiposo => 'Perdita di urina a riposo',
    LogType.perditeVulvari => 'Perdite vulvari',
    LogType.ingestione => 'Ha ingerito qualcosa',
    LogType.insulina => 'Insulina',
    LogType.glicemia => 'Glicemia',
    LogType.denti => 'Denti',
    LogType.collasso => 'Collasso/svenimento',
    LogType.addomeGonfio => 'Addome gonfio',
    LogType.mammelle => 'Mammelle gonfie/calde',
    LogType.ferita => 'Ferita chirurgica',
  };
  String get emoji => switch (this) {
    LogType.pipi => '💧',
    LogType.cacca => '💩',
    LogType.pasto => '🍖',
    LogType.acqua => '🥣',
    LogType.risveglio => '🌅',
    LogType.gioco => '🎾',
    LogType.passeggiata => '🦮',
    LogType.vomito => '🤮',
    LogType.inappetenza => '🍽️',
    LogType.abbattimento => '😴',
    LogType.respiro => '🫁',
    LogType.tosse => '😮‍💨',
    LogType.gengive => '👄',
    LogType.convulsione => '⚡',
    LogType.zoppia => '🦴',
    LogType.pelle => '🐾',
    LogType.neuro => '🌀',
    LogType.temperatura => '🌡️',
    LogType.perditaRiposo => '💦',
    LogType.perditeVulvari => '🩸',
    LogType.ingestione => '☠️',
    LogType.insulina => '💉',
    LogType.glicemia => '🩸',
    LogType.denti => '🦷',
    LogType.collasso => '🆘',
    LogType.addomeGonfio => '🎈',
    LogType.mammelle => '🍼',
    LogType.ferita => '🩹',
  };
}

/// Segnali clinici annotabili su pipì e cacca.
enum Sign {
  sangue,
  sforzo,
  gocce,
  diarrea,
  muco,
  nero,
  vomito,
  conati,
  schiuma,
  addomeGonfio,
  abbattimento,
  // Gengive
  gengivePallide,
  gengiveBlu,
  gengiveGialle,
  gengiveRosse,
  // Respiro / tosse
  dispnea,
  tosseNotturna,
  // Convulsioni
  generalizzata,
  focale,
  nonSiRiprende,
  // Zoppia
  nonCarica,
  // Pelle
  prurito,
  otite,
  lesioni,
  perditaPelo,
  // Neurologici
  testaInclinata,
  barcolla,
  improvviso,
  // Diabete
  nonHaMangiato,
  // Denti
  spazzolati,
  alitosi,
  gengiveSanguinanti,
  masticaMale,
  urinaScura,
  vermi,
  corpoEstraneo,
  pus,
  maleodoranti,
  arrossamento,
  gonfiore,
  secrezione,
  deiscenza,
  sanguinamento,
  starnuti,
  feritaOk,
}

extension SignLabel on Sign {
  String get label => switch (this) {
    Sign.sangue => 'Sangue',
    Sign.sforzo => 'Sforzo/dolore',
    Sign.gocce => 'Poche gocce',
    Sign.diarrea => 'Diarrea',
    Sign.muco => 'Muco',
    Sign.nero => 'Feci nere',
    Sign.vomito => 'Vomito',
    Sign.conati => 'Conati a vuoto',
    Sign.schiuma => 'Schiuma/bile',
    Sign.addomeGonfio => 'Addome gonfio',
    Sign.abbattimento => 'Abbattuto/non mangia',
    Sign.gengivePallide => 'Pallide/bianche',
    Sign.gengiveBlu => 'Blu/grigie',
    Sign.gengiveGialle => 'Gialle',
    Sign.gengiveRosse => 'Rosso scuro',
    Sign.dispnea => 'Fatica a respirare',
    Sign.tosseNotturna => 'Tosse di notte',
    Sign.generalizzata => 'Generalizzata',
    Sign.focale => 'Focale (una parte del corpo)',
    Sign.nonSiRiprende => 'Non si riprende',
    Sign.nonCarica => 'Non appoggia la zampa',
    Sign.prurito => 'Prurito',
    Sign.otite => 'Scuote la testa/orecchie',
    Sign.lesioni => 'Lesioni/arrossamenti',
    Sign.perditaPelo => 'Perdita di pelo',
    Sign.testaInclinata => 'Testa inclinata',
    Sign.barcolla => 'Barcolla',
    Sign.improvviso => 'Comparso all\'improvviso',
    Sign.nonHaMangiato => 'Non ha mangiato prima',
    Sign.spazzolati => 'Spazzolati',
    Sign.alitosi => 'Alito cattivo',
    Sign.gengiveSanguinanti => 'Gengive che sanguinano',
    Sign.masticaMale => 'Mastica a fatica',
    Sign.urinaScura => 'Urina scura/color caffè',
    Sign.vermi => 'Vermi visibili',
    Sign.corpoEstraneo => 'Corpo estraneo/erba',
    Sign.pus => 'Pus (giallo-verde)',
    Sign.maleodoranti => 'Maleodoranti',
    Sign.arrossamento => 'Arrossata',
    Sign.gonfiore => 'Gonfia',
    Sign.secrezione => 'Secrezione',
    Sign.deiscenza => 'Punti aperti',
    Sign.sanguinamento => 'Sanguina',
    Sign.starnuti => 'Starnuti violenti',
    Sign.feritaOk => 'Pulita e asciutta',
  };
}

class LogEntry {
  LogEntry({
    required this.id,
    required this.dogId,
    required this.type,
    required this.time,
    this.indoor = false,
    this.amountMl,
    this.signs = const {},
    this.note = '',
    this.value,
    this.photoId,
  });

  final String id;
  final String dogId;
  final LogType type;

  /// Misura numerica secondo il tipo: punteggio fecale Purina 1-7 (cacca),
  /// atti respiratori/minuto (respiro), minuti (convulsione), °C
  /// (temperatura), unità prescritte (insulina), mg/dL (glicemia).
  final double? value;

  /// Foto allegata (salvata a parte, vedi PhotoStore).
  final String? photoId;
  final DateTime time;

  /// Per pipì/cacca: true = incidente in casa (o sulla traversina).
  final bool indoor;

  /// Per l'acqua: millilitri bevuti, se noti.
  final double? amountMl;
  final Set<Sign> signs;
  final String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'dogId': dogId,
    'type': type.name,
    'time': _iso(time),
    'indoor': indoor,
    'amountMl': amountMl,
    'signs': signs.map((s) => s.name).toList(),
    'note': note,
    'value': value,
    'photoId': photoId,
  };

  factory LogEntry.fromJson(Map<String, Object?> j) => LogEntry(
    id: j['id'] as String,
    dogId: j['dogId'] as String,
    type: LogType.values.byName(j['type'] as String),
    time: _date(j['time'])!,
    indoor: (j['indoor'] as bool?) ?? false,
    amountMl: (j['amountMl'] as num?)?.toDouble(),
    signs: ((j['signs'] as List?) ?? const [])
        .map((s) => Sign.values.byName(s as String))
        .toSet(),
    note: (j['note'] as String?) ?? '',
    value: (j['value'] as num?)?.toDouble(),
    photoId: j['photoId'] as String?,
  );
}

enum RecordType {
  vaccino,
  antiparassitario,
  farmaco,
  visita,
  esame,
  intervento,
  sintomo,
  nota,
}

extension RecordTypeLabel on RecordType {
  String get label => switch (this) {
    RecordType.vaccino => 'Vaccino',
    RecordType.antiparassitario => 'Antiparassitario',
    RecordType.farmaco => 'Farmaco',
    RecordType.visita => 'Visita',
    RecordType.esame => 'Esame/analisi',
    RecordType.intervento => 'Intervento',
    RecordType.sintomo => 'Sintomo',
    RecordType.nota => 'Nota',
  };
  String get emoji => switch (this) {
    RecordType.vaccino => '💉',
    RecordType.antiparassitario => '🪲',
    RecordType.farmaco => '💊',
    RecordType.visita => '🩺',
    RecordType.esame => '🧪',
    RecordType.intervento => '🏥',
    RecordType.sintomo => '🤒',
    RecordType.nota => '📝',
  };
}

/// Voce della cartella sanitaria. Se [nextDue] è valorizzata la voce genera
/// una scadenza (promemoria). Le voci "pianificate" ([done] = false) sono
/// appuntamenti futuri, ad esempio quelli proposti dal piano di prevenzione.
class HealthRecord {
  HealthRecord({
    required this.id,
    required this.dogId,
    required this.type,
    required this.title,
    required this.date,
    this.done = true,
    this.nextDue,
    this.dose = '',
    this.everyHours,
    this.endDate,
    this.notes = '',
    this.vet = '',
    this.cost,
    this.drugEffect = DrugEffect.nessuno,
  });

  final String id;
  final String dogId;
  RecordType type;
  DrugEffect drugEffect;
  String title;
  DateTime date;
  bool done;
  DateTime? nextDue;
  String dose;

  /// Per terapie in corso: ogni quante ore somministrare.
  int? everyHours;
  DateTime? endDate;
  String notes;
  String vet;
  double? cost;

  bool isActiveTherapy(DateTime now) =>
      type == RecordType.farmaco &&
      everyHours != null &&
      !date.isAfter(now) &&
      (endDate == null || endDate!.isAfter(now));

  Map<String, Object?> toJson() => {
    'id': id,
    'dogId': dogId,
    'type': type.name,
    'title': title,
    'date': _iso(date),
    'done': done,
    'nextDue': _iso(nextDue),
    'dose': dose,
    'everyHours': everyHours,
    'endDate': _iso(endDate),
    'notes': notes,
    'vet': vet,
    'cost': cost,
    'drugEffect': drugEffect.name,
  };

  factory HealthRecord.fromJson(Map<String, Object?> j) => HealthRecord(
    id: j['id'] as String,
    dogId: j['dogId'] as String,
    type: RecordType.values.byName(j['type'] as String),
    title: j['title'] as String,
    date: _date(j['date'])!,
    done: (j['done'] as bool?) ?? true,
    nextDue: _date(j['nextDue']),
    dose: (j['dose'] as String?) ?? '',
    everyHours: j['everyHours'] as int?,
    endDate: _date(j['endDate']),
    notes: (j['notes'] as String?) ?? '',
    vet: (j['vet'] as String?) ?? '',
    cost: (j['cost'] as num?)?.toDouble(),
    drugEffect: DrugEffect.values.byName(
      (j['drugEffect'] as String?) ?? 'nessuno',
    ),
  );
}

class WeightEntry {
  WeightEntry({
    required this.id,
    required this.dogId,
    required this.date,
    required this.kg,
  });
  final String id;
  final String dogId;
  final DateTime date;
  final double kg;

  Map<String, Object?> toJson() => {
    'id': id,
    'dogId': dogId,
    'date': _iso(date),
    'kg': kg,
  };
  factory WeightEntry.fromJson(Map<String, Object?> j) => WeightEntry(
    id: j['id'] as String,
    dogId: j['dogId'] as String,
    date: _date(j['date'])!,
    kg: (j['kg'] as num).toDouble(),
  );
}

// ---------------------------------------------------------------------------
// Conferme delle somministrazioni (revisione veterinaria 06, aggiunta 3).
enum DoseStatus { dato, saltato }

class DoseLog {
  DoseLog({
    required this.id,
    required this.dogId,
    required this.recordId,
    required this.scheduledAt,
    required this.status,
    required this.at,
  });
  final String id;
  final String dogId;
  final String recordId;
  final DateTime scheduledAt;
  final DoseStatus status;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'id': id,
    'dogId': dogId,
    'recordId': recordId,
    'scheduledAt': _iso(scheduledAt),
    'status': status.name,
    'at': _iso(at),
  };
  factory DoseLog.fromJson(Map<String, Object?> j) => DoseLog(
    id: j['id'] as String,
    dogId: j['dogId'] as String,
    recordId: j['recordId'] as String,
    scheduledAt: _date(j['scheduledAt'])!,
    status: DoseStatus.values.byName(j['status'] as String),
    at: _date(j['at'])!,
  );
}

// ---------------------------------------------------------------------------
// Storico riproduttivo della femmina (06, aggiunta 7).
enum ReproEventType {
  calore,
  fineCalore,
  accoppiamento,
  parto,
  pseudogravidanza,
  sterilizzazione,
}

extension ReproEventLabel on ReproEventType {
  String get label => switch (this) {
    ReproEventType.calore => 'Inizio calore',
    ReproEventType.fineCalore => 'Fine calore',
    ReproEventType.accoppiamento => 'Accoppiamento',
    ReproEventType.parto => 'Parto',
    ReproEventType.pseudogravidanza => 'Gravidanza isterica',
    ReproEventType.sterilizzazione => 'Sterilizzazione',
  };
}

class ReproEvent {
  ReproEvent({
    required this.id,
    required this.dogId,
    required this.type,
    required this.date,
    this.note = '',
  });
  final String id;
  final String dogId;
  final ReproEventType type;
  final DateTime date;
  final String note;

  Map<String, Object?> toJson() => {
    'id': id,
    'dogId': dogId,
    'type': type.name,
    'date': _iso(date),
    'note': note,
  };
  factory ReproEvent.fromJson(Map<String, Object?> j) => ReproEvent(
    id: j['id'] as String,
    dogId: j['dogId'] as String,
    type: ReproEventType.values.byName(j['type'] as String),
    date: _date(j['date'])!,
    note: (j['note'] as String?) ?? '',
  );
}

// ---------------------------------------------------------------------------
// Qualità della vita (scala HHHHHMM di Villalobos, 06 aggiunta 9).
class QolEntry {
  QolEntry({
    required this.id,
    required this.dogId,
    required this.date,
    required this.scores,
    this.note = '',
    this.kind = 'hhhhhmm',
  });

  /// 'hhhhhmm' (qualità della vita), 'mcs' (massa muscolare, 1 voce 0-3),
  /// 'cognitivo' (checklist DISHAA, 6 voci 0-2).
  final String kind;
  final String id;
  final String dogId;
  final DateTime date;

  /// 7 punteggi 0-10: Hurt, Hunger, Hydration, Hygiene, Happiness,
  /// Mobility, More good days than bad.
  final List<int> scores;
  final String note;
  int get total => scores.fold(0, (a, b) => a + b);

  Map<String, Object?> toJson() => {
    'id': id,
    'dogId': dogId,
    'date': _iso(date),
    'scores': scores,
    'note': note,
    'kind': kind,
  };
  factory QolEntry.fromJson(Map<String, Object?> j) => QolEntry(
    id: j['id'] as String,
    dogId: j['dogId'] as String,
    date: _date(j['date'])!,
    scores: ((j['scores'] as List?) ?? const []).cast<int>(),
    note: (j['note'] as String?) ?? '',
    kind: (j['kind'] as String?) ?? 'hhhhhmm',
  );
}

// ---------------------------------------------------------------------------
// Esami di laboratorio con valori (06 aggiunta 10). L'app non interpreta:
// confronta solo con l'intervallo indicato dal laboratorio.
class LabResult {
  LabResult({
    required this.id,
    required this.dogId,
    required this.date,
    required this.name,
    required this.value,
    this.unit = '',
    this.refLow,
    this.refHigh,
  });
  final String id;
  final String dogId;
  final DateTime date;
  final String name;
  final double value;
  final String unit;
  final double? refLow;
  final double? refHigh;

  bool get outOfRange =>
      (refLow != null && value < refLow!) ||
      (refHigh != null && value > refHigh!);

  Map<String, Object?> toJson() => {
    'id': id,
    'dogId': dogId,
    'date': _iso(date),
    'name': name,
    'value': value,
    'unit': unit,
    'refLow': refLow,
    'refHigh': refHigh,
  };
  factory LabResult.fromJson(Map<String, Object?> j) => LabResult(
    id: j['id'] as String,
    dogId: j['dogId'] as String,
    date: _date(j['date'])!,
    name: j['name'] as String,
    value: (j['value'] as num).toDouble(),
    unit: (j['unit'] as String?) ?? '',
    refLow: (j['refLow'] as num?)?.toDouble(),
    refHigh: (j['refHigh'] as num?)?.toDouble(),
  );
}

// ---------------------------------------------------------------------------
// Aspetto del compagno in pixel art.
enum DogSize { piccola, media, grande }

enum CoatPattern { tinta, focature, pettoBianco, macchie, pezzato, maschera }

enum EarType { dritte, pendenti, semi }

enum TailType { lunga, arricciata, corta }

class AvatarLook {
  AvatarLook({
    this.size = DogSize.media,
    this.coat = 0xFFC8955A,
    this.coat2 = 0xFFF4E6CF,
    this.pattern = CoatPattern.pettoBianco,
    this.ears = EarType.pendenti,
    this.tail = TailType.lunga,
    this.longHair = false,
    this.collar = 0xFFE0453A,
  });

  factory AvatarLook.forWeight(double kg) => AvatarLook(
    size: kg < 10
        ? DogSize.piccola
        : (kg < 25 ? DogSize.media : DogSize.grande),
  );

  DogSize size;
  int coat;
  int coat2;
  CoatPattern pattern;
  EarType ears;
  TailType tail;
  bool longHair;
  int collar;

  AvatarLook copy() => AvatarLook.fromJson(toJson());

  Map<String, Object?> toJson() => {
    'size': size.name,
    'coat': coat,
    'coat2': coat2,
    'pattern': pattern.name,
    'ears': ears.name,
    'tail': tail.name,
    'longHair': longHair,
    'collar': collar,
  };

  factory AvatarLook.fromJson(Map<String, Object?> j) => AvatarLook(
    size: DogSize.values.byName((j['size'] as String?) ?? 'media'),
    coat: (j['coat'] as int?) ?? 0xFFC8955A,
    coat2: (j['coat2'] as int?) ?? 0xFFF4E6CF,
    pattern: CoatPattern.values.byName(
      (j['pattern'] as String?) ?? 'pettoBianco',
    ),
    ears: EarType.values.byName((j['ears'] as String?) ?? 'pendenti'),
    tail: TailType.values.byName((j['tail'] as String?) ?? 'lunga'),
    longHair: (j['longHair'] as bool?) ?? false,
    collar: (j['collar'] as int?) ?? 0xFFE0453A,
  );
}
