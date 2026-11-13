import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../brand.dart';
import '../models.dart';
import '../store.dart';
import '../logic/weather.dart';
import '../notifications.dart';
import 'common.dart';
import 'avatar_editor.dart';

class DogFormPage extends StatefulWidget {
  const DogFormPage({super.key, this.dog});
  final Dog? dog;

  @override
  State<DogFormPage> createState() => _DogFormPageState();
}

class _DogFormPageState extends State<DogFormPage> {
  late final Dog? d = widget.dog;
  late final name = TextEditingController(text: d?.name ?? '');
  late final breed = TextEditingController(text: d?.breed ?? '');
  late final weight = TextEditingController(
    text: d?.weightKg.toStringAsFixed(1) ?? '',
  );
  late final chip = TextEditingController(text: d?.microchip ?? '');
  late final vetName = TextEditingController(text: d?.vetName ?? '');
  late final vetPhone = TextEditingController(text: d?.vetPhone ?? '');
  late final allergies = TextEditingController(text: d?.allergies ?? '');
  late final conditions = TextEditingController(text: d?.conditions ?? '');
  // Nessuna data predefinita per un cane nuovo: un cucciolo trattato da
  // adulto riceverebbe consigli sbagliati (rapporti 16 e 21).
  late DateTime? birth = d?.birthDate;
  late Sex sex = d?.sex ?? Sex.maschio;
  late bool neutered = d?.neutered ?? false;
  late ActivityLevel activity = d?.activity ?? ActivityLevel.normale;
  late DietType diet = d?.diet ?? DietType.secco;
  late ReproState repro = d?.reproState ?? ReproState.nessuno;
  late DateTime? reproSince = d?.reproSince;
  late int wakeHour = d?.wakeHour ?? 7;
  late int sleepHour = d?.sleepStartHour ?? 23;
  late Prudence prudence = d?.prudence ?? Prudence.normale;
  late bool peeRem = d?.pottyRemindersOn ?? true;
  late bool poopRem = d?.poopRemindersOn ?? true;
  late int lead = d?.reminderLeadMinutes ?? 10;
  late Region region = d?.region ?? Region.centro;
  late AdultSize? adultSize = d?.adultSize;
  late bool heat = d?.heatAlertsOn ?? false;
  late final city = TextEditingController(text: d?.city ?? '');
  late final emergency = TextEditingController(text: d?.emergencyPhone ?? '');
  late String? photoId = d?.photoId;

