-- ============================================================
-- MANNERRIEGE - Despesas extras de cada categoria do campeonato
-- (água, custos diversos rateados ou assumidos por alguém)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.campeonato_categoria_despesas (
  id uuid primary key default gen_random_uuid(),
  campeonato_categoria_id uuid not null references public.campeonato_categorias (id) on delete cascade,
  descricao text not null,
  valor numeric(10, 2) not null default 0,
  tipo text not null check (tipo in ('rateado', 'assumido')) default 'rateado',
  assumido_por text, -- nome de quem assumiu, quando tipo = 'assumido'
  criado_em timestamptz not null default now()
);

alter table public.campeonato_categoria_despesas enable row level security;

create policy "Diretoria e coordenacao gerenciam despesas"
  on public.campeonato_categoria_despesas for all
  using (public.is_esportivo())
  with check (public.is_esportivo());

-- Associado escalado naquela categoria pode ver (prestacao de contas),
-- mas nao editar.
create policy "Associado ve despesas da categoria que participa"
  on public.campeonato_categoria_despesas for select
  using (public.participo_da_categoria(campeonato_categoria_id));
