import 'brand.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/clinical_text.dart';
import 'logic/alerts.dart';
import 'logic/bio_params.dart';
import 'logic/elimination_model.dart';
import 'logic/modules.dart';
import 'logic/nutrition.dart';
import 'logic/potty_predictor.dart';
import 'logic/prevention.dart';
import 'models.dart';
import 'notifications.dart';
import 'sync/sync_engine.dart';

/// Stato dell'app e persistenza locale (JSON in SharedPreferences, che
/// funziona su iOS, Android, web e desktop).
class AppStore extends ChangeNotifier implements SyncTarget {
  AppStore({
    SharedPreferences? prefs,
    this.notifier,
    this.namespace = '',
    this.photoBudgetChars = defaultPhotoBudgetChars,
  }) : _prefs = prefs; // ignore: prefer_initializing_formals

  /// Sul web i dati stanno nel localStorage del browser, che tiene circa
  /// 5 MB in tutto: se le foto lo riempissero, non si salverebbero più
  /// nemmeno cani, diari e terapie. Le foto hanno quindi un tetto (in
  /// caratteri base64, circa 1,5 MB). Su Android e iOS nessun tetto.
  static const int? defaultPhotoBudgetChars = kIsWeb ? 1500000 : null;
  final int? photoBudgetChars;

  /// Prefisso delle chiavi di salvataggio (più profili nello stesso test).
  final String namespace;
  String get _key => '${namespace}zampa_v1';
  SharedPreferences? _prefs;
  final Notifier? notifier;

  final dogs = <Dog>[];
  final logs = <LogEntry>[];
  final records = <HealthRecord>[];
  final weights = <WeightEntry>[];
  final doses = <DoseLog>[];
  final repro = <ReproEvent>[];
  final qol = <QolEntry>[];
  final labs = <LabResult>[];
  String? selectedDogId;

  /// L'utente ha letto e accettato l'avvertenza d'uso (primo avvio).
  bool termsAccepted = false;

  Future<void> acceptTerms() async {
    termsAccepted = true;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool('zampa_terms_v1', true);
    notifyListeners();
  }

  final engine = EliminationModel();
  final _cache = <String, ({int version, int hour, FittedModel model})>{};
  int _version = 0;

  /// Modello addestrato (in cache finché i dati non cambiano, max 1 ora).
  FittedModel model(Dog d, Need need, [DateTime? at]) {
    final now = at ?? DateTime.now();
    final key = '${d.id}/${need.name}';
    final hour = now.millisecondsSinceEpoch ~/ 3600000;
    final c = _cache[key];
    if (c != null && c.version == _version && c.hour == hour) return c.model;
    final m = engine.fit(d, need, logs, records, now);
    _cache[key] = (version: _version, hour: hour, model: m);
    return m;
  }

  Forecast forecast(Dog d, Need need, [DateTime? at]) {
    final now = at ?? DateTime.now();
    return model(d, need, now).forecast(now);
  }

  /// C'è almeno un cane vero (non l'esempio)?
  bool get hasRealDog => dogs.any((d) => !isDemoId(d.id));

  /// Cani di esempio presenti.
  List<Dog> get demoDogs => [
    for (final d in dogs)
      if (isDemoId(d.id)) d,
  ];

  /// Elimina il cane di esempio e i suoi dati.
  Future<void> removeDemo() async {
    for (final d in demoDogs) {
      await deleteDog(d.id);
    }
  }

  Dog? get dog {
    if (dogs.isEmpty) return null;
    return dogs.firstWhere(
      (d) => d.id == selectedDogId,
      orElse: () => dogs.first,
    );
  }

  List<LogEntry> logsOf(String dogId) =>
      logs.where((l) => l.dogId == dogId).toList()
        ..sort((a, b) => b.time.compareTo(a.time));

  List<HealthRecord> recordsOf(String dogId) =>
      records.where((r) => r.dogId == dogId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<WeightEntry> weightsOf(String dogId) =>
      weights.where((w) => w.dogId == dogId).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    termsAccepted = _prefs!.getBool('zampa_terms_v1') ?? false;
    final raw = _prefs!.getString(_key);
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, Object?>;
      List<Map<String, Object?>> list(String k) =>
          ((j[k] as List?) ?? const []).cast<Map<String, Object?>>();
      dogs.addAll(list('dogs').map(Dog.fromJson));
      logs.addAll(list('logs').map(LogEntry.fromJson));
      records.addAll(list('records').map(HealthRecord.fromJson));
      weights.addAll(list('weights').map(WeightEntry.fromJson));
      doses.addAll(list('doses').map(DoseLog.fromJson));
      repro.addAll(list('repro').map(ReproEvent.fromJson));
      qol.addAll(list('qol').map(QolEntry.fromJson));
      labs.addAll(list('labs').map(LabResult.fromJson));
      selectedDogId = j['selectedDogId'] as String?;
    }
    notifyListeners();
    await _reschedule();
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert({
    'app': appName,
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'selectedDogId': selectedDogId,
    'dogs': dogs.map((d) => d.toJson()).toList(),
    'logs': logs.map((l) => l.toJson()).toList(),
    'records': records.map((r) => r.toJson()).toList(),
    'weights': weights.map((w) => w.toJson()).toList(),
    'doses': doses.map((x) => x.toJson()).toList(),
    'repro': repro.map((x) => x.toJson()).toList(),
    'qol': qol.map((x) => x.toJson()).toList(),
    'labs': labs.map((x) => x.toJson()).toList(),
  });

