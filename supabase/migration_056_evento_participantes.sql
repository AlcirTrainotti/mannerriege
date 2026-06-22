-- ============================================================
-- MANNERRIEGE - Participantes de eventos, rateio, confirmação e
-- fechamento / prestação de contas do evento
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.eventos
  add column if not exists custo_total numeric(10, 2) default 0, -- custo a ratear entre os confirmados (opcional)
  add column if not exists fechado boolean not null default false,
  add column if not exists fechado_em timestamptz,
  add column if not exists fechado_por uuid references public.profiles (id);

create table public.evento_participantes (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null references public.eventos (id) on delete cascade,
  tipo text not null check (tipo in ('associado', 'convidado')),
  associado_id uuid references public.profiles (id) on delete cascade,
  convidado_id uuid references public.convidados (id) on delete cascade,
  confirmado boolean not null default false,
  data_confirmacao timestamptz,
  pago boolean not null default false,
  data_pagamento date,
  criado_em timestamptz not null default now(),
  check (
    (tipo = 'associado' and associado_id is not null and convidado_id is null) or
    (tipo = 'convidado' and convidado_id is not null and associado_id is null)
  )
);

alter table public.evento_participantes enable row level security;

create policy "Diretoria e tesouraria gerenciam participantes de evento"
  on public.evento_participantes for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

create policy "Associado ve sua propria participacao em eventos"
  on public.evento_participantes for select
  using (tipo = 'associado' and associado_id = auth.uid());
