import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/prevention.dart';
import '../models.dart';
import '../store.dart';
import 'common.dart';
import 'diaries_screen.dart';

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final dog = store.dog!;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Salute di ${dog.name}'),
          actions: [
            IconButton(
              tooltip: 'Copia cartella per il veterinario',
              icon: const Icon(Icons.ios_share),
              onPressed: () => _showReport(context, store, dog),
            ),
          ],
          bottom: const TabBar(
            // Scorrevole: regge testo grande e altre lingue (P13).
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Scadenze'),
              Tab(text: 'Cartella'),
              Tab(text: 'Peso'),
              Tab(text: 'Diari'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.add),
          label: const Text('Aggiungi'),
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => RecordFormPage(dog: dog))),
        ),
        body: TabBarView(
          children: [
            _DueTab(dog: dog),
            _RecordsTab(dog: dog),
            _WeightTab(dog: dog),
            DiariesTab(dog: dog),
          ],
        ),
      ),
    );
  }

  void _showReport(BuildContext context, AppStore store, Dog dog) {
    final text = store.healthReport(dog);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cartella per il veterinario'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chiudi'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copia'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: text));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                toast(
                  context,
                  'Cartella copiata: incollala in una mail o in chat',
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DueTab extends StatelessWidget {
  const _DueTab({required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final due = dueItems(store.records, dog.id);
    final suggestions = PreventionPlanner.suggest(dog, store.records, now);
    return PageBody(
      children: [
        if (suggestions.isNotEmpty)
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Piano di prevenzione suggerito',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${suggestions.length == 1 ? '1 appuntamento consigliato' : '${suggestions.length} appuntamenti consigliati'} per ${dog.name} secondo le linee guida '
                    'WSAVA (vaccini) ed ESCCAP Italia (parassiti). Le date vanno confermate con il veterinario.',
                  ),
                  const SizedBox(height: 8),
                  for (final s in suggestions.take(4))
                    Text(
                      '• ${s.title} – ${dmy(s.date)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (suggestions.length > 4)
                    Text(
                      '• … e altri ${suggestions.length - 4}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () async {
                      await store.addRecords(suggestions);
                      if (context.mounted) {
                        toast(context, 'Piano aggiunto alle scadenze');
                      }
                    },
                    child: const Text('Aggiungi al calendario'),
                  ),
                ],
              ),
            ),
          ),
        if (due.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Nessuna scadenza. Aggiungi vaccini e trattamenti con la data del prossimo richiamo.',
            ),
          ),
        for (final d in due)
          Card(
            child: ListTile(
              leading: Icon(d.record.type.icon),
              title: Text(d.record.title),
              subtitle: Text(
                [
                  d.overdue(now)
                      ? 'SCADUTA ${relative(d.due, now)}'
                      : '${dmy(d.due)} · ${relative(d.due, now)}',
                  if (d.record.notes.isNotEmpty && !d.record.done)
                    d.record.notes,
                ].join('\n'),
                style: TextStyle(
                  color: d.overdue(now)
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
              isThreeLine: d.record.notes.isNotEmpty && !d.record.done,
              trailing: IconButton(
                tooltip: 'Fatto',
                icon: const Icon(Icons.check_circle_outline),
                onPressed: () => _markDone(context, store, d),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecordFormPage(dog: dog, record: d.record),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _markDone(
    BuildContext context,
    AppStore store,
    DueItem d,
  ) async {
    final now = DateTime.now();
    final r = d.record;
    final title = r.title.replaceAll(RegExp(r' \(stagione \d+\)'), '');
    final interval = PreventionPlanner.suggestedInterval(
      r,
      dog: StoreScope.read(context).dog,
      at: now,
    );
    final next = interval == null ? null : now.add(interval);
    if (r.done) {
      // Scadenza di una voce fatta: crea una nuova voce eseguita oggi.
      await store.upsertRecord(
        HealthRecord(
          id: newId(),
          dogId: r.dogId,
          type: r.type,
          title: title,
          date: now,
          dose: r.dose,
          nextDue: next,
          drugEffect: r.drugEffect,
        ),
      );
    } else {
      r
        ..done = true
        ..date = now
        ..nextDue = next;
      await store.upsertRecord(r);
    }
    if (context.mounted) {
      toast(
        context,
        next == null
            ? 'Segnato come fatto'
            : 'Fatto. Prossima scadenza proposta: ${dmy(next)}',
      );
    }
  }
}

class _RecordsTab extends StatelessWidget {
  const _RecordsTab({required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final recs = store.recordsOf(dog.id).where((r) => r.done).toList();
    final t = Theme.of(context);
    return PageBody(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scheda', style: t.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Microchip: ${dog.microchip.isEmpty ? '—' : dog.microchip}',
                ),
                Text(
                  'Veterinario: ${dog.vetName.isEmpty ? '—' : dog.vetName}${dog.vetPhone.isNotEmpty ? ' · ${dog.vetPhone}' : ''}',
                ),
                Text(
                  'Allergie: ${dog.allergies.isEmpty ? 'nessuna nota' : dog.allergies}',
                ),
                Text(
                  'Patologie note: ${dog.conditions.isEmpty ? 'nessuna' : dog.conditions}',
                ),
              ],
            ),
          ),
        ),
        if (recs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('La cartella è vuota.'),
          ),
        for (final r in recs)
          Card(
            child: ListTile(
              leading: Icon(r.type.icon),
              title: Text(r.title),
              subtitle: Text(
                [
                  '${r.type.label} · ${dmy(r.date)}',
                  if (r.dose.isNotEmpty) r.dose,
                  if (r.everyHours != null)
                    'ogni ${r.everyHours} h${r.endDate != null ? ' fino al ${dmy(r.endDate!)}' : ''}',
                  if (r.notes.isNotEmpty) r.notes,
                ].join(' · '),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecordFormPage(dog: dog, record: r),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _WeightTab extends StatelessWidget {
  const _WeightTab({required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final ws = store.weightsOf(dog.id);
    final t = Theme.of(context);
    return PageBody(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dog.weightKg.toStringAsFixed(1)} kg',
                  style: t.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text('Body Condition Score ${dog.bodyCondition}/9'),
                const SizedBox(height: 12),
                if (ws.length >= 2)
                  SizedBox(
                    height: 150,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _WeightPainter(
                        ws,
                        t.colorScheme.primary,
                        t.textTheme.bodySmall!,
                      ),
                    ),
                  )
                else
                  const Text(
                    'Aggiungi almeno due pesate per vedere l\'andamento.',
                  ),
              ],
            ),
          ),
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.monitor_weight_outlined),
          label: const Text('Nuova pesata'),
          onPressed: () async {
            final c = TextEditingController();
            final kg = await showDialog<double>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Peso di oggi'),
                content: TextField(
                  controller: c,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(suffixText: 'kg'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annulla'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(
                      ctx,
                      double.tryParse(c.text.replaceAll(',', '.')),
                    ),
                    child: const Text('Salva'),
                  ),
                ],
              ),
            );
            if (kg != null && kg > 0) {
              await store.addWeight(dog.id, kg, DateTime.now());
            }
          },
        ),
        const SizedBox(height: 8),
        for (final w in ws.reversed)
          ListTile(
            dense: true,
            title: Text('${w.kg.toStringAsFixed(1)} kg'),
            subtitle: Text(dmy(w.date)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => store.deleteWeight(w.id),
            ),
          ),
      ],
    );
  }
}

