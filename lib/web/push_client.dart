/// Notifiche Web Push nel browser (web app e iPhone con Lulù sulla Home).
///
/// Su Android, iOS nativo e nei test si usa la versione vuota
/// ([push_client_stub.dart]): lì i promemoria sono notifiche locali.
library;

export 'push_client_stub.dart'
    if (dart.library.js_interop) 'push_client_web.dart';

/// Iscrizione Web Push da salvare sul server (chiavi in base64url).
class PushSubscriptionInfo {
  const PushSubscriptionInfo({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
  });
  final String endpoint;
  final String p256dh;
  final String auth;

  Map<String, Object?> toJson() => {
    'endpoint': endpoint,
    'p256dh': p256dh,
    'auth': auth,
  };
}
