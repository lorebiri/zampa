import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zampa/logic/alerts.dart';
import 'package:zampa/logic/modules.dart';
import 'package:zampa/logic/seasonal.dart';
import 'package:zampa/models.dart';
import 'package:zampa/store.dart';
import 'package:zampa/ui/avatar.dart';
import 'package:zampa/ui/pdf_export.dart';

final now = DateTime(2026, 11, 10, 15);

Dog _dog({
  Sex sex = Sex.maschio,
  bool neutered = true,
  String breed = '',
  String cond = '',
}) => Dog(
  id: 'd',
  name: 'Fido',
  birthDate: DateTime(2022, 1, 1),
  sex: sex,
  neutered: neutered,
  weightKg: 20,
  breed: breed,
  conditions: cond,
);

LogEntry e(
  LogType t,
  Duration ago, {
  Set<Sign> signs = const {},
  double? value,
  String note = '',
}) => LogEntry(
  id: '$t$ago',
  dogId: 'd',
  type: t,
  time: now.subtract(ago),
  signs: signs,
  value: value,
  note: note,
);

List<HealthAlert> run(
  List<LogEntry> logs, {
  Dog? dog,
  List<HealthRecord> records = const [],
  List<ReproEvent> repro = const [],
  List<({HealthRecord record, DateTime at})> pending = const [],
}) => AlertEngine.compute(
  dog: dog ?? _dog(),
  logs: logs,
  records: records,
  weights: const [],
  now: now,
  repro: repro,
  pendingDoses: pending,
);

