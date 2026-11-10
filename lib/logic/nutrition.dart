import 'dart:math' as math;

import '../models.dart';
import 'potty_predictor.dart';

/// Calcoli nutrizionali secondo le formule NRC 2006 / WSAVA:
/// RER = 70 × peso^0,75 (kcal/giorno), MER = RER × fattore.
class NutritionPlan {
  NutritionPlan({
    required this.rer,
    required this.factor,
    required this.factorReason,
    required this.kcalPerDay,
    required this.gramsPerDay,
    required this.gramsPerMeal,
    required this.meals,
    required this.waterMlMin,
    required this.waterMlMax,
    required this.idealWeightKg,
    required this.weightBasisKg,
    this.notes = const [],
    this.freeFeeding = false,
  });

  /// Avvertenze cliniche da mostrare insieme alla razione.
  final List<String> notes;

  /// Allattamento: cibo a disposizione, nessuna razione fissa.
  final bool freeFeeding;

  final double rer;
  final double factor;
  final String factorReason;
  final double kcalPerDay;
  final double gramsPerDay;
  final double gramsPerMeal;
  final int meals;
  final double waterMlMin;
  final double waterMlMax;
  final double idealWeightKg;
  final double weightBasisKg;
}

class Nutrition {
  static double rer(double kg) => 70 * math.pow(kg, 0.75).toDouble();

  /// Stima del peso ideale dal Body Condition Score (1-9): ogni punto sopra
  /// 5 corrisponde a circa il 10% di peso in eccesso.
  static double idealWeight(Dog dog) {
    if (dog.idealWeightKg != null && dog.idealWeightKg! > 0) {
      return dog.idealWeightKg!;
    }
    return dog.weightKg / (1 + 0.1 * (dog.bodyCondition - 5));
  }

  /// Pasti consigliati per età (AAHA 2019). Nei cuccioli toy sotto i 3 mesi
  /// 5 pasti per prevenire l'ipoglicemia (revisione veterinaria 06 §20).
  static int mealsFor(Dog dog, [DateTime? now]) {
    final m = dog.ageInMonths(now);
    if (m < 3 && dog.weightKg < 5) return 5;
    if (m < 4) return 4;
    if (m < 6) return 3;
    return 2;
  }

  static ({double factor, String reason, bool useIdeal}) merFactor(
    Dog dog, [
    DateTime? now,
  ]) {
    final m = dog.ageInMonths(now);
    final t = now ?? DateTime.now();
    switch (dog.reproAt(t)) {
      case ReproState.gravidanza:
        final d = t.difference(dog.reproSince!).inDays;
        return d > 42
            ? (factor: 3.0, reason: 'gravidanza avanzata', useIdeal: false)
            : (
                factor: 1.8,
                reason: 'gravidanza (prime 6 settimane)',
                useIdeal: false,
              );
      case ReproState.allattamento:
        return (
          factor: 4.0,
          reason: 'allattamento (4-8 × RER)',
          useIdeal: false,
        );
      default:
        break;
    }
    if (m < 4) {
      return (factor: 3.0, reason: 'cucciolo sotto i 4 mesi', useIdeal: false);
    }
    // Le taglie grandi e giganti crescono più a lungo (06 §22).
    // Fine crescita dalla taglia adulta prevista (07 N32), altrimenti
    // stimata dal peso attuale.
    final growthEnd =
        dog.adultSize?.growthEndMonths ??
        (dog.weightKg >= 40
            ? 18
            : dog.weightKg >= 25
            ? 15
            : 12);
    if (m < growthEnd) {
      return (factor: 2.0, reason: 'cucciolo in crescita', useIdeal: false);
    }
    if (dog.bodyCondition >= 7) {
      return (
        factor: 1.0,
        reason: 'programma di dimagrimento (calcolato sul peso ideale)',
        useIdeal: true,
      );
    }
    if (dog.bodyCondition <= 3) {
      return (
        factor: dog.neutered ? 1.6 : 1.8,
        reason: 'sottopeso: calcolato sul peso ideale',
        useIdeal: true,
      );
    }
    switch (dog.activity) {
      case ActivityLevel.lavoro:
        return (
          factor: 3.0,
          reason: 'cane da lavoro/sport intenso',
          useIdeal: false,
        );
      case ActivityLevel.alta:
        return (factor: 2.0, reason: 'cane molto attivo', useIdeal: false);
      case ActivityLevel.bassa:
        return (
          factor: 1.3,
          reason: 'cane sedentario o incline al sovrappeso',
          useIdeal: false,
        );
      case ActivityLevel.normale:
        break;
    }
    if (lifeStageOf(dog, now) == LifeStage.anziano) {
      return (factor: 1.4, reason: 'cane anziano', useIdeal: false);
    }
    return dog.neutered
        ? (factor: 1.6, reason: 'adulto sterilizzato', useIdeal: false)
        : (factor: 1.8, reason: 'adulto non sterilizzato', useIdeal: false);
  }

