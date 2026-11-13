import 'package:flutter/material.dart';

import '../logic/alerts.dart';

/// Identità visiva di Lulù (approvata a novembre 2026, docs/design/).
///
/// Giovane ma non infantile: corallo caldo come colore guida (quello del
/// logo), lime, lilla, cielo e sole come accenti, molto spazio, card grandi e
/// molto arrotondate, titoli grossi. Un solo carattere ad alta leggibilità.
/// Tutte le coppie testo/fondo superano WCAG AA (verificato nei test).
/// Regola delle forme: più una cosa è seria, più è squadrata (gli allarmi
/// restano i più squadrati e mantengono i loro colori clinici).

/// Spaziature (griglia da 4).
abstract final class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Margine laterale delle pagine.
  static const page = 20.0;
}

/// Raggi: gli allarmi sono i più squadrati, il compagno il più morbido.
abstract final class Radii {
  static const alert = 14.0;
  static const chip = 999.0;
  static const field = 18.0;
  static const card = 26.0;
  static const hero = 32.0;
  static const companion = 32.0;
  static const pill = 999.0;
}

/// Durate delle animazioni (azzerate con "riduci movimento").
abstract final class Motion {
  static const short = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 240);

  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  static Duration of(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}

/// Tavolozza di base.
abstract final class Palette {
  // Chiaro: fondo crema caldo, corallo come colore guida.
  static const ink = Color(0xFFB3361E); // corallo scuro: testo e icone (6:1)
  static const inkDeep = Color(0xFF2A0E06);
  static const inkSoft = Color(0xFFFFE3DA);
  static const coral = Color(0xFFF26B4F); // corallo del logo: pulsanti pieni
  static const text = Color(0xFF1E1714);
  static const textMuted = Color(0xFF5C5049);
  static const paper = Color(0xFFFFF7F1);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFF0E2D8);
  static const mustard = Color(0xFFFFD66B); // sole
  static const mustardSoft = Color(0xFFFFF0C2);
  static const mustardInk = Color(0xFF3D2B00);
  static const sage = Color(0xFF3B6512); // verde: testo
  static const sageSoft = Color(0xFFE6F5B8); // lime chiaro
  static const sageInk = Color(0xFF1F2A00);
  static const lilac = Color(0xFFE4D8FF);
  static const lilacInk = Color(0xFF2B1A5C);
  static const sky = Color(0xFFCDEBFF);
  static const skyInk = Color(0xFF06304D);

  // Scuro: marrone notte caldo, non nero.
  static const night = Color(0xFF14100E);
  static const nightCard = Color(0xFF221B18);
  static const nightRaised = Color(0xFF2C2420);
  static const nightLine = Color(0xFF3A2F2A);
  static const nightText = Color(0xFFF8EFE9);
  static const nightMuted = Color(0xFFC4B5AB);
  static const nightInk = Color(0xFFFF8A6E);
  static const nightInkSoft = Color(0xFF4A2219);
  static const nightMustard = Color(0xFFF2C553);
  static const nightMustardSoft = Color(0xFF4A3812);
  static const nightSage = Color(0xFFB9D85A);
  static const nightSageSoft = Color(0xFF2E3A12);
  static const nightLilac = Color(0xFFB9A6F2);
  static const nightSky = Color(0xFF8CCBF5);

  // Schermo LCD del compagno (la sua firma, uguale nei due temi di giorno).
  static const lcdDay = Color(0xFFDCE9C9);
  static const lcdDayInk = Color(0xFF26331F);
  static const lcdNight = Color(0xFF1E2A44);
  static const lcdNightInk = Color(0xFFDDE6FF);
  static const pixelInk = Color(0xFF3A2A25);
}

/// Colori di un livello di allarme: fondo, testo, accento (icona e bordo).
@immutable
class AlertTone {
  const AlertTone(this.bg, this.fg, this.accent, this.icon, this.label);
  final Color bg;
  final Color fg;
  final Color accent;
  final IconData icon;

