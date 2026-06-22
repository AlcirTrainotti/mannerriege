-- ============================================================
-- MANNERRIEGE - Receitas gerais do clube
-- (chamadas de capital, doações, patrocínios - fora de campeonatos)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.financeiro_receitas (
  id uuid primary key default gen_random_uuid(),
  descricao text not null,
  valor numeric(10, 2) not null default 0,
  tipo text not null check (tipo in ('chamada_capital', 'doacao', 'patrocinio', 'outro')) default 'outro',
  origem_nome text,
  patrocinador_id uuid,
  data date not null default current_date,
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.financeiro_receitas enable row level security;

create policy "Diretoria gerencia receitas gerais"
  on public.financeiro_receitas for all
  using (public.is_admin())
  with check (public.is_admin());
