-- ============================================================
-- MANNERRIEGE - Histórico de pagamentos do rateio
--
-- Cada linha é um pagamento (pode ser parcial). O total pago por um
-- participante é a soma de todas as linhas dele. Isso permite saber
-- quem pagou tudo, quem pagou só uma parte, e quem ainda não pagou nada
-- - inclusive olhando o histórico dele em campeonatos anteriores.
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.campeonato_participante_pagamentos (
  id uuid primary key default gen_random_uuid(),
  campeonato_participante_id uuid not null references public.campeonato_participantes (id) on delete cascade,
  valor numeric(10, 2) not null,
  data_pagamento date not null default current_date,
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.campeonato_participante_pagamentos enable row level security;

create policy "Diretoria e coordenacao gerenciam pagamentos"
  on public.campeonato_participante_pagamentos for all
  using (public.is_esportivo())
  with check (public.is_esportivo());

create policy "Associado ve seus proprios pagamentos"
  on public.campeonato_participante_pagamentos for select
  using (
    exists (
      select 1 from public.campeonato_participantes cp
      where cp.id = campeonato_participante_pagamentos.campeonato_participante_id
        and cp.tipo = 'associado'
        and cp.associado_id = auth.uid()
    )
  );
