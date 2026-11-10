import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'logic/alerts.dart';
import 'logic/bio_params.dart';
import 'logic/elimination_model.dart';
import 'logic/nutrition.dart';
import 'logic/potty_predictor.dart';
import 'logic/prevention.dart';
import 'models.dart';
import 'notifications.dart';
import 'sync/sync_engine.dart';

/// Stato dell'app e persistenza locale (JSON in SharedPreferences, che
/// funziona su iOS, Android, web e desktop).
class AppStore extends ChangeNotifier implements SyncTarget {
  AppStore({SharedPreferences? prefs, this.notifier, this.namespace = ''})
    : _prefs = prefs; // ignore: prefer_initializing_formals

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
    'app': 'Zampa',
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
      lastSyncError = null;
      notifyListeners();
      return r;
    } catch (err) {
      lastSyncError = '$err';
      notifyListeners();
      return null;
    }
  }

  @override
  List<LocalItem> syncItems() => [
    for (final d in dogs) LocalItem('dog', d.id, d.id, d.toJson()),
    for (final x in logs) LocalItem('log', x.id, x.dogId, x.toJson()),
    for (final x in records) LocalItem('record', x.id, x.dogId, x.toJson()),
    for (final x in weights) LocalItem('weight', x.id, x.dogId, x.toJson()),
    for (final x in doses) LocalItem('dose', x.id, x.dogId, x.toJson()),
    for (final x in repro) LocalItem('repro', x.id, x.dogId, x.toJson()),
    for (final x in qol) LocalItem('qol', x.id, x.dogId, x.toJson()),
    for (final x in labs) LocalItem('lab', x.id, x.dogId, x.toJson()),
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
  Future<void> afterSignOut({required bool keepLocal}) async {
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
    await _prefs!.setString('photo_$id', base64Encode(bytes));
    return id;
  }

  Uint8List? photo(String id) {
    final s = _prefs?.getString('photo_$id');
    return s == null ? null : base64Decode(s);
  }

  // --- Promemoria ---------------------------------------------------------
  Future<void> _reschedule() async {
    final n = notifier;
    if (n == null || !n.supported) return;
    final now = DateTime.now();
    for (var di = 0; di < dogs.length && di < 9; di++) {
      final d = dogs[di];
      final base = (di + 1) * 1000;
      // Allarmi urgenti: notifica immediata, una volta sola per allarme
      // (06 aggiunta 13).
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
        final slot = base + 90 + ui++;
        if (_prefs!.getBool(key) ?? false) continue;
        await _prefs!.setBool(key, true);
        await n.showNow(
          slot,
          '${a.level == AlertLevel.subito ? '🔴 SUBITO' : '🟠 OGGI'}: ${a.title}',
          '${d.name}: ${a.actionText ?? a.message}',
        );
      }
      // Notifiche a tempo anche ad app chiusa (07 N13): pipì mancata.
      final dLogs = logs.where((l) => l.dogId == d.id).toList()
        ..sort((a, b) => a.time.compareTo(b.time));
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
        final hours = puppy
            ? (d.ageInMonths(now) < 4 ? 6 : 8)
            : (strainMale ? 12 : 24);
        var at = last.add(Duration(hours: hours));
        if (puppy && PottyPredictor.inSleepWindow(d, at)) {
          at = PottyPredictor.nextWake(d, at).add(const Duration(hours: 1));
        }
        await n.schedule(
          base + 96,
          at,
          '🔴 ${d.name}: nessuna pipì da $hours ore?',
          'Se non ha davvero urinato è un\'urgenza: contatta il veterinario. '
              'Se l\'ha fatta, registrala.',
        );
      } else {
        await n.cancel(base + 96);
      }
      // Dosi non confermate dopo 2 ore.
      final upcoming = <DateTime>[];
      for (final r in records.where(
        (r) => r.dogId == d.id && r.isActiveTherapy(now),
      )) {
        final nd = nextDose(r, now.subtract(const Duration(hours: 2)));
        if (nd != null) upcoming.add(nd.add(const Duration(hours: 2)));
      }
      upcoming.sort();
      for (var k = 0; k < 3; k++) {
        if (k < upcoming.length) {
          await n.schedule(
            base + 97 + k,
            upcoming[k],
            '💊 Dose confermata per ${d.name}?',
            'Apri Zampa e segna "Dato" o "Saltato". Se l\'hai saltata non '
                'raddoppiare la successiva: chiedi al veterinario.',
          );
        } else {
          await n.cancel(base + 97 + k);
        }
      }
      // Prossima uscita per pipì e cacca.
      for (final need in Need.values) {
        final id = base + (need == Need.pipi ? 0 : 45);
        final on = need == Need.pipi ? d.pottyRemindersOn : d.poopRemindersOn;
        if (!on) {
          await n.cancel(id);
          continue;
        }
        final p = forecast(d, need, now);
        if (p.last == null) {
          await n.cancel(id);
          continue;
        }
        final at = p.recommendedAt.subtract(
          Duration(minutes: d.reminderLeadMinutes),
        );
        await n.schedule(
          id,
          at.isAfter(now) ? at : p.recommendedAt,
          need == Need.pipi
              ? 'È quasi ora di uscire con ${d.name} 🐾'
              : 'Probabile cacca in arrivo per ${d.name} 💩',
          'Uscita consigliata alle ${hm(p.recommendedAt)}. ${p.reason}',
        );
      }
      // Scadenze sanitarie: il giorno stesso alle 9 e 3 giorni prima.
      final due = dueItems(
        records,
        d.id,
      ).where((x) => !x.overdue(now)).take(20);
      var k = 1;
      for (final item in due) {
        final day = DateTime(item.due.year, item.due.month, item.due.day, 9);
        await n.schedule(
          base + k++,
          day.subtract(const Duration(days: 3)),
          '${item.record.type.emoji} Tra 3 giorni: ${item.record.title}',
          'Promemoria per ${d.name}. Prenota se serve.',
        );
        await n.schedule(
          base + k++,
          day,
          '${item.record.type.emoji} Oggi: ${item.record.title}',
          'Scadenza di oggi per ${d.name}.',
        );
      }
      for (; k <= 40; k++) {
        await n.cancel(base + k);
      }
      // Terapie in corso: tutte le dosi delle prossime 72 ore (così i
      // promemoria arrivano anche se l'app non viene aperta).
      var t = 0;
      for (final r in records.where(
        (r) => r.dogId == d.id && r.isActiveTherapy(now),
      )) {
        var next = nextDose(r, now);
        while (next != null &&
            t < 30 &&
            next.isBefore(now.add(const Duration(hours: 72)))) {
          await n.schedule(
            base + 50 + t++,
            next,
            '💊 ${r.title} per ${d.name}',
            '${r.dose.isEmpty ? 'È ora della dose' : 'Dose: ${r.dose}'} '
                '(come prescritta dal veterinario). Se l\'hai saltata, non '
                'raddoppiare: chiedi al veterinario.',
          );
          next = nextDose(r, next.add(const Duration(minutes: 1)));
        }
      }
      for (; t < 30; t++) {
        await n.cancel(base + 50 + t);
      }
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
    b.writeln('Generata con Zampa il ${dmy(now)}');
    b.writeln();
    b.writeln(
      'Razza: ${d.breed.isEmpty ? '-' : d.breed}  ·  Sesso: ${d.sex.name}'
      '${d.neutered ? ' (sterilizzato/a)' : ''}',
    );
    b.writeln('Nato il: ${dmy(d.birthDate)} (${ageLabel(d, now)})');
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
      id: newId(),
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
  if (m < 1) return '${(m * 4.35).floor()} settimane';
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
