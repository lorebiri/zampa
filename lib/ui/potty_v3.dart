import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../consent.dart';
import '../logic/outing_plan.dart';
import '../logic/poop_forecast.dart';
import '../logic/potty_signals.dart';
import '../logic/study_export.dart';
import '../models.dart';
import 'common.dart';

/// Schede v3 della schermata pipì e cacca (ricerca/28): segnali a un tocco,
/// «Esci adesso», previsione della cacca legata ai pasti, piano di uscite,
/// esportazione anonima per lo studio. Tutte «in prova».

String _two(int x) => x.toString().padLeft(2, '0');
String _hm(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

// ---------------------------------------------------------------------------
// Segnali.
// ---------------------------------------------------------------------------

/// Testi dei segnali (i testi visibili non stanno in lib/logic).
String signalWhat(Sign s, String name) => switch (s) {
  Sign.annusaTerra => '$name annusa a terra',
  Sign.giraSuSe => '$name gira su sé stesso',
  Sign.allaPorta => '$name è andato alla porta',
  Sign.guaisce => '$name guaisce',
  _ => '$name è irrequieto',
};

/// Riga di 5 bottoni: un tocco salva il segnale con l'ora attuale.
class SignalButtons extends StatelessWidget {
  const SignalButtons({super.key, required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ti sta chiedendo di uscire?', style: t.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Un tocco quando lo vedi: impariamo i suoi segnali.',
              style: t.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in signalKinds)
                  ActionChip(
                    avatar: Text(signalEmoji(s)),
                    label: Text(s.label),
                    onPressed: () => _logSignal(context, s),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logSignal(BuildContext context, Sign s) async {
    final store = StoreScope.read(context);
    final e = LogEntry(
      id: newId(),
      dogId: dog.id,
      type: LogType.segnale,
      time: DateTime.now(),
      signs: {s},
    );
    await store.addLog(e);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          persist: false,
          content: Text('Segnale registrato alle ${_hm(e.time)}: esci adesso.'),
          action: SnackBarAction(
            label: 'Annulla',
            onPressed: () => store.deleteLog(e.id),
          ),
        ),
      );
  }
}

/// Testi dell'avviso «Esci adesso».
({String title, String body})? signalTexts(
  SignalAlert? a,
  DateTime now,
  String name,
) {
  if (a == null || !a.goNow) return null;
  final ago = now.difference(a.at).inMinutes;
  final when = ago <= 1 ? 'adesso' : '$ago minuti fa';
  final likely = a.prob30 >= 0.7
      ? 'Di solito, dopo questo segnale, la fa entro mezz\'ora.'
      : a.prob30 >= 0.45
      ? 'Spesso, dopo questo segnale, la fa entro mezz\'ora.'
      : 'Non sempre vuol dire che deve uscire, ma è meglio controllare.';
  return (
    title: 'Esci adesso con $name',
    body: '${signalWhat(a.kind, name)} ($when). $likely',
  );
}

class SignalBanner extends StatelessWidget {
  const SignalBanner({super.key, required this.dog, required this.logs});
  final Dog dog;
  final List<LogEntry> logs;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final x = signalTexts(signalAlert(logs, now), now, dog.name);
    if (x == null) return const SizedBox.shrink();
    final t = Theme.of(context);
    return Card(
      color: t.colorScheme.tertiaryContainer,
      child: ListTile(
        leading: const Icon(Icons.sensor_door_outlined),
        title: Text(x.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(x.body),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cacca legata ai pasti.
// ---------------------------------------------------------------------------

({String title, String window, String why})? poopTexts(
  PoopForecast? f,
  DateTime now,
  String name,
) {
  if (f == null) return null;
  final m = f.expectedAt.difference(now).inMinutes;
  final title = m <= 0
      ? 'Potrebbe essere ora per la cacca'
      : 'Prossima cacca verso le ${_hm(f.expectedAt)}';
  final window = f.hi50.isBefore(now)
      ? 'Se chiede di uscire, portalo fuori.'
      : 'Di solito tra le ${_hm(f.lo50.isBefore(now) ? now : f.lo50)} e le '
            '${_hm(f.hi50)}.';
  final a = f.mainAnchor;
  final why = a == null
      ? 'In base al tempo dall\'ultima cacca e ai suoi orari dei giorni scorsi.'
      : a.kind == PoopAnchorKind.pasto
      ? 'Di solito la fa dopo il pasto delle ${_hm(a.at)} '
            '(circa ${a.predicted.difference(a.at).inMinutes} minuti dopo).'
      : 'Di solito la fa durante l\'uscita delle ${_hm(a.at)}.';
  return (title: title, window: window, why: why);
}

class PoopV3Card extends StatelessWidget {
  const PoopV3Card({super.key, required this.dog, required this.logs});
  final Dog dog;
  final List<LogEntry> logs;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final x = poopTexts(poopForecast(dog, logs, now), now, dog.name);
    if (x == null) return const SizedBox.shrink();
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cacca legata ai pasti (in prova)',
                style: t.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(x.title, style: t.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(x.window),
            const SizedBox(height: 6),
            Text(x.why, style: t.textTheme.bodySmall),
            Text(
              'È una stima: se ${dog.name} chiede di uscire, ascolta lui.',
              style: t.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Piano di uscite.
// ---------------------------------------------------------------------------

/// Orari del padrone, salvati solo sul telefono.
class OwnerPrefs {
  OwnerPrefs({this.awayFrom, this.awayTo, this.n = 4});
  int? awayFrom, awayTo; // minuti, giorni feriali
  int n;

  static String _key(String dogId) => 'lulu_owner_$dogId';

  static Future<OwnerPrefs> load(String dogId) async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_key(dogId));
    if (s == null) return OwnerPrefs();
    final j = jsonDecode(s) as Map<String, dynamic>;
    return OwnerPrefs(
      awayFrom: j['awayFrom'] as int?,
      awayTo: j['awayTo'] as int?,
      n: (j['n'] as int?) ?? 4,
    );
  }

  Future<void> save(String dogId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _key(dogId),
      jsonEncode({'awayFrom': awayFrom, 'awayTo': awayTo, 'n': n}),
    );
  }

  OwnerSchedule get schedule => OwnerSchedule(
    awayWeekdays: awayFrom != null && awayTo != null && awayTo! > awayFrom!
        ? [(awayFrom!, awayTo!)]
        : const [],
  );
}

/// Rischio a parole (niente frasi di accuratezza: solo una stima).
String riskWords(double perWeek) => perWeek < 0.25
    ? 'rischio molto basso'
    : perWeek < 0.75
    ? 'rischio basso'
    : perWeek < 2
    ? 'rischio medio'
    : 'rischio alto';

String planLine(OutingPlan p) {
  final times = p.times.isEmpty ? 'nessuna altra uscita oggi' : p.times.map(_hm).join(', ');
  final w = p.perWeek;
  final est = w < 0.25
      ? 'meno di un incidente al mese'
      : w < 1
      ? 'circa ${math.max(1, (w * 4).round())} incidenti al mese'
      : 'circa ${w.round()} incidenti a settimana';
  return '$times · ${riskWords(w)} ($est)${p.overCap ? ' · un intervallo supera il limite per la sua età' : ''}';
}

class OutingPlanCard extends StatefulWidget {
  const OutingPlanCard({super.key, required this.dog, required this.logs});
  final Dog dog;
  final List<LogEntry> logs;

  @override
  State<OutingPlanCard> createState() => _OutingPlanCardState();
}

class _OutingPlanCardState extends State<OutingPlanCard> {
  OwnerPrefs? prefs;

  @override
  void initState() {
    super.initState();
    OwnerPrefs.load(widget.dog.id).then((p) {
      if (mounted) setState(() => prefs = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = prefs;
    if (p == null) return const SizedBox.shrink();
    final t = Theme.of(context);
    final now = DateTime.now();
    final opts = planOptions(widget.dog, widget.logs, p.schedule, now);
    String fmtMin(int? m) => m == null ? '—' : '${_two(m ~/ 60)}:${_two(m % 60)}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Piano di uscite (in prova)', style: t.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(
              'Quante uscite vuoi fare oggi?',
              style: t.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final o in opts)
              RadioListTile<int>(
                contentPadding: EdgeInsets.zero,
                value: o.n,
                // ignore: deprecated_member_use
                groupValue: p.n,
                // ignore: deprecated_member_use
                onChanged: (v) {
                  setState(() => p.n = v ?? 4);
                  p.save(widget.dog.id);
                },
                title: Text('${o.n} uscite'),
                subtitle: Text(planLine(o)),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.awayFrom == null
                        ? 'Nei giorni feriali sei a casa.'
                        : 'Nei giorni feriali sei fuori dalle '
                              '${fmtMin(p.awayFrom)} alle ${fmtMin(p.awayTo)}.',
                    style: t.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () => _editAway(context, p),
                  child: const Text('Cambia'),
                ),
              ],
            ),
            Text(
              'Il piano usa le pipì e gli incidenti registrati e si rifà ogni '
              'giorno. È un aiuto, non un obbligo: se ${widget.dog.name} '
              'chiede di uscire, portalo fuori.',
              style: t.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAway(BuildContext context, OwnerPrefs p) async {
    final from = await showTimePicker(
      context: context,
      helpText: 'Esci di casa alle (giorni feriali)',
      initialTime: TimeOfDay(
        hour: (p.awayFrom ?? 510) ~/ 60,
        minute: (p.awayFrom ?? 510) % 60,
      ),
    );
    if (from == null || !context.mounted) return;
    final to = await showTimePicker(
      context: context,
      helpText: 'Rientri alle',
      initialTime: TimeOfDay(
        hour: (p.awayTo ?? 1065) ~/ 60,
        minute: (p.awayTo ?? 1065) % 60,
      ),
    );
    if (to == null) return;
    setState(() {
      p.awayFrom = from.hour * 60 + from.minute;
      p.awayTo = to.hour * 60 + to.minute;
      if (p.awayTo! <= p.awayFrom!) {
        p.awayFrom = null;
        p.awayTo = null;
      }
    });
    await p.save(widget.dog.id);
  }
}

// ---------------------------------------------------------------------------
// Esportazione anonima per lo studio.
// ---------------------------------------------------------------------------

class StudyExportTile extends StatelessWidget {
  const StudyExportTile({super.key, required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.science_outlined),
        title: const Text('Esporta i dati anonimi per lo studio'),
        subtitle: const Text(
          'Solo numeri calcolati sul telefono: niente nome, diario, orari o '
          'posizione. Lo condividi tu.',
        ),
        onTap: () => _export(context),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final consent = ConsentStore.instance.allowed(ConsentKind.study);
    if (!consent) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Serve il tuo consenso'),
          content: const Text(
            'Per esportare i dati dello studio devi prima dire di sì a '
            '«Studio sull\'accuratezza» in Privacy. Senza consenso non '
            'esce nulla dal telefono.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Ho capito'),
            ),
          ],
        ),
      );
      return;
    }
    final store = StoreScope.read(context);
    final prefs = await SharedPreferences.getInstance();
    final key = 'lulu_study_pid_${dog.id}';
    final pid = prefs.getString(key) ?? newStudyPid();
    await prefs.setString(key, pid);
    final data = buildStudyExport(
      dog: dog,
      logs: store.logsOf(dog.id),
      now: DateTime.now(),
      pid: pid,
      consent: consent,
    );
    if (data == null || !context.mounted) return;
    final json = const JsonEncoder.withIndent(' ').convert(data);
    final name = 'lulu-studio-${pid.substring(0, 8)}.json';
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(json)),
            mimeType: 'application/json',
            name: name,
          ),
        ],
        fileNameOverrides: [name],
        subject: 'Dati anonimi per lo studio',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}
