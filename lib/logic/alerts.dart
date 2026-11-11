import '../l10n/clinical_text.dart';
import '../models.dart';
import 'bio_params.dart';
import 'modules.dart';
import 'nutrition.dart';
import 'potty_predictor.dart';
import 'prevention.dart';

/// Livelli di urgenza (revisione veterinaria, ricerca/06 §35). Ogni livello
/// ha una frase d'azione fissa, così il proprietario sa sempre cosa fare.
enum AlertLevel { info, attenzione, oggi, subito }

extension AlertLevelAction on AlertLevel {
  String? get action => ClinicalText(switch (this) {
    AlertLevel.subito => 'ALR-LIV-001',
    AlertLevel.oggi => 'ALR-LIV-002',
    AlertLevel.attenzione => 'ALR-LIV-003',
    AlertLevel.info => 'ALR-LIV-004',
  }).text;
}

class HealthAlert {
  HealthAlert(
    this.level,
    this.title,
    this.message, {
    this.action,
    this.rank = 50,
    this.id = '',
  });

  /// Avviso del catalogo clinico: titolo, testo e frase d'azione vengono
  /// dal catalogo (lib/l10n/app_it.arb) con l'ID di [t].
  factory HealthAlert.fromCatalog(
    AlertLevel level,
    ClinicalText t, {
    String? action,
    int rank = 50,
  }) => HealthAlert(
    level,
    t.title,
    t.text,
    action: action ?? t.action,
    rank: rank,
    id: t.id,
  );

  final AlertLevel level;

  /// ID del catalogo clinico (es. ALR-URI-001); '' per gli avvisi creati
  /// fuori dal motore delle regole.
  final String id;
  final String title;
  final String message;

  /// Frase d'azione specifica; '' = nessuna; null = quella del livello.
  final String? action;

  /// Priorità clinica a parità di livello (07 N25): più bassa = prima.
  final int rank;

  String? get actionText {
    final a = action ?? level.action;
    return (a == null || a.isEmpty) ? null : a;
  }
}

