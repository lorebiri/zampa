import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_localizations.dart';
import 'notifications.dart';
import 'brand.dart';
import 'consent.dart';
import 'store.dart';
import 'sync/push_reminders.dart';
import 'sync/supabase_backend.dart';
import 'logic/alerts.dart';
import 'models.dart';
import 'ui/account_screen.dart';
import 'ui/avatar.dart';
import 'ui/common.dart';
import 'ui/device_notice.dart';
import 'ui/dog_wizard.dart';
import 'ui/health_screen.dart';
import 'ui/home_screen.dart';
import 'ui/nutrition_screen.dart';
import 'ui/potty_screen.dart';
import 'ui/profile_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifier.instance.init();
  final store = AppStore(notifier: Notifier.instance);
  await store.load();
  await ConsentStore.instance.load();
  // Account facoltativo: attivo solo se la build contiene la configurazione
  // Supabase (vedi supabase/LEGGIMI.md).
  if (AccountConfig.enabled) {
    await setupAccounts(store, () async {
      try {
        await Supabase.initialize(
          url: AccountConfig.url,
          publishableKey: AccountConfig.anonKey,
        );
        final client = Supabase.instance.client;
        attachEngine(store, SupabaseBackend(client));
        // Web e iPhone: promemoria come notifiche Web Push dal server.
        if (kIsWeb && PushConfig.enabled) {
          final sink = SupabaseReminderSink(client);
          await sink.restore();
          store.reminderSink = sink;
          appReminders = sink;
          client.auth.onAuthStateChange.listen((_) => store.replan());
        }
        return AuthService(client);
      } catch (e) {
        debugPrint('Account non disponibili: $e');
        return null;
      }
    });
  }
  runApp(ZampaApp(store: store));
}

