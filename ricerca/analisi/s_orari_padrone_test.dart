import 'package:flutter_test/flutter_test.dart';
import 'banco.dart';

void main() {
  test('orari_padrone', () => runScenario('orari_padrone', every: 3), timeout: Timeout.none);
}
