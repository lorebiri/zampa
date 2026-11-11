import 'dart:math' as math;

import '../l10n/clinical_text.dart';
import '../models.dart';

/// Logica dei moduli clinici (revisione veterinaria 06, aggiunte 4-11, 18,
/// 19). Nessuna diagnosi e nessun calcolo di dosi: solo registri,
/// andamenti e promemoria.
class Modules {
  static bool _cond(Dog d, List<String> ks) {
    final c = d.conditions.toLowerCase();
    return ks.any(c.contains);
  }

  static bool isInsulin(String title) {
    final t = title.toLowerCase();
    return [
      'insulin',
      'caninsulin',
      'prozinc',
      'vetsulin',
      'lantus',
      'glargin',
    ].any(t.contains);
  }

  /// Farmaci per le convulsioni, dal nome (principio attivo o nome
  /// commerciale): fenobarbital, levetiracetam, bromuro, imepitoina,
  /// zonisamide (ricerca/26 §5.1).
  static bool isAntiepileptic(String title) => RegExp(
    'fenobarb|phenobarb|gardenal|luminal|soliphen|soriphen|epiphen|'
    'levetiracetam|keppra|bromuro di (potassio|sodio)|potassium bromide|'
    'libromide|imepitoin|pexion|zonisamid',
  ).hasMatch(title.toLowerCase());

  /// Variante dei testi delle dosi (UI-DOS-001, UI-DOS-002): insulina,
  /// antiepilettico o farmaco generico.
  static String doseKind(String title) => isInsulin(title)
      ? 'insulin'
      : isAntiepileptic(title)
      ? 'antiepileptic'
      : 'other';

  static bool diabetic(Dog d, List<HealthRecord> records) =>
      _cond(d, ['diabet']) ||
      records.any((r) => r.dogId == d.id && isInsulin(r.title));

  static bool epileptic(Dog d, List<LogEntry> logs) =>
      _cond(d, ['epiless', 'convulsion', 'crisi']) ||
      logs.any((l) => l.dogId == d.id && l.type == LogType.convulsione);

  /// Cardiopatia nota: dalle patologie o dai farmaci (07 N11). La sola razza
  /// (es. Cavalier) non basta: è una predisposizione, non una diagnosi (N22).
  static bool cardiac(Dog d, [List<HealthRecord> records = const []]) =>
      _cond(d, ['cardi', 'mitral', 'valvol', 'soffio', 'mvd']) ||
      records.any(
        (r) =>
            r.dogId == d.id &&
            RegExp('pimobendan|vetmedin|cardisure|furosemide|torasemide|upcard')
                .hasMatch(r.title.toLowerCase()),
      );

  /// Convulsioni per mese (ultimi [months] mesi), dal più vecchio.
  static List<({DateTime month, int count})> seizuresPerMonth(
    List<LogEntry> logs,
    String dogId,
    DateTime now, {
    int months = 6,
  }) {
    final out = <({DateTime month, int count})>[];
    for (var i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      final n = logs
          .where(
            (l) =>
                l.dogId == dogId &&
                l.type == LogType.convulsione &&
                l.time.year == m.year &&
                l.time.month == m.month,
          )
          .length;
      out.add((month: m, count: n));
    }
    return out;
  }

  // --- Riproduzione -------------------------------------------------------
  static List<ReproEvent> reproOf(List<ReproEvent> all, String dogId) =>
      all.where((e) => e.dogId == dogId).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  static DateTime? lastHeat(Dog d, List<ReproEvent> all) {
    final heats = reproOf(
      all,
      d.id,
    ).where((e) => e.type == ReproEventType.calore);
    if (heats.isNotEmpty) return heats.last.date;
    return d.reproState == ReproState.calore ? d.reproSince : null;
  }

  /// Intervallo medio tra i calori (giorni); 200 (~6-7 mesi) se non noto.
  static int heatIntervalDays(Dog d, List<ReproEvent> all) {
    final heats = reproOf(
      all,
      d.id,
    ).where((e) => e.type == ReproEventType.calore).map((e) => e.date).toList();
    if (heats.length < 2) return 200;
    final gaps = <int>[
      for (var i = 1; i < heats.length; i++)
        heats[i].difference(heats[i - 1]).inDays,
    ];
    return (gaps.reduce((a, b) => a + b) / gaps.length).round();
  }

  static DateTime? nextHeat(Dog d, List<ReproEvent> all) {
    if (d.neutered || d.sex != Sex.femmina) return null;
    final last = lastHeat(d, all);
    return last?.add(Duration(days: heatIntervalDays(d, all)));
  }

