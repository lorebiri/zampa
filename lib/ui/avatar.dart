import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/alerts.dart';
import '../logic/bio_params.dart';
import '../logic/elimination_model.dart';
import '../logic/modules.dart';
import '../logic/nutrition.dart';
import '../logic/potty_predictor.dart';
import '../models.dart';
import '../store.dart';
import 'common.dart';
import 'theme.dart';

/// Il "compagno" in pixel art: un cane disegnato da zero, personalizzabile,
/// i cui stati d'animo riflettono i dati reali (mai colpevolizzante, mai una
/// diagnosi: con un allarme serio l'avatar si fa da parte).

enum Pose { idle, happy, waiting, hungry, sleeping, concerned }

class PixelDog {
  static const w = 44, h = 30;

  /// Rasterizza il cane in una griglia di colori (null = trasparente).
  static List<List<Color?>> render(AvatarLook look, Pose pose, int frame) {
    final g = List.generate(h, (_) => List<Color?>.filled(w, null));
    final main = Color(look.coat);
    final sec = Color(look.coat2);
    final dark = Color.lerp(main, Colors.black, 0.35)!;
    final k = switch (look.size) {
      DogSize.piccola => 0.78,
      DogSize.media => 1.0,
      DogSize.grande => 1.22,
    };
    final lying = pose == Pose.sleeping;
    const ground = 27;
    final legLen = lying ? 0 : (2.5 + 2.2 * k).round();
    final rx = 8.5 * k, ry = 3.8 * k;
    final cx = 19.0;
    final cy = ground - legLen - ry + (lying ? 0.5 : 0);
    final headR = 3.6 + 1.3 * k + (look.size == DogSize.piccola ? 0.6 : 0);
    final bob = (pose == Pose.idle || pose == Pose.waiting) && frame % 4 >= 2
        ? 1
        : 0;
    final hx = cx + rx + headR * 0.45;
    final hy = cy - ry - headR * 0.35 + (lying ? 3.2 : 0) + bob;

    void px(int x, int y, Color c) {
      if (x >= 0 && x < w && y >= 0 && y < h) g[y][x] = c;
    }

    void ellipse(
      double ex,
      double ey,
      double erx,
      double ery,
      Color Function(int, int) col,
    ) {
      for (var y = (ey - ery).floor(); y <= (ey + ery).ceil(); y++) {
        for (var x = (ex - erx).floor(); x <= (ex + erx).ceil(); x++) {
          final dx = (x + 0.5 - ex) / erx, dy = (y + 0.5 - ey) / ery;
          if (dx * dx + dy * dy <= 1) px(x, y, col(x, y));
        }
      }
    }

    // Motivi del mantello.
    bool spot(int x, int y) =>
        ((x * 7 + y * 13) % 11 == 0) || ((x * 5 + y * 3) % 17 == 0);
    Color bodyColor(int x, int y) {
      switch (look.pattern) {
        case CoatPattern.tinta:
        case CoatPattern.maschera:
          return main;
        case CoatPattern.focature:
          return y > cy + ry * 0.35 ? sec : main;
        case CoatPattern.pettoBianco:
          return (x > cx + rx * 0.45 && y > cy - ry * 0.2) || y > cy + ry * 0.55
              ? sec
              : main;
        case CoatPattern.macchie:
          return spot(x, y) ? dark : main;
        case CoatPattern.pezzato:
          final a =
              math.pow((x - (cx - rx * 0.3)) / (rx * 0.45), 2) +
                  math.pow((y - cy) / (ry * 0.9), 2) <
              1;
          return a ? main : sec;
      }
    }

    final tailWag = pose == Pose.happy
        ? (frame % 2 == 0 ? -1 : 1)
        : (frame % 6 == 0 ? 1 : 0);

    // Coda (dietro al corpo).
    final tx = (cx - rx + 1).round(), ty = (cy - ry * 0.4).round();
    switch (look.tail) {
      case TailType.lunga:
        for (var i = 0; i < (4 + 2 * k).round(); i++) {
          final x = tx - i, y = ty - (i * 0.9).round() + (i > 1 ? tailWag : 0);
          px(
            x,
            y,
            i > 3 && look.pattern == CoatPattern.pettoBianco ? sec : main,
          );
          if (look.longHair) px(x, y + 1, main);
        }
      case TailType.arricciata:
        ellipse(
          tx - 0.5 + tailWag * 0.3,
          cy - ry - 0.8,
          1.7,
          1.5,
          (_, _) => main,
        );
        px(tx, (cy - ry - 0.8).round(), dark);
      case TailType.corta:
        px(tx - 1, ty + tailWag.clamp(-1, 0), main);
        px(tx - 2, ty - 1 + tailWag.clamp(-1, 0), main);
    }

    // Zampe.
    if (!lying) {
      final legXs = [
        (cx - rx + 2).round(),
        (cx - rx + 4.5).round(),
        (cx + rx - 4.5).round(),
        (cx + rx - 2).round(),
      ];
      for (var i = 0; i < legXs.length; i++) {
        final stepUp = pose == Pose.happy && frame % 2 == i % 2 ? 1 : 0;
        for (var y = (cy + ry * 0.6).round(); y < ground - stepUp; y++) {
          final paw = y >= ground - 2 - stepUp;
          final c =
              paw &&
                  (look.pattern == CoatPattern.focature ||
                      look.pattern == CoatPattern.pettoBianco)
              ? sec
              : (i == 0 || i == 2
                    ? Color.lerp(main, Colors.black, 0.12)!
                    : main);
          px(legXs[i], y, c);
          px(legXs[i] + 1, y, c);
        }
      }
    } else {
      // Zampe anteriori distese davanti.
      for (var x = (cx + rx - 1).round(); x < (hx + headR * 0.6).round(); x++) {
        px(x, ground - 1, look.pattern == CoatPattern.tinta ? main : sec);
      }
    }

    // Corpo.
    ellipse(cx, cy, rx, ry, bodyColor);
    if (look.longHair) {
      for (var x = (cx - rx + 2).round(); x < (cx + rx - 1).round(); x += 2) {
        px(x, (cy + ry).round(), bodyColor(x, (cy + ry).round()));
      }
    }

    // Collare.
    final collar = Color(look.collar);
    for (
      var y = (hy + headR * 0.45).round();
      y <= (cy - ry * 0.1).round();
      y++
    ) {
      px((hx - headR * 0.55).round(), y, collar);
      px((hx - headR * 0.55).round() + 1, y, collar);
    }
    px(
      (hx - headR * 0.55).round() + 1,
      (cy - ry * 0.1).round() + 1,
      const Color(0xFFF2C94C),
    );

    // Testa e muso.
    Color headColor(int x, int y) {
      if (look.pattern == CoatPattern.maschera && x > hx - 1) return dark;
      if (look.pattern == CoatPattern.pezzato) return x < hx ? main : sec;
      return main;
    }

    ellipse(hx, hy, headR, headR * 1.02, headColor);
    final mx = hx + headR * 0.85, my = hy + headR * 0.3;
    final muzzleSec =
        look.pattern == CoatPattern.focature ||
        look.pattern == CoatPattern.pettoBianco ||
        look.pattern == CoatPattern.pezzato;
    ellipse(
      mx,
      my,
      2.2 + 0.4 * k,
      1.6 + 0.3 * k,
      (_, _) => muzzleSec ? sec : main,
    );
    px(
      (mx + 2.2 + 0.4 * k).round() - 1,
      (my - 0.6).round(),
      const Color(0xFF2B1B17),
    ); // naso
    if (pose == Pose.happy || pose == Pose.waiting) {
      px(mx.round(), (my + 1.4).round(), const Color(0xFFE76F8A)); // lingua
      if (frame % 2 == 0) {
        px(mx.round(), (my + 2.2).round(), const Color(0xFFE76F8A));
      }
    }
    // Focature sopra gli occhi.
    if (look.pattern == CoatPattern.focature) {
      px((hx + 1).round(), (hy - 2.2).round(), sec);
    }

    // Occhio.
    final ex = (hx + 1).round(), ey = (hy - 1).round();
    final blink = pose == Pose.idle && frame % 9 == 0;
    if (pose == Pose.sleeping || blink) {
      px(ex, ey, const Color(0xFF2B1B17));
      px(ex + 1, ey, const Color(0xFF2B1B17));
    } else {
      px(ex, ey, const Color(0xFF2B1B17));
      px(ex, ey - 1, const Color(0xFF2B1B17));
      px(ex + 1, ey - 1, Colors.white);
      if (pose == Pose.concerned) px(ex - 1, ey - 2, const Color(0xFF2B1B17));
    }

    // Orecchie.
    final earX = hx - headR * 0.35;
    final earTop = hy - headR;
    switch (look.ears) {
      case EarType.dritte:
        final eh = (3 + 2.2 * k).round();
        for (var i = 0; i < eh; i++) {
          final half = ((eh - i) / 2).floor();
          for (var d = -half; d <= half; d++) {
            px(
              (earX + d).round(),
              (earTop - i + 1).round(),
              i == 0 ? dark : main,
            );
          }
        }
        px(
          earX.round(),
          (earTop).round(),
          Color.lerp(main, const Color(0xFFE76F8A), 0.4)!,
        );
      case EarType.pendenti:
        ellipse(
          earX - 0.5,
          hy + 0.5,
          1.4,
          2.8 + (look.longHair ? 1 : 0),
          (_, _) => dark,
        );
      case EarType.semi:
        for (var d = -1; d <= 1; d++) {
          px((earX + d).round(), earTop.round(), main);
        }
        px(earX.round() + 1, earTop.round() - 1, dark);
        px(earX.round() + 2, earTop.round(), dark);
    }

    // Contorno pixel.
    final out = List.generate(h, (y) => List<Color?>.from(g[y]));
    const ink = Color(0xFF3A2A25);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (g[y][x] != null) continue;
        final n = [
          if (x > 0) g[y][x - 1],
          if (x < w - 1) g[y][x + 1],
          if (y > 0) g[y - 1][x],
          if (y < h - 1) g[y + 1][x],
        ];
        if (n.any((c) => c != null)) out[y][x] = ink;
      }
    }
    return out;
  }
}

