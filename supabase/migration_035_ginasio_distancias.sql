-- ============================================================
-- MANNERRIEGE - Cache do tempo de deslocamento entre ginásios
--
-- Guarda o resultado já calculado pelo Google Maps para não precisar
-- chamar a API de novo toda vez (a API é paga por chamada).
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.ginasio_distancias (
  id uuid primary key default gen_random_uuid(),
  endereco_a text not null,
  endereco_b text not null,
  duracao_minutos integer not null,
  criado_em timestamptz not null default now(),
  unique (endereco_a, endereco_b)
);

alter table public.ginasio_distancias enable row level security;

create policy "Diretoria e coordenacao usam o cache de distancias"
  on public.ginasio_distancias for all
  using (public.is_esportivo())
  with check (public.is_esportivo());
