-- ============================================================
-- infinite recursion detected in policy for relation "app_user_registry"
--
-- Nedeni: reg_admin_select / reg_admin_update içinde
-- EXISTS (SELECT ... FROM app_user_registry ...) — RLS her SELECT'te
-- yine aynı tabloyu kontrol eder → döngü.
--
-- Çözüm: Admin kontrolü SECURITY DEFINER fonksiyonda (RLS atlanır).
-- Supabase SQL Editor'de bir kez çalıştırın.
-- ============================================================

-- Eski politikalar (iç içe sorgulu olanlar)
DROP POLICY IF EXISTS reg_admin_select ON public.app_user_registry;
DROP POLICY IF EXISTS reg_admin_update ON public.app_user_registry;

-- RLS'i atlayarak sadece okuma yapan güvenli kontrol
CREATE OR REPLACE FUNCTION public.ac_is_registry_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.app_user_registry r
    WHERE r.id = auth.uid()
      AND r.role = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.ac_is_registry_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ac_is_registry_admin() TO authenticated, anon;

-- Admin: tüm satırları oku (fonksiyon döngü yapmaz)
CREATE POLICY reg_admin_select ON public.app_user_registry
  FOR SELECT
  USING (public.ac_is_registry_admin());

-- Admin: başka kullanıcıların satırını güncelle (kendi satırı hariç — eski mantık)
CREATE POLICY reg_admin_update ON public.app_user_registry
  FOR UPDATE
  USING (
    public.ac_is_registry_admin()
    AND id <> auth.uid()
  )
  WITH CHECK (
    public.ac_is_registry_admin()
    AND id <> auth.uid()
  );

-- reg_self_select aynı kalır (kendi satırını okuma); yoksa ekleyin:
-- CREATE POLICY reg_self_select ON public.app_user_registry
--   FOR SELECT USING (id = auth.uid());

SELECT 'app_user_registry RLS dongusu duzeltildi' AS durum;
