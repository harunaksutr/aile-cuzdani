-- V2 RLS ve tablo dogrulama sorgulari

select
  tablename,
  rowsecurity as rls_acik,
  relforcerowsecurity as rls_zorunlu
from pg_tables t
join pg_class c on c.relname = t.tablename
join pg_namespace n on n.oid = c.relnamespace and n.nspname = t.schemaname
where t.schemaname = 'public'
  and tablename in ('members','categories','transactions','installments','loans','budgets')
order by tablename;

select
  tablename,
  policyname,
  permissive,
  roles,
  cmd
from pg_policies
where schemaname = 'public'
  and tablename in ('members','categories','transactions','installments','loans','budgets')
order by tablename, policyname;

select
  'members' as tablo,
  count(*) filter (where owner_id is null) as bos_owner
from public.members
union all
select 'categories', count(*) filter (where owner_id is null) from public.categories
union all
select 'transactions', count(*) filter (where owner_id is null) from public.transactions
union all
select 'installments', count(*) filter (where owner_id is null) from public.installments
union all
select 'loans', count(*) filter (where owner_id is null) from public.loans
union all
select 'budgets', count(*) filter (where owner_id is null) from public.budgets;
