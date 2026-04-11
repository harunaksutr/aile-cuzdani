-- ============================================================
-- Aile Cüzdanı — Migration Doğrulama
-- Her şey doğru kurulduysa tüm satırlar ✓ göstermeli
-- ============================================================

-- 1) owner_id kolonları var mı?
SELECT 
  table_name,
  CASE WHEN COUNT(*) > 0 THEN '✓ owner_id var' ELSE '✗ owner_id YOK' END AS durum
FROM information_schema.columns
WHERE table_schema = 'public'
  AND column_name = 'owner_id'
  AND table_name IN ('transactions','installments','loans','budgets','categories','members')
GROUP BY table_name
ORDER BY table_name;

-- 2) RLS aktif mi?
SELECT 
  tablename,
  CASE WHEN rowsecurity THEN '✓ RLS aktif' ELSE '✗ RLS KAPALI' END AS rls_durum
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('transactions','installments','loans','budgets','categories','members')
ORDER BY tablename;

-- 3) Policy'ler var mı?
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE tablename IN ('transactions','installments','loans','budgets','categories','members')
ORDER BY tablename, cmd;

-- 4) owner_id null olan satırlar (backfill gerekiyor mu?)
SELECT 'transactions'  AS tablo, COUNT(*) AS bos_owner FROM transactions  WHERE owner_id IS NULL
UNION ALL
SELECT 'installments'  ,         COUNT(*) FROM installments  WHERE owner_id IS NULL
UNION ALL
SELECT 'loans'         ,         COUNT(*) FROM loans         WHERE owner_id IS NULL
UNION ALL
SELECT 'budgets'       ,         COUNT(*) FROM budgets        WHERE owner_id IS NULL
UNION ALL
SELECT 'categories'    ,         COUNT(*) FROM categories    WHERE owner_id IS NULL
UNION ALL
SELECT 'members'       ,         COUNT(*) FROM members       WHERE owner_id IS NULL;

-- 5) Unique constraint'ler
SELECT conname, contype, conrelid::regclass AS tablo
FROM pg_constraint
WHERE conrelid::regclass::text IN ('categories','members','budgets')
  AND contype = 'u'
ORDER BY tablo;

-- 6) ac_member_upsert fonksiyonu var mı?
SELECT 
  CASE WHEN COUNT(*) > 0 THEN '✓ ac_member_upsert var' ELSE '✗ ac_member_upsert YOK — fix-members sql calistir' END AS rpc_durum
FROM pg_proc WHERE proname = 'ac_member_upsert';