  /// Etichetta testuale del livello: gli allarmi non si riconoscono solo
  /// dal colore.
  final String? label;
}

/// Colori semantici dell'app, in un ThemeExtension per avere chiaro e scuro.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.subito,
    required this.oggi,
    required this.attenzione,
    required this.info,
    required this.good,
    required this.lcd,
    required this.lcdInk,
    required this.deviceBody,
    required this.deviceBezel,
    required this.dark,
  });

  final AlertTone subito;
  final AlertTone oggi;
  final AlertTone attenzione;
  final AlertTone info;

  /// Esito positivo (valore nella norma, fatto).
  final Color good;
  final Color lcd;
  final Color lcdInk;
  final Color deviceBody;
  final Color deviceBezel;
  final bool dark;

  AlertTone tone(AlertLevel l) => switch (l) {
    AlertLevel.subito => subito,
    AlertLevel.oggi => oggi,
    AlertLevel.attenzione => attenzione,
    AlertLevel.info => info,
  };

  static const light = AppColors(
    // Rosso pieno, testo bianco (6,6:1): la cosa più evidente dell'app.
    subito: AlertTone(
      Color(0xFFB42318),
      Color(0xFFFFFFFF),
      Color(0xFF7A1209),
      Icons.emergency,
      'SUBITO',
    ),
    oggi: AlertTone(
      Color(0xFFFDE6E0),
      Color(0xFF6E1A0D),
      Color(0xFFC0391B),
      Icons.local_hospital_outlined,
      'OGGI',
    ),
    attenzione: AlertTone(
      Color(0xFFFFF2CC),
      Color(0xFF4D3700),
      Color(0xFFA36F00),
      Icons.warning_amber_rounded,
      'ATTENZIONE',
    ),
    info: AlertTone(
      Color(0xFFE6EDF7),
      Color(0xFF1B355A),
      Color(0xFF3D6AA8),
      Icons.info_outline,
      null,
    ),
    good: Color(0xFF2B6A41),
    lcd: Palette.lcdDay,
    lcdInk: Palette.lcdDayInk,
    deviceBody: Palette.sageSoft,
    deviceBezel: Color(0xFF9DB596),
    dark: false,
  );

  static const darkColors = AppColors(
    subito: AlertTone(
      Color(0xFFB42318),
      Color(0xFFFFFFFF),
      Color(0xFFFF8A7A),
      Icons.emergency,
      'SUBITO',
    ),
    oggi: AlertTone(
      Color(0xFF41201A),
      Color(0xFFFFD9CF),
      Color(0xFFFF8F6E),
      Icons.local_hospital_outlined,
      'OGGI',
    ),
    attenzione: AlertTone(
      Color(0xFF3A3014),
      Color(0xFFFBE6AC),
      Color(0xFFF2C064),
      Icons.warning_amber_rounded,
      'ATTENZIONE',
    ),
    info: AlertTone(
      Color(0xFF1C2A3E),
      Color(0xFFD5E2F5),
      Color(0xFF8DB3E8),
      Icons.info_outline,
      null,
    ),
    good: Color(0xFF8FD3A4),
    lcd: Color(0xFFC9D9B4),
    lcdInk: Palette.lcdDayInk,
    deviceBody: Palette.nightRaised,
    deviceBezel: Palette.nightLine,
    dark: true,
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(covariant AppColors? other, double t) =>
      t < 0.5 || other == null ? this : other;
}

extension AppThemeX on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}

/// Carattere: Atkinson Hyperlegible Next (Braille Institute, licenza OFL),
/// incluso in assets/fonts. Disegnato per chi vede poco: lettere che non si
/// confondono (I l 1, O 0), aperto e moderno.
const fontFamily = 'AtkinsonNext';

