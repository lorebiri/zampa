import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/logic/outing_geofence.dart';
import 'package:zampa/notifications.dart';

/// Recinto intorno a casa (ricerca/28 §3): solo logica, nessun GPS.
void main() {
  const home = GeoPoint(45.4642, 9.1900);
  // Un punto a [m] metri a nord di casa.
  GeoPoint north(double m) => GeoPoint(home.lat + m / 111195.0, home.lon);
  final t0 = DateTime(2026, 11, 13, 7, 30);
  GeoFix fix(int minute, double m, [double acc = 10, int second = 0]) =>
      GeoFix(t0.add(Duration(minutes: minute, seconds: second)), north(m), acc);
  final on = GeofenceSettings(
    home: home,
    consentAt: DateTime(2026, 11, 1),
    enabled: true,
  );

  test('distanza: 100 m a nord sono circa 100 m', () {
    expect(home.distanceTo(north(100)), closeTo(100, 0.5));
  });

  test('raggio: 60 m di base, regolabile tra 40 e 150', () {
    expect(GeofenceSettings().radiusM, 60);
    expect(GeofenceSettings(radiusM: 10).radiusM, 40);
    expect(GeofenceSettings(radiusM: 500).radiusM, 150);
    expect(GeofenceSettings(radiusM: 90).radiusM, 90);
    expect(GeofenceSettings(radiusM: double.nan).radiusM, 60);
  });

  test('senza consenso, spento o senza casa: nessun evento', () {
    final fixes = [for (var i = 0; i < 20; i++) fix(i, i < 10 ? 300 : 0)];
    for (final s in [
      GeofenceSettings(home: home, enabled: true), // niente consenso
      GeofenceSettings(home: home, consentAt: t0), // spento
      GeofenceSettings(consentAt: t0, enabled: true), // niente casa
      on.disabled(),
    ]) {
      expect(OutingTracker.detect(s, fixes), isEmpty);
    }
    expect(on.disabled().home, isNull, reason: 'spegnere dimentica la casa');
  });

  test('uscita di 20 minuti: «uscito» e «rientrato» con gli orari giusti', () {
    final fixes = [
      fix(0, 5),
      fix(1, 20),
      for (var m = 2; m <= 21; m++) fix(m, 200 + m * 10.0),
      fix(22, 30),
      fix(23, 10),
      fix(24, 5),
    ];
    final ev = OutingTracker.detect(on, fixes);
    expect(ev, [
      OutingEvent(OutingEventType.uscito, t0.add(const Duration(minutes: 2))),
      OutingEvent(
        OutingEventType.rientrato,
        t0.add(const Duration(minutes: 22)),
      ),
    ]);
    final o = pairOutings(ev).single;
    expect(o.minutes, 20);
    final s = OutingSuggestion.forOuting(
      dogId: 'd',
      dogName: 'Lulù',
      outing: o,
    )!;
    expect(
      QuickActionTexts.outingQuestion(s),
      'Sei uscito con Lulù alle 07:32 per 20 minuti: ha fatto pipì? cacca?',
    );
  });

  test('fuori per meno di 3 minuti: nessuna uscita', () {
    final ev = OutingTracker.detect(on, [
      fix(0, 5),
      fix(1, 200),
      fix(2, 200),
      fix(3, 200, 10, -1), // 2 min 59 s dopo la prima
      fix(4, 10),
      fix(5, 10),
    ]);
    expect(ev, isEmpty);
  });

  test('esattamente 3 minuti fuori bastano', () {
    final ev = OutingTracker.detect(on, [fix(0, 5), fix(1, 200), fix(4, 210)]);
    expect(ev.single.type, OutingEventType.uscito);
    expect(ev.single.time, t0.add(const Duration(minutes: 1)));
  });

  test('il margine di accuratezza conta: 100 m con ±50 m non è «fuori»', () {
    // 100 − 50 = 50 < 60 + 15: potrebbe essere ancora in casa.
    final ev = OutingTracker.detect(on, [
      for (var m = 0; m < 15; m++) fix(m, 100, 50),
    ]);
    expect(ev, isEmpty);
    // Con ±10 m invece sì: 100 − 10 = 90 > 75.
    final ev2 = OutingTracker.detect(on, [
      for (var m = 0; m < 15; m++) fix(m, 100, 10),
    ]);
    expect(ev2.single.type, OutingEventType.uscito);
  });

  test('posizioni con accuratezza oltre 100 m: ignorate', () {
    final ev = OutingTracker.detect(on, [
      fix(0, 5),
      for (var m = 1; m < 15; m++) fix(m, 2000, 150),
    ]);
    expect(ev, isEmpty);
    // Una posizione «dentro» molto imprecisa non interrompe l'uscita.
    final ev2 = OutingTracker.detect(on, [
      fix(0, 300),
      fix(1, 0, 500),
      fix(2, 300),
      fix(3, 300),
    ]);
    expect(ev2.single.type, OutingEventType.uscito);
  });

  test('isteresi: il segnale che balla vicino al bordo non crea uscite', () {
    // Tra 60 e 75+acc m: zona grigia, nessun cambio di stato.
    final ev = OutingTracker.detect(on, [
      for (var m = 0; m < 30; m++) fix(m, m.isEven ? 70 : 82),
    ]);
    expect(ev, isEmpty);
  });

  test('una sola posizione dentro non basta per il rientro', () {
    final ev = OutingTracker.detect(on, [
      fix(0, 300),
      fix(4, 300),
      fix(5, 10), // un rimbalzo
      fix(6, 300),
      fix(10, 20),
      fix(11, 15),
    ]);
    expect(ev.map((e) => e.type), [
      OutingEventType.uscito,
      OutingEventType.rientrato,
    ]);
    expect(ev.last.time, t0.add(const Duration(minutes: 10)));
  });

  test('una posizione dentro prima dei 3 minuti azzera il conto', () {
    final ev = OutingTracker.detect(on, [
      fix(0, 300),
      fix(2, 10),
      fix(3, 300),
      fix(5, 300), // solo 2 minuti dalla nuova prima posizione fuori
    ]);
    expect(ev, isEmpty);
  });

  test('posizioni fuori ordine: si ordinano, i doppioni si ignorano', () {
    final ev = OutingTracker.detect(on, [
      fix(4, 300),
      fix(0, 5),
      fix(1, 300),
      fix(1, 300),
    ]);
    expect(ev.single.time, t0.add(const Duration(minutes: 1)));
  });

  test('raggio più grande: 120 m fuori con raggio 150 restano «dentro»', () {
    final wide = GeofenceSettings(
      home: home,
      radiusM: 150,
      consentAt: t0,
      enabled: true,
    );
    final ev = OutingTracker.detect(wide, [
      for (var m = 0; m < 10; m++) fix(m, 120),
    ]);
    expect(ev, isEmpty);
  });

  test('suggerimento: mai per uscite oltre 3 ore o ancora in corso', () {
    final long = Outing(t0, t0.add(const Duration(hours: 4)));
    expect(
      OutingSuggestion.forOuting(dogId: 'd', dogName: 'Lulù', outing: long),
      isNull,
    );
    expect(pairOutings([OutingEvent(OutingEventType.uscito, t0)]), isEmpty);
    final one = Outing(t0, t0.add(const Duration(minutes: 3)));
    final s = OutingSuggestion.forOuting(
      dogId: 'd',
      dogName: 'Lulù',
      outing: one,
    )!;
    expect(QuickActionTexts.outingQuestion(s), contains('per 3 minuti'));
    expect(s.startHm, '07:30');
  });

  test('privacy: gli eventi salvati non contengono coordinate', () {
    final e = OutingEvent(OutingEventType.uscito, t0);
    expect(e.toJson().keys.toSet(), {'type', 'time'});
    final s = GeofenceSettings.fromLocalJson(on.toLocalJson());
    expect(s.active, isTrue);
    expect(s.home!.lat, home.lat);
    expect(s.radiusM, 60);
  });
}
