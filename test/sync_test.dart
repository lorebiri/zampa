import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';
import 'package:zampa/sync/sync_engine.dart';
import 'package:zampa/ui/account_screen.dart';

/// Server simulato con le stesse regole del database (supabase/schema.sql):
/// ogni utente vede solo i cani di cui è membro.
class FakeServer {
  final dogs = <String, RemoteRow>{};
  final entries = <String, RemoteRow>{};
  final members = <String, Set<String>>{}; // dogId → utenti
  final invites = <String, String>{}; // codice → dogId
  int clock = 0;
  DateTime tick() => DateTime.utc(2026, 11, 10).add(Duration(seconds: ++clock));
}

class FakeBackend implements SyncBackend {
  FakeBackend(this.server, this.uid);
  final FakeServer server;
  String? uid;

  @override
  String? get userId => uid;
  bool _member(String dogId) => server.members[dogId]?.contains(uid) ?? false;

  RemoteRow _stamp(RemoteRow r) => RemoteRow(
    kind: r.kind,
    id: r.id,
    dogId: r.dogId,
    data: r.data,
    updatedAt: server.tick(),
    deleted: r.deleted,
    owner: r.owner,
  );

  @override
  Future<List<String>> memberDogIds() async => [
    for (final e in server.members.entries)
      if (e.value.contains(uid)) e.key,
  ];

  @override
  Future<List<RemoteRow>> pullDogs(DateTime? since) async => [
    for (final r in server.dogs.values)
      if (_member(r.id) && (since == null || r.updatedAt.isAfter(since))) r,
  ];

  @override
  Future<List<RemoteRow>> pullEntries(DateTime? since) async => [
    for (final r in server.entries.values)
      if (_member(r.dogId!) && (since == null || r.updatedAt.isAfter(since))) r,
  ];

  @override
  Future<PushResult> insertDogs(List<RemoteRow> rows) async {
    final out = PushResult();
    for (final r in rows) {
      if (r.owner != uid) throw StateError('RLS: owner diverso');
      if (server.dogs.containsKey(r.id)) throw StateError('duplicato');
      final s = server.dogs[r.id] = _stamp(r);
      out.versions[r.id] = s.version;
      server.members.putIfAbsent(r.id, () => {}).add(uid!);
    }
    return out;
  }

  /// Come `.eq('updated_at', base)`: con una base diversa dalla versione
  /// sul server la riga non si scrive e risulta in conflitto.
  void _write(Map<String, RemoteRow> table, RemoteRow r, PushResult out) {
    final cur = table[r.id];
    if (r.base != null && cur != null && cur.version != r.base) {
      out.conflicts.add(r.id);
      return;
    }
    // Come il trigger del server: la proprietà del cane non cambia.
    final s = table[r.id] = _stamp(
      r.kind == 'dog' && cur != null
          ? RemoteRow(
              kind: r.kind,
              id: r.id,
              data: r.data,
              updatedAt: r.updatedAt,
              dogId: r.dogId,
              deleted: r.deleted,
              owner: cur.owner,
            )
          : r,
    );
    out.versions[r.id] = s.version;
  }

  /// Eseguita una volta all'inizio del prossimo `updateDogs`: simula un
  /// altro telefono che scrive tra la ricezione e l'invio.
  Future<void> Function()? beforeUpdate;

  @override
  Future<PushResult> updateDogs(List<RemoteRow> rows) async {
    final hook = beforeUpdate;
    beforeUpdate = null;
    if (hook != null) await hook();
    final out = PushResult();
    for (final r in rows) {
      if (!_member(r.id)) throw StateError('RLS: non membro');
      _write(server.dogs, r, out);
    }
    return out;
  }

  @override
  Future<PushResult> upsertEntries(List<RemoteRow> rows) async {
    final out = PushResult();
    for (final r in rows) {
      if (!_member(r.dogId!)) throw StateError('RLS: non membro');
      _write(server.entries, r, out);
    }
    return out;
  }