  Future<void> _save() async {
    _version++;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_key, exportJson());
    await _reschedule();
    _scheduleSync();
  }

  // --- Sincronizzazione con l'account (facoltativa) -----------------------
  SyncEngine? syncEngine;
  Timer? _syncTimer;
  String? lastSyncError;

  /// Modifiche fatte su questo telefono e sostituite da quelle di un altro
  /// dispositivo (stesso campo cambiato in contemporanea): si mostrano
  /// all'utente finché non le ha viste, mai perse in silenzio (rapporto 11).
  final syncConflicts = <SyncConflict>[];

  void clearSyncConflicts() {
    syncConflicts.clear();
    notifyListeners();
  }

  /// Sincronizza qualche secondo dopo l'ultima modifica (raggruppa i tocchi).
  void _scheduleSync() {
    if (syncEngine?.backend.userId == null) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 3), () => syncNow());
  }

  Future<SyncResult?> syncNow() async {
    final e = syncEngine;
    if (e == null) return null;
    try {
      final r = await e.sync();
      if (r != null) syncConflicts.addAll(r.conflicts);
      lastSyncError = null;
      notifyListeners();
      return r;
    } catch (err) {
      lastSyncError = '$err';
      notifyListeners();
      return null;
    }
  }

  /// Oggetti da sincronizzare; il cane di esempio e i suoi dati restano
  /// solo sul telefono (rapporto 11, P0).
  @override
  List<LocalItem> syncItems() => [
    for (final d in dogs)
      if (!isDemoId(d.id)) LocalItem('dog', d.id, d.id, d.toJson()),
    for (final x in logs)
      if (!isDemoId(x.dogId)) LocalItem('log', x.id, x.dogId, x.toJson()),
    for (final x in records)
      if (!isDemoId(x.dogId)) LocalItem('record', x.id, x.dogId, x.toJson()),
    for (final x in weights)
      if (!isDemoId(x.dogId)) LocalItem('weight', x.id, x.dogId, x.toJson()),
    for (final x in doses)
      if (!isDemoId(x.dogId)) LocalItem('dose', x.id, x.dogId, x.toJson()),
    for (final x in repro)
      if (!isDemoId(x.dogId)) LocalItem('repro', x.id, x.dogId, x.toJson()),
    for (final x in qol)
      if (!isDemoId(x.dogId)) LocalItem('qol', x.id, x.dogId, x.toJson()),
    for (final x in labs)
      if (!isDemoId(x.dogId)) LocalItem('lab', x.id, x.dogId, x.toJson()),
  ];

  void _put<T>(List<T> list, T item, String Function(T) id) {
    final i = list.indexWhere((x) => id(x) == id(item));
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
  }

  @override
  void applyRemote(String kind, Map<String, Object?> data) {
    switch (kind) {
      case 'dog':
        _put(dogs, Dog.fromJson(data), (x) => x.id);
      case 'log':
        _put(logs, LogEntry.fromJson(data), (x) => x.id);
      case 'record':
        _put(records, HealthRecord.fromJson(data), (x) => x.id);
      case 'weight':
        _put(weights, WeightEntry.fromJson(data), (x) => x.id);
      case 'dose':
        _put(doses, DoseLog.fromJson(data), (x) => x.id);
      case 'repro':
        _put(repro, ReproEvent.fromJson(data), (x) => x.id);
      case 'qol':
        _put(qol, QolEntry.fromJson(data), (x) => x.id);
      case 'lab':
        _put(labs, LabResult.fromJson(data), (x) => x.id);
    }
  }

  @override
  void removeLocal(String kind, String id) {
    switch (kind) {
      case 'dog':
        dogs.removeWhere((x) => x.id == id);
        logs.removeWhere((x) => x.dogId == id);
        records.removeWhere((x) => x.dogId == id);
        weights.removeWhere((x) => x.dogId == id);
        doses.removeWhere((x) => x.dogId == id);
        repro.removeWhere((x) => x.dogId == id);
        qol.removeWhere((x) => x.dogId == id);
        labs.removeWhere((x) => x.dogId == id);
        if (selectedDogId == id) selectedDogId = dogs.firstOrNull?.id;
      case 'log':
        logs.removeWhere((x) => x.id == id);
      case 'record':
        records.removeWhere((x) => x.id == id);
      case 'weight':
        weights.removeWhere((x) => x.id == id);
      case 'dose':
        doses.removeWhere((x) => x.id == id);
      case 'repro':
        repro.removeWhere((x) => x.id == id);
      case 'qol':
        qol.removeWhere((x) => x.id == id);
      case 'lab':
        labs.removeWhere((x) => x.id == id);
    }
  }

  @override
  Future<void> persistAfterSync() async {
    if (selectedDogId == null || !dogs.any((d) => d.id == selectedDogId)) {
      selectedDogId = dogs.firstOrNull?.id;
    }
    _version++;
    notifyListeners();
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_key, exportJson());
    await _reschedule();
  }

  String get _syncKey => '${namespace}zampa_sync_v1';

  @override
  Map<String, Object?>? loadSyncState() {
    final raw = _prefs?.getString(_syncKey);
    return raw == null ? null : jsonDecode(raw) as Map<String, Object?>;
  }

  @override
  Future<void> saveSyncState(Map<String, Object?> state) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_syncKey, jsonEncode(state));
  }

  /// Uscita dall'account: i dati restano sul telefono oppure si cancellano.
  Future<void> afterSignOut({
    required bool keepLocal,
    String? previousUserId,
  }) async {
    // I cani condivisi da altri non restano sul telefono: non sono nostri e,
    // con un altro account, verrebbero caricati come se lo fossero (rapp. 11).
    final e = syncEngine;
    if (keepLocal && e != null && previousUserId != null) {
      for (final d in dogs.toList()) {
        final owner = e.ownerOf(d.id);
        if (owner != null && owner != previousUserId) removeLocal('dog', d.id);
      }
    }
    await syncEngine?.reset();
    if (!keepLocal) {
      await wipe();
    } else {
      notifyListeners();
    }
  }

  // --- Cani ---------------------------------------------------------------
  Future<void> upsertDog(Dog d) async {
    final i = dogs.indexWhere((x) => x.id == d.id);
    if (i >= 0) {
      dogs[i] = d;
    } else {
      dogs.add(d);
      weights.add(
        WeightEntry(
          id: newId(),
          dogId: d.id,
          date: DateTime.now(),
          kg: d.weightKg,
        ),
      );
    }
    selectedDogId = d.id;
    await _save();
  }

  Future<void> selectDog(String id) async {
    selectedDogId = id;
    await _save();
  }

  Future<void> deleteDog(String id) async {
    dogs.removeWhere((d) => d.id == id);
    logs.removeWhere((l) => l.dogId == id);
    records.removeWhere((r) => r.dogId == id);
    weights.removeWhere((w) => w.dogId == id);
    doses.removeWhere((x) => x.dogId == id);
    repro.removeWhere((x) => x.dogId == id);
    qol.removeWhere((x) => x.dogId == id);
    labs.removeWhere((x) => x.dogId == id);
    if (selectedDogId == id) selectedDogId = dogs.firstOrNull?.id;
    await _save();
  }

  /// Cancella tutti i dati (diritto all'oblio, GDPR).
  Future<void> wipe() async {
    dogs.clear();
    logs.clear();
    records.clear();
    weights.clear();
    doses.clear();
    repro.clear();
    qol.clear();
    labs.clear();
    for (final k
        in _prefs?.getKeys().where((k) => k.startsWith('photo_')).toList() ??
            <String>[]) {
      await _prefs!.remove(k);
    }
    selectedDogId = null;
    await _save();
  }

  // --- Diario -------------------------------------------------------------
  Future<void> addLog(LogEntry e) async {
    logs.add(e);
    await _save();
  }

  Future<void> deleteLog(String id) async {
    logs.removeWhere((l) => l.id == id);
    await _save();
  }

  // --- Cartella sanitaria -------------------------------------------------
  Future<void> upsertRecord(HealthRecord r) async {
    final i = records.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      records[i] = r;
    } else {
      records.add(r);
    }
    await _save();
  }

  Future<void> deleteRecord(String id) async {
    records.removeWhere((r) => r.id == id);
    await _save();
  }

  Future<void> addRecords(Iterable<HealthRecord> rs) async {
    records.addAll(rs);
    await _save();
  }

  Future<void> addWeight(String dogId, double kg, DateTime date) async {
    weights.add(WeightEntry(id: newId(), dogId: dogId, date: date, kg: kg));
    final d = dogs.firstWhere((x) => x.id == dogId);
    final latest = weightsOf(dogId).last;
    d.weightKg = latest.kg;
    await _save();
  }

  Future<void> deleteWeight(String id) async {
    weights.removeWhere((w) => w.id == id);
    await _save();
  }

  // --- Somministrazioni ---------------------------------------------------
  /// Dosi previste nelle ultime 24 ore non ancora confermate.
  List<({HealthRecord record, DateTime at})> pendingDoses(
    String dogId,
    DateTime now,
  ) {
    final out = <({HealthRecord record, DateTime at})>[];
    for (final r in records.where(
      (r) =>
          r.dogId == dogId &&
          r.type == RecordType.farmaco &&
          r.everyHours != null,
    )) {
      var t = nextDose(r, now.subtract(const Duration(hours: 24)));
      while (t != null && !t.isAfter(now)) {
        final at = t;
        final confirmed = doses.any(
          (x) =>
              x.recordId == r.id &&
              x.scheduledAt.difference(at).inMinutes.abs() < 30,
        );
        if (!confirmed && !at.isBefore(r.date)) out.add((record: r, at: at));
        t = nextDose(r, at.add(const Duration(minutes: 1)));
      }
    }
    out.sort((a, b) => a.at.compareTo(b.at));
    return out;
  }

  Future<void> confirmDose(
    HealthRecord r,
    DateTime scheduledAt,
    DoseStatus s,
  ) async {
    doses.add(
      DoseLog(
        id: newId(),
        dogId: r.dogId,
        recordId: r.id,
        scheduledAt: scheduledAt,
        status: s,
        at: DateTime.now(),
      ),
    );
    await _save();
  }

  // --- Storico riproduttivo, qualità della vita, esami ---------------------
  Future<void> addRepro(ReproEvent e) async {
    repro.add(e);
    final d = dogs.where((x) => x.id == e.dogId).firstOrNull;
    if (d != null) {
      switch (e.type) {
        case ReproEventType.calore:
          d
            ..reproState = ReproState.calore
            ..reproSince = e.date;
        case ReproEventType.accoppiamento:
          d
            ..reproState = ReproState.gravidanza
            ..reproSince = e.date;
        case ReproEventType.parto:
          d
            ..reproState = ReproState.allattamento
            ..reproSince = e.date;
        case ReproEventType.sterilizzazione:
          d
            ..neutered = true
            ..reproState = ReproState.nessuno;
        default:
          break;
      }
    }
    await _save();
  }

  Future<void> deleteRepro(String id) async {
    final removed = repro.where((x) => x.id == id).firstOrNull;
    repro.removeWhere((x) => x.id == id);
    final d = dogs.where((x) => x.id == removed?.dogId).firstOrNull;
    if (d != null) {
      // Ricalcola lo stato riproduttivo dall'ultimo evento rimasto (07 N16).
      final ev = repro.where((x) => x.dogId == d.id).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final last = ev
          .where((x) => x.type != ReproEventType.sterilizzazione)
          .lastOrNull;
      d
        ..reproState = switch (last?.type) {
          ReproEventType.calore => ReproState.calore,
          ReproEventType.accoppiamento => ReproState.gravidanza,
          ReproEventType.parto => ReproState.allattamento,
          _ => ReproState.nessuno,
        }
        ..reproSince = last?.date;
    }
    await _save();
  }

  Future<void> addQol(QolEntry e) async {
    qol.add(e);
    await _save();
  }

  Future<void> addLab(LabResult e) async {
    labs.add(e);
    await _save();
  }

  Future<void> deleteLab(String id) async {
    labs.removeWhere((x) => x.id == id);
    await _save();
  }

  // --- Foto ---------------------------------------------------------------
  /// Le foto (già ridotte) sono salvate a parte, in base64.
  Future<String> savePhoto(Uint8List bytes) async {
    _prefs ??= await SharedPreferences.getInstance();
    final id = newId();
    final encoded = base64Encode(bytes);
    final budget = photoBudgetChars;
    if (budget != null) {
      var used = 0;
      for (final k in _prefs!.getKeys().where((k) => k.startsWith('photo_'))) {
        used += _prefs!.getString(k)?.length ?? 0;
      }
      if (used + encoded.length > budget) throw const PhotoSpaceFull();
    }
    await _prefs!.setString('photo_$id', encoded);
    return id;
  }

  Uint8List? photo(String id) {
    final s = _prefs?.getString('photo_$id');
    return s == null ? null : base64Decode(s);
  }

  // --- Promemoria ---------------------------------------------------------

  /// Massimo di notifiche programmate insieme: iOS ne conserva 64 in attesa
  /// e scarta le altre; ne lasciamo libere alcune per gli avvisi immediati.
  static const maxScheduled = 60;

  /// Tutte le notifiche che vorremmo programmare, con priorità (decisione 7
  /// del CEO): 0 urgenti, 1 dosi, 2 scadenze entro 7 giorni, 3 uscite,
  /// 4 scadenze lontane. Funzione pura: non tocca il sistema (testabile).
  List<PlannedNotification> planNotifications(DateTime now) {
    final out = <PlannedNotification>[];
    for (var di = 0; di < dogs.length && di < 9; di++) {
      final d = dogs[di];
      // Il cane di esempio non manda mai notifiche (CEO 11.4).
      if (isDemoId(d.id)) continue;
      final base = (di + 1) * 1000;
      final dLogs = logs.where((l) => l.dogId == d.id).toList()
        ..sort((a, b) => a.time.compareTo(b.time));

      // Pipì mancata, anche ad app chiusa (07 N13).
      final real = dLogs.where(
        (l) => l.type == LogType.pipi && !l.signs.contains(Sign.gocce),
      );
      if (real.isNotEmpty) {
        final last = real.last.time;
        final puppy = d.ageInMonths(now) < 6;
        final strainMale =
            d.sex == Sex.maschio &&
            dLogs.any(
              (l) =>
                  l.type == LogType.pipi &&
                  (l.signs.contains(Sign.sforzo) ||
                      l.signs.contains(Sign.gocce)) &&
                  now.difference(l.time).inHours <= 24,
            );
        // Dopo un intervento (3 giorni; 14 per la colonna) la ritenzione
        // urinaria è frequente: 12 ore, come l'allarme in app (ricerca/26 A3).
        final postOp = records.any(
          (r) =>
              r.dogId == d.id &&
              r.type == RecordType.intervento &&
              r.done &&
              !r.date.isAfter(now) &&
              now.difference(r.date).inDays <
                  (RegExp('colonna|ernia|disc|spin')
                          .hasMatch(r.title.toLowerCase())
                      ? 14
                      : 3),
        );
        final hours = puppy
            ? (d.ageInMonths(now) < 4 ? 6 : 8)
            : (strainMale || postOp ? 12 : 24);
        var at = last.add(Duration(hours: hours));
        if (puppy && PottyPredictor.inSleepWindow(d, at)) {
          at = PottyPredictor.nextWake(d, at).add(const Duration(hours: 1));
        }
        out.add(
          PlannedNotification(
            base + 96,
            at,
            postOp && !puppy
                ? '🔴 ${d.name}: nessuna pipì da 12 ore dopo l\'intervento?'
                : '🔴 ${d.name}: nessuna pipì da $hours ore?',
            postOp && !puppy
                ? 'Dopo un\'anestesia alcuni cani non riescono a svuotare la '
                      'vescica. Se non ha urinato, o ci prova senza riuscirci, '
                      'chiama oggi il veterinario che l\'ha operato. Se l\'ha '
                      'fatta, registrala.'
                : 'Se non ha davvero urinato è un\'urgenza: contatta il '
                      'veterinario. Se l\'ha fatta, registrala.',
            0,
            exact: true,
          ),
        );
      }

      // Dosi delle prossime 72 ore e conferma dopo 2 ore.
      var t = 0;
      final confirmAt = <({DateTime at, HealthRecord record})>[];
      // Anche le terapie che iniziano più avanti: altrimenti la prima dose
      // e le successive non sono avvisate finché non si riapre l'app dopo
      // l'inizio (rapporto 10, difetto A1).
      for (final r in records.where(
        (r) =>
            r.dogId == d.id &&
            (r.isActiveTherapy(now) ||
                (r.date.isAfter(now) && r.isActiveTherapy(r.date))),
      )) {
        var next = nextDose(r, now);
        while (next != null &&
            t < 30 &&
            next.isBefore(now.add(const Duration(hours: 72)))) {
          out.add(
            PlannedNotification(
              base + 50 + t++,
              next,
              '💊 ${r.title} per ${d.name}',
              '${r.dose.isEmpty ? 'È ora della dose' : 'Dose: ${r.dose}'} '
                  '(come prescritta dal veterinario). Se l\'hai saltata, non '
                  'raddoppiare: chiedi al veterinario.',
              1,
              exact: true,
            ),
          );
          next = nextDose(r, next.add(const Duration(minutes: 1)));
        }
        final nd = nextDose(r, now.subtract(const Duration(hours: 2)));
        if (nd != null) {
          confirmAt.add((at: nd.add(const Duration(hours: 2)), record: r));
        }
      }
      confirmAt.sort((a, b) => a.at.compareTo(b.at));
      for (var k = 0; k < 3 && k < confirmAt.length; k++) {
        // Testi propri per insulina e antiepilettici (ricerca/26 A7).
        final kind = Modules.doseKind(confirmAt[k].record.title);
        out.add(
          PlannedNotification(
            base + 97 + k,
            confirmAt[k].at,
            ClinicalText('UI-DOS-002', {'kind': kind, 'name': d.name}).title,
            ClinicalText('UI-DOS-002', {'kind': kind, 'app': appName}).text,
            1,
            exact: true,
          ),
        );
      }

      // Prossima uscita per pipì e cacca.
      for (final need in Need.values) {
        final on = need == Need.pipi ? d.pottyRemindersOn : d.poopRemindersOn;
        if (!on) continue;
        final p = forecast(d, need, now);
        if (p.last == null) continue;
        // Cacca: si avvisa solo agli orari abituali, mai a un orario
        // «previsto» (piano CEO 11.3).
        if (need == Need.cacca && p.usualMinutes.isEmpty) continue;
        final at = p.recommendedAt.subtract(
          Duration(minutes: d.reminderLeadMinutes),
        );
        out.add(
          PlannedNotification(
            base + (need == Need.pipi ? 0 : 45),
            at.isAfter(now) ? at : p.recommendedAt,
            need == Need.pipi
                ? 'È quasi ora di uscire con ${d.name} 🐾'
                : 'Di solito a quest\'ora ${d.name} fa la cacca 💩',
            need == Need.pipi
                ? 'Uscita consigliata alle ${hm(p.recommendedAt)}. ${p.reason}'
                : p.reason,
            3,
          ),
        );
      }

      // Scadenze sanitarie: 3 giorni prima e il giorno stesso alle 9.
      var k = 1;
      for (final item in dueItems(
        records,
        d.id,
      ).where((x) => !x.overdue(now)).take(20)) {
        final day = DateTime(item.due.year, item.due.month, item.due.day, 9);
        final near = day.difference(now).inDays <= 7;
        out
          ..add(
            PlannedNotification(
              base + k++,
              day.subtract(const Duration(days: 3)),
              '${item.record.type.emoji} Tra 3 giorni: ${item.record.title}',
              'Promemoria per ${d.name}. Prenota se serve.',
              near ? 2 : 4,
            ),
          )
          ..add(
            PlannedNotification(
              base + k++,
              day,
              '${item.record.type.emoji} Oggi: ${item.record.title}',
              'Scadenza di oggi per ${d.name}.',
              near ? 2 : 4,
            ),
          );
      }
    }
    // Solo eventi futuri, per priorità e poi per orario.
    final future = out.where((p) => p.when.isAfter(now)).toList()
      ..sort((a, b) {
        final c = a.priority.compareTo(b.priority);
        return c != 0 ? c : a.when.compareTo(b.when);
      });
    return future.take(maxScheduled).toList();
  }

  static const _notifKey = 'zampa_notif_ids';

  /// Riprogramma le notifiche (per esempio appena concesso il permesso).
  Future<void> replan() => _reschedule();

  /// Allarmi SUBITO/OGGI di oggi non ancora notificati: uno per allarme e
  /// per giorno (la chiave va segnata da chi li consegna).
  List<({String key, PlannedNotification n})> _newUrgent(DateTime now) {
    final out = <({String key, PlannedNotification n})>[];
    for (var di = 0; di < dogs.length && di < 9; di++) {
      final d = dogs[di];
      if (isDemoId(d.id)) continue;
      final urgent =
          AlertEngine.compute(
            dog: d,
            logs: logs,
            records: records,
            weights: weights,
            now: now,
            repro: repro,
            pendingDoses: pendingDoses(d.id, now),
          ).where(
            (a) => a.level == AlertLevel.subito || a.level == AlertLevel.oggi,
          );
      var ui = 0;
      for (final a in urgent.take(6)) {
        final key =
            'alert_${d.id}_${a.title}_${now.year}${now.month}${now.day}';
        final slot = (di + 1) * 1000 + 90 + ui++;
        if (_prefs!.getBool(key) ?? false) continue;
        out.add((
          key: key,
          n: PlannedNotification(
            slot,
            now,
            '${a.level == AlertLevel.subito ? '🔴 SUBITO' : '🟠 OGGI'}: ${a.title}',
            '${d.name}: ${a.actionText ?? a.message}',
            0,
            exact: true,
          ),
        ));
      }
    }
    return out;
  }

  Future<void> _reschedule() async {
    final n = notifier;
    if (n == null || !n.supported) {
      // Web e iPhone: niente notifiche locali, eventualmente Web Push.
      await _pushReminders();
      return;
    }
    final now = DateTime.now();
    // Allarmi urgenti: notifica immediata, una volta sola per allarme.
    for (final u in _newUrgent(now)) {
      await _prefs!.setBool(u.key, true);
      await n.showNow(u.n.id, u.n.title, u.n.body);
    }
    // Notifiche programmate, entro il tetto e per priorità.
    final planned = planNotifications(now);
    final keep = {for (final p in planned) p.id};
    final previous = (_prefs!.getStringList(_notifKey) ?? const []).map(
      int.parse,
    );
    for (final id in previous) {
      if (!keep.contains(id)) await n.cancel(id);
    }
    for (final p in planned) {
      await n.schedule(p.id, p.when, p.title, p.body, exact: p.exact);
    }
    await _prefs!.setStringList(_notifKey, [for (final id in keep) '$id']);
  }

  /// Promemoria via Web Push (web app, iPhone dalla schermata Home): il
  /// server li invia all'ora giusta. Attivo solo con account e permesso.
  ReminderSink? reminderSink;
  Future<void>? _pushing;
  bool _pushAgain = false;

  Future<void> _pushReminders() async {
    final sink = reminderSink;
    if (sink == null || !sink.active || _prefs == null) return;
    if (_pushing != null) {
      // Una sola spedizione alla volta: l'ultima versione vince.
      _pushAgain = true;
      return _pushing;
    }
    final run = () async {
      do {
        _pushAgain = false;
        final now = DateTime.now();
        final urgent = _newUrgent(now);
        try {
          await sink.replace(
            planNotifications(now),
            urgent: [for (final u in urgent) u.n],
          );
          for (final u in urgent) {
            await _prefs!.setBool(u.key, true);
          }
        } catch (e) {
          // Senza rete restano da inviare: si riprova al prossimo salvataggio.
          debugPrint('Promemoria web non inviati: $e');
        }
      } while (_pushAgain);
    }();
    _pushing = run;
    try {
      await run;
    } finally {
      _pushing = null;
    }
  }

  static DateTime? nextDose(HealthRecord r, DateTime now) {
    if (r.everyHours == null || r.everyHours! <= 0) return null;
    var t = r.date;
    final step = Duration(hours: r.everyHours!);
    if (t.isBefore(now)) {
      final n = (now.difference(t).inMinutes / step.inMinutes).ceil();
      t = t.add(step * n);
    }
    if (r.endDate != null && t.isAfter(r.endDate!)) return null;
    return t;
  }

  // --- Report per il veterinario -----------------------------------------
  String healthReport(Dog d) {
    final now = DateTime.now();
    final b = StringBuffer();
    final plan = Nutrition.plan(d, now);
    b.writeln('CARTELLA SANITARIA – ${d.name.toUpperCase()}');
    b.writeln('Generata con $appName il ${dmy(now)}');
    b.writeln();
    b.writeln(
      'Razza: ${d.breed.isEmpty ? '-' : d.breed}  ·  Sesso: ${d.sex.name}'
      '${d.neutered ? ' (sterilizzato/a)' : ''}',
    );
    b.writeln(
      '${d.g('Nato', 'Nata')} il: ${dmy(d.birthDate)} (${ageLabel(d, now)})',
    );
    b.writeln('Microchip: ${d.microchip.isEmpty ? '-' : d.microchip}');
    b.writeln(
      'Peso: ${d.weightKg.toStringAsFixed(1)} kg  ·  BCS ${d.bodyCondition}/9',
    );
    if (d.allergies.isNotEmpty) b.writeln('Allergie: ${d.allergies}');
    if (d.conditions.isNotEmpty) b.writeln('Patologie note: ${d.conditions}');
    b.writeln(
      'Alimentazione: ${d.foodName.isEmpty ? '-' : d.foodName}, '
      '~${plan.kcalPerDay.round()} kcal/giorno',
    );
    b.writeln();
    final active = records.where(
      (r) => r.dogId == d.id && r.isActiveTherapy(now),
    );
    if (active.isNotEmpty) {
      b.writeln('TERAPIE IN CORSO');
      for (final r in active) {
        b.writeln(
          '- ${r.title} ${r.dose} ogni ${r.everyHours} h'
          '${r.endDate != null ? ' fino al ${dmy(r.endDate!)}' : ''}',
        );
      }
      b.writeln();
    }
    b.writeln('STORICO');
    for (final r in recordsOf(d.id).where((r) => r.done)) {
      b.writeln(
        '- ${dmy(r.date)}  ${r.type.label}: ${r.title}'
        '${r.dose.isNotEmpty ? ' (${r.dose})' : ''}'
        '${r.notes.isNotEmpty ? ' – ${r.notes}' : ''}',
      );
    }
    b.writeln();
    final pees = logsOf(d.id).where(
      (l) => l.type == LogType.pipi && now.difference(l.time).inDays < 14,
    );
    if (pees.isNotEmpty) {
      final perDay = PottyStats.outingsPerDay(pees.toList());
      final avg = perDay.values.reduce((a, b) => a + b) / perDay.length;
      b.writeln('MINZIONI (ultimi 14 giorni)');
      b.writeln(
        'Media ${avg.toStringAsFixed(1)} uscite/giorno su ${perDay.length} giorni registrati; '
        'intervallo tipico da sveglio ${model(d, Need.pipi, now).typicalInterval(now).round()} min.',
      );
      final signs = pees.where((l) => l.signs.isNotEmpty);
      for (final s in signs) {
        b.writeln(
          '- ${dmy(s.time)} ${hm(s.time)}: ${s.signs.map((x) => x.label).join(', ')}',
        );
      }
      b.writeln();
    }
    final w = weightsOf(d.id);
    if (w.length > 1) {
      b.writeln('PESO');
      for (final e in w.skip(math.max(0, w.length - 8))) {
        b.writeln('- ${dmy(e.date)}: ${e.kg.toStringAsFixed(1)} kg');
      }
    }
    return b.toString();
  }

  // --- Dati di esempio ----------------------------------------------------
  /// Crea un cane di prova con due settimane di diario realistico, per
  /// provare l'app senza doverla usare per giorni.
  Future<void> loadDemo() async {
    final rnd = math.Random(7);
    final now = DateTime.now();
    final d = Dog(
      id: 'demo-${newId()}',
      name: 'Luna',
      birthDate: DateTime(now.year - 3, now.month, 1),
      sex: Sex.femmina,
      breed: 'Meticcio',
      neutered: true,
      weightKg: 14.2,
      bodyCondition: 6,
      microchip: '380260000123456',
      vetName: 'Ambulatorio Veterinario',
      foodName: 'Crocchette adult medium',
      foodKcalPer100g: 365,
      look: AvatarLook(
        size: DogSize.media,
        coat: 0xFFC8955A,
        coat2: 0xFFF4E6CF,
        pattern: CoatPattern.pettoBianco,
        ears: EarType.semi,
        tail: TailType.lunga,
      ),
    );
    dogs.add(d);
    selectedDogId = d.id;
    for (var day = 14; day >= 0; day--) {
      final base = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: day));
      DateTime at(double h) =>
          base.add(Duration(minutes: (h * 60 + rnd.nextInt(30) - 15).round()));
      void log(LogType t, DateTime when, {bool indoor = false, double? ml}) {
        if (when.isAfter(now)) return;
        logs.add(
          LogEntry(
            id: newId(),
            dogId: d.id,
            type: t,
            time: when,
            indoor: indoor,
            amountMl: ml,
          ),
        );
      }

      log(LogType.risveglio, at(7));
      log(LogType.pipi, at(7.25));
      log(LogType.cacca, at(7.3));
      log(LogType.pasto, at(7.75));
      log(LogType.acqua, at(8), ml: 250);
      log(LogType.pipi, at(12.5));
      log(LogType.acqua, at(13), ml: 200);
      log(LogType.pipi, at(17.5), indoor: day == 4);
      log(LogType.gioco, at(18));
      log(LogType.pasto, at(19.5));
      log(LogType.cacca, at(20));
      log(LogType.acqua, at(20.2), ml: 250);
      log(LogType.pipi, at(22.5));
    }
    for (var i = 0; i < 6; i++) {
      weights.add(
        WeightEntry(
          id: newId(),
          dogId: d.id,
          date: now.subtract(Duration(days: 150 - i * 30)),
          kg: 13.4 + i * 0.16,
        ),
      );
    }
    records.addAll([
      HealthRecord(
        id: newId(),
        dogId: d.id,
        type: RecordType.vaccino,
        title: 'Vaccino core (cimurro, epatite, parvovirosi)',
        date: now.subtract(const Duration(days: 400)),
        nextDue: now
            .subtract(const Duration(days: 400))
            .add(const Duration(days: 365 * 3)),
      ),
      HealthRecord(
        id: newId(),
        dogId: d.id,
        type: RecordType.vaccino,
        title: 'Leptospirosi',
        date: now.subtract(const Duration(days: 340)),
        nextDue: now.add(const Duration(days: 25)),
      ),
      HealthRecord(
        id: newId(),
        dogId: d.id,
        type: RecordType.antiparassitario,
        title: 'Antiparassitario esterno (zecche e pulci)',
        dose: '1 compressa',
        date: now.subtract(const Duration(days: 33)),
        nextDue: now.subtract(const Duration(days: 3)),
      ),
      HealthRecord(
        id: newId(),
        dogId: d.id,
        type: RecordType.visita,
        title: 'Visita di controllo annuale',
        date: now.subtract(const Duration(days: 200)),
        notes: 'Tutto nella norma, tartaro lieve.',
        cost: 60,
        nextDue: now.add(const Duration(days: 165)),
      ),
      HealthRecord(
        id: newId(),
        dogId: d.id,
        type: RecordType.farmaco,
        title: 'Antinfiammatorio',
        dose: '1/2 compressa',
        everyHours: 24,
        date: now.subtract(const Duration(days: 2, hours: 3)),
        endDate: now.add(const Duration(days: 3)),
        notes: 'Per lieve zoppia, da somministrare col pasto.',
      ),
    ]);
    labs.addAll([
      LabResult(
        id: newId(),
        dogId: d.id,
        date: now.subtract(const Duration(days: 200)),
        name: 'Creatinina',
        value: 1.0,
        unit: 'mg/dL',
        refLow: 0.5,
        refHigh: 1.5,
      ),
      LabResult(
        id: newId(),
        dogId: d.id,
        date: now.subtract(const Duration(days: 20)),
        name: 'Creatinina',
        value: 1.2,
        unit: 'mg/dL',
        refLow: 0.5,
        refHigh: 1.5,
      ),
    ]);
    await _save();
  }
}

