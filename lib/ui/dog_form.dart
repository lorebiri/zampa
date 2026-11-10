import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../logic/weather.dart';
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
  late DateTime birth =
      d?.birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 2));
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

  @override
  Widget build(BuildContext context) {
    final chipProblem = microchipProblem(chip.text);
    return Scaffold(
      appBar: AppBar(
        title: Text(d == null ? 'Nuovo cane' : 'Modifica ${d!.name}'),
      ),
      body: PageBody(
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Nome *'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: breed,
            decoration: const InputDecoration(labelText: 'Razza o tipo'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cake_outlined),
            title: Text('Nato il ${dmy(birth)}'),
            subtitle: const Text(
              'Se non la sai, una data approssimativa va bene',
            ),
            onTap: () async {
              final r = await pickDate(context, birth);
              if (r != null) setState(() => birth = r);
            },
          ),
          TextField(
            controller: weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso *',
              suffixText: 'kg',
            ),
          ),
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
          DropdownButtonFormField<AdultSize?>(
            initialValue: adultSize,
            decoration: const InputDecoration(
              labelText: 'Taglia adulta prevista',
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
          const SizedBox(height: 12),
          DropdownButtonFormField<ActivityLevel>(
            initialValue: activity,
            decoration: const InputDecoration(labelText: 'Livello di attività'),
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
          const SizedBox(height: 12),
          DropdownButtonFormField<DietType>(
            initialValue: diet,
            decoration: const InputDecoration(labelText: 'Alimentazione'),
            items: [
              for (final x in DietType.values)
                DropdownMenuItem(value: x, child: Text(x.label)),
            ],
            onChanged: (v) => setState(() => diet = v ?? diet),
          ),
          if (sex == Sex.femmina) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<ReproState>(
              initialValue: repro,
              decoration: const InputDecoration(
                labelText: 'Stato riproduttivo',
              ),
              items: [
                for (final x in ReproState.values)
                  DropdownMenuItem(value: x, child: Text(x.label)),
              ],
              onChanged: (v) => setState(() {
                repro = v ?? repro;
                reproSince ??= DateTime.now();
              }),
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
            children: [
              Expanded(
                child: _hourPicker(
                  'Si sveglia alle',
                  wakeHour,
                  (v) => setState(() => wakeHour = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _hourPicker(
                  'Dorme dalle',
                  sleepHour,
                  (v) => setState(() => sleepHour = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Prudence>(
            initialValue: prudence,
            decoration: const InputDecoration(
              labelText: 'Prudenza delle uscite',
              helperText:
                  'Più prudenza = uscite anticipate. "Meno uscite" vale solo '
                  'per adulti sani: per cuccioli, anziani e cani malati Zampa '
                  'usa comunque "Equilibrata".',
              helperMaxLines: 3,
            ),
            items: [
              for (final x in Prudence.values)
                DropdownMenuItem(value: x, child: Text(x.label)),
            ],
            onChanged: (v) => setState(() => prudence = v ?? prudence),
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
          DropdownButtonFormField<int>(
            initialValue: lead,
            decoration: const InputDecoration(labelText: 'Avvisami prima di'),
            items: [
              for (final m in [0, 5, 10, 15, 20, 30])
                DropdownMenuItem(value: m, child: Text('$m minuti')),
            ],
            onChanged: (v) => setState(() => lead = v ?? lead),
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
            TextField(
              controller: city,
              decoration: const InputDecoration(labelText: 'Città'),
            ),
          const SectionTitle('Dati sanitari'),
          TextField(
            controller: chip,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Microchip',
              errorText: chipProblem,
              helperText: '15 cifre (in Italia inizia con 380)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vetName,
            decoration: const InputDecoration(
              labelText: 'Veterinario di fiducia',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: vetPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefono del veterinario',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emergency,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Pronto soccorso veterinario h24 di riferimento',
              helperText: 'Lo trovi nella scheda Emergenze',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Region>(
            initialValue: region,
            decoration: const InputDecoration(
              labelText: 'Dove vive',
              helperText: 'Per la stagione di zanzare, pappataci e zecche',
            ),
            items: [
              for (final x in Region.values)
                DropdownMenuItem(value: x, child: Text(x.label)),
            ],
            onChanged: (v) => setState(() => region = v ?? region),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: allergies,
            decoration: const InputDecoration(
              labelText: 'Allergie e intolleranze',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: conditions,
            decoration: const InputDecoration(
              labelText: 'Patologie note',
              helperText: 'Es. diabete, Cushing, malattia renale, cistite: il modello ne tiene conto',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Salva')),
        ],
      ),
    );
  }

  Widget _hourPicker(String label, int value, ValueChanged<int> onChanged) =>
      DropdownButtonFormField<int>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (var h = 0; h < 24; h++)
            DropdownMenuItem(value: h, child: Text('${two(h)}:00')),
        ],
        onChanged: (v) => onChanged(v ?? value),
      );

  Future<void> _save() async {
    final kg = double.tryParse(weight.text.replaceAll(',', '.'));
    if (name.text.trim().isEmpty || kg == null || kg <= 0) {
      toast(context, 'Servono almeno nome e peso');
      return;
    }
    final store = StoreScope.read(context);
    final dog = d ?? Dog(id: newId(), name: '', birthDate: birth, sex: sex);
    final weightChanged = d != null && (d!.weightKg - kg).abs() > 0.01;
    dog
      ..name = name.text.trim()
      ..breed = breed.text.trim()
      ..birthDate = birth
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
      ..heatAlertsOn = heat;
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
    await store.upsertDog(dog);
    if (weightChanged) await store.addWeight(dog.id, kg, DateTime.now());
    if (mounted) Navigator.pop(context);
  }
}
