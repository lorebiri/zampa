import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_engine.dart';

/// Configurazione passata alla compilazione, mai scritta nel codice:
///   flutter run --dart-define-from-file=config/supabase.json
/// (vedi supabase/LEGGIMI.md). Senza configurazione gli account sono
/// disattivati e l'app funziona solo sul telefono.
class AccountConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static bool get enabled => url.isNotEmpty && anonKey.isNotEmpty;
}

class SupabaseBackend implements SyncBackend {
  SupabaseBackend(this.client);
  final SupabaseClient client;

  @override
  String? get userId => client.auth.currentUser?.id;

  RemoteRow _row(Map<String, dynamic> r, String kind) => RemoteRow(
    kind: kind,
    id: r['id'] as String,
    dogId: r['dog_id'] as String? ?? r['id'] as String,
    data: (r['data'] as Map).cast<String, Object?>(),
    updatedAt: DateTime.parse(r['updated_at'] as String),
    version: r['updated_at'] as String,
    deleted: r['deleted'] as bool? ?? false,
    owner: r['owner'] as String?,
  );

  @override
  Future<List<String>> memberDogIds() async {
    final rows = await client
        .from('dog_members')
        .select('dog_id')
        .eq('user_id', userId!);
    return [for (final r in rows) r['dog_id'] as String];
  }

  @override
  Future<List<RemoteRow>> pullDogs(DateTime? since) async {
    var q = client.from('dogs').select();
    if (since != null) q = q.gt('updated_at', since.toUtc().toIso8601String());
    final rows = await q;
    return [for (final r in rows) _row(r, 'dog')];
  }

  @override
  Future<List<RemoteRow>> pullEntries(DateTime? since) async {
    final out = <RemoteRow>[];
    // Paginazione: Supabase restituisce al massimo 1000 righe per richiesta.
    for (var from = 0; ; from += 1000) {
      var q = client.from('entries').select();
      if (since != null) {
        q = q.gt('updated_at', since.toUtc().toIso8601String());
      }
      final rows = await q.order('updated_at').range(from, from + 999);
      out.addAll([for (final r in rows) _row(r, r['kind'] as String)]);
      if (rows.length < 1000) break;
    }
    return out;
  }

  Map<String, Object?> _dogJson(RemoteRow r) => {
    'id': r.id,
    'owner': r.owner,
    'data': r.data,
    'updated_at': r.updatedAt.toUtc().toIso8601String(),
    'deleted': r.deleted,
  };

  /// Versioni scritte, dalle righe restituite da `select('id, updated_at')`.
  static Map<String, String> _versions(List<Map<String, dynamic>> rows) => {
    for (final r in rows) r['id'] as String: r['updated_at'] as String,
  };

  /// La versione si confronta con il testo esatto restituito dal server
  /// (microsecondi inclusi); `+00:00` diventa `Z` per non dipendere dalla
  /// codifica del `+` nell'indirizzo della richiesta.
  static String _ts(String v) =>
      v.endsWith('+00:00') ? '${v.substring(0, v.length - 6)}Z' : v;

  /// Aggiornamento condizionato alla versione di base (concorrenza
  /// ottimistica, rapporto 11 A5). Zero righe aggiornate significa conflitto
  /// se la riga è visibile, altrimenti scrittura non consentita (A6).
  Future<void> _update(
    String table,
    RemoteRow r,
    Map<String, Object?> values,
    PushResult out,
  ) async {
    var q = client.from(table).update(values).eq('id', r.id);
    if (r.base != null) q = q.eq('updated_at', _ts(r.base!));
    final res = await q.select('id, updated_at');
    if (res.isNotEmpty) {
      out.versions.addAll(_versions(res));
      return;
    }
    final seen = await client
        .from(table)
        .select('id')
        .eq('id', r.id)
        .maybeSingle();
    if (r.base != null && seen != null) {
      out.conflicts.add(r.id);
      return;
    }
    // Un aggiornamento bloccato dalle regole tocca zero righe senza errore:
    // va segnalato, altrimenti la modifica si perde (rapporto 11).
    throw StateError('Aggiornamento di ${r.kind} ${r.id} non consentito');
  }

