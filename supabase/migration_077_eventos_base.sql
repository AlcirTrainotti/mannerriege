-- ============================================================
-- MANNERRIEGE - Eventos das Categorias de Base (treinos, jogos,
-- campeonatos, festivais...)
-- Rode DEPOIS do migration_076.
-- ============================================================

create table public.eventos_base (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid references public.categorias_base (id) on delete set null, -- nulo = vale pra todas as categorias
  tipo text not null default 'treino' check (tipo in ('treino', 'jogo', 'campeonato', 'festival', 'reuniao', 'outro')),
  titulo text not null,
  data date not null,
  hora_inicio time,
  hora_fim time,
  local text,
  plano_atividades text, -- o que será trabalhado no treino/evento
  observacoes text,
  criado_por uuid references public.profiles (id),
  criado_em timestamptz not null default now()
);

comment on column public.eventos_base.categoria_id is
  'Nulo = evento vale pra todas as categorias (ex: reunião geral, festival aberto).';
comment on column public.eventos_base.plano_atividades is
  'Atividades/conteúdo planejado pelo professor pra esse treino ou evento.';

alter table public.eventos_base enable row level security;

create policy "Equipe da base gerencia eventos"
  on public.eventos_base for all
  using (public.is_base())
  with check (public.is_base());

create policy "Participantes da base leem eventos"
  on public.eventos_base for select
  using (public.is_participante_base());
