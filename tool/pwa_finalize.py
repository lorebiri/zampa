#!/usr/bin/env python3
"""Completa la web app dopo `flutter build web` (vedi tool/build_web.sh).

- Scrive in build/web/sw.js la lista dei file da salvare per l'uso offline e
  un'impronta del loro contenuto (così ogni nuova versione svuota la cache).
- Scrive il numero di versione nella pagina di download.

Uso: python3 tool/pwa_finalize.py build/web [versione]
Solo libreria standard: gira su qualunque runner con Python 3.
"""
import hashlib
import json
import os
import re
import sys

# Mai in cache: grandi, generati da Flutter e non usati, o solo per l'hosting.
ESCLUSI_NOMI = {
    'sw.js', 'flutter_service_worker.js', '_headers', '_redirects',
    'version.json', '.last_build_id',
}
ESCLUSI_ESTENSIONI = ('.apk', '.map', '.symbols')
# Varianti del motore grafico che il browser non usa con una build JavaScript.
ESCLUSI_PREFISSI = ('canvaskit/skwasm', 'skwasm')


def da_salvare(rel: str) -> bool:
    nome = os.path.basename(rel)
    if nome in ESCLUSI_NOMI or nome.startswith('.'):
        return False
    if rel.endswith(ESCLUSI_ESTENSIONI):
        return False
    if rel.startswith(ESCLUSI_PREFISSI):
        return False
    return True


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    radice = sys.argv[1]
    versione = sys.argv[2] if len(sys.argv) > 2 else ''
    sw = os.path.join(radice, 'sw.js')
    if not os.path.isfile(sw):
        print(f'Manca {sw}: la build non contiene web/sw.js', file=sys.stderr)
        return 1

    file = []
    for cartella, _, nomi in os.walk(radice):
        for nome in nomi:
            rel = os.path.relpath(os.path.join(cartella, nome), radice)
            rel = rel.replace(os.sep, '/')
            if da_salvare(rel):
                file.append(rel)
    file.sort()

    impronta = hashlib.sha256()
    for rel in file:
        impronta.update(rel.encode())
        with open(os.path.join(radice, rel), 'rb') as f:
            impronta.update(hashlib.sha256(f.read()).digest())
    codice = impronta.hexdigest()[:16]

    # './' è la pagina principale come la apre la schermata Home.
    precache = ['./'] + file
    testo = open(sw, encoding='utf-8').read()
    testo, n1 = re.subn(r"^const VERSIONE = .*;$",
                        f"const VERSIONE = {json.dumps(codice)};",
                        testo, count=1, flags=re.M)
    testo, n2 = re.subn(r"^const PRECACHE = .*;$",
                        'const PRECACHE = ' + json.dumps(precache) + ';',
                        testo, count=1, flags=re.M)
    if n1 != 1 or n2 != 1:
        print('sw.js: righe VERSIONE/PRECACHE non trovate', file=sys.stderr)
        return 1
    open(sw, 'w', encoding='utf-8').write(testo)

    download = os.path.join(radice, 'download.html')
    if versione and os.path.isfile(download):
        pagina = open(download, encoding='utf-8').read()
        pagina = pagina.replace('__LULU_VERSIONE__', versione)
        open(download, 'w', encoding='utf-8').write(pagina)

    dimensione = sum(os.path.getsize(os.path.join(radice, r)) for r in file)
    print(f'sw.js: {len(file)} file per l\'uso offline '
          f'({dimensione / 1e6:.1f} MB), versione cache {codice}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
