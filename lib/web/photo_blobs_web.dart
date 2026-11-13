import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'photo_blobs.dart';

/// Sul web: IndexedDB (decine o centinaia di MB, secondo il browser).
PhotoBlobs? createPhotoBlobs() =>
    globalContext.has('indexedDB') ? IndexedDbPhotos() : null;

class IndexedDbPhotos implements PhotoBlobs {
  static const _db = 'lulu';
  static const _store = 'foto';
  Future<web.IDBDatabase>? _open;

  Future<web.IDBDatabase> _database() => _open ??= () {
    final c = Completer<web.IDBDatabase>();
    final req = web.window.indexedDB.open(_db, 1);
    req.onupgradeneeded = (web.Event _) {
      final db = req.result as web.IDBDatabase;
      if (!db.objectStoreNames.contains(_store)) db.createObjectStore(_store);
    }.toJS;
    req.onsuccess = (web.Event _) {
      c.complete(req.result as web.IDBDatabase);
    }.toJS;
    req.onerror = (web.Event _) {
      _open = null;
      c.completeError(StateError('IndexedDB non disponibile'));
    }.toJS;
    return c.future;
  }();

  Future<JSAny?> _run(
    String mode,
    web.IDBRequest Function(web.IDBObjectStore s) op,
  ) async {
    final db = await _database();
    final tx = db.transaction(_store.toJS, mode);
    final req = op(tx.objectStore(_store));
    final c = Completer<JSAny?>();
    // Si aspetta la fine della transazione: allora il dato è davvero scritto.
    tx.oncomplete = (web.Event _) {
      if (!c.isCompleted) c.complete(req.result);
    }.toJS;
    tx.onerror = (web.Event _) {
      if (!c.isCompleted) c.completeError(StateError('Foto non salvata'));
    }.toJS;
    tx.onabort = (web.Event _) {
      if (!c.isCompleted) c.completeError(StateError('Spazio esaurito'));
    }.toJS;
    return c.future;
  }

  @override
  Future<void> put(String id, Uint8List bytes) =>
      _run('readwrite', (s) => s.put(bytes.toJS, id.toJS));

  @override
  Future<Uint8List?> get(String id) async {
    final r = await _run('readonly', (s) => s.get(id.toJS));
    if (r == null || r.isUndefinedOrNull) return null;
    return (r as JSUint8Array).toDart;
  }

  @override
  Future<void> clear() => _run('readwrite', (s) => s.clear());
}
