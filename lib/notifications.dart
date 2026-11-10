import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Promemoria locali (nessun server). Su web e desktop Linux/Windows le
/// notifiche programmate non sono supportate: l'app mostra il conto alla
/// rovescia e gli avvisi in primo piano.
class Notifier {
  Notifier._();
  static final instance = Notifier._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> init() async {
    if (!supported || _ready) return;
    try {
      tzdata.initializeTimeZones();
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: darwin,
          macOS: darwin,
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _ready = true;
    } catch (e) {
      debugPrint('Notifiche non disponibili: $e');
    }
  }

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'zampa_promemoria',
      'Promemoria',
      channelDescription: 'Uscite per la pipì, vaccini, farmaci',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  /// Programma (o riprogramma) un promemoria con id stabile.
  Future<void> schedule(
    int id,
    DateTime when,
    String title,
    String body,
  ) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
      if (!when.isAfter(DateTime.now())) return;
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('Promemoria non programmato: $e');
    }
  }

  /// Notifica immediata (allarmi urgenti).
  Future<void> showNow(int id, String title, String body) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (e) {
      debugPrint('Notifica non mostrata: $e');
    }
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id: id);
  }
}
