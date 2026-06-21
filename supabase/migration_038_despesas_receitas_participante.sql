-- ============================================================
-- MANNERRIEGE - Quem assumiu a despesa / quem fez o aporte
-- agora referencia um participante já cadastrado no campeonato,
-- em vez de texto livre.
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.campeonato_categoria_despesas
  add column if not exists assumido_participante_id uuid references public.campeonato_participantes (id) on delete set null;

alter table public.campeonato_categoria_receitas
  add column if not exists aportado_participante_id uuid references public.campeonato_participantes (id) on delete set null;
