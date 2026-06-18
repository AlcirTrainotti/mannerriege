-- ============================================================
-- MANNERRIEGE - Telefone/WhatsApp do associado
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.profiles
  add column if not exists telefone text;
