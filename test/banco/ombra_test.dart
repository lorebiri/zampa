@Tags(['banco'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';

import 'supporto.dart';

/// Banco di prova del MODELLO IN OMBRA (ricerca/12 §7, ricerca/23 §3): test
/// T2-T18 con 32 cani e un evento su tre (il realistico con la griglia
/// usa tutti gli eventi). Lento: 30-60 minuti.
/// Esecuzione: flutter test -j 4 --dart-define=BANCO=true test/banco.
///
/// Le soglie sono quelle di ricerca/12 §7. I test non ancora superati sono
/// segnati con `skip` e il valore misurato: restano qui come obiettivo.
void main() {
  List<Rec2> ombra(String s, {int every = 3}) => esegui(s, every: every).ombra;
  Esito realistico() => esegui('realistico', every: 1, grid: true);

  test('T2: batte il timer nello scenario pulito (R ≤ 0,85)', () {
    expect(ratio2(ombra('pulito'), 'errTimer'), lessThanOrEqualTo(0.85));
  }, skip: lento);

  test('T3: batte il timer nel realistico (R ≤ 0,85, IC sup. < 1,00)', () {
    final r = realistico().ombra;
    final b = boot2(r, (s) => ratio2(s, 'errTimer'), reps: 400);
    expect(b.est, lessThanOrEqualTo(0.85));
    expect(b.hi, lessThan(1.0));
  }, skip: lento ?? _skip['T3']);

  test('T4: non peggio di «stesso orario» nel realistico (R ≤ 1,00)', () {
    expect(ratio2(realistico().ombra, 'errHabit'), lessThanOrEqualTo(1.0));
  }, skip: lento ?? _skip['T4']);

  test('T5: orari decisi dal padrone, errore ≤ 1,3 × «stesso orario»', () {
    final r = ombra('orari_padrone');
    expect(
      mediana(r, 'errModel'),
      lessThanOrEqualTo(1.3 * mediana(r, 'errHabit')),
    );
  }, skip: lento ?? _skip['T5']);

  test('T6: copertura dell\'intervallo all\'80% tra 75% e 88%', () {
    final c = quota(realistico().ombra, (e) => e.b('inWin'));
    expect(c, inInclusiveRange(0.75, 0.88));
  }, skip: lento ?? _skip['T6']);

  test('T7: intervallo 25-75% tra 45% e 60%', () {
    final c = quota(realistico().ombra, (e) => e.b('in50'));
    expect(c, inInclusiveRange(0.45, 0.60));
  }, skip: lento ?? _skip['T7']);

  test('T8: PIT, code < 0,1 e > 0,9 tra 6% e 14%', () {
    final r = realistico().ombra;
    expect(quota(r, (e) => e.d('pit') < 0.1), inInclusiveRange(0.06, 0.14));
    expect(quota(r, (e) => e.d('pit') > 0.9), inInclusiveRange(0.06, 0.14));
  }, skip: lento ?? _skip['T8']);

  test('T9: calibrazione della prossima ora (±10 punti, n ≥ 50; BSS ≥ 0)', () {
    final g = realistico().grid;
    final bins = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.8, 1.0001];
    for (var b = 0; b + 1 < bins.length; b++) {
      final s = g.where((e) => e.p >= bins[b] && e.p < bins[b + 1]).toList();
      if (s.length < 50) continue;
      final mp = s.map((e) => e.p).reduce((a, c) => a + c) / s.length;
      final mo = s.where((e) => e.y == 1).length / s.length;
      expect((mo - mp).abs(), lessThanOrEqualTo(0.10), reason: 'fascia $b');
    }
    expect(1 - brier(g) / brier(g, clim: true), greaterThanOrEqualTo(0));
  }, skip: lento ?? _skip['T9']);

  test('T10: nessun ritardo sistematico di giorno (scenario pulito)', () {
    final r = ombra('pulito').where((e) => !e.b('overnight')).toList();
    expect(mediana(r, 'signedErr').abs(), lessThanOrEqualTo(15));
  }, skip: lento ?? _skip['T10']);

  test('T11: prima pipì del mattino, errore mediano ≤ 45 min', () {
    for (final s in ['weekend', 'cambio_routine']) {
      final r = ombra(s).where((e) => e.b('overnight')).toList();
      expect(mediana(r, 'errModel'), lessThanOrEqualTo(45), reason: s);
    }
  }, skip: lento ?? _skip['T11']);

  test('T12: pipì mancanti, R ≤ 0,95', () {
    expect(ratio2(ombra('mancanti'), 'errTimer'), lessThanOrEqualTo(0.95));
  }, skip: lento ?? _skip['T12']);

  test('T13: orari spostati ±10 min, R ≤ 0,90', () {
    expect(ratio2(ombra('jitter'), 'errTimer'), lessThanOrEqualTo(0.90));
  }, skip: lento ?? _skip['T13']);

  test('T14: poliuria in corso da ≥ 4 giorni, errore con segno ≥ −20 min', () {
    final r = ombra('poliuria').where((e) => e.d('puDays') >= 4).toList();
    expect(mediana(r, 'signedErr'), greaterThanOrEqualTo(-20));
  }, skip: lento ?? _skip['T14']);

  test('T15: tetto di sicurezza invariato nel modello in ombra', () {
    expect(realistico().ombra.every((e) => e.b('capOk')), isTrue);
  }, skip: lento);

  test('T18: accuratezza fuori campione (R6) = copertura prequenziale', () {
    // Per ogni cane: accuracy() calcolata dalla storia registrata, alla fine,
    // contro la copertura misurata dal banco sugli stessi eventi.
    final e = realistico();
    var diffs = 0.0, n = 0;
    for (final (hist, tr) in e.history.values) {
      final end = simStart.add(const Duration(days: simDays));
      final visible = tr.logged.where((l) => l.time.isBefore(end)).toList();
      final m = EliminationModel().fit(
        tr.dog,
        Need.pipi,
        visible,
        const [],
        end,
        shadow: false,
      );
      final acc = m.accuracy(end, hist);
      if (acc == null) continue;
      final mine = e.ombra.where((r) => r.dog == tr.spec.id).toList();
      final tail = mine.sublist(mine.length - acc.n);
      final cov = quota(tail, (r) => r.b('inWin'));
      diffs += (acc.inWindowRate - cov).abs();
      n++;
    }
    expect(n, greaterThan(20));
    expect(diffs / n, lessThanOrEqualTo(0.05));
  }, skip: lento);
}

/// Test non ancora superati, con il valore misurato (aggiornare dopo ogni
/// esecuzione del banco; ricerca/23 §3).
const _skip = <String, String?>{
  'T3': 'Non superato dopo R7 (11/11/2026): R/timer 0,91 [0,87–0,96]',
  'T4': 'Non superato dopo R7: R/«stesso orario» 1,07 [1,00–1,14]',
  'T6': 'Non superato dopo R7: copertura 80% al 71%',
  'T7': 'Non superato dopo R7: copertura 25-75% al 44,7%',
  'T8': 'Non superato dopo R7: PIT 14,0% / 15,1%',
  'T9':
      'Non superato dopo R7: fascia 60-80% −20 punti (n = 85), '
      'Brier skill −0,03',
};
