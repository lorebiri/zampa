import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import 'common.dart';
import 'dog_form.dart';
import 'health_screen.dart';
import 'theme.dart';

/// Risposta a «Prende medicine?» (ricerca/26 A6).
enum MedsAnswer { no, now, later }

/// Procedura guidata per il primo cane: cinque passi brevi, un concetto per
/// schermata, pulsanti grandi (ricerca/16, ricerca/22 §8). Chiede solo quello
/// che serve per partire; il resto sta nel modulo completo («Altri dettagli»).
/// Le regole sono quelle del modulo: nome, data di nascita (mai futura) e
/// peso obbligatori, tutto il resto facoltativo.
class DogWizardPage extends StatefulWidget {
  const DogWizardPage({super.key});

  static const steps = 5;

  @override
  State<DogWizardPage> createState() => _DogWizardPageState();
}

class _DogWizardPageState extends State<DogWizardPage> {
  int step = 0;
  final name = TextEditingController();
  final weight = TextEditingController();
  final conditions = TextEditingController();
  Sex sex = Sex.maschio;
  String? photoId;
  // Nessuna data proposta: un cucciolo trattato da adulto riceverebbe
  // consigli sbagliati (rapporti 16 e 21).
  DateTime? birth;
  AdultSize? adultSize;
  bool neutered = false;
  // Orari proposti: gli stessi valori predefiniti del modulo completo.
  int wakeHour = 7;
  int sleepHour = 23;
  // Terapie in corso (ricerca/26 A6): salvate insieme al cane.
  final dogId = newId();
  MedsAnswer? meds;
  final therapies = <HealthRecord>[];

