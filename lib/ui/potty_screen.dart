import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/bio_params.dart';
import '../logic/pee_forecast_v2.dart';
import '../logic/potty_predictor.dart';
import '../models.dart';
import '../store.dart';
import 'chart_summary.dart';
import 'common.dart';
import 'home_screen.dart';
import 'log_sheet.dart';
import 'potty_v3.dart';

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
          if (kPrevisioneV3InVista) SignalBanner(dog: dog, logs: logs),
          ForecastCard(forecast: f, dog: dog),
          if (need == Need.pipi && f.v2 != null && kPrevisioneV2InVista)
            _V2Card(v: f.v2!, dog: dog, now: now),
          if (need == Need.cacca && kPrevisioneV3InVista)
            PoopV3Card(dog: dog, logs: logs),
          if (kPrevisioneV3InVista) SignalButtons(dog: dog),
          if (need == Need.pipi && kPrevisioneV3InVista)
            OutingPlanCard(dog: dog, logs: logs),
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
                child: Semantics(
                  container: true,
                  label: dayBarsSummary(
                    perDay,
                    now,
                    what: need == Need.pipi ? 'pipì' : 'cacche',
                  ),
                  child: ExcludeSemantics(
                    child: _DayBars(
                      perDay: perDay,
                      now: now,
                      color: t.colorScheme.primary,
                    ),
                  ),
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
          if (kPrevisioneV3InVista) StudyExportTile(dog: dog),
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

/// Scheda della previsione v2 (ricerca/27 §5). Spegnibile con
/// [kPrevisioneV2InVista] finché il CEO non decide se sostituire la
/// previsione di base anche nella Home.
const bool kPrevisioneV2InVista = true;

/// Schede v3 (ricerca/28): segnali, cacca legata ai pasti, piano di uscite,
/// esportazione per lo studio.
const bool kPrevisioneV3InVista = true;

class _V2Card extends StatelessWidget {
  const _V2Card({required this.v, required this.dog, required this.now});
  final PeeForecastV2 v;
  final Dog dog;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final x = v2Texts(v, now, dog.name, leadMinutes: dog.reminderLeadMinutes);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nuova previsione (in prova)', style: t.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(x.title, style: t.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(x.window),
            const SizedBox(height: 6),
            Text(x.advice, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(x.confidence, style: t.textTheme.bodySmall),
            Text(
              'Unisce tre stime: il suo intervallo abituale, gli orari dei '
              'giorni scorsi e lo stesso giorno della settimana scorsa. È una '
              'stima: se ${dog.name} chiede di uscire, ascolta lui.',
              style: t.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
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
                // Con il testo grande i numeri si rimpiccioliscono e le barre
                // usano lo spazio che resta: niente overflow al 200%.
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${perDay[d] ?? ''}', style: small),
                  ),
                  const SizedBox(height: 2),
                  Flexible(
                    child: FractionallySizedBox(
                      heightFactor: (perDay[d] ?? 0) / maxV,
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: d.day == now.day ? 1 : 0.55,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${d.day}', style: small),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Testi della scheda «Prossima pipì» (ricerca/27 §5). Nessuna frase di
/// accuratezza (piano CEO 11.3): la fiducia è detta a parole.
({String title, String window, String confidence, String advice}) v2Texts(
  PeeForecastV2 v,
  DateTime now,
  String name, {
  int leadMinutes = 10,
}) {
  String two(int x) => x.toString().padLeft(2, '0');
  String hm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';
  String dur(int m) {
    if (m < 60) {
      final r = math.max(5, (m / 5).round() * 5);
      return '$r minuti';
    }
    final q = (m / 15).round() * 15;
    final h = q ~/ 60, mm = q % 60;
    final hs = h == 1 ? '1 ora' : '$h ore';
    return mm == 0 ? hs : '$hs e $mm minuti';
  }

  final m = v.minutesUntil(now);
  final title = m <= 0
      ? 'Potrebbe essere ora: è passato l\'orario previsto (${hm(v.expectedAt)})'
      : 'Prossima pipì tra circa ${dur(m)} (verso le ${hm(v.expectedAt)})';
  final lo = v.lo50.isBefore(now) ? now : v.lo50;
  final window = v.hi50.isBefore(now)
      ? 'Di solito a quest\'ora l\'ha già fatta: se chiede di uscire, '
            'portalo fuori.'
      : 'Di solito tra le ${hm(lo)} e le ${hm(v.hi50)}.';
  final confidence = switch (v.confidence) {
    V2Confidence.alta =>
      'Fiducia alta: nelle ultime settimane le previsioni di $name sono '
          'state vicine.',
    V2Confidence.media => 'Fiducia media.',
    V2Confidence.bassa =>
      'Fiducia bassa: sto ancora imparando, oppure i suoi orari cambiano '
          'molto da un giorno all\'altro.',
  };
  final go = v.alertAt.subtract(Duration(minutes: leadMinutes));
  final advice = go.isAfter(now)
      ? 'Per stare tranquilli, esci verso le ${hm(go)}.'
      : 'Per stare tranquilli, esci adesso.';
  return (title: title, window: window, confidence: confidence, advice: advice);
}
