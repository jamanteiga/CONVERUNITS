// Conversor de unidades - Service Worker
// Cambia CACHE_VERSION cuando quieras forzar la renovación de la caché.
const CACHE_VERSION = 'convertunits-v1';
const CORE = ['./', 'index.html', 'manifest.webmanifest', 'icon-192.png', 'icon-512.png', 'icon-maskable-512.png', 'apple-touch-icon.png'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(CACHE_VERSION).then(c => c.addAll(CORE)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys => Promise.all(keys.filter(k => k !== CACHE_VERSION).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // Tipos de cambio: siempre red (la app ya guarda su propia copia)
  if (url.hostname === 'open.er-api.com') return;

  const isHtml = req.mode === 'navigate' || url.pathname.endsWith('.html') || url.pathname.endsWith('/');

  if (url.origin === self.location.origin && isHtml) {
    // Red primero (para recibir siempre la última versión), caché si no hay conexión
    e.respondWith(
      fetch(req).then(r => {
        const copy = r.clone();
        caches.open(CACHE_VERSION).then(c => c.put(req, copy));
        return r;
      }).catch(() => caches.match(req).then(r => r || caches.match('index.html')))
    );
    return;
  }

  // Resto (iconos, manifest, CSS/SVG de banderas en cdnjs): caché y actualiza en segundo plano
  e.respondWith(
    caches.match(req).then(cached => {
      const net = fetch(req).then(r => {
        if (r && (r.ok || r.type === 'opaque')) {
          const copy = r.clone();
          caches.open(CACHE_VERSION).then(c => c.put(req, copy));
        }
        return r;
      }).catch(() => cached);
      return cached || net;
    })
  );
});
