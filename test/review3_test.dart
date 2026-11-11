// Terza revisione veterinaria (ricerca/26): testi delle dosi (A7) e
// frasi d'azione e varianti degli avvisi (A4, A5, A8, A9).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/logic/modules.dart';
import 'package:zampa/main.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';

import 'clinical_scenarios.dart';

const insulinSkip =
    'Confermi che l\'insulina non è stata fatta? Non farla in ritardo e non '
    'raddoppiare la prossima senza aver sentito il veterinario. Se non sei '
    'sicuro che sia stata fatta, non rifarla.';
const seizureSkip =
    'Confermi che la dose non è stata data? Con i farmaci per le convulsioni '
    'una dose saltata può far tornare le crisi: chiama il veterinario oggi '
    'per sapere se darla adesso.';
const genericSkip =
    'Confermi che questa dose non è stata data? Non raddoppiare la prossima: '
    'chiedi al veterinario cosa fare.';

HealthRecord therapy(String title, DateTime start, {String dogId = 'd'}) =>
    HealthRecord(
      id: 'r_$title',
      dogId: dogId,
      type: RecordType.farmaco,
      title: title,
      date: start,
      everyHours: 12,
      drugEffect: DrugEffectLabel.guess(title),
    );

Future<AppStore> _openDemo(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final store = AppStore(prefs: await SharedPreferences.getInstance());
  await store.load();
  await tester.pumpWidget(ZampaApp(store: store));
  final scroll = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(
    find.text('Ho letto e ho capito'),
    200,
    scrollable: scroll,
  );
  await tester.tap(find.text('Ho letto e ho capito'));
  await tester.pump();
  await tester.scrollUntilVisible(
    find.text('Continua'),
    200,
    scrollable: scroll,
  );
  await tester.tap(find.text('Continua'));
  await tester.runAsync(() async {});
  await tester.pump();
  await tester.runAsync(store.loadDemo);
  await tester.pump();
  return store;
}

