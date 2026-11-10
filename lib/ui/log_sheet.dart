import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../store.dart';
import 'common.dart';
import 'emergency_screen.dart';

/// Registrazione rapida: un tocco registra "adesso", con possibilità di
/// annullare.
Future<void> quickLog(
  BuildContext context,
  Dog dog,
  LogType type, {
  bool indoor = false,
}) async {
  final store = StoreScope.read(context);
  final e = LogEntry(
    id: newId(),
    dogId: dog.id,
    type: type,
    time: DateTime.now(),
    indoor: indoor,
  );
  await store.addLog(e);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        // Sparisce da sola anche con "Annulla" (rapporto 16).
        duration: const Duration(seconds: 4),
        persist: false,
        content: Text(
          '${type.label}${indoor ? ' in casa' : ''} registrata alle ${hm(e.time)}',
        ),
        action: SnackBarAction(
          label: 'Annulla',
          onPressed: () => store.deleteLog(e.id),
        ),
      ),
    );
}

Future<void> showLogSheet(
  BuildContext context,
  Dog dog,
  LogType type, {
  bool indoor = false,
}) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _LogSheet(dog: dog, type: type, indoor: indoor),
);

/// Gruppi di eventi registrabili.
const logGroups = <(String, List<LogType>)>[
  ('Bisogni', [LogType.pipi, LogType.cacca, LogType.perditaRiposo]),
  (
    'Routine',
    [
      LogType.passeggiata,
      LogType.pasto,
      LogType.acqua,
      LogType.risveglio,
      LogType.gioco,
      LogType.denti,
    ],
  ),
  (
    'Sintomi',
    [
      LogType.collasso,
      LogType.addomeGonfio,
      LogType.vomito,
      LogType.inappetenza,
      LogType.abbattimento,
      LogType.tosse,
      LogType.gengive,
      LogType.convulsione,
      LogType.zoppia,
      LogType.pelle,
      LogType.neuro,
      LogType.perditeVulvari,
      LogType.mammelle,
      LogType.ferita,
      LogType.ingestione,
    ],
  ),
  (
    'Misure',
    [LogType.respiro, LogType.temperatura, LogType.insulina, LogType.glicemia],
  ),
];

/// Scala fecale Purina 1-7 (06 aggiunta 2): 2 = ideale.
const purina = <int, String>{
  1: 'Molto dure e secche, a palline; richiedono sforzo',
  2: 'Compatte ma non dure, segmentate; raccolte non lasciano residui (ideale)',
  3: 'A tronchetto, umide in superficie; lasciano un segno ma restano intere',
  4: 'Molto umide, a tronchetto; lasciano residuo e si disfano se raccolte',
  5: 'Molto umide, a mucchietti con una forma riconoscibile',
  6: 'Consistenza presente ma nessuna forma, a mucchietti o chiazze',
  7: 'Liquide, senza consistenza, a pozza',
};

class _LogSheet extends StatefulWidget {
  const _LogSheet({
    required this.dog,
    required this.type,
    required this.indoor,
  });
  final Dog dog;
  final LogType type;
  final bool indoor;

