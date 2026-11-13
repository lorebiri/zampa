import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../brand.dart';
import '../consent.dart';
import '../store.dart';
import 'common.dart';
import 'theme.dart';

/// Testi completi inclusi nell'app (vedi `flutter: assets:` in pubspec).
const privacyAsset = 'docs/PRIVACY.md';
const consentAsset = 'docs/CONSENSO-TELEMETRIA.md';

/// Condivide il backup come file. Sostituibile nei test.
typedef BackupSharer = Future<void> Function(
  String json,
  String fileName,
  Rect? origin,
);

/// Backup come file con il foglio di condivisione, non negli appunti
/// (R-P5 di `ricerca/24`, DPIA R8): l'utente sceglie dove salvarlo.
Future<void> shareBackupFile(String json, String fileName, Rect? origin) async {
  await SharePlus.instance.share(
    ShareParams(
      files: [
        XFile.fromData(
          Uint8List.fromList(utf8.encode(json)),
          mimeType: 'application/json',
          name: fileName,
        ),
      ],
      fileNameOverrides: [fileName],
      subject: 'Backup di $appName',
      sharePositionOrigin: origin,
      excludedCupertinoActivities: const [
        CupertinoActivityType.copyToPasteboard,
      ],
    ),
  );
}

String backupFileName(DateTime d) =>
    '${appFileName.toLowerCase()}-backup-${d.year}-${_two(d.month)}-${_two(d.day)}.json';

String _two(int n) => n.toString().padLeft(2, '0');
String _date(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// «Esporta i miei dati»: usata da Profilo e da Privacy.
Future<void> exportBackup(
  BuildContext context,
  AppStore store, {
  BackupSharer share = shareBackupFile,
}) async {
  final box = context.findRenderObject() as RenderBox?;
  final origin = box == null || !box.hasSize
      ? null
      : box.localToGlobal(Offset.zero) & box.size;
  try {
    await share(store.exportJson(), backupFileName(DateTime.now()), origin);
    if (context.mounted) {
      toast(context, 'Backup pronto. Conservalo in un posto sicuro.');
    }
  } catch (_) {
    if (context.mounted) toast(context, 'Non è stato possibile creare il file');
  }
}

/// «Cancella tutti i dati», con conferma.
Future<void> confirmWipe(BuildContext context, AppStore store) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: const Text(
        'Cancellare tutti i cani e tutti i dati da questo dispositivo? '
        'Non si può annullare.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annulla'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Elimina'),
        ),
      ],
    ),
  );
  if (ok == true) await store.wipe();
}

