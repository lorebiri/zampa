import 'dart:convert';

/// Sincronizzazione offline-first.
///
/// L'app lavora sempre sui dati locali. Quando l'utente ha un account, il
/// motore confronta lo stato attuale con l'"ombra" (l'ultimo stato
/// sincronizzato, con la versione del server su cui si basa) per capire cosa
/// è cambiato sul telefono, scarica le novità dal server e invia le modifiche
/// locali.
///
/// Concorrenza ottimistica (rapporto 11, A5): ogni modifica a un oggetto già
/// sul server parte dalla versione (`updated_at` del server) su cui si basa;
/// il server la accetta solo se nel frattempo nessun altro l'ha cambiata.
/// Altrimenti il motore riscarica e riapplica:
/// - cani: unione campo per campo con l'ultima versione comune; se lo stesso
///   campo è cambiato su entrambi i lati vince il server (chi ha scritto per
///   primo) e la modifica locale sostituita viene segnalata in
///   [SyncResult.conflicts], mai persa in silenzio;
/// - voci: vince il server e la versione locale sostituita viene segnalata.
///
/// Eliminazioni: un'eliminazione (locale o remota) vince sempre. Le
/// eliminazioni locali diventano "lapidi" (deleted = true) così gli altri
/// dispositivi le ricevono. Un familiare che elimina un cane condiviso esce
/// dalla condivisione (A8).
///
/// Ombra vuota (dopo un reset o un cambio di account, A4): per gli oggetti che
/// il server ha già vince la copia del server; si inviano solo quelli assenti.

/// Riga remota (cane o voce).
class RemoteRow {
  RemoteRow({
    required this.kind,
    required this.id,
    required this.data,
    required this.updatedAt,
    this.dogId,
    this.deleted = false,
    this.owner,
    String? version,
    this.base,
  }) : version = version ?? updatedAt.toUtc().toIso8601String();

  /// 'dog' oppure uno dei tipi di voce: log, record, weight, dose, repro,
  /// qol, lab.
  final String kind;
  final String id;
  final String? dogId;
  final Map<String, Object?> data;
  final DateTime updatedAt;
  final bool deleted;
  final String? owner;

  /// Versione assegnata dal server: `updated_at` così come lo restituisce il
  /// server (testo esatto, per non perdere i microsecondi).
  final String version;

  /// Solo in invio: versione del server su cui si basa la modifica locale.
  /// Se presente, il server aggiorna solo se la riga ha ancora questa
  /// versione; se è null l'aggiornamento è incondizionato (oggetti nuovi,
  /// lapidi e stato di sincronizzazione di versioni precedenti dell'app).
  final String? base;
}

/// Esito di un invio al server.
class PushResult {
  PushResult({Map<String, String>? versions, Set<String>? conflicts})
    : versions = versions ?? {},
      conflicts = conflicts ?? {};

  /// id → nuova versione assegnata dal server alle righe scritte.
  final Map<String, String> versions;

  /// id delle righe non scritte perché sul server erano cambiate rispetto
  /// alla versione di base (concorrenza ottimistica).
  final Set<String> conflicts;
}

/// Server remoto (Supabase in produzione, simulato nei test).
///
/// Contratto degli invii: le righe con [RemoteRow.base] si scrivono solo se
/// la versione sul server coincide, altrimenti finiscono in
/// [PushResult.conflicts]. Una scrittura impedita dai permessi (riga non
/// visibile o non modificabile) è un errore, mai un conflitto.
abstract class SyncBackend {
  String? get userId;
  Future<List<String>> memberDogIds();
  Future<List<RemoteRow>> pullDogs(DateTime? since);
  Future<List<RemoteRow>> pullEntries(DateTime? since);
  Future<PushResult> insertDogs(List<RemoteRow> rows);
  Future<PushResult> updateDogs(List<RemoteRow> rows);
  Future<PushResult> upsertEntries(List<RemoteRow> rows);
  Future<String> createInvite(String dogId);
  Future<String> acceptInvite(String code);
  Future<void> leaveDog(String dogId);
  Future<void> deleteAccount();
}

/// Modifica locale sostituita da una modifica remota concorrente.
class SyncConflict {
  SyncConflict({
    required this.kind,
    required this.id,
    required this.dogId,
    required this.fields,
    required this.local,
    required this.remote,
  });
  final String kind;
  final String id;
  final String dogId;

