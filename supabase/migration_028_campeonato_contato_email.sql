-- ============================================================
-- MANNERRIEGE - E-mail de contato do campeonato
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.campeonatos
  add column if not exists contato_email text;
