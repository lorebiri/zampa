import 'dart:math' as math;

/// Rilevamento facoltativo dell'uscita con un recinto virtuale intorno a
/// casa (ricerca/28 §3). Solo logica pura: nessun accesso al GPS qui. La
/// lettura della posizione (pacchetto nativo) non è ancora nell'app.
///
/// Privacy: il punto casa resta solo sul telefono ([GeofenceSettings]); le
/// posizioni servono solo a decidere «dentro/fuori» e non si salvano mai.
/// Nello storico vanno solo gli eventi [OutingEvent] (tipo e orario), e
/// nel diario nulla senza la conferma dell'utente ([OutingSuggestion]).

/// Punto geografico (gradi decimali).
class GeoPoint {
  const GeoPoint(this.lat, this.lon);
  final double lat;
  final double lon;

  bool get isValid =>
      lat.isFinite &&
      lon.isFinite &&
      lat >= -90 &&
      lat <= 90 &&
      lon >= -180 &&
      lon <= 180;

  /// Distanza in metri (formula dell'emisenoverso, raggio medio terrestre).
  double distanceTo(GeoPoint o) {
    const r = 6371008.8;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(o.lat - lat);
    final dLon = rad(o.lon - lon);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat)) *
            math.cos(rad(o.lat)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.min(1, math.sqrt(a)));
  }
}

/// Una posizione letta dal telefono, con orario e accuratezza (metri,
/// raggio di confidenza come lo dà il sistema).
class GeoFix {
  const GeoFix(this.time, this.point, this.accuracyM);
  final DateTime time;
  final GeoPoint point;
  final double accuracyM;
}

/// Impostazioni: tutto facoltativo, spento finché l'utente non dà il
/// consenso e non imposta il punto casa.
class GeofenceSettings {
  GeofenceSettings({
    this.home,
    double radiusM = defaultRadiusM,
    this.consentAt,
    this.enabled = false,
  }) : radiusM = clampRadius(radiusM);

  static const defaultRadiusM = 60.0;
  static const minRadiusM = 40.0;
  static const maxRadiusM = 150.0;

  static double clampRadius(double r) =>
      r.isFinite ? r.clamp(minRadiusM, maxRadiusM).toDouble() : defaultRadiusM;

  /// Punto casa scelto dall'utente. Salvato solo sul telefono.
  final GeoPoint? home;
  final double radiusM;

  /// Quando l'utente ha detto sì (consenso esplicito, revocabile).
  final DateTime? consentAt;
  final bool enabled;

  /// Il rilevamento gira solo con consenso, interruttore acceso e casa.
  bool get active =>
      enabled && consentAt != null && home != null && home!.isValid;

  /// Spegnere = dimenticare anche il punto casa.
  GeofenceSettings disabled() => GeofenceSettings(radiusM: radiusM);

  /// Per il salvataggio locale (mai nel backup condiviso né sul server).
  Map<String, Object?> toLocalJson() => {
    'home': home == null ? null : [home!.lat, home!.lon],
    'radiusM': radiusM,
    'consentAt': consentAt?.toUtc().toIso8601String(),
    'enabled': enabled,
  };

  static GeofenceSettings fromLocalJson(Map<String, Object?> j) {
    final h = j['home'];
    GeoPoint? home;
    if (h is List && h.length == 2 && h[0] is num && h[1] is num) {
      home = GeoPoint((h[0] as num).toDouble(), (h[1] as num).toDouble());
    }
    final c = j['consentAt'];
    return GeofenceSettings(
      home: home,
      radiusM: (j['radiusM'] as num?)?.toDouble() ?? defaultRadiusM,
      consentAt: c is String ? DateTime.tryParse(c)?.toLocal() : null,
      enabled: j['enabled'] == true,
    );
  }
}

enum OutingEventType { uscito, rientrato }

/// Evento salvabile nello storico: SOLO tipo e orario, niente coordinate.
class OutingEvent {
  const OutingEvent(this.type, this.time);
  final OutingEventType type;
  final DateTime time;

  Map<String, Object?> toJson() => {
    'type': type.name,
    'time': time.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is OutingEvent && other.type == type && other.time == time;

  @override
  int get hashCode => Object.hash(type, time);

  @override
  String toString() => 'OutingEvent(${type.name},$time)';
}

/// Rilevatore con isteresi, da alimentare con le posizioni in ordine.
///
/// - Posizioni con accuratezza peggiore di [maxAccuracyM] (100 m) o non
///   valide: ignorate.
/// - «Fuori» con certezza: distanza − accuratezza > raggio + [minHysteresisM]
///   (cioè anche il punto più vicino possibile è oltre il bordo).
/// - «Uscito» quando si resta fuori (nessuna posizione «dentro» nel mezzo)
///   per almeno [minAway] (3 minuti); l'orario è quello della prima
///   posizione fuori.
/// - «Dentro»: distanza ≤ raggio. «Rientrato» dopo [insideFixes] posizioni
///   dentro di fila (2); l'orario è quello della prima.
/// - Le posizioni tra le due soglie non cambiano lo stato (isteresi): il
///   segnale che balla vicino alla porta non crea uscite finte.
class OutingTracker {
  OutingTracker(this.settings);

