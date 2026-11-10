import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/modules.dart';
import '../logic/potty_predictor.dart';
import '../models.dart';
import '../store.dart';
import 'common.dart';
import 'log_sheet.dart';
import 'pdf_export.dart';

/// Hub dei diari clinici e degli strumenti (revisione veterinaria 06).
class DiariesTab extends StatelessWidget {
  const DiariesTab({super.key, required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final diabetic = Modules.diabetic(dog, store.records);
    final epileptic = Modules.epileptic(dog, store.logs);
    final cardiac = Modules.cardiac(dog, store.records);
    final female = dog.sex == Sex.femmina;
    final senior = lifeStageOf(dog, now) == LifeStage.anziano;
    Widget tile(
      IconData i,
      String title,
      String sub,
      Widget page, {
      bool highlight = false,
    }) => Card(
      color: highlight
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
      child: ListTile(
        leading: Icon(i),
        title: Text(title),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
      ),
    );
    return PageBody(
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Esporta PDF per il veterinario'),
            subtitle: const Text(
              'Cartella, terapie, grafici di pipì, cacca, acqua e peso, allarmi',
            ),
            onTap: () => exportPdf(context, store, dog),
          ),
        ),
        tile(
          Icons.monitor_heart_outlined,
          'Cuore e respiro',
          'Conta i respiri nel sonno con il timer (ACVIM)',
          BreathingPage(dog: dog),
          highlight: cardiac,
        ),
        tile(
          Icons.bloodtype_outlined,
          'Diabete',
          'Diario insulina e glicemie',
          DiabetesPage(dog: dog),
          highlight: diabetic,
        ),
        tile(
          Icons.bolt,
          'Epilessia',
          'Diario delle crisi e andamento mensile',
          EpilepsyPage(dog: dog),
          highlight: epileptic,
        ),
        if (female)
          tile(
            Icons.female,
            'Calori e riproduzione',
            'Calori, accoppiamenti, parto presunto',
            ReproPage(dog: dog),
          ),
        tile(
          Icons.favorite_outline,
          'Qualità della vita',
          'Scala HHHHHMM per il cane anziano o malato',
          QolPage(dog: dog),
          highlight: senior,
        ),
        tile(
          Icons.elderly,
          'Muscoli e cambiamenti cognitivi',
          'Massa muscolare (WSAVA) e checklist dei cambiamenti dell\'anziano',
          SeniorScalesPage(dog: dog),
          highlight: senior,
        ),
        tile(
          Icons.science_outlined,
          'Esami con valori',
          'Andamento nel tempo rispetto al range del laboratorio',
          LabsPage(dog: dog),
        ),
        tile(
          Icons.flight_takeoff,
          'Viaggi',
          'Checklist per il passaporto europeo',
          TravelPage(dog: dog),
        ),
        tile(
          Icons.euro,
          'Spese veterinarie',
          'Totale annuo e stima della detrazione',
          ExpensesPage(dog: dog),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key, required this.dog});
  final Dog dog;
  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage> {
  Timer? timer;
  int left = 30;
  int seconds = 30;
  int taps = 0;
  bool running = false;

  void start() {
    setState(() {
      running = true;
      left = seconds;
      taps = 0;
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => left--);
      if (left <= 0) {
        t.cancel();
        setState(() => running = false);
        // Con meno di 4 tocchi la misura non è affidabile (07 N44).
        if (taps < 4) {
          toast(context, 'Pochi respiri contati: misura non salvata. Riprova.');
        } else {
          _save(taps * (60 ~/ seconds));
        }
      }
    });
  }