/// Profilo › Privacy (R-P1 di `ricerca/24`).
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key, this.consent, this.share = shareBackupFile});

  /// Di serie [ConsentStore.instance].
  final ConsentStore? consent;
  final BackupSharer share;

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  ConsentStore get consent => widget.consent ?? ConsentStore.instance;

  Future<void> _toggle(ConsentKind k, bool on) async {
    if (on && !consent.ageConfirmed) {
      final ok = await _askAge();
      if (ok != true) return;
      await consent.confirmAge();
    }
    await consent.set(k, on);
    if (!mounted) return;
    if (!on) {
      // Con l'invio vero (R-P3) il messaggio dello studio diventa quello di
      // docs/CONSENSO-TELEMETRIA.md, con la richiesta di cancellazione.
      toast(context, 'Fatto. Non inviamo più nulla.');
    }
  }

  Future<bool?> _askAge() => showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Una domanda prima'),
      content: const Text(
        'Per dare questo consenso devi avere almeno 14 anni. '
        'Se ne hai meno, serve l\'accordo di un genitore.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Ho almeno 14 anni, o un genitore è d\'accordo'),
        ),
      ],
    ),
  );

  String _state(ConsentKind k) {
    final c = consent.choice(k);
    if (consent.allowed(k)) return 'Attivo dal ${_date(c!.at)}';
    if (c != null && c.granted) {
      return 'Spento: il testo è cambiato, rileggilo e scegli di nuovo';
    }
    if (c != null) return 'Spento dal ${_date(c.at)}';
    return 'Spento';
  }

  void _open(String title, String asset, {String? from, String? to}) =>
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MarkdownAssetPage(title: title, asset: asset, from: from, to: to),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    Widget point(String text) => Padding(
      padding: const EdgeInsets.only(top: Space.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(child: Text('•  ')),
          Expanded(child: Text(text)),
        ],
      ),
    );
    Widget toggle(ConsentKind k, String title, String text) => SwitchListTile(
      value: consent.allowed(k),
      onChanged: (v) => _toggle(k, v),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          const SizedBox(height: 4),
          Text(_state(k), style: t.textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListenableBuilder(
        listenable: consent,
        builder: (context, _) => PageBody(
          children: [
            const SectionTitle('In breve'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    point(
                      'Senza account tutto resta sul tuo telefono: '
                      'noi non riceviamo nulla.',
                    ),
                    point(
                      'L\'account è facoltativo. Serve per il backup, per usare '
                      'più telefoni e per la famiglia. I dati vanno su server in '
                      'Germania (Francoforte).',
                    ),
                    point(
                      'Foto, promemoria e previsioni restano sempre sul telefono.',
                    ),
                    point(
                      'Se attivi l\'avviso caldo, il nome della città va al '
                      'servizio meteo Open-Meteo.',
                    ),
                    point(
                      'Studio sull\'accuratezza e rapporti di errore sono '
                      'facoltativi e spenti finché non dici di sì.',
                    ),
                    point(
                      'Niente pubblicità, niente profilazione, nessuna vendita '
                      'di dati.',
                    ),
                    const SizedBox(height: Space.s),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.article_outlined),
                        label: const Text('Leggi l\'informativa completa'),
                        onPressed: () =>
                            _open('Informativa privacy', privacyAsset),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('Le tue scelte'),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      'Sono facoltative. Se dici di no, $appName funziona '
                      'uguale. Puoi cambiare idea quando vuoi.',
                    ),
                  ),
                  toggle(
                    ConsentKind.study,
                    'Studio sull\'accuratezza',
                    'Invia ogni giorno solo numeri calcolati sul telefono, '
                        'senza diario, nomi, orari o posizione.',
                  ),
                  toggle(
                    ConsentKind.crashReports,
                    'Rapporti di errore',
                    'Invia una descrizione tecnica quando l\'app va in '
                        'errore, senza i dati dei cani.',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'In questa versione di prova l\'app non invia ancora '
                      'nulla: la tua scelta resta salvata e sarà rispettata '
                      'quando lo studio e i rapporti partiranno.',
                      style: t.textTheme.bodySmall,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: TextButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Cosa inviamo, nel dettaglio'),
                      onPressed: () => _open(
                        'Studio e rapporti di errore',
                        consentAsset,
                        from: '### Ci aiuti',
                        to: '## Testo breve',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SectionTitle('I tuoi dati'),
            Card(
              child: Column(
                children: [
                  Builder(
                    builder: (tileContext) => ListTile(
                      leading: const Icon(Icons.ios_share),
                      title: const Text('Esporta i miei dati'),
                      subtitle: const Text(
                        'Un file con tutti i tuoi dati (JSON): scegli tu dove '
                        'salvarlo',
                      ),
                      onTap: () =>
                          exportBackup(tileContext, store, share: widget.share),
                    ),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: t.colorScheme.error,
                    ),
                    title: const Text('Cancella tutti i dati'),
                    subtitle: const Text(
                      'Da questo dispositivo. Per l\'account: Profilo › Account '
                      'e famiglia › Elimina account',
                    ),
                    onTap: () => confirmWipe(context, store),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mostra un testo Markdown incluso nell'app (o una sua parte, da [from]
/// fino a [to] escluso).
class MarkdownAssetPage extends StatelessWidget {
  const MarkdownAssetPage({
    super.key,
    required this.title,
    required this.asset,
    this.from,
    this.to,
  });

  final String title;
  final String asset;
  final String? from;
  final String? to;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: FutureBuilder<String>(
      future: rootBundle.loadString(asset),
      builder: (context, snap) {
        if (snap.hasError) {
          return const Center(child: Text('Testo non disponibile'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SelectionArea(
          child: PageBody(
            children: markdownWidgets(
              section(snap.data!, from: from, to: to),
              Theme.of(context),
            ),
          ),
        );
      },
    ),
  );
}

/// Parte di [md] che inizia con la riga [from] e finisce prima di [to].
String section(String md, {String? from, String? to}) {
  var s = md;
  if (from != null) {
    final i = s.indexOf(from);
    if (i >= 0) s = s.substring(i);
  }
  if (to != null) {
    final i = s.indexOf(to);
    if (i > 0) s = s.substring(0, i);
  }
  return s;
}

/// Markdown essenziale per i testi di `docs/`: titoli, elenchi, tabelle
/// (una scheda per riga), grassetto. Salta le note per lo sviluppatore
/// (righe `>`), i separatori e i finti pulsanti (`[ ... ]`).
List<Widget> markdownWidgets(String md, ThemeData t) {
  final out = <Widget>[];
  final para = <String>[];
  List<String>? header;

  void flush() {
    if (para.isEmpty) return;
    out.add(
      Padding(
        padding: const EdgeInsets.only(top: Space.s),
        child: Text.rich(_inline(para.join(' '))),
      ),
    );
    para.clear();
  }

  for (final raw in const LineSplitter().convert(md)) {
    final line = raw.trim();
    if (!line.startsWith('|')) header = null;
    if (line.isEmpty) {
      flush();
    } else if (line.startsWith('>') || line == '---' || line.startsWith('[')) {
      flush();
    } else if (line.startsWith('#')) {
      flush();
      final level = line.indexOf(' ');
      final text = line.substring(level + 1);
      final style = switch (level) {
        1 => t.textTheme.headlineSmall,
        2 => t.textTheme.titleLarge,
        _ => t.textTheme.titleMedium,
      };
      out.add(
        Padding(
          padding: const EdgeInsets.only(top: Space.l),
          child: Semantics(
            header: true,
            child: Text(_plain(text), style: style),
          ),
        ),
      );
    } else if (line.startsWith('- ')) {
      flush();
      out.add(
        Padding(
          padding: const EdgeInsets.only(top: Space.xs, left: Space.s),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ExcludeSemantics(child: Text('•  ')),
              Expanded(child: Text.rich(_inline(line.substring(2)))),
            ],
          ),
        ),
      );
    } else if (line.startsWith('|')) {
      flush();
      final cells = line
          .substring(1, line.endsWith('|') ? line.length - 1 : line.length)
          .split('|')
          .map((c) => c.trim())
          .toList();
      if (cells.every((c) => RegExp(r'^:?-+:?$').hasMatch(c))) continue;
      if (header == null) {
        header = cells;
        continue;
      }
      out.add(
        Card(
          margin: const EdgeInsets.only(top: Space.s),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < cells.length; i++)
                  if (cells[i].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (i < header.length && header[i].isNotEmpty)
                              TextSpan(
                                text: '${_plain(header[i])}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            _inline(cells[i]),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      );
    } else {
      para.add(line);
    }
  }
  flush();
  return out;
}

String _plain(String s) => s
    .replaceAll('**', '')
    .replaceAll('`', '')
    .replaceAllMapped(RegExp(r'\[\[(.*?)\]\]'), (m) => '[da completare]')
    .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]*\)'), (m) => m[1]!);

/// Testo con il **grassetto** di Markdown.
TextSpan _inline(String s) {
  final parts = _plain(s.replaceAll('**', '\u0000')).split('\u0000');
  return TextSpan(
    children: [
      for (var i = 0; i < parts.length; i++)
        TextSpan(
          text: parts[i],
          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null,
        ),
    ],
  );
}
