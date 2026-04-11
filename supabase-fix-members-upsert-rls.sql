-- ============================================================
-- Aile Cüzdanı — members upsert RPC fonksiyonu
-- Üye eklemede çakışma sorununu çözer
-- ============================================================

CREATE OR REPLACE FUNCTION ac_member_upsert(
  p_slug TEXT,
  p_ad   TEXT,
  p_renk TEXT,
  p_sira INTEGER
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER  -- auth.uid() doğru çalışsın
AS $$
BEGIN
  INSERT INTO members (slug, ad, renk, sira, aktif, owner_id)
  VALUES (p_slug, p_ad, p_renk, p_sira, true, auth.uid())
  ON CONFLICT (owner_id, slug)
  DO UPDATE SET
    ad    = EXCLUDED.ad,
    renk  = EXCLUDED.renk,
    sira  = EXCLUDED.sira,
    aktif = true;
END;
$$;

-- Fonksiyona anon erişim ver (RLS bypass için SECURITY DEFINER yeterli)
GRANT EXECUTE ON FUNCTION ac_member_upsert TO anon, authenticated;

SELECT 'ac_member_upsert fonksiyonu olusturuldu' AS durum;