  static NutritionPlan plan(Dog dog, [DateTime? now]) {
    final ideal = idealWeight(dog);
    final f = merFactor(dog, now);
    final basis = f.useIdeal ? ideal : dog.weightKg;
    final r = rer(basis);
    final kcal = r * f.factor;
    final grams = dog.foodKcalPer100g > 0
        ? kcal / (dog.foodKcalPer100g / 100)
        : 0.0;
    final meals = dog.mealsPerDay > 0 ? dog.mealsPerDay : mealsFor(dog, now);
    final t = now ?? DateTime.now();
    final m = dog.ageInMonths(t);
    final notes = <String>[];
    final lactating = dog.reproAt(t) == ReproState.allattamento;
    if (lactating) {
      notes.add(
        'In allattamento il fabbisogno arriva a 4-8 volte quello di riposo: '
        'lascia il cibo a disposizione (alimento per cuccioli) e acqua fresca '
        'sempre. Se trema, ansima, è agitata o barcolla, chiama subito il '
        'veterinario.',
      );
    }
    if (dog.mealsPerDay > 0 && dog.mealsPerDay < mealsFor(dog, t)) {
      notes.add(
        'Per la sua età sono consigliati ${mealsFor(dog, t)} pasti al giorno: '
        'nei cuccioli piccoli pochi pasti possono causare ipoglicemia.',
      );
    }
    final bigAdult = dog.adultSize == null
        ? (dog.weightKg >= 25 || (m < 6 && dog.weightKg >= 12))
        : (dog.adultSize == AdultSize.grande ||
              dog.adultSize == AdultSize.gigante);
    if (m < 24 && m < (dog.adultSize?.growthEndMonths ?? 18) && bigAdult) {
      notes.add(
        'Cucciolo di taglia grande: usa un alimento specifico "puppy large '
        'breed" e non aggiungere integratori di calcio. Mantienilo snello '
        '(BCS 4-5): crescere più in fretta non lo fa diventare più grande, '
        'aumenta il rischio di problemi alle articolazioni.',
      );
    }
    if (f.useIdeal && dog.bodyCondition >= 7) {
      notes.add(
        'Per dimagrire con questa quota di calorie è consigliato un alimento '
        'dietetico specifico: riducendo molto la razione del cibo normale si '
        'rischiano carenze. Prima di iniziare fai visitare il cane: alcune '
        'malattie ormonali causano aumento di peso. Pesalo ogni 2 settimane.'
        '${dog.conditions.trim().isNotEmpty ? ' Con le patologie registrate la dieta va decisa con il veterinario.' : ''}',
      );
    }
    if (f.useIdeal && dog.bodyCondition <= 3) {
      notes.add(
        'Sottopeso: prima fallo visitare per escludere cause mediche, poi '
        'aumenta la razione gradualmente in 1-2 settimane.',
      );
    }
    return NutritionPlan(
      notes: notes,
      freeFeeding: lactating,
      rer: r,
      factor: f.factor,
      factorReason: f.reason,
      kcalPerDay: kcal,
      gramsPerDay: grams,
      gramsPerMeal: grams / meals,
      meals: meals,
      waterMlMin: dog.weightKg * 50,
      waterMlMax: dog.weightKg * 60,
      idealWeightKg: ideal,
      weightBasisKg: basis,
    );
  }

  /// Soglia di polidipsia nel cane: > 100 ml/kg/giorno.
  static double polydipsiaThresholdMl(Dog dog) => dog.weightKg * 100;

  static const bcsDescriptions = {
    1: 'Emaciato: costole, vertebre e bacino visibili a distanza.',
    2: 'Molto magro: costole facilmente visibili, nessun grasso palpabile.',
    3: 'Magro: costole facilmente palpabili, vita evidente.',
    4: 'Sottile: costole palpabili con poco grasso, vita ben visibile.',
    5: 'Ideale: costole palpabili senza eccesso di grasso, vita visibile da sopra.',
    6: 'Leggermente sovrappeso: costole palpabili con lieve grasso in più.',
    7: 'Sovrappeso: costole palpabili a fatica, vita poco visibile.',
    8: 'Obeso: costole non palpabili, nessuna vita, addome disteso.',
    9: 'Obesità grave: depositi di grasso su collo, arti e base della coda.',
  };

