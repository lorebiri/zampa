import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../store.dart';
import '../web/push_client.dart';

/// Configurazione Web Push: la chiave pubblica VAPID (la privata sta solo
/// nei segreti della Edge Function `invia-promemoria`).
class PushConfig {
  static const vapidPublicKey = String.fromEnvironment('VAPID_PUBLIC_KEY');
  static bool get enabled => vapidPublicKey.isNotEmpty;
}

/// Stato dei promemoria sul web, per l'interfaccia.
enum WebReminders {
  /// Questo dispositivo ha le notifiche locali (Android, iOS nativo).
  native,

  /// Il browser non sa ricevere notifiche push (o la build non le prevede).
  unsupported,

  /// iPhone/iPad in Safari: serve aprire l'app dalla schermata Home.
  needsHomeScreen,

  /// Serve l'account (i promemoria passano dal server).
  needsAccount,

  /// Tutto pronto: basta toccare «Attiva promemoria».
  ready,

  /// Attivi su questo browser.
  active,

  /// Permesso negato nel browser.
  denied,
}

/// Promemoria inviati dal server con Web Push (tabelle e funzioni in
/// supabase/migrations/2026-11-14_promemoria_web.sql).
class SupabaseReminderSink implements ReminderSink {
  SupabaseReminderSink(this.client);
  final SupabaseClient client;

  /// Iscrizione di questo browser, quando è attiva.
  PushSubscriptionInfo? subscription;

  @override
  bool get active => client.auth.currentUser != null && subscription != null;

  /// All'avvio: riprende l'iscrizione già data in passato.
  Future<void> restore() async {
    try {
      if (PushClient.permission != 'granted') return;
      subscription = await PushClient.current();
    } catch (e) {
      debugPrint('Iscrizione push non leggibile: $e');
    }
  }

  /// Da chiamare con un tocco dell'utente: permesso, iscrizione, salvataggio.
  Future<bool> enable() async {
    final sub = await PushClient.subscribe(PushConfig.vapidPublicKey);
    if (sub == null) return false;
    await client.rpc(
      'registra_dispositivo_push',
      params: {
        'p_endpoint': sub.endpoint,
        'p_p256dh': sub.p256dh,
        'p_auth': sub.auth,
      },
    );
    subscription = sub;
    return true;
  }

  /// Disattiva su questo browser e cancella i promemoria in coda.
  Future<void> disable() async {
    final sub = subscription;
    subscription = null;
    if (sub != null) {
      await client.rpc(
        'rimuovi_dispositivo_push',
        params: {'p_endpoint': sub.endpoint},
      );
    }
    await PushClient.unsubscribe();
  }

  @override
  Future<void> replace(
    List<PlannedNotification> planned, {
    List<PlannedNotification> urgent = const [],
  }) async {
    Map<String, Object?> row(PlannedNotification p, bool urgente) => {
      'id': p.id,
      'quando': p.when.toUtc().toIso8601String(),
      'titolo': p.title,
      'testo': p.body,
      'urgente': urgente,
    };
    await client.rpc(
      'sostituisci_promemoria',
      params: {
        'p_elementi': [
          for (final p in planned) row(p, false),
          for (final p in urgent) row(p, true),
        ],
      },
    );
  }

  /// Che cosa mostrare all'utente su questo dispositivo.
  WebReminders state({required bool nativeSupported}) => webRemindersState(
    nativeSupported: nativeSupported,
    pushSupported: PushClient.supported && PushConfig.enabled,
    isIos: PushClient.isIos,
    standalone: PushClient.standalone,
    signedIn: client.auth.currentUser != null,
    permission: PushClient.permission,
    subscribed: subscription != null,
  );
}

/// Decide lo stato dei promemoria sul web (funzione pura, testata).
WebReminders webRemindersState({
  required bool nativeSupported,
  required bool pushSupported,
  required bool isIos,
  required bool standalone,
  required bool signedIn,
  required String permission,
  required bool subscribed,
}) {
  if (nativeSupported) return WebReminders.native;
  // Su iPhone il push esiste solo con l'app aperta dalla schermata Home.
  if (isIos && !standalone) return WebReminders.needsHomeScreen;
  if (!pushSupported) return WebReminders.unsupported;
  if (permission == 'denied') return WebReminders.denied;
  if (!signedIn) return WebReminders.needsAccount;
  if (subscribed && permission == 'granted') return WebReminders.active;
  return WebReminders.ready;
}
