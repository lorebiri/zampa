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

  @override
  Future<void> insertDogs(List<RemoteRow> rows) =>
      client.from('dogs').insert([for (final r in rows) _dogJson(r)]);

  @override
  Future<void> updateDogs(List<RemoteRow> rows) async {
    for (final r in rows) {
      await client
          .from('dogs')
          .update({
            'data': r.data,
            'updated_at': r.updatedAt.toUtc().toIso8601String(),
            'deleted': r.deleted,
          })
          .eq('id', r.id);
    }
  }

  @override
  Future<void> upsertEntries(List<RemoteRow> rows) async {
    for (var i = 0; i < rows.length; i += 500) {
      final chunk = rows.sublist(i, min(i + 500, rows.length));
      await client.from('entries').upsert([
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
      ]);
    }
  }

  @override
  Future<String> createInvite(String dogId) async {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // senza 0/O, 1/I
    final rnd = Random.secure();
    final code = List.generate(
      8,
      (_) => alphabet[rnd.nextInt(alphabet.length)],
    ).join();
    await client.from('invites').insert({
      'code': code,
      'dog_id': dogId,
      'created_by': userId,
    });
    return code;
  }

  @override
  Future<String> acceptInvite(String code) async => await client.rpc(
    'accept_invite',
    params: {'invite_code': code.trim().toUpperCase()},
  ) as String;

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
