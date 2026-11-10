import 'dart:math' as math;

import '../models.dart';

/// Parametri biologici del modello di eliminazione.
///
/// Ogni valore riporta la fonte: [E] evidenza forte, [C] consenso clinico,
/// [R] regola empirica / stima prudente. Dettagli e bibliografia in
/// ricerca/04-basi-scientifiche.md e ricerca/05-fattori-biologici-eliminazione.md.
///
/// Questi valori NON sono la previsione: sono il punto di partenza (prior)
/// che il modello sostituisce progressivamente con il comportamento reale del
/// singolo cane.

enum Need { pipi, cacca }

extension NeedX on Need {
  LogType get logType => this == Need.pipi ? LogType.pipi : LogType.cacca;
  String get label => this == Need.pipi ? 'pipì' : 'cacca';

  /// Minuti entro cui eventi ravvicinati sono la stessa uscita
  /// (marcatura nei maschi; più deposizioni nella stessa passeggiata).
  double get clusterMinutes => this == Need.pipi ? 15 : 30;
}

/// Finestra di effetto di un evento (pasto, acqua, ecc.): picco e
/// deviazione standard in minuti, e rapporto di rischio al picco (quanto
/// l'evento moltiplica il rischio di base del bisogno).
class Trigger {
  const Trigger(this.peak, this.width, this.ratio);
  final double peak;
  final double width;
  final double ratio;
}

class NeedPrior {
  const NeedPrior({
    required this.median,
    required this.sigma,
    required this.maxDay,
    required this.maxNight,
    required this.meal,
    required this.water,
    required this.wake,
    required this.play,
    required this.walk,
    required this.nightRatio,
    required this.priorDays,
  });

  /// Copia con un diverso intervallo mediano (Bayes empirico).
  NeedPrior withMedian(double m) => NeedPrior(
    median: m,
    sigma: sigma,
    maxDay: maxDay,
    maxNight: maxNight,
    meal: meal,
    water: water,
    wake: wake,
    play: play,
    walk: walk,
    nightRatio: nightRatio,
    priorDays: priorDays,
  );

  /// Intervallo mediano tra due eventi da svegli (minuti).
  final double median;

  /// Dispersione log-normale dell'intervallo.
  final double sigma;

  /// Attesa massima raccomandata di giorno / di notte (minuti).
  final double maxDay;
  final double maxNight;
  final Trigger meal;
  final Trigger water;
  final Trigger wake;
  final Trigger play;

  /// Inizio passeggiata: il trigger più forte per la cacca (Dapoigny &
  /// Sarna 1991: defecazione poco dopo l'inizio dell'esercizio) [E].
  final Trigger walk;

  /// Forza del prior in giorni di dati equivalenti (05 §Apprendimento).
  final double priorDays;

  /// Rapporto tra la velocità del "bisogno" di notte e di giorno
  /// (ritmo circadiano: di notte si produce meno urina e l'intestino rallenta).
  final double nightRatio;
}

double _lerp(double a, double b, double t) => a + (b - a) * t.clamp(0, 1);

/// Inizio della fase senior per taglia (AAHA 2019/2023) [C].
double seniorStartMonths(double kg) {
  if (kg < 10) return 120;
  if (kg < 25) return 102;
  if (kg < 45) return 90;
  return 72;
}

