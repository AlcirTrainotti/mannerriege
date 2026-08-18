-- ============================================================
-- MANNERRIEGE - Avaliações periódicas do atleta (físico/técnico/
-- psicológico)
-- Rode DEPOIS do migration_089.
--
-- Diferente da nota de desempenho por evento (evento_participantes_base
-- .desempenho_nota, que é uma anotação rápida do treino/jogo), isso
-- aqui é um acompanhamento periódico e mais completo, associado
-- diretamente ao atleta (não a um evento específico).
-- ============================================================

create table public.avaliacoes_atleta_base (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atletas_base (id) on delete cascade,
  tipo text not null check (tipo in ('fisico', 'tecnico', 'psicologico')),
  data date not null default current_date,
  nota numeric(3, 1) check (nota between 0 and 10),
  observacoes text,
  avaliador_id uuid references public.profiles (id) on delete set null,
  criado_em timestamptz not null default now()
);

alter table public.avaliacoes_atleta_base enable row level security;

create policy "Equipe da base gerencia avaliacoes"
  on public.avaliacoes_atleta_base for all
  using (public.is_base())
  with check (public.is_base());

create policy "Responsavel ve as avaliacoes dos seus atletas"
  on public.avaliacoes_atleta_base for select
  using (public.responsavel_do_atleta(atleta_id));

create policy "Atleta ve as proprias avaliacoes"
  on public.avaliacoes_atleta_base for select
  using (public.atleta_e_proprio(atleta_id));
