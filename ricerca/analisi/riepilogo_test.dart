import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'banco.dart';

/// Da eseguire dopo gli scenari: unisce i riferimenti corretti.
void main() {
  test('riepilogo', () {
    final b = StringBuffer();
    b.write(mergeBaselines('realistico_pipi', 'realistico', Need.pipi));
    b.write(mergeBaselines('realistico_cacca', 'realistico', Need.cacca));
    b.write(mergeBaselines('pulito_cacca', 'pulito', Need.cacca, every: 2));
    b.write(mergeBaselines('origine_ottimista_pipi', 'realistico', Need.pipi,
        leaky: true, every: 4));
    b.write(mergeBaselines('origine_ottimista_cacca', 'realistico', Need.cacca,
        leaky: true, every: 2));
    for (final s in ['pulito', 'mancanti', 'jitter', 'orari_padrone',
        'weekend', 'cambio_routine', 'poliuria']) {
      b.write(mergeBaselines('${s}_pipi', s, Need.pipi, every: 3));
    }
    // ignore: avoid_print
    print(b);
  }, timeout: Timeout.none);
}
