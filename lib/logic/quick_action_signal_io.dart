import 'dart:isolate';
import 'dart:ui' show IsolateNameServer;

const _name = 'lulu_quick_actions';
ReceivePort? _port;

/// L'app aperta si mette in ascolto (una porta sola, sostituita se si
/// richiama).
void listenQuickActionSignal(void Function() onSignal) {
  IsolateNameServer.removePortNameMapping(_name);
  _port?.close();
  final p = ReceivePort()..listen((_) => onSignal());
  _port = p;
  IsolateNameServer.registerPortWithName(p.sendPort, _name);
}

/// Dall'isolato in background: true se l'app era aperta e ha ricevuto
/// l'avviso; false se è chiusa (l'azione resta in coda per l'avvio).
bool sendQuickActionSignal() {
  final p = IsolateNameServer.lookupPortByName(_name);
  if (p == null) return false;
  p.send(1);
  return true;
}
