# Auth ve ilk kurulum

Bu projede giris/kayit ve kullanici bazli veri izolasyonu vardir.

## Dosyalar

| Dosya | Amac |
|--------|------|
| `supabase-v2-schema.sql` | V2 tablo kurulumu + tum tablolarda RLS policy |
| `supabase-v2-verify.sql` | V2 migration sonrasi dogrulama sorgulari |
| `supabase-backfill-owner-template.sql` | Eski veriyi tek kullaniciya baglama sablonu |
| `supabase-fix-categories-unique.sql` | `categories_ad_key` / global slug hatasina kalici cozum |

## 1) Supabase SQL

1. Supabase Dashboard > **SQL Editor** > yeni sorgu.
2. `supabase-v2-schema.sql` icerigini yapistirip **Run**.
3. Hata alirsan:
   - Tablo adlari farkliysa (ornegin `public.transaction`) once tablolari duzelt veya scriptte isimleri degistir.
   - Eski **RLS policy** isimleri cakisiyorsa: `pg_policies` ile listele, gereksizleri sil, scripti tekrar calistir.

## 2) Auth ayarlari

- **Authentication** > **Providers** > **Email** acik olmali.
- Hizli test icin **Confirm email** kapali olabilir (uretimde acmayi dusun).

## 3) Kullanici UUID (backfill icin)

- **Authentication** > **Users** > kullaniciya tikla > **User UID** kopyala.
- Eski veriyi bu kullaniciya baglamak icin `supabase-backfill-owner-template.sql` sablonunu kullan.

## 4) Uygulama akisi

- Token yoksa auth ekrani acilir.
- Kayit veya giris sonrasi:
  - `members` veya `categories` bos ise **Ilk kurulum** acilir.
  - Kurulum bitince varsayilan kategoriler ve uyeler olusturulur.

## 5) Veri izolasyonu

Asagidaki tablolarda tum istekler `owner_id = auth.uid()` ile sinirlanir:

- `transactions`, `installments`, `loans`, `budgets`, `categories`, `members`

Baska kullanicinin satirlari gorunmez.

## 6) Migration sonrasi dogrulama

`supabase-v2-verify.sql` dosyasini calistir:

- Her tabloda `owner_id` kolonu gorunmeli.
- `rls_acik` true olmali.
- Policy isimleri `*_owner_*` ile uyumlu olmali.
- `bos_owner` sayisi: yeni hesaplar icin 0 beklenir; eski veri icin backfill oncesi yuksek olabilir.

---

## Canli test checklist

Asagidakileri sirayla dene; her adimda beklenen sonucu kontrol et.

### A — Oncelik (Supabase)

- [ ] `supabase-v2-schema.sql` hatasiz calisti.
- [ ] `supabase-v2-verify.sql` ile kolonlar ve RLS gorunuyor.

### B — Yeni kullanici (sifir veri)

- [ ] `index.html` ac; auth ekrani gorunuyor.
- [ ] **Kayit ol** ile yeni e-posta + sifre (min. 6 karakter).
- [ ] Giris sonrasi **Ilk kurulum** ekrani aciliyor (veya zaten doluysa atlanir).
- [ ] Ilk kurulumu tamamla; Dashboard yukleniyor, hata toast yok.
- [ ] **Ayarlar** > uyeler ve kategoriler listeleniyor.
- [ ] **+ Ekle** ile bir islem kaydet; **Islemler** veya Dashboard’da gorunuyor.

### C — Izolasyon (ikinci kullanici)

- [ ] Cikis yap veya gizli pencere / baska tarayici ac.
- [ ] Baska e-posta ile kayit ol.
- [ ] Ilk kullanicinin islemlerini **gormemelisin** (bos veya sadece kendi verisi).

### D — Alt sayfalar

- [ ] `ekstre.html` — giris yokken `index.html`’e yonleniyor; giris sonrasi PDF akisi aciliyor.
- [ ] `backup.html` — giris yokken yonlenme; giris sonrasi export/import calisiyor.

### E — Cikis

- [ ] **Cikis** ile token temizleniyor, sayfa yenilenince tekrar auth ekrani geliyor.

---

## Sorun giderme

| Belirti | Olası neden | Ne yap |
|--------|-------------|--------|
| `permission denied` veya bos liste | RLS kapali veya policy eksik | Scripti tekrar calistir; `pg_policies` kontrol et |
| Eski veri gorunmuyor | `owner_id` null | Backfill sablonunu kullan |
| Kayit sonrasi giris hatasi | Email onayi acik | Auth ayarlarinda onayi gecici kapat veya maili dogrula |
| FK hatasi | `owner_id` baska tabloya referans veriyor | Once backfill ile gecerli user uuid yaz |

---

## Eski veriyi tek kullaniciya baglama

`supabase-backfill-owner-template.sql` icindeki yorumlari kaldirip UUID’yi yapistir; calistir. Sonra istege bagli `NOT NULL` satirlarini ac.

---

## GitHub Pages + e-posta onayi (localhost’a gitme sorunu)

E-posta dogrulama linki veya sifre sifirlama **Site URL**’e gider. Supabase varsayilan olarak `http://localhost:3000` kullanabilir; bu yuzden onay linki yanlis adrese gider.

**Supabase Dashboard** > **Authentication** > **URL Configuration**:

| Alan | Deger (bu proje icin) |
|------|------------------------|
| **Site URL** | `https://www.familywallet.co/` |
| **Redirect URLs** | `https://www.familywallet.co/**` ve `https://www.familywallet.co/index.html` |

Kaydet. Sonra **yeni** bir onay maili iste (veya `Authentication` > `Users` > kullanici > **Send magic link** / sifirdan kayit). Eski maildeki link hala localhost ise calismaz.

Uygulama `#access_token=...` hash’ini okuyup oturumu acar; ek ayar gerekmez.

---

## Hata: `42830 there is no unique constraint matching given keys for referenced table "categories"`

Foreign key, `CREATE UNIQUE INDEX ... WHERE` ile olusturulan **kismi index**e baglanamaz; PostgreSQL **UNIQUE constraint** (veya PK) ister. Guncel `supabase-fix-categories-unique.sql` bunu `ALTER TABLE ... ADD CONSTRAINT ... UNIQUE (owner_id, ad)` ile cozer.

## Hata: `cannot drop constraint categories_ad_key ... transactions_kategori_fkey depends on it`

`categories(ad)` uzerindeki unique, `transactions.kategori` foreign key tarafindan kullaniliyor. Guncel `supabase-fix-categories-unique.sql` once bu FK'yi guvenli sekilde kaldirır, sonra unique'i degistirir ve FK'yi `(owner_id, kategori) -> (owner_id, ad)` olarak yeniden kurar.

## Hata: `duplicate key value violates unique constraint "categories_ad_key"`

`categories` tablosunda `ad` **tum proje icin tekil** tanimli. Baska kullanicinin `market` kaydi varken senin hesabin ayni adi ekleyemez.

**Cozum:** SQL Editor’da `supabase-fix-categories-unique.sql` dosyasini calistir (categories + members icin owner bazli unique).

Sonra [uygulama](https://www.familywallet.co/) uzerinden **Kurulumu Tamamla**’yi tekrar dene.
