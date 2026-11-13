// Profilo › Privacy (R-P1, R-P4, R-P5 di ricerca/24-privacy.md).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/consent.dart';
import 'package:zampa/main.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/common.dart';
import 'package:zampa/ui/privacy_screen.dart';

void main() {
  late SharedPreferences prefs;
  late AppStore store;
  late ConsentStore consent;
  final shared = <({String json, String name})>[];

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      StoreScope(
        store: store,
        child: MaterialApp(
          home: PrivacyScreen(
            consent: consent,
            share: (json, name, _) async =>
                shared.add((json: json, name: name)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  bool switchOn(WidgetTester tester, String title) => tester
      .widget<SwitchListTile>(find.widgetWithText(SwitchListTile, title))
      .value;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = AppStore(prefs: prefs);
    await store.load();
    consent = ConsentStore(prefs: prefs);
    await consent.load();
    shared.clear();
  });

  testWidgets('i due interruttori sono separati e spenti di serie', (
    tester,
  ) async {
    await open(tester);
    expect(switchOn(tester, 'Studio sull\'accuratezza'), isFalse);
    expect(switchOn(tester, 'Rapporti di errore'), isFalse);
    expect(consent.allowed(ConsentKind.study), isFalse);
    expect(consent.allowed(ConsentKind.crashReports), isFalse);
    expect(find.text('Spento'), findsNWidgets(2));
  });

  testWidgets('la scelta si salva con data e versione del testo', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Studio sull\'accuratezza'));
    await tester.pumpAndSettle();
    // Prima volta: domanda sull'età.
    expect(find.text('Una domanda prima'), findsOneWidget);
    await tester.tap(
      find.text('Ho almeno 14 anni, o un genitore è d\'accordo'),
    );
    await tester.pumpAndSettle();

    expect(switchOn(tester, 'Studio sull\'accuratezza'), isTrue);
    expect(switchOn(tester, 'Rapporti di errore'), isFalse);
    expect(consent.ageConfirmed, isTrue);

    final saved = jsonDecode(
      prefs.getString('zampa_consent_study_v1')!,
    ) as Map<String, Object?>;
    expect(saved['granted'], isTrue);
    expect(saved['version'], ConsentStore.studyVersion);
    expect(DateTime.parse(saved['at']! as String).year, DateTime.now().year);
    expect(prefs.getString('zampa_consent_crashReports_v1'), isNull);

    // Riletta da capo (riavvio dell'app).
    final again = ConsentStore(prefs: prefs);
    await again.load();
    expect(again.allowed(ConsentKind.study), isTrue);
    expect(again.allowed(ConsentKind.crashReports), isFalse);

    // Ritiro con un tocco, senza altre domande.
    await tester.tap(find.text('Studio sull\'accuratezza'));
    await tester.pumpAndSettle();
    expect(find.text('Una domanda prima'), findsNothing);
    expect(switchOn(tester, 'Studio sull\'accuratezza'), isFalse);
    expect(find.text('Fatto. Non inviamo più nulla.'), findsOneWidget);
    final off = ConsentChoice.tryParse(
      prefs.getString('zampa_consent_study_v1'),
    )!;
    expect(off.granted, isFalse);
  });

  testWidgets('senza la conferma dell\'età l\'interruttore resta spento', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Rapporti di errore'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();
    expect(switchOn(tester, 'Rapporti di errore'), isFalse);
    expect(prefs.getString('zampa_consent_crashReports_v1'), isNull);
  });

  test('un sì dato su un testo vecchio non vale più', () async {
    SharedPreferences.setMockInitialValues({
      'zampa_consent_study_v1': jsonEncode({
        'granted': true,
        'at': '2026-01-01T10:00:00.000',
        'version': 'tele-vecchio',
      }),
    });
    final c = ConsentStore(prefs: await SharedPreferences.getInstance());
    await c.load();
    expect(c.choice(ConsentKind.study)!.granted, isTrue);
    expect(c.allowed(ConsentKind.study), isFalse);
  });

  testWidgets('«Cancella tutti i dati» chiede conferma', (tester) async {
    await store.loadDemo();
    expect(store.dogs, isNotEmpty);
    await open(tester);

    await tester.tap(find.text('Cancella tutti i dati'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Non si può annullare'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(store.dogs, isNotEmpty);

    await tester.tap(find.text('Cancella tutti i dati'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elimina'));
    await tester.pumpAndSettle();
    expect(store.dogs, isEmpty);
    expect(store.logs, isEmpty);
  });

  testWidgets('«Esporta i miei dati» crea un file, non usa gli appunti', (
    tester,
  ) async {
    await store.loadDemo();
    await open(tester);
    await tester.tap(find.text('Esporta i miei dati'));
    await tester.pumpAndSettle();
    expect(shared, hasLength(1));
    expect(
      shared.single.name,
      matches(r'^lulu-backup-\d{4}-\d\d-\d\d\.json$'),
    );
    final j = jsonDecode(shared.single.json) as Map<String, Object?>;
    expect((j['dogs']! as List).length, store.dogs.length);
    expect(find.textContaining('Backup pronto'), findsOneWidget);
  });

  testWidgets('le condizioni d\'uso chiedono l\'età e la salvano', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ZampaApp(store: store));
    expect(find.textContaining('almeno 14 anni'), findsOneWidget);
    await tester.tap(find.text('Ho letto e ho capito'));
    await tester.pump();
    await tester.tap(find.text('Continua'));
    await tester.runAsync(() async {});
    await tester.pump();
    expect(store.termsAccepted, isTrue);
    expect(
      prefs.getString('zampa_age_ok_v1'),
      contains(ConsentStore.ageVersion),
    );
  });

  testWidgets('l\'informativa si legge senza le note per lo sviluppatore', (
    tester,
  ) async {
    final md = File(privacyAsset).readAsStringSync();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) =>
              ListView(children: markdownWidgets(md, Theme.of(context))),
        ),
      ),
    );
    Finder has(String s) => find.textContaining(s, findRichText: true);
    expect(has('Informativa privacy di Lulù'), findsOneWidget);
    expect(has('1. In breve'), findsOneWidget);
    expect(has('Stato:'), findsNothing);
    expect(has('**'), findsNothing);
    expect(has('[da completare]'), findsWidgets);
  });

  test('i testi dei consensi partono dal primo livello per l\'utente', () {
    final md = File(consentAsset).readAsStringSync();
    final part = section(md, from: '### Ci aiuti', to: '## Testo breve');
    expect(part, startsWith('### Ci aiuti'));
    expect(part, contains('Rapporti di errore'));
    expect(part, contains('Secondo livello'));
    expect(part, isNot(contains('Regole per lo sviluppatore')));
    expect(part, isNot(contains('Testo breve per Profilo')));
  });
}
