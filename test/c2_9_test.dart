// C2-9 (ricerca/08-piano-ceo.md §11.5): Atkinson nel PDF, conferma prima di
// «Saltato», riassunti dei grafici e modulo del cane al 200%.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/main.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/chart_summary.dart';
import 'package:zampa/ui/common.dart';
import 'package:zampa/ui/dog_form.dart';
import 'package:zampa/ui/pdf_export.dart';
import 'package:zampa/ui/theme.dart';

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

/// Il carattere vero (non quello di prova, largo un quadrato per lettera):
/// misura come sul telefono.
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
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PDF del cane di esempio con Atkinson Hyperlegible Next', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(prefs: await SharedPreferences.getInstance());
    await store.load();
    await store.loadDemo();
    final dog = store.dogs.first;
    final bytes = await buildPdf(store, dog, DateTime.now());
    expect(bytes.length, greaterThan(1000));
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');

    final theme = await pdfTheme();
    for (final f in [
      theme.defaultTextStyle.font,
      theme.defaultTextStyle.fontBold,
      theme.defaultTextStyle.fontItalic,
    ]) {
      expect(f, isA<pw.TtfFont>());
      expect(f!.fontName, contains('Atkinson'));
    }
    // «–» ed «è» sono nel font incluso (nell'Helvetica predefinita no).
    final regular = theme.defaultTextStyle.font! as pw.TtfFont;
    final glyphs = TtfParser(regular.data).charToGlyphIndexMap;
    expect(glyphs.containsKey(0x2013), isTrue);
    expect(glyphs.containsKey(0x00E8), isTrue);
    // Per il controllo a vista del QA: ZAMPA_PDF_OUT=/percorso/prova.pdf
    final out = Platform.environment['ZAMPA_PDF_OUT'];
    if (out != null) File(out).writeAsBytesSync(bytes);
  });

  testWidgets('«Saltato» chiede conferma, «Dato» no', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 2400));
    final store = await _openDemo(tester);
    final before = store.doses.length;
    expect(store.pendingDoses(store.dog!.id, DateTime.now()), isNotEmpty);
    await tester.scrollUntilVisible(
      find.text('Saltato'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Saltato').first);
    await tester.pumpAndSettle();

    // Annullare non registra nulla.
    await tester.tap(find.text('Saltato').first);
    await tester.pumpAndSettle();
    expect(find.text('Dose saltata?'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(store.doses.length, before);

    // Confermare registra la dose come saltata.
    await tester.tap(find.text('Saltato').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sì, saltata'));
    await tester.runAsync(() async {});
    await tester.pumpAndSettle();
    expect(store.doses.length, before + 1);
    expect(store.doses.last.status, DoseStatus.saltato);

    // «Dato» resta con un solo tocco, se c'è ancora una dose da confermare.
    if (find.text('Dato').evaluate().isNotEmpty) {
      await tester.tap(find.text('Dato').first);
      await tester.runAsync(() async {});
      await tester.pumpAndSettle();
      expect(find.text('Dose saltata?'), findsNothing);
      expect(store.doses.length, before + 2);
      expect(store.doses.last.status, DoseStatus.dato);
    }
    await tester.binding.setSurfaceSize(null);
  });

  group('riassunti dei grafici', () {
    test('barre per giorno', () {
      final now = DateTime(2026, 11, 11, 18);
      final m = {
        for (var i = 0; i < 7; i++)
          DateTime(2026, 11, 11 - i): [4, 3, 5, 4, 4, 4, 4][i],
      };
      expect(
        dayBarsSummary(m, now, what: 'pipì', days: 7),
        'Ultimi 7 giorni: da 3 a 5 pipì al giorno, media 4; oggi 4.',
      );
      expect(
        dayBarsSummary({}, now, what: 'pipì'),
        'Ultimi 14 giorni: nessuna registrazione.',
      );
    });

    test('serie nel tempo', () {
      expect(
        seriesSummary(
          'Andamento del peso',
          [13.4, 13.6, 14.2],
          dates: [
            DateTime(2026, 6, 14),
            DateTime(2026, 8, 1),
            DateTime(2026, 11, 11),
          ],
          unit: 'kg',
        ),
        'Andamento del peso: 3 valori dal 14/06/2026 al 11/11/2026, '
        'da 13,4 a 14,2 kg; ultimo 14,2 kg.',
      );
    });

    testWidgets('i grafici delle schede hanno un riassunto', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2400));
      final handle = tester.ensureSemantics();
      await _openDemo(tester);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(r'^Ultimi 14 giorni: .*al giorno')),
        findsOneWidget,
      );
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Peso'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp(r'^Andamento del peso: \d+ valori')),
        findsOneWidget,
      );
      handle.dispose();
      await tester.binding.setSurfaceSize(null);
    });
  });

  testWidgets('modulo del cane al 200%: etichette a capo, mai troncate', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore(prefs: await SharedPreferences.getInstance());
    await store.load();
    await tester.runAsync(store.loadDemo);
    await _loadAtkinson(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    // Telefono stretto, alto abbastanza da costruire tutto il modulo.
    await tester.binding.setSurfaceSize(const Size(360, 12000));
    for (final dog in [null, store.dogs.first]) {
      await tester.pumpWidget(
        StoreScope(
          store: store,
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            home: DogFormPage(dog: dog),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final cut = <String>[];
      for (final e
          in find
              .descendant(
                of: find.byType(DogFormPage),
                matching: find.byType(RichText),
              )
              .evaluate()) {
        final p = e.renderObject! as RenderParagraph;
        if (p.didExceedMaxLines) cut.add(p.text.toPlainText());
      }
      expect(cut, isEmpty, reason: 'etichette troncate: $cut');
      expect(
        find.text('Pronto soccorso veterinario h24 di riferimento'),
        findsOneWidget,
      );
    }
    await tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  testWidgets('barre dei bisogni al 200%: nessun overflow', (tester) async {
    await _loadAtkinson(tester);
    await tester.binding.setSurfaceSize(const Size(360, 3000));
    await _openDemo(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Ultimi 14 giorni'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}