  /// Campi in cui ha prevalso il server (vuoto per le voci: oggetto intero).
  final List<String> fields;

  /// Versione locale sostituita (per poterla mostrare o ripristinare).
  final Map<String, Object?> local;

  /// Versione del server che ha prevalso.
  final Map<String, Object?> remote;

  @override
  String toString() => fields.isEmpty
      ? '$kind $id: tenuta la versione del server'
      : '$kind $id: tenuti dal server ${fields.join(', ')}';
}

/// Oggetto locale sincronizzabile.
class LocalItem {
  LocalItem(this.kind, this.id, this.dogId, this.data);
  final String kind;
  final String id;
  final String dogId;
  final Map<String, Object?> data;
  String get key => '$kind:$id';
}

/// Ciò che il motore chiede all'archivio locale.
abstract class SyncTarget {
  List<LocalItem> syncItems();
  void applyRemote(String kind, Map<String, Object?> data);
  void removeLocal(String kind, String id);
  Future<void> persistAfterSync();
  Map<String, Object?>? loadSyncState();
  Future<void> saveSyncState(Map<String, Object?> state);
}

class SyncResult {
  SyncResult(
    this.pulled,
    this.pushed,
    this.removed, [
    this.conflicts = const [],
  ]);
  final int pulled;
  final int pushed;
  final int removed;

  /// Modifiche locali sostituite da modifiche concorrenti di altri
  /// dispositivi: vanno mostrate all'utente.
  final List<SyncConflict> conflicts;
  @override
  String toString() =>
      'ricevuti $pulled, inviati $pushed, rimossi $removed'
      '${conflicts.isEmpty ? '' : ', conflitti ${conflicts.length}'}';
}

