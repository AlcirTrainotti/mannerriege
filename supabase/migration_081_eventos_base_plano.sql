-- ============================================================
-- MANNERRIEGE - Plano associado a cada evento
-- Rode DEPOIS do migration_080.
--
-- O Alcir pediu pra todo evento ter um plano vinculado (ex: qual
-- plano cobre a participação num festival/campeonato específico,
-- diferente do plano mensal "padrão" do atleta).
-- ============================================================

alter table public.eventos_base
  add column plano_id uuid references public.planos_base (id) on delete set null;

comment on column public.eventos_base.plano_id is
  'Plano vinculado a este evento (opcional) — indica qual plano cobre a participação nele. Pode ser diferente do plano mensal vigente do atleta.';
