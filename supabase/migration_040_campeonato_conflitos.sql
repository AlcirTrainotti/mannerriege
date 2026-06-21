-- ============================================================
-- MANNERRIEGE - Conflitos de horário salvos no banco
-- Evita ter que clicar em "Verificar conflitos" toda vez - o resultado
-- da última verificação fica salvo e aparece direto na tela.
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.campeonatos
  add column if not exists conflitos_verificados_em timestamptz;

create table public.campeonato_conflitos (
  id uuid primary key default gen_random_uuid(),
  campeonato_id uuid not null references public.campeonatos (id) on delete cascade,
  campeonato_categoria_id_a uuid not null references public.campeonato_categorias (id) on delete cascade,
  campeonato_categoria_id_b uuid not null references public.campeonato_categorias (id) on delete cascade,
  jogo_a_id uuid references public.campeonato_jogos (id) on delete cascade,
  jogo_b_id uuid references public.campeonato_jogos (id) on delete cascade,
  pessoas text[] not null default '{}',
  motivo text,
  deslocamento_minutos integer,
  criado_em timestamptz not null default now()
);

alter table public.campeonato_conflitos enable row level security;

create policy "Diretoria e coordenacao gerenciam conflitos"
  on public.campeonato_conflitos for all
  using (public.is_esportivo())
  with check (public.is_esportivo());

create policy "Associado ve conflitos das categorias que participa"
  on public.campeonato_conflitos for select
  using (
    public.participo_da_categoria(campeonato_categoria_id_a)
    or public.participo_da_categoria(campeonato_categoria_id_b)
  );
