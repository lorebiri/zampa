import '../l10n/clinical_text.dart';
import '../models.dart';
import 'potty_predictor.dart';

/// Piano di prevenzione per l'Italia: WSAVA 2024 (vaccini), ESCCAP Italia
/// (parassiti), con le correzioni della revisione veterinaria (ricerca/06).
/// Le date proposte vanno sempre confermate con il veterinario: l'app
/// propone, il veterinario decide. Titoli e note sono voci del catalogo
/// clinico (PRV-001…016): il titolo diventa il nome della voce in cartella.
class PreventionPlanner {
  /// Inizio della stagione di profilassi della filariosi per area.
  static DateTime heartwormStart(Dog dog, int year) =>
      DateTime(year, dog.region == Region.sud ? 4 : 5, 1);

  /// Voci suggerite (non ancora presenti nella cartella) per il cane.
  static List<HealthRecord> suggest(
    Dog dog,
    List<HealthRecord> existing,
    DateTime now,
  ) {
    final out = <HealthRecord>[];
    final mine = existing.where((r) => r.dogId == dog.id).toList();
    bool has(String title) =>
        mine.any((r) => r.title.toLowerCase() == title.toLowerCase());
    bool hasLike(String part, {RecordType? type}) => mine.any(
      (r) =>
          r.title.toLowerCase().contains(part) &&
          (type == null || r.type == type),
    );
    void add(
      RecordType t,
      String id,
      DateTime date, [
      Map<String, Object> p = const {},
    ]) {
      final text = ClinicalText(id, p);
      final title = text.title;
      if (has(title)) return;
      if (date.isBefore(now.subtract(const Duration(days: 7)))) return;
      out.add(
        HealthRecord(
          id: newId(),
          dogId: dog.id,
          type: t,
          title: title,
          date: date,
          done: false,
          notes: text.text,
        ),
      );
    }

    final birth = dog.birthDate;
    DateTime weeks(int w) => birth.add(Duration(days: w * 7));
    final ageWeeks = now.difference(birth).inDays / 7;
    final ageMonths = dog.ageInMonths(now);
    final today = DateTime(now.year, now.month, now.day);

    // --- Microchip e anagrafe ---------------------------------------------
    if (dog.microchip.trim().isEmpty) {
      final due = birth.add(const Duration(days: 60));
      add(RecordType.visita, 'PRV-001', due.isAfter(today) ? due : today);
    } else {
      add(RecordType.visita, 'PRV-002', today.add(const Duration(days: 14)), {
        'microchip': dog.microchip,
      });
    }

    // --- Vaccini ------------------------------------------------------------
    final hasCore = hasLike('core', type: RecordType.vaccino);
    if (ageWeeks < 16) {
      add(RecordType.vaccino, 'PRV-003', weeks(8), {'dose': 'first'});
      add(RecordType.vaccino, 'PRV-003', weeks(12), {'dose': 'second'});
      add(RecordType.vaccino, 'PRV-003', weeks(16), {'dose': 'third'});
    } else if (!hasCore) {
      add(RecordType.vaccino, 'PRV-004', today);
    }
    if (ageWeeks < 26) {
      add(RecordType.vaccino, 'PRV-005', weeks(26));
    }
    final hasLepto = hasLike('lepto', type: RecordType.vaccino);
    if (ageWeeks < 26 && !hasLepto) {
      final first = ageWeeks < 8 ? weeks(8) : today;
      add(RecordType.vaccino, 'PRV-006', first, {'dose': 'first'});
      add(RecordType.vaccino, 'PRV-006', first.add(const Duration(days: 28)), {
        'dose': 'second',
      });
    } else if (!hasLepto) {
      add(RecordType.vaccino, 'PRV-007', today.add(const Duration(days: 30)));
    }

    // --- Vermi intestinali (ESCCAP GL1) -------------------------------------
    if (ageMonths < 6) {
      add(RecordType.antiparassitario, 'PRV-008', today);
    } else {
      add(RecordType.esame, 'PRV-009', today.add(const Duration(days: 30)));
    }

    // --- Filariosi ------------------------------------------------------------
    final protectedRecently = mine.any(
      (r) =>
          r.done &&
          r.title.toLowerCase().contains('filar') &&
          now.difference(r.date).inDays <= 45,
    );
    final seasonYear = now.month >= 6 ? now.year + 1 : now.year;
    final start = heartwormStart(dog, seasonYear);
    final inSeason = now.month >= start.month && now.month <= 12;
    if (inSeason && !protectedRecently && now.month <= 10 && ageWeeks >= 6) {
      add(RecordType.antiparassitario, 'PRV-010', today, {
        'year': '${now.year}',
      });
    } else if ((now.month == 11 || now.month == 12) &&
        !protectedRecently &&
        ageMonths >= 7) {
      add(RecordType.visita, 'PRV-011', today);
    }
    if (ageMonths + (start.difference(now).inDays / 30) >= 7) {
      add(
        RecordType.esame,
        'PRV-012',
        DateTime(start.year, start.month - 1, 15),
        {'year': '${start.year}'},
      );
    }
    if (start.difference(birth).inDays >= 42) {
      add(RecordType.antiparassitario, 'PRV-013', start, {
        'year': '${start.year}',
        'south': yesNo(dog.region == Region.sud),
      });
    }

    // --- Flebotomi (leishmaniosi), zecche e pulci ---------------------------
    // Finita la stagione (da novembre, al Nord da ottobre) si propone la
    // prossima primavera (07 N29).
    final endMonth = dog.region == Region.nord ? 10 : 11;
    final sandflyYear = now.month >= endMonth ? now.year + 1 : now.year;
    final sandfly = DateTime(sandflyYear, 4, 1);
    add(
      RecordType.antiparassitario,
      'PRV-014',
      sandfly.isBefore(today) ? today : sandfly,
      {'year': '${sandfly.year}'},
    );
    add(RecordType.antiparassitario, 'PRV-015', today);

    // --- Visite ---------------------------------------------------------------
    final stage = lifeStageOf(dog, now);
    add(RecordType.visita, 'PRV-016', today.add(const Duration(days: 30)), {
      'senior': yesNo(stage == LifeStage.anziano),
    });
    return out;
  }