  final GeofenceSettings settings;

  static const maxAccuracyM = 100.0;
  static const minHysteresisM = 15.0;
  static const minAway = Duration(minutes: 3);
  static const insideFixes = 2;

  bool _out = false;
  DateTime? _outCandidate;
  DateTime? _inCandidate;
  int _inCount = 0;
  DateTime? _last;

  bool get isOut => _out;

  /// Elabora una posizione; restituisce l'evento se ne scatta uno.
  OutingEvent? add(GeoFix f) {
    if (!settings.active) return null;
    if (!f.accuracyM.isFinite ||
        f.accuracyM < 0 ||
        f.accuracyM > maxAccuracyM ||
        !f.point.isValid) {
      return null;
    }
    // Posizioni fuori ordine o ripetute: ignorate.
    if (_last != null && !f.time.isAfter(_last!)) return null;
    _last = f.time;

    final d = settings.home!.distanceTo(f.point);
    final r = settings.radiusM;
    final surelyOut = d - f.accuracyM > r + minHysteresisM;
    final inside = d <= r;

    if (!_out) {
      if (inside) {
        _outCandidate = null;
        return null;
      }
      if (surelyOut) _outCandidate ??= f.time;
      final start = _outCandidate;
      if (start != null && f.time.difference(start) >= minAway) {
        _out = true;
        _outCandidate = null;
        _inCandidate = null;
        _inCount = 0;
        return OutingEvent(OutingEventType.uscito, start);
      }
      return null;
    }

    // Fuori: si aspetta il rientro confermato.
    if (inside) {
      _inCandidate ??= f.time;
      _inCount++;
      if (_inCount >= insideFixes) {
        final t = _inCandidate!;
        _out = false;
        _inCandidate = null;
        _inCount = 0;
        return OutingEvent(OutingEventType.rientrato, t);
      }
    } else {
      _inCandidate = null;
      _inCount = 0;
    }
    return null;
  }

  /// Comodità: tutta una sequenza (ordinata per orario).
  static List<OutingEvent> detect(
    GeofenceSettings settings,
    Iterable<GeoFix> fixes,
  ) {
    final t = OutingTracker(settings);
    final sorted = fixes.toList()..sort((a, b) => a.time.compareTo(b.time));
    return [for (final f in sorted) ?t.add(f)];
  }
}

/// Uscita completa (uscito → rientrato).
class Outing {
  const Outing(this.start, this.end);
  final DateTime start;
  final DateTime end;
  int get minutes => end.difference(start).inMinutes;
}

/// Accoppia gli eventi in uscite complete (un «uscito» senza rientro è
/// un'uscita ancora in corso: non si propone nulla).
List<Outing> pairOutings(Iterable<OutingEvent> events) {
  final out = <Outing>[];
  DateTime? start;
  for (final e in events) {
    if (e.type == OutingEventType.uscito) {
      start = e.time;
    } else if (start != null) {
      if (e.time.isAfter(start)) out.add(Outing(start, e.time));
      start = null;
    }
  }
  return out;
}

/// Domanda da mostrare dopo un'uscita. Non registra nulla: il diario si
/// scrive solo se l'utente tocca «Pipì» o «Cacca».
class OutingSuggestion {
  const OutingSuggestion({
    required this.dogId,
    required this.dogName,
    required this.outing,
  });

  /// Sopra le 3 ore probabilmente non era una passeggiata con il cane
  /// (lavoro, spesa): nessuna domanda.
  static const maxOuting = Duration(hours: 3);

  final String dogId;
  final String dogName;
  final Outing outing;

  /// Ora d'uscita «HH:MM». Il testo della domanda è in
  /// `QuickActionTexts.outingQuestion` (lib/notifications.dart).
  String get startHm {
    final t = outing.start;
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  /// null se l'uscita è troppo breve o troppo lunga per chiederlo.
  static OutingSuggestion? forOuting({
    required String dogId,
    required String dogName,
    required Outing outing,
  }) {
    final d = outing.end.difference(outing.start);
    if (d < OutingTracker.minAway || d > maxOuting) return null;
    return OutingSuggestion(dogId: dogId, dogName: dogName, outing: outing);
  }
}
