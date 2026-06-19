-- ============================================================
-- MANNERRIEGE - Participantes (equipe) de cada categoria do campeonato
-- Rode no Supabase SQL Editor depois do migration_023
-- ============================================================

create table public.campeonato_participantes (
  id uuid primary key default gen_random_uuid(),
  campeonato_categoria_id uuid not null references public.campeonato_categorias (id) on delete cascade,
  tipo text not null check (tipo in ('associado', 'convidado')),
  associado_id uuid references public.profiles (id) on delete cascade,
  convidado_id uuid references public.convidados (id) on delete cascade,
  funcao text not null default 'atleta' check (funcao in ('atleta', 'comissao_tecnica')),
  criado_em timestamptz not null default now(),
  check (
    (tipo = 'associado' and associado_id is not null and convidado_id is null) or
    (tipo = 'convidado' and convidado_id is not null and associado_id is null)
  )
);

alter table public.campeonato_participantes enable row level security;

-- Diretoria e coordenacao esportiva gerenciam tudo
create policy "Diretoria e coordenacao veem participantes"
  on public.campeonato_participantes for select
  using (public.is_esportivo());

create policy "Diretoria e coordenacao criam participantes"
  on public.campeonato_participantes for insert
  with check (public.is_esportivo());

create policy "Diretoria e coordenacao editam participantes"
  on public.campeonato_participantes for update
  using (public.is_esportivo());

create policy "Diretoria e coordenacao removem participantes"
  on public.campeonato_participantes for delete
  using (public.is_esportivo());

-- Um associado pode ver os colegas de equipe da mesma categoria/campeonato
-- em que ele tambem esta escalado (inclui ele mesmo).
create policy "Associado ve equipe dos campeonatos que participa"
  on public.campeonato_participantes for select
  using (
    exists (
      select 1 from public.campeonato_participantes minha
      where minha.tipo = 'associado'
        and minha.associado_id = auth.uid()
        and minha.campeonato_categoria_id = campeonato_participantes.campeonato_categoria_id
    )
  );

-- Liberar tambem a leitura de campeonatos e categorias para o associado
-- que participa, ja que as regras dessas tabelas hoje so liberam para
-- quem e diretoria/coordenacao.
create policy "Associado ve campeonatos em que participa"
  on public.campeonatos for select
  using (
    exists (
      select 1 from public.campeonato_categorias cc
      join public.campeonato_participantes cp on cp.campeonato_categoria_id = cc.id
      where cc.campeonato_id = campeonatos.id
        and cp.tipo = 'associado'
        and cp.associado_id = auth.uid()
    )
  );

create policy "Associado ve categorias dos campeonatos em que participa"
  on public.campeonato_categorias for select
  using (
    exists (
      select 1 from public.campeonato_participantes cp
      where cp.campeonato_categoria_id = campeonato_categorias.id
        and cp.tipo = 'associado'
        and cp.associado_id = auth.uid()
    )
  );
