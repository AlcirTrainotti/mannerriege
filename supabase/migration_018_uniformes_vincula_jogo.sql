-- ============================================================
-- MANNERRIEGE - Vincula cada peça de uniforme ao seu conjunto
-- Rode no Supabase SQL Editor depois do migration_017
-- ============================================================

alter table public.uniformes
  add column if not exists jogo_uniforme_id uuid references public.jogos_uniforme (id) on delete set null;