class _PixelPainter extends CustomPainter {
  _PixelPainter(this.grid, this.night, this.lcd);
  final List<List<Color?>> grid;
  final bool night;
  final bool lcd;

  @override
  void paint(Canvas canvas, Size size) {
    final p = math
        .min(size.width / PixelDog.w, size.height / PixelDog.h)
        .floorToDouble();
    final ox = (size.width - p * PixelDog.w) / 2;
    final oy = (size.height - p * PixelDog.h) / 2;
    final paint = Paint();
    // Erba / pavimento.
    for (var x = 0; x < PixelDog.w; x++) {
      paint.color = night ? const Color(0xFF2E4A3A) : const Color(0xFF7DB85C);
      canvas.drawRect(Rect.fromLTWH(ox + x * p, oy + 27 * p, p, p * 3), paint);
      if (x % 5 == 1) {
        paint.color = night ? const Color(0xFF3E5E4A) : const Color(0xFF94CC6F);
        canvas.drawRect(Rect.fromLTWH(ox + x * p, oy + 26 * p, p, p), paint);
      }
    }
    for (var y = 0; y < PixelDog.h; y++) {
      for (var x = 0; x < PixelDog.w; x++) {
        final c = grid[y][x];
        if (c == null) continue;
        paint.color = night ? Color.lerp(c, const Color(0xFF1B2440), 0.35)! : c;
        canvas.drawRect(
          Rect.fromLTWH(ox + x * p, oy + y * p, p + 0.3, p + 0.3),
          paint,
        );
      }
    }
    if (lcd) {
      // Sottile retino da schermo LCD.
      paint.color = Colors.black.withValues(alpha: 0.05);
      for (var y = 0; y < PixelDog.h; y++) {
        canvas.drawRect(
          Rect.fromLTWH(ox, oy + y * p, p * PixelDog.w, 0.6),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelPainter old) => true;
}

/// Il cane disegnato, animato.
class PixelDogView extends StatefulWidget {
  const PixelDogView({
    super.key,
    required this.look,
    this.pose = Pose.idle,
    this.night = false,
    this.height = 170,
  });
  final AvatarLook look;
  final Pose pose;
  final bool night;
  final double height;

  @override
  State<PixelDogView> createState() => _PixelDogViewState();
}

class _PixelDogViewState extends State<PixelDogView>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();
  bool boost = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Riduci movimento": il compagno resta fermo (rapporto 16, P9).
    if (Motion.reduced(context)) {
      c.stop();
    } else if (!c.isAnimating) {
      c.repeat();
    }
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      if (Motion.reduced(context)) return;
      setState(() => boost = true);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      if (mounted) setState(() => boost = false);
    },
    child: SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: c,
        builder: (_, _) {
          // Toccarlo non lo rende felice se è preoccupato (07 N39).
          final pose =
              boost &&
                  widget.pose != Pose.sleeping &&
                  widget.pose != Pose.concerned
              ? Pose.happy
              : widget.pose;
          final speed = pose == Pose.happy ? 24 : 9;
          final frame = Motion.reduced(context) ? 0 : (c.value * speed).floor();
          return CustomPaint(
            size: Size.infinite,
            painter: _PixelPainter(
              PixelDog.render(widget.look, pose, frame),
              widget.night,
              true,
            ),
          );
        },
      ),
    ),
  );
}

