/// Avviso «c'è un'azione nuova in coda» dall'isolato in background (bottone
/// della notifica su Android) all'app aperta, nello stesso processo.
/// Sul web `dart:isolate` non esiste: lì non fa nulla (e non serve, perché
/// sul web non ci sono azioni nelle notifiche).
library;

export 'quick_action_signal_stub.dart'
    if (dart.library.isolate) 'quick_action_signal_io.dart';
