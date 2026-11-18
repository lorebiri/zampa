// Banco v2 (ricerca/23). I lavori da eseguire si leggono da
// ricerca/analisi/risultati/lavori.json:
//   {"tag": "base0", "shadow": false, "of": 4,
//    "jobs": [{"scenario": "realistico", "need": "pipi", "every": 1,
//              "grid": false}, ...]}
// Esecuzione: flutter test -j 4 ricerca/analisi/v2_shard{0,1,2,3}_test.dart
// poi flutter test ricerca/analisi/v2_unisci_test.dart.
import 'dart:convert';
import 'dart:io';

import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/pee_forecast_v2.dart';

import 'banco.dart';

({String tag, bool shadow, int of, List<Job> jobs}) leggiLavori() {
  final m = jsonDecode(
    File('ricerca/analisi/risultati/lavori.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  return (
    tag: m['tag'] as String,
    shadow: m['shadow'] as bool? ?? true,
    of: m['of'] as int? ?? 4,
    jobs: [
      for (final j in (m['jobs'] as List).cast<Map<String, dynamic>>())
        Job(
          j['scenario'] as String,
          need: j['need'] == 'cacca' ? Need.cacca : Need.pipi,
          every: j['every'] as int? ?? 1,
          grid: j['grid'] as bool? ?? false,
        ),
    ],
  );
}

void eseguiFrammento(int shard) {
  final l = leggiLavori();
  final m = jsonDecode(
    File('ricerca/analisi/risultati/lavori.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  v2SafetyCapForBench = m['v2Safety'] as bool? ?? true;
  if (shard >= l.of) return;
  runShard(l.tag, l.jobs, shard, l.of, shadow: l.shadow);
}