  @override
  Widget build(BuildContext context) {
    final chipProblem = microchipProblem(chip.text);
    return Scaffold(
      appBar: AppBar(
        title: Text(d == null ? 'Nuovo cane' : 'Modifica ${d!.name}'),
      ),
      body: PageBody(
        children: [
          DogPhotoField(
            photoId: photoId,
            onChanged: (id) => setState(() => photoId = id),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Nome *',
            child: TextField(controller: name),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Razza o tipo',
            child: TextField(controller: breed),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cake_outlined),
            title: Text(
              birth == null
                  ? 'Data di nascita *'
                  : '${sex == Sex.femmina ? 'Nata' : 'Nato'} il ${dmy(birth!)}',
            ),
            subtitle: const Text(
              'Se non la sai, una data approssimativa va bene',
            ),
            onTap: () async {
              final r = await pickBirthDate(context, birth);
              if (r != null) setState(() => birth = r);
            },
          ),
          DogWeightField(controller: weight),
          const SizedBox(height: 12),
          SegmentedButton<Sex>(
            segments: const [
              ButtonSegment(value: Sex.maschio, label: Text('Maschio')),
              ButtonSegment(value: Sex.femmina, label: Text('Femmina')),
            ],
            selected: {sex},
            onSelectionChanged: (s) => setState(() => sex = s.first),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sterilizzato/a'),
            value: neutered,
            onChanged: (v) => setState(() => neutered = v),
          ),
          LabeledField(
            label: 'Taglia adulta prevista',
            child: DropdownButtonFormField<AdultSize?>(
              isExpanded: true,
              initialValue: adultSize,
              decoration: const InputDecoration(
                helperText: 'Per i cuccioli: decide fino a quando cresce e il tipo di alimento',
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
          const SizedBox(height: 12),
          LabeledField(
            label: 'Livello di attività',
            child: DropdownButtonFormField<ActivityLevel>(
              isExpanded: true,
              initialValue: activity,
              items: const [
                DropdownMenuItem(
                  value: ActivityLevel.bassa,
                  child: Text('Bassa (sedentario)'),
                ),
                DropdownMenuItem(
                  value: ActivityLevel.normale,
                  child: Text('Normale'),
                ),
                DropdownMenuItem(
                  value: ActivityLevel.alta,
                  child: Text('Alta (molto sportivo)'),
                ),
                DropdownMenuItem(
                  value: ActivityLevel.lavoro,
                  child: Text('Cane da lavoro'),
                ),
              ],
              onChanged: (v) => setState(() => activity = v ?? activity),
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Alimentazione',
            child: DropdownButtonFormField<DietType>(
              isExpanded: true,
              initialValue: diet,
              items: [
                for (final x in DietType.values)
                  DropdownMenuItem(value: x, child: Text(x.label)),
              ],
              onChanged: (v) => setState(() => diet = v ?? diet),
            ),
          ),
          if (sex == Sex.femmina) ...[
            const SizedBox(height: 12),
            LabeledField(
              label: 'Stato riproduttivo',
              child: DropdownButtonFormField<ReproState>(
                isExpanded: true,
                initialValue: repro,
                items: [
                  for (final x in ReproState.values)
                    DropdownMenuItem(value: x, child: Text(x.label)),
                ],
                onChanged: (v) => setState(() {
                  repro = v ?? repro;
                  reproSince ??= DateTime.now();
                }),
              ),
            ),
            if (repro != ReproState.nessuno)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: Text('Dal ${dmy(reproSince ?? DateTime.now())}'),
                onTap: () async {
                  final r = await pickDate(
                    context,
                    reproSince ?? DateTime.now(),
                  );
                  if (r != null) setState(() => reproSince = r);
                },
              ),
          ],
          if (d != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.brush_outlined),
              label: const Text('Personalizza l\'aspetto del compagno'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AvatarEditorPage(dog: d!)),
              ),
            ),
          ],
          const SectionTitle('Routine e promemoria'),
          Row(
            // Etichette di altezza diversa: i campi restano allineati in basso.
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: HourPicker(
                  label: 'Si sveglia alle',
                  value: wakeHour,
                  onChanged: (v) => setState(() => wakeHour = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HourPicker(
                  label: 'Dorme dalle',
                  value: sleepHour,
                  onChanged: (v) => setState(() => sleepHour = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Prudenza delle uscite',
            child: DropdownButtonFormField<Prudence>(
              isExpanded: true,
              initialValue: prudence,
              decoration: const InputDecoration(
                helperText:
                    'Più prudenza = uscite anticipate. "Meno uscite" vale solo '
                    'per adulti sani: per cuccioli, anziani e cani malati $appName '
                    'usa comunque "Equilibrata".',
              ),
              items: [
                for (final x in Prudence.values)
                  DropdownMenuItem(value: x, child: Text(x.label)),
              ],
              onChanged: (v) => setState(() => prudence = v ?? prudence),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Promemoria pipì'),
            value: peeRem,
            onChanged: (v) => setState(() => peeRem = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Promemoria cacca'),
            value: poopRem,
            onChanged: (v) => setState(() => poopRem = v),
          ),
          LabeledField(
            label: 'Avvisami prima di',
            child: DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: lead,
              items: [
                for (final m in [0, 5, 10, 15, 20, 30])
                  DropdownMenuItem(value: m, child: Text('$m minuti')),
              ],
              onChanged: (v) => setState(() => lead = v ?? lead),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Avviso caldo con il meteo'),
            subtitle: const Text(
              'Usa le previsioni di Open-Meteo (gratuito, senza account): '
              'viene inviata solo la città.',
            ),
            value: heat,
            onChanged: (v) => setState(() => heat = v),
          ),
          if (heat)
            LabeledField(
              label: 'Città',
              child: TextField(controller: city),
            ),
          const SectionTitle('Dati sanitari'),
          LabeledField(
            label: 'Microchip',
            child: TextField(
              controller: chip,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                errorText: chipProblem,
                helperText: '15 cifre (in Italia inizia con 380)',
              ),
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Veterinario di fiducia',
            child: TextField(controller: vetName),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Telefono del veterinario',
            child: TextField(
              controller: vetPhone,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Pronto soccorso veterinario h24 di riferimento',
            child: TextField(
              controller: emergency,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                helperText: 'Lo trovi nella scheda Emergenze',
              ),
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Dove vive',
            child: DropdownButtonFormField<Region>(
              isExpanded: true,
              initialValue: region,
              decoration: const InputDecoration(
                helperText: 'Per la stagione di zanzare, pappataci e zecche',
              ),
              items: [
                for (final x in Region.values)
                  DropdownMenuItem(value: x, child: Text(x.label)),
              ],
              onChanged: (v) => setState(() => region = v ?? region),
            ),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Allergie e intolleranze',
            child: TextField(controller: allergies),
          ),
          const SizedBox(height: 12),
          LabeledField(
            label: 'Patologie note',
            child: TextField(
              controller: conditions,
              decoration: const InputDecoration(
                helperText: 'Es. diabete, Cushing, malattia renale, cistite: il modello ne tiene conto',
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Salva')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final kg = parseDogWeight(weight.text);
    if (name.text.trim().isEmpty || kg == null || birth == null) {
      toast(context, 'Servono almeno nome, data di nascita e peso');
      return;
    }
    final store = StoreScope.read(context);
    final dog =
        d ??
        Dog(
          id: newId(),
          name: '',
          birthDate: birth!,
          sex: sex,
          weightKg: kg,
          // Taglia del compagno coerente con il peso indicato.
          look: AvatarLook.forWeight(kg),
        );
    final weightChanged = d != null && (d!.weightKg - kg).abs() > 0.01;
    dog
      ..name = name.text.trim()
      ..breed = breed.text.trim()
      ..birthDate = birth!
      ..sex = sex
      ..neutered = neutered
      ..weightKg = kg
      ..activity = activity
      ..diet = diet
      ..reproState = sex == Sex.femmina ? repro : ReproState.nessuno
      ..reproSince = reproSince
      ..wakeHour = wakeHour
      ..sleepStartHour = sleepHour
      ..prudence = prudence
      ..pottyRemindersOn = peeRem
      ..poopRemindersOn = poopRem
      ..reminderLeadMinutes = lead
      ..microchip = chip.text.replaceAll(' ', '')
      ..vetName = vetName.text.trim()
      ..vetPhone = vetPhone.text.trim()
      ..allergies = allergies.text.trim()
      ..conditions = conditions.text.trim()
      ..region = region
      ..adultSize = adultSize
      ..emergencyPhone = emergency.text.trim()
      ..heatAlertsOn = heat
      ..photoId = photoId;
    if (heat && city.text.trim().isNotEmpty && city.text.trim() != dog.city) {
      try {
        final g = await Weather.geocode(city.text.trim());
        if (g != null) {
          dog
            ..city = g.name
            ..lat = g.lat
            ..lon = g.lon;
        } else if (mounted) {
          toast(context, 'Città non trovata: avviso caldo non attivo');
        }
      } catch (_) {
        if (mounted) toast(context, 'Meteo non raggiungibile ora');
      }
    }
    if (mounted) {
      await saveDogWithFirstDogPrompts(context, store, dog);
    } else {
      await store.upsertDog(dog);
    }
    if (weightChanged) await store.addWeight(dog.id, kg, DateTime.now());
    if (mounted) Navigator.pop(context);
  }
}

/// Etichetta sopra il campo, non dentro il bordo: va a capo con il testo al
/// 200% invece di essere troncata (ricerca/22 §8). MergeSemantics la lega al
/// campo, così il lettore di schermo la legge insieme al valore.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: t.textTheme.titleSmall?.copyWith(
                color: t.colorScheme.onSurface,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Peso scritto dall'utente, con la virgola o con il punto. Null se manca o
/// non è positivo: è la stessa regola per il modulo e la procedura guidata.
double? parseDogWeight(String text) {
  final kg = double.tryParse(text.replaceAll(',', '.'));
  return kg == null || kg <= 0 ? null : kg;
}

/// Data di nascita: mai nel futuro. Senza data, il calendario parte da tre
/// mesi fa (nessun valore viene però scelto al posto dell'utente).
Future<DateTime?> pickBirthDate(BuildContext context, DateTime? current) =>
    pickDate(
      context,
      current ?? DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );

/// Salva [dog] e, se è il primo cane vero, nell'ordine:
/// 1. propone di eliminare il cane di esempio, se c'è;
/// 2. chiede il permesso delle notifiche, spiegando perché.
/// Condivisa dal modulo completo e dalla procedura guidata.
Future<void> saveDogWithFirstDogPrompts(
  BuildContext context,
  AppStore store,
  Dog dog, {
  List<HealthRecord> records = const [],
}) async {
  // «Primo cane vero»: il cane di esempio non conta (CEO 11.4), altrimenti
  // chi prova l'esempio non riceverebbe mai la richiesta del permesso.
  final firstReal = !isDemoId(dog.id) && !store.hasRealDog;
  await store.upsertDog(dog);
  // Terapie indicate nella procedura guidata (ricerca/26 A6).
  for (final r in records) {
    await store.upsertRecord(r);
  }
  if (firstReal && store.demoDogs.isNotEmpty && context.mounted) {
    final names = store.demoDogs.map((d) => d.name).join(', ');
    final drop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare il cane di esempio?'),
        content: Text(
          '$names serviva solo per provare l\'app. Se lo elimini, restano '
          'solo i dati di ${dog.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tienilo'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina l\'esempio'),
          ),
        ],
      ),
    );
    if (drop == true) {
      await store.removeDemo();
      await store.selectDog(dog.id);
    }
  }
  if (firstReal &&
      Notifier.instance.supported &&
      Notifier.instance.allowed.value != true &&
      context.mounted) {
    // Permesso notifiche dopo il primo cane, spiegando perché (CEO C1-3).
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attivare le notifiche?'),
        content: Text(
          'Servono per avvisarti quando ${dog.name} deve uscire, quando è ora '
          'di una medicina o di un vaccino e, soprattutto, se qualcosa nei dati '
          'registrati richiede di sentire il veterinario. Puoi cambiarle quando vuoi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Non ora'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Attiva'),
          ),
        ],
      ),
    );
    if (go == true) {
      await Notifier.instance.requestPermissions();
      // Riprogramma le notifiche ora che sono permesse.
      await store.upsertDog(dog);
    }
  }
}

/// Peso in kg con l'etichetta sopra. L'unità è sempre visibile: con
/// «suffixText», che compare e scompare con il fuoco, MergeSemantics manda in
/// errore la semantica quando il campo cambia o sparisce.
class DogWeightField extends StatelessWidget {
  const DogWeightField({
    super.key,
    required this.controller,
    this.onChanged,
    this.errorText,
  });
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) => LabeledField(
    label: 'Peso *',
    child: TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      decoration: InputDecoration(
        suffixIcon: const ExcludeSemantics(
          child: Padding(
            padding: EdgeInsetsDirectional.only(end: 16),
            child: Text('kg'),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(),
        errorText: errorText,
      ),
    ),
  );
}

/// Ora intera (00:00-23:00) con l'etichetta sopra il campo.
class HourPicker extends StatelessWidget {
  const HourPicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => LabeledField(
    label: label,
    child: DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: value,
      items: [
        for (var h = 0; h < 24; h++)
          DropdownMenuItem(value: h, child: Text('${two(h)}:00')),
      ],
      onChanged: (v) => onChanged(v ?? value),
    ),
  );
}

/// Foto facoltativa del cane: anteprima rotonda, «Aggiungi», «Cambia» e
/// «Togli». Se la fotocamera non c'è, un avviso e nessun errore.
class DogPhotoField extends StatelessWidget {
  const DogPhotoField({
    super.key,
    required this.photoId,
    required this.onChanged,
  });
  final String? photoId;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context) async {
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
        maxWidth: 600,
        imageQuality: 70,
      );
      if (x == null) return;
      onChanged(await store.savePhoto(await x.readAsBytes()));
    } on PhotoSpaceFull catch (e) {
      if (context.mounted) toast(context, e.message);
    } catch (_) {
      if (context.mounted) {
        toast(context, 'Foto non disponibile su questo dispositivo');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bytes = photoId == null
        ? null
        : StoreScope.read(context).photo(photoId!);
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          image: true,
          label: bytes == null ? 'Nessuna foto' : 'Foto del cane',
          child: CircleAvatar(
            radius: 40,
            backgroundColor: t.colorScheme.secondaryContainer,
            foregroundImage: bytes == null ? null : MemoryImage(bytes),
            child: ExcludeSemantics(
              child: Icon(
                Icons.pets,
                size: 36,
                color: t.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          icon: Icon(
            bytes == null
                ? Icons.add_a_photo_outlined
                : Icons.photo_camera_outlined,
          ),
          label: Text(bytes == null ? 'Aggiungi una foto' : 'Cambia foto'),
          onPressed: () => _pick(context),
        ),
        if (bytes != null)
          TextButton(
            onPressed: () => onChanged(null),
            child: const Text('Togli la foto'),
          ),
      ],
    );
  }
}
