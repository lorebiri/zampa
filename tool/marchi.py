"""Disegni del marchio di Pellovi, usati da tool/gen_icons.py.

Ogni marchio è una funzione `disegna(lato, quota, sfondo, trasparente)` che
restituisce un'immagine RGBA quadrata. Per cambiare logo basta aggiungere qui
un disegno e sceglierlo con `--marchio` (o cambiare MARCHIO_PREDEFINITO).

- lulu:        muso del bolognese (la mascotte), 32x32 in pixel art.
- p-pixel:     la P di Pellovi come profilo di cane, pixel art pulita.
- p-geometrica: la stessa idea con forme geometriche morbide.
- p-fiocchi:   P-cane in pixel art col pelo a fiocchi del bolognese.

I disegni in pixel art si ingrandiscono solo per multipli interi, senza
smussare (nearest neighbor); quello geometrico si disegna in grande e si
riduce con antialiasing.
"""
import math

from PIL import Image, ImageDraw

CORALLO = (242, 107, 79)
CORALLO_SCURO = (255, 138, 110)
NOTTE = (20, 16, 14)
CREMA_FONDO = (255, 247, 241)
BIANCO = (255, 255, 255)
CREMA = (238, 226, 207)
CREMA_SCURA = (214, 196, 170)
CONTORNO = (122, 92, 74)
NERO = (24, 18, 18)
LINGUA = (231, 111, 138)
GUANCE = (248, 170, 160)


# ---------------------------------------------------------------------------
# Strumenti comuni
# ---------------------------------------------------------------------------

def _cerchio(n, cx, cy, r):
    return {(x, y) for x in range(n) for y in range(n)
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r}


def _contorna(px, forma, n, colore=CONTORNO):
    for x in range(n):
        for y in range(n):
            if (x, y) in forma:
                continue
            if any(v in forma for v in [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]):
                px[(x, y)] = colore


def _da_griglia(righe, colori):
    """Griglia di caratteri -> {(x, y): colore}, con contorno automatico."""
    n = len(righe)
    px, forma = {}, set()
    for y, r in enumerate(righe):
        for x, c in enumerate(r):
            if c != '.':
                forma.add((x, y))
                px[(x, y)] = colori[c]
    _contorna(px, forma, n)
    return px, n


def _immagine_pixel(px, n, scala):
    img = Image.new('RGBA', (n, n), (0, 0, 0, 0))
    for (x, y), c in px.items():
        if 0 <= x < n and 0 <= y < n:
            img.putpixel((x, y), c + (255,))
    return img.resize((n * scala, n * scala), Image.NEAREST)


