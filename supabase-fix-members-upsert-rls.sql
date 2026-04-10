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

-- 2) (Önerilir) RLS'ten bağımsız, sadece auth.uid() satırına dokunan RPC — uygulama önce bunu dener
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
  r public.members%ROWTYPE;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  UPDATE public.members
  SET ad = p_ad, renk = p_renk, sira = p_sira, aktif = true
  WHERE owner_id = uid AND slug = p_slug
  RETURNING * INTO r;

  IF FOUND THEN
    RETURN to_jsonb(r)::json;
  END IF;

  INSERT INTO public.members (owner_id, slug, ad, renk, sira, aktif)
  VALUES (uid, p_slug, p_ad, p_renk, p_sira, true)
  RETURNING * INTO r;

  RETURN to_jsonb(r)::json;
END;
$$;

REVOKE ALL ON FUNCTION public.ac_member_upsert(text, text, text, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.ac_member_upsert(text, text, text, int) TO authenticated;
