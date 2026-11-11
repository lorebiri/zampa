import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

/// Numerosità dello studio: dai risultati per cane del banco realistico
/// (risultati/realistico_pipi.json) estrae n cani con reinserimento,
/// gonfiando la variabilità tra cani di un fattore k (i cani veri saranno
/// più diversi tra loro di quelli simulati) attorno a un effetto "vero"
/// ipotizzato (R e copertura del modello corretto: il modello attuale sul
/// banco NON supera la soglia), e stima la probabilità che la
/// regola di decisione preregistrata dia "superato":
///   L2a: R = Σ mediana errore modello / Σ mediana errore timer ≤ 0,80 e
///        limite superiore IC 95% di R < 1,00;
///   L2b: copertura dell'intervallo 80% ≥ 70% e limite inferiore IC 95%
///        ≥ 65%.
/// Gli IC usano il metodo delta su somme per cane (rapido, equivalente al
/// bootstrap per cane per n ≥ 20).
void main() {
  test('potenza', () {
    final raw =
        jsonDecode(
              File('ricerca/analisi/risultati/realistico_pipi.json')
                  .readAsStringSync(),
            )
            as List;
    final byDog = <String, List<Map<String, dynamic>>>{};
    for (final e in raw.cast<Map<String, dynamic>>()) {
      byDog.putIfAbsent(e['dog'] as String, () => []).add(e);
    }
    double med(List<double> x) {
      final s = [...x]..sort();
      return s[s.length ~/ 2];
    }

    // Per cane: (mediana modello, mediana timer, n eventi, n in 80%).
    final dogs = [
      for (final l in byDog.values)
        (
          med([for (final e in l) (e['errModel'] as num).toDouble()]),
          med([for (final e in l) (e['errTimer'] as num).toDouble()]),
          l.length.toDouble(),
          l.where((e) => e['in80'] as bool).length.toDouble(),
        ),
    ];
    final meanRatio =
        dogs.map((d) => d.$1).reduce((a, b) => a + b) /
        dogs.map((d) => d.$2).reduce((a, b) => a + b);
    final b = StringBuffer('## Potenza della regola di decisione\n');
    b.writeln(
      '- banco: ${dogs.length} cani, R = ${meanRatio.toStringAsFixed(2)}',
    );
    final r = math.Random(5);
    for (final k in [1.0, 1.5, 2.0]) {
      for (final (target, covT) in [(0.65, 0.78), (0.70, 0.76), (0.75, 0.74), (0.85, 0.72), (0.70, 0.67)]) {
        for (final n in [20, 30, 45, 60, 90]) {
          var passA = 0, passB = 0, passBoth = 0;
          const reps = 4000;
          for (var rep = 0; rep < reps; rep++) {
            final m = <double>[], t = <double>[], ne = <double>[], ni = <double>[];
            for (var i = 0; i < n; i++) {
              final d = dogs[r.nextInt(dogs.length)];
              // Variabilità tra cani gonfiata di k attorno al rapporto medio,
              // centrata sul rapporto "vero" ipotizzato.
              final ratio = d.$1 / d.$2;
              final rr = (target + (ratio - meanRatio) * k).clamp(
                0.05,
                5.0,
              );
              t.add(d.$2);
              m.add(rr * d.$2);
              ne.add(d.$3);
              final cov = d.$4 / d.$3;
              final cov0 = 0.0 + dogs.map((x) => x.$4).reduce((a, c) => a + c) /
                  dogs.map((x) => x.$3).reduce((a, c) => a + c);
              final cv = (covT + (cov - cov0) * k).clamp(0.0, 1.0);
              ni.add(cv * d.$3);
            }
            double sum(List<double> x) => x.reduce((a, c) => a + c);
            final rHat = sum(m) / sum(t);
            final mt = sum(t) / n;
            var v = 0.0;
            for (var i = 0; i < n; i++) {
              final z = m[i] - rHat * t[i];
              v += z * z;
            }
            final seR = math.sqrt(v / (n - 1) / n) / mt;
            final okA = rHat <= 0.80 && rHat + 1.96 * seR < 1.0;
            final cHat = sum(ni) / sum(ne);
            final me = sum(ne) / n;
            var vc = 0.0;
            for (var i = 0; i < n; i++) {
              final z = ni[i] - cHat * ne[i];
              vc += z * z;
            }
            final seC = math.sqrt(vc / (n - 1) / n) / me;
            final okB = cHat >= 0.70 && cHat - 1.96 * seC >= 0.65;
            if (okA) passA++;
            if (okB) passB++;
            if (okA && okB) passBoth++;
          }
          b.writeln(
            '- variabilità ×$k, R vero $target, copertura vera $covT, '
            'n=$n cani: P(L2a) ${(passA / reps * 100).round()}%, '
            'P(L2b) ${(passB / reps * 100).round()}%, '
            'P(entrambi) ${(passBoth / reps * 100).round()}%',
          );
        }
      }
    }
    File('ricerca/analisi/risultati/potenza.txt').writeAsStringSync('$b');
    // ignore: avoid_print
    print(b);
  }, timeout: Timeout.none);
}
