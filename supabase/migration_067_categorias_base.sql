-- ============================================================
-- MANNERRIEGE - Categorias de Base (Sub-13/Sub-15)
-- Rode DEPOIS do migration_066.
-- ============================================================

create table public.categorias_base (
  id uuid primary key default gen_random_uuid(),
  nome text not null, -- 'Sub-13', 'Sub-15'
  sexo text not null check (sexo in ('masculino', 'feminino')),
  faixa_etaria_min integer,
  faixa_etaria_max integer,
  ativo boolean not null default true,
  criado_em timestamptz not null default now(),
  unique (nome, sexo)
);

comment on table public.categorias_base is
  'Categorias do projeto social Vôlei de Base. Faixas etárias abaixo são uma estimativa inicial (piloto 2026 é 12-13 anos) — ajustar aqui, na tela de Categorias, se a coordenação definir outro critério.';

alter table public.categorias_base enable row level security;

create policy "Equipe da base gerencia categorias"
  on public.categorias_base for all
  using (public.is_coordenador_base())
  with check (public.is_coordenador_base());

create policy "Participantes da base leem categorias"
  on public.categorias_base for select
  using (public.is_participante_base());

insert into public.categorias_base (nome, sexo, faixa_etaria_min, faixa_etaria_max) values
  ('Sub-13', 'masculino', 11, 13),
  ('Sub-13', 'feminino', 11, 13),
  ('Sub-15', 'masculino', 14, 15),
  ('Sub-15', 'feminino', 14, 15);
