// Test d'identità dei testi clinici (piano CEO §11.5, C2-4 punto 1).
//
// Fa girare le regole cliniche su una batteria di scenari che fa scattare
// ogni avviso e ogni variante di testo, e confronta tutto ciò che l'utente
// legge con l'istantanea salvata in test/snapshots/testi_clinici.txt.
// Se un testo cambia, anche di una virgola, il test fallisce.
//
// Una modifica voluta dei testi (per esempio dopo la firma del veterinario)
// si registra rigenerando l'istantanea:
//   ZAMPA_UPDATE_SNAPSHOT=1 flutter test test/clinical_texts_snapshot_test.dart
// e il diff dell'istantanea va riletto nel commit.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/logic/nutrition.dart';
import 'package:zampa/logic/prevention.dart';
import 'package:zampa/logic/seasonal.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/common.dart';
import 'package:zampa/ui/emergency_screen.dart';

import 'clinical_scenarios.dart';

const snapshotPath = 'test/snapshots/testi_clinici.txt';

String clinicalTexts() {
  final b = StringBuffer();
  void line(String s) => b.writeln(s.replaceAll('\n', r'\n'));

  line('### Frasi d\'azione dei livelli');
  for (final l in AlertLevel.values) {
    line('${l.name} | ${l.action}');
  }

  line('');
  line('### Avvisi (AlertEngine)');
  for (final s in alertScenarios()) {
    line('## ${s.name}');
    final out = AlertEngine.compute(
      dog: s.dog,
      logs: s.logs,
      records: s.records,
      weights: s.weights,
      now: s.now,
      repro: s.repro,
      pendingDoses: s.pending,
    );
    for (final a in out) {
      line(
        '${a.level.name} | ${a.title} | ${a.message} | '
        '${a.actionText ?? '(nessuna frase d\'azione)'}',
      );
    }
  }

  line('');
  line('### Prevenzione (PreventionPlanner.suggest)');
  for (final s in preventionScenarios()) {
    line('## ${s.name}');
    for (final r in PreventionPlanner.suggest(s.dog, s.records, s.now)) {
      line('${r.type.name} | ${r.title} | ${r.notes}');
    }
  }

  line('');
  line('### Nutrizione (Nutrition.plan)');
  for (final s in nutritionScenarios()) {
    line('## ${s.name}');
    final p = Nutrition.plan(s.dog, s.now);
    line('motivo | ${p.factorReason}');
    for (final n in p.notes) {
      line('nota | $n');
    }
  }
  line('## Body Condition Score');
  for (final e in Nutrition.bcsDescriptions.entries) {
    line('${e.key} | ${e.value}');
  }
  line('## Alimenti pericolosi');
  for (final f in Nutrition.toxicFoods) {
    line('${f.food} | ${f.danger} | ${f.severity}');
  }

  line('');
  line('### Stagioni, razze, cucciolo (SeasonalTips, Breeds)');
  for (final s in seasonalScenarios()) {
    line('## ${s.name}');
    for (final t in [
      ...Breeds.puppy(s.dog, s.now),
      ...SeasonalTips.forDog(s.dog, s.now),
      ...Breeds.predispositions(s.dog),
      ?Breeds.neuteringInfo(s.dog, s.now),
    ]) {
      line('${t.icon} | ${t.title} | ${t.text}');
    }
  }

  line('');
  line('### Emergenze: segnali d\'allarme (EmergencyScreen.redFlags)');
  for (final (title, help) in EmergencyScreen.redFlags) {
    line('$title | $help');
  }
  return b.toString();
}

/// Testi visibili nella scheda Emergenze, con e senza numeri nel profilo.
Future<String> emergencyScreenTexts(WidgetTester tester) async {
  final b = StringBuffer();
  tester.view.physicalSize = const Size(1200, 30000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  for (final (name, dog) in emergencyDogs()) {
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
    b.writeln('## $name');
    for (final w in tester.widgetList<Text>(find.byType(Text))) {
      final s = w.data ?? w.textSpan?.toPlainText() ?? '';
      // La prima riga di «Cosa dire al telefono» contiene l'età calcolata
      // oggi: cambia con il calendario e non è un testo clinico.
      if (s.isEmpty || s.startsWith('• ${dog?.name},')) continue;
      b.writeln(s.replaceAll('\n', r'\n'));
    }
  }
  return b.toString();
}

void main() {
  testWidgets('i testi clinici coincidono con l\'istantanea', (tester) async {
    final actual =
        '${clinicalTexts()}\n### Emergenze: scheda (EmergencyScreen)\n'
        '${await emergencyScreenTexts(tester)}';
    final file = File(snapshotPath);
    if (Platform.environment['ZAMPA_UPDATE_SNAPSHOT'] == '1') {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(actual);
    }
    expect(file.existsSync(), isTrue, reason: 'manca $snapshotPath');
    final expected = file.readAsStringSync();
    if (actual != expected) {
      final a = actual.split('\n'), e = expected.split('\n');
      final diff = <String>[];
      for (var i = 0; i < a.length || i < e.length; i++) {
        final x = i < e.length ? e[i] : '(assente)';
        final y = i < a.length ? a[i] : '(assente)';
        if (x != y) diff.add('riga ${i + 1}\n  atteso: $x\n  trovato: $y');
        if (diff.length >= 10) break;
      }
      fail('I testi clinici sono cambiati:\n${diff.join('\n')}');
    }
  });
}
