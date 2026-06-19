-- ============================================================
-- MANNERRIEGE - Posição de jogo do associado
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.profiles
  add column if not exists posicao text
    check (posicao in ('ponteiro', 'libero', 'levantador', 'meio', 'oposto', 'tecnico', 'outro'));
