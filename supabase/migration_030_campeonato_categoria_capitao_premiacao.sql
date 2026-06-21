-- ============================================================
-- MANNERRIEGE - Capitão e premiação de cada categoria
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.campeonato_categorias
  add column if not exists capitao_participante_id uuid references public.campeonato_participantes (id) on delete set null,
  add column if not exists colocacao text,
  add column if not exists premiacao_tipo text check (premiacao_tipo in ('dinheiro', 'vaga_outro_campeonato', 'medalha_trofeu', 'outro')),
  add column if not exists premiacao_descricao text,
  add column if not exists premiacao_valor numeric(10, 2);