void main() {
  group('A7: testi delle dosi', () {
    test('insulina e antiepilettici riconosciuti dal nome', () {
      for (final n in [
        'Caninsulin',
        'Insulina glargine',
        'Vetsulin',
        'ProZinc',
        'Lantus',
      ]) {
        expect(Modules.doseKind(n), 'insulin', reason: n);
      }
      for (final n in [
        'Fenobarbital',
        'Soliphen 60 mg',
        'Keppra',
        'Levetiracetam',
        'Bromuro di potassio',
        'Libromide',
        'Pexion (imepitoina)',
        'Zonisamide',
      ]) {
        expect(Modules.doseKind(n), 'antiepileptic', reason: n);
      }
      for (final n in [
        'Metacam',
        'Pimobendan',
        // Il bromuro di un antispastico non è un antiepilettico.
        'Butilscopolamina bromuro',
      ]) {
        expect(Modules.doseKind(n), 'other', reason: n);
      }
    });

    Future<List<PlannedNotification>> confirmReminders(String drug) async {
      SharedPreferences.setMockInitialValues({});
      final s = AppStore(prefs: await SharedPreferences.getInstance());
      await s.load();
      final now = DateTime(2026, 11, 11, 10, 30);
      await s.upsertDog(
        Dog(
          id: 'd',
          name: 'Rex',
          birthDate: DateTime(2020, 1, 1),
          sex: Sex.maschio,
          weightKg: 20,
        ),
      );
      // Dose alle 9: il promemoria di conferma è alle 11.
      await s.upsertRecord(therapy(drug, DateTime(2026, 11, 10, 9)));
      return s
          .planNotifications(now)
          .where((p) => p.id >= 1097 && p.id <= 1099)
          .toList();
    }

    test('promemoria a 2 ore per l\'insulina: non spinge a rifarla', () async {
      final r = await confirmReminders('Caninsulin');
      expect(r, isNotEmpty);
      expect(r.first.when, DateTime(2026, 11, 11, 11));
      expect(r.first.title, '💉 Insulina di Rex: segnata?');
      expect(
        r.first.body,
        'Se è stata fatta, segna "Dato". Se non sei sicuro che sia stata '
        'fatta, non rifarla: chiedi al veterinario.',
      );
    });

    test('promemoria a 2 ore per gli antiepilettici', () async {
      final r = await confirmReminders('Keppra');
      expect(r.first.title, '💊 Dose confermata per Rex?');
      expect(
        r.first.body,
        'Apri Zampa e segna "Dato" o "Saltato". Con i farmaci per le '
        'convulsioni una dose saltata può far tornare le crisi: se l\'hai '
        'saltata, chiama il veterinario oggi per sapere se darla adesso.',
      );
    });

    test('promemoria a 2 ore per gli altri farmaci: testo invariato', () async {
      final r = await confirmReminders('Metacam');
      expect(r.first.title, '💊 Dose confermata per Rex?');
      expect(
        r.first.body,
        'Apri Zampa e segna "Dato" o "Saltato". Se l\'hai saltata non '
        'raddoppiare la successiva: chiedi al veterinario.',
      );
    });

    testWidgets('dialogo «Saltato»: testo per farmaco', (tester) async {
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      final store = await _openDemo(tester);
      final dogId = store.dog!.id;
      for (final (drug, text) in [
        ('Caninsulin', insulinSkip),
        ('Fenobarbital', seizureSkip),
        ('Metacam', genericSkip),
      ]) {
        // Una sola terapia da confermare alla volta.
        store.records.removeWhere(
          (r) => r.dogId == dogId && r.type == RecordType.farmaco,
        );
        await tester.runAsync(
          () => store.upsertRecord(
            therapy(
              drug,
              DateTime.now().subtract(const Duration(hours: 1)),
              dogId: dogId,
            ),
          ),
        );
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text('Saltato'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Saltato'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Saltato'));
        await tester.pumpAndSettle();
        expect(find.text('Dose saltata?'), findsOneWidget, reason: drug);
        expect(find.text(text), findsOneWidget, reason: drug);
        await tester.tap(find.text('Annulla'));
        await tester.pumpAndSettle();
      }
      await tester.binding.setSurfaceSize(null);
    });
  });

  group('A4, A5, A9: varianti degli avvisi', () {
    List<HealthAlert> run(Scenario s) => AlertEngine.compute(
      dog: s.dog,
      logs: s.logs,
      records: s.records,
      weights: s.weights,
      now: s.now,
      repro: s.repro,
      pendingDoses: s.pending,
    );
    HealthAlert one(String scenario, String id) =>
        run(alertScenarios().firstWhere((s) => s.name == scenario))
            .firstWhere((a) => a.id == id);

    test('trilostano: non dare la prossima dose prima di aver sentito il '
        'veterinario', () {
      final a = one('Cushing con vomito', 'ALR-FAR-001');
      expect(
        a.message,
        contains(
          'Non dare la prossima dose finché non hai '
          'parlato con il veterinario',
        ),
      );
      expect(a.message, isNot(contains('sospendi')));
    });

    test('vomito: FANS sospeso, cortisone mai di colpo', () {
      final fans = one('FANS e vomito', 'ALR-FAR-004').message;
      final cort = one('cortisone e vomito', 'ALR-FAR-004').message;
      final both = one('FANS, cortisone e vomito', 'ALR-FAR-004').message;
      expect(fans, contains('Non dare la prossima dose di antinfiammatorio'));
      expect(fans, isNot(contains('cortisone')));
      expect(cort, contains('Non sospendere il cortisone di colpo'));
      expect(cort, isNot(contains('antinfiammatorio')));
      expect(both, contains('antinfiammatorio'));
      expect(
        both,
        contains('Non sospendere il cortisone di colpo'.toLowerCase()),
      );
    });

    test('feci nere: la frase sul FANS solo se c\'è un FANS', () {
      expect(
        one('feci nere con FANS', 'ALR-GI-007a').message,
        contains('non dare la prossima dose di antinfiammatorio'),
      );
      expect(
        one('feci nere con cortisone', 'ALR-GI-007a').message,
        isNot(contains('antinfiammatorio finché')),
      );
    });

    test('nessuna pipì nel maschio con sforzo: testo urgente, non «osserva»', () {
      final a = one('maschio, sforzo 14 ore fa e poi niente', 'ALR-URI-006');
      expect(a.level, AlertLevel.subito);
      expect(a.message, startsWith('Fido è un maschio'));
      expect(a.message, isNot(contains('osserva')));
      expect(a.actionText, AlertLevel.subito.action);
      final spine = one(
        'maschio, sforzo 14 ore fa e poi niente, dopo chirurgia della colonna',
        'ALR-URI-006',
      );
      // La frase sulla colonna va dopo il testo urgente.
      expect(spine.message, startsWith('Fido è un maschio'));
      expect(spine.message, contains('Dopo una chirurgia della colonna'));
      final att = one('adulto senza pipì da 14 ore', 'ALR-URI-006');
      expect(att.level, AlertLevel.attenzione);
      expect(att.message, startsWith('Portalo fuori e osserva'));
      expect(att.actionText, isNull);
    });
  });
}
