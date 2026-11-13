// Screenshot della Home con un allarme SUBITO vero, in chiaro e in scuro,
// per docs/design/. Non fa parte della suite: si lancia a mano con
//   flutter test tool/screens/allarme_test.dart --update-goldens
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/common.dart';
import 'package:zampa/ui/home_screen.dart';
import 'package:zampa/ui/theme.dart';

Future<void> _fonts(WidgetTester tester) => tester.runAsync(() async {
  final atk = FontLoader(fontFamily);
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    atk.addFont(
      rootBundle.load('assets/fonts/AtkinsonHyperlegibleNext-$w.ttf'),
    );
  }
  await atk.load();
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final icons = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final l = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await l.load();
  }
});

void main() {
  for (final dark in [false, true]) {
    testWidgets('allarme ${dark ? 'scuro' : 'chiaro'}', (tester) async {
      await _fonts(tester);
      SharedPreferences.setMockInitialValues({});
      final s = AppStore(prefs: await SharedPreferences.getInstance());
      await s.load();
      await s.upsertDog(
        Dog(
          id: 'r1',
          name: 'Rocco',
          birthDate: DateTime(2019, 3, 1),
          sex: Sex.maschio,
          weightKg: 9,
        ),
      );
      await s.addLog(
        LogEntry(
          id: 'l1',
          dogId: 'r1',
          type: LogType.pipi,
          time: DateTime.now().subtract(const Duration(minutes: 20)),
          signs: {Sign.sforzo},
        ),
      );
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2;
      await tester.pumpWidget(
        StoreScope(
          store: s,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: buildTheme(dark ? Brightness.dark : Brightness.light),
            home: Scaffold(
              body: SafeArea(child: HomeScreen(onOpenTab: (_) {})),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('SUBITO'), findsWidgets);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../../docs/design/app-allarme-${dark ? 'scuro' : 'chiaro'}.png',
        ),
      );
      addTearDown(tester.view.reset);
    });
  }
}