def _componi(segno, lato, raggio, sfondo, trasparente):
    img = Image.new('RGBA', (lato, lato), (0, 0, 0, 0))
    if not trasparente:
        bg = Image.new('RGBA', (lato, lato), sfondo + (255,))
        if raggio:
            mask = Image.new('L', (lato, lato), 0)
            ImageDraw.Draw(mask).rounded_rectangle(
                (0, 0, lato - 1, lato - 1), radius=int(lato * raggio), fill=255)
            img.paste(bg, (0, 0), mask)
        else:
            img = bg
    img.alpha_composite(segno, ((lato - segno.width) // 2, (lato - segno.height) // 2))
    return img


def icona_pixel(px, n, lato, quota=0.86, raggio=0.0, sfondo=CORALLO, trasparente=False):
    """Icona da un disegno in pixel art: scala intera più grande che sta in quota."""
    scala = max(1, math.floor(lato * quota / n))
    if n * scala > lato:  # solo icone più piccole della griglia
        segno = _immagine_pixel(px, n, 1).resize((lato, lato), Image.NEAREST)
    else:
        segno = _immagine_pixel(px, n, scala)
    return _componi(segno, lato, raggio, sfondo, trasparente)


# ---------------------------------------------------------------------------
# lulu: muso del bolognese (32x32)
# ---------------------------------------------------------------------------

def disegno_lulu():
    n = 32
    orecchio_s = _cerchio(n, 7.0, 19.0, 5.6) | _cerchio(n, 6.5, 24.0, 4.6)
    orecchio_d = {(n - 1 - x, y) for (x, y) in orecchio_s}
    testa = (_cerchio(n, 16.0, 16.5, 10.2) | _cerchio(n, 10.5, 8.0, 4.4)
             | _cerchio(n, 16.0, 6.5, 4.6) | _cerchio(n, 21.5, 8.0, 4.4)
             | _cerchio(n, 16.0, 23.0, 7.0))
    forma = testa | orecchio_s | orecchio_d
    px = {p: BIANCO for p in forma}
    for (x, y) in orecchio_s | orecchio_d:
        if (x, y) not in testa:
            px[(x, y)] = BIANCO if (x + y) % 5 else CREMA
    for (x, y) in forma:
        if (x, y) in testa and ((x - 1, y) in orecchio_s - testa or
                                (x + 1, y) in orecchio_d - testa):
            px[(x, y)] = CREMA
    ricci = [(9, 5), (15, 3), (21, 5), (6, 11), (25, 11), (12, 11), (19, 11),
             (4, 18), (27, 18), (3, 23), (28, 23), (5, 27), (26, 27),
             (9, 26), (22, 26), (15, 28)]
    for (x, y) in ricci:
        for (dx, dy) in ((0, 0), (1, 0), (-1, 1)):
            if (x + dx, y + dy) in forma:
                px[(x + dx, y + dy)] = CREMA
    for (x, y) in list(forma):
        if (x, y + 1) not in forma or (x + 1, y + 1) not in forma:
            if px[(x, y)] == BIANCO:
                px[(x, y)] = CREMA
    for ox in (10, 19):
        for (dx, dy) in [(1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1),
                         (0, 2), (1, 2), (2, 2), (3, 2), (1, 3), (2, 3)]:
            px[(ox + dx, 14 + dy)] = NERO
        px[(ox + 1, 15)] = BIANCO
    for (x, y) in [(14, 19), (15, 19), (16, 19), (17, 19),
                   (14, 20), (15, 20), (16, 20), (17, 20), (15, 21), (16, 21)]:
        px[(x, y)] = NERO
    px[(15, 19)] = (90, 80, 80)
    for (x, y) in [(15, 22), (16, 22), (14, 23), (17, 23), (13, 23), (18, 23)]:
        px[(x, y)] = CONTORNO
    for p in [(15, 23), (16, 23), (15, 24), (16, 24)]:
        px[p] = LINGUA
    for p in [(8, 20), (9, 20), (22, 20), (23, 20)]:
        px[p] = GUANCE
    _contorna(px, forma, n)
    return px, n


# ---------------------------------------------------------------------------
# p-pixel: la P come profilo di cane (20x20). Pancia della P = testa vista di
# lato (muso a destra, occhio, orecchio lungo a sinistra); asta = collo.
# ---------------------------------------------------------------------------

_P_PIXEL = [
    "....................",
    "....#########.......",
    "...###########......",
    "..#############.....",
    "..dc###########.....",
    ".dccc#####NN####....",
    ".dccc#####NN#######.",
    ".dccc############NN.",
    ".dccc############NN.",
    ".dccc#####o####oo...",
    "..dcc#####oooo#.....",
    "..dcc#########......",
    "...dcc###...........",
    "....dc##............",
    "....####............",
    "....####............",
    "....####............",
    "....####............",
    "...######...........",
    "....................",
]


def disegno_p_pixel():
    return _da_griglia(_P_PIXEL, {'#': BIANCO, 'c': CREMA, 'd': CREMA_SCURA,
                                  'N': NERO, 'o': CONTORNO})


# ---------------------------------------------------------------------------
# p-fiocchi: P-cane col pelo a fiocchi (24x24), orecchio lungo e riccio.
# ---------------------------------------------------------------------------

def disegno_p_fiocchi():
    n = 24
    testa = (_cerchio(n, 12.5, 8.5, 6.6) | _cerchio(n, 9.0, 4.2, 3.0)
             | _cerchio(n, 13.5, 3.0, 3.0) | _cerchio(n, 17.5, 5.0, 2.8))
    muso = _cerchio(n, 19.0, 10.0, 3.2) | _cerchio(n, 16.0, 11.5, 3.0)
    orecchio = (_cerchio(n, 5.8, 9.5, 2.8) | _cerchio(n, 5.5, 13.0, 2.8)
                | _cerchio(n, 6.2, 16.2, 2.4))
    asta = {(x, y) for x in range(7, 12) for y in range(12, 22)}
    piede = {(x, y) for x in range(6, 13) for y in range(21, 23)}
    forma = testa | muso | orecchio | asta | piede
    px = {p: BIANCO for p in forma}
    for p in orecchio:
        px[p] = CREMA
    for (x, y) in orecchio:
        if (x + 1, y) in forma and (x + 1, y) not in orecchio and x > 6:
            px[(x, y)] = CREMA_SCURA
    for (x, y) in [(10, 2), (11, 2), (14, 1), (15, 1), (17, 3), (8, 6), (6, 11), (5, 14)]:
        if (x, y) in forma:
            px[(x, y)] = CREMA
    for p in [(14, 7), (15, 7), (14, 8), (15, 8)]:
        px[p] = NERO
    px[(14, 7)] = (70, 60, 60)
    for p in [(21, 8), (22, 8), (21, 9), (22, 9)]:
        px[p] = NERO
    for p in [(17, 12), (18, 12), (19, 12)]:
        px[p] = CONTORNO
    _contorna(px, forma, n)
    return px, n


# ---------------------------------------------------------------------------
# p-geometrica: forme piene con antialiasing.
# ---------------------------------------------------------------------------

def segno_p_geometrica(dim, bianco=BIANCO, crema=CREMA, nero=NERO):
    k = 8  # disegno in grande, poi riduzione morbida
    s = dim * k
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    u = s / 20
    d.rounded_rectangle((4 * u, 8 * u, 9 * u, 19.5 * u), radius=2.5 * u, fill=bianco)
    d.ellipse((3 * u, 0.5 * u, 16 * u, 13.5 * u), fill=bianco)
    d.rounded_rectangle((11 * u, 5.5 * u, 19.5 * u, 11.2 * u), radius=2.8 * u, fill=bianco)
    d.ellipse((1 * u, 3 * u, 6.5 * u, 15.5 * u), fill=crema)
    d.ellipse((10.4 * u, 4.6 * u, 12.6 * u, 6.8 * u), fill=nero)
    d.ellipse((17.2 * u, 6.2 * u, 19.8 * u, 8.6 * u), fill=nero)
    return img.resize((dim, dim), Image.LANCZOS)


def icona_geometrica(lato, quota=0.86, raggio=0.0, sfondo=CORALLO, trasparente=False):
    return _componi(segno_p_geometrica(int(lato * quota)), lato, raggio, sfondo, trasparente)


# ---------------------------------------------------------------------------
# Registro dei marchi
# ---------------------------------------------------------------------------

def _pixel(fn):
    def disegna(lato, quota=0.86, raggio=0.0, sfondo=CORALLO, trasparente=False):
        px, n = fn()
        return icona_pixel(px, n, lato, quota, raggio, sfondo, trasparente)
    return disegna


MARCHI = {
    'lulu': _pixel(disegno_lulu),
    'p-pixel': _pixel(disegno_p_pixel),
    'p-fiocchi': _pixel(disegno_p_fiocchi),
    'p-geometrica': icona_geometrica,
}

MARCHIO_PREDEFINITO = 'lulu'


# ---------------------------------------------------------------------------
# Segno a due colori per il logo esteso (la P della scritta «Pellovi»)
# ---------------------------------------------------------------------------

_PIXEL = {'p-pixel': disegno_p_pixel, 'p-fiocchi': disegno_p_fiocchi,
          'lulu': disegno_lulu}


def segno_scritta(nome, altezza, colore, accento, sfondo):
    """Il segno a tinta piatta: corpo `colore`, orecchio `accento`, occhio e
    naso del colore dello `sfondo` (come buchi). Restituisce (immagine,
    frazione dall'alto della linea di base)."""
    if nome == 'p-geometrica':
        img = segno_p_geometrica(altezza, colore, accento, sfondo)
        return img, 19.5 / 20
    px, n = _PIXEL[nome]()
    mappa = {BIANCO: colore, CREMA: accento, CREMA_SCURA: accento, NERO: sfondo,
             (90, 80, 80): sfondo, (70, 60, 60): sfondo, LINGUA: colore,
             GUANCE: colore}
    piatto = {p: mappa[c] for p, c in px.items() if c in mappa}
    righe = [y for (_, y) in piatto]
    base = (max(righe) + 1) / n
    scala = max(1, round(altezza / n))
    return _immagine_pixel(piatto, n, scala), base
