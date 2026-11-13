import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zampa/main.dart';
import 'package:zampa/models.dart';
import 'package:zampa/notifications.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/emergency_screen.dart';
import 'package:zampa/ui/pdf_export.dart';

/// Collaudo sul dispositivo, parte iOS di C2-1 (rapporto 10).
///
/// Prepara un cane vero con una dose fra [doseMinutes] minuti, poi prova
/// testo al 200%, tema scuro, galleria, PDF e pulsanti d'emergenza. Le parti
/// che richiedono un tocco fuori da Flutter (permesso, selettore delle foto,
/// foglio di condivisione) stampano un marcatore `>>>` e aspettano: il
/// collaudatore agisce con `simctl` o con un tocco sul simulatore.
///
/// La consegna della dose ad app chiusa si verifica dopo il test: alla fine
/// l'app aspetta; si termina il processo `flutter` per PID (altrimenti
/// `flutter test` disinstalla l'app e con lei le notifiche in attesa), poi
/// `simctl terminate`, e si controllano log e schermata. La persistenza con
/// `integration_test/persistence_test.dart`, che non cancella i dati.
///
/// Esecuzione: `flutter test integration_test/device_test.dart -d ID`
/// Galleria saltata con `--dart-define=GALLERIA=no`.
const doseMinutes = int.fromEnvironment('DOSE_MIN', defaultValue: 8);
const gallery = String.fromEnvironment('GALLERIA', defaultValue: 'si');

void log(String s) {
  // ignore: avoid_print
  print(s);
}