  /// Il passo ha già provato ad andare avanti: da qui si mostrano gli errori.
  final tried = <int>{};
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    weight.dispose();
    conditions.dispose();
    super.dispose();
  }

  bool get _nameOk => name.text.trim().isNotEmpty;
  bool get _birthOk => birth != null;
  bool get _weightOk => parseDogWeight(weight.text) != null;

  bool _stepOk(int s) => switch (s) {
    0 => _nameOk,
    1 => _birthOk && _weightOk,
    _ => true,
  };

  void _next() {
    if (!_stepOk(step)) {
      setState(() => tried.add(step));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => step++);
  }

  void _back() {
    FocusScope.of(context).unfocus();
    setState(() => step--);
  }

  Future<void> _finish({required bool moreDetails}) async {
    if (saving) return;
    final kg = parseDogWeight(weight.text);
    if (!_nameOk || kg == null || birth == null) {
      toast(context, 'Servono almeno nome, data di nascita e peso');
      return;
    }
    setState(() => saving = true);
    final store = StoreScope.read(context);
    final dog = Dog(
      id: dogId,
      name: name.text.trim(),
      birthDate: birth!,
      sex: sex,
      weightKg: kg,
      neutered: neutered,
      conditions: conditions.text.trim(),
      adultSize: adultSize,
      wakeHour: wakeHour,
      sleepStartHour: sleepHour,
      photoId: photoId,
      // Taglia del compagno coerente con il peso indicato.
      look: AvatarLook.forWeight(kg),
      // «Le aggiungo dopo» (o «ora» senza averne aggiunte): scheda in Home.
      medsToAdd:
          meds == MedsAnswer.later ||
          (meds == MedsAnswer.now && therapies.isEmpty),
    );
    await saveDogWithFirstDogPrompts(
      context,
      store,
      dog,
      records: meds == MedsAnswer.now ? therapies : const [],
    );
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (moreDetails) {
      await nav.pushReplacement(
        MaterialPageRoute(builder: (_) => DogFormPage(dog: dog)),
      );
    } else {
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final last = step == DogWizardPage.steps - 1;
    final (title, intro, fields) = switch (step) {
      0 => (
        'Come si chiama?',
        'Iniziamo dalle cose semplici. La foto è facoltativa.',
        _stepName(),
      ),
      1 => (
        sex == Sex.femmina ? 'Quando è nata?' : 'Quando è nato?',
        'Età e peso servono per i consigli giusti: un cucciolo non è un adulto.',
        _stepBirth(),
      ),
      2 => (
        'Salute',
        'Facoltativo: puoi completarlo anche più avanti.',
        _stepHealth(),
      ),
      3 => (
        'Prende medicine?',
        'Alcune medicine cambiano quanto beve e quanto spesso deve uscire, e '
            'alcuni segni vanno presi più sul serio durante una terapia. Se non '
            'lo sai ora, puoi aggiungerle dopo.',
        _stepMeds(),
      ),
      _ => (
        'La sua giornata',
        'Servono per i promemoria delle uscite. Ti proponiamo gli orari più '
            'comuni: cambiali se serve.',
        _stepRoutine(),
      ),
    };
    return PopScope(
      // Il tasto Indietro del telefono torna al passo precedente.
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && step > 0) _back();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Il tuo cane')),
        // Una chiave per passo: ogni passo riparte dall'alto e i campi non
        // ereditano lo stato di quelli del passo precedente.
        body: PageBody(
          key: ValueKey(step),
          children: [
            Semantics(
              label: 'Passo ${step + 1} di ${DogWizardPage.steps}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Passo ${step + 1} di ${DogWizardPage.steps}',
                    style: t.textTheme.labelLarge?.copyWith(
                      color: t.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Space.s),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (step + 1) / DogWizardPage.steps,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.xl),
            Semantics(
              header: true,
              child: Text(title, style: t.textTheme.headlineSmall),
            ),
            const SizedBox(height: Space.s),
            Text(
              intro,
              style: t.textTheme.bodyLarge?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Space.xl),
            ...fields,
            const SizedBox(height: Space.xl),
            if (last) ...[
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('Fatto'),
                onPressed: saving ? null : () => _finish(moreDetails: false),
              ),
              const SizedBox(height: Space.m),
              OutlinedButton.icon(
                icon: const Icon(Icons.tune),
                label: const Text('Altri dettagli'),
                onPressed: saving ? null : () => _finish(moreDetails: true),
              ),
              const SizedBox(height: Space.s),
              Text(
                'Veterinario, microchip, alimentazione, regione, avviso caldo, '
                'aspetto del compagno e promemoria.',
                style: t.textTheme.bodyMedium?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else
              FilledButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Avanti'),
                onPressed: _next,
              ),
            if (step > 0) ...[
              const SizedBox(height: Space.m),
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Indietro'),
                onPressed: saving ? null : _back,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _stepName() => [
    LabeledField(
      label: 'Nome *',
      child: TextField(
        controller: name,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _next(),
        decoration: InputDecoration(
          errorText: tried.contains(0) && !_nameOk
              ? 'Scrivi il nome del cane'
              : null,
        ),
      ),
    ),
    const SizedBox(height: Space.l),
    LabeledField(
      label: 'Maschio o femmina?',
      child: SegmentedButton<Sex>(
        segments: const [
          ButtonSegment(value: Sex.maschio, label: Text('Maschio')),
          ButtonSegment(value: Sex.femmina, label: Text('Femmina')),
        ],
        selected: {sex},
        onSelectionChanged: (s) => setState(() => sex = s.first),
      ),
    ),
    const SizedBox(height: Space.l),
    LabeledField(
      label: 'Foto (facoltativa)',
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: DogPhotoField(
          photoId: photoId,
          onChanged: (id) => setState(() => photoId = id),
        ),
      ),
    ),
  ];

  List<Widget> _stepBirth() {
    final t = Theme.of(context);
    final birthError = tried.contains(1) && !_birthOk;
    final weightError = tried.contains(1) && !_weightOk;
    return [
      LabeledField(
        label: 'Data di nascita *',
        child: OutlinedButton.icon(
          icon: const Icon(Icons.cake_outlined),
          label: Text(
            birth == null
                ? 'Scegli la data'
                : '${sex == Sex.femmina ? 'Nata' : 'Nato'} il ${dmy(birth!)}',
          ),
          style: birthError
              ? OutlinedButton.styleFrom(
                  side: BorderSide(color: t.colorScheme.error, width: 2),
                )
              : null,
          onPressed: () async {
            final r = await pickBirthDate(context, birth);
            if (r != null) setState(() => birth = r);
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 4, top: 6),
        child: birthError
            ? Semantics(
                liveRegion: true,
                child: Text(
                  'Serve la data di nascita',
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: t.colorScheme.error,
                  ),
                ),
              )
            : Text(
                'Se non la sai, una data approssimativa va bene',
                style: t.textTheme.bodyMedium?.copyWith(
                  color: t.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
      const SizedBox(height: Space.l),
      DogWeightField(
        controller: weight,
        onChanged: (_) => setState(() {}),
        errorText: weightError
            ? 'Scrivi il peso in kg, per esempio 12,5'
            : null,
      ),
      const SizedBox(height: Space.l),
      LabeledField(
        label: 'Taglia da adulto (facoltativa)',
        child: DropdownButtonFormField<AdultSize?>(
          isExpanded: true,
          initialValue: adultSize,
          decoration: const InputDecoration(
            helperText: 'Per i cuccioli: decide fino a quando cresce e il tipo di alimento',
            helperMaxLines: 3,
          ),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Non so / già adulto'),
            ),
            for (final x in AdultSize.values)
              DropdownMenuItem(value: x, child: Text(x.label)),
          ],
          onChanged: (v) => setState(() => adultSize = v),
        ),
      ),
    ];
  }

  List<Widget> _stepHealth() => [
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(sex == Sex.femmina ? 'Sterilizzata' : 'Sterilizzato'),
      value: neutered,
      onChanged: (v) => setState(() => neutered = v),
    ),
    const SizedBox(height: Space.l),
    LabeledField(
      label: 'Malattie note (facoltativo)',
      child: TextField(
        controller: conditions,
        maxLines: null,
        decoration: const InputDecoration(
          helperText: 'Es. diabete, Cushing, malattia renale, cistite: il modello ne tiene conto',
          helperMaxLines: 3,
        ),
      ),
    ),
  ];

  /// Il cane non è ancora salvato: il modulo della terapia riceve un cane
  /// provvisorio con l'ID definitivo.
  Dog get _draftDog => Dog(
    id: dogId,
    name: name.text.trim(),
    birthDate: birth ?? DateTime.now(),
    sex: sex,
    weightKg: parseDogWeight(weight.text) ?? 10,
  );

  /// Il modulo della terapia della scheda Salute, in modalità «solo terapia».
  Future<void> _addTherapy() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => RecordFormPage(
        dog: _draftDog,
        therapyOnly: true,
        onSave: (r) async => setState(() => therapies.add(r)),
      ),
    ),
  );

  Future<void> _choose(MedsAnswer a) async {
    setState(() => meds = a);
    if (a == MedsAnswer.now && therapies.isEmpty) await _addTherapy();
  }

  List<Widget> _stepMeds() {
    final t = Theme.of(context);
    return [
      Wrap(
        spacing: Space.s,
        runSpacing: Space.s,
        children: [
          for (final (a, label) in [
            (MedsAnswer.no, 'No'),
            (MedsAnswer.now, 'Sì, le aggiungo ora'),
            (MedsAnswer.later, 'Sì, le aggiungo dopo'),
          ])
            ChoiceChip(
              label: Text(label),
              selected: meds == a,
              onSelected: (_) => _choose(a),
            ),
        ],
      ),
      if (meds == MedsAnswer.now) ...[
        const SizedBox(height: Space.l),
        for (final r in therapies)
          Card(
            child: ListTile(
              leading: const Icon(Icons.medication_outlined),
              title: Text(
                '${r.title}${r.dose.isNotEmpty ? ' · ${r.dose}' : ''}',
              ),
              subtitle: Text(
                'Ogni ${r.everyHours} ore, dal ${dmy(r.date)} '
                        '${r.endDate == null ? '' : 'al ${dmy(r.endDate!)}'}'
                    .trim(),
              ),
              trailing: IconButton(
                tooltip: 'Togli ${r.title}',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => therapies.remove(r)),
              ),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(
            therapies.isEmpty
                ? 'Aggiungi una medicina'
                : 'Aggiungi un\'altra medicina',
          ),
          onPressed: _addTherapy,
        ),
      ],
      if (meds == MedsAnswer.later) ...[
        const SizedBox(height: Space.l),
        Text(
          'Troverai in Home un promemoria per aggiungerle.',
          style: t.textTheme.bodyMedium?.copyWith(
            color: t.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ];
  }

  List<Widget> _stepRoutine() => [
    HourPicker(
      label: 'Si sveglia alle',
      value: wakeHour,
      onChanged: (v) => setState(() => wakeHour = v),
    ),
    const SizedBox(height: Space.l),
    HourPicker(
      label: 'Dorme dalle',
      value: sleepHour,
      onChanged: (v) => setState(() => sleepHour = v),
    ),
  ];
}
