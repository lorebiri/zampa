import 'package:flutter/material.dart';

import '../logic/nutrition.dart';
import '../models.dart';
import 'common.dart';
import 'theme.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final dog = store.dog!;
    final now = DateTime.now();
    final plan = Nutrition.plan(dog, now);
    final t = Theme.of(context);
    final today = store.logsOf(dog.id).where((l) {
      return l.time.year == now.year &&
          l.time.month == now.month &&
          l.time.day == now.day;
    });
    final waterToday = today
        .where((l) => l.type == LogType.acqua && l.amountMl != null)
        .fold<double>(0, (a, l) => a + l.amountMl!);
    final mealsToday = today.where((l) => l.type == LogType.pasto).length;

    return PageBody(
      children: [
        PageTitle('Nutrizione di ${dog.name}'),
        Card(
          color: t.colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.hero),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${plan.kcalPerDay.round()} kcal al giorno',
                  style: t.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: t.colorScheme.onPrimaryContainer,
                  ),
                ),
                if (plan.freeFeeding)
                  Text(
                    'Cibo a disposizione (niente razione fissa)',
                    style: t.textTheme.titleMedium?.copyWith(
                      color: t.colorScheme.onPrimaryContainer,
                    ),
                  )
                else if (plan.gramsPerDay > 0)
                  Text(
                    '≈ ${plan.gramsPerDay.round()} g di ${dog.foodName.isEmpty ? 'cibo' : dog.foodName} '
                    '(${plan.meals} pasti da ${plan.gramsPerMeal.round()} g)',
                    style: t.textTheme.titleMedium?.copyWith(
                      color: t.colorScheme.onPrimaryContainer,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Fabbisogno a riposo (RER) ${plan.rer.round()} kcal × ${plan.factor.toStringAsFixed(1)} '
                  '(${plan.factorReason}), sul peso di ${plan.weightBasisKg.toStringAsFixed(1)} kg.',
                  style: TextStyle(color: t.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  'Snack e premi: non oltre il 10% delle calorie (≈ ${(plan.kcalPerDay * 0.1).round()} kcal). '
                  'Ricontrolla il peso ogni 2-4 settimane e adatta la razione.',
                  style: t.textTheme.bodySmall?.copyWith(
                    color: t.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final n in plan.notes) NoticeCard(n),
        const SectionTitle('Oggi'),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _Stat(
                  label: 'Pasti registrati',
                  value: '$mealsToday / ${plan.meals}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(
                  label: 'Acqua registrata',
                  value: '${waterToday.round()} ml',
                  hint:
                      'Riferimento ${plan.waterMlMin.round()}-${plan.waterMlMax.round()} ml (inclusa l\'acqua del cibo)',
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Forma fisica (Body Condition Score)'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  value: dog.bodyCondition.toDouble(),
                  min: 1,
                  max: 9,
                  divisions: 8,
                  label: '${dog.bodyCondition}',
                  onChanged: (v) {
                    dog.bodyCondition = v.round();
                    store.upsertDog(dog);
                  },
                ),
                Text(
                  '${dog.bodyCondition}/9 – ${Nutrition.bcsDescriptions[dog.bodyCondition]}',
                ),
                const SizedBox(height: 6),
                Text(
                  'Peso ideale stimato: ${plan.idealWeightKg.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (dog.bodyCondition >= 7)
                  const Text(
                    'Obiettivo: perdere l\'1-2% del peso a settimana, con il controllo del veterinario.',
                  ),
              ],
            ),
          ),
        ),
        const SectionTitle('Alimento'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _FoodForm(dog: dog),
          ),
        ),
        const SectionTitle('Alimenti e sostanze pericolose'),
        Card(
          child: Column(
            children: [
              for (final f in Nutrition.toxicFoods)
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.dangerous_outlined,
                    color: f.severity == 'grave'
                        ? t.colorScheme.error
                        : t.colorScheme.tertiary,
                  ),
                  title: Text(f.food),
                  subtitle: Text('${f.danger} · rischio ${f.severity}'),
                ),
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Se ne ha mangiato: contatta subito il veterinario o un centro antiveleni, anche se sta bene. '
                  'Non provocare il vomito di tua iniziativa (niente sale, acqua ossigenata o dita in gola) '
                  'se non te lo dice il veterinario. Porta con te la confezione o una foto dell\'etichetta.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Calcoli secondo NRC 2006 e linee guida WSAVA/FEDIAF. Sono stime di partenza: '
          'il fabbisogno reale varia fino al ±20% tra cani simili.',
          style: t.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.hint});
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.textTheme.labelMedium),
            Text(
              value,
              style: t.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (hint != null) Text(hint!, style: t.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _FoodForm extends StatefulWidget {
  const _FoodForm({required this.dog});
  final Dog dog;
  @override
  State<_FoodForm> createState() => _FoodFormState();
}

class _FoodFormState extends State<_FoodForm> {
  late final name = TextEditingController(text: widget.dog.foodName);
  late final kcal = TextEditingController(
    text: widget.dog.foodKcalPer100g.toStringAsFixed(0),
  );

  @override
  Widget build(BuildContext context) {
    final d = widget.dog;
    final store = StoreScope.read(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Nome dell\'alimento'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: kcal,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Energia (kcal per 100 g)',
            helperText: 'In etichetta come "energia metabolizzabile". Crocchette ~330-420, umido ~70-120.',
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<DietType>(
          initialValue: d.diet,
          decoration: const InputDecoration(labelText: 'Tipo di dieta'),
          items: [
            for (final x in DietType.values)
              DropdownMenuItem(value: x, child: Text(x.label)),
          ],
          onChanged: (v) => d.diet = v ?? d.diet,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: d.mealsPerDay.clamp(0, 5),
          decoration: const InputDecoration(labelText: 'Pasti al giorno'),
          items: [
            DropdownMenuItem(
              value: 0,
              child: Text('Automatico per età (${Nutrition.mealsFor(d)})'),
            ),
            for (var i = 1; i <= 5; i++)
              DropdownMenuItem(value: i, child: Text('$i')),
          ],
          onChanged: (v) => d.mealsPerDay = v ?? d.mealsPerDay,
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () async {
            d.foodName = name.text.trim();
            d.foodKcalPer100g =
                double.tryParse(kcal.text.replaceAll(',', '.')) ??
                d.foodKcalPer100g;
            await store.upsertDog(d);
            if (context.mounted) toast(context, 'Alimento aggiornato');
          },
          child: const Text('Aggiorna razione'),
        ),
      ],
    );
  }
}
