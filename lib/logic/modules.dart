import 'dart:math' as math;

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
    return [
      (
        item: 'Età minima',
        ok: departure.difference(d.birthDate).inDays >= 15 * 7,
        note:
            'Antirabbico da 12 settimane + 21 giorni: in genere non si viaggia '
            'prima delle 15 settimane di età.',
      ),
      (
        item: 'Microchip registrato',
        ok: d.microchip.isNotEmpty,
        note: 'Obbligatorio e impiantato prima del vaccino antirabbico.',
      ),
      (
        item: 'Vaccino antirabbico valido',
        ok: rabiesOk,
        note: rabies.isEmpty
            ? 'Nessun antirabbico in cartella.'
            : 'La prima vaccinazione è valida dopo 21 giorni; i richiami fatti '
                  'in tempo valgono subito. Durata 1-3 anni secondo la scheda '
                  'tecnica (ultimo: ${rabies.first.date.day}/${rabies.first.date.month}/${rabies.first.date.year}).',
      ),
      (
        item: 'Passaporto europeo per animali',
        ok: null,
        note:
            'Rilasciato dal veterinario ASL o autorizzato. Regole UE: Reg. '
            '(UE) 576/2013 e successive modifiche; verifica prima di partire '
            'sul sito del Ministero della Salute.',
      ),
      (
        item: 'Trattamento contro Echinococcus',
        ok: null,
        note: 'Obbligatorio 24-120 h prima dell\'ingresso in Regno Unito, Irlanda, Finlandia, Norvegia e Malta.',
      ),
      (
        item: 'Rischi parassitari della destinazione',
        ok: null,
        note: 'Chiedi al veterinario: filaria, leishmania e zecche variano molto tra paesi.',
      ),
    ];
  }

  // --- Qualità della vita (HHHHHMM, Villalobos) ---------------------------
  static const qolItems = [
    (
      'Dolore (Hurt)',
      'Il dolore è controllato? Respira bene? 10 = nessun dolore',
    ),
    ('Fame (Hunger)', 'Mangia abbastanza? 10 = appetito normale'),
    ('Idratazione', 'Beve abbastanza? 10 = sì'),
    ('Igiene', 'Si mantiene pulito, niente piaghe? 10 = sì'),
    ('Felicità', 'Interagisce, gioca, risponde? 10 = come sempre'),
    ('Mobilità', 'Si alza e cammina da solo? 10 = sì'),
    ('Più giorni buoni che cattivi', '10 = quasi tutti buoni'),
  ];

  // --- Esami di laboratorio: voci frequenti -------------------------------
  static const labPresets = <(String, String)>[
    ('Creatinina', 'mg/dL'),
    ('SDMA', 'µg/dL'),
    ('Urea (BUN)', 'mg/dL'),
    ('ALT', 'U/L'),
    ('Fosfatasi alcalina (ALP)', 'U/L'),
    ('Glucosio', 'mg/dL'),
    ('Fruttosamina', 'µmol/L'),
    ('Ematocrito', '%'),
    ('Globuli bianchi', '×10³/µL'),
    ('Piastrine', '×10³/µL'),
    ('Proteine totali', 'g/dL'),
    ('Albumina', 'g/dL'),
    ('T4 totale', 'µg/dL'),
    ('Peso specifico urinario', ''),
    ('UPC (proteinuria)', ''),
    ('Pressione sistolica', 'mmHg'),
    ('Titolo Leishmania', ''),
  ];
}
