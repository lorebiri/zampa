import 'dart:math' as math;

import '../l10n/clinical_text.dart';
import '../models.dart';
import 'potty_predictor.dart';

/// Motivo del fattore MER, dal catalogo (NUT-FAT-001…013).
String _reason(int n) =>
    ClinicalText('NUT-FAT-${n.toString().padLeft(3, '0')}').text;

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
            ? (factor: 3.0, reason: _reason(1), useIdeal: false)
            : (factor: 1.8, reason: _reason(2), useIdeal: false);
      case ReproState.allattamento:
        return (factor: 4.0, reason: _reason(3), useIdeal: false);
      default:
        break;
    }
    if (m < 4) {
      return (factor: 3.0, reason: _reason(4), useIdeal: false);
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
      return (factor: 2.0, reason: _reason(5), useIdeal: false);
    }
    if (dog.bodyCondition >= 7) {
      return (factor: 1.0, reason: _reason(6), useIdeal: true);
    }
    if (dog.bodyCondition <= 3) {
      return (
        factor: dog.neutered ? 1.6 : 1.8,
        reason: _reason(7),
        useIdeal: true,
      );
    }
    switch (dog.activity) {
      case ActivityLevel.lavoro:
        return (factor: 3.0, reason: _reason(8), useIdeal: false);
      case ActivityLevel.alta:
        return (factor: 2.0, reason: _reason(9), useIdeal: false);
      case ActivityLevel.bassa:
        return (factor: 1.3, reason: _reason(10), useIdeal: false);
      case ActivityLevel.normale:
        break;
    }
    if (lifeStageOf(dog, now) == LifeStage.anziano) {
      return (factor: 1.4, reason: _reason(11), useIdeal: false);
    }
    return dog.neutered
        ? (factor: 1.6, reason: _reason(12), useIdeal: false)
        : (factor: 1.8, reason: _reason(13), useIdeal: false);
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
      notes.add(const ClinicalText('NUT-001').text);
    }
    if (dog.mealsPerDay > 0 && dog.mealsPerDay < mealsFor(dog, t)) {
      notes.add(ClinicalText('NUT-002', {'meals': '${mealsFor(dog, t)}'}).text);
    }
    final bigAdult = dog.adultSize == null
        ? (dog.weightKg >= 25 || (m < 6 && dog.weightKg >= 12))
        : (dog.adultSize == AdultSize.grande ||
              dog.adultSize == AdultSize.gigante);
    if (m < 24 && m < (dog.adultSize?.growthEndMonths ?? 18) && bigAdult) {
      notes.add(const ClinicalText('NUT-003').text);
    }
    if (f.useIdeal && dog.bodyCondition >= 7) {
      notes.add(
        ClinicalText('NUT-004', {
          'conditions': yesNo(dog.conditions.trim().isNotEmpty),
        }).text,
      );
    }
    if (f.useIdeal && dog.bodyCondition <= 3) {
      notes.add(const ClinicalText('NUT-005').text);
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

  /// Descrizioni del Body Condition Score (catalogo SCA-BCS-1…9).
  static Map<int, String> get bcsDescriptions => {
    for (var i = 1; i <= 9; i++) i: ClinicalText('SCA-BCS-$i').text,
  };

  /// Gravità degli alimenti pericolosi TOS-001…021, nello stesso ordine.
  /// È anche un codice: l'interfaccia colora in rosso le voci «grave».
  static const _toxicSeverity = [
    'grave',
    'grave',
    'grave',
    'grave',
    'grave',
    'grave',
    'grave',
    'grave',
    'grave',
    'grave',
    'moderata',
    'grave',
    'grave',
    'grave',
    'moderata',
    'grave',
    'grave',
    'grave',
    'grave',
    'lieve',
    'moderata',
  ];

  /// Alimenti e sostanze pericolose (revisione veterinaria 06 §25), dal
  /// catalogo: TOS-nnn, titolo = alimento, testo = pericolo.
  static List<({String food, String danger, String severity})> get toxicFoods =>
      [
        for (var i = 0; i < _toxicSeverity.length; i++)
          () {
            final t = ClinicalText('TOS-${(i + 1).toString().padLeft(3, '0')}');
            return (food: t.title, danger: t.text, severity: _toxicSeverity[i]);
          }(),
      ];
}
