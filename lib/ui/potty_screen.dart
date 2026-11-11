import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/bio_params.dart';
import '../logic/potty_predictor.dart';
import '../models.dart';
import '../store.dart';
import 'common.dart';
import 'home_screen.dart';
import 'log_sheet.dart';

class PottyScreen extends StatefulWidget {
  const PottyScreen({super.key});
  @override
  State<PottyScreen> createState() => _PottyScreenState();
}

class _PottyScreenState extends State<PottyScreen> {
  Need need = Need.pipi;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final dog = store.dog!;
    final now = DateTime.now();
    final model = store.model(dog, need, now);
    final f = model.forecast(now);
    final plan = model.dailyPlan(now);
    final logs = store.logsOf(dog.id);
    final perDay = PottyStats.outingsPerDay(logs, type: need.logType);
    final outdoor = PottyStats.outdoorRate(logs, now, 14, type: need.logType);
    final t = Theme.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Registra'),
        onPressed: () => showLogSheet(context, dog, need.logType),
      ),
      body: PageBody(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SegmentedButton<Need>(
              segments: const [
                ButtonSegment(
                  value: Need.pipi,
                  icon: Icon(Icons.water_drop),
                  label: Text('Pipì'),
                ),
                ButtonSegment(
                  value: Need.cacca,
                  icon: Icon(Icons.grass),
                  label: Text('Cacca'),
                ),
              ],
              selected: {need},
              onSelectionChanged: (s) => setState(() => need = s.first),
            ),
          ),
          ForecastCard(forecast: f, dog: dog),
          const SectionTitle('Come calcola l\'orario'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv(context, 'Giorni di dati usati', '${model.daysWithData}'),
                  _kv(
                    context,
                    'Intervallo tipico da sveglio',
                    _dur(f.typicalIntervalMin),
                  ),
                  _kv(
                    context,
                    'Valore di partenza (letteratura)',
                    _dur(BioParams.forNeed(need, dog, now).median),
                  ),
                  if (need == Need.pipi)
                    _kv(
                      context,
                      'Tetto massimo per età (non un obiettivo)',
                      _dur(model.prior.maxDay),
                    ),
                  if (outdoor != null)
                    _kv(
                      context,
                      'Fatta fuori (14 giorni)',
                      '${(outdoor * 100).round()}%',
                    ),
                  const SizedBox(height: 8),
                  Text(
                    need == Need.pipi
                        ? 'L\'orario viene dal suo intervallo abituale da sveglio '
                              'negli ultimi 14 giorni, accorciato subito se negli '
                              'ultimi 3 giorni esce più spesso, e dai suoi orari '
                              'abituali. Finché non ci sono abbastanza dati usa i '
                              'valori della letteratura per età e taglia, con i '
                              'fattori noti (farmaci, malattie, calore). Il tetto '
                              'per età vale sempre. È una stima: se ${dog.name} '
                              'chiede di uscire, ascolta lui.'
                        : 'Mostra gli orari in cui ${dog.name} la fa di solito '
                              'negli ultimi 14 giorni.',
                    style: t.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          SectionTitle('Piano consigliato di oggi (${plan.length} uscite)'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in plan)
                    Chip(
                      label: Text(hm(p)),
                      backgroundColor: p.isBefore(now)
                          ? null
                          : t.colorScheme.secondaryContainer,
                    ),
                ],
              ),
            ),
          ),
          const SectionTitle('Ultimi 14 giorni'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 120,
                child: _DayBars(
                  perDay: perDay,
                  now: now,
                  color: t.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SectionTitle('Diario'),
          for (final l in logs.take(60))
            Dismissible(
              key: ValueKey(l.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: t.colorScheme.errorContainer,
                child: const Icon(Icons.delete_outline),
              ),
              onDismissed: (_) => store.deleteLog(l.id),
              child: ListTile(
                dense: true,
                leading: Icon(l.type.icon),
                title: Text(
                  '${l.type.label}${l.indoor ? ' · in casa' : ''}${l.amountMl != null ? ' · ${l.amountMl!.round()} ml' : ''}',
                ),
                subtitle: (l.signs.isEmpty && l.note.isEmpty)
                    ? null
                    : Text(
                        [
                          ...l.signs.map((s) => s.label),
                          if (l.note.isNotEmpty) l.note,
                        ].join(' · '),
                      ),
                trailing: Text(whenLabel(l.time, now)),
              ),
            ),
          if (logs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Ancora nessuna registrazione.'),
            ),
          const SizedBox(height: 8),
          Text(
            'Scorri verso sinistra una voce per eliminarla.',
            style: t.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static String _dur(double minutes) {
    final h = minutes ~/ 60;
    final m = (minutes % 60).round();
    if (h == 0) return '$m min';
    return m == 0 ? '$h h' : '$h h $m min';
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(k)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class _DayBars extends StatelessWidget {
  const _DayBars({
    required this.perDay,
    required this.now,
    required this.color,
  });
  final Map<DateTime, int> perDay;
  final DateTime now;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final days = [
      for (var i = 13; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
    ];
    final maxV = math.max(1, days.map((d) => perDay[d] ?? 0).fold(0, math.max));
    final small = Theme.of(context).textTheme.labelSmall;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final d in days)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${perDay[d] ?? ''}', style: small),
                  const SizedBox(height: 2),
                  Container(
                    height: 70 * (perDay[d] ?? 0) / maxV,
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: d.day == now.day ? 1 : 0.55,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${d.day}', style: small),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