  /// Intervallo suggerito per la prossima scadenza dopo una voce completata.
  /// [dog] serve per gli intervalli che dipendono dall'età (sverminazione).
  static Duration? suggestedInterval(HealthRecord r, {Dog? dog, DateTime? at}) {
    final t = r.title.toLowerCase();
    final when = at ?? r.date;
    switch (r.type) {
      case RecordType.vaccino:
        // Prima le dosi del ciclo iniziale, poi i richiami.
        // Leptospirosi (07 N10): dopo la 1ª dose la 2ª è già pianificata;
        // dopo la 2ª (o un richiamo) si riparte ogni anno.
        if (t.contains('lepto')) {
          if (t.contains('1ª dose')) return null;
          return const Duration(days: 365);
        }
        if (t.contains('core') && t.contains('ª dose')) return null;
        if (t.contains('dose') && !t.contains('verifica')) return null;
        if (t.contains('leish')) return const Duration(days: 365);
        if (t.contains('tosse')) return const Duration(days: 365);
        if (t.contains('rabbia')) {
          return const Duration(days: 365); // secondo scheda tecnica (1-3 anni)
        }
        return const Duration(days: 365 * 3);
      case RecordType.antiparassitario:
        if (t.contains('sverm')) {
          if (dog == null) return const Duration(days: 90);
          final w = when.difference(dog.birthDate).inDays / 7;
          if (w < 10) return const Duration(days: 14);
          if (w < 26) return const Duration(days: 30);
          return const Duration(days: 90);
        }
        if (t.contains('filar')) {
          if (t.contains('12 mesi')) return const Duration(days: 365);
          if (t.contains('6 mesi')) return const Duration(days: 182);
          if (when.month >= 12) {
            // Dopo la dose di dicembre si riparte a primavera.
            final y = when.year + 1;
            final start = dog == null
                ? DateTime(y, 5, 1)
                : heartwormStart(dog, y);
            return start.difference(when);
          }
          return const Duration(days: 30);
        }
        if (t.contains('collare')) return const Duration(days: 182);
        if (t.contains('pappataci') || t.contains('spot')) {
          return const Duration(days: 25);
        }
        return const Duration(days: 30);
      case RecordType.visita:
        if (t.contains('semestr') || t.contains('geriatr')) {
          return const Duration(days: 182);
        }
        if (t.contains('microchip') || t.contains('filariosi: chiedi')) {
          return null;
        }
        return const Duration(days: 365);
      case RecordType.esame:
        if (t.contains('test') || t.contains('filar') || t.contains('leish')) {
          return const Duration(days: 365);
        }
        if (t.contains('feci')) return const Duration(days: 182);
        return null;
      default:
        return null;
    }
  }
}

class DueItem {
  DueItem(this.record, this.due);
  final HealthRecord record;
  final DateTime due;
  bool overdue(DateTime now) => due.isBefore(now);
}

/// Scadenze: voci pianificate non ancora fatte + prossime scadenze delle
/// voci fatte, se non sono già state sostituite da una voce più recente.
List<DueItem> dueItems(List<HealthRecord> records, String dogId) {
  final mine = records.where((r) => r.dogId == dogId).toList();
  final out = <DueItem>[];
  for (final r in mine) {
    if (!r.done) {
      out.add(DueItem(r, r.date));
    } else if (r.nextDue != null) {
      final superseded = mine.any(
        (o) =>
            o.id != r.id &&
            o.done &&
            o.type == r.type &&
            o.title.toLowerCase() == r.title.toLowerCase() &&
            o.date.isAfter(r.date),
      );
      if (!superseded) out.add(DueItem(r, r.nextDue!));
    }
  }
  out.sort((a, b) => a.due.compareTo(b.due));
  return out;
}
