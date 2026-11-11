// Supporto dei test lenti del banco di prova (tag `banco`, ricerca/12 §7 e
// ricerca/23). Usa il generatore e le metriche di ricerca/analisi.
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/logic/elimination_model.dart';

import '../../ricerca/analisi/banco.dart';

export '../../ricerca/analisi/banco.dart';

/// I test del banco girano solo con `--dart-define=BANCO=true`.
const String? lento = bool.fromEnvironment('BANCO')
    ? null
    : 'Banco di prova lento: flutter test --dart-define=BANCO=true test/banco';

/// Esito di uno scenario: record della previsione di base, del modello in
/// ombra e, se richiesta, della griglia delle probabilità.
class Esito {
  Esito(this.base, this.ombra, this.grid, this.history);
  final List<Rec2> base, ombra;
  final List<GridRec> grid;

  /// Per ogni cane: (previsioni registrate R6, uscite registrate, fine).
  final Map<String, (List<ShadowRecord>, Truth)> history;
}

final _cache = <String, Esito>{};

/// Valuta lo scenario [scenario] (tutti i 32 cani) una sola volta per file.
Esito esegui(
  String scenario, {
  Need need = Need.pipi,
  int every = 3,
  bool shadow = true,
  bool grid = false,
}) {
  final key = '$scenario/${need.name}/$every/$shadow/$grid';
  return _cache.putIfAbsent(key, () {
    final bench = buildBench(scenarios[scenario]!);
    final base = <Rec2>[], ombra = <Rec2>[];
    final g = <GridRec>[];
    final hist = <String, (List<ShadowRecord>, Truth)>{};
    for (final t in bench) {
      final r = evaluatePair(
        t,
        need,
        every: every,
        shadow: shadow,
        gridStepH: grid ? 4 : 0,
      );
      base.addAll(r.base);
      ombra.addAll(r.ombra);
      g.addAll(r.grid);
      hist[t.spec.id] = (r.history, t);
    }
    return Esito(base, ombra, g, hist);
  });
}

double mediana(List<Rec2> r, String k) {
  final x = [for (final e in r) e.d(k)]..sort();
  final n = x.length;
  return n.isOdd ? x[n ~/ 2] : (x[n ~/ 2 - 1] + x[n ~/ 2]) / 2;
}

double quota(List<Rec2> r, bool Function(Rec2) f) =>
    r.where(f).length / r.length;
