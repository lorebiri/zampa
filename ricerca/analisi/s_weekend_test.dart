import 'package:flutter_test/flutter_test.dart';
import 'banco.dart';

void main() {
  test('weekend', () => runScenario('weekend', every: 3), timeout: Timeout.none);
}
