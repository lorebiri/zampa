import 'package:flutter_test/flutter_test.dart';

import 'banco.dart';
import 'v2_lavori.dart';

void main() {
  test('unisci', () {
    final l = leggiLavori();
    // ignore: avoid_print
    print(mergeShards(l.tag, l.jobs, l.of));
  }, timeout: Timeout.none);
}
