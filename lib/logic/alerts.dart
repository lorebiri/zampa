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
  String? get action => switch (this) {
    AlertLevel.subito => 'Vai subito dal veterinario o al pronto soccorso veterinario, anche di notte.',
    AlertLevel.oggi => 'Contatta il veterinario oggi stesso.',
    AlertLevel.attenzione =>
      'Senti il veterinario nei prossimi 1-2 giorni; prima se peggiora.',
    AlertLevel.info => 'Parlane alla prossima visita.',
  };
}

class HealthAlert {
  HealthAlert(
    this.level,
    this.title,
    this.message, {
    this.action,
    this.rank = 50,
  });
  final AlertLevel level;
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

const _confusion =
    'Lo sforzo per urinare e quello per defecare si confondono facilmente: '
    'se non sei sicuro, consideralo un problema urinario.';

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
      String t,
      String m, {
      String? action,
      int rank = 50,
    }) => out.add(HealthAlert(l, t, m, action: action, rank: rank));
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

    // 1. Sforzo a urinare (possibile ostruzione nel maschio: emergenza).
    bool strain(LogEntry l) =>
        l.type == LogType.pipi &&
        (hasSign(l, Sign.sforzo) || hasSign(l, Sign.gocce));
    final strain12 = h12.where(strain).length;
    final strain24 = h24.where(strain).length;
    if (male && strain12 >= 1) {
      add(
        AlertLevel.subito,
        'Sforzo a urinare: possibile urgenza',
        'Se $name si mette in posizione e non esce urina, o escono solo poche '
            'gocce, contatta subito il veterinario o un pronto soccorso '
            'veterinario, anche di notte. Nel maschio un blocco delle vie '
            'urinarie è un\'emergenza: non aspettare il giorno dopo. $_confusion',
      );
    } else if (!male && strain24 >= 2) {
      add(
        AlertLevel.oggi,
        'Sforzo a urinare ripetuto',
        'Più tentativi con sforzo o poche gocce in 24 ore. Contatta il '
            'veterinario oggi stesso; subito se non esce urina. $_confusion',
      );
    } else if (!male && strain24 == 1) {
      add(
        AlertLevel.attenzione,
        'Pipì con sforzo o a gocce',
        'Osserva le prossime pipì. Se non riesce a urinare affatto, contatta '
            'subito il veterinario. $_confusion',
      );
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
          'Cucciolo senza pipì da ${awakeHours.round()} ore da sveglio',
          'Un cucciolo sveglio urina molto più spesso. Se non è una '
              'registrazione mancante, contatta subito il veterinario. Se '
              'escono solo gocce, conta come se non avesse urinato.',
          rank: 5,
        );
      } else if (hours >= 24 && hours < 72) {
        add(
          AlertLevel.subito,
          'Nessuna pipì da ${hours.round()} ore',
          'Se $name non ha davvero urinato (e non è solo una registrazione '
              'mancante), è un\'urgenza, specie nei maschi. Se escono solo '
              'gocce, conta come se non avesse urinato.',
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
          'Nessuna pipì registrata da ${hours.round()} ore',
          '${spine ? 'Dopo una chirurgia della colonna, se non riesce a urinare '
                        'da solo chiama il veterinario oggi: alcuni cani devono '
                        'essere aiutati a svuotare la vescica. ' : ''}'
              'Portalo fuori e osserva: se prova a urinare senza riuscirci, è '
              'abbattuto o vomita, contatta subito il veterinario. Se non '
              'urina entro 24 ore in totale è comunque un\'urgenza.',
          action: '',
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
        add(
          AlertLevel.oggi,
          'Sangue nelle urine con malessere',
          'Sangue nelle urine insieme a vomito o abbattimento richiede una '
              'visita oggi stesso.',
        );
      } else if (inHeat && strain24 == 0) {
        add(
          AlertLevel.info,
          'Sangue durante il calore',
          'In calore è normale una perdita di sangue dalla vulva. Se il '
              'sangue è nelle urine stesse, se si sforza o se il calore dura '
              'più di 3-4 settimane, senti il veterinario.',
        );
      } else {
        add(
          AlertLevel.attenzione,
          'Sangue nelle urine',
          'Va sempre valutato dal veterinario entro 24-48 ore: può essere un '
              'segno di cistite o calcoli (solo il veterinario può dirlo). '
              'Se possibile raccogli un campione di urina.',
        );
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
        'Pipì piccole e frequenti',
        '${raw2h.length} pipì in 2 ore. Può essere un segno di cistite (solo '
            'il veterinario può dirlo): sentilo entro 24-48 ore, subito se c\'è '
            'sforzo senza urina.',
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
      add(
        AlertLevel.subito,
        'Conati a vuoto o addome gonfio',
        'Conati senza riuscire a vomitare, addome gonfio, agitazione e '
            'salivazione possono indicare una torsione/dilatazione dello '
            'stomaco: è un\'emergenza in cui ogni minuto conta.',
        rank: 0,
      );
    }
    if (h24.any((l) => l.type == LogType.collasso)) {
      add(
        AlertLevel.subito,
        'Collasso o svenimento',
        'Un collasso o uno svenimento va sempre valutato subito, anche se '
            'si è ripreso: può dipendere da cuore, emorragia o calo di zuccheri.',
        rank: 1,
      );
    }
    final vomit = vomits24.isNotEmpty, diarrhea = diarrhea24 > 0;
    final puppyGI =
        puppy &&
        ((vomit && diarrhea) || ((vomit || diarrhea) && (down24 || inapp24)));
    if (puppyGI) {
      add(
        bloodStool || downEvent24 ? AlertLevel.subito : AlertLevel.oggi,
        'Cucciolo con vomito o diarrea',
        'Nei cuccioli vomito e diarrea insieme, o con abbattimento o '
            'inappetenza, richiedono una visita oggi stesso: la disidratazione '
            'è rapida e va esclusa la parvovirosi, soprattutto se non ha '
            'completato i vaccini. Subito se è molto abbattuto, ha sangue nelle '
            'feci o non trattiene l\'acqua.',
        rank: 10,
      );
    }
    final diabeticGI = diabetic && (vomit || down24);
    if (diabeticGI) {
      add(
        vomit && down24 ? AlertLevel.subito : AlertLevel.oggi,
        'Diabetico con vomito o abbattimento',
        'Non fare l\'insulina senza aver sentito il veterinario. Vomito e '
            'abbattimento in un cane diabetico vanno valutati oggi stesso; '
            'subito se è molto debole, respira in modo strano o non beve.',
        rank: 8,
      );
    }
    if (activeDrugs.contains(DrugEffect.trilostano) &&
        (vomit || diarrhea || down24 || inapp24)) {
      add(
        AlertLevel.subito,
        'Malessere durante la terapia per il Cushing',
        'Durante la terapia per il Cushing questi segni possono indicare un '
            'calo eccessivo del cortisolo: sospendi la prossima dose solo se te '
            'lo dice il veterinario e chiamalo subito.',
        rank: 9,
      );
    }
    if (onNsaidOrSteroid && !vomit && (inapp24 || down24)) {
      add(
        AlertLevel.oggi,
        'Non mangia o è abbattuto durante antinfiammatori/cortisone',
        'Può essere un effetto collaterale sullo stomaco: chiama il '
            'veterinario oggi. Non sospendere né aggiungere farmaci di tua '
            'iniziativa.',
      );
    }
    if (activeDrugs.contains(DrugEffect.fans) &&
        activeDrugs.contains(DrugEffect.cortisonico)) {
      add(
        AlertLevel.attenzione,
        'Antinfiammatori e cortisone insieme',
        'Antinfiammatori e cortisone insieme aumentano il rischio di ulcere: '
            'verifica col veterinario che sia voluto.',
      );
    }
    final bloodVomit = vomits24.any((l) => hasSign(l, Sign.sangue));
    if (bloodVomit) {
      add(
        AlertLevel.oggi,
        'Vomito con sangue',
        'Sangue o materiale scuro "a fondi di caffè" nel vomito: visita oggi '
            'stesso; subito se è abbattuto o ha le gengive pallide.',
      );
    }
    final tiny = puppy || dog.weightKg < 5;
    if (onNsaidOrSteroid && vomits24.isNotEmpty) {
      add(
        AlertLevel.subito,
        'Vomito durante la terapia con antinfiammatori o cortisone',
        'Chiama subito il veterinario: può essere un effetto collaterale '
            'sullo stomaco. Non sospendere né aggiungere farmaci di tua '
            'iniziativa.',
      );
    } else if (!bloodVomit && !gdv && !puppyGI && !diabeticGI) {
      if (tiny && vomits24.length >= 2) {
        add(
          AlertLevel.oggi,
          'Vomito ripetuto in un cane piccolo',
          'Nei cuccioli e nei cani sotto i 5 kg disidratazione e ipoglicemia '
              'arrivano in fretta.',
        );
      } else if (vomits24.length >= 3 || (vomits24.isNotEmpty && depressed24)) {
        add(
          AlertLevel.attenzione,
          'Vomito ripetuto',
          '${vomits24.length} episodi in 24 ore. Senti il veterinario entro '
              '24 ore; subito se non trattiene nemmeno l\'acqua o è molto '
              'abbattuto.',
        );
      } else if (vomits24.length == 1) {
        add(
          AlertLevel.info,
          'Ha vomitato una volta',
          'Osserva: se si ripete, se è abbattuto o compaiono altri segni, '
              'senti il veterinario.',
        );
      }
    }

    // 6. Feci con sangue o nere, diarrea.
    final black = poops48.any((l) => hasSign(l, Sign.nero));
    if (black) {
      add(
        onNsaidOrSteroid ? AlertLevel.subito : AlertLevel.oggi,
        'Feci nere',
        onNsaidOrSteroid
            ? 'Feci nere durante una terapia con antinfiammatori o cortisone: '
                  'chiama subito il veterinario, potrebbe trattarsi di un '
                  'sanguinamento dello stomaco.'
            : 'Feci nere come catrame possono indicare sangue digerito: '
                  'serve una visita oggi.',
      );
    }
    if (bloodStool) {
      if (puppy && !puppyGI) {
        add(
          AlertLevel.oggi,
          'Cucciolo con sangue nelle feci',
          'Nei cuccioli la diarrea con sangue richiede una visita oggi stesso '
              '(va esclusa la parvovirosi, soprattutto se non ha completato i '
              'vaccini).',
        );
      } else if (vomits24.isNotEmpty || depressed24) {
        add(
          AlertLevel.oggi,
          'Sangue nelle feci con vomito o abbattimento',
          'Questa combinazione richiede una visita oggi stesso.',
        );
      } else {
        add(
          AlertLevel.attenzione,
          'Sangue rosso nelle feci',
          'Se si ripete, se c\'è diarrea abbondante o se cambia il suo '
              'comportamento, senti il veterinario entro 24-48 ore.',
        );
      }
    }
    if (puppy && diarrhea24 >= 2 && !bloodStool && !puppyGI) {
      add(
        AlertLevel.oggi,
        'Cucciolo con diarrea',
        'Nei cuccioli la disidratazione è rapida e va esclusa la parvovirosi: '
            'subito se vomita o è abbattuto.',
      );
    } else if (!puppy &&
        !diabeticGI &&
        (diarrhea24 >= 3 || (diarrhea24 >= 1 && vomits24.isNotEmpty))) {
      add(
        AlertLevel.attenzione,
        'Diarrea${vomits24.isNotEmpty ? ' e vomito' : ''} nelle ultime 24 ore',
        'Assicurati che beva. Se persiste oltre 24-48 ore, se è abbattuto o '
            'vomita ripetutamente, senti il veterinario.',
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
          'Nessuna cacca da ${h.round()} ore',
          'Se non è una registrazione mancante: controlla che beva e si muova. '
              'Se si sforza senza risultato, vomita o è abbattuto, senti il '
              'veterinario. $_confusion',
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
    // Con farmaci o malattie che aumentano la pipì la soglia sale (06 §PU).
    // Solo il fattore clinico: taglia e dieta non giustificano una soglia
    // più alta (terza revisione veterinaria, ricerca/26 A2).
    final clinicalFactor = BioParams.modifier(
      Need.pipi,
      dog,
      records,
      now,
    ).clinical;
    final expectedRise = clinicalFactor < 0.8 ? 2.5 : 1.5;
    var moreUrine = false;
    if (last3 > 0 &&
        base > 0 &&
        last3 >= base * expectedRise &&
        last3 - base >= 2) {
      moreUrine = true;
      add(
        AlertLevel.attenzione,
        'Fa pipì più spesso del solito',
        'Negli ultimi 3 giorni ${last3.toStringAsFixed(1)} uscite al giorno '
            'contro ${base.toStringAsFixed(1)} abituali. Può essere un segno '
            'di infezione urinaria, diabete o problemi renali (solo il '
            'veterinario può dirlo): parlane entro qualche giorno.'
            '${Modules.diabetic(dog, records) ? ' In un cane diabetico segnalalo al veterinario: la terapia potrebbe andare rivista.' : ''}',
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
        add(
          AlertLevel.attenzione,
          'Beve molto',
          'In media ${mean.round()} ml al giorno, oltre i 100 ml/kg. La sete '
              'eccessiva può essere un segno di malattie da approfondire '
              '(solo il veterinario può dirlo). Non ridurre l\'acqua: parlane '
              'con il veterinario.',
        );
      } else if (dog.diet == DietType.secco && mean < dog.weightKg * 20) {
        add(
          AlertLevel.attenzione,
          'Beve poco',
          'Con le crocchette ${mean.round()} ml al giorno sono pochi (meno di '
              '20 ml/kg). Se non è una registrazione incompleta e mangia poco o '
              'è abbattuto, senti il veterinario.',
        );
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
        add(
          AlertLevel.oggi,
          'Attenzione all\'utero (piometra)',
          'In una femmina non sterilizzata, nelle settimane dopo il calore, '
              'sete e pipì aumentate, perdite dalla vulva, vomito o '
              'abbattimento possono indicare un\'infezione dell\'utero '
              '(piometra), che è un\'urgenza.',
          rank: 12,
        );
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
          'Femmina non sterilizzata: attenzione all\'utero',
          'Se è stata in calore negli ultimi 2-3 mesi può trattarsi di '
              'un\'infezione dell\'utero (piometra), che è un\'urgenza: '
              '${n >= 2 ? 'contatta il veterinario oggi stesso' : 'osservala e senti il veterinario se compaiono altri segni'}. '
              'Registra i calori nella sezione Riproduzione: Zampa potrà '
              'avvisarti meglio.',
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
        add(
          AlertLevel.attenzione,
          'Pipì in casa ripetute',
          '$n incidenti in 7 giorni in un cane adulto. Le cause possibili sono '
              'infezione urinaria, aumento della sete, incontinenza (frequente '
              'nelle femmine sterilizzate di taglia media e grande), declino '
              'cognitivo nell\'anziano, oppure intervalli troppo lunghi tra le '
              'uscite. Vale la pena parlarne con il veterinario. Se le perdite '
              'avvengono mentre dorme o riposa, registrale come "Perdita di '
              'urina a riposo".',
        );
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
          add(
            AlertLevel.attenzione,
            'Il cucciolo non cresce',
            'Un cucciolo dovrebbe aumentare di peso ogni settimana: se il peso '
                'è fermo da 2 settimane o cala, senti il veterinario; subito se '
                'mangia poco, vomita o ha diarrea.',
          );
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
          add(
            AlertLevel.attenzione,
            'Sta dimagrendo troppo in fretta',
            'Oltre il 2% a settimana: un dimagrimento troppo rapido non è '
                'sano. Senti il veterinario per rivedere la dieta.',
          );
        } else if (change90 <= -0.10 ||
            (stage == LifeStage.anziano && change90 <= -0.05)) {
          add(
            AlertLevel.attenzione,
            'Calo di peso del ${(-change90 * 100).toStringAsFixed(0)}%',
            'Un calo di peso non voluto merita una visita, soprattutto '
                'nel cane anziano.',
          );
        } else if (change90 <= -0.05 && dog.bodyCondition < 7) {
          add(
            AlertLevel.info,
            'Calo di peso del ${(-change90 * 100).toStringAsFixed(0)}%',
            'Tienilo d\'occhio: se continua senza che tu abbia cambiato la '
                'dieta, senti il veterinario.',
          );
        } else if (change90 >= 0.10) {
          add(
            AlertLevel.info,
            'Aumento di peso del ${(change90 * 100).toStringAsFixed(0)}%',
            'Controlla razione e snack nella sezione Nutrizione.',
          );
        }
      }
    }
    if (ageM >= 12 && dog.bodyCondition <= 3) {
      add(
        AlertLevel.attenzione,
        'Sottopeso',
        'Prima di aumentare la razione fallo visitare, per escludere cause '
            'mediche.',
      );
    } else if (dog.bodyCondition >= 7) {
      add(
        AlertLevel.info,
        'Sovrappeso',
        'Body Condition Score ${dog.bodyCondition}/9: la razione in '
            'Nutrizione è calcolata per un dimagrimento graduale. Prima di '
            'iniziare fai visitare il cane.',
      );
    } else if (dog.bodyCondition == 6) {
      add(
        AlertLevel.info,
        'Leggermente sovrappeso',
        'Riduci gli snack e ricontrolla tra un mese.',
      );
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
      final what = last.note.isNotEmpty ? ': ${last.note}' : '';
      if (now.difference(last.time).inHours < 12) {
        add(
          AlertLevel.subito,
          'Ha ingerito qualcosa$what',
          'Chiama subito il veterinario o un centro antiveleni, anche se sta '
              'bene. Non provocare il vomito di tua iniziativa. Tieni a portata '
              'la confezione o una foto dell\'etichetta.',
          rank: 3,
        );
      } else {
        add(
          AlertLevel.attenzione,
          'Sorveglianza dopo un\'ingestione',
          'Il ${last.time.day}/${last.time.month} ha ingerito$what. Alcuni '
              'veleni (es. topicidi) danno sintomi dopo giorni: sangue dal naso '
              'o dalle gengive, lividi, debolezza, vomito o pipì scarsa → subito '
              'dal veterinario.',
          action: '',
        );
      }
    }

    // Gengive.
    final gums = h24.where((l) => l.type == LogType.gengive).toList();
    if (gums.any(
      (l) => hasSign(l, Sign.gengivePallide) || hasSign(l, Sign.gengiveBlu),
    )) {
      add(
        AlertLevel.subito,
        'Gengive pallide o blu',
        'Possono indicare un problema di circolazione, respirazione o '
            'un\'emorragia: è un\'emergenza.',
        rank: 2,
      );
    } else if (gums.any((l) => hasSign(l, Sign.gengiveRosse))) {
      add(
        AlertLevel.subito,
        'Gengive rosso scuro',
        'Gengive rosso scuro, soprattutto dopo caldo o sforzo, possono '
            'indicare un colpo di calore o uno shock: raffreddalo con acqua '
            '(vedi Emergenze) e vai subito dal veterinario.',
        rank: 2,
      );
    } else if (gums.any((l) => hasSign(l, Sign.gengiveGialle))) {
      add(
        AlertLevel.oggi,
        'Gengive gialle',
        'Il colore giallo (ittero) va valutato dal veterinario oggi stesso.',
      );
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
          'Respira molto veloce nel sonno (${rate.round()}/min)',
          'Oltre 40 respiri al minuto a riposo: possibile difficoltà '
              'respiratoria o cardiaca.',
          rank: 1,
        );
      } else if (rate > 40) {
        add(
          AlertLevel.oggi,
          'Respiri nel sonno oltre 40/min',
          'Rimisura tra 15-30 minuti mentre dorme tranquillo. Se resta sopra '
              '40, o respira con fatica a bocca aperta, vai subito dal '
              'veterinario.',
          rank: 4,
        );
      } else if (rate > 30 && prevRecent && prev.value! > 30) {
        add(
          AlertLevel.oggi,
          'Respiri nel sonno sopra 30/min',
          'Due misure di fila sopra 30 respiri al minuto: segnalalo al '
              'veterinario oggi, soprattutto se ha una malattia di cuore.',
          rank: 4,
        );
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
            'Respiri nel sonno in aumento',
            'Media della settimana ${week.round()}/min contro '
                '${month.round()}/min del mese precedente: segnalalo al '
                'veterinario oggi.',
          );
        }
      }
    }
    final coughs = mine.where((l) => l.type == LogType.tosse).toList();
    final cavalier = dog.breed.toLowerCase().contains('cavalier');
    if (dyspnea) {
      add(
        AlertLevel.subito,
        'Fatica a respirare',
        'Respiro affannoso a riposo, bocca aperta o lingua scura: '
            'tienilo calmo e al fresco e vai subito dal veterinario.',
        rank: 1,
      );
    } else if (coughs.isNotEmpty &&
        now.difference(coughs.last.time).inHours <= 24) {
      final recent = coughs
          .where((l) => now.difference(l.time).inDays <= 7)
          .toList();
      final spanDays = now.difference(recent.first.time).inDays;
      if (cardiac) {
        add(
          AlertLevel.oggi,
          'Tosse in un cane con malattia di cuore',
          'Nei cardiopatici la tosse va segnalata al veterinario oggi.',
        );
      } else if (cavalier) {
        add(
          AlertLevel.attenzione,
          'Tosse in un Cavalier King',
          'Il Cavalier è predisposto alla malattia della valvola mitrale: '
              'segnala la tosse al veterinario e conta i respiri nel sonno.',
        );
      } else if (spanDays >= 3 || down24) {
        add(
          AlertLevel.attenzione,
          'Tosse da più giorni',
          'Tosse che dura da più di 3 giorni o con abbattimento: senti il '
              'veterinario entro 24-48 ore. Evita il contatto con altri cani.',
        );
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
          'Glicemia bassa (${g.round()} mg/dL)',
          'Possibile ipoglicemia. Se è cosciente strofina miele o glucosio '
              'sulle gengive (mai liquidi in bocca a un cane incosciente) e '
              'chiama subito il veterinario. Non fare la prossima insulina '
              'senza averlo sentito.',
          rank: 2,
        );
      } else if (g < 80) {
        add(
          AlertLevel.oggi,
          'Glicemia al limite basso (${g.round()} mg/dL)',
          'Segnalala al veterinario oggi, prima della prossima insulina.',
        );
      } else if (g > 400) {
        add(
          vomit || down24 || inapp24 ? AlertLevel.oggi : AlertLevel.attenzione,
          'Glicemia alta (${g.round()} mg/dL)',
          'Segnalala al veterinario: la terapia potrebbe andare rivista. Se '
              'vomita, è abbattuto o non mangia, oggi stesso.',
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
          'Due dosi di insulina ravvicinate',
          'Due dosi di insulina registrate a ${gapH.toStringAsFixed(1)} ore di '
              'distanza. Se le hai fatte davvero, chiama subito il veterinario: '
              'rischio di ipoglicemia. Se è un errore di registrazione, '
              'cancellane una.',
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
      add(
        AlertLevel.subito,
        'Tremori in una cagna che allatta',
        'Possibile eclampsia (calcio basso dopo il parto): è un\'emergenza. '
            'Allontana i cuccioli e vai subito dal veterinario.',
        rank: 1,
      );
    } else if (tinyPuppy &&
        (neuro.isNotEmpty || seiz24.isNotEmpty || downEvent24)) {
      add(
        AlertLevel.subito,
        'Cucciolo debole o tremante',
        'Nei cuccioli piccoli può essere un\'ipoglicemia. Se è cosciente '
            'strofina un po\' di miele sulle gengive, poi vai subito dal '
            'veterinario.',
        rank: 2,
      );
    } else if (seiz24.isNotEmpty) {
      final long = seiz24.any(
        (l) => (l.value ?? 0) >= 5 || hasSign(l, Sign.nonSiRiprende),
      );
      if (diabetic) {
        add(
          AlertLevel.subito,
          'Convulsione in un cane diabetico',
          'Può essere un\'ipoglicemia. Se è cosciente strofina un po\' di '
              'miele o glucosio sulle gengive (mai liquidi in bocca a un cane '
              'incosciente) e vai subito dal veterinario.',
          rank: 3,
        );
      } else if (long || seiz24.length >= 2) {
        add(
          AlertLevel.subito,
          long
              ? 'Convulsione lunga o senza ripresa'
              : '${seiz24.length} convulsioni in 24 ore',
          'Crisi oltre 5 minuti, crisi a grappolo o mancata ripresa sono '
          'un\'emergenza.',
          rank: 3,
        );
      } else if (seizures.length == 1) {
        add(
          AlertLevel.oggi,
          'Prima convulsione',
          'Una prima crisi va sempre valutata dal veterinario. Annota durata '
              'e cosa è successo prima e dopo.',
        );
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
          'Crisi più frequenti questo mese',
          '$cur crisi questo mese contro una media di ${prevAvg.toStringAsFixed(1)}: '
              'parlane con il veterinario, la terapia potrebbe andare rivista.',
        );
      }
    }

    // Tremori, barcollamento, testa inclinata.
    if (neuro.isNotEmpty && seiz24.isEmpty && !lactating && !tinyPuppy) {
      if (diabetic) {
        add(
          AlertLevel.subito,
          'Possibile ipoglicemia',
          'Tremori o barcollamento in un cane diabetico: se è cosciente '
              'strofina miele o glucosio sulle gengive e vai subito dal '
              'veterinario.',
          rank: 3,
        );
      } else {
        add(
          neuro.any((l) => hasSign(l, Sign.improvviso))
              ? AlertLevel.subito
              : AlertLevel.oggi,
          'Tremori, barcollamento o testa inclinata',
          'Segni neurologici: se sono comparsi all\'improvviso è un\'urgenza. '
              'Pensa anche a possibili sostanze ingerite.',
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
          'Temperatura ${t.toStringAsFixed(1)} °C',
          t >= 41
              ? 'Temperatura molto alta: possibile colpo di calore. '
                    'Raffreddalo subito con acqua fresca o fredda e fai aria, '
                    'poi vai subito dal veterinario.'
              : 'Temperatura troppo bassa: tienilo al caldo e vai subito dal veterinario.',
          rank: 2,
        );
      } else if (t >= 39.5) {
        add(
          AlertLevel.oggi,
          'Febbre (${t.toStringAsFixed(1)} °C)',
          'Normale 38,0-39,2 °C. Non dare antipiretici per persone (sono tossici).',
        );
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
        add(
          AlertLevel.oggi,
          'Non mangia',
          diabetic
              ? 'Se non ha mangiato o ha vomitato, non fare l\'insulina senza '
                    'aver sentito il veterinario.'
              : 'Pasti saltati: serve una visita oggi.',
        );
      } else if (!urgent && skipped24 >= mpd) {
        add(
          AlertLevel.attenzione,
          'Ha saltato i pasti',
          'Se non mangia da 24 ore senti il veterinario entro 1-2 giorni; '
              'prima se vomita o è abbattuto.',
          action: '',
        );
      }
    }
    if (downEvent24 && !puppyGI && !diabeticGI) {
      final other = vomit || diarrhea || inapp24;
      final fragile = puppy || diabetic || senior;
      add(
        other || fragile ? AlertLevel.oggi : AlertLevel.attenzione,
        'Abbattuto',
        other || fragile
            ? 'Abbattimento ${other ? 'insieme ad altri segni' : 'in un cane ${puppy
                            ? 'cucciolo'
                            : diabetic
                            ? 'diabetico'
                            : 'anziano'}'}: '
                  'contatta il veterinario oggi.'
            : 'Osservalo: se non torna vivace entro la giornata, o compaiono '
                  'vomito, diarrea, febbre o gengive pallide, senti il veterinario.',
        action: other || fragile ? null : '',
      );
    }

    // Diabete: insulina senza pasto (07 N15).
    if (diabetic &&
        h12.any(
          (l) => l.type == LogType.insulina && hasSign(l, Sign.nonHaMangiato),
        )) {
      add(
        AlertLevel.oggi,
        'Insulina fatta senza che abbia mangiato',
        'Chiama ora il veterinario e chiedi come comportarti. Nelle prossime '
            'ore offrigli il suo pasto e osservalo: se compaiono debolezza, '
            'tremori o barcollamento strofina miele sulle gengive e vai subito '
            'dal veterinario.',
      );
    }

    // Urina scura (07 aggiunta N6).
    final darkUrine = h48.any(
      (l) => l.type == LogType.pipi && hasSign(l, Sign.urinaScura),
    );
    if (darkUrine) {
      final fever = temps.any((l) => l.value! >= 39.5);
      final tickSeason = now.month >= 3 && now.month <= 11;
      add(
        down24 || fever ? AlertLevel.oggi : AlertLevel.attenzione,
        'Urina scura o color caffè',
        'Urine scure, soprattutto con abbattimento, possono indicare una '
            'distruzione dei globuli rossi (es. malattie trasmesse dalle zecche '
            'come la babesiosi) o un danno muscolare. '
            '${tickSeason ? 'Hai trovato zecche di recente? Dillo al veterinario. ' : ''}'
            '${down24 || fever ? 'Con abbattimento o febbre serve una visita oggi.' : 'Se si ripete, senti il veterinario.'}',
      );
    }

    // Razze MDR1 con loperamide (07 N49).
    if (activeDrugs.contains(DrugEffect.antidiarroico) &&
        RegExp(
          'collie|pastore australiano|australian|shetland|bobtail|'
          'pastore inglese|whippet|silken|pastore svizzero|mcnab|'
          'pastore scozzese',
        ).hasMatch(dog.breed.toLowerCase())) {
      add(
        AlertLevel.attenzione,
        'Loperamide in una razza a rischio MDR1',
        'Nelle razze con possibile mutazione MDR1 la loperamide può dare '
            'effetti neurologici: verifica con il veterinario.',
      );
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
        add(
          AlertLevel.oggi,
          'Malessere nella prima settimana dopo il parto',
          'Febbre, perdite maleodoranti o abbattimento dopo il parto possono '
              'indicare un\'infezione dell\'utero: contatta il veterinario oggi.',
        );
      }
    }
    if (!male && h24.any((l) => l.type == LogType.mammelle)) {
      add(
        AlertLevel.oggi,
        'Mammelle gonfie, calde o dolenti',
        'Può essere una mastite: contatta il veterinario oggi. Non '
            'spremere le mammelle.',
      );
    }
    final dueSoon = Modules.dueDate(dog, repro, now);
    if (dueSoon != null && dueSoon.difference(now).inDays <= 7) {
      final low = temps.where((l) => l.value! < 37.5).toList();
      if (low.isNotEmpty) {
        final hrs = now.difference(low.first.time).inHours;
        add(
          hrs > 24 ? AlertLevel.oggi : AlertLevel.info,
          hrs > 24
              ? 'Temperatura calata da oltre 24 ore senza parto'
              : 'Parto atteso entro circa 24 ore',
          hrs > 24
              ? 'Il calo di temperatura sotto 37,5 °C precede il parto: se dopo '
                    '24 ore non è iniziato il travaglio, chiama il veterinario.'
              : 'La temperatura sotto 37,5 °C di solito precede il parto di '
                    'circa 24 ore. Prepara la cassa parto.',
          action: hrs > 24 ? null : '',
        );
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
      add(
        AlertLevel.oggi,
        'Non appoggia la zampa',
        'Non caricare l\'arto è un segno di dolore importante: visita oggi. '
            'Non dare antidolorifici per persone.',
      );
    } else if (limp.isNotEmpty && now.difference(limp.first.time).inDays >= 3) {
      add(
        AlertLevel.attenzione,
        'Zoppia da più giorni',
        'Una zoppia che dura da 3-5 giorni va vista dal veterinario.',
      );
    }
    if (typeIn(h48, LogType.pelle)) {
      add(
        AlertLevel.attenzione,
        'Prurito, pelle o orecchie',
        'Senti il veterinario entro qualche giorno; prima se si gratta fino '
            'a ferirsi o scuote molto la testa.',
      );
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
      add(
        AlertLevel.attenzione,
        'Problema ai denti',
        'Alito cattivo, gengive che sanguinano o fatica a masticare: '
            'controllo dentale al prossimo appuntamento, prima se mangia poco.',
      );
    }
    final brushed = teeth.where((l) => hasSign(l, Sign.spazzolati)).length;
    if (mine.any(
          (l) => l.type == LogType.denti && hasSign(l, Sign.spazzolati),
        ) &&
        brushed < 3) {
      add(
        AlertLevel.info,
        'Denti: $brushed spazzolature in 7 giorni',
        'Ideale ogni giorno, almeno 3 volte a settimana (AAHA 2019).',
      );
    }

    // Perdite a riposo (incontinenza) e perdite vulvari.
    if (mine.any(
      (l) =>
          l.type == LogType.perditaRiposo && now.difference(l.time).inDays <= 7,
    )) {
      add(
        AlertLevel.attenzione,
        'Perdite di urina a riposo',
        'Perdite mentre dorme o riposa: spesso è un problema curabile '
            '(incontinenza). Parlane con il veterinario. Non ridurre l\'acqua.',
      );
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
        add(
          AlertLevel.oggi,
          'Perdite purulente',
          'Perdite purulente in una femmina non sterilizzata possono indicare '
              'un\'infezione dell\'utero: contatta il veterinario oggi stesso.',
          rank: 12,
        );
      } else if (!inHeatNow) {
        add(
          purulent ? AlertLevel.oggi : AlertLevel.attenzione,
          'Perdite vulvari',
          'Perdite fuori dal calore vanno valutate dal veterinario entro '
              '1-2 giorni; oggi stesso se è abbattuta, beve molto o le perdite '
              'sono purulente.',
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
      add(
        AlertLevel.attenzione,
        'Pipì di notte, prima non succedeva',
        'Due o più notti su 7 con pipì notturna: può essere un segno di '
            'sete aumentata o di un problema urinario. Prenota una visita.',
      );
    }

    // Riproduzione.
    final due = Modules.dueDate(dog, repro, now);
    if (due != null) {
      final daysFromMating = 63 - due.difference(now).inDays;
      if (daysFromMating > 70) {
        add(
          AlertLevel.oggi,
          'Gravidanza oltre i 70 giorni',
          'Il parto non è ancora avvenuto: contatta il veterinario oggi.',
        );
      } else if (daysFromMating >= 58) {
        add(
          AlertLevel.info,
          'Parto vicino (presunto il ${due.day}/${due.month})',
          'Prepara la cassa parto. Chiama subito il veterinario se: '
              'contrazioni forti per oltre 30 minuti senza cuccioli, oltre 2 ore '
              'tra un cucciolo e l\'altro, perdite verdi o nere senza cuccioli.',
          action: '',
        );
      }
    }
    if (Modules.longHeat(dog, repro, now)) {
      add(
        AlertLevel.attenzione,
        'Calore che dura da oltre 4 settimane',
        'Un calore persistente va valutato dal veterinario. Se è già finito, '
            'registra "Fine calore".',
      );
    }

    // Dosi non confermate da oltre 2 ore.
    final late = pendingDoses
        .where((p) => now.difference(p.at).inMinutes >= 120)
        .toList();
    if (late.isNotEmpty) {
      add(
        AlertLevel.attenzione,
        'Dose non confermata: ${late.first.record.title}',
        'Prevista alle ${late.first.at.hour.toString().padLeft(2, '0')}:'
            '${late.first.at.minute.toString().padLeft(2, '0')}. Se l\'hai '
            'saltata, non raddoppiare la successiva: chiedi al veterinario '
            'cosa fare.',
        action: '',
      );
    }

    // Feci troppo dure (scala Purina 1).
    if (h48.any((l) => l.type == LogType.cacca && l.value == 1)) {
      add(
        AlertLevel.info,
        'Feci molto dure',
        'Punteggio 1 della scala fecale: controlla che beva abbastanza. Se si '
            'sforza senza risultato, senti il veterinario.',
      );
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
      add(
        AlertLevel.oggi,
        'Ferita aperta o che sanguina',
        'Punti aperti o sanguinamento della ferita: copri con una garza '
            'pulita, impedisci che si lecchi e contatta il veterinario oggi. '
            'Subito se il sanguinamento è abbondante o si vede tessuto interno.',
        rank: 7,
      );
    } else if (wound.any(
      (l) =>
          hasSign(l, Sign.arrossamento) ||
          hasSign(l, Sign.gonfiore) ||
          hasSign(l, Sign.secrezione),
    )) {
      add(
        AlertLevel.attenzione,
        'Ferita arrossata, gonfia o con secrezione',
        'Può essere un\'infiammazione o un\'infezione della ferita: '
            'mantieni il collare elisabettiano e senti il veterinario entro '
            '1-2 giorni; prima se peggiora o compare febbre.',
      );
    }
    if (surgeries.isNotEmpty) {
      final s0 = surgeries.first.date;
      final hrs = now.difference(s0).inHours;
      final ateSince = mine.any(
        (l) => l.type == LogType.pasto && l.time.isAfter(s0),
      );
      final active = mine.any((l) => l.time.isAfter(s0));
      if (hrs >= 48 && !ateSince && active) {
        add(
          AlertLevel.oggi,
          'Non ha ancora mangiato dopo l\'intervento',
          'L\'appetito di solito torna entro 24-48 ore dall\'intervento: '
              'contatta il veterinario oggi.',
        );
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
        add(
          AlertLevel.oggi,
          'Possibile forasacco',
          'In stagione dei forasacchi, scuotere la testa o starnutire '
              'all\'improvviso dopo un prato richiede una visita oggi: prima si '
              'toglie, meno danni fa.',
        );
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
      add(
        AlertLevel.attenzione,
        'Ciclo vaccinale non completo',
        'Finché non è completo, evita aree frequentate da cani sconosciuti e '
            'chiama il veterinario per fissare la dose.',
      );
    }
    if (overdue.isNotEmpty) {
      add(
        AlertLevel.info,
        overdue.length == 1
            ? 'Una scadenza superata'
            : '${overdue.length} scadenze superate',
        overdue.take(3).map((d) => d.record.title).join(' · '),
        action: '',
      );
    }

    // Ordine: livello, poi priorità clinica (07 N25), senza duplicati.
    out.sort((a, b) {
      final c = b.level.index.compareTo(a.level.index);
      return c != 0 ? c : a.rank.compareTo(b.rank);
    });
    final seen = <String>{};
    out.retainWhere((a) => seen.add(a.title));
    return out;
  }
}
