import 'dart:math' as math;

import '../models.dart';
import 'bio_params.dart';
import 'elimination_model.dart';
import 'poop_forecast.dart';
import 'potty_predictor.dart';

/// ESPORTAZIONE ANONIMA PER LO STUDIO (ricerca/28 §5, ricerca/12 §5.2)
///
/// Calcola sul telefono, solo con il consenso dello studio, un file con
/// le sole metriche: di quanto hanno sbagliato le previsioni (minuti
/// arrotondati a 5, troncati a 720), se la pipì è caduta nelle finestre,
/// se era in casa, se c'era un segnale prima, quante uscite al giorno.
/// NON contiene: nome del cane, razza, note, foto, orari o date assolute
/// (solo il giorno relativo 0, 1, 2…), posizione, dati del padrone.
/// Il file non parte da solo: è il partecipante a condividerlo.

const studyExportVersion = 'studio-v3-2026-11';

int _r5(num m) => (m / 5).round() * 5;
int _cap(num m) => math.max(-720, math.min(720, _r5(m)));

String _daypart(DateTime t, DateTime prev) {
  if (t.difference(prev).inHours >= 6 && t.day != prev.day) return 'mattino';
  if (t.hour < 17) return 'giorno';
  return 'sera';
}

String ageBand(Dog dog, DateTime now) {
  final m = dog.ageInMonths(now);
  if (m < 6) return 'cucciolo';
  if (m >= seniorStartMonths(dog.weightKg)) return 'anziano';
  return 'adulto';
}

String sizeBand(double kg) => kg < 10
    ? '<10'
    : kg < 25
    ? '10-25'
    : kg < 45
    ? '25-45'
    : '>45';

/// Costruisce l'esportazione. [pid]: pseudonimo casuale dello studio (mai
/// derivato dall'id del cane). [consent]: senza consenso non si esporta.
/// [days]: giorni più recenti da valutare.
Map<String, Object?>? buildStudyExport({
  required Dog dog,
  required List<LogEntry> logs,
  required DateTime now,
  required String pid,
  required bool consent,
  bool? garden,
  String? outingStyle,
  int days = 28,
}) {
  if (!consent) return null;
  final all = [
    for (final l in logs)
      if (l.dogId == dog.id && !l.time.isAfter(now)) l,
  ]..sort((a, b) => a.time.compareTo(b.time));
  if (all.isEmpty) return null;
  final first = DateTime(all.first.time.year, all.first.time.month,
      all.first.time.day);
  int dayIndex(DateTime t) =>
      DateTime(t.year, t.month, t.day).difference(first).inDays;
  final from = now.subtract(Duration(days: days));
  final engine = EliminationModel();
  final events = <Map<String, Object?>>[];

  // Pipì: previsione v2 rifatta 1 minuto dopo la pipì precedente.
  final pees = PottyPredictor.outings(all, type: LogType.pipi);
  for (var i = 1; i < pees.length; i++) {
    final actual = pees[i].time;
    if (actual.isBefore(from)) continue;
    final prev = pees[i - 1].time;
    final origin = prev.add(const Duration(minutes: 1));
    final vis = [
      for (final l in all)
        if (!l.time.isAfter(origin)) l,
    ];
    final f = engine
        .fit(dog, Need.pipi, vis, const [], origin, shadow: false)
        .forecast(origin, withAccuracy: false);
    final v = f.v2;
    final exp = v?.expectedAt ?? f.expectedAt;
    final signal = all.any(
      (l) =>
          l.type == LogType.segnale &&
          l.time.isAfter(prev) &&
          !l.time.isAfter(actual) &&
          actual.difference(l.time).inMinutes <= 60,
    );
    events.add({
      'need': 'pipi',
      'day_index': dayIndex(actual),
      'weekend': actual.weekday >= 6,
      'daypart': _daypart(actual, prev),
      'err_v2': _cap(actual.difference(exp).inMinutes.abs()),
      'signed_err_v2': _cap(actual.difference(exp).inMinutes),
      'err_base': _cap(actual.difference(f.expectedAt).inMinutes.abs()),
      'in_50': v != null && !actual.isBefore(v.lo50) && !actual.isAfter(v.hi50),
      'in_80': v != null && !actual.isBefore(v.lo80) && !actual.isAfter(v.hi80),
      'indoor': pees[i].indoor,
      'signal_before': signal,
    });
  }

  // Cacca: previsione v3 legata ai pasti, stessa origine onesta.
  final poops = PottyPredictor.outings(
    all,
    type: LogType.cacca,
    clusterMinutes: Need.cacca.clusterMinutes,
  );
  for (var i = 1; i < poops.length; i++) {
    final actual = poops[i].time;
    if (actual.isBefore(from)) continue;
    final origin = poops[i - 1].time.add(const Duration(minutes: 1));
    final vis = [
      for (final l in all)
        if (!l.time.isAfter(origin)) l,
    ];
    final c = poopCandidates(dog, vis, origin);
    if (c == null) continue;
    events.add({
      'need': 'cacca',
      'day_index': dayIndex(actual),
      'weekend': actual.weekday >= 6,
      'err_v3': _cap(actual.difference(c.at).inMinutes.abs()),
      'err_timer': _cap(actual.difference(c.t).inMinutes.abs()),
      'indoor': poops[i].indoor,
    });
  }

  // Uscite e incidenti per giorno.
  final perDay = <int, Map<String, int>>{};
  for (final o in pees) {
    if (o.time.isBefore(from)) continue;
    final d = perDay.putIfAbsent(dayIndex(o.time), () => {
      'outings': 0,
      'indoor': 0,
      'signals': 0,
    });
    d[o.indoor ? 'indoor' : 'outings'] = d[o.indoor ? 'indoor' : 'outings']! + 1;
  }
  for (final l in all.where((l) => l.type == LogType.segnale)) {
    if (l.time.isBefore(from)) continue;
    final d = perDay.putIfAbsent(dayIndex(l.time), () => {
      'outings': 0,
      'indoor': 0,
      'signals': 0,
    });
    d['signals'] = d['signals']! + 1;
  }

  return {
    'version': studyExportVersion,
    'pid': pid,
    'dog': {
      'age_band': ageBand(dog, now),
      'size_band': sizeBand(dog.weightKg),
      'sex': dog.sex.name,
      'neutered': dog.neutered,
      'chronic': dog.conditions.trim().isNotEmpty,
      'garden': garden,
      'outing_style': outingStyle,
    },
    'events': events,
    'days': [
      for (final e in (perDay.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key))))
        {'day_index': e.key, ...e.value},
    ],
  };
}

/// Pseudonimo casuale (UUID v4) per lo studio.
String newStudyPid([math.Random? r]) {
  final rnd = r ?? math.Random.secure();
  final b = List<int>.generate(16, (_) => rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int x) => x.toRadixString(16).padLeft(2, '0');
  final s = b.map(h).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-'
      '${s.substring(16, 20)}-${s.substring(20)}';
}
