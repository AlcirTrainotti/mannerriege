-- ============================================================
-- MANNERRIEGE - Financeiro das Categorias de Base (novo e separado do
-- financeiro do Master — não compartilha tabelas nem saldo)
-- Rode DEPOIS do migration_091.
--
-- "Contas a pagar/receber" e "lançamentos financeiros" moram nas
-- mesmas duas tabelas (despesas/receitas): um lançamento nasce
-- 'pendente' (é uma conta a pagar/receber em aberto) e vira
-- 'pago'/'recebido' quando baixado (isso é o "encontro de contas").
-- "Fechamentos" é um snapshot mensal congelado, pra não depender de
-- recalcular o histórico depois.
-- "Gestão de matrículas" é a tabela matriculas_base: controla a taxa
-- de matrícula (planos_base.valor_taxa_matricula) de cada atleta,
-- gerada automaticamente quando o plano dele cobra taxa.
-- ============================================================

create table public.financeiro_base_despesas (
  id uuid primary key default gen_random_uuid(),
  descricao text not null,
  valor numeric(10, 2) not null,
  categoria text not null default 'outro',
  data date not null default current_date,
  vencimento date,
  status text not null default 'pago' check (status in ('pendente', 'pago')),
  data_pagamento date,
  criado_por uuid references public.profiles (id) on delete set null,
  criado_em timestamptz not null default now()
);

create table public.financeiro_base_receitas (
  id uuid primary key default gen_random_uuid(),
  descricao text not null,
  valor numeric(10, 2) not null,
  tipo text not null default 'outro',
  origem_nome text,
  data date not null default current_date,
  vencimento date,
  status text not null default 'recebido' check (status in ('pendente', 'recebido')),
  data_recebimento date,
  criado_por uuid references public.profiles (id) on delete set null,
  criado_em timestamptz not null default now()
);

create table public.fechamentos_base (
  id uuid primary key default gen_random_uuid(),
  competencia date not null unique, -- dia 1 do mês fechado
  total_receitas numeric(10, 2) not null,
  total_despesas numeric(10, 2) not null,
  saldo numeric(10, 2) not null,
  observacoes text,
  fechado_por uuid references public.profiles (id) on delete set null,
  criado_em timestamptz not null default now()
);

create table public.matriculas_base (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atletas_base (id) on delete cascade,
  plano_id uuid not null references public.planos_base (id),
  valor numeric(10, 2) not null,
  status text not null default 'pendente' check (status in ('pendente', 'pago', 'isento')),
  data_pagamento date,
  criado_em timestamptz not null default now()
);

alter table public.financeiro_base_despesas enable row level security;
alter table public.financeiro_base_receitas enable row level security;
alter table public.fechamentos_base enable row level security;
alter table public.matriculas_base enable row level security;

create policy "Equipe da base gerencia despesas base"
  on public.financeiro_base_despesas for all
  using (public.is_coordenador_base())
  with check (public.is_coordenador_base());

create policy "Equipe da base gerencia receitas base"
  on public.financeiro_base_receitas for all
  using (public.is_coordenador_base())
  with check (public.is_coordenador_base());

create policy "Equipe da base gerencia fechamentos base"
  on public.fechamentos_base for all
  using (public.is_coordenador_base())
  with check (public.is_coordenador_base());

create policy "Equipe da base gerencia matriculas"
  on public.matriculas_base for all
  using (public.is_coordenador_base())
  with check (public.is_coordenador_base());

create policy "Responsavel ve as matriculas dos seus atletas"
  on public.matriculas_base for select
  using (public.responsavel_do_atleta(atleta_id));

create policy "Atleta ve as proprias matriculas"
  on public.matriculas_base for select
  using (public.atleta_e_proprio(atleta_id));

-- ============================================================
-- Gera automaticamente a matrícula (taxa de matrícula) quando o plano
-- vigente do atleta cobra taxa. Se o plano não cobra taxa, não cria
-- nada (não polui a gestão de matrículas com linhas irrelevantes).
-- ============================================================
create function public._gerar_matricula_base_se_necessario()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cobra boolean;
  v_valor numeric(10, 2);
begin
  select cobra_taxa_matricula, valor_taxa_matricula
    into v_cobra, v_valor
    from public.planos_base
    where id = new.plano_id;

  if v_cobra then
    insert into public.matriculas_base (atleta_id, plano_id, valor, status)
    values (new.atleta_id, new.plano_id, coalesce(v_valor, 0), 'pendente');
  end if;

  return new;
end;
$$;

create trigger atleta_plano_gera_matricula
  after insert on public.atleta_plano
  for each row execute procedure public._gerar_matricula_base_se_necessario();