TextTheme _textTheme(Color text, Color muted) {
  TextStyle s(double size, FontWeight w, double height, [double ls = 0]) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: w,
        height: height,
        letterSpacing: ls,
        color: text,
      );
  return TextTheme(
    displayLarge: s(56, FontWeight.w800, 1.05, -1.5),
    displayMedium: s(48, FontWeight.w800, 1.05, -1.2),
    displaySmall: s(40, FontWeight.w800, 1.08, -1.0),
    headlineLarge: s(34, FontWeight.w800, 1.1, -0.6),
    headlineMedium: s(30, FontWeight.w800, 1.12, -0.5),
    headlineSmall: s(25, FontWeight.w800, 1.18, -0.3),
    titleLarge: s(22, FontWeight.w800, 1.22, -0.2),
    titleMedium: s(17, FontWeight.w700, 1.3),
    titleSmall: s(15.5, FontWeight.w600, 1.3),
    bodyLarge: s(17, FontWeight.w400, 1.45),
    bodyMedium: s(15.5, FontWeight.w400, 1.45),
    bodySmall: s(13.5, FontWeight.w400, 1.4).copyWith(color: muted),
    labelLarge: s(15.5, FontWeight.w600, 1.2, 0.1),
    labelMedium: s(13.5, FontWeight.w600, 1.2, 0.1),
    labelSmall: s(12.5, FontWeight.w600, 1.2, 0.2),
  );
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = dark
      ? const ColorScheme(
          brightness: Brightness.dark,
          primary: Palette.nightInk,
          onPrimary: Palette.inkDeep,
          primaryContainer: Palette.nightInkSoft,
          onPrimaryContainer: Color(0xFFFFDAD0),
          secondary: Palette.nightSage,
          onSecondary: Color(0xFF1F2A00),
          secondaryContainer: Palette.nightSageSoft,
          onSecondaryContainer: Color(0xFFE6F5B8),
          tertiary: Palette.nightLilac,
          onTertiary: Palette.lilacInk,
          tertiaryContainer: Color(0xFF34275C),
          onTertiaryContainer: Palette.lilac,
          error: Color(0xFFFFB4A8),
          onError: Color(0xFF5F1408),
          errorContainer: Color(0xFF41201A),
          onErrorContainer: Color(0xFFFFD9CF),
          surface: Palette.night,
          onSurface: Palette.nightText,
          onSurfaceVariant: Palette.nightMuted,
          surfaceContainerLowest: Color(0xFF0E0B09),
          surfaceContainerLow: Palette.nightCard,
          surfaceContainer: Palette.nightCard,
          surfaceContainerHigh: Palette.nightRaised,
          surfaceContainerHighest: Color(0xFF372D28),
          outline: Color(0xFF9C8B80),
          outlineVariant: Palette.nightLine,
          inverseSurface: Palette.nightText,
          onInverseSurface: Palette.night,
          inversePrimary: Palette.ink,
          shadow: Colors.black,
          scrim: Colors.black,
        )
      : const ColorScheme(
          brightness: Brightness.light,
          primary: Palette.ink,
          onPrimary: Colors.white,
          primaryContainer: Palette.inkSoft,
          onPrimaryContainer: Palette.inkDeep,
          secondary: Palette.sage,
          onSecondary: Colors.white,
          secondaryContainer: Palette.sageSoft,
          onSecondaryContainer: Palette.sageInk,
          tertiary: Color(0xFF5B3FB0),
          onTertiary: Colors.white,
          tertiaryContainer: Palette.lilac,
          onTertiaryContainer: Palette.lilacInk,
          error: Color(0xFFB42318),
          onError: Colors.white,
          errorContainer: Color(0xFFFDE6E0),
          onErrorContainer: Color(0xFF6E1A0D),
          surface: Palette.paper,
          onSurface: Palette.text,
          onSurfaceVariant: Palette.textMuted,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: Palette.card,
          surfaceContainer: Color(0xFFFFFBF8),
          surfaceContainerHigh: Color(0xFFFBEDE4),
          surfaceContainerHighest: Color(0xFFF5E4D9),
          outline: Color(0xFF8C7A70),
          outlineVariant: Palette.line,
          inverseSurface: Palette.text,
          onInverseSurface: Palette.paper,
          inversePrimary: Palette.nightInk,
          shadow: Colors.black,
          scrim: Colors.black,
        );
  final text = _textTheme(scheme.onSurface, scheme.onSurfaceVariant);
  final cardColor = dark ? Palette.nightCard : Palette.card;
  final fieldFill = dark ? Palette.nightCard : Palette.card;
  const pillShape = StadiumBorder();
  const minButton = Size(48, 52);
  final buttonText = text.labelLarge!.copyWith(
    color: null,
    fontWeight: FontWeight.w800,
    fontSize: 16.5,
  );
  final navBg = dark ? Palette.nightText : Palette.text;
  final navInk = dark ? Palette.night : Palette.paper;
  final navMuted = dark ? Palette.textMuted : const Color(0xFFBDB2AA);

  return ThemeData(
    useMaterial3: true,
    brightness: b,
    colorScheme: scheme,
    fontFamily: fontFamily,
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    canvasColor: scheme.surface,
    extensions: [dark ? AppColors.darkColors : AppColors.light],
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.primary,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodyMedium!.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      minVerticalPadding: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.card),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: dark ? Palette.nightInk : Palette.coral,
        foregroundColor: Palette.inkDeep,
        disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.12),
        disabledForegroundColor: scheme.onSurface.withValues(alpha: 0.38),
        minimumSize: minButton,
        shape: pillShape,
        textStyle: buttonText,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minButton,
        shape: pillShape,
        textStyle: buttonText,
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.onSurface, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: pillShape,
        textStyle: buttonText,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: minButton,
        shape: pillShape,
        elevation: 0,
        textStyle: buttonText,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: dark ? Palette.nightInk : Palette.coral,
      foregroundColor: Palette.inkDeep,
      elevation: 1,
      highlightElevation: 2,
      shape: const StadiumBorder(),
      extendedTextStyle: buttonText,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: cardColor,
      side: BorderSide(color: scheme.outlineVariant),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.chip),
      ),
      labelStyle: text.labelLarge!.copyWith(color: scheme.onSurface),
      iconTheme: IconThemeData(color: scheme.primary, size: 20),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      selectedColor: scheme.primaryContainer,
      checkmarkColor: scheme.onPrimaryContainer,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(48, 52),
        textStyle: buttonText,
        selectedBackgroundColor: scheme.primary,
        selectedForegroundColor: scheme.onPrimary,
        backgroundColor: cardColor,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      // Aiuti ed errori lunghi vanno a capo invece di essere troncati (testo
      // al 200%, ricerca/22 §8).
      helperMaxLines: 12,
      errorMaxLines: 12,
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.field),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.field),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.field),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      labelStyle: text.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      side: BorderSide(color: scheme.outline, width: 2),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(scheme.outline),
    ),
    // Barra a pillola: scura nel tema chiaro, chiara nel tema scuro
    // (docs/design/home-*.png). Voce attiva su fondo corallo.
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: navBg,
      surfaceTintColor: Colors.transparent,
      indicatorColor: dark ? Palette.nightInk : Palette.coral,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 24,
          color: s.contains(WidgetState.selected) ? Palette.inkDeep : navMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelMedium!.copyWith(
          color: s.contains(WidgetState.selected) ? navInk : navMuted,
          fontWeight: s.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium!.copyWith(
        color: scheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.field),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.hero),
      ),
      titleTextStyle: text.titleLarge,
      contentTextStyle: text.bodyLarge,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? Palette.nightCard : Palette.card,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: scheme.outline,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.hero)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.field),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      textStyle: text.labelMedium!.copyWith(color: scheme.onInverseSurface),
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.outlineVariant,
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: text.labelLarge!.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: text.labelLarge,
      labelColor: scheme.onSurface,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: dark ? Palette.nightInk : Palette.ink,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: scheme.outlineVariant,
      overlayColor: WidgetStateProperty.all(
        scheme.primary.withValues(alpha: 0.06),
      ),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      shape: const RoundedRectangleBorder(),
      collapsedShape: const RoundedRectangleBorder(),
      iconColor: scheme.primary,
      collapsedIconColor: scheme.onSurfaceVariant,
    ),
  );
}
