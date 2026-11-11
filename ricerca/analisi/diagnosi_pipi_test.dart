import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';
import 'package:zampa/logic/potty_predictor.dart';
import 'banco.dart';

/// Diagnosi del ritardo sistematico sulla pipì (scenario pulito): intervallo
/// appreso dal modello contro intervallo osservato del cane.
void main() {
  test('diagnosi pipì', () {
    final bench = buildBench(scenarios['pulito']!);
    final b = StringBuffer('## Diagnosi pipì (scenario pulito, giorno 20)\n');
    for (final i in [7, 10, 14, 18, 22, 24]) {
      final tr = bench[i];
      final now = simStart.add(const Duration(days: 20, hours: 12, minutes: 1));
      final vis = tr.logged.where((l) => !l.time.isAfter(now)).toList();
      final outs = PottyPredictor.outings(vis).map((o) => o.time).toList();
      final gaps = <double>[];
      for (var k = 1; k < outs.length; k++) {
        if (PottyPredictor.inSleepWindow(tr.dog, outs[k]) ||
            PottyPredictor.inSleepWindow(tr.dog, outs[k - 1])) {
          continue;
        }
        final g = outs[k].difference(outs[k - 1]).inMinutes.toDouble();
        if (g < 600) gaps.add(g);
      }
      gaps.sort();
      final fm = EliminationModel().fit(tr.dog, Need.pipi, vis, const [], now);
      final lit = BioParams.pee(tr.dog, now).median;
      b.writeln(
        '- ${tr.spec.id} ${tr.spec.group} ${tr.spec.weightKg} kg: '
        'mediana osservata da sveglio ${gaps[gaps.length ~/ 2]} min '
        '(n=${gaps.length}), letteratura $lit, Bayes empirico '
        '${fm.prior.median.round()}, intervallo tipico del modello '
        '${fm.typicalInterval(now).round()} min',
      );
    }
    saveText('diagnosi_pipi', b.toString());
    // ignore: avoid_print
    print(b);
  }, timeout: Timeout.none);
}
