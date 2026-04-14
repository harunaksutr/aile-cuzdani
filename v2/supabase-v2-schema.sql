-- Aile Cuzdani V2 schema
-- Tum tablolar owner_id ile ayrilir ve RLS zorunlu tutulur.

create extension if not exists pgcrypto;

create table if not exists public.members (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  slug text not null,
  ad text not null,
  renk text not null default '#378ADD',
  sira integer not null default 1,
  aktif boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint members_owner_slug_key unique (owner_id, slug),
  constraint members_owner_ad_key unique (owner_id, ad)
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  ad text not null,
  renk text not null default '#888780',
  sira integer not null default 1,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint categories_owner_ad_key unique (owner_id, ad)
);

create table if not exists public.loans (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  ad text not null,
  tur text not null,
  banka text not null,
  ana_para numeric(14,2) not null default 0 check (ana_para >= 0),
  aylik_taksit numeric(14,2) not null check (aylik_taksit > 0),
  toplam_taksit integer not null check (toplam_taksit > 0),
  kalan_taksit integer not null check (kalan_taksit >= 0 and kalan_taksit <= toplam_taksit),
  baslangic_tarihi date not null,
  ilk_odeme_tarihi date not null,
  notlar text,
  durum text not null default 'aktif',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.installments (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  aciklama text not null,
  tutar numeric(14,2) not null check (tutar > 0),
  kaynak text not null,
  uye text not null,
  toplam_taksit integer not null default 1 check (toplam_taksit > 0),
  kalan_taksit integer not null default 1 check (kalan_taksit >= 0 and kalan_taksit <= toplam_taksit),
  taksit_no integer,
  loan_id uuid references public.loans(id) on delete set null,
  son_odeme_tarihi date not null,
  durum text not null default 'bekliyor',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint installments_owner_member_fkey
    foreign key (owner_id, uye) references public.members (owner_id, slug)
    on update cascade on delete restrict
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  tarih date not null,
  tutar numeric(14,2) not null check (tutar > 0),
  aciklama text not null,
  kategori text not null,
  kaynak text not null,
  uye text not null,
  notlar text,
  toplam_taksit integer,
  taksit_no integer,
  kalan_taksit integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint transactions_owner_category_fkey
    foreign key (owner_id, kategori) references public.categories (owner_id, ad)
    on update cascade on delete restrict,
  constraint transactions_owner_member_fkey
    foreign key (owner_id, uye) references public.members (owner_id, slug)
    on update cascade on delete restrict
);

create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  ay text not null check (ay ~ '^[0-9]{4}-[0-9]{2}$'),
  uye text not null,
  kategori text not null default 'genel',
  hedef numeric(14,2) not null check (hedef >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint budgets_owner_period_member_category_key unique (owner_id, ay, uye, kategori)
);

create index if not exists idx_members_owner_active on public.members (owner_id, aktif, sira);
create index if not exists idx_categories_owner_sort on public.categories (owner_id, sira);
create index if not exists idx_transactions_owner_tarih on public.transactions (owner_id, tarih desc);
create index if not exists idx_transactions_owner_uye on public.transactions (owner_id, uye);
create index if not exists idx_transactions_owner_kategori on public.transactions (owner_id, kategori);
create index if not exists idx_installments_owner_due on public.installments (owner_id, son_odeme_tarihi);
create index if not exists idx_installments_owner_loan on public.installments (owner_id, loan_id);
create index if not exists idx_loans_owner_durum on public.loans (owner_id, durum);
create index if not exists idx_budgets_owner_period on public.budgets (owner_id, ay);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_members_updated_at on public.members;
create trigger trg_members_updated_at
before update on public.members
for each row execute function public.set_updated_at();

drop trigger if exists trg_categories_updated_at on public.categories;
create trigger trg_categories_updated_at
before update on public.categories
for each row execute function public.set_updated_at();

drop trigger if exists trg_transactions_updated_at on public.transactions;
create trigger trg_transactions_updated_at
before update on public.transactions
for each row execute function public.set_updated_at();

drop trigger if exists trg_installments_updated_at on public.installments;
create trigger trg_installments_updated_at
before update on public.installments
for each row execute function public.set_updated_at();

drop trigger if exists trg_loans_updated_at on public.loans;
create trigger trg_loans_updated_at
before update on public.loans
for each row execute function public.set_updated_at();

drop trigger if exists trg_budgets_updated_at on public.budgets;
create trigger trg_budgets_updated_at
before update on public.budgets
for each row execute function public.set_updated_at();

alter table public.members enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.installments enable row level security;
alter table public.loans enable row level security;
alter table public.budgets enable row level security;

alter table public.members force row level security;
alter table public.categories force row level security;
alter table public.transactions force row level security;
alter table public.installments force row level security;
alter table public.loans force row level security;
alter table public.budgets force row level security;

drop policy if exists members_owner_select on public.members;
drop policy if exists members_owner_insert on public.members;
drop policy if exists members_owner_update on public.members;
drop policy if exists members_owner_delete on public.members;
create policy members_owner_select on public.members for select using (owner_id = auth.uid());
create policy members_owner_insert on public.members for insert with check (owner_id = auth.uid());
create policy members_owner_update on public.members for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy members_owner_delete on public.members for delete using (owner_id = auth.uid());

drop policy if exists categories_owner_select on public.categories;
drop policy if exists categories_owner_insert on public.categories;
drop policy if exists categories_owner_update on public.categories;
drop policy if exists categories_owner_delete on public.categories;
create policy categories_owner_select on public.categories for select using (owner_id = auth.uid());
create policy categories_owner_insert on public.categories for insert with check (owner_id = auth.uid());
create policy categories_owner_update on public.categories for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy categories_owner_delete on public.categories for delete using (owner_id = auth.uid());

drop policy if exists transactions_owner_select on public.transactions;
drop policy if exists transactions_owner_insert on public.transactions;
drop policy if exists transactions_owner_update on public.transactions;
drop policy if exists transactions_owner_delete on public.transactions;
create policy transactions_owner_select on public.transactions for select using (owner_id = auth.uid());
create policy transactions_owner_insert on public.transactions for insert with check (owner_id = auth.uid());
create policy transactions_owner_update on public.transactions for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy transactions_owner_delete on public.transactions for delete using (owner_id = auth.uid());

drop policy if exists installments_owner_select on public.installments;
drop policy if exists installments_owner_insert on public.installments;
drop policy if exists installments_owner_update on public.installments;
drop policy if exists installments_owner_delete on public.installments;
create policy installments_owner_select on public.installments for select using (owner_id = auth.uid());
create policy installments_owner_insert on public.installments for insert with check (owner_id = auth.uid());
create policy installments_owner_update on public.installments for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy installments_owner_delete on public.installments for delete using (owner_id = auth.uid());

drop policy if exists loans_owner_select on public.loans;
drop policy if exists loans_owner_insert on public.loans;
drop policy if exists loans_owner_update on public.loans;
drop policy if exists loans_owner_delete on public.loans;
create policy loans_owner_select on public.loans for select using (owner_id = auth.uid());
create policy loans_owner_insert on public.loans for insert with check (owner_id = auth.uid());
create policy loans_owner_update on public.loans for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy loans_owner_delete on public.loans for delete using (owner_id = auth.uid());

drop policy if exists budgets_owner_select on public.budgets;
drop policy if exists budgets_owner_insert on public.budgets;
drop policy if exists budgets_owner_update on public.budgets;
drop policy if exists budgets_owner_delete on public.budgets;
create policy budgets_owner_select on public.budgets for select using (owner_id = auth.uid());
create policy budgets_owner_insert on public.budgets for insert with check (owner_id = auth.uid());
create policy budgets_owner_update on public.budgets for update using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy budgets_owner_delete on public.budgets for delete using (owner_id = auth.uid());
