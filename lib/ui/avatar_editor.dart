import 'package:flutter/material.dart';

import '../models.dart';
import 'avatar.dart';
import 'common.dart';
import 'theme.dart';

/// Personalizzazione del compagno: razza di partenza, taglia, colori,
/// mantello, pelo, muso, orecchie, coda e accessorio, con anteprima dal vivo.
class AvatarEditorPage extends StatefulWidget {
  const AvatarEditorPage({super.key, required this.dog});
  final Dog dog;

  @override
  State<AvatarEditorPage> createState() => _AvatarEditorPageState();
}

class _AvatarEditorPageState extends State<AvatarEditorPage> {
  late AvatarLook look = widget.dog.look.copy();
  Pose preview = Pose.happy;

  static const coats = <(String, int)>[
    ('Crema', 0xFFF1DDB5),
    ('Fulvo', 0xFFC8955A),
    ('Rosso', 0xFFB4592C),
    ('Cioccolato', 0xFF6B3E26),
    ('Nero', 0xFF2D2726),
    ('Grigio', 0xFF8E8F94),
    ('Blu', 0xFF5E6B7D),
    ('Bianco', 0xFFF7F4EE),
    ('Tigrato', 0xFF7A5634),
    ('Oro', 0xFFE0B04F),
  ];
  static const collars = <int>[
    0xFFE0453A,
    0xFF2E7D6B,
    0xFF3B6FD6,
    0xFFF2C94C,
    0xFF9B59B6,
    0xFF222222,
    0xFFE76F8A,
  ];

  String _pattern(CoatPattern p) => switch (p) {
    CoatPattern.tinta => 'Tinta unita',
    CoatPattern.focature => 'Focature (zampe e muso)',
    CoatPattern.pettoBianco => 'Petto e muso chiari',
    CoatPattern.macchie => 'Macchie',
    CoatPattern.pezzato => 'Pezzato',
    CoatPattern.maschera => 'Maschera scura',
  };

  /// Campione di colore: bersaglio da 48 dp, con nome e stato per i
  /// lettori di schermo.
  Widget swatch(int c, bool selected, VoidCallback onTap, {String? tip}) {
    final s = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: tip ?? 'Colore',
      child: Tooltip(
        message: tip ?? '',
        excludeFromSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.chip),
              border: Border.all(
                color: selected ? s.primary : Colors.transparent,
                width: 3,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Color(c),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: s.outline.withValues(alpha: 0.5)),
              ),
              child: selected
                  ? Icon(
                      Icons.check,
                      size: 20,
                      color: Color(c).computeLuminance() > 0.4
                          ? Colors.black87
                          : Colors.white,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  /// Scelta fra poche opzioni: chip che vanno a capo (testo grande ok).
  Widget _chips<T>(
    List<T> values,
    T selected,
    Map<T, String> labels,
    void Function(T) set,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final v in values)
        ChoiceChip(
          label: Text(labels[v]!),
          selected: v == selected,
          onSelected: (_) => setState(() => set(v)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('L\'aspetto di ${widget.dog.name}')),
      body: PageBody(
        children: [
          CompanionDevice(
            child: ExcludeSemantics(
              child: PixelDogView(look: look, pose: preview, height: 200),
            ),
          ),
          const SizedBox(height: Space.m),
          SegmentedButton<Pose>(
            segments: const [
              ButtonSegment(value: Pose.happy, label: Text('Felice')),
              ButtonSegment(value: Pose.idle, label: Text('Calmo')),
              ButtonSegment(value: Pose.sleeping, label: Text('Dorme')),
            ],
            selected: {preview},
            onSelectionChanged: (s) => setState(() => preview = s.first),
          ),
          const SectionTitle('Parti da una razza'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in BreedPreset.all)
                ActionChip(
                  label: Text(b.name),
                  onPressed: () => setState(() {
                    final keep = look.collar;
                    look = b.build();
                    if (b.build().accessory != Accessory.fiocco) {
                      look.collar = keep;
                    }
                  }),
                ),
            ],
          ),
          const SectionTitle('Taglia'),
          SegmentedButton<DogSize>(
            segments: const [
              ButtonSegment(value: DogSize.piccola, label: Text('Piccola')),
              ButtonSegment(value: DogSize.media, label: Text('Media')),
              ButtonSegment(value: DogSize.grande, label: Text('Grande')),
            ],
            selected: {look.size},
            onSelectionChanged: (s) => setState(() => look.size = s.first),
          ),
          const SectionTitle('Colore principale'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (n, c) in coats)
                swatch(
                  c,
                  look.coat == c,
                  () => setState(() => look.coat = c),
                  tip: n,
                ),
            ],
          ),
          const SectionTitle('Colore secondario'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (n, c) in coats)
                swatch(
                  c,
                  look.coat2 == c,
                  () => setState(() => look.coat2 = c),
                  tip: n,
                ),
            ],
          ),
          const SectionTitle('Mantello'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in CoatPattern.values)
                ChoiceChip(
                  label: Text(_pattern(p)),
                  selected: look.pattern == p,
                  onSelected: (_) => setState(() => look.pattern = p),
                ),
            ],
          ),
          const SectionTitle('Pelo'),
          _chips<CoatType>(CoatType.values, look.coatType, {
            CoatType.raso: 'Raso',
            CoatType.lungo: 'Lungo',
            CoatType.riccio: 'Riccio',
            CoatType.fiocchi: 'A fiocchi',
          }, (v) => look.coatType = v),
          const SectionTitle('Muso'),
          _chips<MuzzleType>(MuzzleType.values, look.muzzle, {
            MuzzleType.corto: 'Corto',
            MuzzleType.medio: 'Medio',
            MuzzleType.lungo: 'Lungo',
          }, (v) => look.muzzle = v),
          const SectionTitle('Orecchie'),
          _chips<EarType>(EarType.values, look.ears, {
            EarType.dritte: 'Dritte',
            EarType.semi: 'Semierette',
            EarType.pendenti: 'Cadenti',
            EarType.lunghe: 'Lunghe e pelose',
          }, (v) => look.ears = v),
          const SectionTitle('Coda'),
          SegmentedButton<TailType>(
            segments: const [
              ButtonSegment(value: TailType.lunga, label: Text('Lunga')),
              ButtonSegment(
                value: TailType.arricciata,
                label: Text('Arricciata'),
              ),
              ButtonSegment(value: TailType.corta, label: Text('Corta')),
            ],
            selected: {look.tail},
            onSelectionChanged: (s) => setState(() => look.tail = s.first),
          ),
          const SectionTitle('Accessorio'),
          _chips<Accessory>(Accessory.values, look.accessory, {
            Accessory.collare: 'Collare',
            Accessory.fiocco: 'Fiocco',
            Accessory.bandana: 'Bandana',
            Accessory.nessuno: 'Nessuno',
          }, (v) => look.accessory = v),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in collars)
                swatch(
                  c,
                  look.collar == c,
                  () => setState(() => look.collar = c),
                  tip: 'Colore dell\'accessorio',
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              widget.dog.look = look;
              await StoreScope.read(context).upsertDog(widget.dog);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salva'),
          ),
          const SizedBox(height: 8),
          Text(
            'Tocca il cane per farlo scodinzolare. Il suo umore segue i dati veri: dorme negli orari '
            'di sonno, aspetta la porta quando si avvicina l\'uscita, è contento dopo una passeggiata.',
            style: t.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
