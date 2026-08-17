-- ============================================================
-- MANNERRIEGE - Frequência e desempenho por atleta em cada evento
-- Rode DEPOIS do migration_077.
-- ============================================================

create table public.evento_participantes_base (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null references public.eventos_base (id) on delete cascade,
  atleta_id uuid not null references public.atletas_base (id) on delete cascade,
  presente boolean, -- nulo = ainda não registrado
  desempenho_nota numeric(3, 1) check (desempenho_nota between 0 and 10),
  desempenho_obs text,
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  unique (evento_id, atleta_id)
);

comment on column public.evento_participantes_base.desempenho_nota is
  'Nota de 0 a 10 (mesma escala usada na especificação do módulo) — avaliação do professor no treino/jogo.';

alter table public.evento_participantes_base enable row level security;

create policy "Equipe da base gerencia frequencia e desempenho"
  on public.evento_participantes_base for all
  using (public.is_base())
  with check (public.is_base());

create policy "Responsavel ve frequencia e desempenho dos seus atletas"
  on public.evento_participantes_base for select
  using (public.responsavel_do_atleta(atleta_id));

create policy "Atleta ve a propria frequencia e desempenho"
  on public.evento_participantes_base for select
  using (public.atleta_e_proprio(atleta_id));
