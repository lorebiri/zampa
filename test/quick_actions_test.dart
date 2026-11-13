import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/logic/quick_actions.dart';
import 'package:zampa/models.dart';
import 'package:zampa/notifications.dart';
import 'package:zampa/store.dart';

/// Bottoni «Fatta ✓» / «Non ancora» nel promemoria della pipì (ricerca/28).
/// Solo logica e store: nessuna piattaforma.
void main() {
  final now = DateTime(2026, 11, 13, 9, 0);
  const payload = ReminderPayload(
    dogId: 'd1',
    dogName: 'Lulù',
    notificationId: 1000,
  );

  group('payload', () {
    test('andata e ritorno', () {
      final p = ReminderPayload.tryParse(payload.encode())!;
      expect(p.dogId, 'd1');
      expect(p.dogName, 'Lulù');
      expect(p.notificationId, 1000);
      expect(p.need, 'pipi');
    });

    test(
      'payload assenti, rovinati o di altre notifiche: null, mai errori',
      () {
        for (final raw in [
          null,
          '',
          'ciao',
          '[1,2]',
          '{"v":2,"k":"uscita","dog":"d1","nid":1}',
          '{"v":1,"k":"dose","dog":"d1","nid":1}',
          '{"v":1,"k":"uscita","dog":"","nid":1}',
          '{"v":1,"k":"uscita","dog":"d1","nid":"x"}',
          '{"v":1,"k":"uscita","need":"cacca","dog":"d1","nid":1}',
        ]) {
          expect(ReminderPayload.tryParse(raw), isNull, reason: '$raw');
        }
      },
    );

    test('dal tocco all\'azione: solo i nostri bottoni', () {
      QuickAction? a(String? id, [String? p]) => QuickAction.fromResponse(
        actionId: id,
        payload: p ?? payload.encode(),
        at: now,
        id: 'x',
      );
      expect(a(QuickActions.done)!.kind, QuickActionKind.done);
      expect(a(QuickActions.notYet)!.kind, QuickActionKind.notYet);
      expect(a(QuickActions.done)!.dogId, 'd1');
      expect(a(null), isNull, reason: 'tocco sulla notifica, non un bottone');
      expect(a('altro'), isNull);
      expect(a(QuickActions.done, 'rovinato'), isNull);
    });

    test('coda: andata e ritorno in JSON, con l\'ora del tocco', () {
      final q = QuickAction(
        id: 'a1',
        kind: QuickActionKind.notYet,
        dogId: 'd1',
        at: now,
      );
      final back = QuickAction.tryFromJson(jsonEncode(q.toJson()))!;
      expect(back.kind, QuickActionKind.notYet);
      expect(back.at, now);
      expect(QuickAction.tryFromJson('{"kind":"boh"}'), isNull);
    });
  });

  group('applicazione (funzione pura)', () {
    QuickAction act(
      String id,
      QuickActionKind k,
      DateTime at, [
      String dog = 'd1',
    ]) => QuickAction(id: id, kind: k, dogId: dog, at: at);

    test('«Fatta ✓»: una pipì fuori casa all\'ora del tocco', () {
      final at = now.subtract(const Duration(hours: 2));
      final r = reduceQuickActions(
        actions: [act('a1', QuickActionKind.done, at)],
        dogIds: {'d1'},
        logs: const [],
        snoozes: const {},
        now: now,
      );
      final l = r.newLogs.single;
      expect(l.type, LogType.pipi);
      expect(l.indoor, isFalse);
      expect(l.dogId, 'd1');
      expect(l.time, at, reason: 'conta il tocco, non l\'apertura dell\'app');
      expect(r.applied, {'a1'});
    });

    test('idempotente: la stessa azione due volte non duplica la pipì', () {
      final a = act('a1', QuickActionKind.done, now);
      final r1 = reduceQuickActions(
        actions: [a],
        dogIds: {'d1'},
        logs: const [],
        snoozes: const {},
        now: now,
      );
      final r2 = reduceQuickActions(
        actions: [a, a],
        dogIds: {'d1'},
        logs: r1.newLogs,
        snoozes: const {},
        now: now,
      );
      expect(r2.newLogs, isEmpty);
      expect(r2.applied, {'a1'});
    });

    test('«Non ancora»: niente diario, promemoria tra 15 minuti', () {
      final r = reduceQuickActions(
        actions: [act('a1', QuickActionKind.notYet, now)],
        dogIds: {'d1'},
        logs: const [],
        snoozes: const {},
        now: now,
      );
      expect(r.newLogs, isEmpty);
      expect(r.snoozes['d1']!.until, now.add(const Duration(minutes: 15)));
    });

    test('«Non ancora» e poi «Fatta ✓»: il rinvio si annulla', () {
      final r = reduceQuickActions(
        actions: [
          act('b', QuickActionKind.done, now.add(const Duration(minutes: 5))),
          act('a', QuickActionKind.notYet, now),
        ],
        dogIds: {'d1'},
        logs: const [],
        snoozes: const {},
        now: now.add(const Duration(minutes: 6)),
      );
      expect(r.newLogs.length, 1);
      expect(r.snoozes, isEmpty);
    });

    test(
      'cane cancellato, cane di esempio, azione troppo vecchia: scartate',
      () {
        final r = reduceQuickActions(
          actions: [
            act('a', QuickActionKind.done, now, 'sparito'),
            act('b', QuickActionKind.done, now, 'demo-1'),
            act(
              'c',
              QuickActionKind.done,
              now.subtract(const Duration(days: 4)),
            ),
          ],
          dogIds: {'d1', 'demo-1'},
          logs: const [],
          snoozes: const {},
          now: now,
        );
        expect(r.newLogs, isEmpty);
        expect(r.applied, {'a', 'b', 'c'}, reason: 'tolte comunque dalla coda');
      },
    );

    test('orario nel futuro (orologio spostato): si usa adesso', () {
      final r = reduceQuickActions(
        actions: [
          act('a', QuickActionKind.done, now.add(const Duration(hours: 1))),
        ],
        dogIds: {'d1'},
        logs: const [],
        snoozes: const {},
        now: now,
      );
      expect(r.newLogs.single.time, now);
    });

    test('il rinvio scade con il tempo o con una pipì registrata dopo', () {
      final s = Snooze(since: now, until: now.add(const Duration(minutes: 15)));
      expect(activeSnoozeUntil(s, const [], now), s.until);
      expect(
        activeSnoozeUntil(s, const [], now.add(const Duration(minutes: 16))),
        isNull,
      );
      final pee = LogEntry(
        id: 'p',
        dogId: 'd1',
        type: LogType.pipi,
        time: now.add(const Duration(minutes: 3)),
      );
      expect(activeSnoozeUntil(s, [pee], now), isNull);
      final s2 = Snooze.decodeAll(Snooze.encodeAll({'d1': s}));
      expect(s2['d1']!.until, s.until);
      expect(Snooze.decodeAll('rovinato'), isEmpty);
    });
  });

  group('store', () {
    Future<(AppStore, SharedPreferences, Dog)> setup() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final s = AppStore(prefs: prefs);
      await s.load();
      await s.acceptTerms();
      final d = Dog(
        id: 'd1',
        name: 'Lulù',
        birthDate: DateTime(2021, 1, 1),
        sex: Sex.femmina,
        weightKg: 8,
      );
      await s.upsertDog(d);
      final t = DateTime.now();
      for (var i = 1; i <= 6; i++) {
        await s.addLog(
          LogEntry(
            id: 'p$i',
            dogId: d.id,
            type: LogType.pipi,
            time: t.subtract(Duration(hours: 4 * i)),
          ),
        );
      }
      return (s, prefs, d);
    }

    test('il promemoria della pipì porta il payload; le urgenze no', () async {
      final (s, _, d) = await setup();
      final plan = s.planNotifications(DateTime.now());
      final reminder = plan.firstWhere((p) => p.id == 1000);
      final p = ReminderPayload.tryParse(reminder.payload)!;
      expect(p.dogId, d.id);
      expect(p.notificationId, 1000);
      // Pipì mancata (urgenza) e scadenze: senza bottoni, testi invariati.
      final urgent = plan.firstWhere((p) => p.id == 1096);
      expect(urgent.payload, isNull);
      expect(urgent.title, startsWith('🔴 Lulù: nessuna pipì da'));
    });

    test('«Fatta ✓» in coda (app chiusa): applicata all\'avvio', () async {
      final (s, prefs, d) = await setup();
      final at = DateTime.now().subtract(const Duration(minutes: 30));
      await QuickActionQueue.add(
        prefs,
        QuickAction(id: 'qa1', kind: QuickActionKind.done, dogId: d.id, at: at),
      );
      final before = s.logsOf(d.id).length;
      expect(await s.applyQuickActions(), 1);
      final logs = s.logsOf(d.id);
      expect(logs.length, before + 1);
      expect(logs.first.time, at);
      expect(logs.first.indoor, isFalse);
      expect(logs.first.type, LogType.pipi);
      // Coda vuota: una seconda volta non aggiunge nulla.
      expect(await s.applyQuickActions(), 0);
      expect(prefs.getKeys().where((k) => k.startsWith('lulu_qa_')), isEmpty);
      // E resta dopo il riavvio.
      final again = AppStore(prefs: prefs);
      await again.load();
      expect(again.logsOf(d.id).length, before + 1);
    });

    test('chiamate contemporanee: la pipì entra una volta sola', () async {
      final (s, prefs, d) = await setup();
      await QuickActionQueue.add(
        prefs,
        QuickAction(
          id: 'qa1',
          kind: QuickActionKind.done,
          dogId: d.id,
          at: DateTime.now(),
        ),
      );
      final before = s.logsOf(d.id).length;
      final r = await Future.wait([
        s.applyQuickActions(),
        s.applyQuickActions(),
      ]);
      expect(r.fold<int>(0, (a, b) => a + b), 1);
      expect(s.logsOf(d.id).length, before + 1);
    });

    test('«Non ancora»: il promemoria torna tra 15 minuti, poi sparisce '
        'con la pipì', () async {
      final (s, prefs, d) = await setup();
      final t = DateTime.now();
      await QuickActionQueue.add(
        prefs,
        QuickAction(id: 'n1', kind: QuickActionKind.notYet, dogId: d.id, at: t),
      );
      final before = s.logsOf(d.id).length;
      await s.applyQuickActions();
      expect(s.logsOf(d.id).length, before, reason: 'niente nel diario');
      final r = s.planNotifications(t.add(const Duration(minutes: 1)));
      final reminder = r.firstWhere((p) => p.id == 1000);
      expect(reminder.when, t.add(const Duration(minutes: 15)));
      expect(reminder.title, QuickActionTexts.snoozeTitle('Lulù'));
      expect(
        ReminderPayload.tryParse(reminder.payload),
        isNotNull,
        reason: 'anche il promemoria riproposto ha i bottoni',
      );
      // Il rinvio è salvato (riavvio dell'app).
      final again = AppStore(prefs: prefs);
      await again.load();
      expect(again.snoozes[d.id]!.until, t.add(const Duration(minutes: 15)));
      // Pipì registrata nell'app: torna il promemoria normale.
      await s.addLog(
        LogEntry(
          id: 'nuova',
          dogId: d.id,
          type: LogType.pipi,
          time: t.add(const Duration(minutes: 2)),
        ),
      );
      final r2 = s.planNotifications(t.add(const Duration(minutes: 3)));
      final normal = r2.firstWhere((p) => p.id == 1000);
      expect(normal.title, 'È quasi ora di uscire con Lulù 🐾');
    });

    test('cancellare tutto cancella anche i rinvii', () async {
      final (s, prefs, d) = await setup();
      await QuickActionQueue.add(
        prefs,
        QuickAction(
          id: 'n1',
          kind: QuickActionKind.notYet,
          dogId: d.id,
          at: DateTime.now(),
        ),
      );
      await s.applyQuickActions();
      expect(s.snoozes, isNotEmpty);
      await s.wipe();
      expect(s.snoozes, isEmpty);
      expect(prefs.getString('lulu_snooze_v1'), isNull);
    });
  });
}
