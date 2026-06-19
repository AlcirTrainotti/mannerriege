-- ============================================================
-- MANNERRIEGE - Quantidades de camisas/bermudas passam a ser
-- calculadas automaticamente a partir das peças cadastradas,
-- então os campos manuais não são mais necessários.
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.jogos_uniforme
  drop column if exists quantidade_camisas,
  drop column if exists quantidade_bermudas;
