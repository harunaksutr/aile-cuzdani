-- Ekstre PDF ile gelen taksitli satırların Taksitler sayfasında görünmesi için transactions tablosunda:
-- (Supabase SQL Editor’da bir kez çalıştırın.)

alter table public.transactions
  add column if not exists toplam_taksit integer default 1,
  add column if not exists taksit_no integer default 1,
  add column if not exists kalan_taksit integer default 1;

comment on column public.transactions.toplam_taksit is 'Kart taksit planı (ekstre); 1 = tek çekim';
comment on column public.transactions.taksit_no is 'Bu ekstre satırı kaçıncı taksit';
comment on column public.transactions.kalan_taksit is 'Kalan taksit sayısı (ekstre anındaki)';
