// Strada 5 (ricerca/27): partenza a freddo, giorni 1-7 del banco
// realistico, previsione di base contro v2.1 (un evento su tre).
import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';

import 'banco.dart';

void main() {
  test('partenza a freddo', () {
    final bench = buildBench(scenarios['realistico']!);
    final b = <Rec2>[], v = <Rec2>[];
    for (final t in bench) {
      final r = evaluatePair(t, Need.pipi, shadow: false, fromDay: 1, every: 3);
      b.addAll(r.base);
      v.addAll(r.v2);
    }
    final out = StringBuffer();
    for (final (lo, hi) in [(1, 4), (4, 7), (7, 28)]) {
      bool f(Rec2 e) => e.d('day') >= lo && e.d('day') < hi;
      out
        ..writeln(render('freddo BASE giorni $lo-$hi', summarize2(b.where(f).toList())))
        ..writeln(render('freddo V2 giorni $lo-$hi', summarize2(v.where(f).toList(), shadow: true)));
    }
    saveText('v21_freddo', out.toString());
  }, timeout: Timeout.none);
}
