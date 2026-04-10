-- Sadece "infinite recursion detected in policy for relation app_user_registry" düzeltmesi.
-- Daha önce eski politikaları çalıştırdıysan: Supabase SQL Editor'da bunu bir kez çalıştır.

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

DROP POLICY IF EXISTS "registry_select_admin_all" ON public.app_user_registry;
CREATE POLICY "registry_select_admin_all"
  ON public.app_user_registry
  FOR SELECT
  TO authenticated
  USING (public.is_app_registry_admin());

DROP POLICY IF EXISTS "registry_update_admin" ON public.app_user_registry;
CREATE POLICY "registry_update_admin"
  ON public.app_user_registry
  FOR UPDATE
  TO authenticated
  USING (public.is_app_registry_admin())
  WITH CHECK (true);
