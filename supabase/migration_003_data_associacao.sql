-- ============================================================
-- MANNERRIEGE - Data de associacao
-- Rode este script no Supabase SQL Editor DEPOIS do migration_002
-- ============================================================

alter table public.profiles
  add column if not exists data_associacao date;
