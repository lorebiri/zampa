// Pacchetto Paese e testi v1.0-rc (piano CEO 10.5 e §11.5, C2-4 punto 4).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/l10n/country_pack.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/common.dart';
import 'package:zampa/ui/emergency_screen.dart';

import 'clinical_scenarios.dart';

const cavPhone = '02 6610 1029';

Future<void> pumpEmergency(WidgetTester tester, Dog? dog) async {
  tester.view.physicalSize = const Size(1200, 8000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final store = AppStore(prefs: await SharedPreferences.getInstance());
  if (dog != null) {
    store.dogs.add(dog);
    store.selectedDogId = dog.id;
  }
  await tester.pumpWidget(
    MaterialApp(
      home: StoreScope(store: store, child: const EmergencyScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  test('la verifica del numero del centro antiveleni ha meno di 6 mesi', () {
    for (final e in poisonCentres.entries) {
      final age = DateTime.now().difference(e.value.verifiedDate).inDays;
      expect(
        age,
        lessThanOrEqualTo(183),
        reason:
            'Centro antiveleni ${e.key} (${e.value.phone}) verificato il '
            '${e.value.verifiedOn}: riverificarlo sulle fonti '
            '${e.value.sources.join(', ')} e aggiornare la data in '
            'lib/l10n/country_pack.dart',
      );
      expect(age, greaterThanOrEqualTo(0), reason: 'data nel futuro');
    }
  });

  test('il CAV di Milano è registrato solo per l\'Italia', () {
    expect(poisonCentreFor('IT')!.phone, cavPhone);
    expect(poisonCentreFor('it')!.phone, cavPhone);
    expect(poisonCentreFor('CH'), isNull);
    expect(poisonCentreFor('FR'), isNull);
    expect(poisonCentres.keys, ['IT']);
  });

  testWidgets('scheda Emergenze: numero CAV con un cane in Italia', (
    tester,
  ) async {
    await pumpEmergency(tester, mkDog());
    expect(find.textContaining(cavPhone), findsOneWidget);
    // Chiamata diretta: la voce è toccabile e ha l'icona del telefono.
    final tile = tester.widget<ListTile>(
      find.ancestor(
        of: find.textContaining(cavPhone),
        matching: find.byType(ListTile),
      ),
    );
    expect(tile.onTap, isNotNull);
    expect(tile.trailing, isA<Icon>());
  });

  testWidgets('scheda Emergenze: nessun numero CAV fuori dall\'Italia', (
    tester,
  ) async {
    for (final c in ['CH', 'FR', 'DE', 'GB']) {
      await pumpEmergency(tester, mkDog()..country = c);
      expect(find.textContaining(cavPhone), findsNothing, reason: c);
      expect(find.textContaining('Antiveleni di Milano'), findsNothing);
    }
    await pumpEmergency(tester, null);
    expect(find.textContaining(cavPhone), findsNothing);
  });

  test('il Paese si salva e manca solo nei dati vecchi (allora è IT)', () {
    final d = mkDog()..country = 'CH';
    expect(Dog.fromJson(d.toJson()).country, 'CH');
    final old = d.toJson()..remove('country');
    expect(Dog.fromJson(old).country, 'IT');
  });

  test(
    'frase d\'azione «chiama» per gli avvisi SUBITO che dicono di chiamare',
    () {
      // Frase comune approvata con modifica (ricerca/26 §3.4).
      const call =
          'Chiama subito il veterinario. Se non risponde entro pochi minuti, '
          'o se il cane peggiora, vai al pronto soccorso veterinario, anche '
          'di notte.';
      const ids = {
        'ALR-TOX-001',
        'ALR-DIA-002',
        'ALR-DIA-005',
        'ALR-FAR-001',
        'ALR-FAR-004',
        'ALR-GI-007a',
      };
      final seen = <String>{};
      for (final s in alertScenarios()) {
        for (final a in AlertEngine.compute(
          dog: s.dog,
          logs: s.logs,
          records: s.records,
          weights: s.weights,
          now: s.now,
          repro: s.repro,
          pendingDoses: s.pending,
        )) {
          if (ids.contains(a.id)) {
            seen.add(a.id);
            expect(a.actionText, call, reason: a.id);
          } else if (a.level == AlertLevel.subito && a.id != 'ALR-URI-006') {
            expect(a.actionText, AlertLevel.subito.action, reason: a.id);
          }
          // ALR-URI-006: frase d'azione solo quando sale a SUBITO.
          if (a.id == 'ALR-URI-006') {
            expect(
              a.actionText,
              a.level == AlertLevel.subito ? AlertLevel.subito.action : isNull,
            );
          }
        }
      }
      expect(seen, ids);
    },
  );
}
