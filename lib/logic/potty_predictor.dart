import 'dart:math' as math;

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

/// Previsione di base (Ciclo 2, C2-3; piano CEO 11.3).
///
/// Finché il modello statistico non batte un semplice timer sul banco di
/// prova (ricerca/12), ciò che l'utente vede si basa solo su regole
/// trasparenti, calcolate sui dati registrati del cane:
/// 1. intervallo personale da sveglio (mediana degli ultimi 14 giorni), che
///    si accorcia subito se negli ultimi 3 giorni è diventato più breve
///    (protezione per la poliuria che compare);
/// 2. orari abituali (gli stessi da almeno il 40% dei giorni), quando cadono
///    prima dell'intervallo;
/// 3. finestra «di solito tra X e Y» dagli intervalli osservati (20°-80°).
/// Tetti di sicurezza e notte restano quelli del modello, invariati.
class Baseline {
  const Baseline({
    required this.intervalMin,
    required this.recommendedAfterMin,
    required this.windowStartMin,
    required this.windowEndMin,
    required this.habitualMinutes,
    required this.nIntervals,
    required this.adaptedRecent,
    this.firstMinutes = const [],
  });

  /// Prima uscita dopo la notte negli ultimi 14 giorni: (fine settimana?,
  /// minuti dalla mezzanotte).
  final List<(bool, int)> firstMinutes;

  /// Intervallo tipico da sveglio (minuti).
  final double intervalMin;

  /// Minuti dopo l'ultimo evento a cui conviene uscire (secondo la prudenza).
  final double recommendedAfterMin;
  final double windowStartMin;
  final double windowEndMin;

  /// Orari abituali (minuti dalla mezzanotte), in ordine.
  final List<int> habitualMinutes;

  /// Intervalli da sveglio su cui si basa (0 = solo valori di partenza).
  final int nIntervals;

  /// True se l'intervallo è stato accorciato per gli ultimi 3 giorni.
  final bool adaptedRecent;

  static double _quantile(List<double> sorted, double q) {
    if (sorted.length == 1) return sorted.first;
    final pos = q * (sorted.length - 1);
    final lo = pos.floor(), hi = pos.ceil();
    return sorted[lo] + (sorted[hi] - sorted[lo]) * (pos - lo);
  }

  /// [times]: eventi registrati (già fusi), in ordine cronologico.
  /// [fallbackMin]: intervallo di partenza dalla letteratura, usato finché
  /// gli intervalli osservati sono meno di 4.
  static Baseline compute({
    required Dog dog,
    required List<DateTime> times,
    required DateTime now,
    required double fallbackMin,
    required double prudenceQuantile,
    required double maxGapMin,
    double minGapMin = 15,
    double lowQuantile = 0.1,
    double highQuantile = 0.9,
    double adaptBelow = 0.85,
  }) {
    final past = [
      for (final t in times)
        if (!t.isAfter(now)) t,
    ];
    final all = <(DateTime, double)>[];
    for (var i = 1; i < past.length; i++) {
      final a = past[i - 1], b = past[i];
      if (now.difference(b).inDays >= 14) continue;
      if (PottyPredictor.inSleepWindow(dog, a) ||
          PottyPredictor.inSleepWindow(dog, b)) {
        continue;
      }
      final g = b.difference(a).inMinutes.toDouble();
      if (g < minGapMin || g > maxGapMin) continue;
      all.add((b, g));
    }
    final gaps = [for (final e in all) e.$2]..sort();
    final recent = [
      for (final e in all)
        if (now.difference(e.$1).inHours < 72) e.$2,
    ]..sort();

    double interval, qRec, q20, q80;
    var adapted = false;
    if (gaps.length < 4) {
      interval = fallbackMin;
      // Senza dati: finestra larga e uscita prudente intorno alla mediana.
      qRec = fallbackMin * (0.6 + prudenceQuantile);
      q20 = fallbackMin * 0.7;
      q80 = fallbackMin * 1.35;
    } else {
      interval = _quantile(gaps, 0.5);
      qRec = _quantile(gaps, prudenceQuantile);
      q20 = _quantile(gaps, lowQuantile);
      q80 = _quantile(gaps, highQuantile);
      if (recent.length >= 3) {
        final r = _quantile(recent, 0.5);
        // Solo verso il più breve, e solo se il cambiamento è netto: un
        // cane che deve uscire più spesso non deve aspettare.
        if (r < interval * adaptBelow) {
          final k = r / interval;
          interval *= k;
          qRec *= k;
          q20 *= k;
          q80 *= k;
          adapted = true;
        }
      }
    }
    // Prima uscita di ogni giorno dopo la pausa della notte (≥ 5 ore, con
    // l'uscita precedente il giorno prima).
    final firsts = <(bool, int)>[];
    for (var i = 1; i < past.length; i++) {
      final t = past[i], p = past[i - 1];
      if (now.difference(t).inDays >= 14) continue;
      if (t.difference(p).inHours < 5) continue;
      if (t.hour >= 14 || (p.day == t.day && p.month == t.month)) continue;
      firsts.add((t.weekday >= 6, t.hour * 60 + t.minute));
    }
    return Baseline(
      firstMinutes: firsts,
      intervalMin: interval,
      recommendedAfterMin: math.min(qRec, interval),
      windowStartMin: q20,
      windowEndMin: q80,
      habitualMinutes: findHabitual(dog, past, now),
      nIntervals: gaps.length,
      adaptedRecent: adapted,
    );
  }

