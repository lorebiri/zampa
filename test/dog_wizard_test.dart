// Procedura guidata per il primo cane: percorso completo, validazioni
// identiche al modulo, dialogo del cane di esempio e testo al 200%.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/common.dart';
import 'package:zampa/ui/dog_form.dart';
import 'package:zampa/ui/dog_wizard.dart';
import 'package:zampa/ui/health_screen.dart';
import 'package:zampa/ui/theme.dart';

Future<AppStore> _store(WidgetTester tester, {bool demo = false}) async {
  SharedPreferences.setMockInitialValues({});
  final store = AppStore(prefs: await SharedPreferences.getInstance());
  await store.load();
  if (demo) await tester.runAsync(store.loadDemo);
  return store;
}

/// Una pagina con il pulsante che apre la procedura, come nell'app.
Future<void> _open(
  WidgetTester tester,
  AppStore store, {
  Size size = const Size(800, 2000),
}) async {
  // Alto abbastanza da vedere tutto il passo senza scorrere.
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    StoreScope(
      store: store,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DogWizardPage()),
                ),
                child: const Text('Apri'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Apri'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String text) async {
  final f = find.text(text);
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// Passi 1 e 2 compilati: Birba, femmina, nata 90 giorni fa, 9,5 kg.
Future<void> _fillFirstTwo(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Birba');
  await _tap(tester, 'Femmina');
  await _tap(tester, 'Avanti');
  await _tap(tester, 'Scegli la data');
  await _tap(tester, 'OK');
  await tester.enterText(find.byType(TextField), '9,5');
  await _tap(tester, 'Avanti');
}

/// «Fatto» o «Altri dettagli»: il salvataggio fa anche lavoro asincrono vero.
Future<void> _finish(WidgetTester tester, String text) async {
  await _tap(tester, text);
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _loadAtkinson(WidgetTester tester) => tester.runAsync(() async {
  final loader = FontLoader(fontFamily);
  for (final w in ['Regular', 'Italic', 'Medium', 'SemiBold', 'Bold']) {
    loader.addFont(
      rootBundle.load('assets/fonts/AtkinsonHyperlegibleNext-$w.ttf'),
    );
  }
  await loader.load();
});

void main() {
  testWidgets('percorso completo: il cane è creato con i valori giusti', (
    tester,
  ) async {
    final store = await _store(tester);
    await _open(tester, store);
    expect(find.text('Passo 1 di 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Passo 1 di 5'), findsOneWidget);

    await _fillFirstTwo(tester);
    expect(find.text('Passo 3 di 5'), findsOneWidget);
    expect(find.text('Sterilizzata'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'diabete');
    await _tap(tester, 'Avanti');

    // Passo 4: medicine. «No»: nessuna terapia, nessuna scheda in Home.
    expect(find.text('Passo 4 di 5'), findsOneWidget);
    expect(find.text('Prende medicine?'), findsOneWidget);
    await _tap(tester, 'No');
    await _tap(tester, 'Avanti');

    // Passo 5: orari proposti, poi «Fatto».
    expect(find.text('Passo 5 di 5'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('23:00'), findsOneWidget);
    expect(find.text('Altri dettagli'), findsOneWidget);
    await _finish(tester, 'Fatto');

    // Primo cane vero, senza esempio: solo la richiesta delle notifiche.
    expect(find.text('Eliminare il cane di esempio?'), findsNothing);
    expect(find.text('Attivare le notifiche?'), findsOneWidget);
    await _finish(tester, 'Non ora');
    expect(find.byType(DogWizardPage), findsNothing);
    expect(store.dogs, hasLength(1));
    final dog = store.dogs.single;
    final now = DateTime.now();
    expect(isDemoId(dog.id), isFalse);
    expect(dog.name, 'Birba');
    expect(dog.sex, Sex.femmina);
    expect(dog.weightKg, 9.5);
    expect(
      dog.birthDate,
      DateUtils.dateOnly(now.subtract(const Duration(days: 90))),
    );
    expect(dog.neutered, isTrue);
    expect(dog.conditions, 'diabete');
    expect(dog.adultSize, isNull);
    expect(dog.wakeHour, 7);
    expect(dog.sleepStartHour, 23);
    expect(dog.photoId, isNull);
    // Il resto ha i valori predefiniti del modulo completo.
    expect(dog.activity, ActivityLevel.normale);
    expect(dog.diet, DietType.secco);
    expect(dog.prudence, Prudence.normale);
    expect(dog.pottyRemindersOn, isTrue);
    expect(dog.poopRemindersOn, isTrue);
    expect(dog.reminderLeadMinutes, 10);
    expect(dog.heatAlertsOn, isFalse);
    expect(dog.medsToAdd, isFalse);
    expect(store.records, isEmpty);
  });

  testWidgets('senza nome non si va avanti', (tester) async {
    final store = await _store(tester);
    await _open(tester, store);
    await _tap(tester, 'Avanti');
    expect(find.text('Passo 1 di 5'), findsOneWidget);
    expect(find.text('Scrivi il nome del cane'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '   ');
    await _tap(tester, 'Avanti');
    expect(find.text('Passo 1 di 5'), findsOneWidget);
  });

  testWidgets('data di nascita obbligatoria e mai futura, peso positivo', (
    tester,
  ) async {
    final store = await _store(tester);
    await _open(tester, store);
    await tester.enterText(find.byType(TextField), 'Birba');
    await _tap(tester, 'Avanti');

    // Niente data e niente peso: si resta al passo 2, con gli errori.
    await _tap(tester, 'Avanti');
    expect(find.text('Passo 2 di 5'), findsOneWidget);
    expect(find.text('Serve la data di nascita'), findsOneWidget);
    expect(find.text('Scrivi il peso in kg, per esempio 12,5'), findsOneWidget);

    // Il calendario finisce oggi: le date future non si possono scegliere.
    await _tap(tester, 'Scegli la data');
    final picker = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(picker.lastDate, DateUtils.dateOnly(DateTime.now()));
    await _tap(tester, 'OK');
    expect(find.text('Serve la data di nascita'), findsNothing);

    // Peso zero o non numerico: come nel modulo, non va bene.
    for (final bad in ['0', '-3', 'tanti']) {
      await tester.enterText(find.byType(TextField), bad);
      await _tap(tester, 'Avanti');
      expect(find.text('Passo 2 di 5'), findsOneWidget, reason: bad);
    }
    await tester.enterText(find.byType(TextField), '12.5');
    await _tap(tester, 'Avanti');
    expect(find.text('Passo 3 di 5'), findsOneWidget);

    // «Indietro» torna al passo precedente senza perdere i dati.
    await _tap(tester, 'Indietro');
    expect(find.text('Passo 2 di 5'), findsOneWidget);
    expect(find.text('12.5'), findsOneWidget);
  });

  testWidgets('con il cane di esempio: dopo «Fatto» propone di eliminarlo', (
    tester,
  ) async {
    final store = await _store(tester, demo: true);
    expect(store.demoDogs, hasLength(1));
    await _open(tester, store);
    await _fillFirstTwo(tester);
    await _tap(tester, 'Avanti');
    await _tap(tester, 'Avanti');
    await _finish(tester, 'Fatto');

    // Prima la proposta di eliminare l'esempio, poi le notifiche.
    expect(find.text('Eliminare il cane di esempio?'), findsOneWidget);
    expect(find.text('Attivare le notifiche?'), findsNothing);
    await _finish(tester, 'Elimina l\'esempio');
    expect(find.text('Attivare le notifiche?'), findsOneWidget);
    await _finish(tester, 'Non ora');
    expect(find.byType(DogWizardPage), findsNothing);
    expect(store.demoDogs, isEmpty);
    expect(store.dogs.single.name, 'Birba');
    expect(store.dog!.id, store.dogs.single.id);
  });

  testWidgets('«Altri dettagli» salva e apre il modulo completo', (
    tester,
  ) async {
    final store = await _store(tester);
    await _open(tester, store);
    await _fillFirstTwo(tester);
    await _tap(tester, 'Avanti');
    await _tap(tester, 'Avanti');
    await _finish(tester, 'Altri dettagli');
    await _finish(tester, 'Non ora');

    expect(store.dogs.single.name, 'Birba');
    expect(find.byType(DogFormPage), findsOneWidget);
    expect(find.text('Modifica Birba'), findsOneWidget);
    expect(find.byType(DogWizardPage), findsNothing);
  });

  testWidgets('«Sì, le aggiungo ora» crea terapie vere, come in Salute', (
    tester,
  ) async {
    final store = await _store(tester);
    await _open(tester, store);
    await _fillFirstTwo(tester);
    await _tap(tester, 'Avanti');
    expect(find.text('Passo 4 di 5'), findsOneWidget);

    // La scelta apre il modulo della terapia della scheda Salute.
    await _tap(tester, 'Sì, le aggiungo ora');
    expect(find.byType(RecordFormPage), findsOneWidget);
    expect(find.text('Nuova medicina'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome della medicina'),
      'Metacam',
    );
    await tester.pumpAndSettle();
    // Senza «ogni quante ore» non è una terapia: non si salva.
    await _tap(tester, 'Salva');
    expect(find.byType(RecordFormPage), findsOneWidget);
    expect(find.text('Indica ogni quante ore la prende'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Ogni quante ore'),
      '24',
    );
    await _tap(tester, 'Salva');
    expect(find.byType(RecordFormPage), findsNothing);
    expect(find.text('Passo 4 di 5'), findsOneWidget);
    expect(find.text('Metacam'), findsOneWidget);
    // Niente è salvato prima di «Fatto».
    expect(store.records, isEmpty);

    // Una seconda medicina, poi la si toglie.
    await _tap(tester, 'Aggiungi un\'altra medicina');
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome della medicina'),
      'Prednicortone',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Ogni quante ore'),
      '12',
    );
    await _tap(tester, 'Salva');
    expect(find.text('Prednicortone'), findsOneWidget);
    await _tap(tester, 'Avanti');
    await _tap(tester, 'Indietro');
    await tester.tap(find.byTooltip('Togli Prednicortone'));
    await tester.pumpAndSettle();
    expect(find.text('Prednicortone'), findsNothing);

    await _tap(tester, 'Avanti');
    await _finish(tester, 'Fatto');
    await _finish(tester, 'Non ora');
    final dog = store.dogs.single;
    expect(dog.medsToAdd, isFalse);
    final r = store.records.single;
    expect(r.dogId, dog.id);
    expect(r.type, RecordType.farmaco);
    expect(r.title, 'Metacam');
    expect(r.everyHours, 24);
    expect(r.endDate, isNull);
    // Nome riconosciuto come in Salute (DrugEffect.guess).
    expect(r.drugEffect, DrugEffect.fans);
    final now = DateTime.now();
    expect(r.isActiveTherapy(now.add(const Duration(minutes: 1))), isTrue);
    // È una terapia vera: genera le dosi e i promemoria.
    expect(AppStore.nextDose(r, now), isNotNull);
  });

  testWidgets('«Sì, le aggiungo dopo»: nessuna terapia, scheda in Home', (
    tester,
  ) async {
    final store = await _store(tester);
    await _open(tester, store);
    await _fillFirstTwo(tester);
    await _tap(tester, 'Avanti');
    await _tap(tester, 'Sì, le aggiungo dopo');
    expect(find.byType(RecordFormPage), findsNothing);
    expect(
      find.text('Troverai in Home un promemoria per aggiungerle.'),
      findsOneWidget,
    );
    await _tap(tester, 'Avanti');
    await _finish(tester, 'Fatto');
    await _finish(tester, 'Non ora');
    expect(store.dogs.single.medsToAdd, isTrue);
    expect(store.records, isEmpty);
  });

  testWidgets(
    'procedura al 200%: nessun overflow, nessuna etichetta troncata',
    (tester) async {
      final store = await _store(tester);
      await _loadAtkinson(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      await tester.binding.setSurfaceSize(const Size(360, 3000));
      await _open(tester, store);

      void check(String step) {
        expect(tester.takeException(), isNull, reason: step);
        final cut = <String>[];
        for (final e
            in find
                .descendant(
                  of: find.byType(DogWizardPage),
                  matching: find.byType(RichText),
                )
                .evaluate()) {
          final p = e.renderObject! as RenderParagraph;
          if (p.didExceedMaxLines) cut.add(p.text.toPlainText());
        }
        expect(cut, isEmpty, reason: '$step, testi troncati: $cut');
      }

      check('passo 1');
      await tester.enterText(find.byType(TextField), 'Birba');
      await _tap(tester, 'Avanti');
      await _tap(tester, 'Avanti'); // mostra anche gli errori
      check('passo 2 con errori');
      await _tap(tester, 'Scegli la data');
      await _tap(tester, 'OK');
      await tester.enterText(find.byType(TextField), '9');
      await _tap(tester, 'Avanti');
      check('passo 3');
      await _tap(tester, 'Avanti');
      await _tap(tester, 'Sì, le aggiungo dopo');
      check('passo 4');
      await _tap(tester, 'Avanti');
      check('passo 5');
      expect(find.text('Fatto'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    },
  );
}
