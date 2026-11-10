import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../brand.dart';
import '../store.dart';
import '../sync/supabase_backend.dart';
import '../sync/sync_engine.dart';
import 'common.dart';

/// Servizio di accesso attivo (null se gli account non sono configurati).
AuthService? appAuth;

/// Account facoltativo: backup, più dispositivi e condivisione in famiglia.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final email = TextEditingController();
  final code = TextEditingController();
  final invite = TextEditingController();
  bool codeSent = false;
  bool busy = false;
  String? error;

  Future<void> _do(Future<void> Function() f, {String? ok}) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await f();
      if (ok != null && mounted) toast(context, ok);
    } catch (e) {
      if (mounted) setState(() => error = _human(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String _human(Object e) {
    final s = '$e';
    if (s.contains('canceled') || s.contains('cancelled')) {
      return 'Accesso annullato.';
    }
    if (s.contains('Codice non valido')) {
      return 'Codice d\'invito non valido o scaduto.';
    }
    if (s.contains('Token has expired') || s.contains('otp')) {
      return 'Codice errato o scaduto: richiedine uno nuovo.';
    }
    if (s.contains('SocketException') || s.contains('Failed host lookup')) {
      return 'Nessuna connessione a Internet.';
    }
    return 'Operazione non riuscita: $s';
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final auth = appAuth;
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Account e famiglia')),
      body: PageBody(
        children: [
          if (auth == null) ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Gli account non sono ancora attivi in questa versione: i dati restano solo '
                  'su questo dispositivo. Puoi sempre fare un backup da Profilo › Esporta.',
                ),
              ),
            ),
          ] else
            StreamBuilder(
              stream: auth.changes,
              builder: (_, _) => auth.user == null
                  ? _signedOut(auth, t)
                  : _signedIn(auth, store, t),
            ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(error!, style: TextStyle(color: t.colorScheme.error)),
            ),
          if (busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _signedOut(AuthService auth, ThemeData t) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'L\'account è facoltativo. Serve per il backup, per usare $appName su più dispositivi '
        'e per condividere il cane con la famiglia. I dati vengono salvati su server in UE '
        '(Francoforte) e solo i membri di un cane possono vederne i dati.',
        style: t.textTheme.bodyMedium,
      ),
      const SizedBox(height: 16),
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.apple),
          label: const Text('Continua con Apple'),
          onPressed: busy ? null : () => _do(auth.signInWithApple),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: const Text('Continua con Google'),
        onPressed: busy ? null : () => _do(auth.signInWithGoogle),
      ),
      const SectionTitle('Oppure con la tua email'),
      TextField(
        controller: email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      const SizedBox(height: 8),
      if (!codeSent)
        FilledButton.tonal(
          onPressed: busy || !email.text.contains('@')
              ? null
              : () => _do(() async {
                  await auth.sendEmailCode(email.text);
                  setState(() => codeSent = true);
                }, ok: 'Ti abbiamo inviato un codice via email'),
          child: const Text('Inviami il codice'),
        )
      else ...[
        TextField(
          controller: code,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          decoration: const InputDecoration(
            labelText: 'Codice ricevuto via email',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: busy
              ? null
              : () => _do(() => auth.verifyEmailCode(email.text, code.text)),
          child: const Text('Accedi'),
        ),
      ],
      const SizedBox(height: 12),
      Text(
        'Al primo accesso i cani e i dati già presenti su questo telefono vengono caricati '
        'nel tuo account.',
        style: t.textTheme.bodySmall,
      ),
    ],
  );

  Widget _signedIn(AuthService auth, AppStore store, ThemeData t) {
    final engine = store.syncEngine;
    final dog = store.dog;
    final uid = auth.user?.id;
    final shared =
        dog != null &&
        engine?.ownerOf(dog.id) != null &&
        engine!.ownerOf(dog.id) != uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_circle),
            title: Text(auth.user?.email ?? 'Account attivo'),
            subtitle: Text(
              store.lastSyncError != null
                  ? 'Ultima sincronizzazione non riuscita: riprova quando sei online.'
                  : engine?.lastSync == null
                  ? 'Sincronizzazione in attesa'
                  : 'Sincronizzato ${relative(engine!.lastSync!, DateTime.now())}',
            ),
          ),
        ),
        FilledButton.tonalIcon(
          icon: const Icon(Icons.sync),
          label: const Text('Sincronizza ora'),
          onPressed: busy
              ? null
              : () => _do(() async {
                  final r = await store.syncNow();
                  if (r == null && store.lastSyncError != null) {
                    throw store.lastSyncError!;
                  }
                }, ok: 'Sincronizzato'),
        ),
        const SectionTitle('Famiglia'),
        if (dog != null)
          FilledButton.icon(
            icon: const Icon(Icons.person_add_alt),
            label: Text('Invita un familiare per ${dog.name}'),
            onPressed: busy
                ? null
                : () => _do(() async {
                    await store.syncNow(); // il cane deve essere sul server
                    final c = await engine!.backend.createInvite(dog.id);
                    if (!mounted) return;
                    await showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Codice d\'invito'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SelectableText(
                              c,
                              style: t.textTheme.displaySmall?.copyWith(
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Chi lo inserisce in Profilo › Account e famiglia vedrà e potrà '
                              'aggiornare i dati di questo cane. Valido 7 giorni.',
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Clipboard.setData(ClipboardData(text: c)),
                            child: const Text('Copia'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Fatto'),
                          ),
                        ],
                      ),
                    );
                  }),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: invite,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Ho un codice d\'invito',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: busy
                  ? null
                  : () => _do(() async {
                      await engine!.backend.acceptInvite(invite.text);
                      await store.syncNow();
                      invite.clear();
                    }, ok: 'Ora condividi questo cane'),
              child: const Text('Unisciti'),
            ),
          ],
        ),
        if (shared) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: busy
                ? null
                : () => _do(() async {
                    await engine.backend.leaveDog(dog.id);
                    await store.syncNow();
                  }, ok: 'Non condividi più ${dog.name}'),
            child: Text('Smetti di condividere ${dog.name}'),
          ),
        ],
        const SectionTitle('Account'),
        OutlinedButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text('Esci'),
          onPressed: busy ? null : () => _signOut(auth, store, delete: false),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          style: TextButton.styleFrom(foregroundColor: t.colorScheme.error),
          icon: const Icon(Icons.delete_forever_outlined),
          label: const Text('Elimina account'),
          onPressed: busy ? null : () => _signOut(auth, store, delete: true),
        ),
      ],
    );
  }

  Future<void> _signOut(
    AuthService auth,
    AppStore store, {
    required bool delete,
  }) async {
    final keep = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(delete ? 'Eliminare l\'account?' : 'Uscire dall\'account?'),
        content: Text(
          delete
              ? 'L\'account e tutti i dati dei cani di cui sei proprietario verranno cancellati '
                    'definitivamente dal server, anche per i familiari con cui li condividi. '
                    'Non si può annullare.\n\nVuoi tenere una copia dei dati su questo telefono?'
              : 'Vuoi tenere i dati su questo telefono? Restano utilizzabili senza account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancella dal telefono'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tieni sul telefono'),
          ),
        ],
      ),
    );
    if (keep == null) return;
    await _do(() async {
      if (delete) await store.syncEngine!.backend.deleteAccount();
      final uid = auth.user?.id;
      await auth.signOut();
      await store.afterSignOut(keepLocal: keep, previousUserId: uid);
    }, ok: delete ? 'Account eliminato' : 'Sei uscito dall\'account');
  }
}

/// Collega account e sincronizzazione all'archivio (chiamato all'avvio).
Future<void> setupAccounts(
  AppStore store,
  Future<AuthService?> Function() init,
) async {
  final auth = await init();
  if (auth == null) return;
  appAuth = auth;
  auth.changes.listen((_) {
    if (auth.user != null) store.syncNow();
  });
  if (auth.user != null) store.syncNow();
}

/// Usato nei test e nelle anteprime: motore con un backend qualsiasi.
SyncEngine attachEngine(AppStore store, SyncBackend backend) {
  final e = SyncEngine(backend, store);
  store.syncEngine = e;
  return e;
}
