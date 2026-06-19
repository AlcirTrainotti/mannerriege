-- ============================================================
-- MANNERRIEGE - Campeonatos
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.campeonatos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  cidade text,
  estado text, -- UF, 2 letras
  contato_nome text,
  contato_telefone text,
  data_inicio date,
  data_fim date,
  observacoes text,
  criado_por uuid references public.profiles (id),
  criado_em timestamptz not null default now()
);

alter table public.campeonatos enable row level security;

create policy "Diretoria e coordenacao veem campeonatos"
  on public.campeonatos for select
  using (public.is_esportivo());

create policy "Diretoria e coordenacao criam campeonatos"
  on public.campeonatos for insert
  with check (public.is_esportivo());

create policy "Diretoria e coordenacao editam campeonatos"
  on public.campeonatos for update
  using (public.is_esportivo());

create policy "Diretoria e coordenacao removem campeonatos"
  on public.campeonatos for delete
  using (public.is_esportivo());
