-- ============================================================
-- MANNERRIEGE - Evento passa a puxar o local do cadastro de Quadras
-- Rode DEPOIS do migration_084.
-- ============================================================

alter table public.eventos_base
  add column quadra_id uuid references public.quadras (id) on delete restrict;

comment on column public.eventos_base.quadra_id is
  'Quadra oficial do cadastro centralizado. O campo "local" (texto livre) vira só um complemento opcional (ex: "portão dos fundos").';
