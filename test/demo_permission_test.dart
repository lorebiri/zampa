import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';

/// Ciclo 2, C2-2: il cane di esempio non manda notifiche e non impedisce
/// quelle del primo cane vero (CEO 11.4).
void main() {
  test('solo il cane di esempio: nessuna notifica programmata', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(prefs: await SharedPreferences.getInstance());
    await s.load();
    await s.loadDemo();
    expect(s.dogs, hasLength(1));
    expect(isDemoId(s.dogs.single.id), isTrue);
    expect(s.hasRealDog, isFalse);
    expect(s.planNotifications(DateTime.now()), isEmpty);
  });

  test('esempio e poi cane vero: notifiche solo per il cane vero', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(prefs: await SharedPreferences.getInstance());
    await s.load();
    await s.loadDemo();
    final now = DateTime.now();
    final d = Dog(
      id: newId(),
      name: 'Birba',
      birthDate: DateTime(now.year - 4, 1, 1),
      sex: Sex.femmina,
      weightKg: 9,
    );
    await s.upsertDog(d);
    expect(s.hasRealDog, isTrue);
    expect(s.demoDogs, hasLength(1));
    await s.addLog(
      LogEntry(
        id: newId(),
        dogId: d.id,
        type: LogType.pipi,
        time: now.subtract(const Duration(hours: 1)),
      ),
    );
    final planned = s.planNotifications(now);
    expect(planned, isNotEmpty);
    expect(planned.every((p) => p.body.contains('Luna') == false), isTrue);
    expect(planned.every((p) => !p.title.contains('Luna')), isTrue);

    await s.removeDemo();
    expect(s.dogs.map((x) => x.id), [d.id]);
    expect(s.logs.every((l) => !isDemoId(l.dogId)), isTrue);
  });
}
