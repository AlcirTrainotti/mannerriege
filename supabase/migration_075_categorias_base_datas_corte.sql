-- ============================================================
-- MANNERRIEGE - Categorias de Base: datas de corte de nascimento
-- Rode DEPOIS do migration_074.
--
-- Substitui a faixa etária aproximada (idade mínima/máxima) por datas
-- de corte de nascimento exatas — convenção usual de categorias de
-- base (ex: "nascidos entre 01/01/2013 e 31/12/2015"). Usado pra
-- sugerir automaticamente a categoria de um atleta a partir da data de
-- nascimento informada no cadastro.
-- ============================================================

alter table public.categorias_base
  add column if not exists data_corte_min date,
  add column if not exists data_corte_max date;

comment on column public.categorias_base.data_corte_min is
  'Data de nascimento mínima aceita nesta categoria (inclusive) — usada pra sugerir a categoria automaticamente no cadastro do atleta.';
comment on column public.categorias_base.data_corte_max is
  'Data de nascimento máxima aceita nesta categoria (inclusive).';

-- Chute inicial coerente com a faixa etária já semeada (ajustável na
-- própria tela de Categorias, agora que ela permite editar).
update public.categorias_base set data_corte_min = '2013-01-01', data_corte_max = '2015-12-31' where nome = 'Sub-13';
update public.categorias_base set data_corte_min = '2011-01-01', data_corte_max = '2012-12-31' where nome = 'Sub-15';
