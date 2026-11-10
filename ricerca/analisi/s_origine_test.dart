import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'banco.dart';

/// Origine "ultimo evento di qualsiasi tipo" (come nel test di validazione
/// attuale): quanto ottimismo introduce sul banco realistico?
void main() {
  test(
    'origine ottimista pipì',
    () => runScenario('realistico', leaky: true, every: 4, tag: 'origine_ottimista_pipi'),
    timeout: Timeout.none,
  );
  test(
    'origine ottimista cacca',
    () => runScenario('realistico', need: Need.cacca, leaky: true, every: 2, tag: 'origine_ottimista_cacca'),
    timeout: Timeout.none,
  );
}
