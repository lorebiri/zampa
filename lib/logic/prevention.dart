import '../models.dart';
import 'potty_predictor.dart';

/// Piano di prevenzione per l'Italia: WSAVA 2024 (vaccini), ESCCAP Italia
/// (parassiti), con le correzioni della revisione veterinaria (ricerca/06).
/// Le date proposte vanno sempre confermate con il veterinario: l'app
/// propone, il veterinario decide.
const _cats =
    'Gli spot-on e alcuni collari per cani contengono permetrina, molto '
    'tossica per i gatti: se in casa c\'è un gatto chiedi al veterinario un '
    'prodotto adatto e tienili separati finché il prodotto è asciutto.';

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
    void add(RecordType t, String title, DateTime date, String notes) {
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
          notes: notes,
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
      add(
        RecordType.visita,
        'Microchip e iscrizione all\'anagrafe canina',
        due.isAfter(today) ? due : today,
        'Obbligatoria per legge (L. 281/1991, O.M. 6/8/2008, anagrafe '
            'SINAC): entro 60 giorni dalla nascita e comunque prima della '
            'cessione. Se hai adottato il cane, verifica che sia intestato a te.',
      );
    } else {
      add(
        RecordType.visita,
        'Verifica che l\'anagrafe sia intestata a te',
        today.add(const Duration(days: 14)),
        'Controlla sul portale dell\'anagrafe canina della tua Regione (o '
            'SINAC) che il microchip ${dog.microchip} sia intestato a te e '
            'che indirizzo e telefono siano aggiornati.',
      );
    }

    // --- Vaccini ------------------------------------------------------------
    const core = 'Vaccino core (cimurro, epatite, parvovirosi)';
    final hasCore = hasLike('core', type: RecordType.vaccino);
    if (ageWeeks < 16) {
      add(
        RecordType.vaccino,
        '$core – 1ª dose',
        weeks(8),
        'WSAVA: prima dose a 6-8 settimane.',
      );
      add(
        RecordType.vaccino,
        '$core – 2ª dose',
        weeks(12),
        'Ogni 2-4 settimane fino a 16 settimane o più.',
      );
      add(
        RecordType.vaccino,
        '$core – 3ª dose',
        weeks(16),
        'L\'ultima dose non prima delle 16 settimane.',
      );
    } else if (!hasCore) {
      add(
        RecordType.vaccino,
        '$core – verifica il libretto',
        today,
        'Nessun vaccino core registrato. Se non trovi il libretto, il '
            'veterinario può fare una dose (WSAVA considera protettiva una dose '
            'dei vaccini core vivi attenuati nell\'adulto) oppure dosare gli '
            'anticorpi.',
      );
    }
    if (ageWeeks < 26) {
      add(
        RecordType.vaccino,
        '$core – richiamo',
        weeks(26),
        'WSAVA 2024: richiamo a 26 settimane (oppure a 12 mesi secondo il '
            'veterinario), poi ogni 3 anni se il vaccino usato lo prevede.',
      );
    }
    final hasLepto = hasLike('lepto', type: RecordType.vaccino);
    if (ageWeeks < 26 && !hasLepto) {
      final first = ageWeeks < 8 ? weeks(8) : today;
      add(
        RecordType.vaccino,
        'Leptospirosi – 1ª dose',
        first,
        'Consigliata in Italia: 2 dosi a 2-4 settimane di distanza, poi '
            'richiamo annuale.',
      );
      add(
        RecordType.vaccino,
        'Leptospirosi – 2ª dose',
        first.add(const Duration(days: 28)),
        'Completa l\'avvio vaccinale.',
      );
    } else if (!hasLepto) {
      add(
        RecordType.vaccino,
        'Leptospirosi',
        today.add(const Duration(days: 30)),
        'Se non è mai stato vaccinato servono 2 dosi a 2-4 settimane; poi '
            'richiamo annuale. Verifica il libretto.',
      );
    }

    // --- Vermi intestinali (ESCCAP GL1) -------------------------------------
    if (ageMonths < 6) {
      add(
        RecordType.antiparassitario,
        'Sverminazione cucciolo',
        today,
        'Ogni 2 settimane fino a 2 settimane dopo lo svezzamento, poi ogni '
            'mese fino a 6 mesi.',
      );
    } else {
      add(
        RecordType.esame,
        'Esame delle feci',
        today.add(const Duration(days: 30)),
        'Da 1 a 4 volte l\'anno secondo lo stile di vita (o sverminazione '
            'periodica secondo il veterinario).',
      );
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
      add(
        RecordType.antiparassitario,
        'Prevenzione filariosi (stagione ${now.year})',
        today,
        'ESCCAP Italia: profilassi mensile fino a dicembre (un mese dopo la '
            'fine della stagione delle zanzare). Se non era protetto, chiedi al '
            'veterinario se serve prima un test.',
      );
    } else if ((now.month == 11 || now.month == 12) &&
        !protectedRecently &&
        ageMonths >= 7) {
      add(
        RecordType.visita,
        'Filariosi: chiedi al veterinario se fare una dose ora e il test',
        today,
        'Se non era protetto quest\'estate, il veterinario valuterà un test '
            '(antigene + microfilarie) prima di iniziare; il test affidabile si '
            'fa in primavera.',
      );
    }
    if (ageMonths + (start.difference(now).inDays / 30) >= 7) {
      add(
        RecordType.esame,
        'Test filariosi e leishmaniosi annuale (${start.year})',
        DateTime(start.year, start.month - 1, 15),
        'Prima di iniziare la profilassi: antigene della filaria e, nelle '
            'zone a rischio, test per la leishmania.',
      );
    }
    if (start.difference(birth).inDays >= 42) {
      add(
        RecordType.antiparassitario,
        'Inizio profilassi filariosi ${start.year}',
        start,
        'Mensile fino a dicembre${dog.region == Region.sud ? ' (al Sud valuta con il veterinario la copertura tutto l\'anno)' : ''}. '
            'Nel cucciolo dalle 6-8 settimane, secondo il prodotto. Esistono '
            'anche iniezioni a lento rilascio da 6 o 12 mesi.',
      );
    }

    // --- Flebotomi (leishmaniosi), zecche e pulci ---------------------------
    // Finita la stagione (da novembre, al Nord da ottobre) si propone la
    // prossima primavera (07 N29).
    final endMonth = dog.region == Region.nord ? 10 : 11;
    final sandflyYear = now.month >= endMonth ? now.year + 1 : now.year;
    final sandfly = DateTime(sandflyYear, 4, 1);
    add(
      RecordType.antiparassitario,
      'Repellente anti-pappataci (leishmaniosi) ${sandfly.year}',
      sandfly.isBefore(today) ? today : sandfly,
      'Da aprile a novembre per tutti i cani, anche al Nord: la '
          'leishmaniosi è ormai presente in molte aree. Il collare dura secondo '
          'il prodotto, lo spot-on 3-4 settimane. $_cats',
    );
    add(
      RecordType.antiparassitario,
      'Antiparassitario esterno (zecche e pulci)',
      today,
      'Frequenza secondo il prodotto (1-3 mesi). Al Centro-Sud anche tutto '
          'l\'anno. $_cats',
    );

    // --- Visite ---------------------------------------------------------------
    final stage = lifeStageOf(dog, now);
    add(
      RecordType.visita,
      stage == LifeStage.anziano
          ? 'Controllo geriatrico semestrale'
          : 'Visita di controllo annuale',
      today.add(const Duration(days: 30)),
      stage == LifeStage.anziano
          ? 'Per i cani anziani: visita ed esami del sangue e delle urine ogni '
                '6 mesi.'
          : 'Visita generale, peso, denti, richiami.',
    );
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
