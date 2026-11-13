import 'package:flutter/material.dart';

/// Icone della barra in basso in pixel art (16x16), colorate come emoji ma
/// uguali su Android, iPhone e web, anche offline. Decorative: la voce la dà
/// l'etichetta della scheda.
class PixelIcon extends StatelessWidget {
  const PixelIcon(this.kind, {super.key, this.size = 26});
  final NavIcon kind;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(size),
      painter: _PixelIconPainter(_icons[kind]!),
    ),
  );
}

enum NavIcon { casa, zampa, stetoscopio, pappa, profilo }

const _palette = <String, Color>{
  'r': Color(0xFFD64430), // tetto
  'c': Color(0xFF8C5A3C), // comignolo
  'w': Color(0xFFF6E2BE), // muri
  'W': Color(0xFFDEC496),
  'd': Color(0xFF7A4E2E), // porta
  'b': Color(0xFF78BEEB), // finestra
  'B': Color(0xFF2E6EC8), // zampa
  'g': Color(0xFF46A0AA), // stetoscopio
  'G': Color(0xFF2A7882),
  's': Color(0xFFD7DEE4),
  'm': Color(0xFFE87878), // carne
  'M': Color(0xFFC85050),
  'o': Color(0xFFE2BE96), // osso (visibile su barra chiara e scura)
  'p': Color(0xFF4285F4), // persona
  'P': Color(0xFF265ABE),
};

const _icons = <NavIcon, List<String>>{
  NavIcon.casa: [
    '................',
    '.......rr...cc..',
    '......rrrr..cc..',
    '.....rrrrrr.cc..',
    '....rrrrrrrrcc..',
    '...rrrrrrrrrr...',
    '..rrrrrrrrrrrr..',
    '.rrrrrrrrrrrrrr.',
    '..wwwwwwwwwwww..',
    '..wwbbwwwwwwww..',
    '..wwbbwwwddwww..',
    '..wwwwwwwddwww..',
    '..wwwwwwwddwww..',
    '..wwwwwwwddwww..',
    '..WWWWWWWWWWWW..',
    '................',
  ],
  NavIcon.zampa: [
    '................',
    '....BB....BB....',
    '...BBBB..BBBB...',
    '...BBBB..BBBB...',
    'BB..BB....BB..BB',
    'BBB..........BBB',
    'BBB...BBBB...BBB',
    '.B...BBBBBB...B.',
    '....BBBBBBBB....',
    '...BBBBBBBBBB...',
    '...BBBBBBBBBB...',
    '...BBBBBBBBBB...',
    '....BBB..BBB....',
    '................',
    '................',
    '................',
  ],
  NavIcon.stetoscopio: [
    '................',
    '..GG.......GG...',
    '..GG.......GG...',
    '..gg.......gg...',
    '..gg.......gg...',
    '..gg.......gg...',
    '...gg.....gg....',
    '....ggg.ggg.....',
    '......ggg.......',
    '......gg........',
    '......gg...ss...',
    '......gg..sGGs..',
    '.......gg.sGGs..',
    '........gggss...',
    '................',
    '................',
  ],
  NavIcon.pappa: [
    '................',
    '..........oo....',
    '.........oooo...',
    '.........oo.o...',
    '......mmMoo.....',
    '....mmmmmMM.....',
    '...mmmmmmmmM....',
    '..mmmmmmmmmM....',
    '..mmmmmmmmmM....',
    '..mmmmmmmmM.....',
    '...mmmmmmM......',
    '....MMMMM.......',
    '................',
    '................',
    '................',
    '................',
  ],
  NavIcon.profilo: [
    '................',
    '......pppp......',
    '.....pppppp.....',
    '.....pppppp.....',
    '.....pppppp.....',
    '.....pppppp.....',
    '......pppp......',
    '................',
    '....pppppppp....',
    '...pppppppppp...',
    '..pppppppppppp..',
    '..pppppppppppp..',
    '..pppppppppppp..',
    '..PPPPPPPPPPPP..',
    '................',
    '................',
  ],
};

class _PixelIconPainter extends CustomPainter {
  const _PixelIconPainter(this.rows);
  final List<String> rows;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 16;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < rows.length; y++) {
      final row = rows[y];
      for (var x = 0; x < row.length; x++) {
        final c = _palette[row[x]];
        if (c == null) continue;
        paint.color = c;
        canvas.drawRect(
          Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PixelIconPainter old) => old.rows != rows;
}
