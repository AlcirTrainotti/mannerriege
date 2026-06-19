-- ============================================================
-- MANNERRIEGE - E-mail no cadastro de convidado
-- Útil para guardar o contato e para quando um ex-associado vira
-- convidado (mantém o e-mail que ele já tinha).
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.convidados
  add column if not exists email text;
