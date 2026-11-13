#!/usr/bin/env python3
"""Anteprima delle varianti del logo di Pellovi (P-cane), per la scelta.

Uso: python3 tool/anteprima_logo.py docs/brand/anteprima-logo-pellovi.png
Per ogni variante: icona a 512, 192, 96 e 48 px (le ultime a grandezza
reale), icona arrotondata come su Android, logo esteso chiaro e scuro.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw, ImageFont  # noqa: E402

import marchi  # noqa: E402

RADICE = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
FONT = os.path.join(RADICE, 'assets/fonts/AtkinsonHyperlegibleNext-ExtraBold.ttf')
FONT_TESTO = os.path.join(RADICE, 'assets/fonts/AtkinsonHyperlegibleNext-Bold.ttf')

VARIANTI = [
    ('p-pixel', 'A · P-cane in pixel art'),
    ('p-fiocchi', 'B · P-cane a fiocchi (bolognese)'),
    ('p-geometrica', 'C · P-cane geometrica'),
]


def scritta(nome, sfondo, colore, accento, altezza=120):
    """Logo esteso: il segno fa da P, seguito da «ellovi»."""
    segno, base = marchi.segno_scritta(nome, altezza, colore, accento, sfondo)
    font = ImageFont.truetype(FONT, 10)
    # Il segno è alto quanto le aste di «ellovi» (la «l»).
    for size in range(40, 400, 2):
        font = ImageFont.truetype(FONT, size)
        bb = font.getbbox('l')
        if bb[3] - bb[1] >= segno.height * base * 0.98:
            break
    testo = 'ellovi'
    tb = font.getbbox(testo)
    w = segno.width + int(size * 0.02) + tb[2] + 60
    h = segno.height + 60
    img = Image.new('RGBA', (w, h), sfondo + (255,))
    img.alpha_composite(segno, (30, 30))
    linea_base = 30 + int(segno.height * base)
    asc = font.getmetrics()[0]
    ImageDraw.Draw(img).text(
        (30 + segno.width + int(size * 0.02), linea_base - asc), testo,
        font=font, fill=colore)
    return img


def main(out):
    lati = [512, 192, 96, 48]
    righe = []
    for nome, titolo in VARIANTI:
        disegna = marchi.MARCHI[nome]
        icone = [disegna(l) for l in lati]
        tonda = disegna(192, quota=0.9, raggio=0.22)
        chiaro = scritta(nome, marchi.CREMA_FONDO, marchi.CORALLO, (255, 196, 180))
        scuro = scritta(nome, marchi.NOTTE, marchi.BIANCO, (238, 226, 207))
        righe.append((titolo, icone, tonda, chiaro, scuro))

    W = 1900
    H = sum(80 + 512 + 40 for _ in righe) + 40
    tela = Image.new('RGB', (W, H), (246, 240, 235))
    d = ImageDraw.Draw(tela)
    ft = ImageFont.truetype(FONT, 40)
    fp = ImageFont.truetype(FONT_TESTO, 22)
    y = 30
    for titolo, icone, tonda, chiaro, scuro in righe:
        d.text((40, y), titolo, font=ft, fill=(30, 23, 20))
        y += 70
        x = 40
        for img, lato in zip(icone, [512, 192, 96, 48]):
            tela.paste(img, (x, y), img)
            d.text((x, y + img.height + 6), f'{lato} px', font=fp, fill=(92, 80, 73))
            x += img.width + 30
        tela.paste(tonda, (x, y), tonda)
        d.text((x, y + 198), 'Android', font=fp, fill=(92, 80, 73))
        x += 222
        for i, logo in enumerate((chiaro, scuro)):
            k = min((W - x - 40) / logo.width, 230 / logo.height)
            l2 = logo.resize((int(logo.width * k), int(logo.height * k)), Image.LANCZOS)
            tela.paste(l2, (x, y + i * 260), l2)
        y += 512 + 50
    tela.save(out, optimize=True)
    print(out)


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'anteprima-logo-pellovi.png')
