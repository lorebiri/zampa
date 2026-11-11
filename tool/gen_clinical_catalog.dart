// Genera lib/l10n/clinical_catalog.g.dart: la tabella che, dato il nome di
// una voce del catalogo e i suoi parametri, chiama il metodo generato da
// gen-l10n. Così la logica può chiedere un testo per ID (ClinicalText) senza
// un BuildContext.
//
// Uso, dopo ogni modifica di lib/l10n/app_it.arb:
//   flutter gen-l10n && dart run tool/gen_clinical_catalog.dart
// Il test test/l10n_catalog_test.dart fallisce se il file non è aggiornato.
import 'dart:io';

const sourcePath = 'lib/l10n/app_localizations.dart';
const outputPath = 'lib/l10n/clinical_catalog.g.dart';

/// Voci dichiarate in app_localizations.dart, con i parametri nell'ordine
/// del metodo generato.
List<({String key, List<({String type, String name})> params})> entriesOf(
  String source,
) {
  final out = <({String key, List<({String type, String name})> params})>[];
  final decl = RegExp(
    r'^  String (?:get (\w+);|(\w+)\(([^)]*)\);)',
    multiLine: true,
  );
  for (final m in decl.allMatches(source)) {
    if (m.group(1) != null) {
      out.add((key: m.group(1)!, params: const []));
      continue;
    }
    final params = <({String type, String name})>[];
    for (final p in m.group(3)!.split(',')) {
      final parts = p.trim().split(RegExp(r'\s+'));
      if (parts.length != 2) continue;
      params.add((type: parts[0], name: parts[1]));
    }
    out.add((key: m.group(2)!, params: params));
  }
  return out;
}

String generate(String source) {
  final b = StringBuffer()
    ..writeln('// GENERATO da tool/gen_clinical_catalog.dart: non modificare.')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln()
    ..writeln("import 'app_localizations.dart';")
    ..writeln()
    ..writeln(
      '/// Parametri di ogni voce del catalogo, nell\'ordine del metodo.',
    )
    ..writeln('const catalogParams = <String, List<String>>{');
  final entries = entriesOf(source);
  for (final e in entries) {
    b.writeln(
      "  '${e.key}': [${e.params.map((p) => "'${p.name}'").join(', ')}],",
    );
  }
  b
    ..writeln('};')
    ..writeln()
    ..writeln('/// Testo della voce [key] con i parametri [p].')
    ..writeln(
      'String catalogLookup(AppLocalizations l, String key, '
      'Map<String, Object> p) => switch (key) {',
    );
  for (final e in entries) {
    if (e.params.isEmpty) {
      b.writeln("  '${e.key}' => l.${e.key},");
    } else {
      final args = e.params
          .map((x) => "p['${x.name}']! as ${x.type}")
          .join(', ');
      b.writeln("  '${e.key}' => l.${e.key}($args),");
    }
  }
  b
    ..writeln(
      "  _ => throw ArgumentError.value(key, 'key', 'voce assente dal catalogo'),",
    )
    ..writeln('};');
  return b.toString();
}

void main() {
  final out = generate(File(sourcePath).readAsStringSync());
  File(outputPath).writeAsStringSync(out);
  Process.runSync('dart', ['format', outputPath]);
  stdout.writeln('Scritto $outputPath');
}