/// Stato del compagno calcolato dai dati reali, con le regole della
/// revisione veterinaria (07 N38-N43): mai felice con un allarme aperto,
/// niente "fame" quando nutrirlo potrebbe essere sbagliato.
class PetMood {
  PetMood(this.pose, this.message, this.bubble);
  final Pose pose;
  final String message;
  final IconData? bubble;

  static PetMood of(
    AppStore store,
    Dog dog,
    DateTime now,
    Forecast pee,
    List<HealthAlert> alerts,
  ) {
    if (alerts.any(
      (a) => a.level == AlertLevel.oggi || a.level == AlertLevel.subito,
    )) {
      return PetMood(
        Pose.concerned,
        'Ci sono segnalazioni importanti: leggile qui sopra.',
        Icons.priority_high,
      );
    }
    final watch = alerts.any((a) => a.level == AlertLevel.attenzione);
    if (PottyPredictor.inSleepWindow(dog, now)) {
      return PetMood(
        Pose.sleeping,
        'È la sua ora di riposo.'
        '${pee.last == null ? '' : ' Prima uscita prevista alle ${hm(pee.recommendedAt)}.'}',
        Icons.bedtime,
      );
    }
    if (watch) {
      return PetMood(
        Pose.idle,
        'C\'è qualcosa da tenere d\'occhio: leggi qui sotto.',
        Icons.visibility_outlined,
      );
    }
    final logs = store.logsOf(dog.id);
    final recent = logs
        .where((l) => now.difference(l.time).inMinutes <= 30)
        .toList();
    final cleanOuting = recent.any(
      (l) =>
          (l.type == LogType.pipi ||
              l.type == LogType.cacca ||
              l.type == LogType.passeggiata) &&
          !l.indoor,
    );
    if (cleanOuting && recent.every((l) => l.signs.isEmpty)) {
      return PetMood(
        Pose.happy,
        '${dog.name} è contento: uscita fatta!',
        Icons.favorite,
      );
    }
    if (pee.last != null &&
        (pee.overdue || pee.recommendedAt.difference(now).inMinutes <= 20)) {
      return PetMood(
        Pose.waiting,
        '${dog.name} aspetta la porta: è ora di uscire.',
        Icons.door_front_door_outlined,
      );
    }
    if (_mealTime(store, dog, now)) {
      return PetMood(
        Pose.hungry,
        Modules.diabetic(dog, store.records)
            ? 'Ora del pasto: prima il pasto, poi l\'insulina solo se ha mangiato.'
            : 'È l\'ora del suo pasto abituale.',
        Icons.restaurant,
      );
    }
    return PetMood(
      Pose.idle,
      '${dog.name} sta tranquillo. Prossima uscita alle ${hm(pee.recommendedAt)}.',
      null,
    );
  }

