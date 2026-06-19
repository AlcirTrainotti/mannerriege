-- ============================================================
-- MANNERRIEGE - Cidade e time de origem do convidado
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.convidados
  add column if not exists cidade text,
  add column if not exists time_origem text;