  /// Orari ricorrenti negli ultimi 14 giorni: gruppi entro 45 minuti presenti
  /// in almeno il 40% dei giorni con dati (e almeno 3 giorni).
  static List<int> findHabitual(Dog dog, List<DateTime> times, DateTime now) {
    final recent = [
      for (final t in times)
        if (!t.isAfter(now) && now.difference(t).inDays < 14) t,
    ];
    final days = {for (final t in recent) DateTime(t.year, t.month, t.day)}
        .length;
    if (days < 3) return const [];
    final mins = [for (final t in recent) t.hour * 60 + t.minute]..sort();
    final clusters = <List<int>>[];
    for (final m in mins) {
      if (clusters.isEmpty || m - clusters.last.last > 45) {
        clusters.add([m]);
      } else {
        clusters.last.add(m);
      }
    }
    final need = math.max(3, (days * 0.4).ceil());
    return [
      for (final c in clusters)
        if (c.length >= need) c[c.length ~/ 2],
    ];
  }

  /// Prima uscita abituale del mattino del giorno [day] (che conta come
  /// fine settimana o no): mediana e 5°-95° percentile (±30 min) delle prime uscite
  /// dopo la notte dello stesso tipo di giorno; con meno di 3 giorni dello
  /// stesso tipo usa tutti i giorni; con meno di 3 in tutto, null.
  ({DateTime at, DateTime from, DateTime to})? usualFirst(DateTime day) {
    final we = day.weekday >= 6;
    var m = [
      for (final f in firstMinutes)
        if (f.$1 == we) f.$2.toDouble(),
    ];
    if (m.length < 3) m = [for (final f in firstMinutes) f.$2.toDouble()];
    if (m.length < 3) return null;
    m.sort();
    DateTime at(double x) =>
        DateTime(day.year, day.month, day.day, 0, x.round());
    return (
      at: at(_quantile(m, 0.5)),
      from: at(_quantile(m, 0.05) - 30),
      to: at(_quantile(m, 0.95) + 30),
    );
  }

  /// Prossimo orario abituale dopo [after] (entro 24 ore), o null.
  DateTime? nextHabitual(DateTime after) {
    DateTime? best;
    for (final m in habitualMinutes) {
      for (var d = 0; d <= 1; d++) {
        final t = DateTime(
          after.year,
          after.month,
          after.day + d,
          m ~/ 60,
          m % 60,
        );
        if (t.isAfter(after) && (best == null || t.isBefore(best))) best = t;
      }
    }
    return best;
  }
}
