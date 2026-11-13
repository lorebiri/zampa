import 'dart:convert';
import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'logic/outing_geofence.dart' show OutingSuggestion;
import 'logic/quick_actions.dart';
import 'logic/quick_action_signal.dart';
import 'models.dart' show newId;

/// Promemoria locali (nessun server). Su web e desktop Linux/Windows le
/// notifiche programmate non sono supportate: l'app mostra il conto alla
/// rovescia e gli avvisi in primo piano.
///
/// Azioni rapide nel promemoria della pipì («Fatta ✓», «Non ancora»,
/// ricerca/28): dove la piattaforma non le ha (web, Linux, Windows) il
/// promemoria semplicemente non c'è o arriva senza bottoni, senza errori.
class Notifier {
  Notifier._();
  static final instance = Notifier._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _exactAllowed = false;

  /// Notifiche consentite dal sistema: null finché non si sa (o se la
  /// piattaforma non le supporta). La Home mostra «Notifiche spente» se false.
  final allowed = ValueNotifier<bool?>(null);

  /// Chiamata quando c'è almeno un'azione rapida nuova in coda (l'app la
  /// applica al diario e ai promemoria: vedi AppStore.applyQuickActions).
  Future<void> Function()? onQuickAction;

  /// Rilegge dal sistema se le notifiche sono consentite.
  Future<bool?> refreshAllowed() async {
    if (!supported || !_ready) return null;
    bool? ok;
    try {
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
        ok = (await ios.checkPermissions())?.isEnabled;
      } else if (mac != null) {
        ok = (await mac.checkPermissions())?.isEnabled;
      } else if (android != null) {
        ok = await android.areNotificationsEnabled();
      }
    } catch (e) {
      debugPrint('Stato del permesso non leggibile: $e');
    }
    allowed.value = ok;
    return ok;
  }

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
    // La risposta del plugin a volte è «no» anche se l'utente ha toccato
    // «Consenti» (rapporto 10, C5): conta lo stato reale del sistema.
    final real = await refreshAllowed();
    return ok || real == true;
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
      await _initPlugin(_plugin, foreground: _onForegroundResponse);
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
      await refreshAllowed();
      // Bottone toccato in background mentre l'app è aperta (Android).
      listenQuickActionSignal(_signalApp);
      // App aperta proprio da un bottone (iOS, dove l'azione apre l'app).
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final r = launch?.notificationResponse;
      if (launch?.didNotificationLaunchApp == true && r != null) {
        await _onForegroundResponse(r);
      }
    } catch (e) {
      debugPrint('Notifiche non disponibili: $e');
    }
  }

  static InitializationSettings get _settings {
    final darwin = DarwinInitializationSettings(
      // I permessi si chiedono dopo il primo cane, spiegando a cosa
      // servono (vedi requestPermissions), non all'apertura dell'app.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          QuickActions.category,
          actions: [
            // Su iOS l'azione apre l'app (foreground): così non serve un
            // isolato in background, che richiederebbe codice nativo in
            // AppDelegate per registrare i plugin (ricerca/28 §2).
            DarwinNotificationAction.plain(
              QuickActions.done,
              QuickActionTexts.done,
              options: {DarwinNotificationActionOption.foreground},
            ),
            DarwinNotificationAction.plain(
              QuickActions.notYet,
              QuickActionTexts.notYet,
              options: {DarwinNotificationActionOption.foreground},
            ),
          ],
        ),
      ],
    );
    return InitializationSettings(
      android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: darwin,
      macOS: darwin,
    );
  }

  static Future<void> _initPlugin(
    FlutterLocalNotificationsPlugin plugin, {
    DidReceiveNotificationResponseCallback? foreground,
  }) => plugin.initialize(
    settings: _settings,
    onDidReceiveNotificationResponse: foreground,
    onDidReceiveBackgroundNotificationResponse: luluNotificationBackground,
  );

  Future<void> _signalApp() async {
    try {
      await onQuickAction?.call();
    } catch (e) {
      debugPrint('Azione rapida non applicata: $e');
    }
  }

  /// Risposta arrivata all'app aperta (o aperta dal tocco).
  Future<void> _onForegroundResponse(NotificationResponse r) async {
    final queued = await handleResponse(r, plugin: _plugin);
    if (queued) await _signalApp();
  }

  /// Salva il tocco in coda (una chiave per azione in SharedPreferences) e,
  /// per «Non ancora», ripropone subito il promemoria tra 15 minuti. Non
  /// apre il diario: lo fa l'app (subito se è aperta, altrimenti al
  /// prossimo avvio). Vale sia nell'app sia nell'isolato in background.
  /// true se l'azione era nostra ed è stata messa in coda.
  static Future<bool> handleResponse(
    NotificationResponse r, {
    required FlutterLocalNotificationsPlugin plugin,
  }) async {
    final now = DateTime.now();
    final a = QuickAction.fromResponse(
      actionId: r.actionId,
      payload: r.payload,
      at: now,
      id: newId(),
    );
    if (a == null) return false;
    final prefs = await SharedPreferences.getInstance();
    await QuickActionQueue.add(prefs, a);
    if (a.kind == QuickActionKind.notYet) {
      final p = ReminderPayload.tryParse(r.payload)!;
      // 15 minuti: puntuale se l'utente ha concesso le sveglie esatte.
      var exact = true;
      try {
        final android = plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (android != null) {
          exact = await android.canScheduleExactNotifications() ?? false;
        }
      } catch (_) {
        exact = false;
      }
      await _scheduleOn(
        plugin,
        p.notificationId,
        now.add(QuickActions.snoozeDelay),
        QuickActionTexts.snoozeTitle(p.dogName),
        QuickActionTexts.snoozeBody,
        exact: exact,
        payload: r.payload,
        utc: true,
      );
    }
    return true;
  }

  static const _channel = 'zampa_promemoria';
  static const _channelName = 'Promemoria';
  static const _channelDesc = 'Uscite per la pipì, vaccini, farmaci';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channel,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  /// Promemoria dell'uscita per la pipì, con i bottoni. Stesso canale.
  static const _actionDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channel,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction(QuickActions.done, QuickActionTexts.done),
        AndroidNotificationAction(QuickActions.notYet, QuickActionTexts.notYet),
      ],
    ),
    iOS: DarwinNotificationDetails(categoryIdentifier: QuickActions.category),
    macOS: DarwinNotificationDetails(categoryIdentifier: QuickActions.category),
  );

  /// Programma (o riprogramma) un promemoria con id stabile. Con un
  /// [payload] di promemoria dell'uscita la notifica ha i bottoni rapidi.
  Future<void> schedule(
    int id,
    DateTime when,
    String title,
    String body, {
    bool exact = false,
    String? payload,
  }) async {
    if (!_ready) return;
    await _scheduleOn(
      _plugin,
      id,
      when,
      title,
      body,
      exact: exact && _exactAllowed,
      payload: payload,
    );
  }

  static Future<void> _scheduleOn(
    FlutterLocalNotificationsPlugin plugin,
    int id,
    DateTime when,
    String title,
    String body, {
    bool exact = false,
    String? payload,
    bool utc = false,
  }) async {
    try {
      await plugin.cancel(id: id);
      if (!when.isAfter(DateTime.now())) return;
      final withActions = ReminderPayload.tryParse(payload) != null;
      await plugin.zonedSchedule(
        id: id,
        // In background il fuso locale non è caricato: l'istante in UTC è
        // lo stesso (nessuna ripetizione «alla stessa ora»).
        scheduledDate: utc
            ? tz.TZDateTime.from(when.toUtc(), tz.UTC)
            : tz.TZDateTime.from(when, tz.local),
        notificationDetails: withActions ? _actionDetails : _details,
        // Urgenze e dosi all'orario esatto anche in Doze (se l'utente ha
        // concesso le sveglie esatte su Android 12+); il resto può slittare.
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
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

  /// Cancella tutte le notifiche programmate e mostrate.
  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    if (!_ready) return;
    await _plugin.cancel(id: id);
  }
}

/// Bottone della notifica toccato con l'app chiusa o in background (Android:
/// l'azione non apre l'app). Gira in un isolato a parte: qui NON si apre il
/// diario (l'app potrebbe scriverlo nello stesso momento e una delle due
/// scritture andrebbe persa). Si salva solo il tocco, con il suo orario, in
/// una chiave propria; l'app lo applica appena è aperta (subito se lo è già).
@pragma('vm:entry-point')
Future<void> luluNotificationBackground(NotificationResponse r) async {
  try {
    DartPluginRegistrant.ensureInitialized();
    final plugin = FlutterLocalNotificationsPlugin();
    await Notifier._initPlugin(plugin);
    final queued = await Notifier.handleResponse(r, plugin: plugin);
    if (queued) sendQuickActionSignal();
  } catch (e) {
    debugPrint('Azione rapida non salvata: $e');
  }
}

/// Coda delle azioni rapide in SharedPreferences: una chiave per tocco
/// (`lulu_qa_<id>`), scritta una volta e cancellata dopo l'applicazione.
class QuickActionQueue {
  QuickActionQueue._();

  static Future<void> add(SharedPreferences prefs, QuickAction a) =>
      prefs.setString('${QuickActions.prefsPrefix}${a.id}', _encode(a));

  static String _encode(QuickAction a) => jsonEncode(a.toJson());

  /// Rilegge dal disco (l'isolato in background scrive a parte) e restituisce
  /// le azioni in coda; le chiavi illeggibili si cancellano.
  static Future<List<QuickAction>> read(SharedPreferences prefs) async {
    try {
      await prefs.reload();
    } catch (_) {}
    final out = <QuickAction>[];
    for (final k in prefs.getKeys().toList()) {
      if (!k.startsWith(QuickActions.prefsPrefix)) continue;
      final raw = prefs.getString(k);
      final a = raw == null ? null : QuickAction.tryFromJson(raw);
      if (a == null) {
        await prefs.remove(k);
      } else {
        out.add(a);
      }
    }
    return out;
  }

  static Future<void> remove(
    SharedPreferences prefs,
    Iterable<String> ids,
  ) async {
    for (final id in ids) {
      await prefs.remove('${QuickActions.prefsPrefix}$id');
    }
  }
}

/// Testi per l'utente dei bottoni rapidi (ricerca/28).
class QuickActionTexts {
  QuickActionTexts._();

  static const done = 'Fatta ✓';
  static const notYet = 'Non ancora';

  static String snoozeTitle(String name) =>
      'Ancora da fare: uscita con $name 🐾';

  static const snoozeBody =
      'Hai scelto «Non ancora» 15 minuti fa. Se è già uscito, tocca «Fatta ✓».';

  /// Domanda dopo un'uscita rilevata con il recinto intorno a casa (solo
  /// progettata: la lettura della posizione non è ancora nell'app).
  /// Non registra nulla: l'utente sceglie «Pipì», «Cacca» o niente.
  static String outingQuestion(OutingSuggestion s) {
    final n = s.outing.minutes;
    final dur = n == 1 ? '1 minuto' : '$n minuti';
    return 'Sei uscito con ${s.dogName} alle ${s.startHm} per $dur: '
        'ha fatto pipì? cacca?';
  }
}