  static bool _mealTime(AppStore store, Dog dog, DateTime now) {
    final logs = store.logsOf(dog.id);
    final h12 = logs.where((l) => now.difference(l.time).inHours <= 12);
    final unsafe = h12.any(
      (l) =>
          l.type == LogType.vomito ||
          l.type == LogType.ingestione ||
          l.type == LogType.inappetenza ||
          l.type == LogType.addomeGonfio ||
          l.signs.contains(Sign.conati) ||
          l.signs.contains(Sign.addomeGonfio),
    );
    final surgerySoon = store.records.any(
      (r) =>
          r.dogId == dog.id &&
          r.type == RecordType.intervento &&
          !r.done &&
          r.date.isAfter(now) &&
          r.date.difference(now).inHours <= 24,
    );
    if (unsafe || surgerySoon || dog.reproAt(now) == ReproState.allattamento) {
      return false;
    }
    final meals = Nutrition.plan(dog, now).meals;
    final today = logs
        .where(
          (l) =>
              l.type == LogType.pasto &&
              l.time.year == now.year &&
              l.time.month == now.month &&
              l.time.day == now.day,
        )
        .length;
    if (today >= meals) return false; // anche il cane a dieta: pasti fatti
    final habitual = store.model(dog, Need.cacca, now).habitualMealMinutes(now);
    final nowMin = now.hour * 60 + now.minute;
    final due = habitual.where((m) => m <= nowMin).length;
    return habitual.isNotEmpty && today < due;
  }
}