class _WeightPainter extends CustomPainter {
  _WeightPainter(this.ws, this.color, this.text);
  final List<WeightEntry> ws;
  final Color color;
  final TextStyle text;

  @override
  void paint(Canvas canvas, Size size) {
    final minKg = ws.map((w) => w.kg).reduce(math.min) * 0.97;
    final maxKg = ws.map((w) => w.kg).reduce(math.max) * 1.03;
    final t0 = ws.first.date, t1 = ws.last.date;
    final span = math.max(1, t1.difference(t0).inHours);
    const left = 36.0;
    Offset pt(WeightEntry w) => Offset(
      left + (size.width - left - 8) * w.date.difference(t0).inHours / span,
      (size.height - 16) * (1 - (w.kg - minKg) / (maxKg - minKg)),
    );
    final path = Path()..moveTo(pt(ws.first).dx, pt(ws.first).dy);
    for (final w in ws.skip(1)) {
      path.lineTo(pt(w).dx, pt(w).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (final w in ws) {
      canvas.drawCircle(pt(w), 3.5, Paint()..color = color);
    }
    for (final v in [minKg, maxKg]) {
      final tp = TextPainter(
        text: TextSpan(
          text: v.toStringAsFixed(1),
          style: text.copyWith(fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(0, (size.height - 16) * (1 - (v - minKg) / (maxKg - minKg)) - 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeightPainter old) => old.ws != ws;
}

class RecordFormPage extends StatefulWidget {
  const RecordFormPage({super.key, required this.dog, this.record});
  final Dog dog;
  final HealthRecord? record;

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  late RecordType type = widget.record?.type ?? RecordType.vaccino;
  late final title = TextEditingController(text: widget.record?.title ?? '');
  late final dose = TextEditingController(text: widget.record?.dose ?? '');
  late final notes = TextEditingController(text: widget.record?.notes ?? '');
  late final vet = TextEditingController(text: widget.record?.vet ?? '');
  late final every = TextEditingController(
    text: widget.record?.everyHours?.toString() ?? '',
  );
  late final cost = TextEditingController(
    text: widget.record?.cost?.toString() ?? '',
  );
  late DateTime date = widget.record?.date ?? DateTime.now();
  late bool done = widget.record?.done ?? true;
  late DateTime? nextDue = widget.record?.nextDue;
  late DateTime? endDate = widget.record?.endDate;
  late DrugEffect effect = widget.record?.drugEffect ?? DrugEffect.nessuno;

  static const _presets = {
    RecordType.vaccino: [
      'Vaccino core (cimurro, epatite, parvovirosi)',
      'Leptospirosi',
      'Rabbia',
      'Tosse dei canili',
      'Leishmaniosi',
    ],
    RecordType.antiparassitario: [
      'Antiparassitario esterno (zecche e pulci)',
      'Prevenzione filariosi',
      'Sverminazione',
      'Repellente anti-pappataci (spot-on)',
      'Collare repellente',
      'Filariosi iniettabile 6 mesi',
      'Filariosi iniettabile 12 mesi',
    ],
    RecordType.visita: [
      'Visita di controllo annuale',
      'Controllo geriatrico semestrale',
      'Visita specialistica',
    ],
    RecordType.esame: [
      'Esami del sangue',
      'Esame delle urine',
      'Esame delle feci',
      'Test filaria/leishmania',
      'Ecografia',
      'Radiografia',
    ],
  };

  @override
  Widget build(BuildContext context) {
    final isTherapy = type == RecordType.farmaco;
    final presets = _presets[type] ?? const <String>[];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.record == null ? 'Nuova voce' : 'Modifica voce'),
        actions: [
          if (widget.record != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await StoreScope.read(context).deleteRecord(widget.record!.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: PageBody(
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final rt in RecordType.values)
                ChoiceChip(
                  avatar: Icon(rt.icon, size: 18),
                  label: Text(rt.label),
                  selected: type == rt,
                  onSelected: (_) => setState(() => type = rt),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Titolo / nome'),
            onChanged: (v) {
              if (isTherapy) setState(() => effect = DrugEffectLabel.guess(v));
            },
          ),
          if (presets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final p in presets)
                    ActionChip(
                      label: Text(p, style: const TextStyle(fontSize: 12)),
                      onPressed: () => setState(() {
                        title.text = p;
                        final iv = PreventionPlanner.suggestedInterval(
                          HealthRecord(
                            id: '',
                            dogId: '',
                            type: type,
                            title: p,
                            date: date,
                          ),
                          dog: widget.dog,
                          at: date,
                        );
                        if (iv != null && done) nextDue = date.add(iv);
                      }),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Già fatto'),
            subtitle: Text(
              done ? 'Voce della cartella' : 'Appuntamento futuro',
            ),
            value: done,
            onChanged: (v) => setState(() => done = v),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(
              '${done ? 'Data' : 'Previsto il'}: ${dmy(date)}${isTherapy ? ' ${hm(date)}' : ''}',
            ),
            onTap: () async {
              final d = isTherapy
                  ? await pickDateTime(context, date)
                  : await pickDate(context, date);
              if (d != null) setState(() => date = d);
            },
          ),
          if (done && !isTherapy)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(
                'Prossima scadenza: ${nextDue == null ? 'nessuna' : dmy(nextDue!)}',
              ),
              subtitle: const Text(
                'Riceverai un promemoria 3 giorni prima e il giorno stesso',
              ),
              trailing: nextDue == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => nextDue = null),
                    ),
              onTap: () async {
                final d = await pickDate(
                  context,
                  nextDue ?? date.add(const Duration(days: 365)),
                );
                if (d != null) setState(() => nextDue = d);
              },
            ),
          if (type == RecordType.farmaco ||
              type == RecordType.antiparassitario ||
              type == RecordType.vaccino) ...[
            const SizedBox(height: 8),
            TextField(
              controller: dose,
              decoration: const InputDecoration(
                labelText: 'Dose (es. 1/2 compressa, 5 mg)',
              ),
            ),
          ],
          if (isTherapy) ...[
            const SizedBox(height: 12),
            TextField(
              controller: every,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ogni quante ore',
                helperText: 'Es. 12 = due volte al giorno. Ricevi un promemoria a ogni dose.',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy),
              title: Text(
                'Fine terapia: ${endDate == null ? 'non definita' : dmy(endDate!)}',
              ),
              onTap: () async {
                final d = await pickDate(
                  context,
                  endDate ?? date.add(const Duration(days: 7)),
                );
                if (d != null) {
                  setState(
                    () => endDate = DateTime(d.year, d.month, d.day, 23, 59),
                  );
                }
              },
            ),
            DropdownButtonFormField<DrugEffect>(
              initialValue: effect,
              decoration: const InputDecoration(
                labelText: 'Effetto sui bisogni',
                helperText: 'Usato dal modello di previsione (riconosciuto in automatico dai nomi più comuni)',
              ),
              items: [
                for (final e in DrugEffect.values)
                  DropdownMenuItem(value: e, child: Text(e.label)),
              ],
              onChanged: (v) =>
                  setState(() => effect = v ?? DrugEffect.nessuno),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: vet,
            decoration: const InputDecoration(
              labelText: 'Veterinario / struttura (facoltativo)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Costo (facoltativo)',
              suffixText: '€',
              helperText: 'Utile per la detrazione delle spese veterinarie',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note, esito, referto',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              if (title.text.trim().isEmpty) {
                toast(context, 'Inserisci un titolo');
                return;
              }
              final r =
                  widget.record ??
                  HealthRecord(
                    id: newId(),
                    dogId: widget.dog.id,
                    type: type,
                    title: '',
                    date: date,
                  );
              r
                ..type = type
                ..title = title.text.trim()
                ..date = date
                ..done = done
                ..nextDue = done ? nextDue : null
                ..dose = dose.text.trim()
                ..everyHours = isTherapy ? int.tryParse(every.text) : null
                ..endDate = isTherapy ? endDate : null
                ..drugEffect = isTherapy ? effect : DrugEffect.nessuno
                ..notes = notes.text.trim()
                ..vet = vet.text.trim()
                ..cost = double.tryParse(cost.text.replaceAll(',', '.'));
              await StoreScope.read(context).upsertRecord(r);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}
