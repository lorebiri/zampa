import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'banco.dart';

void main() {
  test(
    'realistico griglia cacca',
    () => runScenario('realistico', need: Need.cacca, grid: true),
    timeout: Timeout.none,
  );
}
