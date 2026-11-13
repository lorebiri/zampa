// ignore_for_file: invalid_use_of_visible_for_testing_member
// Anteprima del compagno tamagotchi: 3 cani personalizzati per 6 stati
// d'animo, con il disegnatore vero dell'app (lib/ui/avatar.dart).
//   flutter test tool/screens/tamagotchi_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zampa/brand.dart';
import 'package:zampa/models.dart';
import 'package:zampa/ui/avatar.dart';
import 'package:zampa/ui/theme.dart';

final _cani = <(String, AvatarLook)>[
  ('$mascotName · bolognese (predefinito)', AvatarLook.lulu()),
  (
    'Birba · pinscher nero focato',
    AvatarLook(
      size: DogSize.piccola,
      coat: 0xFF2B2422,
      coat2: 0xFFB8743A,
      pattern: CoatPattern.focature,
      ears: EarType.dritte,
      tail: TailType.corta,
      collar: 0xFF7A5AD1,
    ),
  ),
  (
    'Rocco · labrador miele',
    AvatarLook(
      size: DogSize.grande,
      coat: 0xFFD9A55B,
      coat2: 0xFFF1D6A6,
      pattern: CoatPattern.tinta,
      ears: EarType.pendenti,
      tail: TailType.lunga,
      collar: 0xFF2E7D4F,
    ),
  ),
];

const _stati = <(Pose, String, String, IconData)>[
  (Pose.happy, 'Felice', 'fatto tutto di oggi', Icons.favorite),
  (Pose.idle, 'Sereno', 'scodinzola, scadenza in vista', Icons.event_available),
  (
    Pose.waiting,
    'Impaziente',
    'alla porta: pipì vicina',
    Icons.door_front_door,
  ),
  (Pose.hungry, 'Affamato', 'vicino all\'ora della pappa', Icons.rice_bowl),
  (Pose.sleeping, 'Assonnato', 'di notte, come i suoi orari', Icons.bedtime),
  (
    Pose.concerned,
    'Preoccupato',
    'allarme: senti il veterinario',
    Icons.medical_services,
  ),
];

Future<void> _fonts(WidgetTester tester) => tester.runAsync(() async {
  final atk = FontLoader(fontFamily);
  for (final w in ['Regular', 'Bold', 'ExtraBold']) {
    atk.addFont(
      rootBundle.load('assets/fonts/AtkinsonHyperlegibleNext-$w.ttf'),
    );
  }
  await atk.load();
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/user/flutter';
  final f = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (f.existsSync()) {
    final l = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(f.readAsBytesSync().buffer)));
    await l.load();
  }
});

void main() {
  testWidgets('anteprima tamagotchi', (tester) async {
    await _fonts(tester);
    tester.view.physicalSize = const Size(2400, 1180);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final theme = buildTheme(Brightness.light);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Il compagno tamagotchi di $appName: 3 cani personalizzati, 6 stati d\'animo',
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  'Ogni stato ha posa, espressione, coda e un oggetto di contesto; sotto, i 4 fotogrammi '
                  'dell\'animazione di Lulù (ferma con «riduci movimento»).',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(width: 250),
                    for (final s in _stati)
                      SizedBox(
                        width: 340,
                        child: Column(
                          children: [
                            Text(s.$2, style: theme.textTheme.titleLarge),
                            Text(s.$3, style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ),
                  ],
                ),
                for (final c in _cani)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 250,
                          child: Text(c.$1, style: theme.textTheme.titleMedium),
                        ),
                        for (final s in _stati)
                          SizedBox(
                            width: 340,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: CompanionDevice(
                                night: s.$1 == Pose.sleeping,
                                child: PixelDogView(
                                  look: c.$2,
                                  pose: s.$1,
                                  night: s.$1 == Pose.sleeping,
                                  height: 150,
                                  frame: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 250,
                        child: Text(
                          'Animazione (4 fotogrammi)',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      for (final s in _stati)
                        SizedBox(
                          width: 340,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var f = 0; f < 4; f++)
                                Container(
                                  width: 80,
                                  height: 84,
                                  margin: const EdgeInsets.all(2),
                                  color: s.$1 == Pose.sleeping
                                      ? const Color(0xFF1E2A44)
                                      : const Color(0xFFDCE9C9),
                                  child: PixelDogView(
                                    look: _cani.first.$2,
                                    pose: s.$1,
                                    night: s.$1 == Pose.sleeping,
                                    height: 80,
                                    frame: f,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/design/tamagotchi-anteprima.png'),
    );
  });
}