class ZampaApp extends StatelessWidget {
  const ZampaApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        locale: const Locale('it'),
        supportedLocales: const [Locale('it'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const RootPage(),
      ),
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    if (!store.termsAccepted) return const TermsPage();
    final dog = store.dog;
    if (dog == null) return const WelcomePage();
    final pages = [
      HomeScreen(onOpenTab: (i) => setState(() => _tab = i)),
      const PottyScreen(),
      const HealthScreen(),
      const NutritionScreen(),
      const ProfileScreen(),
    ];
    // Con il testo molto grande le etichette della barra restano solo sulla
    // voce attiva, così non vengono tagliate (P12/P13 del rapporto 16).
    final bigText = MediaQuery.textScalerOf(context).scale(10) > 13;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.short),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: KeyedSubtree(key: ValueKey(_tab), child: pages[_tab]),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.3,
          child: NavigationBar(
            selectedIndex: _tab,
            labelBehavior: bigText
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : null,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.wb_sunny_outlined),
                selectedIcon: Icon(Icons.wb_sunny),
                label: 'Oggi',
              ),
              NavigationDestination(
                icon: Icon(Icons.water_drop_outlined),
                selectedIcon: Icon(Icons.water_drop),
                label: 'Bisogni',
              ),
              NavigationDestination(
                icon: Icon(Icons.monitor_heart_outlined),
                selectedIcon: Icon(Icons.monitor_heart),
                label: 'Salute',
              ),
              NavigationDestination(
                icon: Icon(Icons.rice_bowl_outlined),
                selectedIcon: Icon(Icons.rice_bowl),
                label: 'Nutrizione',
              ),
              NavigationDestination(
                icon: Icon(Icons.pets_outlined),
                selectedIcon: Icon(Icons.pets),
                label: 'Profilo',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Impaginazione comune di benvenuto e avvertenza: colonna stretta,
/// testo allineato a sinistra, scorrevole anche con il testo al 200%.
class _IntroLayout extends StatelessWidget {
  const _IntroLayout({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Space.xl,
              Space.xl,
              Space.xl,
              Space.xxl,
            ),
            children: children,
          ),
        ),
      ),
    ),
  );
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    return _IntroLayout(
      children: [
        CompanionDevice(
          child: ExcludeSemantics(
            child: PixelDogView(
              look: AvatarLook(),
              pose: Pose.happy,
              height: 150,
            ),
          ),
        ),
        const SizedBox(height: Space.xl),
        Semantics(
          header: true,
          child: Text(appName, style: t.textTheme.displaySmall),
        ),
        const SizedBox(height: Space.s),
        Text(
          appTagline,
          style: t.textTheme.titleLarge?.copyWith(color: t.colorScheme.primary),
        ),
        const SizedBox(height: Space.m),
        Text(
          'La salute del tuo cane in un posto solo: cartella sanitaria, '
          'vaccini, farmaci, nutrizione e un modello che impara quando '
          'deve uscire per la pipì e la cacca.',
          style: t.textTheme.bodyLarge?.copyWith(
            color: t.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Space.xl),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Aggiungi il tuo cane'),
          onPressed: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const DogWizardPage())),
        ),
        const SizedBox(height: Space.m),
        if (appAuth != null) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Ho già un account'),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AccountScreen())),
          ),
          const SizedBox(height: Space.m),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.science_outlined),
          label: const Text('Prova con un cane di esempio'),
          onPressed: store.loadDemo,
        ),
        const SizedBox(height: Space.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lock_outline,
              size: 18,
              color: t.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Space.s),
            Expanded(
              child: Text(
                'I dati restano sul tuo dispositivo. $appName non sostituisce il '
                'veterinario.',
                style: t.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Avvertenza d'uso da accettare al primo avvio (revisione veterinaria 06 §34).
class TermsPage extends StatefulWidget {
  const TermsPage({super.key});
  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  bool ok = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final s = t.colorScheme;
    Widget point(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: Space.l),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: s.primary),
          const SizedBox(width: Space.m),
          Expanded(child: Text(text, style: t.textTheme.bodyLarge)),
        ],
      ),
    );
    return _IntroLayout(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: s.primaryContainer,
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: Icon(
              Icons.health_and_safety_outlined,
              size: 34,
              color: s.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: Space.l),
        Semantics(
          header: true,
          child: Text('Prima di iniziare', style: t.textTheme.headlineMedium),
        ),
        const SizedBox(height: Space.l),
        const NoticeCard(disclaimer, level: AlertLevel.info),
        point(
          Icons.medical_information_outlined,
          '$appName non è un dispositivo medico. In Italia diagnosi e '
          'prescrizione dei farmaci veterinari spettano solo al '
          'veterinario: l\'app non suggerisce dosi né terapie. Le '
          'previsioni dei bisogni sono stime statistiche.',
        ),
        point(
          Icons.lock_outline,
          'Senza account i dati restano solo su questo dispositivo; '
          'l\'account è facoltativo. Nessuna pubblicità. Solo se attivi '
          'l\'avviso caldo, la città viene inviata al servizio meteo '
          'Open-Meteo. Dettagli in Profilo › Privacy.',
        ),
        const SizedBox(height: Space.xl),
        Material(
          color: ok ? s.primaryContainer : s.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.field),
            side: BorderSide(color: ok ? s.primary : s.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: CheckboxListTile(
            value: ok,
            onChanged: (v) => setState(() => ok = v ?? false),
            title: const Text('Ho letto e ho capito'),
            // Età (R-P4 di ricerca/24, informativa §9): una frase in più nel
            // testo da accettare, salvata con data e versione.
            subtitle: const Text(
              'e ho almeno 14 anni, oppure un genitore è d\'accordo',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        const SizedBox(height: Space.l),
        FilledButton(
          onPressed: ok
              ? () {
                  unawaited(ConsentStore.instance.confirmAge());
                  StoreScope.read(context).acceptTerms();
                }
              : null,
          child: const Text('Continua'),
        ),
      ],
    );
  }
}