  /// Data presunta del parto: accoppiamento + 63 giorni (± 5).
  static DateTime? dueDate(Dog d, List<ReproEvent> all, DateTime now) {
    final ev = reproOf(all, d.id);
    final mating = ev.where((e) => e.type == ReproEventType.accoppiamento);
    if (mating.isEmpty) return null;
    final m = mating.last.date;
    final born = ev.any(
      (e) => e.type == ReproEventType.parto && e.date.isAfter(m),
    );
    if (born || now.difference(m).inDays > 80) return null;
    return m.add(const Duration(days: 63));
  }

  /// Calore che dura da più di 4 settimane (senza "fine calore").
  static bool longHeat(Dog d, List<ReproEvent> all, DateTime now) {
    final ev = reproOf(all, d.id);
    final start = lastHeat(d, all);
    if (start == null) return false;
    final ended = ev.any(
      (e) => e.type == ReproEventType.fineCalore && e.date.isAfter(start),
    );
    final days = now.difference(start).inDays;
    return !ended && days > 28 && days < 60;
  }

  // --- Spese ---------------------------------------------------------------
  /// Detrazione IRPEF spese veterinarie (art. 15 TUIR): 19% della parte
  /// eccedente 129,11 € fino a 550 € di spesa. Da verificare ogni anno.
  static ({double total, double deductible, double refund}) expenses(
    List<HealthRecord> records,
    int year,
  ) {
    final total = records
        .where((r) => r.cost != null && r.date.year == year)
        .fold<double>(0, (a, r) => a + r.cost!);
    final deductible = math.max(0.0, math.min(total, 550) - 129.11);
    return (total: total, deductible: deductible, refund: deductible * 0.19);
  }

  // --- Viaggi --------------------------------------------------------------
  static List<({String item, bool? ok, String note})> travelChecklist(
    Dog d,
    List<HealthRecord> records,
    DateTime departure,
  ) {
    final rabies =
        records
            .where(
              (r) =>
                  r.dogId == d.id &&
                  r.done &&
                  r.type == RecordType.vaccino &&
                  r.title.toLowerCase().contains('rabbia'),
            )
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    // I 21 giorni valgono solo dopo la PRIMA vaccinazione (07 N51).
    final firstRabies = rabies.isEmpty ? null : rabies.last;
    final booster = rabies.length >= 2;
    final rabiesOk =
        rabies.isNotEmpty &&
        (booster || departure.difference(firstRabies!.date).inDays >= 21) &&
        (rabies.first.nextDue == null ||
            rabies.first.nextDue!.isAfter(departure));
    // Voci del catalogo VIA-001…006: titolo = voce, testo = nota.
    ({String item, bool? ok, String note}) via(
      String id,
      bool? ok, [
      Map<String, Object> p = const {},
    ]) {
      final t = ClinicalText(id, p);
      return (item: t.title, ok: ok, note: t.text);
    }

    final last = rabies.isEmpty ? null : rabies.first.date;
    return [
      via('VIA-001', departure.difference(d.birthDate).inDays >= 15 * 7),
      via('VIA-002', d.microchip.isNotEmpty),
      via('VIA-003', rabiesOk, {
        'hasRabies': yesNo(last != null),
        'date': last == null ? '' : '${last.day}/${last.month}/${last.year}',
      }),
      via('VIA-004', null),
      via('VIA-005', null),
      via('VIA-006', null),
    ];
  }

  // --- Qualità della vita (HHHHHMM, Villalobos) ---------------------------
  /// Voci del catalogo SCA-QOL-1…7: (voce, domanda).
  static List<(String, String)> get qolItems => [
    for (var i = 1; i <= 7; i++)
      (ClinicalText('SCA-QOL-$i').title, ClinicalText('SCA-QOL-$i').text),
  ];

  // --- Esami di laboratorio: voci frequenti -------------------------------
  /// Unità degli esami LAB-001…017, nello stesso ordine del catalogo.
  static const _labUnits = [
    'mg/dL',
    'µg/dL',
    'mg/dL',
    'U/L',
    'U/L',
    'mg/dL',
    'µmol/L',
    '%',
    '×10³/µL',
    '×10³/µL',
    'g/dL',
    'g/dL',
    'µg/dL',
    '',
    '',
    'mmHg',
    '',
  ];

  /// Esami frequenti: (nome dal catalogo LAB-nnn, unità).
  static List<(String, String)> get labPresets => [
    for (var i = 0; i < _labUnits.length; i++)
      (
        ClinicalText('LAB-${(i + 1).toString().padLeft(3, '0')}').text,
        _labUnits[i],
      ),
  ];
}