  @override
  State<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends State<_LogSheet> {
  late LogType type = widget.type;
  late bool indoor = widget.indoor;
  DateTime time = DateTime.now();
  final signs = <Sign>{};
  final ml = TextEditingController();
  final value = TextEditingController();
  final note = TextEditingController();
  int? fecal;
  String? photoId;

  List<Sign> get availableSigns => switch (type) {
    LogType.pipi => [
      Sign.sangue,
      Sign.sforzo,
      Sign.gocce,
      Sign.urinaScura,
      Sign.abbattimento,
    ],
    LogType.cacca => [
      Sign.diarrea,
      Sign.vermi,
      Sign.muco,
      Sign.sangue,
      Sign.nero,
      Sign.sforzo,
      Sign.abbattimento,
    ],
    LogType.vomito => [
      Sign.conati,
      Sign.schiuma,
      Sign.sangue,
      Sign.addomeGonfio,
      Sign.corpoEstraneo,
      Sign.abbattimento,
    ],
    LogType.perditeVulvari => [Sign.sangue, Sign.pus, Sign.maleodoranti],
    LogType.gengive => [
      Sign.gengivePallide,
      Sign.gengiveBlu,
      Sign.gengiveGialle,
      Sign.gengiveRosse,
    ],
    LogType.tosse => [Sign.dispnea, Sign.tosseNotturna, Sign.abbattimento],
    LogType.convulsione => [
      Sign.generalizzata,
      Sign.focale,
      Sign.nonSiRiprende,
    ],
    LogType.zoppia => [Sign.nonCarica],
    LogType.pelle => [
      Sign.prurito,
      Sign.otite,
      Sign.starnuti,
      Sign.improvviso,
      Sign.lesioni,
      Sign.perditaPelo,
    ],
    LogType.ferita => [
      Sign.feritaOk,
      Sign.arrossamento,
      Sign.gonfiore,
      Sign.secrezione,
      Sign.deiscenza,
      Sign.sanguinamento,
    ],
    LogType.neuro => [Sign.barcolla, Sign.testaInclinata, Sign.improvviso],
    LogType.insulina => [Sign.nonHaMangiato],
    LogType.denti => [
      Sign.spazzolati,
      Sign.alitosi,
      Sign.gengiveSanguinanti,
      Sign.masticaMale,
    ],
    _ => const [],
  };

  /// Etichetta del campo numerico per i tipi che lo prevedono.
  (String, String)? get valueField => switch (type) {
    LogType.respiro => (
      'Respiri in un minuto (durante il sonno)',
      'Usa il timer in Salute › Diari, oppure conta per 30" e raddoppia',
    ),
    LogType.convulsione => (
      'Durata (minuti)',
      'Oltre 5 minuti è un\'emergenza',
    ),
    LogType.temperatura => ('Temperatura rettale (°C)', 'Normale 38,0-39,2 °C'),
    LogType.insulina => (
      'Unità somministrate',
      'Come prescritte dal veterinario: l\'app non calcola dosi',
    ),
    LogType.glicemia => (
      'Glicemia (mg/dL)',
      'Solo come registro per il veterinario',
    ),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final elim = type == LogType.pipi || type == LogType.cacca;
    final vf = valueField;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Registra per ${widget.dog.name}',
              style: t.textTheme.titleLarge,
            ),
            for (final (title, types) in logGroups) ...[
              const SizedBox(height: 10),
              Text(title, style: t.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final lt in types)
                    if ((lt != LogType.perditeVulvari &&
                            lt != LogType.mammelle) ||
                        widget.dog.sex == Sex.femmina)
                      ChoiceChip(
                        avatar: Icon(lt.icon, size: 18),
                        label: Text(lt.label),
                        selected: type == lt,
                        onSelected: (_) => setState(() {
                          type = lt;
                          signs.retainAll(availableSigns);
                        }),
                      ),
                ],
              ),
            ],
            if (type == LogType.ingestione)
              Card(
                color: t.colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.emergency),
                  title: const Text(
                    'Chiama subito il veterinario o un centro antiveleni',
                  ),
                  subtitle: const Text(
                    'Non provocare il vomito di tua iniziativa',
                  ),
                  onTap: () => openEmergencies(context),
                ),
              ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text('Quando: ${whenLabel(time, DateTime.now())}'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final r = await pickDateTime(context, time);
                if (r != null) setState(() => time = r);
              },
            ),
            if (elim)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('In casa / incidente'),
                subtitle: const Text(
                  'Aiuta il modello a capire quando era troppo tardi',
                ),
                value: indoor,
                onChanged: (v) => setState(() => indoor = v),
              ),
            if (type == LogType.cacca) ...[
              Text(
                'Consistenza (scala Purina 1-7)',
                style: t.textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final k in purina.keys)
                    ChoiceChip(
                      label: Text('$k'),
                      selected: fecal == k,
                      onSelected: (v) => setState(() => fecal = v ? k : null),
                    ),
                ],
              ),
              if (fecal != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    '$fecal – ${purina[fecal]}',
                    style: t.textTheme.bodySmall,
                  ),
                ),
            ],
            if (type == LogType.acqua)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: ml,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Quantità bevuta (ml, facoltativo)',
                    helperText:
                        'Riferimento con crocchette: ${(widget.dog.weightKg * 50).round()}-${(widget.dog.weightKg * 60).round()} ml al giorno. Con cibo umido beve molto meno: è normale.',
                    helperMaxLines: 3,
                  ),
                ),
              ),
            if (vf != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: vf.$1,
                    helperText: vf.$2,
                    helperMaxLines: 2,
                  ),
                ),
              ),
            if (type == LogType.insulina)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Se non ha mangiato o ha vomitato, non fare l\'insulina senza aver sentito il veterinario.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            if (availableSigns.isNotEmpty) ...[
              Text('Dettagli da annotare', style: t.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in availableSigns)
                    FilterChip(
                      label: Text(s.label),
                      selected: signs.contains(s),
                      onSelected: (v) =>
                          setState(() => v ? signs.add(s) : signs.remove(s)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: note,
              decoration: InputDecoration(
                labelText: type == LogType.ingestione
                    ? 'Cosa, quanto e a che ora'
                    : 'Nota (facoltativa)',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: Icon(
                    photoId == null ? Icons.add_a_photo_outlined : Icons.check,
                  ),
                  label: Text(photoId == null ? 'Foto' : 'Foto allegata'),
                  onPressed: _pickPhoto,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Utile per feci, vomito e lesioni da mostrare al veterinario',
                    style: t.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Salva')),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final store = StoreScope.read(context);
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Scatta una foto'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Scegli dalla galleria'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;
      final x = await ImagePicker().pickImage(
        source: source,
        maxWidth: 900,
        imageQuality: 70,
      );
      if (x == null) return;
      final id = await store.savePhoto(await x.readAsBytes());
      setState(() => photoId = id);
    } catch (e) {
      if (mounted) toast(context, 'Foto non disponibile su questo dispositivo');
    }
  }

  /// Controlli di plausibilità (07 N21). Restituisce un messaggio d'errore.
  String? _check(double? v) {
    if (v == null) return null;
    switch (type) {
      case LogType.temperatura:
        if (v > 90) {
          return 'Sembra in °F: inserisci i gradi Celsius (°F − 32) × 5/9.';
        }
        if (v < 30 || v > 45) return 'Temperatura non plausibile (30-45 °C).';
      case LogType.respiro:
        if (v < 4 || v > 150) {
          return 'Valore non plausibile (4-150 respiri al minuto).';
        }
      case LogType.convulsione:
        if (v < 0 || v > 60) return 'Durata non plausibile (0-60 minuti).';
      case LogType.glicemia:
        if (v < 30) {
          return 'Valore molto basso: se è in mmol/L moltiplica per 18 (mg/dL).';
        }
      default:
        break;
    }
    return null;
  }

  Future<void> _save() async {
    final store = StoreScope.read(context);
    final allSigns = {...signs};
    // "Diarrea" senza punteggio = 6 della scala Purina (07 N33).
    if (type == LogType.cacca &&
        fecal == null &&
        signs.contains(Sign.diarrea)) {
      fecal = 6;
    }
    final parsed = double.tryParse(value.text.replaceAll(',', '.'));
    final problem = _check(parsed);
    if (problem != null) {
      toast(context, problem);
      return;
    }
    // Scala Purina 5-7 = diarrea (usata dagli allarmi).
    if (type == LogType.cacca && fecal != null && fecal! >= 5) {
      allSigns.add(Sign.diarrea);
    }
    final v = type == LogType.cacca
        ? fecal?.toDouble()
        : double.tryParse(value.text.replaceAll(',', '.'));
    await store.addLog(
      LogEntry(
        id: newId(),
        dogId: widget.dog.id,
        type: type,
        time: time,
        indoor: (type == LogType.pipi || type == LogType.cacca) && indoor,
        amountMl: double.tryParse(ml.text.replaceAll(',', '.')),
        signs: allSigns,
        note: note.text.trim(),
        value: v,
        photoId: photoId,
      ),
    );
    if (!mounted) return;
    final nav = Navigator.of(context);
    final wasIngestion = type == LogType.ingestione;
    nav.pop();
    if (wasIngestion) {
      nav.push(MaterialPageRoute(builder: (_) => const EmergencyScreen()));
    }
  }
}
