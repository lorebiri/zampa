// Service worker di Lulù: l'app si apre anche senza rete.
//
// - Alla build, tool/pwa_finalize.py sostituisce VERSIONE e la lista
//   PRECACHE con i file veri di build/web (e un'impronta del loro contenuto):
//   a ogni nuova versione pubblicata la cache vecchia viene buttata.
// - Pagine (navigazione): prima la rete, senza rete la copia salvata.
// - Il resto dello stesso sito: prima la copia salvata, poi la rete.
// - Altri siti (account, meteo): mai in cache, passano diretti.
// - I file .apk non vengono mai messi in cache (sono grandi).
'use strict';

const VERSIONE = 'dev';
const PRECACHE = ['./', 'index.html', 'flutter_bootstrap.js', 'manifest.json'];

const CACHE = 'lulu-' + VERSIONE;
// Caratteri di riserva (emoji, simboli) che Flutter scarica da Google.
const FONT_HOSTS = ['fonts.gstatic.com'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE);
      // Uno alla volta: un file mancante non blocca l'installazione.
      await Promise.all(
        PRECACHE.map((url) =>
          cache.add(new Request(url, { cache: 'reload' })).catch((e) => {
            console.warn('Non salvato offline:', url, e);
          }),
        ),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys
          .filter((k) => k.startsWith('lulu-') && k !== CACHE)
          .map((k) => caches.delete(k)),
      );
      await self.clients.claim();
    })(),
  );
});

function shouldSkip(url) {
  return url.pathname.endsWith('.apk') || url.pathname.endsWith('/sw.js');
}

async function networkFirst(request) {
  const cache = await caches.open(CACHE);
  try {
    const response = await fetch(request);
    if (response && response.ok) {
      // La pagina principale si salva sempre con la stessa chiave.
      await cache.put(new URL('index.html', self.registration.scope), response.clone());
    }
    return response;
  } catch (e) {
    const cached =
      (await cache.match(new URL('index.html', self.registration.scope))) ||
      (await cache.match(self.registration.scope));
    if (cached) return cached;
    throw e;
  }
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE);
  const cached = await cache.match(request, { ignoreSearch: true });
  if (cached) return cached;
  const response = await fetch(request);
  if (response && (response.ok || response.type === 'opaque')) {
    cache.put(request, response.clone()).catch(() => {});
  }
  return response;
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);

  if (url.origin === self.location.origin) {
    if (shouldSkip(url)) return;
    // Pagine fuori dall'app (es. download.html) restano pagine normali.
    const isAppShell =
      request.mode === 'navigate' &&
      (url.href === self.registration.scope ||
        url.href.startsWith(self.registration.scope + 'index.html') ||
        url.href.startsWith(self.registration.scope + '#') ||
        url.href.startsWith(self.registration.scope + '?'));
    if (isAppShell) {
      event.respondWith(networkFirst(request));
    } else if (request.mode === 'navigate') {
      event.respondWith(
        fetch(request).catch(async () => {
          const cache = await caches.open(CACHE);
          return (await cache.match(request, { ignoreSearch: true })) || Response.error();
        }),
      );
    } else {
      event.respondWith(cacheFirst(request));
    }
    return;
  }

  if (FONT_HOSTS.includes(url.hostname)) {
    event.respondWith(cacheFirst(request));
  }
});
