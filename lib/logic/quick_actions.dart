import 'dart:convert';

import '../models.dart';

/// Azioni rapide nella notifica del promemoria della pipì (ricerca/28).
///
/// I testi per l'utente (etichette dei bottoni, promemoria riproposto) sono
/// in `QuickActionTexts` (lib/notifications.dart), fuori da lib/logic/.
///
/// Tutto qui è logica pura, senza piattaforma: cosa c'è nel payload della
/// notifica, come si salva un'azione toccata ad app chiusa e cosa fa al
/// diario («Fatta ✓») e al piano dei promemoria («Non ancora»).
class QuickActions {
  QuickActions._();

  /// Identificativi delle azioni (Android `AndroidNotificationAction.id`,
  /// iOS `DarwinNotificationAction.identifier`).
  static const done = 'lulu_fatta';
  static const notYet = 'lulu_non_ancora';

  /// Categoria iOS/macOS con i due bottoni.
  static const category = 'lulu_uscita_pipi';

  /// «Non ancora» ripropone il promemoria dopo 15 minuti.
  static const snoozeDelay = Duration(minutes: 15);

  /// Un'azione rimasta in coda più di 3 giorni non si applica più (per
  /// esempio un telefono rimasto spento): meglio niente che un dato vecchio.
  static const maxAge = Duration(days: 3);

  /// Prefisso delle chiavi in SharedPreferences: una chiave per azione, così
  /// chi scrive (isolato in background) e chi legge (app) non si
  /// sovrascrivono mai a vicenda una lista comune.
  static const prefsPrefix = 'lulu_qa_';
}

/// Contenuto del payload della notifica «È quasi ora di uscire».
class ReminderPayload {
  const ReminderPayload({
    required this.dogId,
    required this.dogName,
    required this.notificationId,
    this.need = 'pipi',
  });

  /// Versione del formato: un payload sconosciuto si ignora, mai un errore.
  static const version = 1;
  static const kind = 'uscita';

  final String dogId;
  final String dogName;

  /// Id della notifica, per riproporla con lo stesso id (sostituisce, non
  /// si somma).
  final int notificationId;
  final String need;

  String encode() => jsonEncode({
    'v': version,
    'k': kind,
    'need': need,
    'dog': dogId,
    'name': dogName,
    'nid': notificationId,
  });

  /// null se il payload manca, è di un'altra notifica o è rovinato.
  static ReminderPayload? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw);
      if (j is! Map) return null;
      if (j['v'] != version || j['k'] != kind) return null;
      final dog = j['dog'];
      final nid = j['nid'];
      if (dog is! String || dog.isEmpty || nid is! int) return null;
      final need = j['need'];
      if (need != 'pipi') return null; // per ora solo la pipì ha i bottoni
      final name = j['name'];
      return ReminderPayload(
        dogId: dog,
        dogName: name is String ? name : '',
        notificationId: nid,
        need: need as String,
      );
    } catch (_) {
      return null;
    }
  }
}

enum QuickActionKind { done, notYet }

/// Un tocco su un bottone della notifica, con l'ora del tocco (non quella
/// in cui l'app lo applica).
class QuickAction {
  QuickAction({
    required this.id,
    required this.kind,
    required this.dogId,
    required this.at,
  });

  /// Identificativo unico del tocco: rende l'applicazione idempotente (la
  /// pipì registrata ha id `qa_<id>`, mai due volte).
  final String id;
  final QuickActionKind kind;
  final String dogId;
  final DateTime at;

  /// Dall'id del bottone e dal payload; null se non è un'azione nostra.
  static QuickAction? fromResponse({
    required String? actionId,
    required String? payload,
    required DateTime at,
    required String id,
  }) {
    final kind = switch (actionId) {
      QuickActions.done => QuickActionKind.done,
      QuickActions.notYet => QuickActionKind.notYet,
      _ => null,
    };
    if (kind == null) return null;
    final p = ReminderPayload.tryParse(payload);
    if (p == null) return null;
    return QuickAction(id: id, kind: kind, dogId: p.dogId, at: at);
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'dog': dogId,
    'at': at.toUtc().toIso8601String(),
  };

