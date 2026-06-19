-- ============================================================
-- MANNERRIEGE - Conjuntos de uniforme (jogos de uniforme)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.jogos_uniforme (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  quantidade_camisas integer not null default 0,
  quantidade_bermudas integer not null default 0,
  data_confeccao date,
  -- Por enquanto preenchido manualmente. Quando o modulo de Campeonatos
  -- existir, podemos passar a calcular este numero automaticamente a
  -- partir dos campeonatos em que este conjunto foi usado.
  campeonatos_participados integer not null default 0,
  foto_url text,
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.jogos_uniforme enable row level security;

create policy "Diretoria e coordenacao veem jogos de uniforme"
  on public.jogos_uniforme for select
  using (public.is_esportivo());

create policy "Diretoria e coordenacao criam jogos de uniforme"
  on public.jogos_uniforme for insert
  with check (public.is_esportivo());

create policy "Diretoria e coordenacao editam jogos de uniforme"
  on public.jogos_uniforme for update
  using (public.is_esportivo());

create policy "Diretoria e coordenacao removem jogos de uniforme"
  on public.jogos_uniforme for delete
  using (public.is_esportivo());
