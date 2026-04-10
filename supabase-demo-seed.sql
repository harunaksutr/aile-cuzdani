-- Aile Cuzdani - Demo veri seed scripti
--
-- Kullanim:
-- 1) Supabase Authentication > Users'tan demo kullaniciyi olustur (ornegin demo@ailecuzdani.app).
-- 2) Kullanici UID'sini kopyala.
-- 3) Asagidaki demo_owner satirindaki UUID'yi degistir.
-- 4) SQL Editor'da scripti calistir.
--
-- Not: Script tekrar calistirilabilir (on conflict ile gunceller).

DO $$
DECLARE
  demo_owner uuid := '00000000-0000-0000-0000-000000000000'; -- BURAYI DEGISTIR
BEGIN
  IF demo_owner::text = '00000000-0000-0000-0000-000000000000' THEN
    RAISE EXCEPTION 'Lutfen demo_owner UUID degerini demo kullanici UIDsi ile degistirin.';
  END IF;

  -- Members
  INSERT INTO public.members (owner_id, slug, ad, renk, sira, aktif)
  VALUES
    (demo_owner, 'ahmet', 'Ahmet', '#378ADD', 1, true),
    (demo_owner, 'ayse',  'Ayse',  '#1D9E75', 2, true)
  ON CONFLICT (owner_id, slug)
  DO UPDATE SET ad = EXCLUDED.ad, renk = EXCLUDED.renk, sira = EXCLUDED.sira, aktif = EXCLUDED.aktif;

  -- Eski demo isimleri varsa pasife al (tekrarli listeleri engeller)
  UPDATE public.members
  SET aktif = false
  WHERE owner_id = demo_owner
    AND slug IN ('harun', 'asli')
    AND slug NOT IN ('ahmet', 'ayse');

  -- Categories
  INSERT INTO public.categories (owner_id, ad, renk, sira)
  VALUES
    (demo_owner, 'market',   '#378ADD', 1),
    (demo_owner, 'fatura',   '#1D9E75', 2),
    (demo_owner, 'restoran', '#EF9F27', 3),
    (demo_owner, 'ulasim',   '#D85A30', 4),
    (demo_owner, 'saglik',   '#7F77DD', 5),
    (demo_owner, 'diger',    '#888780', 6)
  ON CONFLICT (owner_id, ad)
  DO UPDATE SET renk = EXCLUDED.renk, sira = EXCLUDED.sira;

  -- Budgets (bu ay + gecen ay)
  INSERT INTO public.budgets (owner_id, ay, uye, kategori, hedef, updated_at)
  VALUES
    (demo_owner, to_char(current_date, 'YYYY-MM'), 'hepsi', 'genel', 30000, now()),
    (demo_owner, to_char(current_date - interval '1 month', 'YYYY-MM'), 'hepsi', 'genel', 28000, now())
  ON CONFLICT (owner_id, ay, uye, kategori)
  DO UPDATE SET hedef = EXCLUDED.hedef, updated_at = EXCLUDED.updated_at;

  -- Transactions (son 2 ay)
  INSERT INTO public.transactions (owner_id, tarih, aciklama, tutar, kategori, kaynak, uye, notlar)
  VALUES
    (demo_owner, (current_date - 2)::text::date, 'Migros market', 1280.50, 'market', 'garanti', 'ahmet', ''),
    (demo_owner, (current_date - 4)::text::date, 'Elektrik faturasi', 640.00, 'fatura', 'otomatik_odeme', 'hepsi', ''),
    (demo_owner, (current_date - 6)::text::date, 'Yemek disari', 520.00, 'restoran', 'enpara', 'ayse', ''),
    (demo_owner, (current_date - 8)::text::date, 'Benzin', 1550.00, 'ulasim', 'yapı_kredi', 'ahmet', ''),
    (demo_owner, (current_date - 11)::text::date, 'Eczane', 390.00, 'saglik', 'nakit', 'ayse', ''),
    (demo_owner, (current_date - 15)::text::date, 'Pazar alisverisi', 860.00, 'market', 'nakit', 'hepsi', ''),
    (demo_owner, (current_date - interval '1 month' - interval '3 day')::date, 'Market toplu alisveris', 2100.00, 'market', 'garanti', 'ahmet', ''),
    (demo_owner, (current_date - interval '1 month' - interval '5 day')::date, 'Su faturasi', 280.00, 'fatura', 'havale', 'hepsi', ''),
    (demo_owner, (current_date - interval '1 month' - interval '10 day')::date, 'Kafe', 240.00, 'restoran', 'enpara', 'ayse', '');

  -- Installments (demo)
  INSERT INTO public.installments (owner_id, aciklama, tutar, kaynak, uye, toplam_taksit, kalan_taksit, taksit_no, son_odeme_tarihi, durum)
  VALUES
    -- Banner demo: 1 gecikmis + 1 yaklasan
    (demo_owner, 'Egitim odemesi', 1450.00, 'havale', 'ahmet', 6, 2, 5, (current_date - 3)::date, 'bekliyor'),
    (demo_owner, 'Kres taksiti', 920.00, 'havale', 'ayse', 10, 6, 5, (current_date + 4)::date, 'bekliyor'),
    -- Ekstre kaynakli taksit (banner filtresi nedeniyle gecikmiste gorunmez)
    (demo_owner, 'Telefon taksiti', 1250.00, 'garanti', 'ahmet', 12, 5, 8, (current_date + 5)::date, 'bekliyor')
  ON CONFLICT DO NOTHING;
END $$;
