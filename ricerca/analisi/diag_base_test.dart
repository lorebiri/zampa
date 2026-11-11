// Diagnosi della previsione di base su singoli eventi (ricerca/23).
import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';
import 'package:zampa/logic/potty_predictor.dart';

import 'banco.dart';

void main() {
  test('diagnosi base', () {
    const sc = String.fromEnvironment('SC', defaultValue: 'orari_padrone');
    const dogs = String.fromEnvironment('DOGS', defaultValue: 'c01,c09');
    final bench = buildBench(scenarios[sc]!);
    for (final tr in bench.where((t) => dogs.split(',').contains(t.spec.id))) {
      final outs = PottyPredictor.outings(tr.logged)
          .map((o) => o.time)
          .toList();
      // ignore: avoid_print
      print(
        '${tr.spec.id} ${tr.spec.group} wake ${tr.dog.wakeHour} '
        'bed ${tr.dog.sleepStartHour}',
      );
      for (var i = 1; i < outs.length; i++) {
        final a = outs[i];
        if (a.isBefore(simStart.add(const Duration(days: 20)))) continue;
        if (a.isAfter(simStart.add(const Duration(days: 23)))) break;
        final origin = outs[i - 1].add(const Duration(minutes: 1));
        final vis = tr.logged.where((l) => !l.time.isAfter(origin)).toList();
        final f = EliminationModel()
            .fit(tr.dog, Need.pipi, vis, const [], origin, shadow: false)
            .forecast(origin, withAccuracy: false);
        String hm(DateTime t) =>
            '${t.day} ${t.hour}:${t.minute.toString().padLeft(2, '0')}';
        // ignore: avoid_print
        print(
          'prev ${hm(outs[i - 1])} vero ${hm(a)} atteso ${hm(f.expectedAt)} '
          'cons ${hm(f.recommendedAt)} fin ${hm(f.windowStart)}-'
          '${hm(f.windowEnd)} int ${f.typicalIntervalMin.round()} '
          '${f.reason}',
        );
      }
    }
  });
}
