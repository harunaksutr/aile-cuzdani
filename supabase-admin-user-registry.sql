-- ============================================================
-- Aile Cüzdanı — Admin Kullanıcı Yönetimi
-- admin.html sayfası için gerekli
-- ============================================================

-- 1) Registry tablosunu oluştur
CREATE TABLE IF NOT EXISTS app_user_registry (
  id         UUID PRIMARY KEY,           -- auth.users.id ile aynı
  email      TEXT NOT NULL,
  role       TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2) RLS
ALTER TABLE app_user_registry ENABLE ROW LEVEL SECURITY;

-- Herkes kendi satırını okuyabilir
CREATE POLICY reg_self_select ON app_user_registry 
  FOR SELECT USING (id = auth.uid());

-- Admin tümünü okuyabilir
CREATE POLICY reg_admin_select ON app_user_registry 
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM app_user_registry WHERE id = auth.uid() AND role = 'admin')
  );

-- Admin güncelleme yapabilir (kendi rolünü değiştiremez)
CREATE POLICY reg_admin_update ON app_user_registry 
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM app_user_registry WHERE id = auth.uid() AND role = 'admin')
    AND id != auth.uid()  -- kendi rolünü değiştiremez
  );

-- 3) Mevcut auth kullanıcılarını registry'e doldur
INSERT INTO app_user_registry (id, email, role, created_at)
SELECT 
  id,
  email,
  'user' AS role,
  created_at
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 4) İlk kullanıcıyı admin yap (en eski hesap)
UPDATE app_user_registry 
SET role = 'admin' 
WHERE id = (SELECT id FROM app_user_registry ORDER BY created_at ASC LIMIT 1);

-- 5) Yeni kayıt olduğunda otomatik ekle
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO app_user_registry (id, email, role)
  VALUES (NEW.id, NEW.email, 'user')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

SELECT 'app_user_registry hazir' AS durum,
       COUNT(*) AS kullanici_sayisi,
       SUM(CASE WHEN role='admin' THEN 1 ELSE 0 END) AS admin_sayisi
FROM app_user_registry;
