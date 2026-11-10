import 'package:flutter_test/flutter_test.dart';
import 'banco.dart';

void main() {
  test(
    'realistico griglia pipì',
    () => runScenario('realistico', grid: true),
    timeout: Timeout.none,
  );
}
