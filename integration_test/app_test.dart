import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/main.dart';
import 'package:zampa/models.dart';
import 'package:zampa/notifications.dart';
import 'package:zampa/store.dart';

/// Collaudo sul dispositivo (C1-2): app vera, notifiche vere del sistema.
/// Esecuzione: `flutter test integration_test/app_test.dart -d ID_SIMULATORE`
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Porta un testo sullo schermo, scorrendo la lista verticale se serve
/// (le liste pigre non costruiscono ciò che è fuori schermo).
Future<Finder> reveal(WidgetTester tester, String text) async {
  final f = find.text(text);
  if (f.evaluate().isEmpty) {
    final vertical = find.byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(f, 200, scrollable: vertical.first);
  } else {
    await tester.ensureVisible(f.first);
  }
  await settle(tester);
  return f;
}

/// Tocca un testo, scorrendo la pagina se è fuori schermo.
Future<void> tapText(WidgetTester tester, String text) async {
  final f = await reveal(tester, text);
  await tester.tap(f.first);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('avvio, cane di esempio, schede e notifiche programmate', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await Notifier.instance.init();
    final store = AppStore(prefs: prefs, notifier: Notifier.instance);
    await store.load();
    await tester.pumpWidget(ZampaApp(store: store));
    await settle(tester);

    // Avvertenza iniziale.
    expect(find.text('Prima di iniziare'), findsOneWidget);
    await tapText(tester, 'Ho letto e ho capito');
    await settle(tester);
    await tapText(tester, 'Continua');
    await settle(tester);

    // Cane di esempio e schermata Oggi.
    await tapText(tester, 'Prova con un cane di esempio');
    // Il compagno in pixel art è animato in continuo: niente pumpAndSettle
    // da qui in poi, solo avanzamenti a tempo.
    await settle(tester);
    expect(find.text('Luna'), findsWidgets);
    expect(await reveal(tester, 'Prossima pipì'), findsOneWidget);

    // Navigazione tra le schede principali.
    for (final tab in ['Bisogni', 'Salute', 'Nutrizione', 'Profilo', 'Oggi']) {
      await tester.tap(find.text(tab).last);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'scheda $tab');
    }

    // Permesso notifiche come nel flusso reale (dopo il primo cane), poi
    // riprogrammazione: iOS scarta le richieste fatte senza permesso.
    // ignore: avoid_print
    print('RICHIESTA PERMESSO NOTIFICHE');
    final granted = await Notifier.instance.requestPermissions().timeout(
      const Duration(seconds: 90),
      onTimeout: () => false,
    );
    // ignore: avoid_print
    print('PERMESSO CONCESSO: $granted');
    expect(granted, isTrue, reason: 'consentire le notifiche nel simulatore');
    await store.upsertDog(store.dog!);
    await settle(tester);

    // Notifiche: il sistema deve avere notifiche in attesa, entro il tetto.
    expect(
      Notifier.instance.ready,
      isTrue,
      reason: 'plugin notifiche inizializzato',
    );
    final pending = await Notifier.instance.pending();
    // ignore: avoid_print
    print('NOTIFICHE IN ATTESA: ${pending.length}');
    for (final p in pending.take(8)) {
      // ignore: avoid_print
      print('  #${p.id} ${p.title}');
    }
    expect(pending, isNotEmpty);
    expect(pending.length, lessThanOrEqualTo(AppStore.maxScheduled));
    expect(
      pending.any((p) => (p.title ?? '').startsWith('💊')),
      isTrue,
      reason: 'dosi della terapia',
    );

    // Registrazione di una pipì con un tocco dalla schermata Oggi.
    final before = store.logs.where((l) => l.type == LogType.pipi).length;
    await tapText(tester, 'Fatta fuori');
    await settle(tester);
    expect(store.logs.where((l) => l.type == LogType.pipi).length, before + 1);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
