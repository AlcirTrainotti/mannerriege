-- ============================================================
-- MANNERRIEGE - Controle de pagamento do rateio e entrega de medalha
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.campeonato_participantes
  add column if not exists pago boolean not null default false,
  add column if not exists data_pagamento date,
  add column if not exists medalha_entregue boolean not null default false;
