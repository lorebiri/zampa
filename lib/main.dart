import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notifications.dart';
import 'store.dart';
import 'sync/supabase_backend.dart';
import 'ui/account_screen.dart';
import 'ui/common.dart';
import 'ui/dog_form.dart';
import 'ui/health_screen.dart';
import 'ui/home_screen.dart';
import 'ui/nutrition_screen.dart';
import 'ui/potty_screen.dart';
import 'ui/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Notifier.instance.init();
  final store = AppStore(notifier: Notifier.instance);
  await store.load();
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
    ThemeData theme(Brightness b) {
      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D6B),
        brightness: b,
      ).copyWith(tertiary: const Color(0xFFE08A3C));
      return ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.symmetric(vertical: 6),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      );
    }

    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Zampa',
        debugShowCheckedModeBanner: false,
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        locale: const Locale('it'),
        supportedLocales: const [Locale('it'), Locale('en')],
        localizationsDelegates: const [
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
    return Scaffold(
      body: SafeArea(child: pages[_tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Oggi',
          ),
          NavigationDestination(
            icon: Icon(Icons.water_drop_outlined),
            selectedIcon: Icon(Icons.water_drop),
            label: 'Bisogni',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'Salute',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Nutrizione',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.all(28),
              shrinkWrap: true,
              children: [
                Icon(Icons.pets, size: 64, color: t.colorScheme.primary),
                const SizedBox(height: 12),
                Text(
                  'Zampa',
                  style: t.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'La salute del tuo cane in un posto solo: cartella sanitaria, '
                  'vaccini, farmaci, nutrizione e un modello che impara quando '
                  'deve uscire per la pipì e la cacca.',
                  style: t.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Aggiungi il tuo cane'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DogFormPage()),
                  ),
                ),
                const SizedBox(height: 12),
                if (appAuth != null) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Ho già un account'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AccountScreen()),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Prova con un cane di esempio'),
                  onPressed: store.loadDemo,
                ),
                const SizedBox(height: 24),
                Text(
                  'I dati restano sul tuo dispositivo. Zampa non sostituisce il '
                  'veterinario.',
                  style: t.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(28),
              shrinkWrap: true,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 56,
                  color: t.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Prima di iniziare',
                  style: t.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(disclaimer, style: t.textTheme.bodyLarge),
                const SizedBox(height: 12),
                const Text(
                  'Zampa non è un dispositivo medico. In Italia diagnosi e '
                  'prescrizione dei farmaci veterinari spettano solo al '
                  'veterinario: l\'app non suggerisce dosi né terapie. Le '
                  'previsioni dei bisogni sono stime statistiche.',
                ),
                const SizedBox(height: 12),
                const Text(
                  'I dati restano solo su questo dispositivo: nessun account, '
                  'nessun server, nessuna pubblicità. Solo se attivi l\'avviso '
                  'caldo, la città viene inviata al servizio meteo Open-Meteo.',
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: ok,
                  onChanged: (v) => setState(() => ok = v ?? false),
                  title: const Text('Ho letto e ho capito'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: ok
                      ? () => StoreScope.read(context).acceptTerms()
                      : null,
                  child: const Text('Continua'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