/// Schermo del compagno per la pagina Oggi.
class PetScreen extends StatelessWidget {
  const PetScreen({
    super.key,
    required this.dog,
    required this.pee,
    required this.alerts,
    this.onEdit,
  });
  final Dog dog;
  final Forecast pee;
  final List<HealthAlert> alerts;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final t = Theme.of(context);
    // Con un allarme "subito" il compagno lascia il posto a una scheda
    // rossa statica: una cosa seria non deve sembrare un gioco (07 N39).
    if (alerts.any((a) => a.level == AlertLevel.subito)) {
      final tone = context.colors.subito;
      return Material(
        color: tone.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.alert),
          side: BorderSide(color: tone.accent, width: 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openEmergencies(context),
          child: Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Row(
              children: [
                Icon(tone.icon, color: tone.fg, size: 30),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Text(
                    'Situazione urgente: leggi le segnalazioni qui sopra',
                    style: t.textTheme.titleMedium?.copyWith(
                      color: tone.fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: tone.fg),
              ],
            ),
          ),
        ),
      );
    }
    final mood = PetMood.of(store, dog, now, pee, alerts);
    final night = PottyPredictor.inSleepWindow(dog, now);
    final logsToday = store
        .logsOf(dog.id)
        .where(
          (l) =>
              l.time.year == now.year &&
              l.time.month == now.month &&
              l.time.day == now.day,
        );
    final h12 = store
        .logsOf(dog.id)
        .where((l) => now.difference(l.time).inHours <= 12);
    final meals = Nutrition.plan(dog, now).meals;
    final mealsDone = logsToday.where((l) => l.type == LogType.pasto).length;
    final showMeals =
        dog.reproAt(now) != ReproState.allattamento &&
        !h12.any(
          (l) => l.type == LogType.vomito || l.type == LogType.ingestione,
        );
    // Uscite: solo passeggiate e pipì fuori casa; obiettivo dal modello.
    final outings = logsToday
        .where(
          (l) =>
              l.type == LogType.passeggiata ||
              (l.type == LogType.pipi && !l.indoor),
        )
        .length;
    final rest =
        store.records.any(
          (r) =>
              r.dogId == dog.id &&
              r.type == RecordType.intervento &&
              r.done &&
              now.difference(r.date).inDays < 14,
        ) ||
        RegExp('riposo|ernia|frattura').hasMatch(dog.conditions.toLowerCase());
    final c = context.colors;
    final ink = night ? Palette.lcdNightInk : c.lcdInk;
    final lastPee = pee.last == null ? '—' : relative(pee.last!, now);
    return Semantics(
      container: true,
      label: '${dog.name}, il tuo compagno. ${mood.message}',
      child: CompanionDevice(
        night: night,
        margin: const EdgeInsets.symmetric(vertical: 6),
        overlay: [
          if (night)
            Positioned(
              left: 14,
              top: 12,
              child: ExcludeSemantics(
                child: Icon(
                  Icons.nightlight_round,
                  color: ink.withValues(alpha: 0.8),
                  size: 20,
                ),
              ),
            ),
          if (mood.bubble != null)
            Positioned(
              right: 14,
              top: 10,
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Palette.pixelInk, width: 2),
                  ),
                  child: Icon(mood.bubble, size: 22, color: Palette.pixelInk),
                ),
              ),
            ),
        ],
        footer: [
          const SizedBox(height: Space.m),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.xs),
            child: ExcludeSemantics(
              child: Text(
                mood.message,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: t.colorScheme.onSurface),
              ),
            ),
          ),
          const SizedBox(height: Space.m),
          _StatRow(
            children: [
              _Stat(
                icon: Icons.water_drop_outlined,
                label: 'Ultima pipì',
                text: lastPee,
              ),
              if (showMeals)
                _Stat(
                  icon: Icons.rice_bowl_outlined,
                  label: 'Pasti',
                  text: '$mealsDone/$meals',
                ),
              if (!rest)
                _Stat(
                  icon: Icons.directions_walk,
                  label: 'Uscite oggi',
                  text: '$outings',
                ),
              if (rest)
                const _Stat(
                  icon: Icons.healing_outlined,
                  label: 'Riposo',
                  text: 'solo bisogni',
                ),
            ],
          ),
          if (onEdit != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.brush_outlined),
                label: const Text('Cambia aspetto'),
                onPressed: onEdit,
              ),
            ),
        ],
        child: ExcludeSemantics(
          child: PixelDogView(
            look: dog.look,
            pose: mood.pose,
            night: night,
            height: 200,
          ),
        ),
      ),
    );
  }
}

