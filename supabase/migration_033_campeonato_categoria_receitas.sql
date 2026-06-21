-- ============================================================
-- MANNERRIEGE - Receitas extras de cada categoria do campeonato
-- (verba liberada pela associação, aportes de integrantes)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.campeonato_categoria_receitas (
  id uuid primary key default gen_random_uuid(),
  campeonato_categoria_id uuid not null references public.campeonato_categorias (id) on delete cascade,
  descricao text not null,
  valor numeric(10, 2) not null default 0,
  origem text not null check (origem in ('associacao', 'aporte_pessoal', 'outro')) default 'associacao',
  aportado_por text, -- nome de quem aportou, quando origem = 'aporte_pessoal'
  criado_em timestamptz not null default now()
);

alter table public.campeonato_categoria_receitas enable row level security;

create policy "Diretoria e coordenacao gerenciam receitas"
  on public.campeonato_categoria_receitas for all
  using (public.is_esportivo())
  with check (public.is_esportivo());

create policy "Associado ve receitas da categoria que participa"
  on public.campeonato_categoria_receitas for select
  using (public.participo_da_categoria(campeonato_categoria_id));
