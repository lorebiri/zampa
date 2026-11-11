import 'package:flutter_test/flutter_test.dart';
import 'banco.dart';

void main() {
  test('cambio_routine', () => runScenario('cambio_routine', every: 3), timeout: Timeout.none);
}
