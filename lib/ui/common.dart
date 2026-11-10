import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../logic/alerts.dart';
import '../models.dart';
import '../store.dart';
import 'emergency_screen.dart';

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);

  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

/// Contenitore centrato a larghezza massima, per tablet, web e desktop.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.padding});
  final List<Widget> children;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: ListView(
        padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: children,
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class AlertCard extends StatelessWidget {
  const AlertCard(this.alert, {super.key});
  final HealthAlert alert;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final (bg, fg, icon, label) = switch (alert.level) {
      AlertLevel.subito => (s.error, s.onError, Icons.emergency, 'SUBITO'),
      AlertLevel.oggi => (
        s.errorContainer,
        s.onErrorContainer,
        Icons.local_hospital_outlined,
        'OGGI',
      ),
      AlertLevel.attenzione => (
        const Color(0xFFFFE9C7),
        const Color(0xFF5A3A00),
        Icons.warning_amber_rounded,
        'ATTENZIONE',
      ),
      AlertLevel.info => (
        s.secondaryContainer,
        s.onSecondaryContainer,
        Icons.info_outline,
        null,
      ),
    };
    final urgent =
        alert.level == AlertLevel.subito || alert.level == AlertLevel.oggi;
    final dog = StoreScope.read(context).dog;
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Text(
                    alert.title,
                    style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  if (alert.actionText != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        alert.actionText!,
                        style: TextStyle(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(alert.message, style: TextStyle(color: fg)),
                  if (urgent) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (dog != null && dog.vetPhone.isNotEmpty)
                          FilledButton.tonalIcon(
                            icon: const Icon(Icons.call),
                            label: const Text('Chiama il veterinario'),
                            onPressed: () => callNumber(context, dog.vetPhone),
                          ),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.emergency),
                          label: const Text('Emergenze'),
                          onPressed: () => openEmergencies(context),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apre il compositore telefonico (su web/desktop può non essere disponibile).
Future<void> callNumber(BuildContext context, String number) async {
  final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) toast(context, 'Chiama il numero $number');
}

void openEmergencies(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const EmergencyScreen()));

/// "tra 1 h 20 min", "5 min fa".
String relative(DateTime t, DateTime now) {
  final d = t.difference(now);
  final past = d.isNegative;
  final m = d.inMinutes.abs();
  String txt;
  if (m < 1) {
    return 'adesso';
  } else if (m < 60) {
    txt = '$m min';
  } else if (m < 60 * 24) {
    final h = m ~/ 60, r = m % 60;
    txt = r == 0 ? '$h h' : '$h h $r min';
  } else {
    final days = (m / 1440).round();
    txt = days == 1 ? '1 giorno' : '$days giorni';
  }
  return past ? '$txt fa' : 'tra $txt';
}

String dayLabel(DateTime t, DateTime now) {
  final a = DateTime(t.year, t.month, t.day);
  final b = DateTime(now.year, now.month, now.day);
  final diff = a.difference(b).inDays;
  if (diff == 0) return 'oggi';
  if (diff == 1) return 'domani';
  if (diff == -1) return 'ieri';
  return dmy(t);
}

String whenLabel(DateTime t, DateTime now) => '${dayLabel(t, now)} ${hm(t)}';

Future<DateTime?> pickDateTime(BuildContext context, DateTime initial) async {
  final d = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(1995),
    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
  );
  if (d == null || !context.mounted) return null;
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (t == null) {
    return DateTime(d.year, d.month, d.day, initial.hour, initial.minute);
  }
  return DateTime(d.year, d.month, d.day, t.hour, t.minute);
}

Future<DateTime?> pickDate(BuildContext context, DateTime initial) =>
    showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1995),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
}

const disclaimer =
    'Zampa aiuta a osservare e organizzare: non fa diagnosi e non sostituisce '
    'la visita veterinaria. In emergenza (fatica a respirare, gengive pallide '
    'o blu, addome gonfio con conati a vuoto, collasso, convulsioni, sospetto '
    'avvelenamento, sforzo a urinare senza risultato, colpo di calore) '
    'contatta subito il veterinario o il pronto soccorso veterinario più '
    'vicino.';

/// Icone (le emoji non sono affidabili sul web senza rete).
extension LogTypeIcon on LogType {
  IconData get icon => switch (this) {
    LogType.pipi => Icons.water_drop,
    LogType.cacca => Icons.grass,
    LogType.pasto => Icons.restaurant,
    LogType.acqua => Icons.local_drink,
    LogType.risveglio => Icons.wb_sunny_outlined,
    LogType.gioco => Icons.sports_baseball_outlined,
    LogType.passeggiata => Icons.directions_walk,
    LogType.vomito => Icons.sick_outlined,
    LogType.inappetenza => Icons.no_meals_outlined,
    LogType.abbattimento => Icons.bedtime_outlined,
    LogType.respiro => Icons.air,
    LogType.tosse => Icons.masks_outlined,
    LogType.gengive => Icons.mood,
    LogType.convulsione => Icons.bolt,
    LogType.zoppia => Icons.accessible_forward,
    LogType.pelle => Icons.pest_control_outlined,
    LogType.neuro => Icons.cyclone,
    LogType.temperatura => Icons.thermostat,
    LogType.perditaRiposo => Icons.water_damage_outlined,
    LogType.perditeVulvari => Icons.female,
    LogType.ingestione => Icons.dangerous_outlined,
    LogType.insulina => Icons.vaccines_outlined,
    LogType.glicemia => Icons.bloodtype_outlined,
    LogType.denti => Icons.clean_hands_outlined,
    LogType.collasso => Icons.personal_injury_outlined,
    LogType.addomeGonfio => Icons.circle_outlined,
    LogType.mammelle => Icons.child_friendly_outlined,
    LogType.ferita => Icons.healing_outlined,
  };
}

extension RecordTypeIcon on RecordType {
  IconData get icon => switch (this) {
    RecordType.vaccino => Icons.vaccines,
    RecordType.antiparassitario => Icons.bug_report_outlined,
    RecordType.farmaco => Icons.medication_outlined,
    RecordType.visita => Icons.medical_services_outlined,
    RecordType.esame => Icons.science_outlined,
    RecordType.intervento => Icons.local_hospital_outlined,
    RecordType.sintomo => Icons.sick_outlined,
    RecordType.nota => Icons.sticky_note_2_outlined,
  };
}
