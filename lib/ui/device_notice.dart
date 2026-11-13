import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../brand.dart';
import '../logic/alerts.dart';
import '../notifications.dart';
import 'common.dart';

/// Chiave dell'avviso già letto (per dispositivo).
const deviceNoticeKey = 'lulu_device_notice_v1';

/// Testo dell'avviso per i dispositivi senza promemoria programmati (web,
/// iPhone dal browser, desktop Linux/Windows).
const deviceNoticeText =
    'Su questo dispositivo $appName non può mandarti notifiche: promemoria, '
    'dosi e allarmi li vedi quando apri l\'app. Per riceverli installa '
    '$appName su Android. Su iPhone aggiungi $appName alla schermata Home '
    '(Condividi › Aggiungi alla schermata Home): così i dati non vengono '
    'cancellati da Safari dopo qualche settimana senza aprirla.';

/// Avviso, una volta per dispositivo, quando i promemoria non arrivano come
/// notifiche. Senza, chi usa la web app crederebbe di essere avvisato.
class DeviceNotice extends StatefulWidget {
  const DeviceNotice({super.key, this.supported});

  /// Se il dispositivo programma le notifiche; null = chiedi a [Notifier].
  final bool? supported;

  @override
  State<DeviceNotice> createState() => _DeviceNoticeState();
}

class _DeviceNoticeState extends State<DeviceNotice> {
  bool _dismissed = true;

  bool get _supported => widget.supported ?? Notifier.instance.supported;

  @override
  void initState() {
    super.initState();
    if (!_supported) _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(deviceNoticeKey) ?? false;
      if (mounted) setState(() => _dismissed = seen);
    } catch (e) {
      debugPrint('Avviso dispositivo: $e');
      if (mounted) setState(() => _dismissed = false);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(deviceNoticeKey, true);
    } catch (e) {
      debugPrint('Avviso dispositivo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_supported || _dismissed) return const SizedBox.shrink();
    return NoticeCard(
      deviceNoticeText,
      level: AlertLevel.info,
      tag: 'PROMEMORIA',
      child: Align(
        alignment: Alignment.centerRight,
        child: TextButton(onPressed: _dismiss, child: const Text('Ho capito')),
      ),
    );
  }
}
