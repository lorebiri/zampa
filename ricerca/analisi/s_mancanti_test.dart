import 'package:flutter_test/flutter_test.dart';
import 'banco.dart';

void main() {
  test('mancanti', () => runScenario('mancanti', every: 3), timeout: Timeout.none);
}