  @override
  Future<PushResult> insertDogs(List<RemoteRow> rows) async {
    final res = await client
        .from('dogs')
        .insert([for (final r in rows) _dogJson(r)])
        .select('id, updated_at');
    return PushResult(versions: _versions(res));
  }

  @override
  Future<PushResult> updateDogs(List<RemoteRow> rows) async {
    final out = PushResult();
    for (final r in rows) {
      await _update('dogs', r, {
        'data': r.data,
        'updated_at': r.updatedAt.toUtc().toIso8601String(),
        'deleted': r.deleted,
      }, out);
    }
    return out;
  }

  @override
  Future<PushResult> upsertEntries(List<RemoteRow> rows) async {
    final out = PushResult();
    // Modifiche a voci già sul server: una per una, condizionate alla
    // versione di base. Sono poche (le voci si aggiungono più che correggere).
    for (final r in rows.where((r) => r.base != null)) {
      await _update('entries', r, {
        'data': r.data,
        'updated_at': r.updatedAt.toUtc().toIso8601String(),
        'deleted': r.deleted,
      }, out);
    }
    // Voci nuove e lapidi: a blocchi, senza condizioni.
    final plain = rows.where((r) => r.base == null).toList();
    for (var i = 0; i < plain.length; i += 500) {
      final chunk = plain.sublist(i, min(i + 500, plain.length));
      final res = await client
          .from('entries')
          .upsert([
            for (final r in chunk)
              {
                'id': r.id,
                'dog_id': r.dogId,
                'kind': r.kind,
                'data': r.data,
                'updated_at': r.updatedAt.toUtc().toIso8601String(),
                'updated_by': userId,
                'deleted': r.deleted,
              },
          ])
          .select('id, updated_at');
      out.versions.addAll(_versions(res));
    }
    return out;
  }

  @override
  Future<String> createInvite(String dogId) async =>
      // Il codice lo genera il server (monouso, scadenza decisa lato server).
      await client.rpc('create_invite', params: {'p_dog_id': dogId}) as String;

  @override
  Future<String> acceptInvite(String code) async {
    final d = await client.rpc(
      'accept_invite',
      params: {'invite_code': code.trim().toUpperCase()},
    );
    if (d == null) {
      throw const AuthException('Codice non valido, scaduto o già usato');
    }
    return d as String;
  }

  @override
  Future<void> leaveDog(String dogId) => client
      .from('dog_members')
      .delete()
      .eq('dog_id', dogId)
      .eq('user_id', userId!);

  @override
  Future<void> deleteAccount() => client.rpc('delete_my_account');
}

/// Accesso: Apple, Google, email con codice.
class AuthService {
  AuthService(this.client);
  final SupabaseClient client;

  User? get user => client.auth.currentUser;
  Stream<AuthState> get changes => client.auth.onAuthStateChange;

  static String _nonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<void> signInWithApple() async {
    if (kIsWeb) {
      await client.auth.signInWithOAuth(OAuthProvider.apple);
      return;
    }
    final raw = _nonce();
    final hashed = sha256.convert(utf8.encode(raw)).toString();
    final cred = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
      nonce: hashed,
    );
    final idToken = cred.identityToken;
    if (idToken == null) {
      throw const AuthException('Apple non ha restituito il token');
    }
    await client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: raw,
    );
  }

  bool _googleReady = false;

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await client.auth.signInWithOAuth(OAuthProvider.google);
      return;
    }
    final g = GoogleSignIn.instance;
    if (!_googleReady) {
      await g.initialize(
        clientId: AccountConfig.googleIosClientId.isEmpty
            ? null
            : AccountConfig.googleIosClientId,
        serverClientId: AccountConfig.googleWebClientId.isEmpty
            ? null
            : AccountConfig.googleWebClientId,
      );
      _googleReady = true;
    }
    final account = await g.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('Google non ha restituito il token');
    }
    await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  /// Invia un codice di accesso via email (nessuna password da ricordare).
  Future<void> sendEmailCode(String email) =>
      client.auth.signInWithOtp(email: email.trim(), shouldCreateUser: true);

  Future<void> verifyEmailCode(String email, String code) => client.auth
      .verifyOTP(email: email.trim(), token: code.trim(), type: OtpType.email);

  Future<void> signOut() async {
    await client.auth.signOut();
    if (!kIsWeb && _googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }
}
