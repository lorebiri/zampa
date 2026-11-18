// Banco a candidati (ricerca/27). Scenari da ricerca/analisi/risultati/lavori3.json:
//   {"scenari": ["realistico", ...], "of": 4, "grid": true, "triggers": true}
// Esecuzione: flutter test -j 4 ricerca/analisi/v3_shard*_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'banco.dart';

void main() {
  test('frammento 2', () {
    final m = jsonDecode(
      File('ricerca/analisi/risultati/lavori3.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final of = m['of'] as int? ?? 4;
    if (2 >= of) return;
    for (final s in (m['scenari'] as List).cast<String>()) {
      runDumpShard(
        s,
        2,
        of,
        grid: m['grid'] as bool? ?? true,
        triggers: m['triggers'] as bool? ?? true,
        shadow: m['shadow'] as bool? ?? true,
      );
    }
  }, timeout: Timeout.none);
}
