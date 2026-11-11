import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import 'common.dart';
import 'dog_form.dart';
import 'theme.dart';

/// Procedura guidata per il primo cane: quattro passi brevi, un concetto per
/// schermata, pulsanti grandi (ricerca/16, ricerca/22 §8). Chiede solo quello
/// che serve per partire; il resto sta nel modulo completo («Altri dettagli»).
/// Le regole sono quelle del modulo: nome, data di nascita (mai futura) e
/// peso obbligatori, tutto il resto facoltativo.
class DogWizardPage extends StatefulWidget {
  const DogWizardPage({super.key});

  static const steps = 4;

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
      id: newId(),
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
    );
    await saveDogWithFirstDogPrompts(context, store, dog);
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
