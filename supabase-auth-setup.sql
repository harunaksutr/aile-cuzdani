-- ============================================================
-- Aile Cüzdanı — Auth Setup & RLS
-- Supabase SQL Editor'de bir kez çalıştır
-- ============================================================

-- ── 0) Mevcut çakışan policy'leri temizle ─────────────────
DO $$ 
DECLARE r RECORD;
BEGIN
  FOR r IN 
    SELECT policyname, tablename 
    FROM pg_policies 
    WHERE tablename IN ('transactions','installments','loans','budgets','categories','members')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I', r.policyname, r.tablename);
  END LOOP;
END $$;

-- ── 1) owner_id kolonları — zaten varsa atla ──────────────
ALTER TABLE transactions  ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE installments  ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE loans         ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE budgets        ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE categories    ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE members       ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;

-- ── 2) İndeksler ──────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_transactions_owner  ON transactions(owner_id);
CREATE INDEX IF NOT EXISTS idx_installments_owner  ON installments(owner_id);
CREATE INDEX IF NOT EXISTS idx_loans_owner         ON loans(owner_id);
CREATE INDEX IF NOT EXISTS idx_budgets_owner       ON budgets(owner_id);
CREATE INDEX IF NOT EXISTS idx_categories_owner    ON categories(owner_id);
CREATE INDEX IF NOT EXISTS idx_members_owner       ON members(owner_id);

-- ── 3) RLS aktifleştir ────────────────────────────────────
ALTER TABLE transactions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE installments  ENABLE ROW LEVEL SECURITY;
ALTER TABLE loans         ENABLE ROW LEVEL SECURITY;
ALTER TABLE budgets        ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories    ENABLE ROW LEVEL SECURITY;
ALTER TABLE members       ENABLE ROW LEVEL SECURITY;

-- ── 4) Policy'ler — her tablo için SELECT / INSERT / UPDATE / DELETE ──

-- TRANSACTIONS
CREATE POLICY txn_owner_select ON transactions FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY txn_owner_insert ON transactions FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY txn_owner_update ON transactions FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY txn_owner_delete ON transactions FOR DELETE USING (owner_id = auth.uid());

-- INSTALLMENTS
CREATE POLICY inst_owner_select ON installments FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY inst_owner_insert ON installments FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY inst_owner_update ON installments FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY inst_owner_delete ON installments FOR DELETE USING (owner_id = auth.uid());

-- LOANS
CREATE POLICY loans_owner_select ON loans FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY loans_owner_insert ON loans FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY loans_owner_update ON loans FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY loans_owner_delete ON loans FOR DELETE USING (owner_id = auth.uid());

-- BUDGETS
CREATE POLICY budgets_owner_select ON budgets FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY budgets_owner_insert ON budgets FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY budgets_owner_update ON budgets FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY budgets_owner_delete ON budgets FOR DELETE USING (owner_id = auth.uid());

-- CATEGORIES
CREATE POLICY cat_owner_select ON categories FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY cat_owner_insert ON categories FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY cat_owner_update ON categories FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY cat_owner_delete ON categories FOR DELETE USING (owner_id = auth.uid());

-- MEMBERS
CREATE POLICY mem_owner_select ON members FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY mem_owner_insert ON members FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY mem_owner_update ON members FOR UPDATE USING (owner_id = auth.uid()) WITH CHECK (owner_id = auth.uid());
CREATE POLICY mem_owner_delete ON members FOR DELETE USING (owner_id = auth.uid());

-- ── 5) Unique constraint'ler — owner bazlı ────────────────
-- categories: (owner_id, ad) unique olmalı
ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_ad_key;
ALTER TABLE categories DROP CONSTRAINT IF EXISTS categories_owner_ad_unique;
ALTER TABLE categories ADD CONSTRAINT categories_owner_ad_unique UNIQUE (owner_id, ad);

-- members: (owner_id, slug) unique olmalı  
ALTER TABLE members DROP CONSTRAINT IF EXISTS members_slug_key;
ALTER TABLE members DROP CONSTRAINT IF EXISTS members_owner_slug_unique;
ALTER TABLE members ADD CONSTRAINT members_owner_slug_unique UNIQUE (owner_id, slug);

-- budgets: (owner_id, ay, uye, kategori) unique
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_ay_uye_kategori_key;
ALTER TABLE budgets DROP CONSTRAINT IF EXISTS budgets_owner_ay_uye_kat_unique;
ALTER TABLE budgets ADD CONSTRAINT budgets_owner_ay_uye_kat_unique UNIQUE (owner_id, ay, uye, kategori);

SELECT 'RLS kurulumu tamamlandi' AS durum;