  @override
  Future<String> createInvite(String dogId) async {
    if (!_member(dogId)) throw StateError('RLS');
    final code = 'ABC${server.invites.length}';
    server.invites[code] = dogId;
    return code;
  }

  @override
  Future<String> acceptInvite(String code) async {
    final d =
        server.invites[code] ??
        (throw StateError('Codice non valido, scaduto o già usato'));
    server.members[d]!.add(uid!);
    return d;
  }

  @override
  Future<void> leaveDog(String dogId) async =>
      server.members[dogId]?.remove(uid);

  @override
  Future<void> deleteAccount() async {
    // Cascata: i cani di cui è proprietario spariscono con tutti i dati.
    final owned = [
      for (final d in server.dogs.values)
        if (d.owner == uid) d.id,
    ];
    for (final d in owned) {
      server.dogs.remove(d);
      server.entries.removeWhere((_, e) => e.dogId == d);
      server.members.remove(d);
    }
    for (final m in server.members.values) {
      m.remove(uid);
    }
    uid = null;
  }
}

Future<AppStore> device(String ns, FakeServer server, String? uid) async {
  final s = AppStore(
    prefs: await SharedPreferences.getInstance(),
    namespace: ns,
  );
  await s.load();
  attachEngine(s, FakeBackend(server, uid));
  return s;
}

Dog dog(String id) => Dog(
  id: id,
  name: 'Luna',
  birthDate: DateTime(2023, 1, 1),
  sex: Sex.femmina,
  weightKg: 14,
);

