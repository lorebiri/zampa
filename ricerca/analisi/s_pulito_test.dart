import 'package:flutter_test/flutter_test.dart';
import 'banco.dart';

void main() {
  test('pulito', () => runScenario('pulito', every: 3), timeout: Timeout.none);
}