  static QuickAction? tryFromJson(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      final kind = QuickActionKind.values.firstWhere(
        (k) => k.name == j['kind'],
      );
      return QuickAction(
        id: j['id']! as String,
        kind: kind,
        dogId: j['dog']! as String,
        at: DateTime.parse(j['at']! as String).toLocal(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// «Non ancora» per un cane: il promemoria torna a [until]. Scade da solo
/// se nel diario compare una pipì dopo [since] o se [until] è passato.
class Snooze {
  const Snooze({required this.since, required this.until});
  final DateTime since;
  final DateTime until;

  Map<String, Object?> toJson() => {
    'since': since.toUtc().toIso8601String(),
    'until': until.toUtc().toIso8601String(),
  };

  static Snooze? tryFromJson(Object? j) {
    try {
      final m = j! as Map;
      return Snooze(
        since: DateTime.parse(m['since'] as String).toLocal(),
        until: DateTime.parse(m['until'] as String).toLocal(),
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, Snooze> decodeAll(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      return {for (final e in j.entries) e.key: ?Snooze.tryFromJson(e.value)};
    } catch (_) {
      return {};
    }
  }

  static String encodeAll(Map<String, Snooze> m) =>
      jsonEncode({for (final e in m.entries) e.key: e.value.toJson()});
}

/// Il rinvio vale ancora? (nel futuro e nessuna pipì registrata dopo).
DateTime? activeSnoozeUntil(
  Snooze? s,
  Iterable<LogEntry> dogLogs,
  DateTime now,
) {
  if (s == null || !s.until.isAfter(now)) return null;
  final peeAfter = dogLogs.any(
    (l) => l.type == LogType.pipi && l.time.isAfter(s.since),
  );
  return peeAfter ? null : s.until;
}

/// Risultato dell'applicazione di una coda di azioni.
class QuickActionResult {
  QuickActionResult(this.newLogs, this.snoozes, this.applied);

  /// Pipì da aggiungere al diario.
  final List<LogEntry> newLogs;

  /// Rinvii aggiornati (tutti i cani).
  final Map<String, Snooze> snoozes;

  /// Id delle azioni consumate (applicate o scartate): da togliere dalla coda.
  final Set<String> applied;

  bool get changed => newLogs.isNotEmpty || applied.isNotEmpty;
}

/// Applica le azioni in ordine di tocco. Funzione pura.
///
/// - «Fatta ✓»: una pipì fuori casa (indoor false) all'ora del tocco, per il
///   cane della notifica; il rinvio di quel cane si annulla.
/// - «Non ancora»: nessuna registrazione; il promemoria torna dopo 15 minuti.
/// - Azioni di cani non più presenti, del cane di esempio, troppo vecchie o
///   già applicate: scartate senza errori.
QuickActionResult reduceQuickActions({
  required Iterable<QuickAction> actions,
  required Set<String> dogIds,
  required Iterable<LogEntry> logs,
  required Map<String, Snooze> snoozes,
  required DateTime now,
}) {
  final existing = {for (final l in logs) l.id};
  final out = <LogEntry>[];
  final sn = Map<String, Snooze>.of(snoozes);
  final consumed = <String>{};
  final sorted = actions.toList()..sort((a, b) => a.at.compareTo(b.at));
  for (final a in sorted) {
    consumed.add(a.id);
    if (!dogIds.contains(a.dogId) || isDemoId(a.dogId)) continue;
    if (now.difference(a.at) > QuickActions.maxAge) continue;
    // Un orario nel futuro (orologio cambiato) si porta ad adesso.
    final at = a.at.isAfter(now) ? now : a.at;
    switch (a.kind) {
      case QuickActionKind.done:
        final id = 'qa_${a.id}';
        if (existing.contains(id)) continue;
        existing.add(id);
        out.add(LogEntry(id: id, dogId: a.dogId, type: LogType.pipi, time: at));
        sn.remove(a.dogId);
      case QuickActionKind.notYet:
        sn[a.dogId] = Snooze(
          since: at,
          until: at.add(QuickActions.snoozeDelay),
        );
    }
  }
  // Rinvii scaduti: via.
  sn.removeWhere((_, s) => !s.until.isAfter(now));
  return QuickActionResult(out, sn, consumed);
}
