import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/alerts.dart';
import '../logic/bio_params.dart';
import '../logic/elimination_model.dart';
import '../logic/potty_predictor.dart';
import '../logic/prevention.dart';
import '../logic/seasonal.dart';
import '../logic/weather.dart';
import '../brand.dart';
import '../models.dart';
import '../notifications.dart';
import '../store.dart';
import 'common.dart';
import 'avatar_editor.dart';
import 'dog_wizard.dart';
import 'avatar.dart';
import 'log_sheet.dart';
import 'theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenTab});
  final void Function(int) onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _tick;
  AppLifecycleListener? _life;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
    // Chi torna dalle Impostazioni dopo aver acceso le notifiche deve vedere
    // sparire l'avviso, e i promemoria vanno riprogrammati.
    _life = AppLifecycleListener(
      onResume: () async {
        final was = Notifier.instance.allowed.value;
        final now = await Notifier.instance.refreshAllowed();
        if (was != true && now == true && mounted) {
          await StoreScope.read(context).replan();
        }
      },
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _life?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final dog = store.dog!;
    final now = DateTime.now();
    final pee = store.forecast(dog, Need.pipi, now);
    final poop = store.forecast(dog, Need.cacca, now);
    final alerts = AlertEngine.compute(
      dog: dog,
      logs: store.logs,
      records: store.records,
      weights: store.weights,
      now: now,
      repro: store.repro,
      pendingDoses: store.pendingDoses(dog.id, now),
    );
    final pending = store.pendingDoses(dog.id, now);
    final postOps =
        store.records
            .where(
              (r) =>
                  r.dogId == dog.id &&
                  r.type == RecordType.intervento &&
                  r.done &&
                  !r.date.isAfter(now) &&
                  now.difference(r.date).inDays < 14,
            )
            .map((r) => r.date)
            .toList()
          ..sort();
    final postOpSince = postOps.isEmpty ? null : postOps.last;
    final tips = [
      ...Breeds.puppy(dog, now),
      ...SeasonalTips.forDog(dog, now),
      ...Breeds.predispositions(dog),
      ?Breeds.neuteringInfo(dog, now),
    ];
    final due = dueItems(store.records, dog.id).take(3).toList();
    final therapies = store.records
        .where(
          (r) =>
              r.dogId == dog.id &&
              (r.isActiveTherapy(now) ||
                  // Terapie che iniziano più avanti (rapporto 10, B1).
                  (r.date.isAfter(now) && r.isActiveTherapy(r.date))),
        )
        .toList();

    return PageBody(
      children: [
        DogHeader(dog: dog),
        if (isDemoId(dog.id)) const _DemoBanner(),
        if (!isDemoId(dog.id)) const _NotificationsOffBanner(),
        // Le urgenze vengono prima del compagno: una cosa seria non deve
        // sembrare un gioco (revisione veterinaria).
        for (final a in alerts.where(
          (a) => a.level == AlertLevel.subito || a.level == AlertLevel.oggi,
        ))
          AlertCard(a),
        PetScreen(
          dog: dog,
          pee: pee,
          alerts: alerts,
          onEdit: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => AvatarEditorPage(dog: dog))),
        ),
        for (final a in alerts.where((a) => a.level == AlertLevel.attenzione))
          AlertCard(a),
        if (postOpSince != null) PostOpCard(dog: dog, since: postOpSince),
        FutureBuilder<String?>(
          future: Weather.heatWarning(dog, pee.recommendedAt),
          builder: (_, snap) => snap.data == null
              ? const SizedBox.shrink()
              : AlertCard(
                  HealthAlert(
                    AlertLevel.attenzione,
                    'Meteo all\'ora dell\'uscita',
                    snap.data!,
                    action: '',
                  ),
                ),
        ),
        ForecastCard(forecast: pee, dog: dog, onTap: () => widget.onOpenTab(1)),
        ForecastCard(
          forecast: poop,
          dog: dog,
          onTap: () => widget.onOpenTab(1),
        ),
        const SectionTitle('Registra con un tocco'),
        QuickActions(dog: dog),
        if (pending.isNotEmpty) ...[
          const SectionTitle('Dosi da confermare'),
          for (final p in pending)
            _DoseCard(
              text:
                  '${p.record.title}${p.record.dose.isNotEmpty ? ' · ${p.record.dose}' : ''}\n'
                  'prevista ${whenLabel(p.at, now)}',
              late: now.difference(p.at).inMinutes >= 120,
              onGiven: () => store.confirmDose(p.record, p.at, DoseStatus.dato),
              onSkipped: () =>
                  store.confirmDose(p.record, p.at, DoseStatus.saltato),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Se hai saltato una dose non raddoppiare la successiva: chiedi al veterinario cosa fare.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        if (therapies.isNotEmpty) ...[
          const SectionTitle('Terapie in corso'),
          for (final r in therapies)
            Card(
              child: ListTile(
                leading: const Icon(Icons.medication_outlined),
                title: Text(
                  '${r.title}${r.dose.isNotEmpty ? ' · ${r.dose}' : ''}',
                ),
                subtitle: Text(() {
                  final n = AppStore.nextDose(r, now);
                  final base = n == null
                      ? 'Terapia in chiusura'
                      : 'Prossima dose ${whenLabel(n, now)} (${relative(n, now)})';
                  final eff = r.drugEffect == DrugEffect.nessuno
                      ? DrugEffectLabel.guess(r.title)
                      : r.drugEffect;
                  // 07 tabella I: il diuretico serale non va spostato da soli.
                  if (eff == DrugEffect.diuretico &&
                      n != null &&
                      n.hour >= 18) {
                    return '$base\nNon spostare né saltare il diuretico per ridurre '
                        'le uscite notturne: chiedi al veterinario se si può dare al mattino.';
                  }
                  return base;
                }()),
              ),
            ),
        ],
        SectionTitle(
          'Prossime scadenze',
          trailing: TextButton(
            onPressed: () => widget.onOpenTab(2),
            child: const Text('Tutte'),
          ),
        ),
        if (due.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Nessuna scadenza'),
              subtitle: const Text(
                'Crea il piano di prevenzione nella sezione Salute',
              ),
              onTap: () => widget.onOpenTab(2),
            ),
          ),
        for (final d in due)
          Card(
            child: ListTile(
              leading: Icon(d.record.type.icon),
              title: Text(d.record.title),
              subtitle: Text(
                d.overdue(now)
                    ? 'Scaduta ${relative(d.due, now)}'
                    : '${dmy(d.due)} · ${relative(d.due, now)}',
                style: TextStyle(
                  color: d.overdue(now)
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
            ),
          ),
        for (final a in alerts.where((a) => a.level == AlertLevel.info))
          AlertCard(a),
        if (tips.isNotEmpty) ...[
          const SectionTitle('Da sapere'),
          for (final tip in tips)
            Card(
              child: ListTile(
                leading: Icon(
                  tip.icon == 'warning'
                      ? Icons.wb_sunny_outlined
                      : Icons.lightbulb_outline,
                ),
                title: Text(tip.title),
                subtitle: Text(tip.text),
              ),
            ),
        ],
        const SizedBox(height: 12),
        Text(
          disclaimer,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class DogHeader extends StatelessWidget {
  const DogHeader({super.key, required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    final s = t.colorScheme;
    final c = context.colors;
    final bigText = MediaQuery.textScalerOf(context).scale(10) > 13;
    // Il pulsante Emergenze ha sempre la parola, non solo l'icona (P14).
    final emergency = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: c.subito.bg,
        foregroundColor: c.subito.fg,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
      ),
      icon: const Icon(Icons.emergency, size: 20),
      label: const Text('Emergenze'),
      onPressed: () => openEmergencies(context),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, Space.s, 0, Space.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.dark ? Palette.nightMustard : Palette.mustard,
                    borderRadius: BorderRadius.circular(Radii.field),
                  ),
                  child: Text(
                    dog.name.isEmpty ? '?' : dog.name[0].toUpperCase(),
                    style: t.textTheme.headlineSmall?.copyWith(
                      color: Palette.mustardInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        dog.name,
                        style: t.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      [
                        if (dog.breed.isNotEmpty) dog.breed,
                        ageLabel(dog),
                        // Spazio indivisibile: "14.2 kg" non va a capo.
                        '${dog.weightKg.toStringAsFixed(1)}\u00A0kg',
                        switch (lifeStageOf(dog)) {
                          LifeStage.cucciolo => 'cucciolo',
                          LifeStage.giovane => 'giovane',
                          LifeStage.adulto => 'adulto',
                          LifeStage.anziano => 'anziano',
                        },
                      ].join(' · '),
                      style: t.textTheme.bodyMedium?.copyWith(
                        color: s.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (store.dogs.length > 1)
                PopupMenuButton<String>(
                  tooltip: 'Cambia cane',
                  icon: const Icon(Icons.swap_horiz),
                  onSelected: store.selectDog,
                  itemBuilder: (_) => [
                    for (final d in store.dogs)
                      PopupMenuItem(value: d.id, child: Text(d.name)),
                  ],
                ),
              if (!bigText) ...[const SizedBox(width: Space.s), emergency],
            ],
          ),
          if (bigText) ...[const SizedBox(height: Space.m), emergency],
        ],
      ),
    );
  }
}

/// Dose da confermare: testo sopra, pulsanti grandi e separati sotto, così
/// regge il testo al 200% e "Saltato" non si tocca per sbaglio (P1, P11).
class _DoseCard extends StatelessWidget {
  const _DoseCard({
    required this.text,
    required this.late,
    required this.onGiven,
    required this.onSkipped,
  });
  final String text;
  final bool late;
  final VoidCallback onGiven;
  final VoidCallback onSkipped;

  /// «Saltato» chiede conferma: una dose segnata saltata per sbaglio falsa il
  /// diario della terapia. «Dato» resta con un solo tocco.
  Future<void> _confirmSkip(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dose saltata?'),
        content: const Text('Confermi che questa dose non è stata data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sì, saltata'),
          ),
        ],
      ),
    );
    if (ok == true) onSkipped();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final buttons = Padding(
      padding: const EdgeInsets.only(top: Space.m),
      child: Wrap(
        spacing: Space.m,
        runSpacing: Space.s,
        children: [
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Dato'),
            onPressed: onGiven,
          ),
          OutlinedButton(
            onPressed: () => _confirmSkip(context),
            child: const Text('Saltato'),
          ),
        ],
      ),
    );
    if (late) {
      return NoticeCard(
        text,
        level: AlertLevel.attenzione,
        tag: 'IN RITARDO',
        child: buttons,
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medication, color: t.colorScheme.primary),
                const SizedBox(width: Space.m),
                Expanded(child: Text(text, style: t.textTheme.bodyLarge)),
              ],
            ),
            buttons,
          ],
        ),
      ),
    );
  }
}

