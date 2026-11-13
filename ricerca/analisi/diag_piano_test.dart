// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';

import 'banco.dart';

void main() {
  test('tempi', () {
    final specs = population(0);
    for (final arm in [const PlanArm('piano4', 'piano')]) {
      final sw = Stopwatch()..start();
      final r = simulatePlan(specs[8], 8, arm);
      print('${arm.name}: ${sw.elapsedMilliseconds} ms decide $planDecideCalls ${planDecideMs}ms acc ${r.acc} out ${r.outings} days ${r.days}');
    }
  }, timeout: Timeout.none);
}
