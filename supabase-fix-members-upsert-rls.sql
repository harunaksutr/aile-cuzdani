-- Aile Cüzdanı — Üye ekleme: pasif (aktif=false) satırı PostgREST upsert ile yeniden açmak
--
-- Sorun: INSERT ... ON CONFLICT DO UPDATE, RLS'nin UPDATE için sadece aktif=true
-- satırlara izin vermesi durumunda başarısız olur; ardından düz INSERT 23505 verir.
--
-- Supabase SQL Editor'da bir kez çalıştır.

-- 1) Upsert'ın UPDATE kolunu çalıştırabilmesi: kendi satırların (aktif ne olursa)
DROP POLICY IF EXISTS "members_update_owner_any_aktif" ON public.members;
CREATE POLICY "members_update_owner_any_aktif"
ON public.members
FOR UPDATE
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

-- 2) RLS'ten bağımsız RPC — uygulama önce bunu dener.
--    owner_id hem uuid hem text projelerde çalışsın diye metin üzerinden eşleştirme.
CREATE OR REPLACE FUNCTION public.ac_member_upsert(
  p_slug text,
  p_ad text,
  p_renk text,
  p_sira int
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
  uid_txt text := auth.uid()::text;
  r public.members%ROWTYPE;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  UPDATE public.members
  SET ad = p_ad, renk = p_renk, sira = p_sira, aktif = true
  WHERE slug = p_slug
    AND (owner_id = uid OR owner_id::text = uid_txt)
  RETURNING * INTO r;

  IF FOUND THEN
    RETURN to_jsonb(r)::json;
  END IF;

  BEGIN
    INSERT INTO public.members (owner_id, slug, ad, renk, sira, aktif)
    VALUES (uid, p_slug, p_ad, p_renk, p_sira, true)
    RETURNING * INTO r;
  EXCEPTION
    WHEN unique_violation THEN
      UPDATE public.members
      SET ad = p_ad, renk = p_renk, sira = p_sira, aktif = true
      WHERE slug = p_slug
        AND (owner_id = uid OR owner_id::text = uid_txt)
      RETURNING * INTO r;
      IF NOT FOUND THEN
        RAISE;
      END IF;
  END;

  RETURN to_jsonb(r)::json;
END;
$$;

REVOKE ALL ON FUNCTION public.ac_member_upsert(text, text, text, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ac_member_upsert(text, text, text, int) TO authenticated;
