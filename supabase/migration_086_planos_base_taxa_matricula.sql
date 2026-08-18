-- ============================================================
-- MANNERRIEGE - Taxa de matrícula opcional por plano
-- Rode DEPOIS do migration_085.
-- ============================================================

alter table public.planos_base
  add column cobra_taxa_matricula boolean not null default false,
  add column valor_taxa_matricula numeric(10, 2);

comment on column public.planos_base.cobra_taxa_matricula is
  'Se true, este plano cobra uma taxa de matrícula (valor único na entrada), além da mensalidade.';
comment on column public.planos_base.valor_taxa_matricula is
  'Valor da taxa de matrícula, só relevante quando cobra_taxa_matricula = true.';
