-- Aile Cüzdanı — Yönetim sayfası (admin.html) için kullanıcı kaydı
-- Supabase SQL Editor'da bir kez çalıştır.
--
-- 1) Bu scripti çalıştırdıktan sonra ilk yöneticiyi ata:
--    UPDATE public.app_user_registry SET role = 'admin' WHERE email = 'senin@eposta.com';
-- 2) Eski hesaplar için backfill aşağıda; yeni kayıtlar tetikleyiciyle eklenir.

-- Tablo: auth.users ile eşleşen satırlar (silinince CASCADE ile gider)
CREATE TABLE IF NOT EXISTS public.app_user_registry (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email text,
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS app_user_registry_role_idx ON public.app_user_registry (role);

ALTER TABLE public.app_user_registry ENABLE ROW LEVEL SECURITY;

-- Politika içinde doğrudan bu tabloya SELECT, RLS'yi tekrar çalıştırır → "infinite recursion".
-- SECURITY DEFINER: fonksiyon sahibi olarak okur, RLS uygulanmaz (sadece admin kontrolü için).
CREATE OR REPLACE FUNCTION public.is_app_registry_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.app_user_registry r
    WHERE r.id = auth.uid() AND r.role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_app_registry_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_app_registry_admin() TO authenticated;

-- Herkes kendi satırını görebilir
DROP POLICY IF EXISTS "registry_select_own" ON public.app_user_registry;
CREATE POLICY "registry_select_own"
  ON public.app_user_registry
  FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Yöneticiler tüm satırları görebilir
DROP POLICY IF EXISTS "registry_select_admin_all" ON public.app_user_registry;
CREATE POLICY "registry_select_admin_all"
  ON public.app_user_registry
  FOR SELECT
  TO authenticated
  USING (public.is_app_registry_admin());

-- Sadece yöneticiler rol (ve e-posta senkronu) güncelleyebilir
DROP POLICY IF EXISTS "registry_update_admin" ON public.app_user_registry;
CREATE POLICY "registry_update_admin"
  ON public.app_user_registry
  FOR UPDATE
  TO authenticated
  USING (public.is_app_registry_admin())
  WITH CHECK (true);

-- Yeni kayıt: auth.users eklendiğinde
CREATE OR REPLACE FUNCTION public.handle_app_user_registry_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.app_user_registry (id, email, role)
  VALUES (NEW.id, NEW.email, 'user')
  ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_app_registry ON auth.users;
CREATE TRIGGER on_auth_user_created_app_registry
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_app_user_registry_insert();

-- E-posta değişince (isteğe bağlı senkron)
CREATE OR REPLACE FUNCTION public.handle_app_user_registry_email_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    UPDATE public.app_user_registry SET email = NEW.email WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_updated_app_registry ON auth.users;
CREATE TRIGGER on_auth_user_updated_app_registry
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_app_user_registry_email_update();

-- Mevcut kullanıcıları doldur
INSERT INTO public.app_user_registry (id, email, role)
SELECT u.id, u.email, 'user'
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.app_user_registry r WHERE r.id = u.id)
ON CONFLICT (id) DO NOTHING;

GRANT SELECT, UPDATE ON public.app_user_registry TO authenticated;
