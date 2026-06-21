-- ============================================================
-- MANNERRIEGE - Agenda de jogos de cada categoria
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.campeonato_jogos (
  id uuid primary key default gen_random_uuid(),
  campeonato_categoria_id uuid not null references public.campeonato_categorias (id) on delete cascade,
  data date not null,
  hora_inicio time not null,
  hora_fim time,
  ginasio_nome text,
  ginasio_endereco text,
  adversario text,
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.campeonato_jogos enable row level security;

create policy "Diretoria e coordenacao gerenciam jogos"
  on public.campeonato_jogos for all
  using (public.is_esportivo())
  with check (public.is_esportivo());

create policy "Associado ve jogos da categoria que participa"
  on public.campeonato_jogos for select
  using (public.participo_da_categoria(campeonato_categoria_id));
