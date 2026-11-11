// Diagnosi: casi in cui l'uscita consigliata supera il tetto da sveglio.
import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';
import 'package:zampa/logic/potty_predictor.dart';

import 'banco.dart';

void main() {
  test('diagnosi tetto', () {
    const sc = String.fromEnvironment('SC', defaultValue: 'orari_padrone');
    final bench = buildBench(scenarios[sc]!);
    var shown = 0;
    for (final tr in bench) {
      final outs = PottyPredictor.outings(tr.logged)
          .map((o) => o.time)
          .toList();
      for (var i = 1; i < outs.length && shown < 12; i++) {
        final origin = outs[i - 1].add(const Duration(minutes: 1));
        if (origin.isBefore(simStart.add(const Duration(days: 7)))) continue;
        final vis = tr.logged.where((l) => !l.time.isAfter(origin)).toList();
        final prior = BioParams.forNeed(Need.pipi, tr.dog, origin);
        final f = EliminationModel()
            .fit(tr.dog, Need.pipi, vis, const [], origin, shadow: false)
            .forecast(origin, withAccuracy: false);
        final cap = f.last!.add(Duration(minutes: prior.maxDay.round() + 1));
        if (PottyPredictor.inSleepWindow(tr.dog, cap)) continue;
        final limit = cap.isAfter(origin) ? cap : origin;
        if (!f.recommendedAt.isAfter(limit)) continue;
        shown++;
        // ignore: avoid_print
        print(
          '${tr.spec.id} ${tr.spec.group} sonno ${tr.dog.sleepStartHour}-'
          '${tr.dog.wakeHour} ultima ${f.last} tetto $cap consigliato '
          '${f.recommendedAt} limite ${f.latestAt}: ${f.reason}',
        );
      }
    }
  });
}
