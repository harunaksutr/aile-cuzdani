-- Aile Cuzdani - Ekstre importundan kalan yanlis "gecikmis" son taksitleri temizle
--
-- Ne yapar:
-- - Sadece ekstre kaynakli (enpara/garanti/yapi_kredi)
-- - Krediye bagli olmayan (loan_id IS NULL)
-- - Taksitli kayit (toplam_taksit > 1)
-- - Son taksit gorunen (kalan_taksit = 1)
-- - Hala bekliyor olan (durum = 'bekliyor')
-- satirlari "odendi" yapar ve kalan_taksit'i 0'a indirir.
--
-- Neden:
-- Eski import akisinda ekstrede gorunen (o ay odenmis) son taksit bazen
-- yanlislikla bekliyor olarak kalabiliyordu; bu da dashboard'da "gecikmis"
-- bildirimi uretiyordu.

-- 1) Once etkilenecek kayitlari gor (kontrol icin)
SELECT id, kaynak, aciklama, tutar, taksit_no, toplam_taksit, kalan_taksit, son_odeme_tarihi, durum
FROM public.installments
WHERE owner_id = auth.uid()
  AND loan_id IS NULL
  AND kaynak IN ('enpara', 'garanti', 'yapı_kredi')
  AND COALESCE(toplam_taksit, 0) > 1
  AND COALESCE(kalan_taksit, 0) = 1
  AND COALESCE(taksit_no, 0) >= COALESCE(toplam_taksit, 0)
  AND durum = 'bekliyor'
ORDER BY son_odeme_tarihi ASC;

-- 2) Duzelt
UPDATE public.installments
SET kalan_taksit = 0,
    durum = 'odendi'
WHERE owner_id = auth.uid()
  AND loan_id IS NULL
  AND kaynak IN ('enpara', 'garanti', 'yapı_kredi')
  AND COALESCE(toplam_taksit, 0) > 1
  AND COALESCE(kalan_taksit, 0) = 1
  AND COALESCE(taksit_no, 0) >= COALESCE(toplam_taksit, 0)
  AND durum = 'bekliyor';

-- 3) Sonuc kontrol
SELECT id, kaynak, aciklama, toplam_taksit, kalan_taksit, taksit_no, son_odeme_tarihi, durum
FROM public.installments
WHERE owner_id = auth.uid()
  AND loan_id IS NULL
  AND kaynak IN ('enpara', 'garanti', 'yapı_kredi')
  AND COALESCE(toplam_taksit, 0) > 1
  AND COALESCE(taksit_no, 0) >= COALESCE(toplam_taksit, 0)
ORDER BY son_odeme_tarihi DESC
LIMIT 50;
