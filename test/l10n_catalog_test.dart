// Controlli del catalogo dei testi (piano CEO §11.5, C2-4 punto 2).
//
// 1. Ogni voce dell'ARB porta il suo ID e la chiave corrisponde all'ID.
// 2. La tabella generata (clinical_catalog.g.dart) è aggiornata.
// 3. Ogni ID usato nel codice esiste nell'ARB e viceversa.
// 4. Gli scenari del test d'identità fanno scattare ogni avviso.
// 5. Nessuna stringa visibile all'utente dentro lib/logic/ fuori dal
//    catalogo (con l'elenco esatto dei file che restano da migrare).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/l10n/clinical_catalog.g.dart';
import 'package:zampa/l10n/clinical_text.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/logic/modules.dart';
import 'package:zampa/logic/nutrition.dart';
import 'package:zampa/ui/emergency_screen.dart';

import '../tool/gen_clinical_catalog.dart' as gen;
import 'clinical_scenarios.dart';

final idPattern = RegExp(r'^[A-Z]{2,3}(-[A-Z]{2,3})?-\d+[a-z]?$');

Map<String, dynamic> arb() =>
    jsonDecode(File('lib/l10n/app_it.arb').readAsStringSync())
        as Map<String, dynamic>;

/// ID del catalogo → parti presenti (Title, Text, Action).
Map<String, Set<String>> arbIds() {
  final out = <String, Set<String>>{};
  final a = arb();
  for (final k in a.keys.where((k) => !k.startsWith('@'))) {
    final desc = (a['@$k'] as Map)['description'] as String;
    final id = desc.split(' ').first;
    final part = k.substring(catalogKey(id).length);
    out.putIfAbsent(id, () => {}).add(part);
  }
  return out;
}

