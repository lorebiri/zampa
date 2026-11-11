/// Pacchetti Paese (piano CEO 9.2 e 10.5): dati che valgono solo in un Paese
/// e che vanno riverificati a ogni rilascio pubblico e almeno ogni 6 mesi.
/// Un test fallisce se una verifica ha più di 6 mesi.
///
/// Centro antiveleni: lo presenta il testo EMG-019 del catalogo (variante
/// `cav = yes`), nella scheda Emergenze, con chiamata diretta.
class PoisonCentre {
  const PoisonCentre({
    required this.phone,
    required this.verifiedOn,
    required this.sources,
  });

  /// Numero come si legge; per chiamare si tolgono gli spazi.
  final String phone;

  /// Data dell'ultima verifica (AAAA-MM-GG).
  final String verifiedOn;

  /// Dove è stato verificato.
  final List<String> sources;

  DateTime get verifiedDate => DateTime.parse(verifiedOn);
}

/// Centri antiveleni verificati per gli animali, per Paese. Mai mostrare il
/// numero di un Paese a un cane di un altro Paese.
const poisonCentres = <String, PoisonCentre>{
  // CAV di Milano, Ospedale Niguarda: 24 ore su 24, risponde anche per gli
  // animali, da tutta Italia (ricerca/15 §2 e §3.1, piano CEO 10.5). Non si
  // dichiara che è gratuito: il sito non lo dice.
  'IT': PoisonCentre(
    phone: '02 6610 1029',
    verifiedOn: '2026-11-10',
    sources: ['centroantiveleni.org', 'ospedaleniguarda.it'],
  ),
};

/// Centro antiveleni del Paese, o null se non ce n'è uno verificato.
PoisonCentre? poisonCentreFor(String country) =>
    poisonCentres[country.toUpperCase()];
