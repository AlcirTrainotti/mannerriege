-- ============================================================
-- MANNERRIEGE - Despesas gerais do clube
-- (benfeitorias, manutenções, compras de material, etc.)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.financeiro_despesas (
  id uuid primary key default gen_random_uuid(),
  descricao text not null,
  valor numeric(10, 2) not null default 0,
  categoria text not null check (categoria in ('benfeitoria', 'manutencao', 'compra_material', 'evento', 'outro')) default 'outro',
  data date not null default current_date,
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.financeiro_despesas enable row level security;

create policy "Diretoria gerencia despesas gerais"
  on public.financeiro_despesas for all
  using (public.is_admin())
  with check (public.is_admin());
