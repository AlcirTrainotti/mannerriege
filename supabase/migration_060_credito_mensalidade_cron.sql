-- ============================================================
-- MANNERRIEGE - Crédito de mensalidade (pagamento adiantado)
--
-- Quando um associado paga várias mensalidades de uma vez (ex: PIX do
-- ano todo), o valor vira um "crédito". Toda vez que a mensalidade do
-- mês for gerada, o sistema desconta automaticamente desse crédito,
-- até ele acabar.
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.mensalidades
  add column if not exists pago_via_credito boolean not null default false;

create table public.associado_creditos_mensalidade (
  id uuid primary key default gen_random_uuid(),
  associado_id uuid not null references public.profiles (id) on delete cascade,
  valor numeric(10, 2) not null,
  tipo text not null check (tipo in ('credito', 'uso')),
  descricao text,
  mensalidade_id uuid references public.mensalidades (id) on delete set null,
  criado_em timestamptz not null default now()
);

alter table public.associado_creditos_mensalidade enable row level security;

create policy "Diretoria e tesouraria gerenciam creditos"
  on public.associado_creditos_mensalidade for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

create policy "Associado ve o proprio historico de credito"
  on public.associado_creditos_mensalidade for select
  using (associado_id = auth.uid());

-- ============================================================
-- Funcao "miolo": faz a geracao das mensalidades do mes e tenta abater
-- do credito de cada associado. Nao tem checagem de permissao - so e
-- chamada pela funcao publica (uso interativo) ou pelo job agendado
-- (pg_cron). Por isso a execucao dela e revogada de anon/authenticated.
-- ============================================================
create function public._gerar_mensalidades_mes_core(p_competencia date)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_criadas integer;
  v_valor_socio numeric(10, 2);
  v_valor_padrao numeric(10, 2);
  v_rec record;
  v_saldo numeric(10, 2);
begin
  select valor_socio_ginastico, valor_padrao
    into v_valor_socio, v_valor_padrao
    from public.configuracao_mensalidade where id = 1;

  create temporary table tmp_novas_mensalidades on commit drop as
  with inseridas as (
    insert into public.mensalidades (associado_id, competencia, valor)
    select
      p.id,
      date_trunc('month', p_competencia)::date,
      case when p.socio_ginastico then coalesce(v_valor_socio, 30) else coalesce(v_valor_padrao, 50) end
    from public.profiles p
    where p.status <> 'inativo'
    on conflict (associado_id, competencia) do nothing
    returning id, associado_id, valor
  )
  select * from inseridas;

  get diagnostics v_criadas = row_count;

  for v_rec in select * from tmp_novas_mensalidades loop
    select coalesce(sum(case when tipo = 'credito' then valor else -valor end), 0)
      into v_saldo
      from public.associado_creditos_mensalidade
      where associado_id = v_rec.associado_id;

    if v_saldo >= v_rec.valor then
      update public.mensalidades
        set pago = true, pago_via_credito = true, data_pagamento = current_date
        where id = v_rec.id;

      insert into public.associado_creditos_mensalidade (associado_id, valor, tipo, descricao, mensalidade_id)
      values (v_rec.associado_id, v_rec.valor, 'uso', 'Abatido automaticamente do crédito', v_rec.id);
    end if;
  end loop;

  return v_criadas;
end;
$$;

revoke execute on function public._gerar_mensalidades_mes_core(date) from public, anon, authenticated;

create or replace function public.gerar_mensalidades_mes(p_competencia date)
returns integer
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_financeiro() then
    raise exception 'Apenas administradores ou tesoureiro podem gerar mensalidades';
  end if;
  return public._gerar_mensalidades_mes_core(p_competencia);
end;
$$;

-- ============================================================
-- Lista de associados ativos para o financeiro (lançamento de
-- mensalidade, crédito, etc.)
-- ============================================================
create function public.listar_associados_financeiro()
returns table (id uuid, nome text, status text)
language sql
security definer
set search_path = public
as $$
  select p.id, p.nome, p.status
  from public.profiles p
  where public.is_financeiro();
$$;

-- ============================================================
-- Permite o tipo "mensalidade_adiantada" nas receitas gerais (usado
-- pelo Lançamento Rápido quando um associado paga várias mensalidades
-- de uma vez).
-- ============================================================
alter table public.financeiro_receitas drop constraint if exists financeiro_receitas_tipo_check;
alter table public.financeiro_receitas add constraint financeiro_receitas_tipo_check
  check (tipo in ('chamada_capital', 'doacao', 'patrocinio', 'mensalidade_adiantada', 'outro'));

-- ============================================================
-- Job agendado: gera as mensalidades do mes automaticamente, todo
-- dia 1, as 9h UTC (6h da manha no horario de Brasilia).
-- ============================================================
create extension if not exists pg_cron;

select cron.schedule(
  'gerar-mensalidades-mensal',
  '0 9 1 * *',
  $$select public._gerar_mensalidades_mes_core(date_trunc('month', current_date)::date)$$
);
