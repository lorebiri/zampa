import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'push_client.dart';

/// Versione per il browser, con il service worker dell'app (web/sw.js).
class PushClient {
  /// Il browser sa ricevere notifiche push (su iPhone: iOS 16.4+, e solo con
  /// l'app aperta dalla schermata Home).
  static bool get supported =>
      globalContext.has('PushManager') &&
      globalContext.has('Notification') &&
      web.window.navigator.has('serviceWorker');

  /// Aperta come app installata (schermata Home), non in una scheda.
  static bool get standalone {
    final nav = web.window.navigator as JSObject;
    final iosStandalone =
        nav.has('standalone') &&
        (nav['standalone'] as JSBoolean?)?.toDart == true;
    return iosStandalone ||
        web.window.matchMedia('(display-mode: standalone)').matches;
  }

  static bool get isIos {
    final ua = web.window.navigator.userAgent;
    return RegExp(r'iPhone|iPad|iPod').hasMatch(ua) ||
        (web.window.navigator.platform == 'MacIntel' &&
            web.window.navigator.maxTouchPoints > 1);
  }

  static String get permission => globalContext.has('Notification')
      ? web.Notification.permission
      : 'unsupported';

  /// Chiede il permesso e iscrive il browser. Va chiamata da un tocco
  /// dell'utente (Safari lo richiede). Null se il permesso è negato.
  static Future<PushSubscriptionInfo?> subscribe(String vapidPublicKey) async {
    if (!supported) return null;
    final perm = (await web.Notification.requestPermission().toDart).toDart;
    if (perm != 'granted') return null;
    final reg = await web.window.navigator.serviceWorker.ready.toDart;
    final existing = await reg.pushManager.getSubscription().toDart;
    final sub =
        existing ??
        await reg.pushManager
            .subscribe(
              web.PushSubscriptionOptionsInit(
                userVisibleOnly: true,
                applicationServerKey: _decode(vapidPublicKey).toJS,
              ),
            )
            .toDart;
    return _info(sub);
  }

  /// L'iscrizione già presente, se c'è.
  static Future<PushSubscriptionInfo?> current() async {
    if (!supported) return null;
    final reg = await web.window.navigator.serviceWorker.ready.toDart;
    final sub = await reg.pushManager.getSubscription().toDart;
    return sub == null ? null : _info(sub);
  }

  static Future<void> unsubscribe() async {
    if (!supported) return;
    final reg = await web.window.navigator.serviceWorker.ready.toDart;
    final sub = await reg.pushManager.getSubscription().toDart;
    if (sub != null) await sub.unsubscribe().toDart;
  }

  static PushSubscriptionInfo? _info(web.PushSubscription sub) {
    final p = sub.getKey('p256dh');
    final a = sub.getKey('auth');
    if (p == null || a == null) return null;
    return PushSubscriptionInfo(
      endpoint: sub.endpoint,
      p256dh: _encode(p.toDart.asUint8List()),
      auth: _encode(a.toDart.asUint8List()),
    );
  }

  static String _encode(Uint8List b) => base64Url.encode(b).replaceAll('=', '');

  static Uint8List _decode(String s) =>
      base64Url.decode(s.padRight((s.length + 3) ~/ 4 * 4, '='));
}
