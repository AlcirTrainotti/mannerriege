-- ============================================================
-- MANNERRIEGE - Responsável do campeonato, datas de inscrição
-- e regulamento (PDF + resumo)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.campeonatos
  add column if not exists responsavel_id uuid references public.profiles (id),
  add column if not exists data_inscricao_equipe date,
  add column if not exists data_inscricao_atletas date,
  add column if not exists regulamento_url text,
  add column if not exists regulamento_resumo text;
