-- ============================================================
-- MANNERRIEGE - Categorias inscritas em cada campeonato
-- Rode no Supabase SQL Editor depois do migration_022
-- ============================================================

create table public.campeonato_categorias (
  id uuid primary key default gen_random_uuid(),
  campeonato_id uuid not null references public.campeonatos (id) on delete cascade,
  categoria text not null check (categoria in ('Livre', '35+', '40+', '45+', '50+', '55+', '60+')),
  custo_inscricao numeric(10, 2) default 0,
  criado_em timestamptz not null default now(),
  unique (campeonato_id, categoria)
);

alter table public.campeonato_categorias enable row level security;

create policy "Diretoria e coordenacao veem categorias do campeonato"
  on public.campeonato_categorias for select
  using (public.is_esportivo());

create policy "Diretoria e coordenacao criam categorias do campeonato"
  on public.campeonato_categorias for insert
  with check (public.is_esportivo());

create policy "Diretoria e coordenacao editam categorias do campeonato"
  on public.campeonato_categorias for update
  using (public.is_esportivo());

create policy "Diretoria e coordenacao removem categorias do campeonato"
  on public.campeonato_categorias for delete
  using (public.is_esportivo());
