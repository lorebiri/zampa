import '../models.dart';
import 'bio_params.dart';

/// Funzioni di supporto condivise dal modello di eliminazione e dagli
/// allarmi. La previsione vera e propria è in elimination_model.dart.

enum LifeStage { cucciolo, giovane, adulto, anziano }

LifeStage lifeStageOf(Dog dog, [DateTime? now]) {
  final m = dog.ageInMonths(now);
  if (m < 6) return LifeStage.cucciolo;
  if (m < 12) return LifeStage.giovane;
  if (m >= seniorStartMonths(dog.weightKg)) return LifeStage.anziano;
  return LifeStage.adulto;
}

enum Confidence { bassa, media, alta }

class PottyPredictor {
  /// Uscite (eventi ravvicinati fusi) in ordine cronologico. Ogni uscita
  /// ricorda se è stata un incidente in casa.
  static List<({DateTime time, bool indoor})> outings(
    List<LogEntry> logs, {
    LogType type = LogType.pipi,
    double clusterMinutes = 15,
  }) {
    final evs = logs.where((l) => l.type == type).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    final out = <({DateTime time, bool indoor})>[];
    for (final p in evs) {
      if (out.isNotEmpty &&
          p.time.difference(out.last.time).inMinutes < clusterMinutes) {
        final last = out.removeLast();
        out.add((time: last.time, indoor: last.indoor || p.indoor));
      } else {
        out.add((time: p.time, indoor: p.indoor));
      }
    }
    return out;
  }

  static bool inSleepWindow(Dog dog, DateTime t) {
    final h = t.hour + t.minute / 60.0;
    final s = dog.sleepStartHour.toDouble();
    final w = dog.wakeHour.toDouble();
    if (s == w) return false;
    return s > w ? (h >= s || h < w) : (h >= s && h < w);
  }

  /// Prossimo orario di risveglio successivo a [t].
  static DateTime nextWake(Dog dog, DateTime t) {
    var w = DateTime(t.year, t.month, t.day, dog.wakeHour);
    if (!w.isAfter(t)) w = DateTime(t.year, t.month, t.day + 1, dog.wakeHour);
    return w;
  }
}

/// Statistiche giornaliere per grafici e allarmi.
class PottyStats {
  static Map<DateTime, int> outingsPerDay(
    List<LogEntry> logs, {
    LogType type = LogType.pipi,
  }) {
    final m = <DateTime, int>{};
    for (final o in PottyPredictor.outings(
      logs,
      type: type,
      clusterMinutes: type == LogType.pipi ? 15 : 30,
    )) {
      final d = DateTime(o.time.year, o.time.month, o.time.day);
      m[d] = (m[d] ?? 0) + 1;
    }
    return m;
  }

  /// Quota di bisogni fatti fuori negli ultimi [days] giorni (0-1).
  static double? outdoorRate(
    List<LogEntry> logs,
    DateTime now,
    int days, {
    LogType type = LogType.pipi,
  }) {
    final from = now.subtract(Duration(days: days));
    final outs = PottyPredictor.outings(
      logs,
      type: type,
    ).where((o) => o.time.isAfter(from)).toList();
    if (outs.isEmpty) return null;
    return outs.where((o) => !o.indoor).length / outs.length;
  }
}
