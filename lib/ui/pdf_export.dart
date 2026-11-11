import 'dart:math' as math;

import '../brand.dart';

import 'dart:typed_data';

import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../logic/alerts.dart';
import '../logic/bio_params.dart';
import '../logic/modules.dart';
import '../logic/nutrition.dart';
import '../logic/potty_predictor.dart';
import '../models.dart';
import '../store.dart';
import 'common.dart';

/// Esportazione PDF per il veterinario (revisione veterinaria 06, aggiunta
/// 16): cartella, terapie con conferme, grafici di 14 giorni, allarmi.
Future<void> exportPdf(BuildContext context, AppStore store, Dog dog) async {
  try {
    final bytes = await buildPdf(store, dog, DateTime.now());
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          '${appName}_${dog.name}_${dmy(DateTime.now()).replaceAll('/', '-')}.pdf',
    );
  } catch (e) {
    if (context.mounted) toast(context, 'PDF non disponibile: $e');
  }
}

String _safe(String s) => s
    .replaceAll('≈', '~')
    .replaceAll('≥', '>=')
    .replaceAll('≤', '<=')
    .replaceAll('×', 'x')
    .replaceAll('→', '->')
    .replaceAll('µ', 'u')
    .replaceAll(RegExp(r'[^\u0000-ÿ€–—’]'), '');

pw.ThemeData? _pdfTheme;

/// Tema del PDF con Atkinson Hyperlegible Next, lo stesso carattere dell'app
/// (ricerca/22 §8): i TTF inclusi negli asset disegnano «–» e gli accenti,
/// che l'Helvetica predefinita del pacchetto `pdf` non copre.
Future<pw.ThemeData> pdfTheme() async {
  if (_pdfTheme case final t?) return t;
  Future<pw.Font> ttf(String w) async => pw.Font.ttf(
    await rootBundle.load('assets/fonts/AtkinsonHyperlegibleNext-$w.ttf'),
  );
  final bold = await ttf('Bold');
  return _pdfTheme = pw.ThemeData.withFont(
    base: await ttf('Regular'),
    bold: bold,
    italic: await ttf('Italic'),
    // Il corsivo grassetto non è incluso: si usa il grassetto.
    boldItalic: bold,
  );
}

