import 'push_client.dart';

/// Versione senza browser: nessuna notifica Web Push.
class PushClient {
  static bool get supported => false;
  static bool get standalone => false;
  static bool get isIos => false;

  /// 'default', 'granted', 'denied' o 'unsupported'.
  static String get permission => 'unsupported';

  static Future<PushSubscriptionInfo?> subscribe(String vapidPublicKey) async =>
      null;
  static Future<PushSubscriptionInfo?> current() async => null;
  static Future<void> unsubscribe() async {}
}
