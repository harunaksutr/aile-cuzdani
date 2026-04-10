# Demo Kurulumu

Bu rehber, ekran goruntusu almak icin hizli bir demo hesabi ve demo veri kurar.

## 1) Demo kullanici olustur

Supabase -> Authentication -> Users:

- `demo@ailecuzdani.app` benzeri bir e-posta ile kullanici olustur
- sifre ver
- **UID** degerini kopyala

## 2) Demo verileri ekle

`supabase-demo-seed.sql` dosyasini ac:

- `demo_owner` satirindaki UUID'yi kendi demo UID ile degistir
- SQL Editor'da scripti calistir

## 3) Demo giris

- `landing.html` -> Giris
- Demo e-posta/sifre ile oturum ac
- Varsayilan demo uyeler: **Ahmet** ve **Ayse**
- Dashboard, Islemler, Taksitler ve Ayarlar ekranlarindan screenshot al

## 4) Screenshot onerisi

- Dashboard (metrik + grafikler)
- Islemler (satir ici duzenleme acikken)
- Taksitler (bekleyen odemeler)
- Ekstre Yukle (tablo gorunumu)

## Not

Script tekrar calistirilabilir. `members/categories/budgets` tarafinda `ON CONFLICT` ile guncelleme yapar.
