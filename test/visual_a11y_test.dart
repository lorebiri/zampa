// Controlli automatici dell'identità visiva (ricerca/22-direzione-visiva.md):
// contrasto del testo in chiaro e in scuro, testo al 200% senza overflow,
// aree di tocco di almeno 44 px (stile Lulù, docs/design/).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/main.dart';
import 'package:zampa/store.dart';
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
  // Con il testo al 200% la casella (con la frase sull'età) può restare
  // appena sotto il bordo: la si porta del tutto in vista.
  await tester.ensureVisible(find.text('Ho letto e ho capito'));
  await tester.pump();
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

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('i colori degli allarmi superano 4,5:1 in chiaro e in scuro', () {
    for (final c in [AppColors.light, AppColors.darkColors]) {
      for (final l in AlertLevel.values) {
        final tone = c.tone(l);
        expect(
          _contrast(tone.fg, tone.bg),
          greaterThanOrEqualTo(4.5),
          reason: '$l (scuro: ${c.dark})',
        );
        // Icona e banda: almeno 3:1 (elementi grafici, WCAG 1.4.11).
        expect(
          _contrast(l == AlertLevel.subito ? tone.fg : tone.accent, tone.bg),
          greaterThanOrEqualTo(3),
        );
      }
    }
  });

  for (final dark in [false, true]) {
    testWidgets('Oggi: contrasto del testo (${dark ? 'scuro' : 'chiaro'})', (
      tester,
    ) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      await _openDemo(tester);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });
  }

  testWidgets('testo al 200%: nessun overflow nelle schede principali', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    await tester.binding.setSurfaceSize(const Size(400, 880));
    await _openDemo(tester);
    expect(tester.takeException(), isNull);
    // Con il testo grande la barra mostra l'etichetta solo sulla voce
    // attiva: si tocca la voce intera.
    // Testo che compare solo nella pagina aperta.
    const pages = [
      ('Bisogni', 'Registra'),
      ('Salute', 'Salute di Luna'),
      ('Nutrizione', 'Nutrizione di Luna'),
      ('Profilo', 'I tuoi cani'),
    ];
    for (final (i, (tab, marker)) in pages.indexed) {
      await tester.tap(find.byType(NavigationDestination).at(i + 1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull, reason: tab);
      expect(find.text(marker, skipOffstage: false), findsWidgets);
    }
    await tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });

  for (final dark in [false, true]) {
    testWidgets('aree di tocco ≥ 44 px e contrasto in tutte le schede '
        '(${dark ? 'scuro' : 'chiaro'})', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      await tester.binding.setSurfaceSize(const Size(420, 2400));
      await _openDemo(tester);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byType(NavigationDestination).at(i));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      }
      await tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });
  }
}