  Future<void> _save(int perMin) async {
    await StoreScope.read(context).addLog(
      LogEntry(
        id: newId(),
        dogId: widget.dog.id,
        type: LogType.respiro,
        time: DateTime.now(),
        value: perMin.toDouble(),
      ),
    );
    if (mounted) toast(context, 'Registrati $perMin respiri al minuto');
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    final rows = store
        .logsOf(widget.dog.id)
        .where((l) => l.type == LogType.respiro && l.value != null)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Cuore e respiro')),
      body: PageBody(
        children: [
          const Text(
            'Conta i respiri mentre dorme tranquillo (non dopo il gioco né al caldo): ogni volta che '
            'il torace si alza tocca il pulsante. Con il timer da 30 secondi il risultato viene '
            'raddoppiato. Normale sotto 30 al minuto (ACVIM 2019).',
          ),
          const SizedBox(height: 12),
          Center(
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30 secondi')),
                ButtonSegment(value: 60, label: Text('60 secondi')),
              ],
              selected: {seconds},
              onSelectionChanged: running
                  ? null
                  : (v) => setState(() => seconds = v.first),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: FilledButton(
                style: FilledButton.styleFrom(shape: const CircleBorder()),
                onPressed: running ? () => setState(() => taps++) : start,
                child: Text(
                  running ? '$taps\n${left}s' : 'Inizia',
                  textAlign: TextAlign.center,
                  style: t.textTheme.headlineMedium?.copyWith(
                    color: t.colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SectionTitle('Misure'),
          if (rows.isEmpty) const Text('Ancora nessuna misura.'),
          for (final l in rows.take(30))
            ListTile(
              dense: true,
              leading: Icon(
                Icons.air,
                color: l.value! > 40
                    ? t.colorScheme.error
                    : l.value! > 30
                    ? t.colorScheme.tertiary
                    : null,
              ),
              title: Text('${l.value!.round()} respiri/min'),
              trailing: Text(whenLabel(l.time, DateTime.now())),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class DiabetesPage extends StatelessWidget {
  const DiabetesPage({super.key, required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final logs = store.logsOf(dog.id);
    final ins = logs.where((l) => l.type == LogType.insulina).toList();
    final glu = logs
        .where((l) => l.type == LogType.glicemia && l.value != null)
        .toList();
    final water7 = logs.where(
      (l) =>
          l.type == LogType.acqua &&
          l.amountMl != null &&
          now.difference(l.time).inDays < 7,
    );
    // Media sui giorni effettivamente registrati (07 N45).
    final waterDays = {
      for (final l in water7) DateTime(l.time.year, l.time.month, l.time.day),
    }.length;
    final waterPerDay = water7.isEmpty
        ? null
        : water7.fold<double>(0, (a, l) => a + l.amountMl!) / waterDays;
    return Scaffold(
      appBar: AppBar(title: const Text('Diabete')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Insulina o glicemia'),
        onPressed: () => showLogSheet(context, dog, LogType.insulina),
      ),
      body: PageBody(
        children: [
          // Blocco visivo contro la doppia insulina (07 aggiunta N2).
          if (ins.isNotEmpty && now.difference(ins.first.time).inHours < 10)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.check_circle),
                title: Text(
                  'Insulina già fatta alle ${hm(ins.first.time)}'
                  '${ins.first.value != null ? ' (${ins.first.value!.toStringAsFixed(1)} UI)' : ''}',
                ),
                subtitle: const Text(
                  'Prima di farla, chiedi in famiglia: due persone che fanno '
                  'l\'iniezione è un errore frequente.',
                ),
              ),
            ),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Se non ha mangiato o ha vomitato, non fare l\'insulina senza aver sentito il veterinario.\n\n'
                'Ipoglicemia (debolezza, tremori, barcollamento, convulsioni): se è cosciente strofina '
                'miele o glucosio sulle gengive, mai liquidi in bocca a un cane incosciente, poi subito '
                'dal veterinario.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Text(
            'Le unità sono quelle prescritte dal veterinario: Zampa le registra, non le calcola. '
            'Acqua, pipì e peso sono gli indicatori di controllo (AAHA 2018).',
          ),
          const SectionTitle('Indicatori'),
          Text(
            'Acqua media ultimi 7 giorni: ${waterPerDay == null ? '—' : '${waterPerDay.round()} ml/giorno '
                      '(${(waterPerDay / dog.weightKg).round()} ml/kg)'}',
          ),
          Text('Peso attuale: ${dog.weightKg.toStringAsFixed(1)} kg'),
          if (glu.length >= 2) ...[
            const SectionTitle('Glicemie'),
            SizedBox(
              height: 120,
              child: _Spark(values: glu.reversed.map((l) => l.value!).toList()),
            ),
          ],
          const SectionTitle('Somministrazioni'),
          if (ins.isEmpty) const Text('Nessuna somministrazione registrata.'),
          for (final l in ins.take(40))
            ListTile(
              dense: true,
              leading: const Icon(Icons.vaccines_outlined),
              title: Text(
                '${l.value?.toStringAsFixed(1) ?? '?'} unità'
                '${l.signs.contains(Sign.nonHaMangiato) ? ' · NON aveva mangiato' : ''}',
              ),
              trailing: Text(whenLabel(l.time, now)),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class EpilepsyPage extends StatelessWidget {
  const EpilepsyPage({super.key, required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final seizures = store
        .logsOf(dog.id)
        .where((l) => l.type == LogType.convulsione)
        .toList();
    final months = Modules.seizuresPerMonth(store.logs, dog.id, now);
    final maxC = math.max(1, months.map((m) => m.count).fold(0, math.max));
    const names = [
      'gen',
      'feb',
      'mar',
      'apr',
      'mag',
      'giu',
      'lug',
      'ago',
      'set',
      'ott',
      'nov',
      'dic',
    ];
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Diario delle crisi')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Registra una crisi'),
        onPressed: () => showLogSheet(context, dog, LogType.convulsione),
      ),
      body: PageBody(
        children: [
          const Text(
            'Durante una crisi: non mettere le mani in bocca, allontana gli oggetti, abbassa le luci e '
            'cronometra. Oltre 5 minuti, oppure 2 crisi in 24 ore: subito dal veterinario (IVETF 2015).',
          ),
          const SectionTitle('Crisi per mese'),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final m in months)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${m.count}'),
                        Container(
                          height: 80.0 * m.count / maxC,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: t.colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          names[m.month.month - 1],
                          style: t.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SectionTitle('Crisi registrate'),
          if (seizures.isEmpty) const Text('Nessuna crisi registrata.'),
          for (final l in seizures)
            ListTile(
              leading: const Icon(Icons.bolt),
              title: Text(
                '${dmy(l.time)} ${hm(l.time)} · ${l.value == null ? 'durata ?' : '${l.value!.toStringAsFixed(1)} min'}',
              ),
              subtitle: Text(
                [
                  ...l.signs.map((s) => s.label),
                  if (l.note.isNotEmpty) l.note,
                ].join(' · '),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class ReproPage extends StatelessWidget {
  const ReproPage({super.key, required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final ev = Modules.reproOf(store.repro, dog.id).reversed.toList();
    final next = Modules.nextHeat(dog, store.repro);
    final due = Modules.dueDate(dog, store.repro, now);
    final last = Modules.lastHeat(dog, store.repro);
    return Scaffold(
      appBar: AppBar(title: const Text('Calori e riproduzione')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Aggiungi'),
        onPressed: () => _add(context, store),
      ),
      body: PageBody(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ultimo calore: ${last == null ? '—' : dmy(last)}'),
                  Text(
                    'Prossimo calore stimato: ${next == null ? '—' : dmy(next)} '
                    '(ogni ~${Modules.heatIntervalDays(dog, store.repro)} giorni)',
                  ),
                  if (due != null)
                    Text(
                      'Parto presunto: ${dmy(due)} (± 5 giorni)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  if (last != null && !dog.neutered) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Gravidanza isterica possibile tra ${dmy(last.add(const Duration(days: 42)))} e '
                      '${dmy(last.add(const Duration(days: 63)))}. Fino a ${dmy(last.add(const Duration(days: 84)))} '
                      'attenzione ai segni di piometra (sete, pipì, perdite, abbattimento).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (due != null && due.difference(now).inDays <= 5)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Scheda parto: prepara la cassa parto in un luogo tranquillo e caldo. Chiama subito il '
                  'veterinario se le contrazioni forti durano oltre 30 minuti senza cuccioli, se passano '
                  'oltre 2 ore tra un cucciolo e l\'altro, se ci sono perdite verdi o nere senza cuccioli, '
                  'o se la gravidanza supera i 70 giorni. Dopo il parto: tremori o agitazione possono '
                  'indicare eclampsia (subito dal veterinario).',
                ),
              ),
            ),
          const SectionTitle('Storico'),
          if (ev.isEmpty) const Text('Nessun evento registrato.'),
          for (final e in ev)
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(e.type.label),
              subtitle: Text(dmy(e.date)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => store.deleteRepro(e.id),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, AppStore store) async {
    final type = await showDialog<ReproEventType>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Cosa vuoi registrare?'),
        children: [
          for (final t in ReproEventType.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, t),
              child: Text(t.label),
            ),
        ],
      ),
    );
    if (type == null || !context.mounted) return;
    final date = await pickDate(context, DateTime.now());
    if (date == null) return;
    await store.addRepro(
      ReproEvent(id: newId(), dogId: dog.id, type: type, date: date),
    );
  }
}

// ---------------------------------------------------------------------------
class QolPage extends StatefulWidget {
  const QolPage({super.key, required this.dog});
  final Dog dog;
  @override
  State<QolPage> createState() => _QolPageState();
}

class _QolPageState extends State<QolPage> {
  // Parte da 5 (o dall'ultima valutazione) e chiede di toccare ogni voce
  // (07 N46).
  List<int>? _scores;
  final touched = <int>{};

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final history =
        store.qol
            .where((q) => q.dogId == widget.dog.id && q.kind == 'hhhhhmm')
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    _scores ??= history.isEmpty
        ? List<int>.filled(7, 5)
        : [...history.last.scores];
    final scores = _scores!;
    final total = scores.fold(0, (a, b) => a + b);
    final complete = touched.length == 7;
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Qualità della vita')),
      body: PageBody(
        children: [
          const Text(
            'Scala HHHHHMM (Villalobos): 7 voci da 0 a 10. Compilala ogni 1-2 settimane, '
            'sempre nelle stesse condizioni. Sopra 35 la qualità di vita è considerata accettabile.',
          ),
          for (var i = 0; i < 7; i++) ...[
            const SizedBox(height: 10),
            Text(
              '${Modules.qolItems[i].$1}: ${scores[i]}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(Modules.qolItems[i].$2, style: t.textTheme.bodySmall),
            Slider(
              value: scores[i].toDouble(),
              min: 0,
              max: 10,
              divisions: 10,
              onChanged: (v) => setState(() {
                scores[i] = v.round();
                touched.add(i);
              }),
            ),
          ],
          Text('Totale: $total / 70', style: t.textTheme.titleLarge),
          if (total < 35)
            Card(
              color: const Color(0xFFFFE9C7),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Punteggio sotto 35: parlane con il veterinario. Esistono molte possibilità per '
                  'controllare dolore e disagio.',
                  style: TextStyle(color: Color(0xFF5A3A00)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (!complete)
            Text(
              'Valuta tutte le 7 voci (mancano ${7 - touched.length}).',
              style: t.textTheme.bodySmall,
            ),
          FilledButton(
            onPressed: !complete
                ? null
                : () async {
                    await store.addQol(
                      QolEntry(
                        id: newId(),
                        dogId: widget.dog.id,
                        date: DateTime.now(),
                        scores: [...scores],
                      ),
                    );
                    if (context.mounted) toast(context, 'Valutazione salvata');
                  },
            child: const Text('Salva valutazione'),
          ),
          if (history.length >= 2) ...[
            const SectionTitle('Andamento'),
            SizedBox(
              height: 120,
              child: _Spark(
                values: history.map((q) => q.total.toDouble()).toList(),
                minY: 0,
                maxY: 70,
                threshold: 35,
              ),
            ),
          ],
          for (final q in history.reversed)
            ListTile(
              dense: true,
              title: Text('${q.total}/70'),
              trailing: Text(dmy(q.date)),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class LabsPage extends StatelessWidget {
  const LabsPage({super.key, required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final mine = store.labs.where((l) => l.dogId == dog.id).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final byName = <String, List<LabResult>>{};
    for (final l in mine) {
      byName.putIfAbsent(l.name, () => []).add(l);
    }
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Esami con valori')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Valore'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => _LabDialog(dog: dog, store: store),
        ),
      ),
      body: PageBody(
        children: [
          const Text(
            'Zampa non interpreta gli esami: mostra l\'andamento e segnala i valori fuori '
            'dall\'intervallo indicato dal laboratorio. L\'interpretazione spetta al veterinario.',
          ),
          if (byName.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nessun valore registrato.'),
            ),
          for (final e in byName.entries)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key, style: t.textTheme.titleMedium),
                    if (e.value.length >= 2)
                      SizedBox(
                        height: 80,
                        child: _Spark(
                          values: e.value.map((l) => l.value).toList(),
                        ),
                      ),
                    for (final l in e.value.reversed)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${dmy(l.date)}: ${l.value} ${l.unit}'
                              '${l.refLow != null || l.refHigh != null ? '  (rif. ${l.refLow ?? '–'}–${l.refHigh ?? '–'})' : ''}',
                              style: TextStyle(
                                color: l.outOfRange
                                    ? t.colorScheme.error
                                    : null,
                                fontWeight: l.outOfRange
                                    ? FontWeight.w700
                                    : null,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => store.deleteLab(l.id),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LabDialog extends StatefulWidget {
  const _LabDialog({required this.dog, required this.store});
  final Dog dog;
  final AppStore store;
  @override
  State<_LabDialog> createState() => _LabDialogState();
}

class _LabDialogState extends State<_LabDialog> {
  final name = TextEditingController();
  final value = TextEditingController();
  final unit = TextEditingController();
  final low = TextEditingController();
  final high = TextEditingController();
  DateTime date = DateTime.now();

  double? _n(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nuovo valore'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Autocomplete<(String, String)>(
            optionsBuilder: (v) => Modules.labPresets.where(
              (p) => p.$1.toLowerCase().contains(v.text.toLowerCase()),
            ),
            displayStringForOption: (p) => p.$1,
            onSelected: (p) {
              name.text = p.$1;
              unit.text = p.$2;
            },
            fieldViewBuilder: (ctx, c, f, _) => TextField(
              controller: c,
              focusNode: f,
              onChanged: (v) => name.text = v,
              decoration: const InputDecoration(
                labelText: 'Esame (es. Creatinina)',
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: value,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valore'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: unit,
            decoration: const InputDecoration(labelText: 'Unità'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: low,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rif. min'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: high,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Rif. max'),
                ),
              ),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Data: ${dmy(date)}'),
            onTap: () async {
              final d = await pickDate(context, date);
              if (d != null) setState(() => date = d);
            },
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: () async {
          final v = _n(value);
          if (name.text.trim().isEmpty || v == null) return;
          await widget.store.addLab(
            LabResult(
              id: newId(),
              dogId: widget.dog.id,
              date: date,
              name: name.text.trim(),
              value: v,
              unit: unit.text.trim(),
              refLow: _n(low),
              refHigh: _n(high),
            ),
          );
          if (context.mounted) Navigator.pop(context);
        },
        child: const Text('Salva'),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
class TravelPage extends StatefulWidget {
  const TravelPage({super.key, required this.dog});
  final Dog dog;
  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  DateTime departure = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final items = Modules.travelChecklist(widget.dog, store.records, departure);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Viaggi')),
      body: PageBody(
        children: [
          ListTile(
            leading: const Icon(Icons.flight_takeoff),
            title: Text('Partenza: ${dmy(departure)}'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () async {
              final d = await pickDate(context, departure);
              if (d != null) setState(() => departure = d);
            },
          ),
          for (final i in items)
            Card(
              child: ListTile(
                leading: Icon(
                  i.ok == null
                      ? Icons.help_outline
                      : i.ok!
                      ? Icons.check_circle
                      : Icons.cancel,
                  color: i.ok == null
                      ? null
                      : i.ok!
                      ? Colors.green
                      : t.colorScheme.error,
                ),
                title: Text(i.item),
                subtitle: Text(i.note),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Le regole cambiano spesso e variano per paese: verifica sempre con il veterinario e sul '
            'sito del Ministero della Salute prima di partire.',
            style: t.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class ExpensesPage extends StatelessWidget {
  const ExpensesPage({super.key, required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final t = Theme.of(context);
    final mine = store.records.where((r) => r.dogId == dog.id).toList();
    final years = {
      now.year,
      ...mine.where((r) => r.cost != null).map((r) => r.date.year),
    }.toList()..sort((a, b) => b - a);
    return Scaffold(
      appBar: AppBar(title: const Text('Spese veterinarie')),
      body: PageBody(
        children: [
          for (final y in years)
            Builder(
              builder: (_) {
                // Il tetto di 550 € vale per contribuente: si sommano tutti
                // i cani registrati (07 N52).
                final mine = Modules.expenses(
                  store.records.where((r) => r.dogId == dog.id).toList(),
                  y,
                );
                final all = Modules.expenses(store.records, y);
                return Card(
                  child: ListTile(
                    title: Text(
                      '$y: € ${mine.total.toStringAsFixed(2)} per ${dog.name}',
                    ),
                    subtitle: Text(
                      '${store.dogs.length > 1 ? 'Tutti i cani: € ${all.total.toStringAsFixed(2)}. ' : ''}'
                      'Detraibile stimato: € ${all.deductible.toStringAsFixed(2)} → rimborso IRPEF ≈ € ${all.refund.toStringAsFixed(2)}',
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          Text(
            'Stima indicativa: 19% della spesa oltre la franchigia di 129,11 € e fino a 550 € (somma di '
            'tutti gli animali del contribuente). Servono fattura o scontrino parlante e il pagamento '
            'tracciabile (L. 160/2019, art. 1 c. 679). Verifica con il CAF o il commercialista. '
            'Inserisci il costo nelle voci della cartella.',
            style: t.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _Spark extends StatelessWidget {
  const _Spark({required this.values, this.minY, this.maxY, this.threshold});
  final List<double> values;
  final double? minY;
  final double? maxY;
  final double? threshold;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _SparkPainter(
      values,
      Theme.of(context).colorScheme.primary,
      minY,
      maxY,
      threshold,
      Theme.of(context).colorScheme.error,
    ),
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(
    this.v,
    this.color,
    this.minY,
    this.maxY,
    this.threshold,
    this.thColor,
  );
  final List<double> v;
  final Color color;
  final double? minY;
  final double? maxY;
  final double? threshold;
  final Color thColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) return;
    final lo = minY ?? v.reduce(math.min) * 0.95;
    final hi = maxY ?? v.reduce(math.max) * 1.05;
    final span = (hi - lo).abs() < 1e-9 ? 1 : hi - lo;
    Offset p(int i) => Offset(
      size.width * i / (v.length - 1),
      size.height * (1 - (v[i] - lo) / span),
    );
    if (threshold != null) {
      final y = size.height * (1 - (threshold! - lo) / span);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = thColor.withValues(alpha: 0.5),
      );
    }
    final path = Path()..moveTo(p(0).dx, p(0).dy);
    for (var i = 1; i < v.length; i++) {
      path.lineTo(p(i).dx, p(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < v.length; i++) {
      canvas.drawCircle(p(i), 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => old.v != v;
}

// ---------------------------------------------------------------------------
/// Valutazioni dell'anziano (07 aggiunta N10): Muscle Condition Score WSAVA
/// (descrittivo) e una checklist dei cambiamenti cognitivi sui sei ambiti
/// DISHAA, scritta per Zampa e NON validata. I questionari validati (CBPI,
/// LOAD, CCDR) sono protetti da copyright: vanno usati con licenza.
class SeniorScalesPage extends StatefulWidget {
  const SeniorScalesPage({super.key, required this.dog});
  final Dog dog;
  @override
  State<SeniorScalesPage> createState() => _SeniorScalesPageState();
}

class _SeniorScalesPageState extends State<SeniorScalesPage> {
  int? mcs;
  final cog = <int, int>{};

  static const mcsLevels = [
    ('Normale', 'Muscoli pieni su schiena, scapole, cranio e cosce.'),
    ('Perdita lieve', 'Si sente un po\' di più la colonna o il cranio.'),
    ('Perdita moderata', 'Ossa di schiena, scapole e bacino ben palpabili.'),
    ('Perdita grave', 'Ossa molto evidenti, muscoli assottigliati ovunque.'),
  ];

  static const cogItems = [
    (
      'Disorientamento',
      'Si perde in casa, resta bloccato negli angoli, non riconosce persone note.',
    ),
    (
      'Interazione',
      'Cerca meno (o molto di più) la compagnia, reagisce diversamente.',
    ),
    ('Sonno-veglia', 'Dorme di giorno, è sveglio o agitato di notte.'),
    (
      'Pulizia in casa',
      'Sporca in casa pur essendo educato, non chiede di uscire.',
    ),
    (
      'Attività',
      'Gironzola senza scopo, lecca in modo ripetitivo, gioca meno.',
    ),
    ('Ansia', 'Più pauroso, agitato quando resta solo, vocalizza.'),
  ];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    final history =
        store.qol
            .where((q) => q.dogId == widget.dog.id && q.kind != 'hhhhhmm')
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final cogTotal = cog.values.fold(0, (a, b) => a + b);
    final cogDone = cog.length == cogItems.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Muscoli e cognitivo')),
      body: PageBody(
        children: [
          const SectionTitle('Massa muscolare (Muscle Condition Score, WSAVA)'),
          const Text(
            'Passa la mano su colonna, scapole, cranio e cosce. Indipendente dal peso: '
            'un cane può essere in sovrappeso e perdere muscolo.',
          ),
          RadioGroup<int>(
            groupValue: mcs,
            onChanged: (v) => setState(() => mcs = v),
            child: Column(
              children: [
                for (var i = 0; i < mcsLevels.length; i++)
                  RadioListTile<int>(
                    value: i,
                    title: Text(mcsLevels[i].$1),
                    subtitle: Text(mcsLevels[i].$2),
                  ),
              ],
            ),
          ),
          if (mcs != null && mcs! >= 1)
            Card(
              color: const Color(0xFFFFE9C7),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  mcs! >= 2
                      ? 'Perdita muscolare moderata o grave: parlane con il veterinario nei prossimi giorni.'
                      : 'Perdita lieve: segnalala alla prossima visita.',
                  style: const TextStyle(color: Color(0xFF5A3A00)),
                ),
              ),
            ),
          FilledButton.tonal(
            onPressed: mcs == null
                ? null
                : () async {
                    await store.addQol(
                      QolEntry(
                        id: newId(),
                        dogId: widget.dog.id,
                        date: DateTime.now(),
                        scores: [mcs!],
                        kind: 'mcs',
                      ),
                    );
                    if (context.mounted) toast(context, 'Valutazione salvata');
                  },
            child: const Text('Salva massa muscolare'),
          ),
          const SectionTitle('Cambiamenti cognitivi (checklist DISHAA)'),
          Text(
            'Checklist informativa scritta per Zampa sui sei ambiti DISHAA: non è un punteggio '
            'validato e non fa diagnosi. Per ogni voce: 0 = no, 1 = a volte, 2 = spesso.',
            style: t.textTheme.bodySmall,
          ),
          for (var i = 0; i < cogItems.length; i++) ...[
            const SizedBox(height: 8),
            Text(
              cogItems[i].$1,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(cogItems[i].$2, style: t.textTheme.bodySmall),
            SegmentedButton<int>(
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(value: 0, label: Text('No')),
                ButtonSegment(value: 1, label: Text('A volte')),
                ButtonSegment(value: 2, label: Text('Spesso')),
              ],
              selected: cog.containsKey(i) ? {cog[i]!} : <int>{},
              onSelectionChanged: (v) => setState(() {
                if (v.isEmpty) {
                  cog.remove(i);
                } else {
                  cog[i] = v.first;
                }
              }),
            ),
          ],
          if (cogDone && (cogTotal >= 3 || cog.values.any((v) => v == 2)))
            const Card(
              color: Color(0xFFFFE9C7),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Ci sono cambiamenti da segnalare: parlane con il veterinario. Alcuni '
                  'possono dipendere da dolore, problemi di vista o udito, o malattie '
                  'curabili, non solo dall\'età.',
                  style: TextStyle(color: Color(0xFF5A3A00)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: !cogDone
                ? null
                : () async {
                    await store.addQol(
                      QolEntry(
                        id: newId(),
                        dogId: widget.dog.id,
                        date: DateTime.now(),
                        scores: [
                          for (var i = 0; i < cogItems.length; i++) cog[i]!,
                        ],
                        kind: 'cognitivo',
                      ),
                    );
                    if (context.mounted) toast(context, 'Checklist salvata');
                  },
            child: const Text('Salva checklist'),
          ),
          if (history.isNotEmpty) ...[
            const SectionTitle('Storico'),
            for (final q in history.take(20))
              ListTile(
                dense: true,
                title: Text(
                  q.kind == 'mcs'
                      ? 'Massa muscolare: ${mcsLevels[q.scores.first].$1}'
                      : 'Checklist cognitiva: ${q.total}/12',
                ),
                trailing: Text(dmy(q.date)),
              ),
          ],
          const SizedBox(height: 8),
          Text(
            'Questionari validati come CBPI (dolore), LOAD (artrosi) e CCDR (disfunzione '
            'cognitiva) sono protetti da copyright: il veterinario può somministrarli in visita.',
            style: t.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