Future<void> settle(WidgetTester tester, [int steps = 20]) async {
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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

Future<void> tapText(WidgetTester tester, String text) async {
  final f = await reveal(tester, text);
  await tester.tap(f.first);
}

/// Raccoglie le eccezioni di disegno (per esempio i RenderFlex in overflow).
List<String> drain(WidgetTester tester) {
  final out = <String>[];
  Object? e;
  while ((e = tester.takeException()) != null) {
    final lines = e.toString().split('\n');
    // Prima riga e, per gli overflow, il widget che li causa.
    final who = lines.firstWhere(
      (l) => l.contains('creator') || l.contains('Column') || l.contains('Row'),
      orElse: () => '',
    );
    out.add('${lines.first} ${who.trim()}');
  }
  return out;
}

/// Scorre tutta la pagina visibile fino in fondo, per costruire ogni riga.
Future<void> scrollAll(WidgetTester tester) async {
  final vertical = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  if (vertical.evaluate().isEmpty) return;
  for (var i = 0; i < 25; i++) {
    await tester.drag(vertical.first, const Offset(0, -500));
    await settle(tester, 3);
  }
  for (var i = 0; i < 25; i++) {
    await tester.drag(vertical.first, const Offset(0, 500));
    await settle(tester, 2);
  }
}

const tabs = ['Oggi', 'Bisogni', 'Salute', 'Nutrizione', 'Profilo'];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('C2-1 iOS: cane vero, aspetto, galleria, PDF, emergenze', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await Notifier.instance.init();
    await Notifier.instance.cancelAll();
    final store = AppStore(prefs: prefs, notifier: Notifier.instance);
    await store.load();
    await tester.pumpWidget(ZampaApp(store: store));
    await settle(tester);
    await tapText(tester, 'Ho letto e ho capito');
    await settle(tester);
    await tapText(tester, 'Continua');
    await settle(tester);

    // --- Cane vero con numeri utili, pipì, terapia e un vaccino -------------
    final now = DateTime.now();
    final dog = Dog(
      id: newId(),
      name: 'Birba',
      birthDate: DateTime(now.year - 4, now.month, 1),
      sex: Sex.femmina,
      weightKg: 9,
      vetName: 'Dott.ssa Rossi',
      vetPhone: '+39 055 123 4567',
      emergencyPhone: '055 765 4321',
    );
    await store.upsertDog(dog);
    await settle(tester);

    log('>>> PERMESSO NOTIFICHE: tocca «Consenti»');
    final granted = await Notifier.instance.requestPermissions().timeout(
      const Duration(seconds: 120),
      onTimeout: () => false,
    );
    log('PERMESSO CONCESSO (risposta del plugin): $granted');
    await Future<void>.delayed(const Duration(seconds: 2));
    final allowed = await Notifier.instance.refreshAllowed();
    log('PERMESSO LETTO DAL SISTEMA: $allowed');
    expect(allowed, isTrue);

    await store.addLog(
      LogEntry(
        id: newId(),
        dogId: dog.id,
        type: LogType.pipi,
        time: now.subtract(const Duration(minutes: 30)),
      ),
    );
    // Prima dose esattamente fra doseMinutes minuti, poi ogni 12 ore.
    final firstDose = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(minutes: doseMinutes));
    await store.upsertRecord(
      HealthRecord(
        id: newId(),
        dogId: dog.id,
        type: RecordType.farmaco,
        title: 'Antibiotico di prova',
        dose: '1 compressa',
        date: firstDose,
        everyHours: 12,
        endDate: now.add(const Duration(days: 5)),
      ),
    );
    await store.upsertRecord(
      HealthRecord(
        id: newId(),
        dogId: dog.id,
        type: RecordType.vaccino,
        title: 'Richiamo leptospirosi',
        date: now.subtract(const Duration(days: 360)),
        nextDue: now.add(const Duration(days: 5)),
      ),
    );
    await settle(tester);

    final planned = store.planNotifications(DateTime.now());
    log('TABELLA ORARI (${planned.length} programmate):');
    for (final p in planned) {
      log(
        'ORARIO|${p.id}|${p.when.toIso8601String()}|${p.priority}|'
        '${p.exact ? 'esatta' : 'non esatta'}|${p.title}',
      );
    }
    final pending = await Notifier.instance.pending();
    log('NOTIFICHE IN ATTESA NEL SISTEMA: ${pending.length}');
    expect(pending.length, planned.length);
    expect(
      planned.any((p) => p.when == firstDose && p.title.startsWith('💊')),
      isTrue,
      reason: 'dose di prova fra $doseMinutes minuti',
    );
    log('DOSE DI PROVA ALLE: ${firstDose.toIso8601String()}');

    // --- Testo al 200% su tutte le schede ---------------------------------
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    await settle(tester);
    final overflow200 = <String>[];
    for (final (i, tab) in tabs.indexed) {
      await tester.tap(find.byType(NavigationDestination).at(i));
      await settle(tester);
      await scrollAll(tester);
      for (final e in drain(tester)) {
        overflow200.add('$tab: $e');
      }
    }
    await tester.tap(find.byType(NavigationDestination).first);
    await settle(tester);
    await tapText(tester, 'Emergenze');
    await settle(tester);
    expect(find.byType(EmergencyScreen), findsOneWidget);
    await scrollAll(tester);
    for (final e in drain(tester)) {
      overflow200.add('Emergenze: $e');
    }
    log('TESTO 200%: ${overflow200.length} errori di disegno');
    for (final e in overflow200) {
      log('  200% $e');
    }
    Navigator.of(tester.element(find.byType(EmergencyScreen))).pop();
    await settle(tester);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    await settle(tester);

    // --- Tema scuro ---------------------------------------------------------
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await settle(tester);
    final ctx = tester.element(find.byType(Scaffold).first);
    final darkOk = Theme.of(ctx).brightness == Brightness.dark;
    log('TEMA SCURO APPLICATO: $darkOk');
    final darkErrors = <String>[];
    for (final (i, tab) in tabs.indexed) {
      await tester.tap(find.byType(NavigationDestination).at(i));
      await settle(tester);
      darkErrors.addAll(drain(tester).map((e) => '$tab: $e'));
    }
    log('TEMA SCURO: ${darkErrors.length} errori');
    expect(darkOk, isTrue);
    tester.platformDispatcher.clearPlatformBrightnessTestValue();
    await tester.tap(find.byType(NavigationDestination).first);
    await settle(tester);

    // --- Galleria -----------------------------------------------------------
    if (gallery == 'si') {
      log('>>> GALLERIA: scegli una foto nel selettore');
      try {
        final x = await ImagePicker()
            .pickImage(
              source: ImageSource.gallery,
              maxWidth: 900,
              imageQuality: 70,
            )
            .timeout(const Duration(seconds: 150));
        if (x == null) {
          log('GALLERIA: nessuna foto scelta');
        } else {
          final bytes = await x.readAsBytes();
          final id = await store.savePhoto(bytes);
          final back = store.photo(id);
          log('GALLERIA: foto di ${bytes.length} byte, salvata come $id, '
              'riletta ${back?.length} byte');
          await store.addLog(
            LogEntry(
              id: newId(),
              dogId: dog.id,
              type: LogType.cacca,
              time: DateTime.now(),
              photoId: id,
            ),
          );
        }
      } catch (e) {
        log('GALLERIA: errore $e');
      }
      await settle(tester);
    }

    // --- PDF: generazione e condivisione ------------------------------------
    final bytes = await buildPdf(store, dog, DateTime.now());
    final header = String.fromCharCodes(bytes.take(5));
    final file = File('${Directory.systemTemp.path}/zampa_collaudo.pdf');
    await file.writeAsBytes(bytes);
    log('PDF: ${bytes.length} byte, intestazione $header, ${file.path}');
    expect(header, '%PDF-');
    log('>>> CONDIVISIONE PDF: foglio di condivisione aperto per 20 s');
    final shareFuture = Printing.sharePdf(
      bytes: bytes,
      filename: 'Lulu_Birba_collaudo.pdf',
    );
    var shared = '(in corso)';
    shareFuture.then((v) => shared = '$v').catchError((Object e) {
      shared = 'errore $e';
      return shared;
    });
    await Future<void>.delayed(const Duration(seconds: 20));
    log('CONDIVISIONE PDF: esito $shared');

    // --- Emergenze: tel: e mappa --------------------------------------------
    final tel = Uri(scheme: 'tel', path: dog.vetPhone.replaceAll(' ', ''));
    final canTel = await canLaunchUrl(tel);
    bool? telOk;
    try {
      telOk = await launchUrl(tel);
    } catch (e) {
      log('TEL: errore $e');
    }
    log('TEL: canLaunch=$canTel launch=$telOk ($tel)');
    final maps = Uri.parse(
      'https://www.google.com/maps/search/pronto+soccorso+veterinario',
    );
    final mapsOk = await launchUrl(maps, mode: LaunchMode.externalApplication);
    log('MAPPA: launch=$mapsOk');
    log('>>> MAPPA APERTA: schermata entro 10 s');
    await Future<void>.delayed(const Duration(seconds: 10));
    // L'app resta aperta: il collaudatore chiude il processo `flutter` (per
    // PID, così l'app non viene disinstallata) e poi l'app con
    // `simctl terminate`, e verifica la consegna della dose ad app chiusa.
    log('>>> FINE PROVE: chiudere ora flutter e l\'app (attesa massima 10 min)');
    await Future<void>.delayed(const Duration(minutes: 10));
    log('FINE DEVICE TEST');
  });
}
