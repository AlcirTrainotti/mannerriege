-- ============================================================
-- MANNERRIEGE - Conselho Fiscal
--
-- Conselheiro fiscal é um associado eleito (continua sendo "associado"
-- no papel, só ganha esta capacidade extra) que aprova mensalmente as
-- contas do clube.
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.profiles
  add column if not exists conselheiro_fiscal boolean not null default false;

create function public.is_conselheiro_fiscal()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and conselheiro_fiscal = true
  );
$$ language sql security definer stable set search_path = public;

create table public.aprovacoes_mensais (
  id uuid primary key default gen_random_uuid(),
  competencia date not null,
  aprovado_por uuid not null references public.profiles (id),
  observacoes text,
  criado_em timestamptz not null default now(),
  unique (competencia, aprovado_por)
);

alter table public.aprovacoes_mensais enable row level security;

create policy "Financeiro ve todas as aprovacoes"
  on public.aprovacoes_mensais for select
  using (public.is_financeiro() or public.is_conselheiro_fiscal());

create policy "Conselheiro fiscal aprova com seu proprio nome"
  on public.aprovacoes_mensais for insert
  with check (public.is_conselheiro_fiscal() and aprovado_por = auth.uid());

create policy "Conselheiro fiscal remove a propria aprovacao"
  on public.aprovacoes_mensais for delete
  using (aprovado_por = auth.uid());