LogEntry log(String id, String dogId) => LogEntry(
  id: id,
  dogId: dogId,
  type: LogType.pipi,
  time: DateTime(2026, 11, 10, 8),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'i dati locali vengono caricati e arrivano sull\'altro dispositivo',
    () async {
      final server = FakeServer();
      final a = await device('a.', server, 'lorenzo');
      await a.upsertDog(dog('d1'));
      await a.addLog(log('l1', 'd1'));
      await a.syncNow();
      expect(server.dogs.keys, ['d1']);
      expect(
        server.entries.length,
        greaterThanOrEqualTo(2),
      ); // pipì + peso iniziale

      final b = await device('b.', server, 'lorenzo');
      await b.syncNow();
      expect(b.dogs.single.name, 'Luna');
      expect(b.logs.single.id, 'l1');
    },
  );

  test('modifiche ed eliminazioni si propagano', () async {
    final server = FakeServer();
    final a = await device('a.', server, 'lorenzo');
    await a.upsertDog(dog('d1'));
    await a.addLog(log('l1', 'd1'));
    await a.syncNow();
    final b = await device('b.', server, 'lorenzo');
    await b.syncNow();

    b.dogs.single.name = 'Luna Bella';
    await b.upsertDog(b.dogs.single);
    await b.deleteLog('l1');
    await b.syncNow();
    await a.syncNow();
    expect(a.dogs.single.name, 'Luna Bella');
    expect(a.logs, isEmpty);
  });

  test(
    'conflitto: i due dispositivi convergono sulla stessa versione',
    () async {
      final server = FakeServer();
      final a = await device('a.', server, 'lorenzo');
      await a.upsertDog(dog('d1'));
      await a.syncNow();
      final b = await device('b.', server, 'lorenzo');
      await b.syncNow();

      a.dogs.single.weightKg = 15;
      await a.upsertDog(a.dogs.single);
      b.dogs.single.weightKg = 16;
      await b.upsertDog(b.dogs.single);
      await a.syncNow();
      await b.syncNow();
      await a.syncNow();
      expect(a.dogs.single.weightKg, b.dogs.single.weightKg);
    },
  );

  test('famiglia: invito, dati condivisi, uscita', () async {
    final server = FakeServer();
    final owner = await device('a.', server, 'lorenzo');
    await owner.upsertDog(dog('d1'));
    await owner.syncNow();
    final code = await owner.syncEngine!.backend.createInvite('d1');

    final family = await device('c.', server, 'giulia');
    await family.syncEngine!.backend.acceptInvite(code);
    await family.syncNow();
    expect(family.dogs.single.id, 'd1');

    await family.addLog(log('l9', 'd1'));
    await family.syncNow();
    await owner.syncNow();
    expect(owner.logs.any((l) => l.id == 'l9'), isTrue);

    await family.syncEngine!.backend.leaveDog('d1');
    await family.syncNow();
    expect(family.dogs, isEmpty);
    expect(family.logs, isEmpty);
    expect(
      server.dogs.containsKey('d1'),
      isTrue,
      reason: 'i dati del proprietario restano',
    );
  });

  test('chi non è membro non vede i cani degli altri', () async {
    final server = FakeServer();
    final a = await device('a.', server, 'lorenzo');
    await a.upsertDog(dog('d1'));
    await a.syncNow();
    final stranger = await device('x.', server, 'estraneo');
    await stranger.syncNow();
    expect(stranger.dogs, isEmpty);
  });

  test(
    'eliminazione dell\'account del proprietario: i familiari perdono il cane',
    () async {
      final server = FakeServer();
      final owner = await device('a.', server, 'lorenzo');
      await owner.upsertDog(dog('d1'));
      await owner.syncNow();
      final code = await owner.syncEngine!.backend.createInvite('d1');
      final family = await device('c.', server, 'giulia');
      await family.syncEngine!.backend.acceptInvite(code);
      await family.syncNow();

      await owner.syncEngine!.backend.deleteAccount();
      await owner.afterSignOut(keepLocal: true);
      expect(owner.dogs.single.id, 'd1', reason: 'copia locale tenuta');
      expect(server.dogs, isEmpty);

      await family.syncNow();
      expect(family.dogs, isEmpty);
    },
  );

  test(
    'uscita con cancellazione locale non cancella i dati sul server',
    () async {
      final server = FakeServer();
      final a = await device('a.', server, 'lorenzo');
      await a.upsertDog(dog('d1'));
      await a.syncNow();
      (a.syncEngine!.backend as FakeBackend).uid = null; // signOut
      await a.afterSignOut(keepLocal: false);
      expect(a.dogs, isEmpty);
      expect(server.dogs.containsKey('d1'), isTrue);
    },
  );

  test('senza account non succede nulla', () async {
    final server = FakeServer();
    final a = await device('a.', server, null);
    await a.upsertDog(dog('d1'));
    expect(await a.syncNow(), isNull);
    expect(server.dogs, isEmpty);
  });

  test('il cane di esempio non viene mai caricato online', () async {
    final server = FakeServer();
    final a = await device('a.', server, 'lorenzo');
    await a.loadDemo();
    await a.upsertDog(dog('d1'));
    await a.syncNow();
    expect(server.dogs.keys, ['d1']);
    expect(server.entries.values.every((e) => e.dogId == 'd1'), isTrue);
  });

  test(
    'uscita tenendo i dati: i cani condivisi da altri non restano',
    () async {
      final server = FakeServer();
      final owner = await device('a.', server, 'lorenzo');
      await owner.upsertDog(dog('d1'));
      await owner.syncNow();
      final code = await owner.syncEngine!.backend.createInvite('d1');
      final family = await device('c.', server, 'giulia');
      await family.upsertDog(dog('g1'));
      await family.syncEngine!.backend.acceptInvite(code);
      await family.syncNow();
      expect(family.dogs.map((d) => d.id).toSet(), {'d1', 'g1'});
      (family.syncEngine!.backend as FakeBackend).uid = null;
      await family.afterSignOut(keepLocal: true, previousUserId: 'giulia');
      expect(family.dogs.map((d) => d.id), ['g1']);
    },
  );

  // --- Concorrenza ottimistica (rapporto 11, A5) ---------------------------

  Future<(AppStore, AppStore)> twoPhones(FakeServer server) async {
    final a = await device('a.', server, 'lorenzo');
    await a.upsertDog(dog('d1'));
    await a.addLog(log('l1', 'd1'));
    await a.syncNow();
    final b = await device('b.', server, 'lorenzo');
    await b.syncNow();
    return (a, b);
  }

  test(
    'due telefoni modificano campi diversi dello stesso cane: restano entrambe',
    () async {
      final server = FakeServer();
      final (a, b) = await twoPhones(server);

      a.dogs.single.weightKg = 15;
      await a.upsertDog(a.dogs.single);
      b.dogs.single.name = 'Luna Bella';
      await b.upsertDog(b.dogs.single);
      await a.syncNow();
      final rb = await b.syncNow();
      await a.syncNow();

      expect(rb!.conflicts, isEmpty);
      for (final s in [a, b]) {
        expect(s.dogs.single.name, 'Luna Bella');
        expect(s.dogs.single.weightKg, 15);
      }
      expect(server.dogs['d1']!.data['name'], 'Luna Bella');
      expect(server.dogs['d1']!.data['weightKg'], 15);
    },
  );

  test(
    'due telefoni modificano lo stesso campo: vince il primo e l\'altro lo sa',
    () async {
      final server = FakeServer();
      final (a, b) = await twoPhones(server);

      a.dogs.single.weightKg = 15;
      await a.upsertDog(a.dogs.single);
      b.dogs.single.weightKg = 16;
      b.dogs.single.name = 'Luna Bella';
      await b.upsertDog(b.dogs.single);
      await a.syncNow();
      final rb = await b.syncNow();
      await a.syncNow();

      // Il peso di A era già sul server; il nome di B non era in conflitto.
      for (final s in [a, b]) {
        expect(s.dogs.single.weightKg, 15);
        expect(s.dogs.single.name, 'Luna Bella');
      }
      // La modifica sostituita non si perde in silenzio.
      final c = rb!.conflicts.single;
      expect(c.kind, 'dog');
      expect(c.id, 'd1');
      expect(c.fields, ['weightKg']);
      expect(c.local['weightKg'], 16);
      expect(b.syncConflicts.single.id, 'd1');
    },
  );

  test(
    'scrittura concorrente tra ricezione e invio: si riscarica e si riapplica',
    () async {
      final server = FakeServer();
      final (a, b) = await twoPhones(server);

      b.dogs.single.name = 'Luna Bella';
      await b.upsertDog(b.dogs.single);
      // Mentre B invia, A scrive il peso sul server.
      (b.syncEngine!.backend as FakeBackend).beforeUpdate = () async {
        a.dogs.single.weightKg = 17;
        await a.upsertDog(a.dogs.single);
        await a.syncNow();
      };
      final rb = await b.syncNow();
      await a.syncNow();

      expect(rb!.conflicts, isEmpty);
      for (final s in [a, b]) {
        expect(s.dogs.single.name, 'Luna Bella');
        expect(s.dogs.single.weightKg, 17);
      }
    },
  );

  test('due telefoni modificano la stessa voce: vince il server, conflitto segnalato', () async {
    final server = FakeServer();
    final (a, b) = await twoPhones(server);

    LogEntry at(int h) => LogEntry(
      id: 'l1',
      dogId: 'd1',
      type: LogType.pipi,
      time: DateTime(2026, 11, 10, h),
    );
    a.logs[0] = at(9);
    b.logs[0] = at(10);
    await a.syncNow();
    final rb = await b.syncNow();
    await a.syncNow();

    expect(a.logs.single.time, DateTime(2026, 11, 10, 9));
    expect(b.logs.single.time, DateTime(2026, 11, 10, 9));
    final c = rb!.conflicts.single;
    expect(c.kind, 'log');
    expect(c.local['time'], at(10).toJson()['time']);
  });

  test('un\'eliminazione vince su una modifica concorrente', () async {
    final server = FakeServer();
    final (a, b) = await twoPhones(server);

    a.dogs.single.weightKg = 15;
    await a.upsertDog(a.dogs.single);
    await b.deleteLog('l1');
    b.dogs.single.name = 'Luna Bella';
    await b.upsertDog(b.dogs.single);
    a.logs[0] = LogEntry(
      id: 'l1',
      dogId: 'd1',
      type: LogType.cacca,
      time: DateTime(2026, 11, 10, 9),
    );
    await a.syncNow();
    await b.syncNow();
    await a.syncNow();
    expect(a.logs, isEmpty);
    expect(server.entries['l1']!.deleted, isTrue);
  });

  // --- Reset con ombra vuota (rapporto 11, A4) ------------------------------

  test('reset con la copia del server più recente: vince il server', () async {
    final server = FakeServer();
    final (a, b) = await twoPhones(server);

    // A esce tenendo i dati; nel frattempo B modifica il cane e la voce.
    final fa = a.syncEngine!.backend as FakeBackend..uid = null;
    await a.afterSignOut(keepLocal: true, previousUserId: 'lorenzo');
    b.dogs.single.name = 'Luna Bella';
    await b.upsertDog(b.dogs.single);
    b.logs[0] = LogEntry(
      id: 'l1',
      dogId: 'd1',
      type: LogType.cacca,
      time: DateTime(2026, 11, 10, 9),
    );
    await b.syncNow();
    // A, offline e senza account, aggiunge una voce nuova.
    await a.addLog(log('l2', 'd1'));
    fa.uid = 'lorenzo'; // di nuovo nello stesso account

    final before = server.clock;
    final ra = await a.syncNow();
    expect(a.dogs.single.name, 'Luna Bella');
    expect(a.logs.firstWhere((l) => l.id == 'l1').type, LogType.cacca);
    expect(server.dogs['d1']!.data['name'], 'Luna Bella');
    expect(server.entries['l1']!.data['type'], 'cacca');
    // Si invia solo ciò che il server non aveva.
    expect(ra!.pushed, 1);
    expect(server.clock, before + 1);
    expect(server.entries.containsKey('l2'), isTrue);

    await b.syncNow();
    expect(b.logs.map((l) => l.id).toSet(), {'l1', 'l2'});
  });

  // --- Familiare che elimina un cane condiviso (rapporto 11, A8) ------------

  test(
    'il familiare che elimina un cane condiviso esce, senza lapidi',
    () async {
      final server = FakeServer();
      final owner = await device('a.', server, 'lorenzo');
      await owner.upsertDog(dog('d1'));
      await owner.addLog(log('l1', 'd1'));
      await owner.syncNow();
      final code = await owner.syncEngine!.backend.createInvite('d1');
      final family = await device('c.', server, 'giulia');
      await family.syncEngine!.backend.acceptInvite(code);
      await family.syncNow();

      await family.deleteDog('d1');
      await family.syncNow();
      expect(server.members['d1'], {'lorenzo'});
      expect(server.dogs['d1']!.deleted, isFalse);
      expect(server.entries.values.any((e) => e.deleted), isFalse);
      await family.syncNow();
      expect(family.dogs, isEmpty);

      await owner.syncNow();
      expect(owner.dogs.single.id, 'd1');
      expect(owner.logs.single.id, 'l1');
    },
  );

  test('stato salvato da una versione precedente (senza versioni)', () async {
    final server = FakeServer();
    final (a, b) = await twoPhones(server);
    // Si tolgono le versioni dall'ombra salvata, come nelle versioni vecchie.
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonDecode(prefs.getString('b.zampa_sync_v1')!) as Map;
    for (final v in (raw['shadow'] as Map).values) {
      (v as Map).remove('v');
    }
    await prefs.setString('b.zampa_sync_v1', jsonEncode(raw));
    final b2 = await device('b.', server, 'lorenzo');
    a.dogs.single.weightKg = 15;
    await a.upsertDog(a.dogs.single);
    await a.syncNow();
    await b2.syncNow();
    expect(b2.dogs.single.weightKg, 15);
    b2.dogs.single.name = 'Luna Bella';
    await b2.upsertDog(b2.dogs.single);
    await b2.syncNow();
    await a.syncNow();
    expect(a.dogs.single.name, 'Luna Bella');
    expect(a.dogs.single.weightKg, 15);
    expect(b2.syncConflicts, isEmpty);
  });
}