Future<Uint8List> buildPdf(AppStore store, Dog dog, DateTime now) async {
  pw.ThemeData? theme;
  try {
    theme = await pdfTheme();
  } catch (_) {
    // Senza i caratteri il PDF esce comunque, con l'Helvetica del pacchetto
    // (_safe toglie i simboli che non sa disegnare).
  }
  final doc = pw.Document(
    title: '$appName – ${dog.name}',
    author: appName,
    theme: theme,
  );
  final plan = Nutrition.plan(dog, now);
  final logs = store.logsOf(dog.id);
  final days = [
    for (var i = 13; i >= 0; i--) DateTime(now.year, now.month, now.day - i),
  ];
  Map<DateTime, double> perDay(
    bool Function(LogEntry) f,
    double Function(LogEntry) v,
  ) {
    final m = <DateTime, double>{};
    for (final l in logs.where(f)) {
      final d = DateTime(l.time.year, l.time.month, l.time.day);
      m[d] = (m[d] ?? 0) + v(l);
    }
    return m;
  }

  final pee = PottyStats.outingsPerDay(logs)
      .map((k, v) => MapEntry(k, v.toDouble()));
  final poop = PottyStats.outingsPerDay(
    logs,
    type: LogType.cacca,
  ).map((k, v) => MapEntry(k, v.toDouble()));
  final water = perDay(
    (l) => l.type == LogType.acqua && l.amountMl != null,
    (l) => l.amountMl!,
  );
  final alerts = AlertEngine.compute(
    dog: dog,
    logs: store.logs,
    records: store.records,
    weights: store.weights,
    now: now,
    repro: store.repro,
    pendingDoses: store.pendingDoses(dog.id, now),
  ).where((a) => a.level != AlertLevel.info);
  final therapies = store.records
      .where((r) => r.dogId == dog.id && r.type == RecordType.farmaco)
      .toList();
  final weights = store.weightsOf(dog.id);
  final labs = store.labs.where((l) => l.dogId == dog.id).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  final symptoms = logs
      .where(
        (l) =>
            now.difference(l.time).inDays <= 30 &&
            !{
              LogType.pipi,
              LogType.cacca,
              LogType.pasto,
              LogType.acqua,
              LogType.risveglio,
              LogType.gioco,
              LogType.passeggiata,
            }.contains(l.type),
      )
      .toList();
  final pf = store.forecast(dog, Need.pipi, now);

  pw.Widget h(String t) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
    child: pw.Text(
      _safe(t),
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.teal800,
      ),
    ),
  );
  pw.Widget p(String t, {double size = 10}) =>
      pw.Text(_safe(t), style: pw.TextStyle(fontSize: size));

  pw.Widget bars(
    String title,
    Map<DateTime, double> data,
    PdfColor color, {
    String unit = '',
  }) {
    final maxV = math.max(
      1.0,
      days.map((d) => data[d] ?? 0).fold<double>(0, math.max),
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        p(title, size: 10),
        pw.SizedBox(height: 4),
        pw.SizedBox(
          height: 70,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              for (final d in days)
                pw.Expanded(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text(
                        (data[d] ?? 0) == 0
                            ? ''
                            : (data[d]!).round().toString(),
                        style: const pw.TextStyle(fontSize: 6),
                      ),
                      pw.Container(
                        height: 50 * (data[d] ?? 0) / maxV,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 1),
                        color: color,
                      ),
                      pw.Text(
                        '${d.day}',
                        style: const pw.TextStyle(fontSize: 6),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (unit.isNotEmpty) p(unit, size: 7),
      ],
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (c) => pw.Text(
        _safe(
          'Dati inseriti dal proprietario con $appName il ${dmy(now)} – non sostituisce la visita veterinaria – pag. ${c.pageNumber}/${c.pagesCount}',
        ),
        style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
      ),
      build: (c) => [
        pw.Text(
          _safe('Cartella sanitaria di ${dog.name}'),
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        p(
          '${dog.breed.isEmpty ? 'Razza n.d.' : dog.breed} · ${dog.sex.name}${dog.neutered ? ' (sterilizzato/a)' : ''} · '
          'nato il ${dmy(dog.birthDate)} (${ageLabel(dog, now)}) · ${dog.weightKg.toStringAsFixed(1)} kg · BCS ${dog.bodyCondition}/9',
        ),
        p(
          'Microchip: ${dog.microchip.isEmpty ? '-' : dog.microchip} · Allergie: ${dog.allergies.isEmpty ? '-' : dog.allergies}',
        ),
        p('Patologie note: ${dog.conditions.isEmpty ? '-' : dog.conditions}'),
        p(
          'Alimentazione: ${dog.foodName.isEmpty ? '-' : dog.foodName} (${dog.diet.label}), ~${plan.kcalPerDay.round()} kcal/giorno',
        ),
        if (alerts.isNotEmpty) ...[
          h('Segnalazioni attive al ${dmy(now)} ${hm(now)}'),
          for (final a in alerts)
            p('• [${a.level.name.toUpperCase()}] ${a.title}'),
        ],
        h('Andamento ultimi 14 giorni'),
        pw.Row(
          children: [
            pw.Expanded(
              child: bars('Pipì (uscite/giorno)', pee, PdfColors.teal),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: bars('Cacca (volte/giorno)', poop, PdfColors.brown),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Expanded(
              child: bars(
                'Acqua registrata (ml/giorno)',
                water,
                PdfColors.blue,
                unit:
                    'Polidipsia oltre ${(dog.weightKg * 100).round()} ml/giorno',
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  p('Peso'),
                  for (final w in weights.skip(math.max(0, weights.length - 6)))
                    p('${dmy(w.date)}: ${w.kg.toStringAsFixed(1)} kg', size: 8),
                ],
              ),
            ),
          ],
        ),
        p(
          'Intervallo tipico tra le pipì da sveglio: ${pf.typicalIntervalMin.round()} min '
          '(mediana degli ultimi 14 giorni registrati in $appName).',
          size: 8,
        ),
        if (therapies.isNotEmpty) ...[
          h('Terapie'),
          for (final r in therapies) ...[
            p(
              '• ${r.title} ${r.dose} ${r.everyHours != null ? 'ogni ${r.everyHours} h' : ''} dal ${dmy(r.date)}'
              '${r.endDate != null ? ' al ${dmy(r.endDate!)}' : ''}',
            ),
            () {
              final d = store.doses.where((x) => x.recordId == r.id).toList();
              if (d.isEmpty) return pw.SizedBox();
              final given = d.where((x) => x.status == DoseStatus.dato).length;
              return p(
                '   somministrazioni confermate: $given, saltate: ${d.length - given}',
                size: 8,
              );
            }(),
          ],
        ],
        if (symptoms.isNotEmpty) ...[
          h('Sintomi e misure (30 giorni)'),
          for (final l in symptoms.take(40))
            p(
              '• ${dmy(l.time)} ${hm(l.time)} ${l.type.label}'
              '${l.value != null ? ': ${_fmtValue(l)}' : ''}'
              '${l.signs.isNotEmpty ? ' (${l.signs.map((s) => s.label).join(', ')})' : ''}'
              '${l.note.isNotEmpty ? ' – ${l.note}' : ''}',
              size: 8,
            ),
        ],
        ..._extraSections(store, dog, now, logs, h, p),
        if (labs.isNotEmpty) ...[
          h('Esami'),
          pw.TableHelper.fromTextArray(
            headers: ['Data', 'Esame', 'Valore', 'Riferimento'],
            data: [
              for (final l in labs.take(30))
                [
                  dmy(l.date),
                  _safe(l.name),
                  _safe('${l.value} ${l.unit}${l.outOfRange ? ' *' : ''}'),
                  '${l.refLow ?? '-'} – ${l.refHigh ?? '-'}',
                ],
            ],
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
        h('Storico'),
        for (final r in store.recordsOf(dog.id).where((r) => r.done))
          p(
            '• ${dmy(r.date)} ${r.type.label}: ${r.title}${r.dose.isNotEmpty ? ' (${r.dose})' : ''}${r.notes.isNotEmpty ? ' – ${r.notes}' : ''}',
            size: 9,
          ),
      ],
    ),
  );
  return doc.save();
}

String _fmtValue(LogEntry l) {
  final v = l.value!;
  return switch (l.type) {
    LogType.temperatura => '${v.toStringAsFixed(1)} °C',
    LogType.respiro => '${v.round()} respiri/min',
    LogType.convulsione => '${v.toStringAsFixed(1)} min',
    LogType.insulina => '${v.toStringAsFixed(1)} UI',
    LogType.glicemia => '${v.round()} mg/dL',
    LogType.cacca => 'Purina ${v.round()}/7',
    _ => v.toString(),
  };
}

/// Sezioni aggiuntive richieste dalla revisione veterinaria (07 N47).
List<pw.Widget> _extraSections(
  AppStore store,
  Dog dog,
  DateTime now,
  List<LogEntry> logs,
  pw.Widget Function(String) h,
  pw.Widget Function(String, {double size}) p,
) {
  final out = <pw.Widget>[];
  final last14 = logs.where((l) => now.difference(l.time).inDays < 14).toList();
  // Bisogni: in casa, notturni, con segni, punteggi fecali.
  final pees = last14.where((l) => l.type == LogType.pipi).toList();
  final poops = last14.where((l) => l.type == LogType.cacca).toList();
  final night = pees
      .where((l) => PottyPredictor.inSleepWindow(dog, l.time))
      .length;
  out
    ..add(h('Bisogni (14 giorni)'))
    ..add(
      p(
        'Pipì registrate: ${pees.length} · in casa: ${pees.where((l) => l.indoor).length} · '
        'notturne: $night · con segni: ${pees.where((l) => l.signs.isNotEmpty).length}',
        size: 9,
      ),
    )
    ..add(
      p(
        'Cacca registrate: ${poops.length} · in casa: ${poops.where((l) => l.indoor).length} · '
        'punteggi Purina: ${poops.where((l) => l.value != null).map((l) => '${dmy(l.time).substring(0, 5)}=${l.value!.round()}').join(', ')}',
        size: 9,
      ),
    );
  // Acqua in ml/kg/die sui giorni registrati.
  final water = last14.where(
    (l) => l.type == LogType.acqua && l.amountMl != null,
  );
  final days = {
    for (final l in water) DateTime(l.time.year, l.time.month, l.time.day),
  };
  if (days.isNotEmpty) {
    final mean = water.fold<double>(0, (a, l) => a + l.amountMl!) / days.length;
    out.add(
      p(
        'Acqua: media ${mean.round()} ml/die = ${(mean / dog.weightKg).round()} ml/kg/die '
        'su ${days.length} giorni registrati (polidipsia > 100 ml/kg/die).',
        size: 9,
      ),
    );
  }
  // Respiri nel sonno.
  final breaths = logs
      .where((l) => l.type == LogType.respiro && l.value != null)
      .take(20)
      .toList();
  if (breaths.isNotEmpty) {
    out
      ..add(h('Respiri nel sonno'))
      ..add(
        p(
          breaths
              .map(
                (l) =>
                    '${dmy(l.time).substring(0, 5)} ${hm(l.time)}: ${l.value!.round()}/min',
              )
              .join(' · '),
          size: 8,
        ),
      );
  }
  // Crisi per mese.
  final seiz = Modules.seizuresPerMonth(store.logs, dog.id, now);
  if (seiz.any((m) => m.count > 0)) {
    out
      ..add(h('Crisi convulsive per mese'))
      ..add(
        p(
          seiz
              .map((m) => '${m.month.month}/${m.month.year}: ${m.count}')
              .join(' · '),
          size: 9,
        ),
      );
  }
  // Diabete.
  final diab = logs
      .where((l) => l.type == LogType.insulina || l.type == LogType.glicemia)
      .take(40)
      .toList();
  if (diab.isNotEmpty) {
    out.add(h('Insulina e glicemie'));
    for (final l in diab) {
      out.add(
        p(
          '• ${dmy(l.time)} ${hm(l.time)} ${l.type.label}: ${l.value == null ? '?' : _fmtValue(l)}'
          '${l.signs.contains(Sign.nonHaMangiato) ? ' (non aveva mangiato)' : ''}',
          size: 8,
        ),
      );
    }
  }
  // Conferme delle somministrazioni con data (07 aggiunta N14).
  final confirmed = store.doses.where((d) => d.dogId == dog.id).toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  if (confirmed.isNotEmpty) {
    out.add(h('Somministrazioni confermate dal proprietario'));
    out.add(
      p(
        confirmed
            .take(60)
            .map((d) {
              final r = store.records
                  .where((x) => x.id == d.recordId)
                  .firstOrNull;
              return '${dmy(d.scheduledAt).substring(0, 5)} ${hm(d.scheduledAt)} '
                  '${r?.title ?? 'farmaco'}: ${d.status == DoseStatus.dato ? 'dato' : 'SALTATO'}';
            })
            .join(' · '),
        size: 7,
      ),
    );
  }
  // Crisi rispetto alle dosi saltate, per mese.
  if (seiz.any((m) => m.count > 0) && confirmed.isNotEmpty) {
    out.add(h('Crisi e dosi saltate per mese'));
    for (final m in seiz) {
      final miss = confirmed
          .where(
            (d) =>
                d.status == DoseStatus.saltato &&
                d.scheduledAt.year == m.month.year &&
                d.scheduledAt.month == m.month.month,
          )
          .length;
      out.add(
        p(
          '${m.month.month}/${m.month.year}: crisi ${m.count} · dosi saltate $miss',
          size: 9,
        ),
      );
    }
  }
  // Dosi saltate.
  final skipped = store.doses
      .where((d) => d.dogId == dog.id && d.status == DoseStatus.saltato)
      .toList();
  if (skipped.isNotEmpty) {
    out.add(h('Dosi segnalate come saltate'));
    for (final d in skipped.take(30)) {
      final r = store.records.where((x) => x.id == d.recordId).firstOrNull;
      out.add(
        p(
          '• ${dmy(d.scheduledAt)} ${hm(d.scheduledAt)} ${r?.title ?? 'farmaco'}',
          size: 8,
        ),
      );
    }
  }
  // Riproduzione.
  final repro = Modules.reproOf(store.repro, dog.id);
  if (repro.isNotEmpty) {
    out
      ..add(h('Storico riproduttivo'))
      ..add(
        p(
          repro.map((e) => '${dmy(e.date)} ${e.type.label}').join(' · '),
          size: 9,
        ),
      );
  }
  // Qualità della vita.
  final qol =
      store.qol.where((q) => q.dogId == dog.id && q.kind == 'hhhhhmm').toList()
        ..sort((a, b) => a.date.compareTo(b.date));
  if (qol.isNotEmpty) {
    out
      ..add(h('Qualità della vita (HHHHHMM, su 70)'))
      ..add(
        p(qol.map((q) => '${dmy(q.date)}: ${q.total}').join(' · '), size: 9),
      );
  }
  return out;
}