class BioParams {
  /// Prior per la PIPÌ in funzione dell'età (mesi), interpolato tra le fasce
  /// della tabella in 04-basi-scientifiche.md §1 [R/C].
  static NeedPrior pee(Dog dog, DateTime now) {
    final m = dog.ageInMonths(now);
    final senior = m >= seniorStartMonths(dog.weightKg);
    // (età mesi, mediana, maxGiorno, maxNotte)
    const table = [
      // Tetti diurni da svegli ridotti su revisione veterinaria (06 §29):
      // "mesi + 1 ore" vale a riposo, non da sveglio.
      (2.0, 60.0, 120.0, 240.0),
      (3.0, 90.0, 180.0, 300.0),
      (4.0, 120.0, 240.0, 390.0),
      (5.0, 150.0, 300.0, 450.0),
      (6.0, 210.0, 360.0, 510.0),
      (12.0, 300.0, 480.0, 600.0),
    ];
    double median, maxDay, maxNight;
    if (senior) {
      median = 240;
      maxDay = 360;
      maxNight = 480;
    } else if (m <= table.first.$1) {
      (median, maxDay, maxNight) = (
        table.first.$2,
        table.first.$3,
        table.first.$4,
      );
    } else if (m >= table.last.$1) {
      (median, maxDay, maxNight) = (
        table.last.$2,
        table.last.$3,
        table.last.$4,
      );
    } else {
      var i = 0;
      while (table[i + 1].$1 < m) {
        i++;
      }
      final a = table[i], b = table[i + 1];
      final t = (m - a.$1) / (b.$1 - a.$1);
      median = _lerp(a.$2, b.$2, t);
      maxDay = _lerp(a.$3, b.$3, t);
      maxNight = _lerp(a.$4, b.$4, t);
    }
    final puppy = m < 6;
    final young = m < 12;
    // Latenze in minuti: picco e deviazione standard (FWHM / 2,355).
    // Fonti: 04 §2 e 05 §PARAMETRI (gran parte delle latenze è STIMA entro
    // finestre fisiologiche misurate, es. ADH entro 15' da una bevuta,
    // Thrasher 1981).
    return NeedPrior(
      median: median,
      sigma: puppy ? 0.45 : (senior ? 0.45 : (young ? 0.42 : 0.40)),
      maxDay: maxDay,
      maxNight: maxNight,
      // Rapporti di rischio al picco da 05 §PARAMETRI (STIMA entro finestre
      // fisiologiche misurate).
      meal: puppy ? const Trigger(30, 25, 2.0) : const Trigger(30, 25, 1.3),
      water: puppy
          ? const Trigger(45, 30, 2.5)
          : senior
          ? const Trigger(50, 35, 2.0)
          : const Trigger(60, 38, 2.0),
      wake: puppy ? const Trigger(5, 8.5, 10) : const Trigger(5, 8.5, 6),
      play: puppy
          ? const Trigger(10, 13, 3)
          : young
          ? const Trigger(10, 13, 2)
          : const Trigger(10, 13, 1.5),
      walk: const Trigger(5, 6.5, 8),
      nightRatio: puppy ? 0.35 : (senior ? 0.25 : 0.15),
      priorDays: 7,
    );
  }

  /// Prior per la CACCA (05 §2): intervallo mediano per età, riflesso
  /// gastrocolico (colon distale attivo 0-2 h dopo il pasto, Sarna & Lang
  /// 1989), esercizio come innesco principale (Dapoigny & Sarna 1991),
  /// risveglio (dati umani, Rao 2004), sonno ×0,1.
  static NeedPrior poop(Dog dog, DateTime now) {
    final m = dog.ageInMonths(now);
    final senior = m >= seniorStartMonths(dog.weightKg);
    final puppy = m < 6;
    final double median = m < 3
        ? 240
        : m < 6
        ? 330
        : m < 12
        ? 480
        : senior
        ? 780
        : 660;
    return NeedPrior(
      median: median,
      sigma: puppy ? 0.55 : 0.6,
      maxDay: puppy ? 480 : 1440,
      maxNight: puppy ? 600 : 1440,
      meal: puppy ? const Trigger(25, 20, 5) : const Trigger(30, 25, 3),
      water: const Trigger(30, 20, 1.0),
      wake: puppy ? const Trigger(20, 19, 4) : const Trigger(20, 19, 3),
      play: const Trigger(10, 10, 1.5),
      walk: senior ? const Trigger(10, 8.5, 4) : const Trigger(10, 8.5, 6),
      nightRatio: 0.1,
      priorDays: 4,
    );
  }

  static NeedPrior forNeed(Need need, Dog dog, DateTime now) =>
      need == Need.pipi ? pee(dog, now) : poop(dog, now);

