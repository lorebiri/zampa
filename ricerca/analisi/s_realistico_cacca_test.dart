import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'banco.dart';

void main() {
  test(
    'realistico cacca',
    () => runScenario('realistico', need: Need.cacca),
    timeout: Timeout.none,
  );
  test(
    'pulito cacca',
    () => runScenario('pulito', need: Need.cacca, every: 2),
    timeout: Timeout.none,
  );
}
