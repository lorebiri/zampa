import 'package:flutter_test/flutter_test.dart';
import 'banco.dart';

void main() {
  test('poliuria', () => runScenario('poliuria', every: 3), timeout: Timeout.none);
}
