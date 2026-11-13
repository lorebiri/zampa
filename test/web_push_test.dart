// Promemoria Web Push (blocco B): stato sul web, avviso con «Attiva
// promemoria», e AppStore che spedisce promemoria e allarmi al server.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';
import 'package:zampa/sync/push_reminders.dart';
import 'package:zampa/ui/common.dart';
import 'package:zampa/ui/device_notice.dart';
import 'package:zampa/ui/theme.dart';

class _FakeSink implements ReminderSink {
  bool fail = false;
  final calls =
      <
        ({List<PlannedNotification> planned, List<PlannedNotification> urgent})
      >[];

  @override
  bool get active => true;

  @override
  Future<void> replace(
    List<PlannedNotification> planned, {
    List<PlannedNotification> urgent = const [],
  }) async {
    if (fail) throw Exception('rete assente');
    calls.add((planned: planned, urgent: urgent));
  }
}

Future<AppStore> _storeWithThirstyDog(_FakeSink sink) async {
  SharedPreferences.setMockInitialValues({});
  final s = AppStore(prefs: await SharedPreferences.getInstance());
  await s.load();
  s.reminderSink = sink;
  await s.upsertDog(
    Dog(
      id: 'd1',
      name: 'Birba',
      birthDate: DateTime(2020, 1, 1),
      sex: Sex.maschio,
      weightKg: 6,
    ),
  );
  // Ultima pipì 30 ore fa: allarme urgente «nessuna pipì».
  await s.addLog(
    LogEntry(
      id: 'p1',
      dogId: 'd1',
      type: LogType.pipi,
      time: DateTime.now().subtract(const Duration(hours: 30)),
    ),
  );
  return s;
}

void main() {
  group('Stato dei promemoria sul web', () {
    WebReminders st({
      bool native = false,
      bool push = true,
      bool ios = false,
      bool standalone = false,
      bool signedIn = true,
      String permission = 'default',
      bool subscribed = false,
    }) => webRemindersState(
      nativeSupported: native,
      pushSupported: push,
      isIos: ios,
      standalone: standalone,
      signedIn: signedIn,
      permission: permission,
      subscribed: subscribed,
    );

    test('Android e iOS nativi: notifiche locali', () {
      expect(st(native: true), WebReminders.native);
    });
    test('iPhone in Safari: prima la schermata Home', () {
      expect(st(ios: true, push: false), WebReminders.needsHomeScreen);
      expect(st(ios: true, standalone: true), WebReminders.ready);
    });
    test('browser senza push', () {
      expect(st(push: false), WebReminders.unsupported);
    });
    test('senza account non si può', () {
      expect(st(signedIn: false), WebReminders.needsAccount);
    });
    test('permesso negato, pronto, attivo', () {
      expect(st(permission: 'denied'), WebReminders.denied);
      expect(st(), WebReminders.ready);
      expect(st(permission: 'granted', subscribed: true), WebReminders.active);
    });
  });

  group('Avviso della Home', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Widget host(Widget child) => MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: ListView(children: [child])),
    );

    testWidgets('pronto: «Attiva promemoria» chiama l\'attivazione', (
      tester,
    ) async {
      var called = 0;
      await tester.pumpWidget(
        host(
          DeviceNotice(
            state: WebReminders.ready,
            onEnable: () async {
              called++;
              return false;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(deviceNoticeReadyText), findsOneWidget);
      await tester.tap(find.text('Attiva promemoria'));
      await tester.pumpAndSettle();
      expect(called, 1);
      // Non attivati: l'avviso resta, con un messaggio.
      expect(find.text(deviceNoticeReadyText), findsOneWidget);
    });

    testWidgets('testi per iPhone, account e permesso negato', (tester) async {
      for (final (s, text) in [
        (WebReminders.needsHomeScreen, deviceNoticeHomeText),
        (WebReminders.needsAccount, deviceNoticeAccountText),
        (WebReminders.denied, deviceNoticeDeniedText),
      ]) {
        await tester.pumpWidget(host(DeviceNotice(key: ValueKey(s), state: s)));
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget, reason: s.name);
        expect(find.text('Attiva promemoria'), findsNothing);
      }
    });

    testWidgets('attivi: nessun avviso', (tester) async {
      await tester.pumpWidget(
        host(const DeviceNotice(state: WebReminders.active)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NoticeCard), findsNothing);
    });
  });

  group('AppStore spedisce i promemoria al server', () {
    test('promemoria e allarme urgente, l\'allarme una volta sola', () async {
      final sink = _FakeSink();
      final s = await _storeWithThirstyDog(sink);
      expect(sink.calls, isNotEmpty);
      final allUrgent = sink.calls.expand((c) => c.urgent).toList();
      expect(allUrgent.where((u) => u.title.contains('SUBITO')), hasLength(1));
      final before = sink.calls.length;
      await s.replan();
      expect(sink.calls.length, before + 1);
      expect(sink.calls.last.urgent, isEmpty);
      // Una pipì adesso: il server riceve il promemoria futuro.
      await s.addLog(
        LogEntry(
          id: 'p2',
          dogId: 'd1',
          type: LogType.pipi,
          time: DateTime.now(),
        ),
      );
      expect(sink.calls.last.planned, isNotEmpty);
      expect(
        sink.calls.last.planned.every((p) => p.when.isAfter(DateTime.now())),
        isTrue,
      );
    });

    test(
      'senza rete l\'allarme si riprova al salvataggio successivo',
      () async {
        final sink = _FakeSink()..fail = true;
        final s = await _storeWithThirstyDog(sink);
        expect(sink.calls, isEmpty);
        sink.fail = false;
        await s.replan();
        expect(
          sink.calls.single.urgent.where((u) => u.title.contains('SUBITO')),
          hasLength(1),
        );
      },
    );

    test('il cane di esempio non manda mai promemoria', () async {
      SharedPreferences.setMockInitialValues({});
      final sink = _FakeSink();
      final s = AppStore(prefs: await SharedPreferences.getInstance());
      await s.load();
      s.reminderSink = sink;
      await s.loadDemo();
      expect(sink.calls.expand((c) => [...c.planned, ...c.urgent]), isEmpty);
    });
  });
}
