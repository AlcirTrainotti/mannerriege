-- ============================================================
-- MANNERRIEGE - Sócio do ginástico (define o valor da mensalidade)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.profiles
  add column if not exists socio_ginastico boolean not null default false;

comment on column public.profiles.socio_ginastico is 'Se true, mensalidade de R$30. Se false, mensalidade de R$50.';
