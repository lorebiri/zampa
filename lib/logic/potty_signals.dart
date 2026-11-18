import '../models.dart';

/// SEGNALI DEL CANE (ricerca/28 §1)
///
/// Il padrone segna con un tocco un segnale che anticipa pipì o cacca:
/// annusa a terra, gira su sé stesso, va alla porta, guaisce, è irrequieto.
/// Un segnale recente (dopo l'ultima pipì) alza subito la probabilità e fa
/// scattare «Esci adesso». La probabilità che segua una pipì o una cacca
/// entro 30 minuti è imparata sul cane stesso (segnali passati seguiti da
/// un bisogno registrato), partendo da valori tipici dichiarati come
/// ipotesi [IPOTESI, da misurare nella beta]: «va alla porta» e «guaisce»
/// 0,8; «annusa a terra» e «gira su sé stesso» 0,6; «è irrequieto» 0,4.

/// I segnali, nell'ordine dei bottoni.
const signalKinds = [
  Sign.annusaTerra,
  Sign.giraSuSe,
  Sign.allaPorta,
  Sign.guaisce,
  Sign.irrequieto,
];

/// Valore tipico della probabilità di un bisogno entro 30 minuti [IPOTESI].
double signalPrior(Sign s) => switch (s) {
  Sign.allaPorta || Sign.guaisce => 0.8,
  Sign.annusaTerra || Sign.giraSuSe => 0.6,
  _ => 0.4,
};

/// Emoji dei bottoni.
String signalEmoji(Sign s) => switch (s) {
  Sign.annusaTerra => '👃',
  Sign.giraSuSe => '🔄',
  Sign.allaPorta => '🚪',
  Sign.guaisce => '🗣️',
  _ => '🐕',
};

Sign signalOf(LogEntry l) =>
    l.signs.firstWhere(signalKinds.contains, orElse: () => Sign.irrequieto);

class SignalAlert {
  const SignalAlert({
    required this.at,
    required this.kind,
    required this.prob30,
    required this.goNow,
    required this.learnedOn,
  });

  /// Orario e tipo dell'ultimo segnale dopo l'ultima pipì.
  final DateTime at;
  final Sign kind;

  /// Probabilità di una pipì o cacca entro 30 minuti dal segnale.
  final double prob30;

  /// True se il segnale è di meno di [goNowMinutes] minuti fa: «Esci adesso».
  final bool goNow;

  /// Segnali passati del cane con esito noto su cui è imparata.
  final int learnedOn;
}

const goNowMinutes = 20;

/// Probabilità imparata per il tipo [kind]: (bisogni entro 30 minuti dopo i
/// segnali passati + 4 × valore tipico) / (segnali passati + 4). Si contano
/// solo i segnali con esito noto (almeno 30 minuti prima di [now]).
({double p, int n}) learnedSignalProb(
  List<LogEntry> logs,
  DateTime now,
  Sign kind, {
  int days = 28,
}) {
  final needs = [
    for (final l in logs)
      if ((l.type == LogType.pipi || l.type == LogType.cacca) &&
          !l.time.isAfter(now))
        l.time,
  ]..sort();
  var hits = 0, n = 0;
  final from = now.subtract(Duration(days: days));
  DateTime? prevSig;
  for (final l in logs) {
    if (l.type != LogType.segnale) continue;
    if (l.time.isBefore(from)) continue;
    if (l.time.isAfter(now.subtract(const Duration(minutes: 30)))) continue;
    // Più tocchi ravvicinati sono lo stesso episodio.
    if (prevSig != null && l.time.difference(prevSig).inMinutes < 10) continue;
    prevSig = l.time;
    if (signalOf(l) != kind) continue;
    n++;
    final until = l.time.add(const Duration(minutes: 30));
    if (needs.any((t) => !t.isBefore(l.time) && !t.isAfter(until))) hits++;
  }
  const pseudo = 4.0;
  return (p: (hits + pseudo * signalPrior(kind)) / (n + pseudo), n: n);
}

/// Ultimo segnale dopo l'ultima pipì (o cacca), se di meno di un'ora fa.
SignalAlert? signalAlert(List<LogEntry> logs, DateTime now) {
  DateTime? lastNeed;
  LogEntry? sig;
  for (final l in logs) {
    if (l.time.isAfter(now)) continue;
    if (l.type == LogType.pipi || l.type == LogType.cacca) {
      if (lastNeed == null || l.time.isAfter(lastNeed)) lastNeed = l.time;
    } else if (l.type == LogType.segnale) {
      if (sig == null || l.time.isAfter(sig.time)) sig = l;
    }
  }
  if (sig == null) return null;
  if (lastNeed != null && !sig.time.isAfter(lastNeed)) return null;
  final age = now.difference(sig.time).inMinutes;
  if (age > 60) return null;
  final kind = signalOf(sig);
  final lp = learnedSignalProb(logs, now, kind);
  return SignalAlert(
    at: sig.time,
    kind: kind,
    prob30: lp.p,
    goNow: age <= goNowMinutes,
    learnedOn: lp.n,
  );
}

/// Probabilità nella prossima ora corretta con un segnale recente: il
/// segnale non può abbassarla, solo alzarla.
double probWithSignal(double base, SignalAlert? a) {
  if (a == null || !a.goNow) return base;
  final s = a.prob30.clamp(0.0, 0.95);
  return 1 - (1 - base) * (1 - s);
}