/// Segnali d'allarme ricavati dai dati registrati. Non sono diagnosi: fanno
/// notare un cambiamento e dicono quando sentire il veterinario. Soglie e
/// testi: ricerca/04 §4, ricerca/06 (revisione veterinaria).
class AlertEngine {
  static List<HealthAlert> compute({
    required Dog dog,
    required List<LogEntry> logs,
    required List<HealthRecord> records,
    required List<WeightEntry> weights,
    required DateTime now,
    List<ReproEvent> repro = const [],
    List<({HealthRecord record, DateTime at})> pendingDoses = const [],
  }) {
    final out = <HealthAlert>[];
    void add(
      AlertLevel l,
      String id, {
      Map<String, Object> p = const {},
      String? action,
      int rank = 50,
    }) => out.add(
      HealthAlert.fromCatalog(l, AlertText(id, p), action: action, rank: rank),
    );
    final mine =
        logs.where((l) => l.dogId == dog.id && !l.time.isAfter(now)).toList()
          ..sort((a, b) => a.time.compareTo(b.time));
    final pees = mine.where((l) => l.type == LogType.pipi).toList();
    // Una pipì con solo gocce non conta come minzione (07 N5).
    final realPees = pees.where((l) => !l.signs.contains(Sign.gocce)).toList();
    final postOp = records.any(
      (r) =>
          r.dogId == dog.id &&
          r.type == RecordType.intervento &&
          r.done &&
          !r.date.isAfter(now) &&
          now.difference(r.date).inDays < 14,
    );
    final stage = lifeStageOf(dog, now);
    final male = dog.sex == Sex.maschio;
    final puppy = stage == LifeStage.cucciolo;
    final name = dog.name;
    List<LogEntry> within(Duration d) =>
        mine.where((l) => now.difference(l.time) <= d).toList();
    final h12 = within(const Duration(hours: 12));
    final h24 = within(const Duration(hours: 24));
    final h48 = within(const Duration(hours: 48));
    bool hasSign(LogEntry l, Sign s) => l.signs.contains(s);
    final activeDrugs = records
        .where((r) => r.dogId == dog.id && r.isActiveTherapy(now))
        .map(
          (r) => r.drugEffect == DrugEffect.nessuno
              ? DrugEffectLabel.guess(r.title)
              : r.drugEffect,
        )
        .toSet();
    final onNsaidOrSteroid =
        activeDrugs.contains(DrugEffect.fans) ||
        activeDrugs.contains(DrugEffect.cortisonico);
    final depressed24 = h24.any((l) => hasSign(l, Sign.abbattimento));
    // Frase d'azione comune «chiama prima» (ricerca/26 §3.4, ACT-CALL-FIRST)
    // degli avvisi SUBITO in cui la prima azione utile è una telefonata.
    final callFirst = const ClinicalText('ALR-LIV-005').text;

    // 1. Sforzo a urinare (possibile ostruzione nel maschio: emergenza).
    bool strain(LogEntry l) =>
        l.type == LogType.pipi &&
        (hasSign(l, Sign.sforzo) || hasSign(l, Sign.gocce));
    final strain12 = h12.where(strain).length;
    final strain24 = h24.where(strain).length;
    if (male && strain12 >= 1) {
      add(AlertLevel.subito, 'ALR-URI-001', p: {'name': name});
    } else if (!male && strain24 >= 2) {
      add(AlertLevel.oggi, 'ALR-URI-002');
    } else if (!male && strain24 == 1) {
      add(AlertLevel.attenzione, 'ALR-URI-003');
    }

    // 2. Nessuna pipì da troppo tempo.
    final asleep = PottyPredictor.inSleepWindow(dog, now);
    final todayWake = DateTime(now.year, now.month, now.day, dog.wakeHour);
    final awakeFor4h = !asleep && now.difference(todayWake).inHours >= 4;
    if (realPees.isNotEmpty) {
      final hours = now.difference(realPees.last.time).inMinutes / 60;
      // Nel cucciolo contano le ore da sveglio (07 N9).
      final awakeSince = !asleep && todayWake.isAfter(realPees.last.time)
          ? todayWake
          : realPees.last.time;
      final awakeHours = now.difference(awakeSince).inMinutes / 60;
      final puppyLimit = dog.ageInMonths(now) < 4 ? 6 : 8;
      if (puppy && !asleep && awakeHours >= puppyLimit && hours < 72) {
        add(
          AlertLevel.subito,
          'ALR-URI-004',
          p: {'hours': '${awakeHours.round()}'},
          rank: 5,
        );
      } else if (hours >= 24 && hours < 72) {
        add(
          AlertLevel.subito,
          'ALR-URI-005',
          p: {'hours': '${hours.round()}', 'name': name},
          rank: 5,
        );
      } else if (hours >= 12 && hours < 24 && (awakeFor4h || postOp)) {
        final strainMale = male && strain24 > 0;
        final spine = records.any(
          (r) =>
              r.dogId == dog.id &&
              r.type == RecordType.intervento &&
              now.difference(r.date).inDays < 14 &&
              RegExp('colonna|ernia|disc|spin').hasMatch(r.title.toLowerCase()),
        );
        add(
          strainMale ? AlertLevel.subito : AlertLevel.attenzione,
          'ALR-URI-006',
          p: {
            'hours': '${hours.round()}',
            'name': name,
            // A SUBITO un testo urgente, non condizionale (ricerca/26 §3.5):
            // la frase sulla colonna va dopo.
            'variant': strainMale
                ? (spine ? 'strainSpine' : 'strain')
                : (spine ? 'spine' : 'other'),
          },
          // v1.0-rc (ricerca/15 §3.1 punto 5): quando sale a SUBITO mostra
          // la frase d'azione del livello; altrimenti nessuna.
          action: strainMale ? null : '',
          rank: 6,
        );
      }
    }

    // 3. Sangue nelle urine.
    final bloodUrine = h48.any(
      (l) => l.type == LogType.pipi && hasSign(l, Sign.sangue),
    );
    if (bloodUrine) {
      final inHeat = dog.reproAt(now) == ReproState.calore;
      final vomitOrDown = h48.any(
        (l) => l.type == LogType.vomito || hasSign(l, Sign.abbattimento),
      );
      if (vomitOrDown) {
        add(AlertLevel.oggi, 'ALR-URI-007');
      } else if (inHeat && strain24 == 0) {
        // Il testo dice già quando chiamare: nessuna frase d'azione (B11).
        add(AlertLevel.info, 'ALR-URI-008', action: '');
      } else {
        add(AlertLevel.attenzione, 'ALR-URI-009');
      }
    }

    // 4. Pipì piccole e ravvicinate (pollachiuria): eventi grezzi.
    final raw2h = pees
        .where((l) => now.difference(l.time).inMinutes <= 120)
        .toList();
    final intactMale = male && !dog.neutered;
    final withSigns = raw2h.where((l) => l.signs.isNotEmpty).length;
    if ((!intactMale && raw2h.length >= 4) ||
        (raw2h.length >= 3 && withSigns >= 1)) {
      add(
        AlertLevel.attenzione,
        'ALR-URI-010',
        p: {'count': '${raw2h.length}'},
      );
    }

    // 5. Vomito, diarrea e quadri gastrointestinali (06, 07 N1-N4).
    final vomits24 = h24
        .where((l) => l.type == LogType.vomito || hasSign(l, Sign.vomito))
        .toList();
    final diarrhea24 = h24
        .where((l) => l.type == LogType.cacca && hasSign(l, Sign.diarrea))
        .length;
    final inapp24 = h24.any((l) => l.type == LogType.inappetenza);
    final downEvent24 = h24.any((l) => l.type == LogType.abbattimento);
    final down24 = downEvent24 || depressed24;
    final diabetic = Modules.diabetic(dog, records);
    final poops48 = h48.where((l) => l.type == LogType.cacca).toList();
    final bloodStool = poops48.any((l) => hasSign(l, Sign.sangue));
    final gdv = h24.any(
      (l) =>
          hasSign(l, Sign.conati) ||
          hasSign(l, Sign.addomeGonfio) ||
          l.type == LogType.addomeGonfio,
    );
    if (gdv) {
      add(AlertLevel.subito, 'ALR-GI-001', rank: 0);
    }
    if (h24.any((l) => l.type == LogType.collasso)) {
      add(AlertLevel.subito, 'ALR-NEU-001', rank: 1);
    }
    final vomit = vomits24.isNotEmpty, diarrhea = diarrhea24 > 0;
    final puppyGI =
        puppy &&
        ((vomit && diarrhea) || ((vomit || diarrhea) && (down24 || inapp24)));
    if (puppyGI) {
      add(
        bloodStool || downEvent24 ? AlertLevel.subito : AlertLevel.oggi,
        'ALR-GI-002',
        rank: 10,
      );
    }
    final diabeticGI = diabetic && (vomit || down24);
    if (diabeticGI) {
      add(
        vomit && down24 ? AlertLevel.subito : AlertLevel.oggi,
        'ALR-DIA-001',
        rank: 8,
      );
    }
    if (activeDrugs.contains(DrugEffect.trilostano) &&
        (vomit || diarrhea || down24 || inapp24)) {
      add(AlertLevel.subito, 'ALR-FAR-001', action: callFirst, rank: 9);
    }
    if (onNsaidOrSteroid && !vomit && (inapp24 || down24)) {
      add(AlertLevel.oggi, 'ALR-FAR-002');
    }
    if (activeDrugs.contains(DrugEffect.fans) &&
        activeDrugs.contains(DrugEffect.cortisonico)) {
      add(AlertLevel.attenzione, 'ALR-FAR-003');
    }
    final bloodVomit = vomits24.any((l) => hasSign(l, Sign.sangue));
    if (bloodVomit) {
      add(AlertLevel.oggi, 'ALR-GI-003');
    }
    final tiny = puppy || dog.weightKg < 5;
    final onNsaid = activeDrugs.contains(DrugEffect.fans);
    final onSteroid = activeDrugs.contains(DrugEffect.cortisonico);
    if (onNsaidOrSteroid && vomits24.isNotEmpty) {
      // Testi diversi per FANS e cortisone (ricerca/26 A5).
      add(
        AlertLevel.subito,
        'ALR-FAR-004',
        p: {
          'drug': onNsaid && onSteroid
              ? 'entrambi'
              : (onNsaid ? 'fans' : 'cortisone'),
        },
        action: callFirst,
      );
    } else if (!bloodVomit && !gdv && !puppyGI && !diabeticGI) {
      if (tiny && vomits24.length >= 2) {
        add(AlertLevel.oggi, 'ALR-GI-004');
      } else if (vomits24.length >= 3 || (vomits24.isNotEmpty && depressed24)) {
        add(
          AlertLevel.attenzione,
          'ALR-GI-005',
          p: {'count': '${vomits24.length}'},
        );
      } else if (vomits24.length == 1) {
        add(AlertLevel.info, 'ALR-GI-006');
      }
    }

    // 6. Feci con sangue o nere, diarrea.
    final black = poops48.any((l) => hasSign(l, Sign.nero));
    if (black) {
      add(
        onNsaidOrSteroid ? AlertLevel.subito : AlertLevel.oggi,
        onNsaidOrSteroid ? 'ALR-GI-007a' : 'ALR-GI-007b',
        p: onNsaidOrSteroid ? {'nsaid': yesNo(onNsaid)} : const {},
        action: onNsaidOrSteroid ? callFirst : null,
      );
    }
    if (bloodStool) {
      if (puppy && !puppyGI) {
        add(AlertLevel.oggi, 'ALR-GI-008');
      } else if (vomits24.isNotEmpty || depressed24) {
        add(AlertLevel.oggi, 'ALR-GI-009');
      } else {
        add(AlertLevel.attenzione, 'ALR-GI-010');
      }
    }
    if (puppy && diarrhea24 >= 2 && !bloodStool && !puppyGI) {
      add(AlertLevel.oggi, 'ALR-GI-011');
    } else if (!puppy &&
        !diabeticGI &&
        (diarrhea24 >= 3 || (diarrhea24 >= 1 && vomits24.isNotEmpty))) {
      add(
        AlertLevel.attenzione,
        'ALR-GI-012',
        p: {'vomit': yesNo(vomits24.isNotEmpty)},
      );
    }

    // 7. Stitichezza (non dopo anestesia/ricovero recenti).
    final poops = mine.where((l) => l.type == LogType.cacca).toList();
    final recentSurgery = records.any(
      (r) =>
          r.dogId == dog.id &&
          r.type == RecordType.intervento &&
          r.done &&
          now.difference(r.date).inHours < 72,
    );
    if (poops.isNotEmpty && !recentSurgery) {
      final h = now.difference(poops.last.time).inMinutes / 60;
      final limit = puppy ? 24 : 48;
      final active = mine.any(
        (l) => l.time.isAfter(poops.last.time) && l.type != LogType.cacca,
      );
      if (h >= limit && h < 120 && active) {
        final urgent =
            (puppy && h >= 36) || (!puppy && h >= 72) || vomits24.isNotEmpty;
        add(
          urgent ? AlertLevel.oggi : AlertLevel.attenzione,
          'ALR-GI-013',
          p: {'hours': '${h.round()}'},
        );
      }
    }

    // 8. Frequenza della pipì in aumento rispetto al suo normale.
    final perDay = PottyStats.outingsPerDay(pees);
    final today = DateTime(now.year, now.month, now.day);
    double avg(int a, int b) {
      final v = <int>[];
      for (var d = a; d <= b; d++) {
        final x = perDay[today.subtract(Duration(days: d))];
        if (x != null) v.add(x);
      }
      if (v.length < (b - a + 1) * 0.6) return -1;
      return v.reduce((x, y) => x + y) / v.length;
    }

    final last3 = avg(1, 3), base = avg(4, 17);
    final bioFactor = BioParams.modifier(Need.pipi, dog, records, now).factor;
    // Con farmaci o malattie che aumentano la pipì la soglia sale (06 §PU).
    final expectedRise = bioFactor < 0.8 ? 2.5 : 1.5;
    var moreUrine = false;
    if (last3 > 0 &&
        base > 0 &&
        last3 >= base * expectedRise &&
        last3 - base >= 2) {
      moreUrine = true;
      add(
        AlertLevel.attenzione,
        'ALR-URI-011',
        p: {
          'recent': last3.toStringAsFixed(1),
          'usual': base.toStringAsFixed(1),
          'diabetic': yesNo(Modules.diabetic(dog, records)),
        },
      );
    }

    // 9. Acqua: troppa (polidipsia) o troppo poca con dieta secca.
    final waterByDay = <DateTime, double>{};
    for (final l in mine.where(
      (l) => l.type == LogType.acqua && l.amountMl != null,
    )) {
      final d = DateTime(l.time.year, l.time.month, l.time.day);
      final ago = today.difference(d).inDays;
      if (ago < 1 || ago > 3) continue;
      waterByDay[d] = (waterByDay[d] ?? 0) + l.amountMl!;
    }
    var drinksTooMuch = false;
    if (waterByDay.length >= 2) {
      final mean =
          waterByDay.values.reduce((a, b) => a + b) / waterByDay.length;
      if (mean > Nutrition.polydipsiaThresholdMl(dog)) {
        drinksTooMuch = true;
        add(AlertLevel.attenzione, 'ALR-URI-012', p: {'ml': '${mean.round()}'});
      } else if (dog.diet == DietType.secco && mean < dog.weightKg * 20) {
        add(AlertLevel.attenzione, 'ALR-URI-013', p: {'ml': '${mean.round()}'});
      }
    }

    // 10. Piometra: femmina intera nelle settimane dopo il calore.
    final heat = Modules.lastHeat(dog, repro);
    final vulvar7 = mine.any(
      (l) =>
          l.type == LogType.perditeVulvari &&
          now.difference(l.time).inDays <= 7,
    );
    if (!male && !dog.neutered && heat != null) {
      final days = now.difference(heat).inDays;
      final signs =
          drinksTooMuch ||
          moreUrine ||
          vomits24.isNotEmpty ||
          depressed24 ||
          vulvar7 ||
          h48.any(
            (l) =>
                l.type == LogType.abbattimento || l.type == LogType.inappetenza,
          );
      if (days >= 14 && days <= 84 && signs) {
        add(AlertLevel.oggi, 'ALR-REP-001', rank: 12);
      }
    } else if (!male &&
        !dog.neutered &&
        heat == null &&
        dog.ageInMonths(now) >= 12) {
      // Nessun calore registrato: si contano i segni (07 N6).
      final n = [
        drinksTooMuch,
        moreUrine,
        vomits24.isNotEmpty,
        down24,
        inapp24,
        vulvar7,
      ].where((x) => x).length;
      if (n >= 1) {
        add(
          n >= 2 ? AlertLevel.oggi : AlertLevel.attenzione,
          'ALR-REP-002',
          p: {'urgent': yesNo(n >= 2)},
          rank: 12,
        );
      }
    }

    // 11. Incidenti in casa ripetuti in un adulto.
    if (stage == LifeStage.adulto || stage == LifeStage.anziano) {
      final n = pees
          .where((l) => l.indoor && now.difference(l.time).inDays <= 7)
          .length;
      if (n >= 2) {
        add(AlertLevel.attenzione, 'ALR-URI-014', p: {'count': '$n'});
      }
    }

    // 12. Peso.
    final w = weights.where((e) => e.dogId == dog.id).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final ageM = dog.ageInMonths(now);
    final growing = ageM < 6 || (ageM < 9 && dog.weightKg >= 10);
    if (w.length >= 2) {
      final lastW = w.last;
      if (growing) {
        final ref = w.lastWhere(
          (e) => lastW.date.difference(e.date).inDays >= 14,
          orElse: () => lastW,
        );
        if (ref != lastW && lastW.kg <= ref.kg) {
          add(AlertLevel.attenzione, 'ALR-PES-001');
        }
      } else if (ageM >= 12) {
        final ref90 = w.firstWhere(
          (e) => lastW.date.difference(e.date).inDays <= 90,
          orElse: () => lastW,
        );
        final ref7 = w.lastWhere(
          (e) => lastW.date.difference(e.date).inDays >= 7,
          orElse: () => lastW,
        );
        final change90 = ref90 == lastW
            ? 0.0
            : (lastW.kg - ref90.kg) / ref90.kg;
        final weeks = ref7 == lastW
            ? 0
            : lastW.date.difference(ref7.date).inDays / 7;
        final weekly = weeks > 0 ? (lastW.kg - ref7.kg) / ref7.kg / weeks : 0.0;
        if (dog.bodyCondition >= 7 && weekly < -0.02) {
          add(AlertLevel.attenzione, 'ALR-PES-002');
        } else if (change90 <= -0.10 ||
            (stage == LifeStage.anziano && change90 <= -0.05)) {
          add(
            AlertLevel.attenzione,
            'ALR-PES-003',
            p: {'percent': (-change90 * 100).toStringAsFixed(0)},
          );
        } else if (change90 <= -0.05 && dog.bodyCondition < 7) {
          add(
            AlertLevel.info,
            'ALR-PES-004',
            p: {'percent': (-change90 * 100).toStringAsFixed(0)},
          );
        } else if (change90 >= 0.10) {
          add(
            AlertLevel.info,
            'ALR-PES-005',
            p: {'percent': (change90 * 100).toStringAsFixed(0)},
          );
        }
      }
    }
    if (ageM >= 12 && dog.bodyCondition <= 3) {
      add(AlertLevel.attenzione, 'ALR-PES-006');
    } else if (dog.bodyCondition >= 7) {
      add(
        AlertLevel.info,
        'ALR-PES-007',
        p: {
          'bcs': '${dog.bodyCondition}',
          // Nel cucciolo niente dimagrimento fai da te (ricerca/26 B7).
          'growing': yesNo(Nutrition.isGrowing(dog, now)),
        },
      );
    } else if (dog.bodyCondition == 6) {
      add(AlertLevel.info, 'ALR-PES-008');
    }

    // 14. Nuovi segni registrabili (revisione veterinaria 06, aggiunta 2).
    final cardiac = Modules.cardiac(dog, records);
    final senior = stage == LifeStage.anziano;
    bool typeIn(List<LogEntry> ls, LogType t) => ls.any((l) => l.type == t);

    // Ha ingerito qualcosa: subito nelle prime 12 ore, poi 5 giorni di
    // sorveglianza (07 N19: alcuni veleni danno sintomi dopo giorni).
    final ingest = mine
        .where(
          (l) =>
              l.type == LogType.ingestione && now.difference(l.time).inDays < 5,
        )
        .toList();
    if (ingest.isNotEmpty) {
      final last = ingest.last;
      final note = {'hasNote': yesNo(last.note.isNotEmpty), 'note': last.note};
      if (now.difference(last.time).inHours < 12) {
        add(
          AlertLevel.subito,
          'ALR-TOX-001',
          p: note,
          action: callFirst,
          rank: 3,
        );
      } else {
        add(
          AlertLevel.attenzione,
          'ALR-TOX-002',
          p: {...note, 'date': '${last.time.day}/${last.time.month}'},
          action: '',
        );
      }
    }

    // Gengive.
    final gums = h24.where((l) => l.type == LogType.gengive).toList();
    if (gums.any(
      (l) => hasSign(l, Sign.gengivePallide) || hasSign(l, Sign.gengiveBlu),
    )) {
      add(AlertLevel.subito, 'ALR-RES-001', rank: 2);
    } else if (gums.any((l) => hasSign(l, Sign.gengiveRosse))) {
      add(AlertLevel.subito, 'ALR-RES-002', rank: 2);
    } else if (gums.any((l) => hasSign(l, Sign.gengiveGialle))) {
      add(AlertLevel.oggi, 'ALR-RES-003');
    }

    // Respiro nel sonno (ACVIM 2019, 07 N14) e tosse.
    final breaths = mine
        .where((l) => l.type == LogType.respiro && l.value != null)
        .toList();
    final dyspnea = mine.any(
      (l) =>
          l.type == LogType.tosse &&
          hasSign(l, Sign.dispnea) &&
          now.difference(l.time).inHours <= 12,
    );
    final blueGums = gums.any((l) => hasSign(l, Sign.gengiveBlu));
    if (breaths.isNotEmpty && now.difference(breaths.last.time).inHours <= 24) {
      final last = breaths.last;
      final prev = breaths.length >= 2 ? breaths[breaths.length - 2] : null;
      final prevRecent =
          prev != null && last.time.difference(prev.time).inHours <= 48;
      final prev30min =
          prev != null && last.time.difference(prev.time).inMinutes <= 30;
      final rate = last.value!;
      if (rate > 40 &&
          (cardiac || dyspnea || blueGums || (prev30min && prev.value! > 40))) {
        add(
          AlertLevel.subito,
          'ALR-RES-004',
          p: {'rate': '${rate.round()}'},
          rank: 1,
        );
      } else if (rate > 40) {
        add(AlertLevel.oggi, 'ALR-RES-005', rank: 4);
      } else if (rate > 30 && prevRecent && prev.value! > 30) {
        add(AlertLevel.oggi, 'ALR-RES-006', rank: 4);
      } else {
        double avg(int fromDays, int toDays) {
          final v = breaths
              .where((l) {
                final d = now.difference(l.time).inDays;
                return d >= fromDays && d < toDays;
              })
              .map((l) => l.value!)
              .toList();
          return v.isEmpty ? 0 : v.reduce((a, b) => a + b) / v.length;
        }

        final week = avg(0, 7), month = avg(7, 37);
        if (week > 30 && month > 0 && week >= month * 1.25) {
          add(
            AlertLevel.oggi,
            'ALR-RES-007',
            p: {'week': '${week.round()}', 'month': '${month.round()}'},
          );
        }
      }
    }
    final coughs = mine.where((l) => l.type == LogType.tosse).toList();
    final cavalier = dog.breed.toLowerCase().contains('cavalier');
    if (dyspnea) {
      add(AlertLevel.subito, 'ALR-RES-008', rank: 1);
    } else if (coughs.isNotEmpty &&
        now.difference(coughs.last.time).inHours <= 24) {
      final recent = coughs
          .where((l) => now.difference(l.time).inDays <= 7)
          .toList();
      final spanDays = now.difference(recent.first.time).inDays;
      if (cardiac) {
        add(AlertLevel.oggi, 'ALR-RES-009');
      } else if (cavalier) {
        add(AlertLevel.attenzione, 'ALR-RES-010');
      } else if (spanDays >= 3 || down24) {
        add(AlertLevel.attenzione, 'ALR-RES-011');
      }
    }

    // Glicemie (07 N2) e doppia insulina (07 aggiunta N2).
    final glu6 = mine
        .where(
          (l) =>
              l.type == LogType.glicemia &&
              l.value != null &&
              now.difference(l.time).inHours <= 6,
        )
        .toList();
    if (glu6.isNotEmpty) {
      final g = glu6.last.value!;
      if (g < 60) {
        add(
          AlertLevel.subito,
          'ALR-DIA-002',
          p: {'value': '${g.round()}'},
          action: callFirst,
          rank: 2,
        );
      } else if (g < 80) {
        add(AlertLevel.oggi, 'ALR-DIA-003', p: {'value': '${g.round()}'});
      } else if (g > 400) {
        add(
          vomit || down24 || inapp24 ? AlertLevel.oggi : AlertLevel.attenzione,
          'ALR-DIA-004',
          p: {'value': '${g.round()}'},
        );
      }
    }
    final insulins = mine.where((l) => l.type == LogType.insulina).toList();
    if (insulins.length >= 2) {
      final a = insulins[insulins.length - 2], b = insulins.last;
      final gapH = b.time.difference(a.time).inMinutes / 60;
      final every = records
          .where(
            (r) =>
                r.dogId == dog.id &&
                Modules.isInsulin(r.title) &&
                r.everyHours != null,
          )
          .map((r) => r.everyHours!)
          .fold<int>(12, (x, y) => y);
      final minGap = every - 4 > 6 ? every - 4 : 6;
      if (gapH < minGap && now.difference(b.time).inHours <= 12) {
        add(
          AlertLevel.subito,
          'ALR-DIA-005',
          p: {'hours': gapH.toStringAsFixed(1)},
          action: callFirst,
          rank: 2,
        );
      }
    }

    // Convulsioni (IVETF 2015).
    final seizures = mine.where((l) => l.type == LogType.convulsione).toList();
    final seiz24 = seizures
        .where((l) => now.difference(l.time).inHours <= 24)
        .toList();
    final neuro = h24.where((l) => l.type == LogType.neuro).toList();
    final lactating =
        dog.reproAt(now) == ReproState.allattamento ||
        repro.any(
          (e) =>
              e.dogId == dog.id &&
              e.type == ReproEventType.parto &&
              now.difference(e.date).inDays <= 50,
        );
    final tinyPuppy = puppy && (dog.weightKg < 5 || dog.ageInMonths(now) < 4);
    if (!male && lactating && (neuro.isNotEmpty || seiz24.isNotEmpty)) {
      add(AlertLevel.subito, 'ALR-REP-003', rank: 1);
    } else if (tinyPuppy &&
        (neuro.isNotEmpty || seiz24.isNotEmpty || downEvent24)) {
      add(AlertLevel.subito, 'ALR-NEU-002', rank: 2);
    } else if (seiz24.isNotEmpty) {
      final long = seiz24.any(
        (l) => (l.value ?? 0) >= 5 || hasSign(l, Sign.nonSiRiprende),
      );
      if (diabetic) {
        add(AlertLevel.subito, 'ALR-NEU-003', rank: 3);
      } else if (long || seiz24.length >= 2) {
        add(
          AlertLevel.subito,
          long ? 'ALR-NEU-004a' : 'ALR-NEU-004b',
          p: {'count': '${seiz24.length}'},
          rank: 3,
        );
      } else if (seizures.length == 1) {
        add(AlertLevel.oggi, 'ALR-NEU-005');
      }
    }
    final perMonth = Modules.seizuresPerMonth(logs, dog.id, now, months: 4);
    if (perMonth.length == 4) {
      final prevAvg =
          (perMonth[0].count + perMonth[1].count + perMonth[2].count) / 3;
      final cur = perMonth[3].count;
      if (cur >= 2 && cur > prevAvg * 1.5 && seiz24.isEmpty) {
        add(
          AlertLevel.attenzione,
          'ALR-NEU-006',
          p: {'count': '$cur', 'average': prevAvg.toStringAsFixed(1)},
        );
      }
    }

    // Tremori, barcollamento, testa inclinata.
    if (neuro.isNotEmpty && seiz24.isEmpty && !lactating && !tinyPuppy) {
      if (diabetic) {
        add(AlertLevel.subito, 'ALR-DIA-006', rank: 3);
      } else {
        add(
          neuro.any((l) => hasSign(l, Sign.improvviso))
              ? AlertLevel.subito
              : AlertLevel.oggi,
          'ALR-NEU-007',
        );
      }
    }

    // Temperatura rettale.
    final temps = h24
        .where((l) => l.type == LogType.temperatura && l.value != null)
        .toList();
    if (temps.isNotEmpty) {
      final t = temps.last.value!;
      if (t >= 41 || t < 37) {
        add(
          AlertLevel.subito,
          t >= 41 ? 'ALR-TMP-001a' : 'ALR-TMP-001b',
          p: {'temp': t.toStringAsFixed(1)},
          rank: 2,
        );
      } else if (t >= 39.5) {
        add(AlertLevel.oggi, 'ALR-TMP-002', p: {'temp': t.toStringAsFixed(1)});
      }
    }

    // Inappetenza secondo i pasti previsti (07 N7) e abbattimento (N18).
    final mpd = Nutrition.plan(dog, now).meals;
    final skipped24 = h24.where((l) => l.type == LogType.inappetenza).length;
    final skipped48 = h48.where((l) => l.type == LogType.inappetenza).length;
    if (skipped24 > 0 || skipped48 > 0) {
      final tinyOrYoung = dog.ageInMonths(now) < 4 || dog.weightKg < 5;
      final urgent =
          skipped48 >= 2 * mpd ||
          (tinyOrYoung && skipped24 >= 2) ||
          (puppy && down24) ||
          ((senior || diabetic) && skipped24 > 0) ||
          (onNsaidOrSteroid && skipped24 > 0);
      if (urgent && !diabeticGI && !puppyGI) {
        add(AlertLevel.oggi, diabetic ? 'ALR-CIB-001a' : 'ALR-CIB-001b');
      } else if (!urgent && skipped24 >= mpd) {
        add(AlertLevel.attenzione, 'ALR-CIB-002', action: '');
      }
    }
    if (downEvent24 && !puppyGI && !diabeticGI) {
      final other = vomit || diarrhea || inapp24;
      final fragile = puppy || diabetic || senior;
      if (other || fragile) {
        add(
          AlertLevel.oggi,
          'ALR-CIB-003a',
          p: {
            'reason': other
                ? 'signs'
                : puppy
                ? 'puppy'
                : diabetic
                ? 'diabetic'
                : 'other',
          },
        );
      } else {
        add(AlertLevel.attenzione, 'ALR-CIB-003b', action: '');
      }
    }

    // Diabete: insulina senza pasto (07 N15).
    if (diabetic &&
        h12.any(
          (l) => l.type == LogType.insulina && hasSign(l, Sign.nonHaMangiato),
        )) {
      add(AlertLevel.oggi, 'ALR-DIA-007');
    }

    // Urina scura (07 aggiunta N6).
    final darkUrine = h48.any(
      (l) => l.type == LogType.pipi && hasSign(l, Sign.urinaScura),
    );
    if (darkUrine) {
      final fever = temps.any((l) => l.value! >= 39.5);
      final tickSeason = now.month >= 3 && now.month <= 11;
      final urgent = down24 || fever;
      add(
        urgent ? AlertLevel.oggi : AlertLevel.attenzione,
        'ALR-URI-015',
        p: {
          'variant': tickSeason
              ? (urgent ? 'tickUrgent' : 'tick')
              : (urgent ? 'urgent' : 'other'),
        },
      );
    }

    // Razze MDR1 con loperamide (07 N49).
    if (activeDrugs.contains(DrugEffect.antidiarroico) &&
        RegExp(
          'collie|pastore australiano|australian|shetland|bobtail|'
          'pastore inglese|whippet|silken|pastore svizzero|mcnab|'
          'pastore scozzese',
        ).hasMatch(dog.breed.toLowerCase())) {
      add(AlertLevel.attenzione, 'ALR-FAR-005');
    }

    // Dopo il parto (07 aggiunta N3).
    final birth = repro
        .where((e) => e.dogId == dog.id && e.type == ReproEventType.parto)
        .map((e) => e.date)
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    if (!male && birth != null && now.difference(birth).inDays <= 7) {
      final fever = temps.any((l) => l.value! >= 39.5);
      final smelly = h48.any(
        (l) =>
            l.type == LogType.perditeVulvari &&
            (hasSign(l, Sign.maleodoranti) || hasSign(l, Sign.pus)),
      );
      if (fever || smelly || down24) {
        add(AlertLevel.oggi, 'ALR-REP-004');
      }
    }
    if (!male && h24.any((l) => l.type == LogType.mammelle)) {
      add(AlertLevel.oggi, 'ALR-REP-005');
    }
    final dueSoon = Modules.dueDate(dog, repro, now);
    if (dueSoon != null && dueSoon.difference(now).inDays <= 7) {
      final low = temps.where((l) => l.value! < 37.5).toList();
      if (low.isNotEmpty) {
        final hrs = now.difference(low.first.time).inHours;
        if (hrs > 24) {
          add(AlertLevel.oggi, 'ALR-REP-006a');
        } else {
          add(AlertLevel.info, 'ALR-REP-006b', action: '');
        }
      }
    }

    // Zoppia, pelle, denti.
    final limp = mine
        .where(
          (l) => l.type == LogType.zoppia && now.difference(l.time).inDays <= 7,
        )
        .toList();
    if (limp.any(
      (l) => hasSign(l, Sign.nonCarica) && now.difference(l.time).inHours <= 24,
    )) {
      add(AlertLevel.oggi, 'ALR-ALT-001');
    } else if (limp.isNotEmpty && now.difference(limp.first.time).inDays >= 3) {
      add(AlertLevel.attenzione, 'ALR-ALT-002');
    }
    if (typeIn(h48, LogType.pelle)) {
      add(AlertLevel.attenzione, 'ALR-ALT-003');
    }
    final teeth = mine
        .where(
          (l) => l.type == LogType.denti && now.difference(l.time).inDays <= 7,
        )
        .toList();
    if (teeth.any(
      (l) =>
          hasSign(l, Sign.alitosi) ||
          hasSign(l, Sign.gengiveSanguinanti) ||
          hasSign(l, Sign.masticaMale),
    )) {
      add(AlertLevel.attenzione, 'ALR-ALT-004');
    }
    final brushed = teeth.where((l) => hasSign(l, Sign.spazzolati)).length;
    if (mine.any(
          (l) => l.type == LogType.denti && hasSign(l, Sign.spazzolati),
        ) &&
        brushed < 3) {
      add(AlertLevel.info, 'ALR-ALT-005', p: {'count': '$brushed'});
    }

    // Perdite a riposo (incontinenza) e perdite vulvari.
    if (mine.any(
      (l) =>
          l.type == LogType.perditaRiposo && now.difference(l.time).inDays <= 7,
    )) {
      add(AlertLevel.attenzione, 'ALR-URI-016');
    }
    if (vulvar7 &&
        (male ||
            dog.neutered ||
            heat == null ||
            now.difference(heat).inDays > 84 ||
            now.difference(heat).inDays < 14)) {
      final inHeatNow = heat != null && now.difference(heat).inDays < 21;
      final purulent = mine.any(
        (l) =>
            l.type == LogType.perditeVulvari &&
            now.difference(l.time).inDays <= 7 &&
            (hasSign(l, Sign.pus) || hasSign(l, Sign.maleodoranti)),
      );
      if (purulent && !dog.neutered) {
        add(AlertLevel.oggi, 'ALR-REP-007', rank: 12);
      } else if (!inHeatNow) {
        add(
          purulent ? AlertLevel.oggi : AlertLevel.attenzione,
          'ALR-REP-008',
          // Nella sterilizzata non si parla di calore (ricerca/26 B8).
          p: {
            'variant': !male && dog.neutered
                ? (purulent ? 'spayedPus' : 'spayed')
                : 'other',
          },
        );
      }
    }

    // Pipì notturne nuove (nicturia, 04 §1.4).
    int nightsWithPee(int fromDay, int toDay) {
      var n = 0;
      for (var d = fromDay; d <= toDay; d++) {
        final day = today.subtract(Duration(days: d));
        if (pees.any(
          (l) =>
              PottyPredictor.inSleepWindow(dog, l.time) &&
              DateTime(l.time.year, l.time.month, l.time.day) == day &&
              l.time.hour < 12,
        )) {
          n++;
        }
      }
      return n;
    }

    if (!puppy &&
        nightsWithPee(0, 6) >= 2 &&
        nightsWithPee(7, 20) == 0 &&
        pees.any((l) => now.difference(l.time).inDays >= 14)) {
      add(AlertLevel.attenzione, 'ALR-URI-017');
    }

    // Riproduzione.
    final due = Modules.dueDate(dog, repro, now);
    if (due != null) {
      final daysFromMating = 63 - due.difference(now).inDays;
      if (daysFromMating > 70) {
        add(AlertLevel.oggi, 'ALR-REP-009');
      } else if (daysFromMating >= 58) {
        add(
          AlertLevel.info,
          'ALR-REP-010',
          p: {'date': '${due.day}/${due.month}'},
          action: '',
        );
      }
    }
    if (Modules.longHeat(dog, repro, now)) {
      add(AlertLevel.attenzione, 'ALR-REP-011');
    }

    // Dosi non confermate da oltre 2 ore.
    final late = pendingDoses
        .where((p) => now.difference(p.at).inMinutes >= 120)
        .toList();
    if (late.isNotEmpty) {
      final at = late.first.at;
      add(
        AlertLevel.attenzione,
        'ALR-FAR-006',
        p: {
          'drug': late.first.record.title,
          'time':
              '${at.hour.toString().padLeft(2, '0')}:'
              '${at.minute.toString().padLeft(2, '0')}',
        },
        action: '',
      );
    }

    // Feci troppo dure (scala Purina 1).
    if (h48.any((l) => l.type == LogType.cacca && l.value == 1)) {
      add(AlertLevel.info, 'ALR-GI-014');
    }

    // Modalità post-operatoria (07 aggiunta N8).
    final surgeries =
        records
            .where(
              (r) =>
                  r.dogId == dog.id &&
                  r.type == RecordType.intervento &&
                  r.done &&
                  !r.date.isAfter(now) &&
                  now.difference(r.date).inDays < 14,
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final wound = mine
        .where(
          (l) =>
              l.type == LogType.ferita && now.difference(l.time).inHours <= 48,
        )
        .toList();
    if (wound.any(
      (l) => hasSign(l, Sign.deiscenza) || hasSign(l, Sign.sanguinamento),
    )) {
      add(AlertLevel.oggi, 'ALR-CHI-001', rank: 7);
    } else if (wound.any(
      (l) =>
          hasSign(l, Sign.arrossamento) ||
          hasSign(l, Sign.gonfiore) ||
          hasSign(l, Sign.secrezione),
    )) {
      add(AlertLevel.attenzione, 'ALR-CHI-002');
    }
    if (surgeries.isNotEmpty) {
      final s0 = surgeries.first.date;
      final hrs = now.difference(s0).inHours;
      final ateSince = mine.any(
        (l) => l.type == LogType.pasto && l.time.isAfter(s0),
      );
      final active = mine.any((l) => l.time.isAfter(s0));
      if (hrs >= 48 && !ateSince && active) {
        add(AlertLevel.oggi, 'ALR-CHI-003');
      }
    }

    // Forasacchi in stagione (07 aggiunta N9).
    if (now.month >= 5 && now.month <= 8) {
      final fox = h24.any(
        (l) =>
            (l.type == LogType.pelle &&
                hasSign(l, Sign.otite) &&
                hasSign(l, Sign.improvviso)) ||
            hasSign(l, Sign.starnuti),
      );
      if (fox) {
        add(AlertLevel.oggi, 'ALR-ALT-006');
      }
    }

    // 13. Scadenze superate.
    final overdue = dueItems(
      records,
      dog.id,
    ).where((d) => d.overdue(now)).toList();
    final coreOverdue = overdue.any(
      (d) =>
          d.record.type == RecordType.vaccino &&
          d.record.title.toLowerCase().contains('core'),
    );
    if (puppy && coreOverdue) {
      add(AlertLevel.attenzione, 'ALR-PRV-001');
    }
    if (overdue.isNotEmpty) {
      add(
        AlertLevel.info,
        'ALR-PRV-002',
        p: {
          'count': overdue.length,
          'items': overdue.take(3).map((d) => d.record.title).join(' · '),
        },
        action: '',
      );
    }

    return sortAndDedup(out);
  }

  /// Ordine: livello, poi priorità clinica (07 N25). Gli avvisi con lo
  /// stesso ID del catalogo compaiono una volta sola, con il livello più
  /// alto. Prima il confronto era sul titolo, che contiene numeri e cambia
  /// con la lingua (ricerca/15 §3.3).
  static List<HealthAlert> sortAndDedup(List<HealthAlert> out) {
    out.sort((a, b) {
      final c = b.level.index.compareTo(a.level.index);
      return c != 0 ? c : a.rank.compareTo(b.rank);
    });
    final seen = <String>{};
    out.retainWhere((a) => seen.add(a.id.isEmpty ? 'titolo:${a.title}' : a.id));
    return out;
  }
}