String two(int v) => v.toString().padLeft(2, '0');
String hm(DateTime t) => '${two(t.hour)}:${two(t.minute)}';
String dmy(DateTime t) => '${two(t.day)}/${two(t.month)}/${t.year}';

String ageLabel(Dog d, [DateTime? now]) {
  final m = d.ageInMonths(now);
  if (m < 4) {
    final w = (now ?? DateTime.now()).difference(d.birthDate).inDays ~/ 7;
    return w == 1 ? '1 settimana' : '$w settimane';
  }
  if (m < 24) return '${m.floor()} mesi';
  final y = (m / 12).floor();
  return '$y anni';
}

/// Validazione microchip ISO 11784/11785: 15 cifre. In Italia il codice
/// paese è 380.
String? microchipProblem(String code) {
  final c = code.replaceAll(' ', '');
  if (c.isEmpty) return null;
  if (!RegExp(r'^\d{15}$').hasMatch(c)) {
    return 'Il microchip ISO ha 15 cifre numeriche.';
  }
  return null;
}

/// Notifica da programmare (vedi AppStore.planNotifications).
class PlannedNotification {
  PlannedNotification(
    this.id,
    this.when,
    this.title,
    this.body,
    this.priority, {
    this.exact = false,
  });
  final int id;
  final DateTime when;
  final String title;
  final String body;

  /// 0 urgenti, 1 dosi, 2 scadenze vicine, 3 uscite, 4 scadenze lontane.
  final int priority;

  /// Da consegnare all'orario esatto anche in risparmio energetico.
  final bool exact;
}

/// Spazio per le foto esaurito (solo web, vedi [AppStore.photoBudgetChars]).
class PhotoSpaceFull implements Exception {
  const PhotoSpaceFull();

  String get message =>
      'Spazio per le foto esaurito in questa versione web. Le foto si '
      'possono aggiungere senza limiti nell\'app Android.';

  @override
  String toString() => message;
}

/// Dove spedire i promemoria quando il dispositivo non ha notifiche locali
/// (vedi lib/sync/push_reminders.dart).
abstract class ReminderSink {
  /// Account collegato e browser iscritto alle notifiche push.
  bool get active;

  /// Sostituisce i promemoria programmati sul server; [urgent] sono allarmi
  /// da inviare subito, che la sostituzione successiva non cancella.
  Future<void> replace(
    List<PlannedNotification> planned, {
    List<PlannedNotification> urgent = const [],
  });
}
