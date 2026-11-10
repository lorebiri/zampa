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
          if (f.curve.isNotEmpty) ...[
            const SectionTitle('Probabilità nelle prossime ore'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: SizedBox(
                  height: 170,
                  child: CustomPaint(
                    painter: _CurvePainter(
                      curve: f.curve,
                      now: now,
                      recommended: f.recommendedAt,
                      color: t.colorScheme.primary,
                      accent: t.colorScheme.tertiary,
                      text: t.textTheme.bodySmall!,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ],
          const SectionTitle('Come sta imparando'),
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
                  if (f.accuracy != null) ...[
                    _kv(
                      context,
                      'Errore tipico sulle ultime ${f.accuracy!.n}',
                      '± ${f.accuracy!.medianAbsErrorMin.round()} min',
                    ),
                    _kv(
                      context,
                      'Eventi caduti nella finestra',
                      '${(f.accuracy!.inWindowRate * 100).round()}%',
                    ),
                  ] else
                    _kv(context, 'Accuratezza', 'servono almeno 4 eventi'),
                  if (outdoor != null)
                    _kv(
                      context,
                      'Fatta fuori (14 giorni)',
                      '${(outdoor * 100).round()}%',
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Il modello stima quarto d\'ora per quarto d\'ora la probabilità '
                    'del bisogno, tenendo conto di tempo trascorso, ora del giorno, '
                    'sonno, pasti, acqua, risveglio, gioco e passeggiate, più i fattori '
                    'biologici (età, taglia, dieta, calore, farmaci, malattie note). '
                    'Parte dai valori della letteratura veterinaria e si adatta a '
                    '${dog.name} man mano che registri.',
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

class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.curve,
    required this.now,
    required this.recommended,
    required this.color,
    required this.accent,
    required this.text,
  });
  final List<(DateTime, double)> curve;
  final DateTime now;
  final DateTime recommended;
  final Color color;
  final Color accent;
  final TextStyle text;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0, bottom = 20.0;
    final w = size.width - left, h = size.height - bottom;
    final end = curve.last.$1;
    final span = end.difference(now).inMinutes.toDouble();
    double x(DateTime t) =>
        left + w * (t.difference(now).inMinutes / span).clamp(0, 1);
    double y(double p) => h * (1 - p);
    final grid = Paint()
      ..color = text.color!.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (final p in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawLine(Offset(left, y(p)), Offset(size.width, y(p)), grid);
      _label(canvas, '${(p * 100).round()}%', Offset(0, y(p) - 7));
    }
    // Etichette orarie ogni 2 ore.
    var t = DateTime(now.year, now.month, now.day, now.hour + 1);
    while (t.isBefore(end)) {
      if (t.hour % 2 == 0) {
        _label(canvas, '${two(t.hour)}:00', Offset(x(t) - 14, h + 4));
      }
      t = t.add(const Duration(hours: 1));
    }
    final path = Path()..moveTo(x(curve.first.$1), y(curve.first.$2));
    final fill = Path()
      ..moveTo(x(curve.first.$1), h)
      ..lineTo(x(curve.first.$1), y(curve.first.$2));
    for (final (tt, p) in curve) {
      path.lineTo(x(tt), y(p));
      fill.lineTo(x(tt), y(p));
    }
    fill
      ..lineTo(x(curve.last.$1), h)
      ..close();
    canvas.drawPath(fill, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
    if (recommended.isBefore(end)) {
      final rx = x(recommended);
      canvas.drawLine(
        Offset(rx, 0),
        Offset(rx, h),
        Paint()
          ..color = accent
          ..strokeWidth = 2,
      );
      _label(
        canvas,
        'esci',
        Offset(math.min(rx + 4, size.width - 24), 2),
        color: accent,
      );
    }
  }

  void _label(Canvas c, String s, Offset o, {Color? color}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: text.copyWith(color: color, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(covariant _CurvePainter old) => old.curve != curve;
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
