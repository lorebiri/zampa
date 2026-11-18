import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../logic/alerts.dart';
import '../models.dart';
import '../store.dart';
import '../brand.dart';
import 'emergency_screen.dart';
import 'theme.dart';

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
        padding:
            padding ??
            const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 112),
        children: children,
      ),
    ),
  );
}

/// Titolo di sezione: un'intestazione vera per i lettori di schermo.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, Space.xl, 0, Space.s),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Intestazione grande di una pagina (Nutrizione, Profilo…).
class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, Space.s, 4, Space.s),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.headlineMedium),
    ),
  );
}

/// Forma di un livello: SUBITO è un blocco pieno, OGGI ha una banda spessa
/// e il bordo, ATTENZIONE una banda sottile, INFO nessuna banda. Così il
/// livello si riconosce da posizione, forma, parola e icona, non solo dal
/// colore (rapporto 16, P2 e §5.4).
class _ToneBox extends StatelessWidget {
  const _ToneBox({required this.level, required this.child});
  final AlertLevel level;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tone = context.colors.tone(level);
    final stripe = switch (level) {
      AlertLevel.subito => 0.0,
      AlertLevel.oggi => 8.0,
      AlertLevel.attenzione => 5.0,
      AlertLevel.info => 0.0,
    };
    final border = switch (level) {
      AlertLevel.subito => BorderSide(color: tone.accent, width: 3),
      AlertLevel.oggi => BorderSide(color: tone.accent, width: 1.5),
      AlertLevel.attenzione => BorderSide(
        color: tone.accent.withValues(alpha: 0.6),
      ),
      AlertLevel.info => BorderSide.none,
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: ShapeDecoration(
        color: tone.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.alert),
          side: border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (stripe > 0) Container(width: stripe, color: tone.accent),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Riga "icona + PAROLA DEL LIVELLO", grande e in grassetto.
class LevelTag extends StatelessWidget {
  const LevelTag(this.level, {super.key, this.text});
  final AlertLevel level;

  /// Parola alternativa (es. "IN RITARDO").
  final String? text;

  @override
  Widget build(BuildContext context) {
    final tone = context.colors.tone(level);
    final label = text ?? tone.label;
    final iconSize = switch (level) {
      AlertLevel.subito => 30.0,
      AlertLevel.oggi => 26.0,
      _ => 24.0,
    };
    final iconColor = level == AlertLevel.subito ? tone.fg : tone.accent;
    return Row(
      children: [
        Icon(tone.icon, color: iconColor, size: iconSize),
        if (label != null) ...[
          const SizedBox(width: Space.s),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: fontFamily,
                color: tone.fg,
                fontSize: level == AlertLevel.subito ? 18 : 16,
                height: 1.2,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard(this.alert, {super.key});
  final HealthAlert alert;

  @override
  Widget build(BuildContext context) {
    final tone = context.colors.tone(alert.level);
    final fg = tone.fg;
    final t = Theme.of(context).textTheme;
    final urgent =
        alert.level == AlertLevel.subito || alert.level == AlertLevel.oggi;
    final dog = StoreScope.read(context).dog;
    // Pulsanti a colori invertiti rispetto alla scheda: contrasto alto in
    // entrambi i temi.
    final strong = FilledButton.styleFrom(
      backgroundColor: fg,
      foregroundColor: tone.bg,
    );
    final soft = OutlinedButton.styleFrom(
      foregroundColor: fg,
      side: BorderSide(color: fg, width: 1.5),
    );
    final levelName = tone.label?.toLowerCase();
    return Semantics(
      container: true,
      liveRegion: alert.level == AlertLevel.subito,
      label: levelName == null ? null : 'Allarme livello $levelName',
      child: _ToneBox(
        level: alert.level,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, 14, Space.l, Space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tone.label != null) ...[
                LevelTag(alert.level),
                const SizedBox(height: Space.s),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tone.label == null) ...[
                    Icon(tone.icon, color: tone.accent),
                    const SizedBox(width: Space.m),
                  ],
                  Expanded(
                    child: Text(
                      alert.title,
                      style: t.titleMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.xs),
              if (alert.actionText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: Text(
                    alert.actionText!,
                    style: t.bodyLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(alert.message, style: t.bodyMedium?.copyWith(color: fg)),
              if (urgent) ...[
                const SizedBox(height: Space.m),
                Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  children: [
                    if (dog != null && dog.vetPhone.isNotEmpty)
                      FilledButton.icon(
                        style: strong,
                        icon: const Icon(Icons.call),
                        label: const Text('Chiama il veterinario'),
                        onPressed: () => callNumber(context, dog.vetPhone),
                      ),
                    OutlinedButton.icon(
                      style: soft,
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
      ),
    );
  }
}

/// Avviso testuale con il tono di un livello (sostituisce le schede con il
/// fondo crema fisso, illeggibili in tema scuro: rapporto 16, P1).
class NoticeCard extends StatelessWidget {
  const NoticeCard(
    this.text, {
    super.key,
    this.level = AlertLevel.attenzione,
    this.tag,
    this.child,
  });
  final String text;
  final AlertLevel level;

  /// Parola del livello da mostrare sopra il testo (es. "IN RITARDO").
  final String? tag;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final tone = context.colors.tone(level);
    final t = Theme.of(context).textTheme;
    return _ToneBox(
      level: level,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, Space.m, Space.l, Space.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tag != null) ...[
              LevelTag(level, text: tag),
              const SizedBox(height: Space.s),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tag == null) ...[
                  Icon(tone.icon, color: tone.accent),
                  const SizedBox(width: Space.m),
                ],
                Expanded(
                  child: Text(
                    text,
                    style: t.bodyMedium?.copyWith(color: tone.fg),
                  ),
                ),
              ],
            ),
            ?child,
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

Future<DateTime?> pickDate(
  BuildContext context,
  DateTime initial, {
  DateTime? lastDate,
}) {
  final last = lastDate ?? DateTime.now().add(const Duration(days: 365 * 5));
  return showDatePicker(
    context: context,
    initialDate: initial.isAfter(last) ? last : initial,
    firstDate: DateTime(1995),
    lastDate: last,
  );
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
}

const disclaimer =
    '$appName aiuta a osservare e organizzare: non fa diagnosi e non sostituisce '
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
    LogType.segnale => Icons.sensor_door_outlined,
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