  /// Moltiplicatore dell'intervallo tipico (< 1 = bisogni più frequenti)
  /// dovuto a fattori biologici e ambientali al tempo [t].
  static ({double factor, List<String> reasons}) modifier(
    Need need,
    Dog dog,
    List<HealthRecord> records,
    DateTime t,
  ) {
    var f = 1.0;
    final why = <String>[];
    void apply(double x, String r) {
      f *= x;
      why.add(r);
    }

    final cond = dog.conditions.toLowerCase();
    // Confronto a inizio parola (06 §31: "irc" non deve trovare "circa").
    bool has(List<String> k) =>
        k.any((w) => RegExp('(^|[^a-zà-ù])$w').hasMatch(cond));
    if (need == Need.pipi) {
      // Cani piccoli: più acqua per kg (∝ BW^-0,25, NRC 2006) [C].
      if (dog.weightKg < 10) apply(0.85, 'taglia piccola');
      // Cibo umido: più urina nei piccoli, quasi nulla nei grandi
      // (Stevenson 2003) [E].
      final wet = dog.weightKg < 10 ? 0.8 : (dog.weightKg > 25 ? 0.95 : 0.88);
      if (dog.diet == DietType.umido) apply(wet, 'cibo umido');
      if (dog.diet == DietType.misto) apply((1 + wet) / 2, 'dieta mista');
      switch (dog.reproAt(t)) {
        case ReproState.calore:
          apply(0.9, 'calore');
        case ReproState.gravidanza:
          final d = t.difference(dog.reproSince!).inDays;
          if (d > 40) apply(0.8, 'gravidanza avanzata');
        case ReproState.allattamento:
          apply(0.8, 'allattamento');
        case ReproState.nessuno:
          break;
      }
      // Malattie note (05 §1.8, STIMA): aprono anche la sorveglianza.
      if (has(['diabet'])) apply(0.4, 'diabete');
      if (has(['cushing', 'ipercortisol', 'iperadrenocortic'])) {
        apply(0.5, 'Cushing');
      }
      if (has(['renal', 'irc', 'insufficienza ren', 'iris'])) {
        apply(0.6, 'malattia renale');
      }
      if (has(['cistit', 'infezione urin', 'ivu'])) apply(0.4, 'cistite');
    } else {
      if (dog.reproAt(t) == ReproState.allattamento) {
        apply(0.6, 'allattamento');
      }
      if (dog.activity == ActivityLevel.alta ||
          dog.activity == ActivityLevel.lavoro) {
        apply(0.9, 'molto attivo');
      }
      if (has(['colit', 'ibd', 'enterit'])) apply(0.6, 'malattia intestinale');
      // Dopo anestesia/ricovero lo svuotamento gastrico rallenta molto
      // (Boscan 2014; Warrit 2017) [E].
      final surgery = records.any(
        (r) =>
            r.dogId == dog.id &&
            r.type == RecordType.intervento &&
            r.done &&
            !r.date.isAfter(t) &&
            t.difference(r.date).inHours < 48,
      );
      if (surgery) apply(2.0, 'recente anestesia/ricovero');
    }

    // Farmaci attivi al tempo t.
    for (final r in records) {
      if (r.dogId != dog.id || !r.isActiveTherapy(t)) continue;
      final eff = r.drugEffect == DrugEffect.nessuno
          ? DrugEffectLabel.guess(r.title)
          : r.drugEffect;
      if (need == Need.pipi) {
        switch (eff) {
          case DrugEffect.diuretico:
            // Furosemide: picco 1-2 h, durata ~6 h dalla dose [E].
            final since = _hoursSinceDose(r, t);
            if (since != null && since < 6) {
              apply(since < 2 ? 0.35 : 0.6, 'diuretico (${r.title})');
            } else {
              apply(0.85, 'diuretico (${r.title})');
            }
          case DrugEffect.cortisonico:
            apply(0.67, 'cortisonico (${r.title})');
          case DrugEffect.poliuria:
            apply(0.77, r.title);
          default:
            break;
        }
      } else {
        switch (eff) {
          case DrugEffect.lassativo:
            apply(0.6, 'lassativo (${r.title})');
          case DrugEffect.antidiarroico:
            apply(1.67, r.title);
          case DrugEffect.poliuria:
            apply(0.83, r.title);
          default:
            break;
        }
      }
    }
    return (factor: f.clamp(0.2, 3.0), reasons: why);
  }

  static double? _hoursSinceDose(HealthRecord r, DateTime t) {
    if (r.everyHours == null || r.everyHours! <= 0) return null;
    final elapsed = t.difference(r.date).inMinutes / 60.0;
    if (elapsed < 0) return null;
    return elapsed % r.everyHours!;
  }

  /// Nucleo gaussiano di un trigger a [dtMin] minuti dall'evento.
  static double kernel(double dtMin, Trigger tr) {
    if (dtMin < 0 || dtMin > tr.peak + 4 * tr.width) return 0;
    final z = (dtMin - tr.peak) / tr.width;
    return math.exp(-0.5 * z * z);
  }
}
