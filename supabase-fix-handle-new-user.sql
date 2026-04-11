-- ============================================================
-- "Database error saving new user" — çoğunlukla handle_new_user
-- tetikleyicisi app_user_registry'ye INSERT ederken patlar.
-- Yaygın neden: NEW.email NULL iken email sütunu NOT NULL.
-- Supabase SQL Editor'de bir kez çalıştır.
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  em text;
BEGIN
  em := COALESCE(
    NULLIF(trim(COALESCE(NEW.email::text, '')), ''),
    NULLIF(trim(COALESCE(NEW.raw_user_meta_data->>'email', '')), ''),
    NULLIF(trim(COALESCE(NEW.raw_user_meta_data->>'preferred_username', '')), ''),
    'user-' || replace(NEW.id::text, '-', '') || '@pending.local'
  );

  INSERT INTO public.app_user_registry (id, email, role)
  VALUES (NEW.id, em, 'user')
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Tetikleyici yoksa oluştur (isim projenizde farklıysa düzenleyin)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_new_user();

SELECT 'handle_new_user guncellendi' AS durum;
