#!/usr/bin/env python3
"""Icone di Pellovi da un unico disegno (tool/marchi.py).

Genera tutte le icone (web, Android normali e adaptive, iOS, macOS, Windows).
Per cambiare logo basta scegliere un altro disegno in tool/marchi.py:

  python3 tool/gen_icons.py                      # marchio predefinito
  python3 tool/gen_icons.py --marchio p-pixel    # un altro marchio
  python3 tool/gen_icons.py --anteprima file.png # anche l'anteprima

I disegni in pixel art si ingrandiscono per multipli interi, senza smussare.
Serve Pillow (pip install pillow).
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw  # noqa: E402

N = 32  # lato della griglia

from marchi import MARCHI, MARCHIO_PREDEFINITO, CORALLO as SFONDO, disegno_lulu, _immagine_pixel

MARCHIO = MARCHIO_PREDEFINITO


def icona(lato, quota=0.86, raggio=0.0, sfondo=SFONDO, trasparente=False):
    """Icona del marchio scelto (tool/marchi.py)."""
    return MARCHI[MARCHIO](lato, quota, raggio, sfondo, trasparente)


def faccia(scala):
    """Il muso di Lulù (la mascotte), per le pagine e le prove."""
    px, n = disegno_lulu()
    return _immagine_pixel(px, n, scala)


def salva(img, percorso, rgb=False):
    os.makedirs(os.path.dirname(percorso) or '.', exist_ok=True)
    (img.convert('RGB') if rgb else img).save(percorso)


def main():
    global MARCHIO
    if '--marchio' in sys.argv:
        MARCHIO = sys.argv[sys.argv.index('--marchio') + 1]
        if MARCHIO not in MARCHI:
            print(f'Marchi disponibili: {", ".join(MARCHI)}', file=sys.stderr)
            return
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

    if '--anteprima' in sys.argv:
        anteprima(sys.argv[sys.argv.index('--anteprima') + 1])
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
