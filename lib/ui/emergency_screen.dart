import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../store.dart';
import 'common.dart';

/// Scheda Emergenze, sempre raggiungibile (revisione veterinaria 06,
/// aggiunta ALTA n. 1). Nessuna diagnosi: cosa fare e chi chiamare.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const redFlags = <(String, String)>[
    (
      'Addome gonfio, conati a vuoto, agitazione',
      'Possibile torsione/dilatazione dello stomaco: ogni minuto conta.',
    ),
    (
      'Fatica a respirare, respiro rumoroso, lingua o gengive blu',
      'Tienilo calmo e al fresco durante il trasporto.',
    ),
    (
      'Gengive pallide o bianche, collasso, debolezza improvvisa',
      'Può indicare un\'emorragia interna o uno shock.',
    ),
    (
      'Convulsioni oltre 5 minuti, oppure 2 o più in 24 ore',
      'Non mettere le mani in bocca; allontana gli oggetti; cronometra.',
    ),
    (
      'Colpo di calore: ansima molto, barcolla, gengive rosso scuro',
      'Raffreddalo subito: bagnalo abbondantemente con acqua fresca o fredda '
          'e fai aria. Non coprirlo con asciugamani bagnati. Poi vai subito dal '
          'veterinario continuando a raffreddarlo in auto, anche se sembra '
          'riprendersi.',
    ),
    (
      'Sospetto avvelenamento, morso di vipera, contatto con processionaria',
      'Porta la confezione o una foto. Non provocare il vomito di tua '
          'iniziativa (niente sale o acqua ossigenata).',
    ),
    (
      'Sforzo a urinare senza risultato, o nessuna pipì da 24 ore',
      'Nel maschio un blocco urinario è un\'emergenza.',
    ),
    (
      'Cucciolo con vomito e diarrea, soprattutto se non vaccinato',
      'Va esclusa la parvovirosi; la disidratazione è rapida.',
    ),
    (
      'Cucciolo di taglia toy debole, tremante o che non risponde',
      'Possibile ipoglicemia: solo se è cosciente, un po\' di miele sulle '
          'gengive, poi subito dal veterinario.',
    ),
    (
      'Femmina non sterilizzata abbattuta, che beve molto o ha perdite dalla '
          'vulva, settimane dopo il calore',
      'Possibile piometra (infezione dell\'utero).',
    ),
    (
      'Parto difficile',
      'Oltre 30 minuti di contrazioni forti senza cucciolo, oltre 2 ore tra '
          'un cucciolo e l\'altro, perdite verdi o nere, gravidanza oltre i '
          '70 giorni.',
    ),
    (
      'Cagna che allatta e trema, barcolla o è agitata',
      'Possibile eclampsia (calcio basso).',
    ),
    (
      'Traumi (investimento, caduta, morsi), sanguinamenti, feci nere',
      'Anche se sembra stare bene: le lesioni interne non si vedono.',
    ),
    (
      'Dolore intenso, guaisce se toccato, non si alza',
      'Non dare farmaci per persone: molti sono tossici per il cane.',
    ),
    (
      'Ha ingerito un oggetto, ossa, pannocchie, batterie o farmaci',
      'Chiama prima di fare qualsiasi cosa.',
    ),
    (
      'Reazione allergica grave: muso o palpebre gonfie, orticaria diffusa, '
          'vomito o fatica a respirare dopo puntura, farmaco o vaccino',
      'Il gonfiore del muso può chiudere le vie respiratorie: vai subito.',
    ),
    (
      'Occhio sporgente, ferito, molto dolente o perdita improvvisa della vista',
      'Impedisci che si gratti; non mettere colliri di tua iniziativa.',
    ),
    (
      'Ustioni, folgorazione (cavi elettrici) o quasi-annegamento',
      'Anche se sembra stare bene: i danni a polmoni e cuore possono '
          'comparire nelle ore successive.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final dog = store.dog;
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Emergenze')),
      body: PageBody(
        children: [
          if (dog != null && dog.vetPhone.isNotEmpty)
            _CallTile(
              icon: Icons.local_hospital,
              title: 'Chiama il mio veterinario',
              subtitle:
                  '${dog.vetName.isEmpty ? '' : '${dog.vetName} · '}${dog.vetPhone}',
              number: dog.vetPhone,
            ),
          if (dog != null && dog.emergencyPhone.isNotEmpty)
            _CallTile(
              icon: Icons.emergency,
              title: 'Pronto soccorso veterinario h24',
              subtitle: dog.emergencyPhone,
              number: dog.emergencyPhone,
            ),
          if (dog == null ||
              (dog.vetPhone.isEmpty && dog.emergencyPhone.isEmpty))
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Aggiungi i numeri utili'),
                subtitle: const Text(
                  'Nel profilo del cane inserisci il telefono del tuo '
                  'veterinario e di un pronto soccorso h24: li troverai qui.',
                ),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text(
                'Cerca pronto soccorso veterinario vicino a me',
              ),
              subtitle: const Text('Apre la mappa'),
              onTap: () => launchUrl(
                Uri.parse(
                  'https://www.google.com/maps/search/pronto+soccorso+veterinario',
                ),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
          // Il numero di un centro antiveleni va mostrato solo dopo averne
          // verificato la disponibilità per gli animali (07 N35).
          Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Sospetto avvelenamento'),
              subtitle: const Text(
                'Chiama subito il tuo veterinario o il pronto soccorso h24: '
                'sapranno contattare un centro antiveleni. Tieni a portata la '
                'confezione o una foto dell\'etichetta.',
              ),
            ),
          ),
          if (dog != null) _PhoneScript(dog: dog),
          const SectionTitle('Vai subito dal veterinario se…'),
          for (final (title, help) in redFlags)
            Card(
              child: ListTile(
                leading: Icon(Icons.priority_high, color: t.colorScheme.error),
                title: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(help),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            disclaimer,
            style: t.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CallTile extends StatelessWidget {
  const _CallTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.number,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String number;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.call),
      onTap: () => callNumber(context, number),
    ),
  );
}

/// "Cosa dire al telefono" generato dal profilo (07 aggiunta N16).
class _PhoneScript extends StatelessWidget {
  const _PhoneScript({required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final drugs = store.records
        .where((r) => r.dogId == dog.id && r.isActiveTherapy(now))
        .map((r) => '${r.title}${r.dose.isNotEmpty ? ' ${r.dose}' : ''}')
        .toList();
    final ingest = store
        .logsOf(dog.id)
        .where(
          (l) =>
              l.type == LogType.ingestione &&
              now.difference(l.time).inHours <= 24,
        )
        .toList();
    final lines = [
      '${dog.name}, ${dog.sex == Sex.maschio ? 'maschio' : 'femmina'}'
          '${dog.neutered ? ' sterilizzato/a' : ''}, ${ageLabel(dog, now)}, '
          '${dog.weightKg.toStringAsFixed(1)} kg${dog.breed.isNotEmpty ? ', ${dog.breed}' : ''}.',
      if (ingest.isNotEmpty)
        'Ha ingerito: ${ingest.first.note.isEmpty ? '(descrivi cosa e quanto)' : ingest.first.note} '
            'alle ${hm(ingest.first.time)}.',
      'Farmaci in corso: ${drugs.isEmpty ? 'nessuno' : drugs.join(', ')}.',
      if (dog.conditions.isNotEmpty) 'Patologie note: ${dog.conditions}.',
      if (dog.allergies.isNotEmpty) 'Allergie: ${dog.allergies}.',
      'Cosa è successo e da quando; come respira; colore delle gengive.',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cosa dire al telefono',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            for (final l in lines) Text('• $l'),
          ],
        ),
      ),
    );
  }
}
