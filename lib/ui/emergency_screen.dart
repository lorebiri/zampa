import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/clinical_text.dart';
import '../l10n/country_pack.dart';
import '../models.dart';
import '../store.dart';
import 'common.dart';
import 'theme.dart';

/// Scheda Emergenze, sempre raggiungibile (revisione veterinaria 06,
/// aggiunta ALTA n. 1). Nessuna diagnosi: cosa fare e chi chiamare.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  /// Segnali d'allarme EMG-001…018 del catalogo: (titolo, cosa fare).
  static List<(String, String)> get redFlags => [
    for (var i = 1; i <= 18; i++)
      () {
        final t = ClinicalText('EMG-${i.toString().padLeft(3, '0')}');
        return (t.title, t.text);
      }(),
  ];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final dog = store.dog;
    final cav = dog == null ? null : poisonCentreFor(dog.country);
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(const ClinicalText('UI-EMG-001').text)),
      body: PageBody(
        children: [
          if (dog != null && dog.vetPhone.isNotEmpty)
            _CallTile(
              icon: Icons.local_hospital,
              title: const ClinicalText('UI-EMG-002').text,
              subtitle:
                  '${dog.vetName.isEmpty ? '' : '${dog.vetName} · '}${dog.vetPhone}',
              number: dog.vetPhone,
            ),
          if (dog != null && dog.emergencyPhone.isNotEmpty)
            _CallTile(
              icon: Icons.emergency,
              title: const ClinicalText('UI-EMG-003').text,
              subtitle: dog.emergencyPhone,
              number: dog.emergencyPhone,
            ),
          if (dog == null ||
              (dog.vetPhone.isEmpty && dog.emergencyPhone.isEmpty))
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(const ClinicalText('EMG-020').title),
                subtitle: Text(const ClinicalText('EMG-020').text),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(const ClinicalText('UI-EMG-004').title),
              subtitle: Text(const ClinicalText('UI-EMG-004').text),
              onTap: () => launchUrl(
                Uri.parse(
                  'https://www.google.com/maps/search/pronto+soccorso+veterinario',
                ),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ),
          // Il numero di un centro antiveleni si mostra solo se verificato
          // per gli animali (07 N35) e solo nel Paese del cane (piano CEO
          // 10.5): oggi il CAV di Milano per l'Italia.
          Card(
            child: ListTile(
              leading: const Icon(Icons.science_outlined),
              title: Text(const ClinicalText('EMG-019').title),
              subtitle: Text(
                ClinicalText('EMG-019', {
                  'cav': yesNo(cav != null),
                  'phone': cav?.phone ?? '',
                }).text,
              ),
              trailing: cav == null ? null : const Icon(Icons.call),
              onTap: cav == null ? null : () => callNumber(context, cav.phone),
            ),
          ),
          if (dog != null) _PhoneScript(dog: dog),
          SectionTitle(const ClinicalText('UI-EMG-005').text),
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
  Widget build(BuildContext context) {
    // Il numero da chiamare è l'azione più importante della pagina: blocco
    // rosso pieno, come gli allarmi SUBITO.
    final tone = context.colors.subito;
    final t = Theme.of(context).textTheme;
    return Card(
      color: tone.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.alert),
      ),
      child: ListTile(
        minVerticalPadding: 14,
        leading: Icon(icon, color: tone.fg, size: 28),
        title: Text(
          title,
          style: t.titleMedium?.copyWith(
            color: tone.fg,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle, style: t.bodyLarge?.copyWith(color: tone.fg)),
        trailing: Icon(Icons.call, color: tone.fg),
        onTap: () => callNumber(context, number),
      ),
    );
  }
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
    // Promemoria EMG-021 e righe UI-EMG-007…011 del catalogo.
    final lines = [
      ClinicalText('EMG-021', {
        'name': dog.name,
        'sex': dog.sex == Sex.maschio ? 'male' : 'female',
        'neutered': yesNo(dog.neutered),
        'age': ageLabel(dog, now),
        'weight': dog.weightKg.toStringAsFixed(1),
        'hasBreed': yesNo(dog.breed.isNotEmpty),
        'breed': dog.breed,
      }).text,
      if (ingest.isNotEmpty)
        ClinicalText('UI-EMG-007', {
          'hasNote': yesNo(ingest.first.note.isNotEmpty),
          'note': ingest.first.note,
          'time': hm(ingest.first.time),
        }).text,
      ClinicalText('UI-EMG-008', {
        'hasDrugs': yesNo(drugs.isNotEmpty),
        'drugs': drugs.join(', '),
      }).text,
      if (dog.conditions.isNotEmpty)
        ClinicalText('UI-EMG-009', {'conditions': dog.conditions}).text,
      if (dog.allergies.isNotEmpty)
        ClinicalText('UI-EMG-010', {'allergies': dog.allergies}).text,
      const ClinicalText('UI-EMG-011').text,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              const ClinicalText('EMG-021').title,
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