class SyncEngine {
  SyncEngine(this.backend, this.target) {
    final s = target.loadSyncState();
    if (s != null) {
      _shadow.addAll(
        ((s['shadow'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(k as String, (v as Map).cast<String, Object?>()),
        ),
      );
      _owners.addAll(
        ((s['owners'] as Map?) ?? const {}).cast<String, String>(),
      );
      final lp = s['lastPull'] as String?;
      _lastPull = lp == null ? null : DateTime.parse(lp);
      _user = s['user'] as String?;
    }
  }

  final SyncBackend backend;
  final SyncTarget target;

  /// Numero massimo di giri ricezione-invio in una sincronizzazione quando il
  /// server segnala conflitti; quelli rimasti si riprovano alla successiva.
  static const maxRounds = 3;

  /// key → {json, dogId, v}: ultimo stato sincronizzato e versione del
  /// server su cui si basa (v manca negli stati salvati da versioni vecchie).
  final _shadow = <String, Map<String, Object?>>{};

  /// Proprietario remoto di ciascun cane già presente sul server.
  final _owners = <String, String>{};
  DateTime? _lastPull;
  String? _user;
  DateTime? lastSync;
  bool _running = false;

  bool get busy => _running;

  /// Proprietario remoto di un cane (null se il cane non è ancora sul server).
  String? ownerOf(String dogId) => _owners[dogId];

  static String _enc(Object? m) => jsonEncode(m);

  static Map<String, Object?> _dec(String json) =>
      (jsonDecode(json) as Map).cast<String, Object?>();

  Future<void> _saveState() => target.saveSyncState({
    'shadow': _shadow,
    'owners': _owners,
    'lastPull': _lastPull?.toIso8601String(),
    'user': _user,
  });

  /// Dimentica lo stato di sincronizzazione (es. dopo l'uscita dall'account).
  Future<void> reset() async {
    _shadow.clear();
    _owners.clear();
    _lastPull = null;
    _user = null;
    await _saveState();
  }

  /// Unione a tre vie, campo per campo (primo livello del JSON): un campo
  /// cambiato da una sola parte prende quel valore; se è cambiato da entrambe
  /// in modo diverso vince [remote] e il nome del campo finisce in [lost].
  static Map<String, Object?> merge3(
    Map<String, Object?> base,
    Map<String, Object?> local,
    Map<String, Object?> remote,
    List<String> lost,
  ) {
    final out = <String, Object?>{};
    for (final k in <String>{...base.keys, ...local.keys, ...remote.keys}) {
      final b = _enc(base[k]), l = _enc(local[k]), r = _enc(remote[k]);
      final takeLocal = l != b && l != r && r == b;
      if (l != b && l != r && r != b) lost.add(k);
      final src = takeLocal ? local : remote;
      if (src.containsKey(k)) out[k] = src[k];
    }
    return out;
  }

  Future<SyncResult?> sync({DateTime? now}) async {
    final uid = backend.userId;
    if (uid == null || _running) return null;
    _running = true;
    try {
      // Cambio di account: si riparte da zero. Con l'ombra vuota vince la
      // copia del server per gli oggetti che ha già (A4).
      if (_user != null && _user != uid) {
        _shadow.clear();
        _owners.clear();
        _lastPull = null;
      }
      _user = uid;
      final t = now ?? DateTime.now().toUtc();
      var pulled = 0, removed = 0, pushed = 0;
      final conflicts = <SyncConflict>[];
      final since = _lastPull?.subtract(const Duration(minutes: 2));
      var maxSeen = _lastPull;

      for (var round = 0; round < maxRounds; round++) {
        // 1) Ricezione.
        final remoteDogs = await backend.pullDogs(since);
        final remoteEntries = await backend.pullEntries(since);
        final current = {for (final i in target.syncItems()) i.key: i};
        for (final r in [...remoteDogs, ...remoteEntries]) {
          if (maxSeen == null || r.updatedAt.isAfter(maxSeen)) {
            maxSeen = r.updatedAt;
          }
          final key = '${r.kind}:${r.id}';
          if (r.kind == 'dog' && r.owner != null) _owners[r.id] = r.owner!;
          final local = current[key];
          final sh = _shadow[key];
          final shadowJson = sh?['json'] as String?;
          if (r.deleted) {
            // Un'eliminazione remota vince sempre.
            if (local != null) {
              target.removeLocal(r.kind, r.id);
              removed++;
            }
            _shadow.remove(key);
            continue;
          }
          final remoteJson = _enc(r.data);
          final shadowRow = <String, Object?>{
            'json': remoteJson,
            'dogId': r.dogId ?? r.id,
            'v': r.version,
          };
          // Versione già nota (per esempio scritta da questo telefono): non
          // c'è nulla di nuovo da applicare.
          if (sh != null && sh['v'] == r.version) continue;
          if (sh != null && sh['v'] == null && shadowJson == remoteJson) {
            sh['v'] = r.version; // stato di una versione vecchia dell'app
            continue;
          }
          if (local == null) {
            // Eliminato sul telefono e non ancora comunicato: l'eliminazione
            // vince (la lapide parte senza condizioni). Altrimenti è nuovo.
            if (shadowJson != null) continue;
            target.applyRemote(r.kind, r.data);
            pulled++;
            _shadow[key] = shadowRow;
            continue;
          }
          final localJson = _enc(local.data);
          if (shadowJson == null || localJson == shadowJson) {
            // Nessuna modifica locale, oppure ombra vuota dopo un reset o un
            // cambio di account (A4): vince il server.
            if (localJson != remoteJson) {
              target.applyRemote(r.kind, r.data);
              pulled++;
            }
            _shadow[key] = shadowRow;
            continue;
          }
          // Modifica locale e modifica remota concorrenti (A5). L'ombra passa
          // alla versione remota: ciò che resta da inviare parte da lì.
          _shadow[key] = shadowRow;
          if (localJson == remoteJson) continue;
          final lost = <String>[];
          final Map<String, Object?> result;
          if (r.kind == 'dog') {
            result = merge3(_dec(shadowJson), local.data, r.data, lost);
          } else {
            result = r.data;
          }
          if (_enc(result) != localJson) {
            target.applyRemote(r.kind, result);
            pulled++;
          }
          if (r.kind != 'dog' || lost.isNotEmpty) {
            conflicts.add(
              SyncConflict(
                kind: r.kind,
                id: r.id,
                dogId: local.dogId,
                fields: lost,
                local: local.data,
                remote: r.data,
              ),
            );
          }
        }

        // Cani da cui l'utente non è più membro: si tolgono dal telefono i
        // dati che erano stati sincronizzati.
        final members = (await backend.memberDogIds()).toSet();
        for (final key in _shadow.keys.toList()) {
          final dogId = _shadow[key]!['dogId'] as String;
          if (_owners.containsKey(dogId) && !members.contains(dogId)) {
            final parts = key.split(':');
            target.removeLocal(parts[0], parts.sublist(1).join(':'));
            _shadow.remove(key);
            removed++;
          }
        }
        for (final d in _owners.keys.toList()) {
          if (!members.contains(d)) _owners.remove(d);
        }

        // 2) Invio delle modifiche locali.
        final now2 = {for (final i in target.syncItems()) i.key: i};
        final newDogs = <RemoteRow>[], changedDogs = <RemoteRow>[];
        final entries = <RemoteRow>[];
        for (final i in now2.values) {
          final sh = _shadow[i.key];
          if (sh?['json'] == _enc(i.data)) continue;
          final row = RemoteRow(
            kind: i.kind,
            id: i.id,
            dogId: i.dogId,
            data: i.data,
            updatedAt: t,
            owner: i.kind == 'dog' ? (_owners[i.id] ?? uid) : null,
            base: sh?['v'] as String?,
          );
          if (i.kind == 'dog') {
            (_owners.containsKey(i.id) ? changedDogs : newDogs).add(row);
          } else {
            entries.add(row);
          }
        }
        // Un familiare che elimina un cane condiviso esce dalla condivisione:
        // nessuna lapide per il cane né per le sue voci (A8).
        final leaving = <String>{};
        for (final key in _shadow.keys) {
          if (now2.containsKey(key) || !key.startsWith('dog:')) continue;
          final id = key.substring(4);
          final owner = _owners[id];
          if (owner != null && owner != uid) leaving.add(id);
        }
        for (final d in leaving) {
          await backend.leaveDog(d);
          _owners.remove(d);
          _shadow.removeWhere((_, v) => v['dogId'] == d);
        }
        // Eliminazioni locali → lapidi (senza condizioni: vincono sempre).
        final deletedDogs = <RemoteRow>[];
        final tombstones = <String>[];
        for (final key in _shadow.keys) {
          if (now2.containsKey(key)) continue;
          final parts = key.split(':');
          final kind = parts[0], id = parts.sublist(1).join(':');
          tombstones.add(key);
          final row = RemoteRow(
            kind: kind,
            id: id,
            dogId: _shadow[key]!['dogId'] as String,
            data: _dec(_shadow[key]!['json'] as String),
            updatedAt: t,
            deleted: true,
          );
          if (kind == 'dog') {
            deletedDogs.add(row);
          } else {
            entries.add(row);
          }
        }

        final dogRes = PushResult(), entryRes = PushResult();
        void collect(PushResult into, PushResult r) {
          into.versions.addAll(r.versions);
          into.conflicts.addAll(r.conflicts);
        }

        if (newDogs.isNotEmpty) {
          collect(dogRes, await backend.insertDogs(newDogs));
        }
        for (final d in newDogs) {
          _owners[d.id] = uid;
        }
        if (changedDogs.isNotEmpty || deletedDogs.isNotEmpty) {
          collect(
            dogRes,
            await backend.updateDogs([...changedDogs, ...deletedDogs]),
          );
        }
        if (entries.isNotEmpty) {
          collect(entryRes, await backend.upsertEntries(entries));
        }

        // 3) Ombra: le righe scritte prendono la versione nuova del server;
        // quelle in conflitto restano in attesa e si riprovano dopo aver
        // riscaricato la versione remota.
        var roundConflicts = 0;
        for (final r in [...newDogs, ...changedDogs, ...entries]) {
          if (r.deleted) continue;
          final res = r.kind == 'dog' ? dogRes : entryRes;
          if (res.conflicts.contains(r.id)) {
            roundConflicts++;
            continue;
          }
          pushed++;
          _shadow['${r.kind}:${r.id}'] = {
            'json': _enc(r.data),
            'dogId': r.dogId ?? r.id,
            'v': res.versions[r.id],
          };
        }
        for (final key in tombstones) {
          pushed++;
          _shadow.remove(key);
        }
        if (roundConflicts == 0) break;
      }

      // Il riferimento è l'orario del SERVER più recente ricevuto, mai
      // l'orologio del telefono (gli orologi dei dispositivi possono
      // differire e far perdere modifiche).
      _lastPull = maxSeen;
      lastSync = DateTime.now();
      await target.persistAfterSync();
      await _saveState();
      return SyncResult(pulled, pushed, removed, conflicts);
    } finally {
      _running = false;
    }
  }
}
