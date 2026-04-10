// Aile Cüzdanı — Service Worker
const CACHE = 'aile-cuzdani-v1';

self.addEventListener('install', e => self.skipWaiting());
self.addEventListener('activate', e => e.waitUntil(self.clients.claim()));

// Push bildirimi al
self.addEventListener('push', e => {
  const data = e.data ? e.data.json() : {};
  e.waitUntil(
    self.registration.showNotification(data.title || 'Aile Cüzdanı', {
      body: data.body || '',
      icon: data.icon || '/aile-cuzdani/icon-192.png',
      badge: '/aile-cuzdani/icon-192.png',
      tag: data.tag || 'taksit',
      data: { url: data.url || '/aile-cuzdani/' }
    })
  );
});

// Bildirime tıklanınca uygulamayı aç
self.addEventListener('notificationclick', e => {
  e.notification.close();
  e.waitUntil(
    clients.matchAll({ type: 'window' }).then(list => {
      for (const c of list) {
        if (c.url.includes('aile-cuzdani') && 'focus' in c) return c.focus();
      }
      return clients.openWindow(e.notification.data?.url || '/aile-cuzdani/');
    })
  );
});

// Günlük alarm — her sabah 08:00'de taksit kontrolü
self.addEventListener('periodicsync', e => {
  if (e.tag === 'taksit-kontrol') {
    e.waitUntil(taksitKontrol());
  }
});

async function taksitKontrol() {
  // Bu fonksiyon index.html'den tetiklenir, SW sadece bildirimi gösterir
}
