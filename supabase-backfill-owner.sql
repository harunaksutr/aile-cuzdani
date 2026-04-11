-- ============================================================
-- Aile Cüzdanı — Eski Veriyi Tek Kullanıcıya Bağlama
-- supabase-auth-setup.sql'den SONRA çalıştır
-- ============================================================

-- 1) Kullanıcı UUID'nizi Authentication > Users'dan kopyalayın
-- Aşağıdaki 'BURAYA-UUID-YAPISTIR' kısmını değiştirin

DO $$
DECLARE
  target_uid UUID := 'BURAYA-UUID-YAPISTIR'; -- ← değiştir
BEGIN
  -- Sadece owner_id boş olan satırları güncelle (mevcut multi-user verisine dokunma)
  UPDATE transactions  SET owner_id = target_uid WHERE owner_id IS NULL;
  UPDATE installments  SET owner_id = target_uid WHERE owner_id IS NULL;
  UPDATE loans         SET owner_id = target_uid WHERE owner_id IS NULL;
  UPDATE budgets        SET owner_id = target_uid WHERE owner_id IS NULL;
  UPDATE categories    SET owner_id = target_uid WHERE owner_id IS NULL;
  UPDATE members       SET owner_id = target_uid WHERE owner_id IS NULL;

  RAISE NOTICE 'Backfill tamamlandi: transactions=%, installments=%, loans=%, budgets=%, categories=%, members=%',
    (SELECT COUNT(*) FROM transactions WHERE owner_id = target_uid),
    (SELECT COUNT(*) FROM installments WHERE owner_id = target_uid),
    (SELECT COUNT(*) FROM loans WHERE owner_id = target_uid),
    (SELECT COUNT(*) FROM budgets WHERE owner_id = target_uid),
    (SELECT COUNT(*) FROM categories WHERE owner_id = target_uid),
    (SELECT COUNT(*) FROM members WHERE owner_id = target_uid);
END $$;
