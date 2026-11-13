// ignore_for_file: avoid_print
// Banco della cacca v3 (ricerca/28 §2). Parametri da ambiente:
// CACCA_SC=realistico CACCA_EVERY=3 CACCA_FULL=1 CACCA_BASE=1
//   flutter test ricerca/analisi/v3_cacca_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:zampa/logic/poop_forecast.dart';

import 'banco.dart';

void main() {
  test('cacca v3', () {
    final env = Platform.environment;
    final scs = (env['CACCA_SC'] ?? 'realistico').split(',');
    final every = int.parse(env['CACCA_EVERY'] ?? '3');
    final b = StringBuffer();
    for (final sc in scs) {
      b.writeln(runPoopBench(sc,
          every: every,
          full: env['CACCA_FULL'] == '1',
          base: env['CACCA_BASE'] == '1',
          p: PoopModelParams(
            readyFrac: double.parse(env['CACCA_READY'] ?? '0.65'),
            pseudo: double.parse(env['CACCA_PSEUDO'] ?? '3'),
          )));
    }
    print(b);
    final tag = env['CACCA_TAG'];
    if (tag != null) saveText('v3cacca_$tag', b.toString());
  }, timeout: Timeout.none);
}