  /// Alimenti e sostanze pericolose (revisione veterinaria 06 §25).
  static const toxicFoods = <({String food, String danger, String severity})>[
    (
      food: 'Xilitolo (gomme e dolci "senza zucchero", dentifricio per persone, burro di arachidi light, integratori)',
      danger: 'ipoglicemia e danno al fegato anche a piccole dosi',
      severity: 'grave',
    ),
    (
      food: 'Uva e uvetta',
      danger: 'insufficienza renale acuta, dose imprevedibile',
      severity: 'grave',
    ),
    (
      food: 'Cioccolato e cacao (più è fondente, più è pericoloso)',
      danger: 'teobromina: vomito, agitazione, aritmie, convulsioni',
      severity: 'grave',
    ),
    (
      food: 'Cipolla, aglio, porro, erba cipollina (anche cotti o in polvere)',
      danger:
          'anemia: alterazioni del sangue da circa 5 g/kg, effetto cumulativo',
      severity: 'grave',
    ),
    (
      food: 'Farmaci per persone: paracetamolo, ibuprofene, naprossene, ketoprofene, aspirina',
      danger: 'ulcere, danno a reni e fegato, anemia',
      severity: 'grave',
    ),
    (
      food: 'Altri farmaci umani: antidepressivi, farmaci per ADHD, farmaci per il cuore',
      danger: 'agitazione, aritmie, convulsioni',
      severity: 'grave',
    ),
    (
      food: 'Veleni per topi (anticoagulanti, colecalciferolo)',
      danger: 'emorragie anche dopo 3-5 giorni; danno renale',
      severity: 'grave',
    ),
    (
      food: 'Lumachicidi a base di metaldeide',
      danger: 'tremori e convulsioni gravi in poco tempo',
      severity: 'grave',
    ),
    (
      food: 'Antigelo (glicole etilenico), insetticidi, bocconi avvelenati',
      danger: 'insufficienza renale, sintomi neurologici',
      severity: 'grave',
    ),
    (
      food: 'Processionaria del pino (febbraio-maggio)',
      danger:
          'necrosi di lingua e bocca: subito dal veterinario, non strofinare',
      severity: 'grave',
    ),
    (
      food: 'Cannabis / THC',
      danger: 'barcollamento, perdita di urina, letargia',
      severity: 'moderata',
    ),
    (
      food: 'Piante: oleandro, Cycas revoluta, tasso, mughetto, azalea, ricino, bulbi',
      danger: 'effetti su cuore, fegato o sistema nervoso',
      severity: 'grave',
    ),
    (
      food: 'Funghi selvatici, alghe tossiche in acqua stagnante',
      danger: 'danno al fegato, sintomi neurologici',
      severity: 'grave',
    ),
    (
      food: 'Rospi e morsi di vipera',
      danger: 'salivazione, gonfiore, collasso: subito dal veterinario',
      severity: 'grave',
    ),
    (
      food: 'Noci di macadamia',
      danger: 'debolezza, tremori, febbre',
      severity: 'moderata',
    ),
    (
      food: 'Alcol e impasti lievitati crudi',
      danger: 'intossicazione, dilatazione dello stomaco',
      severity: 'grave',
    ),
    (
      food: 'Caffeina (caffè, tè, energy drink), noce moscata, luppolo',
      danger: 'agitazione, tachicardia, ipertermia, convulsioni',
      severity: 'grave',
    ),
    (
      food: 'Cibo ammuffito e compost',
      danger: 'tremori e convulsioni (micotossine)',
      severity: 'grave',
    ),
    (
      food: 'Batterie a bottone, magneti, pannocchie, noccioli, ossa cotte',
      danger: 'ustioni interne, ostruzioni e perforazioni',
      severity: 'grave',
    ),
    (
      food: 'Avocado',
      danger: 'disturbi gastrointestinali; il nocciolo causa ostruzioni',
      severity: 'lieve',
    ),
    (
      food: 'Cibi molto grassi (avanzi, fritti) e sale in eccesso',
      danger: 'pancreatite; vomito e convulsioni da sale',
      severity: 'moderata',
    ),
  ];
}
