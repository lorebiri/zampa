import 'package:flutter/widgets.dart';

import '../brand.dart';
import 'app_localizations.dart';
import 'clinical_catalog.g.dart';

/// Lingua dei testi calcolati fuori dai widget (regole cliniche, notifiche,
/// PDF). Oggi l'app è solo in italiano; quando arriveranno altre lingue
/// basterà impostare qui il catalogo della lingua scelta.
class ClinicalL10n {
  static AppLocalizations current = lookupAppLocalizations(const Locale('it'));
}

/// Nome della voce nel file ARB: l'ID del catalogo in camelCase
/// (ALR-URI-001 → alrUri001, ALR-GI-007a → alrGi007a, SCA-BCS-1 → scaBcs1).
String catalogKey(String id) {
  final p = id.split('-');
  return p.first.toLowerCase() +
      p
          .skip(1)
          .map((x) => x[0].toUpperCase() + x.substring(1).toLowerCase())
          .join();
}

/// Un testo del catalogo clinico (docs/clinica/testi-clinici-v1.md),
/// indicato con il suo ID e i parametri da inserire. Il testo vero sta in
/// lib/l10n/app_it.arb: qui c'è solo il riferimento.
///
/// Parametri: valori già formattati come stringhe; le varianti di frase
/// sono scelte con parametri di tipo `select` (es. `'vomit': 'yes'`); i
/// conteggi dei plurali sono `int`.
class ClinicalText {
  const ClinicalText(this.id, [this.params = const {}]);

  final String id;
  final Map<String, Object> params;

  String get key => catalogKey(id);

  String get title => resolve('Title');
  String get text => resolve('Text');

  /// Frase d'azione specifica, se la voce ne ha una.
  String? get action =>
      catalogParams.containsKey('${key}Action') ? resolve('Action') : null;

  /// Il nome dell'app arriva sempre da brand.dart (unico punto da cambiare).
  String resolve(String part, [AppLocalizations? l]) => catalogLookup(
    l ?? ClinicalL10n.current,
    '$key$part',
    {'app': appName, ...params},
  );

  @override
  String toString() => 'ClinicalText($id, $params)';
}

/// Gli avvisi di alerts.dart usano lo stesso tipo.
typedef AlertText = ClinicalText;

/// Valore di un parametro `select` sì/no.
String yesNo(bool v) => v ? 'yes' : 'no';
