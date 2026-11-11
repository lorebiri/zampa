// Riassunti testuali dei grafici per i lettori di schermo (ricerca/22 §8,
// C2-9): chi non vede le barre o la curva sente lo stesso contenuto in una
// frase. Solo descrizione dei dati mostrati: nessuna interpretazione clinica.
import 'dart:math' as math;

import '../store.dart' show dmy;

/// Numero all'italiana con al più un decimale: 14,2 · 4 · 3,5.
String numIt(double v) {
  final r = (v * 10).round() / 10;
  if (r == r.roundToDouble()) return r.round().toString();
  return r.toStringAsFixed(1).replaceAll('.', ',');
}

/// Barre per giorno: «Ultimi 14 giorni: da 3 a 5 pipì al giorno, media 4;
/// oggi 2.» I giorni senza registrazioni contano come zero, come nel grafico.
String dayBarsSummary(
  Map<DateTime, int> perDay,
  DateTime now, {
  required String what,
  int days = 14,
}) {
  final values = [
    for (var i = days - 1; i >= 0; i--)
      perDay[DateTime(now.year, now.month, now.day - i)] ?? 0,
  ];
  final total = values.fold(0, (a, b) => a + b);
  if (total == 0) return 'Ultimi $days giorni: nessuna registrazione.';
  final lo = values.reduce(math.min), hi = values.reduce(math.max);
  final range = lo == hi
      ? '$lo $what al giorno'
      : 'da $lo a $hi $what al giorno';
  return 'Ultimi $days giorni: $range, media ${numIt(total / days)}; '
      'oggi ${values.last}.';
}

/// Serie nel tempo (peso, glicemie, esami, punteggi): «Andamento del peso:
/// 5 valori dal 14/06/2026 al 11/11/2026, da 13,4 a 14,2 kg; ultimo 14,2 kg.»
String seriesSummary(
  String name,
  List<double> values, {
  List<DateTime>? dates,
  String unit = '',
  String? extra,
}) {
  if (values.isEmpty) return '$name: nessun valore.';
  final u = unit.isEmpty ? '' : ' $unit';
  final lo = values.reduce(math.min), hi = values.reduce(math.max);
  final count = values.length == 1 ? '1 valore' : '${values.length} valori';
  final when = dates == null || dates.isEmpty
      ? ''
      : ' dal ${dmy(dates.first)} al ${dmy(dates.last)}';
  final range = lo == hi
      ? 'sempre ${numIt(lo)}$u'
      : 'da ${numIt(lo)} a ${numIt(hi)}$u';
  return '$name: $count$when, $range; ultimo ${numIt(values.last)}$u.'
      '${extra == null ? '' : ' $extra'}';
}
