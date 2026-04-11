-- ============================================================
-- Google ile giriş sonrası adminlik kaybolduysa
-- E-posta/şifre hesabınızda admin id’si vardı; Google aynı e-posta
-- ile YENİ bir kullanıcı (farklı UUID) oluşturdu. Registry admin’i
-- eski id’ye bağlıdır.
--
-- Çözüm: Google hesabınızın UUID’sini kullanarak, aynı e-posta için
-- registry’de başka bir admin satırı varsa bu hesabı da admin yapar.
--
-- Aşağıdaki UUID bu proje için tanımlı ana kullanıcı kimliği.
-- Başka bir Google UUID kullanacaksanız iki yerde değiştirin.
-- SQL Editor’de çalıştırın.
-- ============================================================

INSERT INTO public.app_user_registry (id, email, role)
SELECT
  u.id,
  COALESCE(NULLIF(trim(u.email), ''), 'unknown@local'),
  'admin'::text
FROM auth.users u
WHERE u.id = '95e69359-0058-444d-9f7a-d8158af33873'::uuid
  AND length(trim(COALESCE(u.email, ''))) > 0
  AND EXISTS (
    SELECT 1
    FROM public.app_user_registry r
    WHERE r.role = 'admin'
      AND lower(r.email) = lower(trim(u.email))
  )
ON CONFLICT (id) DO UPDATE SET role = 'admin';

-- Kaç satır etkilendi görmek için (0 satır = e-posta eşleşmedi veya admin yok)
SELECT id, email, role FROM public.app_user_registry WHERE id = '95e69359-0058-444d-9f7a-d8158af33873'::uuid;