/// La "console" del compagno: corpo color salvia, schermo LCD con cornice.
/// È l'unico elemento giocoso dell'app e non usa mai i colori degli
/// allarmi (rapporto 16, §5.4).
class CompanionDevice extends StatelessWidget {
  const CompanionDevice({
    super.key,
    required this.child,
    this.night = false,
    this.overlay = const [],
    this.footer = const [],
    this.margin = EdgeInsets.zero,
  });
  final Widget child;
  final bool night;
  final List<Widget> overlay;
  final List<Widget> footer;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(Space.m, Space.m, Space.m, Space.s),
      decoration: BoxDecoration(
        color: c.deviceBody,
        borderRadius: BorderRadius.circular(Radii.companion),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: night ? Palette.lcdNight : c.lcd,
              borderRadius: BorderRadius.circular(Radii.card),
              border: Border.all(color: c.deviceBezel, width: 3),
              boxShadow: [
                // Leggera ombra interna simulata: lo schermo sembra incassato.
                BoxShadow(
                  color: Colors.black.withValues(alpha: c.dark ? 0.35 : 0.08),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 8, 6),
                  child: child,
                ),
                ...overlay,
              ],
            ),
          ),
          ...footer,
        ],
      ),
    );
  }
}

/// Indicatori in colonne uguali; con il testo molto grande, uno sotto
/// l'altro.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(10) > 15) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in children)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: c,
            ),
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: Space.s),
            Expanded(child: children[i]),
          ],
        ],
      ),
    );
  }
}

/// Valore del compagno: un numero da leggere, non una barra da riempire
/// (07 N42).
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.text});
  final IconData icon;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label: $text',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: t.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(Radii.chip),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: t.colorScheme.secondary),
                  const SizedBox(width: 4),
                  Flexible(child: Text(label, style: t.textTheme.labelMedium)),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: t.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
