-- ============================================================
-- Kendi hesabınızı tekrar admin yapın (app_user_registry)
-- Aşağıdaki UUID ana kullanıcı kimliği (Authentication → Users ile aynı olmalı).
-- Supabase SQL Editor'de bir kez çalıştırın.
--
-- Google ile girişte eski e-posta hesabınızdaki admini OTOMATİK taşımak için:
-- supabase-sync-admin-same-email.sql dosyasına bakın.
-- ============================================================

INSERT INTO public.app_user_registry (id, email, role)
SELECT id, COALESCE(email, 'unknown@local'), 'admin'
FROM auth.users
WHERE id = '95e69359-0058-444d-9f7a-d8158af33873'::uuid
ON CONFLICT (id) DO UPDATE SET role = 'admin';

-- Kontrol: admin olanlar
SELECT id, email, role, created_at
FROM public.app_user_registry
WHERE role = 'admin'
ORDER BY created_at;
