// Lulù come web app installabile (PWA) e APK: nome, manifest, icone e
// avviso per i dispositivi che non ricevono notifiche (web, iPhone).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/brand.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/device_notice.dart';
import 'package:zampa/ui/privacy_screen.dart';
import 'package:zampa/ui/theme.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildTheme(Brightness.light),
  home: Scaffold(body: ListView(children: [child])),
);

void main() {
  group('Nome', () {
    test('il nome visibile è Lulù, i file usano Lulu senza accento', () {
      expect(appName, 'Lulù');
      expect(appFileName, 'Lulu');
      expect(
        backupFileName(DateTime(2026, 11, 13)),
        'lulu-backup-2026-11-13.json',
      );
    });

    test('Android mostra Lulù sotto l\'icona (applicationId invariato)', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      expect(manifest, contains('android:label="$appName"'));
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();
      expect(gradle, contains('applicationId = "it.zampa.zampa"'));
    });
  });

  group('Web app installabile', () {
    final manifest = jsonDecode(
      File('web/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    test('manifest: nome, colori, avvio relativo al base href', () {
      expect(manifest['short_name'], appName);
      expect(manifest['name'], startsWith(appName));
      expect(manifest['display'], 'standalone');
      expect(manifest['start_url'], './');
      expect(manifest['scope'], './');
      expect(manifest['theme_color'], '#22406A');
    });

    test('manifest: icone normali e maskable, tutte presenti', () {
      final icons = (manifest['icons'] as List).cast<Map<String, dynamic>>();
      expect(icons.where((i) => i['purpose'] == 'maskable'), hasLength(2));
      expect(icons.where((i) => i['sizes'] == '512x512'), hasLength(2));
      for (final i in icons) {
        expect(File('web/${i['src']}').existsSync(), isTrue, reason: i['src']);
      }
      expect(File('web/icons/apple-touch-icon.png').existsSync(), isTrue);
    });

    test('index.html: meta per iPhone, service worker di Lulù', () {
      final html = File('web/index.html').readAsStringSync();
      expect(html, contains('<base href="\$FLUTTER_BASE_HREF">'));
      expect(html, contains('apple-touch-icon'));
      expect(html, contains('apple-mobile-web-app-title" content="$appName"'));
      expect(html, contains('name="theme-color"'));
      expect(html, contains("register('sw.js')"));
      expect(html, contains('<title>$appName</title>'));
    });

    test('il bootstrap non registra il service worker di Flutter', () {
      // Quello di Flutter si disinstalla da solo e toglierebbe sw.js.
      final js = File('web/flutter_bootstrap.js').readAsStringSync();
      expect(js, contains('{{flutter_js}}'));
      expect(js, isNot(contains('serviceWorkerSettings:')));
    });

    test('sw.js ha le righe che tool/pwa_finalize.py riscrive', () {
      final sw = File('web/sw.js').readAsStringSync();
      expect(
        RegExp(r'^const VERSIONE = .*;$', multiLine: true).hasMatch(sw),
        isTrue,
      );
      expect(
        RegExp(r'^const PRECACHE = .*;$', multiLine: true).hasMatch(sw),
        isTrue,
      );
    });

    test('sw.js riceve i promemoria Web Push e apre Lulù al tocco', () {
      final sw = File('web/sw.js').readAsStringSync();
      expect(sw, contains("addEventListener('push'"));
      expect(sw, contains('showNotification('));
      expect(sw, contains("addEventListener('notificationclick'"));
    });

    test('pagina di download: APK e istruzioni per iPhone', () {
      final html = File('web/download.html').readAsStringSync();
      expect(html, contains('Scarica per Android (APK)'));
      expect(html, contains('href="lulu.apk"'));
      expect(html, contains('Aggiungi alla schermata Home'));
    });
  });

  group('Avviso: qui niente notifiche', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('si vede dove le notifiche non sono supportate', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const DeviceNotice(supported: false)));
      await tester.pumpAndSettle();
      expect(find.text(deviceNoticeText), findsOneWidget);
      expect(find.text('PROMEMORIA'), findsOneWidget);
    });

    testWidgets('non si vede su Android e iOS nativi', (tester) async {
      await tester.pumpWidget(_host(const DeviceNotice(supported: true)));
      await tester.pumpAndSettle();
      expect(find.text(deviceNoticeText), findsNothing);
    });

    testWidgets('«Ho capito» lo nasconde anche alle aperture successive', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const DeviceNotice(supported: false)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ho capito'));
      await tester.pumpAndSettle();
      expect(find.text(deviceNoticeText), findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(deviceNoticeKey), isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_host(const DeviceNotice(supported: false)));
      await tester.pumpAndSettle();
      expect(find.text(deviceNoticeText), findsNothing);
    });
  });

  group('Foto sul web', () {
    test(
      'oltre il tetto la foto è rifiutata e i dati restano salvabili',
      () async {
        SharedPreferences.setMockInitialValues({});
        final s = AppStore(
          prefs: await SharedPreferences.getInstance(),
          photoBudgetChars: 1000,
        );
        await s.load();
        // 600 byte → 800 caratteri base64: entra.
        final id = await s.savePhoto(Uint8List(600));
        expect(s.photo(id), hasLength(600));
        // La seconda supererebbe 1000 caratteri.
        await expectLater(
          s.savePhoto(Uint8List(600)),
          throwsA(isA<PhotoSpaceFull>()),
        );
        expect(const PhotoSpaceFull().message, contains('Android'));
      },
    );

    test('su Android e iOS nessun tetto', () async {
      expect(AppStore.defaultPhotoBudgetChars, isNull); // test non web
      SharedPreferences.setMockInitialValues({});
      final s = AppStore(prefs: await SharedPreferences.getInstance());
      await s.load();
      await s.savePhoto(Uint8List(3000000));
    });
  });
}