class ForecastCard extends StatelessWidget {
  const ForecastCard({
    super.key,
    required this.forecast,
    required this.dog,
    this.onTap,
    this.big = false,
  });
  final Forecast forecast;
  final Dog dog;
  final VoidCallback? onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final f = forecast;
    final t = Theme.of(context);
    final now = DateTime.now();
    final isPee = f.need == Need.pipi;
    final urgent = f.overdue || f.recommendedAt.difference(now).inMinutes <= 15;
    final c = context.colors;
    // "È quasi ora" usa la senape del brand, mai i colori degli allarmi:
    // un'uscita imminente non è un problema di salute.
    final bg = urgent
        ? (c.dark ? Palette.nightMustardSoft : Palette.mustardSoft)
        : t.colorScheme.primaryContainer;
    final fg = urgent
        ? t.colorScheme.onTertiaryContainer
        : t.colorScheme.onPrimaryContainer;
    // Nessuna «affidabilità» né percentuale: la previsione di base è una
    // regola trasparente, non una promessa di precisione (piano CEO 11.3).
    final learning = f.confidence == Confidence.bassa;
    final usual = [
      for (final m in f.usualMinutes)
        '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}',
    ];
    final muted = fg.withValues(alpha: 0.85);
    return Card(
      color: bg,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.hero),
        side: urgent
            ? BorderSide(
                color: c.dark ? Palette.nightMustard : Palette.mustard,
                width: 2,
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isPee ? Icons.water_drop : Icons.grass, color: fg),
                  const SizedBox(width: Space.s),
                  Expanded(
                    child: Text(
                      isPee ? 'Prossima pipì' : 'Prossima cacca',
                      style: t.textTheme.titleMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (learning) ...[
                const SizedBox(height: Space.xs),
                Row(
                  children: [
                    Icon(Icons.school_outlined, size: 16, color: muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Sto imparando',
                        style: t.textTheme.labelMedium?.copyWith(color: muted),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: Space.m),
              if (f.last == null)
                Text(f.reason, style: TextStyle(color: fg))
              else if (!isPee) ...[
                // Cacca: solo le abitudini, nessun orario puntuale.
                if (usual.isNotEmpty)
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Di solito verso le ',
                          style: t.textTheme.titleLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: usual.join(' e '),
                          style: t.textTheme.headlineMedium?.copyWith(
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    f.reason,
                    style: t.textTheme.bodyMedium?.copyWith(color: fg),
                  ),
                const SizedBox(height: Space.xs),
                Text(
                  'Ultima ${relative(f.last!, now)}',
                  style: t.textTheme.bodyLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else ...[
                if (f.overdue)
                  Text(
                    'Adesso',
                    style: t.textTheme.displayMedium?.copyWith(color: fg),
                  )
                else
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Esci alle ',
                          style: t.textTheme.titleLarge?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(
                          text: hm(f.recommendedAt),
                          style: t.textTheme.displayMedium?.copyWith(color: fg),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: Space.xs),
                Text(
                  f.overdue
                      ? 'Ultima ${relative(f.last!, now)}'
                      : '${relative(f.recommendedAt, now)}${dayLabel(f.recommendedAt, now) != 'oggi' ? ' (${dayLabel(f.recommendedAt, now)})' : ''} · ultima ${relative(f.last!, now)}',
                  style: t.textTheme.bodyLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: Space.m),
                Text(
                  'Di solito tra le ${hm(f.windowStart)} e le ${hm(f.windowEnd)}',
                  style: t.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: Space.xs),
                Text(
                  f.reason,
                  style: t.textTheme.bodyMedium?.copyWith(color: fg),
                ),
                if (f.factors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.xs),
                    child: Text(
                      'Fattori considerati: ${f.factors.join(', ')}',
                      style: t.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
              ],
              const SizedBox(height: Space.l),
              Wrap(
                spacing: Space.m,
                runSpacing: Space.s,
                children: [
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(48, 56),
                      backgroundColor: c.dark ? Palette.nightInk : Palette.ink,
                      foregroundColor: c.dark
                          ? const Color(0xFF0B2545)
                          : Colors.white,
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Fatta fuori'),
                    onPressed: () => quickLog(context, dog, f.need.logType),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 56),
                      foregroundColor: fg,
                      side: BorderSide(color: fg.withValues(alpha: 0.6)),
                    ),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('In casa'),
                    onPressed: () =>
                        quickLog(context, dog, f.need.logType, indoor: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key, required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final items = [
      LogType.passeggiata,
      LogType.pasto,
      LogType.acqua,
      LogType.risveglio,
      LogType.gioco,
    ];
    Widget button(IconData icon, String label, VoidCallback onTap) =>
        _QuickButton(icon: icon, label: label, onTap: onTap);
    return Wrap(
      spacing: Space.s,
      runSpacing: Space.s,
      children: [
        for (final t in items)
          button(t.icon, t.label, () => quickLog(context, dog, t)),
        button(
          Icons.add,
          'Con dettagli…',
          () => showLogSheet(context, dog, LogType.pipi),
        ),
      ],
    );
  }
}

/// Pulsante di registrazione rapida: 48 dp, annunciato come pulsante.
class _QuickButton extends StatelessWidget {
  const _QuickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        backgroundColor: s.surfaceContainerLow,
        foregroundColor: s.onSurface,
        iconColor: s.primary,
        side: BorderSide(color: s.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.chip),
        ),
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

/// Modalità post-operatoria (revisione veterinaria 07, aggiunta N8).
class PostOpCard extends StatelessWidget {
  const PostOpCard({super.key, required this.dog, required this.since});
  final Dog dog;
  final DateTime since;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = now.difference(since).inDays + 1;
    final t = Theme.of(context);
    return Card(
      color: t.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.healing_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Convalescenza: giorno $day di 14',
                    style: t.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '• Riposo: uscite brevi al guinzaglio solo per i bisogni, niente '
              'corse, salti o scale.\n'
              '• Collare elisabettiano (o body) finché il veterinario non dice '
              'di toglierlo: non deve leccare la ferita.\n'
              '• Controlla la ferita due volte al giorno e registrala.\n'
              '• Prima pipì entro 24 ore; appetito di solito entro 24-48 ore.\n'
              '• Somministra solo i farmaci prescritti.',
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              icon: const Icon(Icons.healing_outlined),
              label: const Text('Controlla la ferita'),
              onPressed: () => showLogSheet(context, dog, LogType.ferita),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner fisso del cane di esempio: dati finti, nessuna notifica.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) => NoticeCard(
    'Questo è un cane di esempio: i dati sono inventati e non riceverai '
    'notifiche. Aggiungi il tuo cane per usare $appName davvero.',
    level: AlertLevel.info,
    tag: 'ESEMPIO',
    child: Padding(
      padding: const EdgeInsets.only(top: Space.s),
      child: FilledButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi il tuo cane'),
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DogWizardPage())),
      ),
    ),
  );
}

/// Avviso permanente e gratuito se il sistema blocca le notifiche: senza,
/// promemoria, dosi e allarmi non arrivano (CEO 11.4).
class _NotificationsOffBanner extends StatelessWidget {
  const _NotificationsOffBanner();

  Future<void> _enable(BuildContext context) async {
    final store = StoreScope.read(context);
    final ok = await Notifier.instance.requestPermissions();
    if (ok) {
      await store.replan();
      return;
    }
    // Già negato una volta: il sistema non chiede più, servono le Impostazioni.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await launchUrl(Uri.parse('app-settings:'));
    } else if (context.mounted) {
      toast(context, 'Attivale da Impostazioni › App › Zampa › Notifiche');
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool?>(
    valueListenable: Notifier.instance.allowed,
    builder: (context, allowed, _) => allowed != false
        ? const SizedBox.shrink()
        : NoticeCard(
            'Senza notifiche non ti avviseremo quando deve uscire, per le '
            'medicine e i vaccini, né se qualcosa richiede il veterinario.',
            level: AlertLevel.attenzione,
            tag: 'NOTIFICHE SPENTE',
            child: Padding(
              padding: const EdgeInsets.only(top: Space.s),
              child: FilledButton.icon(
                icon: const Icon(Icons.notifications_active_outlined),
                label: const Text('Attiva'),
                onPressed: () => _enable(context),
              ),
            ),
          ),
  );
}