void main() {
  // Il PDF carica Atkinson dagli asset (C2-9).
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Nuovi segni (revisione veterinaria)', () {
    test('ha ingerito qualcosa → subito', () {
      expect(
        run([
          e(
            LogType.ingestione,
            const Duration(minutes: 10),
            note: 'cioccolato',
          ),
        ]).first.level,
        AlertLevel.subito,
      );
    });
    test(
      'respiri > 40 con fatica a respirare → subito; due misure > 30 → oggi',
      () {
        expect(
          run([
            e(LogType.respiro, const Duration(hours: 1), value: 44),
            e(LogType.tosse, const Duration(hours: 1), signs: {Sign.dispnea}),
          ]).first.level,
          AlertLevel.subito,
        );
        final a = run([
          e(LogType.respiro, const Duration(hours: 5), value: 34),
          e(LogType.respiro, const Duration(hours: 1), value: 33),
        ]);
        expect(a.first.level, AlertLevel.oggi);
      },
    );
    test('gengive pallide → subito', () {
      expect(
        run([
          e(
            LogType.gengive,
            const Duration(minutes: 5),
            signs: {Sign.gengivePallide},
          ),
        ]).first.level,
        AlertLevel.subito,
      );
    });
    test('febbre 39,8 → oggi; 41,2 → subito', () {
      expect(
        run([e(LogType.temperatura, const Duration(minutes: 5), value: 39.8)])
            .first
            .level,
        AlertLevel.oggi,
      );
      expect(
        run([e(LogType.temperatura, const Duration(minutes: 5), value: 41.2)])
            .first
            .level,
        AlertLevel.subito,
      );
    });
    test('convulsione di 6 minuti → subito; prima crisi breve → oggi', () {
      expect(
        run([e(LogType.convulsione, const Duration(hours: 1), value: 6)])
            .first
            .level,
        AlertLevel.subito,
      );
      expect(
        run([e(LogType.convulsione, const Duration(hours: 1), value: 1)])
            .first
            .level,
        AlertLevel.oggi,
      );
    });
    test('diabetico con tremori → subito (ipoglicemia)', () {
      final a = run([
        e(LogType.neuro, const Duration(minutes: 20)),
      ], dog: _dog(cond: 'diabete mellito'));
      expect(a.first.title, contains('ipoglicemia'));
      expect(a.first.level, AlertLevel.subito);
    });
    test('non appoggia la zampa → oggi', () {
      expect(
        run([
          e(LogType.zoppia, const Duration(hours: 2), signs: {Sign.nonCarica}),
        ]).first.level,
        AlertLevel.oggi,
      );
    });
    test('perdite a riposo → attenzione con "Non ridurre l\'acqua"', () {
      final a = run([e(LogType.perditaRiposo, const Duration(hours: 2))]);
      expect(a.any((x) => x.message.contains('Non ridurre l\'acqua')), isTrue);
    });
    test('dose non confermata da 3 ore → attenzione', () {
      final r = HealthRecord(
        id: 'r',
        dogId: 'd',
        type: RecordType.farmaco,
        title: 'Fenobarbital',
        date: now.subtract(const Duration(days: 3)),
        everyHours: 12,
      );
      final a = run(
        [],
        pending: [(record: r, at: now.subtract(const Duration(hours: 3)))],
      );
      expect(a.any((x) => x.title.startsWith('Dose non confermata')), isTrue);
    });
    test('piometra con perdite vulvari dopo il calore (da storico)', () {
      final d = _dog(sex: Sex.femmina, neutered: false);
      final a = run(
        [e(LogType.perditeVulvari, const Duration(hours: 5))],
        dog: d,
        repro: [
          ReproEvent(
            id: 'h',
            dogId: 'd',
            type: ReproEventType.calore,
            date: now.subtract(const Duration(days: 35)),
          ),
        ],
      );
      expect(
        a.any(
          (x) => x.title.contains('piometra') && x.level == AlertLevel.oggi,
        ),
        isTrue,
      );
    });
  });

  group('Moduli', () {
    test('data presunta del parto = accoppiamento + 63 giorni', () {
      final d = _dog(sex: Sex.femmina, neutered: false);
      final m = now.subtract(const Duration(days: 20));
      final due = Modules.dueDate(d, [
        ReproEvent(
          id: 'a',
          dogId: 'd',
          type: ReproEventType.accoppiamento,
          date: m,
        ),
      ], now);
      expect(due, m.add(const Duration(days: 63)));
    });
    test('detrazione spese veterinarie: 19% oltre 129,11 € fino a 550 €', () {
      final r = [
        HealthRecord(
          id: '1',
          dogId: 'd',
          type: RecordType.visita,
          title: 'v',
          date: DateTime(2026, 3, 1),
          cost: 400,
        ),
        HealthRecord(
          id: '2',
          dogId: 'd',
          type: RecordType.visita,
          title: 'v',
          date: DateTime(2026, 6, 1),
          cost: 300,
        ),
      ];
      final x = Modules.expenses(r, 2026);
      expect(x.total, 700);
      expect(x.deductible, closeTo(550 - 129.11, 0.01));
      expect(x.refund, closeTo((550 - 129.11) * 0.19, 0.01));
    });
    test('predisposizioni di razza', () {
      expect(
        Breeds.predispositions(_dog(breed: 'Border Collie'))
            .any((t) => t.title.contains('MDR1')),
        isTrue,
      );
      expect(Breeds.isBrachy('Bulldog francese'), isTrue);
    });
    test('consigli stagionali: processionaria a marzo, botti a Capodanno', () {
      expect(
        SeasonalTips.forDog(
          _dog(),
          DateTime(2026, 3, 10),
        ).any((t) => t.title.contains('processionaria')),
        isTrue,
      );
      expect(
        SeasonalTips.forDog(
          _dog(),
          DateTime(2026, 12, 30),
        ).any((t) => t.title.contains('Capodanno')),
        isTrue,
      );
    });
  });

  test('il compagno in pixel art si disegna con ogni combinazione', () {
    for (final size in DogSize.values) {
      for (final pat in CoatPattern.values) {
        for (final ears in EarType.values) {
          for (final tail in TailType.values) {
            for (final pose in Pose.values) {
              final g = PixelDog.render(
                AvatarLook(
                  size: size,
                  pattern: pat,
                  ears: ears,
                  tail: tail,
                  longHair: pat.index.isEven,
                ),
                pose,
                3,
              );
              final filled = g.expand((r) => r).where((c) => c != null).length;
              expect(
                filled,
                greaterThan(80),
                reason: '$size $pat $ears $tail $pose',
              );
            }
          }
        }
      }
    }
  });

  test('PDF per il veterinario con il cane di esempio', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(prefs: await SharedPreferences.getInstance());
    await s.load();
    await s.loadDemo();
    final bytes = await buildPdf(s, s.dog!, DateTime.now());
    expect(bytes.length, greaterThan(2000));
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}
