@Tags(['banco'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';

import 'supporto.dart';

/// Banco di prova della PREVISIONE DI BASE (ricerca/23 §2): tutti i 32 cani,
/// tutti gli eventi, origine onesta. Pochi minuti: il modello statistico non
/// viene addestrato. Esecuzione: flutter test --dart-define=BANCO=true test/banco.
void main() {
  Esito base(String s) => esegui(s, every: 1, shadow: false);

  test(
    'T1: origine onesta (nessun log futuro, verificato a ogni previsione)',
    () {
      // evaluatePair lancia StateError se un log successivo all'origine è
      // visibile: basta eseguire uno scenario.
      expect(base('pulito').base, isNotEmpty);
    },
    skip: lento,
  );

  test('base, realistico: non peggio del timer (R ≤ 1,00)', () {
    final r = base('realistico').base;
    expect(ratio2(r, 'errTimer'), lessThanOrEqualTo(1.0));
  }, skip: lento);

  test('base, orari decisi dal padrone: errore ≤ 1,3 × «stesso orario»', () {
    final r = base('orari_padrone').base;
    expect(
      mediana(r, 'errModel'),
      lessThanOrEqualTo(1.3 * mediana(r, 'errHabit')),
    );
    expect(ratio2(r, 'errTimer'), lessThanOrEqualTo(0.8));
  }, skip: lento);

  test('base: copertura della finestra mostrata tra 70% e 88%', () {
    for (final s in ['realistico', 'pulito', 'orari_padrone', 'poliuria']) {
      final c = quota(base(s).base, (e) => e.b('inWin'));
      expect(c, inInclusiveRange(0.70, 0.88), reason: '$s: $c');
    }
  }, skip: lento);

  test('T14 base: con la poliuria in corso da 4 giorni non è in ritardo', () {
    final r = base('poliuria').base.where((e) => e.d('puDays') >= 4).toList();
    expect(mediana(r, 'signedErr'), greaterThanOrEqualTo(-20));
  }, skip: lento);

  test('T15: tetto di sicurezza da sveglio sempre rispettato', () {
    for (final s in ['realistico', 'orari_padrone', 'poliuria']) {
      final r = base(s).base;
      expect(r.where((e) => !e.b('capOk')), isEmpty, reason: s);
    }
  }, skip: lento);

  test('T16 cacca: solo orari abituali, descrittivo (nessuna soglia)', () {
    final r = esegui(
      'realistico',
      need: Need.cacca,
      every: 1,
      shadow: false,
    ).base;
    expect(r, isNotEmpty);
  }, skip: lento);
}
