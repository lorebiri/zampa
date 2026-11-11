import '../l10n/clinical_text.dart';
import '../models.dart';
import 'potty_predictor.dart';

/// Consigli informativi (mai diagnosi): stagione e area geografica (ESCCAP
/// Italia), predisposizioni di razza, cucciolo. Revisione veterinaria 06,
/// aggiunte 6, 14, 15, 21.
class Tip {
  const Tip(this.title, this.text, {this.icon = 'info'});
  final String title;
  final String text;
  final String icon;
}

/// Consiglio del catalogo clinico (STG, RAZ, CUC): titolo e testo per ID.
Tip _tip(String id, {Map<String, Object> p = const {}, String icon = 'info'}) {
  final t = ClinicalText(id, p);
  return Tip(t.title, t.text, icon: icon);
}

class SeasonalTips {
  static List<Tip> forDog(Dog dog, DateTime now) {
    final m = now.month;
    final out = <Tip>[];
    if (m >= 2 && m <= 5) {
      out.add(_tip('STG-001', icon: 'warning'));
    }
    if (m >= 5 && m <= 8) {
      out.add(_tip('STG-002'));
    }
    if (m >= 6 && m <= 9) {
      final atRisk =
          Breeds.isBrachy(dog.breed) ||
          lifeStageOf(dog, now) == LifeStage.anziano ||
          dog.bodyCondition >= 7 ||
          dog.conditions.toLowerCase().contains('cardi');
      out.add(
        _tip(
          'STG-003',
          p: {'atRisk': yesNo(atRisk), 'name': dog.name},
          icon: 'warning',
        ),
      );
    }
    if (m >= 10 || m <= 4) {
      out.add(_tip('STG-004'));
    }
    if (m >= 6 && m <= 11) {
      out.add(_tip('STG-005'));
    }
    if (m == 12 || m <= 2) {
      final fragile =
          dog.weightKg < 10 ||
          lifeStageOf(dog, now) == LifeStage.anziano ||
          lifeStageOf(dog, now) == LifeStage.cucciolo;
      out.add(
        _tip('STG-006', p: {'fragile': yesNo(fragile), 'name': dog.name}),
      );
    }
    final tickAllYear = dog.region != Region.nord;
    if (tickAllYear || (m >= 3 && m <= 11)) {
      out.add(_tip('STG-007', p: {'allYear': yesNo(tickAllYear)}));
    }
    final d = now.day;
    if ((m == 12 && d >= 20) || (m == 1 && d <= 2)) {
      out.add(_tip('STG-008'));
    }
    return out;
  }
}

class Breeds {
  static bool _has(String breed, List<String> ks) {
    final b = breed.toLowerCase();
    return ks.any(b.contains);
  }

  static bool isBrachy(String breed) => _has(breed, [
    'bulldog',
    'carlino',
    'pug',
    'boxer',
    'shih',
    'pechinese',
    'boston',
    'cavalier',
    'dogue',
    'bouledogue',
  ]);

  /// Predisposizioni note, solo informative.
  static List<Tip> predispositions(Dog dog) {
    final b = dog.breed;
    final out = <Tip>[];
    if (_has(b, [
              'alano',
              'pastore tedesco',
              'setter',
              'weimaraner',
              'dobermann',
              'bovaro',
              'san bernardo',
              'terranova',
              'basset',
              'bloodhound',
              'levriero',
              'akita',
            ]) &&
            !_has(b, ['piccolo levriero']) ||
        dog.weightKg >= 35) {
      out.add(_tip('RAZ-001'));
    }
    if (isBrachy(b)) {
      out.add(_tip('RAZ-002'));
    }
    if (_has(b, [
      'collie',
      'pastore australiano',
      'australian shepherd',
      'shetland',
      'bobtail',
      'pastore inglese',
      'whippet',
      'silken',
      'pastore svizzero',
      'mcnab',
      'pastore scozzese',
    ])) {
      out.add(_tip('RAZ-003'));
    }
    if (_has(b, ['dalmata'])) {
      out.add(_tip('RAZ-004'));
    }
    if (_has(b, ['bassotto', 'dachshund', 'corgi', 'basset'])) {
      out.add(_tip('RAZ-005'));
    }
    if (_has(b, ['yorkshire', 'chihuahua', 'pomerania', 'volpino', 'toy'])) {
      out.add(_tip('RAZ-006'));
    }
    if (_has(b, ['schnauzer nano', 'schnauzer mini', 'zwergschnauzer'])) {
      out.add(_tip('RAZ-007'));
    }
    if (_has(b, ['dobermann', 'doberman'])) {
      out.add(_tip('RAZ-008'));
    }
    if (_has(b, ['cocker'])) {
      out.add(_tip('RAZ-009'));
    }
    if (_has(b, ['bulldog francese', 'bouledogue', 'french bulldog'])) {
      out.add(_tip('RAZ-010'));
    }
    if (_has(b, ['cavalier'])) {
      out.add(_tip('RAZ-011'));
    }
    return out;
  }

  /// Età della sterilizzazione nelle taglie grandi (07 aggiunta N18):
  /// solo informazione, nessuna raccomandazione di età.
  static Tip? neuteringInfo(Dog dog, DateTime now) {
    final big =
        dog.adultSize == AdultSize.grande ||
        dog.adultSize == AdultSize.gigante ||
        dog.weightKg >= 25;
    if (dog.neutered || !big || dog.ageInMonths(now) > 24) return null;
    return _tip('RAZ-012');
  }

  /// Consigli per il cucciolo: socializzazione ed educazione al bisogno.
  static List<Tip> puppy(Dog dog, DateTime now) {
    final w = now.difference(dog.birthDate).inDays / 7;
    if (w > 26) return const [];
    return [if (w <= 16) _tip('CUC-001'), _tip('CUC-002')];
  }
}
