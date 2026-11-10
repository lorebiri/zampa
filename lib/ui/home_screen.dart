import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/alerts.dart';
import '../logic/bio_params.dart';
import '../logic/elimination_model.dart';
import '../logic/potty_predictor.dart';
import '../logic/prevention.dart';
import '../logic/seasonal.dart';
import '../logic/weather.dart';
import '../models.dart';
import '../store.dart';
import 'common.dart';
import 'avatar_editor.dart';
import 'avatar.dart';
import 'log_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onOpenTab});
  final void Function(int) onOpenTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick?.cancel();
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
        .where((r) => r.dogId == dog.id && r.isActiveTherapy(now))
        .toList();

    return PageBody(
      children: [
        DogHeader(dog: dog),
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
            Card(
              color: now.difference(p.at).inMinutes >= 120
                  ? const Color(0xFFFFE9C7)
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                child: Row(
                  children: [
                    const Icon(Icons.medication),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${p.record.title}${p.record.dose.isNotEmpty ? ' · ${p.record.dose}' : ''}\n'
                        'prevista ${whenLabel(p.at, now)}',
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          store.confirmDose(p.record, p.at, DoseStatus.dato),
                      child: const Text('Dato'),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      onPressed: () =>
                          store.confirmDose(p.record, p.at, DoseStatus.saltato),
                      child: const Text('Saltato'),
                    ),
                  ],
                ),
              ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: t.colorScheme.primaryContainer,
            child: Text(
              dog.name.isEmpty ? '?' : dog.name[0].toUpperCase(),
              style: t.textTheme.headlineSmall?.copyWith(
                color: t.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dog.name,
                  style: t.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  [
                    if (dog.breed.isNotEmpty) dog.breed,
                    ageLabel(dog),
                    '${dog.weightKg.toStringAsFixed(1)} kg',
                    switch (lifeStageOf(dog)) {
                      LifeStage.cucciolo => 'cucciolo',
                      LifeStage.giovane => 'giovane',
                      LifeStage.adulto => 'adulto',
                      LifeStage.anziano => 'anziano',
                    },
                  ].join(' · '),
                  style: t.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Emergenze',
            icon: Icon(Icons.emergency, color: t.colorScheme.error),
            onPressed: () => openEmergencies(context),
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
        ],
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
    final bg = urgent
        ? t.colorScheme.tertiaryContainer
        : t.colorScheme.primaryContainer;
    final fg = urgent
        ? t.colorScheme.onTertiaryContainer
        : t.colorScheme.onPrimaryContainer;
    final confLabel = switch (f.confidence) {
      Confidence.bassa => 'Sto imparando',
      Confidence.media => 'Affidabilità media',
      Confidence.alta => 'Affidabilità alta',
    };
    return Card(
      color: bg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(isPee ? Icons.water_drop : Icons.grass, color: fg),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isPee ? 'Prossima pipì' : 'Prossima cacca',
                      style: t.textTheme.titleMedium?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(confLabel),
                    side: BorderSide.none,
                    backgroundColor: t.colorScheme.surface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (f.last == null)
                Text(f.reason, style: TextStyle(color: fg))
              else ...[
                Text(
                  f.overdue ? 'Adesso' : 'Esci alle ${hm(f.recommendedAt)}',
                  style: t.textTheme.displaySmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  f.overdue
                      ? 'Ultima ${relative(f.last!, now)}'
                      : '${relative(f.recommendedAt, now)}${dayLabel(f.recommendedAt, now) != 'oggi' ? ' (${dayLabel(f.recommendedAt, now)})' : ''} · ultima ${relative(f.last!, now)}',
                  style: TextStyle(color: fg),
                ),
                const SizedBox(height: 8),
                Text(
                  'Finestra probabile ${hm(f.windowStart)}–${hm(f.windowEnd)} · '
                  'probabilità nella prossima ora ${(f.probNextHour * 100).round()}%',
                  style: t.textTheme.bodySmall?.copyWith(color: fg),
                ),
                const SizedBox(height: 4),
                Text(
                  f.reason,
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (f.factors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Fattori considerati: ${f.factors.join(', ')}',
                      style: t.textTheme.bodySmall?.copyWith(color: fg),
                    ),
                  ),
              ],
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.check),
                    label: const Text('Fatta fuori'),
                    onPressed: () => quickLog(context, dog, f.need.logType),
                  ),
                  OutlinedButton.icon(
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in items)
          ActionChip(
            avatar: Icon(t.icon, size: 18),
            label: Text(t.label),
            onPressed: () => quickLog(context, dog, t),
          ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('Con dettagli…'),
          onPressed: () => showLogSheet(context, dog, LogType.pipi),
        ),
      ],
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
      child: Padding(
        padding: const EdgeInsets.all(14),
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
