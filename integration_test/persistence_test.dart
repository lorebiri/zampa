import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/main.dart';
import 'package:zampa/models.dart';
import 'package:zampa/notifications.dart';
import 'package:zampa/store.dart';

/// Persistenza (C2-1, rapporto 10): da eseguire dopo `device_test.dart`,
/// con l'app chiusa in mezzo (`simctl terminate`). Non cancella nulla:
/// controlla che il cane, i diari, la terapia e la foto siano ancora lì e che
/// all'avvio le notifiche vengano riprogrammate.
void log(String s) {
  // ignore: avoid_print
  print(s);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('i dati sopravvivono alla chiusura dell\'app', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await Notifier.instance.init();
    final before = await Notifier.instance.pending();
    log('NOTIFICHE IN ATTESA ALL\'AVVIO (prima del load): ${before.length}');
    final store = AppStore(prefs: prefs, notifier: Notifier.instance);
    await store.load();
    await tester.pumpWidget(ZampaApp(store: store));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    log('TERMINI ACCETTATI: ${store.termsAccepted}');
    log('CANI: ${store.dogs.map((d) => d.name).join(', ')}');
    log('DIARIO: ${store.logs.length} voci; '
        'CARTELLA: ${store.records.length} voci');
    final photos = store.logs.where((l) => l.photoId != null).toList();
    final photoOk =
        photos.isNotEmpty && (store.photo(photos.first.photoId!)?.length ?? 0) > 0;
    log('FOTO NEL DIARIO: ${photos.length}, leggibile: $photoOk');
    final after = await Notifier.instance.pending();
    log('NOTIFICHE IN ATTESA DOPO IL LOAD: ${after.length}');

    expect(store.termsAccepted, isTrue);
    expect(store.dogs.map((d) => d.name), contains('Birba'));
    final birba = store.dogs.firstWhere((d) => d.name == 'Birba');
    expect(birba.vetPhone, isNotEmpty);
    expect(store.logs.any((l) => l.type == LogType.pipi), isTrue);
    expect(
      store.records.any((r) => r.title == 'Antibiotico di prova'),
      isTrue,
    );
    expect(find.text('Birba'), findsWidgets);
    expect(after, isNotEmpty);
  });
}