List<File> dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => !f.path.endsWith('.g.dart'))
        .where((f) => !f.path.contains('app_localizations'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

// --- Lettura delle stringhe di un file Dart ---------------------------------

class Literal {
  Literal(this.text, this.line, this.calls);
  final String text;
  final int line;

  /// Funzioni le cui parentesi contengono la stringa (es. RegExp, _has).
  final List<String> calls;
}

/// Stringhe letterali di un sorgente Dart, senza i commenti e con le parti
/// interpolate (`${...}`) tolte dal testo.
List<Literal> literalsOf(String src) {
  final out = <Literal>[];
  final calls = <String>[];
  var i = 0;
  final newlines = [for (final m in '\n'.allMatches(src)) m.start];
  int lineAt(int pos) {
    var n = 0;
    while (n < newlines.length && newlines[n] < pos) {
      n++;
    }
    return n + 1;
  }

  late int Function(int) skipExpr;

  // Legge una stringa che inizia in [start] (dopo l'eventuale r) e
  // restituisce la posizione dopo la chiusura.
  int readString(int start, bool raw, StringBuffer text) {
    final q = src[start];
    final triple = src.startsWith(q * 3, start);
    final close = triple ? q * 3 : q;
    var k = start + close.length;
    while (k < src.length) {
      if (src.startsWith(close, k)) return k + close.length;
      final c = src[k];
      if (!raw && c == r'\') {
        text.write(src[k + 1]);
        k += 2;
        continue;
      }
      if (!raw && c == r'$') {
        if (k + 1 < src.length && src[k + 1] == '{') {
          k = skipExpr(k + 2);
          continue;
        }
        // $nome: interpolazione semplice, il nome non è testo.
        k++;
        while (k < src.length && RegExp(r'\w').hasMatch(src[k])) {
          k++;
        }
        continue;
      }
      text.write(c);
      k++;
    }
    return k;
  }

  // Salta un'espressione interpolata fino alla graffa di chiusura.
  skipExpr = (int k) {
    var depth = 1;
    while (k < src.length) {
      final c = src[k];
      if (c == "'" || c == '"') {
        k = readString(k, false, StringBuffer());
        continue;
      }
      if (c == '{') depth++;
      if (c == '}') {
        depth--;
        if (depth == 0) return k + 1;
      }
      k++;
    }
    return k;
  };

  while (i < src.length) {
    final c = src[i];
    if (src.startsWith('//', i)) {
      i = src.indexOf('\n', i);
      if (i < 0) break;
      continue;
    }
    if (src.startsWith('/*', i)) {
      i = src.indexOf('*/', i) + 2;
      continue;
    }
    final raw = c == 'r' && i + 1 < src.length && "'\"".contains(src[i + 1]);
    if (c == "'" || c == '"' || raw) {
      final start = raw ? i + 1 : i;
      final b = StringBuffer();
      final end = readString(start, raw, b);
      out.add(Literal(b.toString(), lineAt(i), List.of(calls)));
      i = end;
      continue;
    }
    if (c == '(') {
      var k = i;
      while (k > 0 && src[k - 1] == ' ') {
        k--;
      }
      final e = k;
      while (k > 0 && RegExp(r'\w').hasMatch(src[k - 1])) {
        k--;
      }
      calls.add(src.substring(k, e));
    } else if (c == ')' && calls.isNotEmpty) {
      calls.removeLast();
    }
    i++;
  }
  return out;
}

/// Stringhe che sembrano testo per l'utente: almeno una lettera e uno
/// spazio. Escluse le chiavi di confronto (RegExp, contains, _has, _cond).
const matchingCalls = {'RegExp', 'contains', 'hasMatch', '_has', '_cond'};

List<Literal> visibleStrings(String src) =>
    literalsOf(src)
        .where((l) => RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(l.text))
        .where((l) => l.text.contains(' '))
        .where((l) => !l.calls.any(matchingCalls.contains))
        .toList();

/// File di lib/logic/ che contengono ancora testi per l'utente non migrati
/// nel catalogo. Il test fallisce se un file non elencato ne contiene, o se
/// un file elencato non ne contiene più (va tolto dall'elenco).
const remainingInLogic = {
  // Etichette dei fattori della previsione («taglia piccola», «diabete»…).
  'lib/logic/bio_params.dart',
  // Avviso caldo e freddo MET-001 e MET-002 (richiede la rete: non è nel
  // test d'identità).
  'lib/logic/weather.dart',
};

/// File del modello di previsione, in lavorazione in parallelo (C2-3):
/// possono contenere testi (PRM-001…007 in elimination_model.dart) finché il
/// modello non passa al catalogo. Non toccati da C2-4.
const parallelWork = {
  'lib/logic/elimination_model.dart',
  'lib/logic/potty_predictor.dart',
};

void main() {
  test('ogni voce dell\'ARB ha un ID valido e la chiave corrisponde', () {
    final a = arb();
    for (final k in a.keys.where((k) => !k.startsWith('@'))) {
      expect(a.containsKey('@$k'), isTrue, reason: '$k senza descrizione');
      final desc = (a['@$k'] as Map)['description'] as String;
      final id = desc.split(' ').first;
      expect(idPattern.hasMatch(id), isTrue, reason: '$k: ID «$id»');
      expect(
        ['Title', 'Text', 'Action'].map((p) => '${catalogKey(id)}$p'),
        contains(k),
        reason: 'la chiave $k non corrisponde all\'ID $id',
      );
    }
  });

  test('la tabella generata è aggiornata (dart run tool/gen_clinical_catalog.dart)', () {
    final source = File(gen.sourcePath).readAsStringSync();
    // Confronto senza spazi: il file è passato da dart format.
    String squash(String s) => s
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r',(?=[)\]}])'), '');
    expect(
      squash(File(gen.outputPath).readAsStringSync()),
      squash(gen.generate(source)),
      reason:
          'rigenera con: flutter gen-l10n && '
          'dart run tool/gen_clinical_catalog.dart',
    );
    // Ogni voce dell'ARB è nel codice generato da gen-l10n e viceversa.
    final keys = arb().keys.where((k) => !k.startsWith('@')).toSet();
    expect(catalogParams.keys.toSet(), keys);
  });

  test('ogni ID usato nel codice esiste nell\'ARB e viceversa', () {
    final ids = arbIds();
    final used = <String>{};
    for (final f in dartFiles('lib')) {
      for (final l in literalsOf(f.readAsStringSync())) {
        if (!idPattern.hasMatch(l.text)) continue;
        used.add(l.text);
        expect(
          ids.containsKey(l.text),
          isTrue,
          reason: '${f.path}:${l.line} usa ${l.text}, assente dall\'ARB',
        );
      }
    }
    // Famiglie lette in un ciclo (l'ID è composto a runtime): si controlla
    // che il ciclo copra esattamente le voci del catalogo.
    int count(String prefix) =>
        ids.keys.where((id) => RegExp('^$prefix\\d+\$').hasMatch(id)).length;
    expect(Nutrition.toxicFoods.length, count('TOS-'));
    expect(Nutrition.bcsDescriptions.length, count('SCA-BCS-'));
    expect(Modules.qolItems.length, count('SCA-QOL-'));
    expect(Modules.labPresets.length, count('LAB-'));
    final reasons = RegExp(r'_reason\((\d+)\)')
        .allMatches(File('lib/logic/nutrition.dart').readAsStringSync())
        .map((m) => int.parse(m.group(1)!))
        .toSet();
    expect(reasons.length, count('NUT-FAT-'));
    for (final n in reasons) {
      used.add('NUT-FAT-${n.toString().padLeft(3, '0')}');
    }
    for (final p in ['TOS-', 'SCA-BCS-', 'SCA-QOL-', 'LAB-']) {
      used.addAll(ids.keys.where((id) => id.startsWith(p)));
    }
    final red = EmergencyScreen.redFlags.length;
    for (var i = 1; i <= red; i++) {
      used.add('EMG-${i.toString().padLeft(3, '0')}');
    }
    expect(ids.keys.toSet().difference(used), isEmpty);
  });

  test('gli scenari del test d\'identità fanno scattare ogni avviso', () {
    final seen = <String>{};
    for (final s in alertScenarios()) {
      seen.addAll(
        AlertEngine.compute(
          dog: s.dog,
          logs: s.logs,
          records: s.records,
          weights: s.weights,
          now: s.now,
          repro: s.repro,
          pendingDoses: s.pending,
        ).map((a) => a.id),
      );
    }
    final alerts = arbIds().keys
        .where((id) => id.startsWith('ALR-') && !id.startsWith('ALR-LIV-'))
        .toSet();
    // Non raggiungibile con la logica attuale: la temperatura bassa è letta
    // solo nelle ultime 24 ore, quindi «da oltre 24 ore» non scatta mai.
    // Segnalato nel rapporto C2-4; il testo resta nel catalogo.
    const unreachable = {'ALR-REP-006a'};
    expect(alerts.difference(seen).difference(unreachable), isEmpty);
    expect(seen.intersection(unreachable), isEmpty);
  });

  test('nessuna stringa visibile in lib/logic/ fuori dal catalogo', () {
    final dirty = <String, List<String>>{};
    for (final f in dartFiles('lib/logic')) {
      final v = visibleStrings(f.readAsStringSync());
      if (v.isNotEmpty) {
        dirty[f.path] = [for (final l in v) '${l.line}: ${l.text}'];
      }
    }
    final unexpected = dirty.keys
        .toSet()
        .difference(remainingInLogic)
        .difference(parallelWork);
    expect(
      unexpected,
      isEmpty,
      reason: unexpected.map((p) => '$p\n  ${dirty[p]!.join('\n  ')}').join(),
    );
    expect(
      remainingInLogic.difference(dirty.keys.toSet()),
      isEmpty,
      reason: 'file ormai migrati: toglierli da remainingInLogic',
    );
  });

  test('il controllo delle stringhe riconosce testi e chiavi', () {
    final v = visibleStrings(r'''
      // 'commento con spazi'
      final a = 'Testo per ${dog.name} da tradurre';
      final b = RegExp('pastore tedesco|collie');
      final c = t.contains('filariosi: chiedi');
      final d = 'ALR-URI-001';
      final e = _has(b, ['san bernardo']);
    ''');
    expect(v.map((l) => l.text), ['Testo per  da tradurre']);
  });
}
