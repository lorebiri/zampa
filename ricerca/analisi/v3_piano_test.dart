// ignore_for_file: avoid_print
// Banco del piano di uscite (ricerca/28 §3). Parametri da ambiente:
// PIANO_ARMS=fisso3,fisso4,piano3,piano4,v2,... PIANO_EVERY=3 PIANO_SEED=0
// PIANO_TAG=nome  flutter test ricerca/analisi/v3_piano_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'banco.dart';

PlanArm armOf(String s) {
  final sig = s.endsWith('+s');
  final b = sig ? s.substring(0, s.length - 2) : s;
  if (b == 'v2') return PlanArm(s, 'v2', signals: sig);
  final kind = b.startsWith('fisso') ? 'fisso' : 'piano';
  return PlanArm(s, kind, n: int.parse(b.substring(kind.length)), signals: sig);
}

void main() {
  test('piano di uscite', () {
    final env = Platform.environment;
    final arms = (env['PIANO_ARMS'] ?? 'fisso3,fisso4,piano3,piano4')
        .split(',')
        .map(armOf)
        .toList();
    final txt = runPlanBench(
      arms,
      every: int.parse(env['PIANO_EVERY'] ?? '3'),
      seed: int.parse(env['PIANO_SEED'] ?? '0'),
    );
    print(txt);
    final tag = env['PIANO_TAG'];
    if (tag != null) saveText('v3piano_$tag', txt);
  }, timeout: Timeout.none);
}
