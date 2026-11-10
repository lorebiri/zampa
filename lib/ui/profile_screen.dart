import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../store.dart';
import 'common.dart';
import 'account_screen.dart';
import 'avatar.dart';
import 'dog_form.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    return PageBody(
      children: [
        Text(
          'I tuoi cani',
          style: t.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        for (final d in store.dogs)
          Card(
            child: ListTile(
              leading: SizedBox(
                width: 64,
                child: PixelDogView(look: d.look, height: 48),
              ),
              title: Text(d.name),
              subtitle: Text(
                '${d.breed.isEmpty ? '' : '${d.breed} · '}${ageLabel(d)} · ${d.weightKg.toStringAsFixed(1)} kg',
              ),
              selected: d.id == store.dog?.id,
              onTap: () => store.selectDog(d.id),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => DogFormPage(dog: d))),
              ),
            ),
          ),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Aggiungi un altro cane'),
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const DogFormPage())),
        ),
        const SectionTitle('Account'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('Account e famiglia'),
            subtitle: const Text(
              'Facoltativo: backup, più dispositivi, condivisione',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
        ),
        const SectionTitle('I tuoi dati'),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Esporta tutti i dati (JSON)'),
                subtitle: const Text('Copia un backup completo negli appunti'),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(text: store.exportJson()),
                  );
                  if (context.mounted) {
                    toast(context, 'Backup copiato negli appunti');
                  }
                },
              ),
              if (store.dog != null)
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: t.colorScheme.error,
                  ),
                  title: Text('Elimina ${store.dog!.name}'),
                  onTap: () => _confirm(
                    context,
                    'Eliminare ${store.dog!.name} e tutti i suoi dati? Non si può annullare.',
                    () => store.deleteDog(store.dog!.id),
                  ),
                ),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: t.colorScheme.error,
                ),
                title: const Text('Cancella tutti i dati'),
                onTap: () => _confirm(
                  context,
                  'Cancellare tutti i cani e tutti i dati da questo dispositivo? Non si può annullare.',
                  store.wipe,
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Informazioni'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zampa 0.1 – prototipo', style: t.textTheme.titleMedium),
                const SizedBox(height: 6),
                const Text(
                  'I dati restano solo su questo dispositivo: nessun account, nessun server, nessuna pubblicità. '
                  'Solo se attivi l\'avviso caldo, la città viene inviata al servizio meteo Open-Meteo.',
                ),
                const SizedBox(height: 6),
                const Text(
                  'Basi scientifiche: WSAVA 2024 (vaccini), ESCCAP Italia (parassiti), NRC 2006 e FEDIAF '
                  '(nutrizione), AAHA (fasi di vita), letteratura di fisiologia veterinaria per il modello '
                  'dei bisogni.',
                ),
                const SizedBox(height: 6),
                Text(disclaimer, style: t.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirm(
    BuildContext context,
    String msg,
    Future<void> Function() action,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await action();
            },
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
  }
}
