import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/logic/prevention.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';

/// Ciclo 1, C1-3: tetto delle notifiche programmate con priorità
/// (iOS ne conserva al massimo 64 in attesa).
void main() {
  test('3 cani, 2 terapie ogni 8 h e prevenzione completa: ≤ 60, dosi e urgenze incluse', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(prefs: await SharedPreferences.getInstance());
    await s.load();
    final now = DateTime(2026, 11, 10, 10, 5);
    for (var i = 0; i < 3; i++) {
      final d = Dog(
        id: 'd$i',
        name: 'Cane $i',
        birthDate: DateTime(2020, 1, 1),
        sex: Sex.maschio,
        weightKg: 20,
      );
      await s.upsertDog(d);
      await s.addLog(
        LogEntry(
          id: 'p$i',
          dogId: d.id,
          type: LogType.pipi,
          time: now.subtract(const Duration(hours: 2)),
        ),
      );
      for (final t in ['Fenobarbital', 'Pimobendan']) {
        await s.upsertRecord(
          HealthRecord(
            id: '$t$i',
            dogId: d.id,
            type: RecordType.farmaco,
            title: t,
            date: DateTime(2026, 11, 9, 10),
            everyHours: 8,
            endDate: now.add(const Duration(days: 30)),
          ),
        );
      }
      await s.addRecords(PreventionPlanner.suggest(d, s.records, now));
    }
    final planned = s.planNotifications(now);
    expect(planned.length, lessThanOrEqualTo(AppStore.maxScheduled));
    // Tutte le dosi delle prossime 24 ore ci sono (3 cani × 2 farmaci × 3 dosi).
    final doses24 = planned.where(
      (p) =>
          p.title.startsWith('💊') &&
          !p.title.contains('confermata') &&
          p.when.difference(now).inHours < 24,
    );
    expect(doses24.length, 18);
    // Le urgenze (pipì mancata) ci sono per tutti e tre i cani.
    expect(planned.where((p) => p.priority == 0).length, 3);
    // Ordinate per priorità.
    for (var i = 1; i < planned.length; i++) {
      expect(
        planned[i].priority,
        greaterThanOrEqualTo(planned[i - 1].priority),
      );
    }
    // Urgenze e dosi sono "esatte".
    expect(planned.where((p) => p.priority <= 1).every((p) => p.exact), isTrue);
  });
}
