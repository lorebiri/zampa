import 'package:flutter_test/flutter_test.dart';
import 'banco.dart';

void main() {
  test('jitter', () => runScenario('jitter', every: 3), timeout: Timeout.none);
}
