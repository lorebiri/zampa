import 'dart:convert';

/// Sincronizzazione offline-first.
///
/// L'app lavora sempre sui dati locali. Quando l'utente ha un account, il
/// motore confronta lo stato attuale con l'"ombra" (l'ultimo stato
/// sincronizzato) per capire cosa è cambiato sul telefono, scarica le novità
/// dal server e invia le modifiche locali.
///
/// Conflitti: se lo stesso oggetto è cambiato sia sul telefono sia sul server,
/// vince la modifica locale non ancora inviata (verrà caricata subito dopo);
/// un'eliminazione remota vince sempre. Le eliminazioni locali diventano
/// "lapidi" (deleted = true) così gli altri dispositivi le ricevono.

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
  });

  /// 'dog' oppure uno dei tipi di voce: log, record, weight, dose, repro,
  /// qol, lab.
  final String kind;
  final String id;
  final String? dogId;
  final Map<String, Object?> data;
  final DateTime updatedAt;
  final bool deleted;
  final String? owner;
}

/// Server remoto (Supabase in produzione, simulato nei test).
abstract class SyncBackend {
  String? get userId;
  Future<List<String>> memberDogIds();
  Future<List<RemoteRow>> pullDogs(DateTime? since);
  Future<List<RemoteRow>> pullEntries(DateTime? since);
  Future<void> insertDogs(List<RemoteRow> rows);
  Future<void> updateDogs(List<RemoteRow> rows);
  Future<void> upsertEntries(List<RemoteRow> rows);
  Future<String> createInvite(String dogId);
  Future<String> acceptInvite(String code);
  Future<void> leaveDog(String dogId);
  Future<void> deleteAccount();
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
  SyncResult(this.pulled, this.pushed, this.removed);
  final int pulled;
  final int pushed;
  final int removed;
  @override
  String toString() => 'ricevuti $pulled, inviati $pushed, rimossi $removed';
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

  /// key → {json, dogId}: ultimo stato sincronizzato.
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

  static String _enc(Map<String, Object?> m) => jsonEncode(m);

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

  Future<SyncResult?> sync({DateTime? now}) async {
    final uid = backend.userId;
    if (uid == null || _running) return null;
    _running = true;
    try {
      // Cambio di account: si riparte da zero (i dati locali verranno
      // caricati nel nuovo account).
      if (_user != null && _user != uid) {
        _shadow.clear();
        _owners.clear();
        _lastPull = null;
      }
      _user = uid;
      final t = now ?? DateTime.now().toUtc();
      var pulled = 0, removed = 0;

      // 1) Ricezione.
      final since = _lastPull?.subtract(const Duration(minutes: 2));
      final remoteDogs = await backend.pullDogs(since);
      final remoteEntries = await backend.pullEntries(since);
      final current = {for (final i in target.syncItems()) i.key: i};
      var maxSeen = _lastPull;
      for (final r in [...remoteDogs, ...remoteEntries]) {
        if (maxSeen == null || r.updatedAt.isAfter(maxSeen)) {
          maxSeen = r.updatedAt;
        }
        final key = '${r.kind}:${r.id}';
        if (r.kind == 'dog' && r.owner != null) _owners[r.id] = r.owner!;
        final local = current[key];
        final shadowJson = _shadow[key]?['json'] as String?;
        // Modifica locale in attesa: oggetto cambiato, oppure eliminato sul
        // telefono ma non ancora comunicato al server (non va resuscitato).
        final pendingLocal =
            (local != null && _enc(local.data) != shadowJson) ||
            (local == null && shadowJson != null);
        if (r.deleted) {
          if (local != null) {
            target.removeLocal(r.kind, r.id);
            removed++;
          }
          _shadow.remove(key);
          continue;
        }
        if (pendingLocal) continue; // vince la modifica locale
        final remoteJson = _enc(r.data);
        if (local == null || _enc(local.data) != remoteJson) {
          target.applyRemote(r.kind, r.data);
          pulled++;
        }
        _shadow[key] = {'json': remoteJson, 'dogId': r.dogId ?? r.id};
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
        final json = _enc(i.data);
        if (_shadow[i.key]?['json'] == json) continue;
        final row = RemoteRow(
          kind: i.kind,
          id: i.id,
          dogId: i.dogId,
          data: i.data,
          updatedAt: t,
          owner: i.kind == 'dog' ? (_owners[i.id] ?? uid) : null,
        );
        if (i.kind == 'dog') {
          (_owners.containsKey(i.id) ? changedDogs : newDogs).add(row);
        } else {
          entries.add(row);
        }
      }
      // Eliminazioni locali → lapidi.
      final deletedDogs = <RemoteRow>[];
      for (final key in _shadow.keys) {
        if (now2.containsKey(key)) continue;
        final parts = key.split(':');
        final kind = parts[0], id = parts.sublist(1).join(':');
        final dogId = _shadow[key]!['dogId'] as String;
        final row = RemoteRow(
          kind: kind,
          id: id,
          dogId: dogId,
          data: jsonDecode(
            _shadow[key]!['json'] as String,
          ) as Map<String, Object?>,
          updatedAt: t,
          deleted: true,
        );
        if (kind == 'dog') {
          deletedDogs.add(row);
        } else {
          entries.add(row);
        }
      }
      if (newDogs.isNotEmpty) await backend.insertDogs(newDogs);
      for (final d in newDogs) {
        _owners[d.id] = uid;
      }
      if (changedDogs.isNotEmpty || deletedDogs.isNotEmpty) {
        await backend.updateDogs([...changedDogs, ...deletedDogs]);
      }
      if (entries.isNotEmpty) await backend.upsertEntries(entries);

      // 3) La nuova ombra è lo stato attuale.
      _shadow
        ..clear()
        ..addEntries(
          now2.values.map(
            (i) => MapEntry(i.key, {'json': _enc(i.data), 'dogId': i.dogId}),
          ),
        );
      // Il riferimento è l'orario del SERVER più recente ricevuto, mai
      // l'orologio del telefono (gli orologi dei dispositivi possono
      // differire e far perdere modifiche).
      _lastPull = maxSeen;
      lastSync = DateTime.now();
      await target.persistAfterSync();
      await _saveState();
      return SyncResult(
        pulled,
        newDogs.length +
            changedDogs.length +
            deletedDogs.length +
            entries.length,
        removed,
      );
    } finally {
      _running = false;
    }
  }
}
