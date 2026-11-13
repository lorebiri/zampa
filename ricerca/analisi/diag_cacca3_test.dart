// ignore_for_file: avoid_print
import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/poop_forecast.dart';
import 'package:zampa/logic/potty_predictor.dart';
import 'package:zampa/models.dart';

import 'banco.dart';

void main() {
  test('diag', () {
    final bench = buildBench(scenarios['realistico']!);
    for (final id in ['c01', 'c02']) {
      final tr = bench.firstWhere((t) => t.spec.id == id);
      final outs = PottyPredictor.outings(tr.logged, type: LogType.cacca, clusterMinutes: 30).map((o) => o.time).toList();
      print('$id ${tr.spec.group} sched=${tr.spec.scheduled}');
      String hm(DateTime t) => '${t.day}/${t.hour}:${t.minute.toString().padLeft(2, '0')}';
      for (var i = 20; i < 28 && i < outs.length; i++) {
        final o = outs[i - 1].add(const Duration(minutes: 1));
        final vis = tr.logged.where((l) => !l.time.isAfter(o)).toList();
        final a = anchorForecast(tr.dog, vis, o);
        print('  prev ${hm(outs[i - 1])} actual ${hm(outs[i])} M ${hm(a.at)} '
            '${a.anchors.take(6).map((x) => '${x.kind.name[0]}${hm(x.predicted)}:${x.prob.toStringAsFixed(2)}').join(' ')}');
      }
    }
  });
}
