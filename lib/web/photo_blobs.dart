import 'dart:typed_data';

export 'photo_blobs_stub.dart'
    if (dart.library.js_interop) 'photo_blobs_web.dart';

/// Archivio delle foto fuori da SharedPreferences. Sul web è IndexedDB:
/// il localStorage tiene circa 5 MB in tutto e le foto lo riempirebbero.
abstract class PhotoBlobs {
  Future<void> put(String id, Uint8List bytes);
  Future<Uint8List?> get(String id);
  Future<void> clear();
}
