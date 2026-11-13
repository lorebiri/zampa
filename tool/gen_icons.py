#!/usr/bin/env python3
"""Logo di Lulù: muso di un bolognese in pixel art (griglia 32x32).

Genera tutte le icone (web, Android normali e adaptive, iOS, macOS, Windows)
ingrandendo sempre per multipli interi, senza smussare (nearest neighbor).

Uso: python3 tool/gen_icons.py [--anteprima percorso.png]
Serve Pillow (pip install pillow).
"""
import math
import os
import sys

from PIL import Image, ImageDraw

N = 32  # lato della griglia

# Tavolozza
SFONDO = (242, 107, 79)        # corallo caldo: il bianco stacca
BIANCO = (255, 255, 255)
CREMA = (238, 226, 207)        # ombre dei fiocchi
CREMA_SCURA = (214, 196, 170)  # ombre più profonde (orecchie)
CONTORNO = (122, 92, 74)       # contorno caldo, si legge anche a 48 px
NERO = (24, 18, 18)
LUCE = (255, 255, 255)
GUANCE = (248, 170, 160)
LINGUA = (231, 111, 138)


def _cerchio(cx, cy, r):
    return {(x, y) for x in range(N) for y in range(N)
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r}


def disegno():
    """Restituisce {(x, y): colore} della faccia (il resto è trasparente)."""
    # Orecchie: lunghe e pelose, scendono ai lati.
    orecchio_s = _cerchio(7.0, 19.0, 5.6) | _cerchio(6.5, 24.0, 4.6)
    orecchio_d = {(N - 1 - x, y) for (x, y) in orecchio_s}
    # Testa: nuvola di pelo con tre ciuffi in alto.
    testa = (_cerchio(16.0, 16.5, 10.2) | _cerchio(10.5, 8.0, 4.4)
             | _cerchio(16.0, 6.5, 4.6) | _cerchio(21.5, 8.0, 4.4)
             | _cerchio(16.0, 23.0, 7.0))
    forma = testa | orecchio_s | orecchio_d
    px = {}
    for p in forma:
        px[p] = BIANCO
    # Orecchie leggermente crema, staccate dalla testa da ombre.
    for (x, y) in orecchio_s | orecchio_d:
        if (x, y) not in testa:
            px[(x, y)] = BIANCO if (x + y) % 5 else CREMA
    for (x, y) in forma:
        if (x, y) in testa and ((x - 1, y) in orecchio_s - testa or
                                (x + 1, y) in orecchio_d - testa):
            px[(x, y)] = CREMA
    # Fiocchi: archetti crema (ricci del pelo).
    ricci = [(9, 5), (15, 3), (21, 5), (6, 11), (25, 11), (12, 11), (19, 11),
             (4, 18), (27, 18), (3, 23), (28, 23), (5, 27), (26, 27),
             (9, 26), (22, 26), (15, 28)]
    for (x, y) in ricci:
        for (dx, dy) in ((0, 0), (1, 0), (-1, 1)):
            if (x + dx, y + dy) in forma:
                px[(x + dx, y + dy)] = CREMA
    # Ombra in basso a destra di ogni bordo: volume.
    for (x, y) in list(forma):
        if (x, y + 1) not in forma or (x + 1, y + 1) not in forma:
            if px[(x, y)] == BIANCO:
                px[(x, y)] = CREMA
    # Occhi: rotondi, neri, grandi, con un punto di luce.
    for ox in (10, 19):
        for (dx, dy) in [(1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (3, 1),
                         (0, 2), (1, 2), (2, 2), (3, 2), (1, 3), (2, 3)]:
            px[(ox + dx, 14 + dy)] = NERO
        px[(ox + 1, 15)] = LUCE
    # Tartufo nero con riflesso.
    for (x, y) in [(14, 19), (15, 19), (16, 19), (17, 19),
                   (14, 20), (15, 20), (16, 20), (17, 20), (15, 21), (16, 21)]:
        px[(x, y)] = NERO
    px[(15, 19)] = (90, 80, 80)
    # Bocca e lingua.
    for (x, y) in [(15, 22), (16, 22), (14, 23), (17, 23), (13, 23), (18, 23)]:
        px[(x, y)] = CONTORNO
    px[(15, 23)] = LINGUA
    px[(16, 23)] = LINGUA
    px[(15, 24)] = LINGUA
    px[(16, 24)] = LINGUA
    # Guance.
    for (x, y) in [(8, 20), (9, 20), (22, 20), (23, 20)]:
        px[(x, y)] = GUANCE
    # Contorno esterno: pixel vuoti accanto alla forma.
    for x in range(N):
        for y in range(N):
            if (x, y) in forma:
                continue
            vicini = [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
            if any(v in forma for v in vicini):
                px[(x, y)] = CONTORNO
    return px


def faccia(scala):
    """La faccia ingrandita di un fattore intero, sfondo trasparente."""
    img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    for (x, y), c in disegno().items():
        if 0 <= x < N and 0 <= y < N:
            img.putpixel((x, y), c + (255,))
    return img.resize((N * scala, N * scala), Image.NEAREST)


def icona(lato, quota=0.86, raggio=0.0, sfondo=SFONDO, trasparente=False):
    """Icona quadrata: faccia alla scala intera più grande che sta in quota."""
    scala = max(1, math.floor(lato * quota / N))
    if N * scala > lato:
        # Solo per icone più piccole della griglia (16, 20, 29 px).
        f = faccia(1).resize((lato, lato), Image.NEAREST)
    else:
        f = faccia(scala)
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
    off = ((lato - f.width) // 2, (lato - f.height) // 2)
    img.alpha_composite(f, off)
    return img


def salva(img, percorso, rgb=False):
    os.makedirs(os.path.dirname(percorso) or '.', exist_ok=True)
    (img.convert('RGB') if rgb else img).save(percorso)


def main():
    radice = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')
    os.chdir(radice)

    # Web
    salva(icona(512), 'web/icons/Icon-512.png', rgb=True)
    salva(icona(192), 'web/icons/Icon-192.png', rgb=True)
    salva(icona(512, quota=0.64), 'web/icons/Icon-maskable-512.png', rgb=True)
    salva(icona(192, quota=0.67), 'web/icons/Icon-maskable-192.png', rgb=True)
    salva(icona(180), 'web/icons/apple-touch-icon.png', rgb=True)
    salva(icona(32, quota=1.0, raggio=0.2), 'web/favicon.png')
    faccia(16).save('web/icons/logo-faccia-512.png')

    # Android: icone classiche (mipmap) e adaptive (foreground + colore).
    for nome, lato in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96),
                       ('xxhdpi', 144), ('xxxhdpi', 192)]:
        salva(icona(lato, quota=0.9, raggio=0.22),
              f'android/app/src/main/res/mipmap-{nome}/ic_launcher.png')
    for nome, lato in [('mdpi', 108), ('hdpi', 162), ('xhdpi', 216),
                       ('xxhdpi', 324), ('xxxhdpi', 432)]:
        # Zona sicura: 66 dp su 108.
        salva(icona(lato, quota=66 / 108, trasparente=True),
              f'android/app/src/main/res/mipmap-{nome}/ic_launcher_foreground.png')

    # iOS (niente trasparenza, gli angoli li arrotonda il sistema).
    ios = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    if os.path.isdir(ios):
        for nome in os.listdir(ios):
            if nome.startswith('Icon-App-') and nome.endswith('.png'):
                misura, fattore = nome[len('Icon-App-'):-len('.png')].split('@')
                lato = round(float(misura.split('x')[0]) * int(fattore[:-1]))
                salva(icona(lato), f'{ios}/{nome}', rgb=True)

    # macOS
    mac = 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
    if os.path.isdir(mac):
        for lato in (16, 32, 64, 128, 256, 512, 1024):
            salva(icona(lato, raggio=0.22), f'{mac}/app_icon_{lato}.png')

    # Windows
    if os.path.isdir('windows/runner/resources'):
        icona(256, raggio=0.22).save(
            'windows/runner/resources/app_icon.ico',
            sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

    if len(sys.argv) > 2 and sys.argv[1] == '--anteprima':
        anteprima(sys.argv[2])
    print('Icone generate.')


def anteprima(percorso):
    """Le dimensioni principali affiancate, su fondo chiaro e scuro."""
    lati = [16, 32, 48, 96, 192, 512]
    w = sum(lati) + 40 * (len(lati) + 1)
    h = 512 * 2 + 40 * 3
    tela = Image.new('RGB', (w, h), (242, 244, 239))
    ImageDraw.Draw(tela).rectangle((0, h // 2, w, h), fill=(15, 23, 34))
    x = 40
    for lato in lati:
        i = icona(lato, quota=1.0 if lato <= 32 else 0.86,
                  raggio=0.22 if lato <= 96 else 0.0)
        tela.paste(i, (x, 40 + 512 - lato), i)
        m = icona(lato, quota=0.9, raggio=0.22)
        tela.paste(m, (x, h // 2 + 20 + 512 - lato), m)
        x += lato + 40
    tela.save(percorso)


if __name__ == '__main__':
    main()
