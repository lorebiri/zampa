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

class SeasonalTips {
  static List<Tip> forDog(Dog dog, DateTime now) {
    final m = now.month;
    final out = <Tip>[];
    if (m >= 2 && m <= 5) {
      out.add(
        const Tip(
          'Stagione della processionaria',
          'Evita le pinete e i nidi bianchi sui pini. Se il cane la tocca con '
              'la bocca (salivazione, lingua gonfia): subito dal veterinario, '
              'senza strofinare.',
          icon: 'warning',
        ),
      );
    }
    if (m >= 5 && m <= 8) {
      out.add(
        const Tip(
          'Stagione dei forasacchi',
          'Dopo i prati controlla orecchie, zampe (tra le dita) e narici. Se '
              'scuote la testa o starnutisce all\'improvviso, senti il veterinario.',
        ),
      );
    }
    if (m >= 6 && m <= 9) {
      final atRisk =
          Breeds.isBrachy(dog.breed) ||
          lifeStageOf(dog, now) == LifeStage.anziano ||
          dog.bodyCondition >= 7 ||
          dog.conditions.toLowerCase().contains('cardi');
      out.add(
        Tip(
          'Caldo: rischio colpo di calore',
          '${atRisk ? 'Per ${dog.name} il rischio è più alto. ' : ''}Passeggiate '
              'nelle ore fresche, mai lasciarlo in auto, sempre acqua fresca. '
              'Il 74% dei colpi di calore avviene durante lo sforzo.',
          icon: 'warning',
        ),
      );
    }
    if (m >= 10 || m <= 4) {
      out.add(
        const Tip(
          'Veleni per lumache e topi',
          'In questa stagione sono più usati nei giardini e negli orti: tienilo '
              'al guinzaglio vicino a coltivazioni e cantine.',
        ),
      );
    }
    if (m >= 6 && m <= 11) {
      out.add(
        const Tip(
          'Acqua stagnante e leptospirosi',
          'Non farlo bere da pozzanghere, fossi e stagni: la leptospirosi si '
              'trasmette con l\'urina dei topi ed è trasmissibile all\'uomo. '
              'Vomito, abbattimento e sete dopo un bagno in acque ferme → '
              'veterinario oggi.',
        ),
      );
    }
    if (m == 12 || m <= 2) {
      final fragile =
          dog.weightKg < 10 ||
          lifeStageOf(dog, now) == LifeStage.anziano ||
          lifeStageOf(dog, now) == LifeStage.cucciolo;
      out.add(
        Tip(
          'Freddo',
          '${fragile ? 'Per ${dog.name} il freddo pesa di più. ' : ''}Uscite '
              'brevi quando gela, cappottino per i cani a pelo raso o piccoli; '
              'asciugalo dopo la pioggia; attenzione al sale antighiaccio sui '
              'polpastrelli (sciacquali al rientro).',
        ),
      );
    }
    final tickAllYear = dog.region != Region.nord;
    if (tickAllYear || (m >= 3 && m <= 11)) {
      out.add(
        Tip(
          'Zecche',
          tickAllYear
              ? 'Al Centro-Sud le zecche sono presenti tutto l\'anno: mantieni '
                    'la protezione e controlla il pelo dopo le passeggiate.'
              : 'Stagione delle zecche (marzo-novembre): controlla il pelo dopo '
                    'le passeggiate.',
        ),
      );
    }
    final d = now.day;
    if ((m == 12 && d >= 20) || (m == 1 && d <= 2)) {
      out.add(
        const Tip(
          'Botti di Capodanno',
          'Tienilo in casa, con una zona tranquilla e finestre chiuse; '
              'controlla che la medaglietta sia aggiornata. Se è molto '
              'pauroso, parlane prima con il veterinario.',
        ),
      );
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
      out.add(
        const Tip(
          'Torace profondo: attenzione alla torsione gastrica',
          'Pasti divisi, niente corse subito dopo mangiato. Addome gonfio con '
              'conati a vuoto è un\'emergenza.',
        ),
      );
    }
    if (isBrachy(b)) {
      out.add(
        const Tip(
          'Razza brachicefala',
          'Respira peggio con caldo e sforzo: evita le ore calde e '
              'segnala al veterinario russare forte o affanno.',
        ),
      );
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
      out.add(
        const Tip(
          'Possibile mutazione MDR1',
          'Chiedi al veterinario il test MDR1 prima di usare alcuni '
              'antiparassitari e farmaci (es. ivermectina ad alte dosi).',
        ),
      );
    }
    if (_has(b, ['dalmata'])) {
      out.add(
        const Tip(
          'Dalmata: calcoli di urati',
          'Acqua abbondante e dieta concordata con il veterinario; segnala '
              'sforzo o sangue nelle urine.',
        ),
      );
    }
    if (_has(b, ['bassotto', 'dachshund', 'corgi', 'basset'])) {
      out.add(
        const Tip(
          'Schiena lunga',
          'Evita salti da divani e scale ripide. Dolore alla schiena o zampe '
              'posteriori deboli: subito dal veterinario.',
        ),
      );
    }
    if (_has(b, ['yorkshire', 'chihuahua', 'pomerania', 'volpino', 'toy'])) {
      out.add(
        const Tip(
          'Razza toy: trachea e zuccheri',
          'Predisposta al collasso tracheale (tosse "a clacson": usa la '
              'pettorina, non il collare) e, da cucciolo, all\'ipoglicemia: '
              'pasti frequenti.',
        ),
      );
    }
    if (_has(b, ['schnauzer nano', 'schnauzer mini', 'zwergschnauzer'])) {
      out.add(
        const Tip(
          'Schnauzer nano: pancreatite',
          'Evita avanzi e cibi grassi; vomito e dolore addominale dopo un '
              'pasto grasso vanno visti dal veterinario.',
        ),
      );
    }
    if (_has(b, ['dobermann', 'doberman'])) {
      out.add(
        const Tip(
          'Dobermann: cuore',
          'Predisposto alla cardiomiopatia dilatativa: chiedi al veterinario '
              'dei controlli cardiologici periodici (ECG Holter, ecografia).',
        ),
      );
    }
    if (_has(b, ['cocker'])) {
      out.add(
        const Tip(
          'Cocker: orecchie',
          'Predisposto alle otiti: controlla e asciuga le orecchie dopo bagni '
              'e passeggiate sotto la pioggia.',
        ),
      );
    }
    if (_has(b, ['bulldog francese', 'bouledogue', 'french bulldog'])) {
      out.add(
        const Tip(
          'Bulldog francese: schiena',
          'Predisposto all\'ernia del disco: dolore alla schiena o zampe '
              'posteriori deboli vanno visti subito.',
        ),
      );
    }
    if (_has(b, ['cavalier'])) {
      out.add(
        const Tip(
          'Cavalier King: cuore',
          'Predisposto alla malattia della valvola mitrale: conta i respiri '
              'nel sonno ogni settimana (sezione Diari).',
        ),
      );
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
    return const Tip(
      'Sterilizzazione nelle taglie grandi',
      'Per alcune razze grandi gli studi indicano che l\'età della '
          'sterilizzazione può influire su articolazioni e alcuni tumori (Hart '
          'et al. 2020). Non esiste un\'età giusta per tutti: parlane con il '
          'veterinario.',
    );
  }

  /// Consigli per il cucciolo: socializzazione ed educazione al bisogno.
  static List<Tip> puppy(Dog dog, DateTime now) {
    final w = now.difference(dog.birthDate).inDays / 7;
    if (w > 26) return const [];
    return [
      if (w <= 16)
        const Tip(
          'Finestra di socializzazione (fino a ~14 settimane)',
          'Fagli conoscere con calma persone, rumori, superfici e cani '
              'vaccinati e sani, anche prima della fine dei vaccini, in '
              'ambienti controllati (AVSAB 2008). Finché i vaccini non sono '
              'completi evita parchi e aree con feci di cani sconosciuti; sì a '
              'cani sani e vaccinati, case di amici e classi per cuccioli con '
              'protocollo igienico. Abitualo a trasportino e manipolazione.',
        ),
      const Tip(
        'Educazione al bisogno',
        'Premia subito, fuori, appena ha fatto. Non punire gli incidenti: '
            'pulisci con un detergente enzimatico. Zampa ti dice quando '
            'portarlo fuori.',
      ),
    ];
  }
}
