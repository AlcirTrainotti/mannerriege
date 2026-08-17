-- ============================================================
-- MANNERRIEGE - Planos das Categorias de Base
-- Estrutura já pronta pra mensalidade, ativa desde o lançamento
-- (piloto no plano gratuito) — lançar um plano pago no futuro é só
-- cadastrar um novo plano aqui, sem precisar de deploy novo.
-- Rode DEPOIS do migration_067.
-- ============================================================

create table public.planos_base (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  valor_mensal numeric(10, 2) not null default 0,
  descricao text,
  padrao boolean not null default false, -- atribuído automaticamente a todo atleta novo
  ativo boolean not null default true,
  ordem integer not null default 0,
  criado_em timestamptz not null default now()
);

comment on column public.planos_base.padrao is
  'No máximo um plano marcado como padrão por vez (ver índice único abaixo) — é o plano atribuído automaticamente quando um atleta é cadastrado.';

-- Garante no máximo um plano padrão por vez
create unique index planos_base_unico_padrao on public.planos_base (padrao) where padrao;

alter table public.planos_base enable row level security;

create policy "Equipe da base gerencia planos"
  on public.planos_base for all
  using (public.is_coordenador_base())
  with check (public.is_coordenador_base());

create policy "Participantes da base leem planos"
  on public.planos_base for select
  using (public.is_participante_base());

insert into public.planos_base (nome, valor_mensal, descricao, padrao, ordem) values (
  'Plano Piloto Gratuito',
  0,
  'Formação gratuita do piloto 2026 (Sub-13/Sub-15) — fase social até fev/2027, conforme cronograma do projeto.',
  true,
  1
);
