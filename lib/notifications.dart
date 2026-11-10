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
  bool _exactAllowed = false;

  /// Chiede il permesso per le notifiche (e su Android le sveglie esatte).
  Future<bool> requestPermissions() async {
    if (!supported || !_ready) return false;
    var ok = true;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final mac = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      ok =
          await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    } else if (mac != null) {
      ok =
          await mac.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    } else if (android != null) {
      ok = await android.requestNotificationsPermission() ?? false;
      if (ok) await requestExactAlarms();
    }
    return ok;
  }

  /// Su Android 12+ chiede di consentire le sveglie esatte (urgenze e dosi).
  Future<bool> requestExactAlarms() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    await android.requestExactAlarmsPermission();
    _exactAllowed = await android.canScheduleExactNotifications() ?? false;
    return _exactAllowed;
  }

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
        // I permessi si chiedono dopo il primo cane, spiegando a cosa
        // servono (vedi requestPermissions), non all'apertura dell'app.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: darwin,
          macOS: darwin,
        ),
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        _exactAllowed = await android.canScheduleExactNotifications() ?? false;
      } else {
        _exactAllowed = true; // iOS/macOS: sempre puntuali
      }
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
    String body, {
    bool exact = false,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(id: id);
      if (!when.isAfter(DateTime.now())) return;
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: _details,
        // Urgenze e dosi all'orario esatto anche in Doze (se l'utente ha
        // concesso le sveglie esatte su Android 12+); il resto può slittare.
        androidScheduleMode: exact && _exactAllowed
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
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

  /// Notifiche programmate in attesa nel sistema (per il collaudo).
  Future<List<PendingNotificationRequest>> pending() async =>
      _ready ? _plugin.pendingNotificationRequests() : const [];

  bool get ready => _ready;

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id: id);
  }
}
