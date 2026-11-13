// Il compagno tamagotchi: stati d'animo legati a quello che succede.
// Regole: mai felice con un allarme, mai colpevolizzante, torna positivo
// appena si fa qualcosa.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/logic/bio_params.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/avatar.dart';

Future<AppStore> _store() async {
  SharedPreferences.setMockInitialValues({});
  final s = AppStore(prefs: await SharedPreferences.getInstance());
  await s.load();
  await s.upsertDog(
    Dog(
      id: 'd1',
      name: 'Birba',
      birthDate: DateTime(2020, 1, 1),
      sex: Sex.femmina,
      weightKg: 8,
    ),
  );
  return s;
}

PetMood _mood(AppStore s, DateTime now) {
  final dog = s.dogs.first;
  final alerts = AlertEngine.compute(
    dog: dog,
    logs: s.logs,
    records: s.records,
    weights: s.weights,
    now: now,
    pendingDoses: s.pendingDoses(dog.id, now),
  );
  return PetMood.of(s, dog, now, s.forecast(dog, Need.pipi, now), alerts);
}

void main() {
  // Le 15 di un giorno qualunque: sveglio, lontano dai pasti tipici.
  final now = DateTime(2026, 11, 10, 15, 0);

  test('scodinzola dopo un pasto appena dato', () async {
    final s = await _store();
    await s.addLog(
      LogEntry(
        id: 'p',
        dogId: 'd1',
        type: LogType.pipi,
        time: now.subtract(const Duration(hours: 1)),
      ),
    );
    await s.addLog(
      LogEntry(
        id: 'm',
        dogId: 'd1',
        type: LogType.pasto,
        time: now.subtract(const Duration(minutes: 10)),
      ),
    );
    final m = _mood(s, now);
    expect(m.pose, Pose.happy);
    expect(m.message, contains('scodinzola'));
  });

  test('sereno e premuroso con una scadenza vicina, anche passata', () async {
    final s = await _store();
    await s.addLog(
      LogEntry(
        id: 'p',
        dogId: 'd1',
        type: LogType.pipi,
        time: now.subtract(const Duration(hours: 1)),
      ),
    );
    await s.upsertRecord(
      HealthRecord(
        id: 'v',
        dogId: 'd1',
        type: RecordType.vaccino,
        title: 'Leptospirosi',
        done: false,
        date: now.add(const Duration(days: 2)),
      ),
    );
    var m = _mood(s, now);
    expect(m.pose, Pose.idle);
    expect(
      m.message,
      'Leptospirosi è tra 2 giorni: ci penso io a ricordartelo.',
    );
    // Scaduta: nessun rimprovero.
    await s.upsertRecord(
      HealthRecord(
        id: 'v',
        dogId: 'd1',
        type: RecordType.vaccino,
        title: 'Leptospirosi',
        done: false,
        date: now.subtract(const Duration(days: 3)),
      ),
    );
    m = _mood(s, now);
    expect(m.message, contains('quando puoi'));
    expect(m.pose, isNot(Pose.concerned));
  });

  test('felice quando le cose di oggi sono fatte', () async {
    final s = await _store();
    await s.addLog(
      LogEntry(
        id: 'p',
        dogId: 'd1',
        type: LogType.pipi,
        time: now.subtract(const Duration(hours: 1)),
      ),
    );
    for (final h in [8, 13]) {
      await s.addLog(
        LogEntry(
          id: 'm$h',
          dogId: 'd1',
          type: LogType.pasto,
          time: DateTime(now.year, now.month, now.day, h),
        ),
      );
    }
    final m = _mood(s, now);
    expect(m.pose, Pose.happy);
    expect(m.message, startsWith('Fatto tutto per oggi'));
  });

  test('con un allarme urgente resta preoccupato, mai felice', () async {
    final s = await _store();
    await s.addLog(
      LogEntry(
        id: 'm',
        dogId: 'd1',
        type: LogType.pasto,
        time: now.subtract(const Duration(minutes: 10)),
      ),
    );
    await s.addLog(
      LogEntry(
        id: 'x',
        dogId: 'd1',
        type: LogType.cacca,
        time: now.subtract(const Duration(minutes: 20)),
        signs: {Sign.sangue, Sign.nero},
      ),
    );
    final m = _mood(s, now);
    expect(m.pose, Pose.concerned);
  });
}
