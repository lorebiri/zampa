import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// I due consensi facoltativi di `docs/CONSENSO-TELEMETRIA.md`.
enum ConsentKind {
  /// Studio sull'accuratezza (telemetria, `ricerca/12` §5).
  study,

  /// Rapporti di errore (Sentry, `docs/CRASH-STRUMENTO.md`).
  crashReports,
}

/// Ultima scelta dell'utente su un consenso, con la prova richiesta
/// dall'art. 7.1 GDPR: data e ora, versione del testo mostrato.
@immutable
class ConsentChoice {
  const ConsentChoice({
    required this.granted,
    required this.at,
    required this.version,
  });

  final bool granted;
  final DateTime at;
  final String version;

  Map<String, Object?> toJson() => {
    'granted': granted,
    'at': at.toIso8601String(),
    'version': version,
  };

  static ConsentChoice? tryParse(String? raw) {
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      return ConsentChoice(
        granted: j['granted'] == true,
        at: DateTime.parse(j['at']! as String),
        version: j['version']! as String,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Punto unico per i consensi facoltativi (R-P1, R-P3 di `ricerca/24`).
///
/// **Il futuro codice di telemetria e di Sentry deve leggere solo da qui**
/// ([allowed]) e deve:
/// - partire solo se `allowed(...)` è vero, e fermarsi appena diventa falso
///   (ascoltare questo oggetto, che è un [ChangeNotifier]);
/// - non inviare mai nulla per il cane di esempio (`isDemoId`) né dalle build
///   di sviluppo;
/// - al ritiro dello studio, chiedere la cancellazione per il `pid` e
///   dimenticare il codice.
///
/// Se cambia cosa si invia, cambia prima il testo in
/// `docs/CONSENSO-TELEMETRIA.md`, poi la costante di versione qui sotto: le
/// scelte salvate con una versione diversa non valgono più e l'interruttore
/// torna spento.
class ConsentStore extends ChangeNotifier {
  ConsentStore({SharedPreferences? prefs})
    : _prefs = prefs; // ignore: prefer_initializing_formals

  /// Istanza dell'app (caricata in `main`).
  static final instance = ConsentStore();

  /// Versione del testo dello studio (`consentVersion`).
  static const studyVersion = 'tele-2026-11';

  /// Versione del testo dei rapporti di errore.
  static const crashReportsVersion = 'errori-2026-11';

  /// Versione della frase sull'età nelle condizioni d'uso.
  static const ageVersion = 'eta14-2026-11';

  static const _ageKey = 'zampa_age_ok_v1';
  static String _key(ConsentKind k) => 'zampa_consent_${k.name}_v1';

  SharedPreferences? _prefs;
  final _choices = <ConsentKind, ConsentChoice>{};
  ConsentChoice? _age;

  static String versionOf(ConsentKind k) => switch (k) {
    ConsentKind.study => studyVersion,
    ConsentKind.crashReports => crashReportsVersion,
  };

  Future<SharedPreferences> _p() async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> load() async {
    final p = await _p();
    for (final k in ConsentKind.values) {
      final c = ConsentChoice.tryParse(p.getString(_key(k)));
      if (c == null) {
        _choices.remove(k);
      } else {
        _choices[k] = c;
      }
    }
    _age = ConsentChoice.tryParse(p.getString(_ageKey));
    notifyListeners();
  }

  /// Ultima scelta salvata (anche un "no" o una versione vecchia).
  ConsentChoice? choice(ConsentKind k) => _choices[k];

  /// Vero solo con un "sì" dato sul testo in vigore. Spento di serie.
  bool allowed(ConsentKind k) {
    final c = _choices[k];
    return c != null && c.granted && c.version == versionOf(k);
  }

  Future<void> set(ConsentKind k, bool granted, {DateTime? now}) async {
    final c = ConsentChoice(
      granted: granted,
      at: now ?? DateTime.now(),
      version: versionOf(k),
    );
    _choices[k] = c;
    notifyListeners();
    await (await _p()).setString(_key(k), jsonEncode(c.toJson()));
  }

  /// L'utente ha dichiarato di avere almeno 14 anni, o che un genitore è
  /// d'accordo (art. 8 GDPR, art. 2-quinquies Codice privacy).
  bool get ageConfirmed => _age?.granted == true;

  Future<void> confirmAge({DateTime? now}) async {
    _age = ConsentChoice(
      granted: true,
      at: now ?? DateTime.now(),
      version: ageVersion,
    );
    notifyListeners();
    await (await _p()).setString(_ageKey, jsonEncode(_age!.toJson()));
  }
}
