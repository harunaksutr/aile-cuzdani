-- Aile Cuzdani - budgets tekillik duzeltmesi
--
-- Hata:
-- duplicate key value violates unique constraint "budgets_ay_uye_kategori_key"
--
-- Neden:
-- Eski semada tekillik (ay, uye, kategori) idi; cok kullanicida cakisir.
-- Dogrusu owner bazli olmasi: (owner_id, ay, uye, kategori)
--
-- Supabase SQL Editor'da bir kez calistir.

ALTER TABLE public.budgets DROP CONSTRAINT IF EXISTS budgets_ay_uye_kategori_key;
DROP INDEX IF EXISTS public.budgets_ay_uye_kategori_key;
ALTER TABLE public.budgets DROP CONSTRAINT IF EXISTS budgets_owner_ay_uye_kategori_key;
ALTER TABLE public.budgets
  ADD CONSTRAINT budgets_owner_ay_uye_kategori_key
  UNIQUE (owner_id, ay, uye, kategori);

-- Kontrol
SELECT conname, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.budgets'::regclass
  AND contype = 'u'
ORDER BY conname;
