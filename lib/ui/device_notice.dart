import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../brand.dart';
import '../logic/alerts.dart';
import '../notifications.dart';
import '../sync/push_reminders.dart';
import '../web/push_client.dart';
import 'common.dart';

/// Chiave dell'avviso già letto (per dispositivo); per gli stati diversi da
/// «non supportato» si aggiunge il nome dello stato, così un avviso nuovo
/// (per esempio «Attiva promemoria» dopo l'accesso) compare di nuovo.
const deviceNoticeKey = 'lulu_device_notice_v1';

/// Testo dell'avviso per i dispositivi senza promemoria (browser senza
/// notifiche push, desktop Linux/Windows).
const deviceNoticeText =
    'Su questo dispositivo $appName non può mandarti notifiche: promemoria, '
    'dosi e allarmi li vedi quando apri l\'app. Per riceverli installa '
    '$appName su Android. Su iPhone aggiungi $appName alla schermata Home '
    '(Condividi › Aggiungi alla schermata Home): così i dati non vengono '
    'cancellati da Safari dopo qualche settimana senza aprirla.';

const deviceNoticeHomeText =
    'Su iPhone i promemoria arrivano solo con $appName sulla schermata Home: '
    'tocca Condividi › Aggiungi alla schermata Home e aprila da lì. Così '
    'Safari non cancella nemmeno i tuoi dati se non la apri per un po\'.';

const deviceNoticeAccountText =
    'Per ricevere uscite, dosi, vaccini e allarmi anche ad app chiusa entra '
    'con l\'account (Profilo › Account e famiglia): sul web i promemoria '
    'partono dal server.';

const deviceNoticeReadyText =
    'Attiva i promemoria: ti avvisiamo per uscite, dosi, vaccini e allarmi '
    'anche quando $appName è chiusa.';

const deviceNoticeDeniedText =
    'Le notifiche di $appName sono bloccate nel browser: riattivale dalle '
    'impostazioni del sito per ricevere promemoria e allarmi.';

/// Promemoria del browser in uso (impostato in main.dart, solo sul web con
/// account e chiave VAPID).
SupabaseReminderSink? appReminders;

/// Avviso sui promemoria per i dispositivi senza notifiche locali (web,
/// iPhone): spiega cosa manca e, quando si può, attiva le notifiche push.
class DeviceNotice extends StatefulWidget {
  const DeviceNotice({super.key, this.supported, this.state, this.onEnable});

  /// Se il dispositivo programma le notifiche; null = chiedi a [Notifier].
  final bool? supported;

  /// Stato da mostrare (per i test); null = calcolato.
  final WebReminders? state;

  /// Attivazione dei promemoria (per i test); null = [appReminders].
  final Future<bool> Function()? onEnable;

  @override
  State<DeviceNotice> createState() => _DeviceNoticeState();
}

class _DeviceNoticeState extends State<DeviceNotice> {
  bool _dismissed = true;
  bool _busy = false;

  WebReminders get _state {
    if (widget.state != null) return widget.state!;
    final native = widget.supported ?? Notifier.instance.supported;
    if (native) return WebReminders.native;
    final sink = appReminders;
    if (sink != null) return sink.state(nativeSupported: false);
    if (widget.supported == null &&
        PushClient.isIos &&
        !PushClient.standalone) {
      return WebReminders.needsHomeScreen;
    }
    return WebReminders.unsupported;
  }

  String _key(WebReminders s) => s == WebReminders.unsupported
      ? deviceNoticeKey
      : '${deviceNoticeKey}_${s.name}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = _state;
    if (s == WebReminders.native || s == WebReminders.active) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_key(s)) ?? false;
      if (mounted) setState(() => _dismissed = seen);
    } catch (e) {
      debugPrint('Avviso dispositivo: $e');
      if (mounted) setState(() => _dismissed = false);
    }
  }

  Future<void> _dismiss() async {
    final s = _state;
    setState(() => _dismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(s), true);
    } catch (e) {
      debugPrint('Avviso dispositivo: $e');
    }
  }

  Future<void> _enable() async {
    setState(() => _busy = true);
    var ok = false;
    try {
      final enable =
          widget.onEnable ?? () async => await appReminders?.enable() ?? false;
      ok = await enable();
      if (ok && mounted) await StoreScope.read(context).replan();
    } catch (e) {
      debugPrint('Promemoria web: $e');
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _dismissed = true;
    });
    toast(
      context,
      ok
          ? 'Promemoria attivi su questo dispositivo'
          : 'Promemoria non attivati: controlla il permesso delle notifiche',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    if (_dismissed || s == WebReminders.native || s == WebReminders.active) {
      return const SizedBox.shrink();
    }
    final text = switch (s) {
      WebReminders.needsHomeScreen => deviceNoticeHomeText,
      WebReminders.needsAccount => deviceNoticeAccountText,
      WebReminders.ready => deviceNoticeReadyText,
      WebReminders.denied => deviceNoticeDeniedText,
      _ => deviceNoticeText,
    };
    return NoticeCard(
      text,
      level: AlertLevel.info,
      tag: 'PROMEMORIA',
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton(
              onPressed: _busy ? null : _dismiss,
              child: Text(s == WebReminders.ready ? 'Non ora' : 'Ho capito'),
            ),
            if (s == WebReminders.ready)
              FilledButton.icon(
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Attiva promemoria'),
                onPressed: _busy ? null : _enable,
              ),
          ],
        ),
      ),
    );
  }
}
