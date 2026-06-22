-- ============================================================
-- MANNERRIEGE - Fechamento anual + resumo financeiro para associados
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.fechamentos_anuais (
  id uuid primary key default gen_random_uuid(),
  ano integer not null unique,
  total_receitas numeric(10, 2) not null default 0,
  total_despesas numeric(10, 2) not null default 0,
  saldo numeric(10, 2) not null default 0,
  observacoes text,
  fechado_por uuid references public.profiles (id),
  fechado_em timestamptz not null default now()
);

alter table public.fechamentos_anuais enable row level security;

create policy "Financeiro gerencia fechamentos anuais"
  on public.fechamentos_anuais for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

create policy "Associado ve os fechamentos anuais"
  on public.fechamentos_anuais for select
  using (auth.uid() is not null);

-- ============================================================
-- Resumo financeiro publico: numeros agregados, sem detalhar cada
-- lancamento, para qualquer associado logado conferir a saude
-- financeira do clube.
-- ============================================================
create function public.resumo_financeiro_associado(p_ano integer)
returns table (total_receitas numeric, total_despesas numeric, saldo numeric, associados_adimplentes integer, associados_total integer)
language sql
security definer
stable
set search_path = public
as $$
  select
    (
      coalesce((select sum(valor) from public.mensalidades where pago = true and extract(year from competencia) = p_ano), 0) +
      coalesce((select sum(valor) from public.financeiro_receitas where extract(year from data) = p_ano), 0) +
      coalesce((select sum(valor) from public.evento_receitas where extract(year from criado_em) = p_ano), 0)
    ) as total_receitas,
    (
      coalesce((select sum(valor) from public.financeiro_despesas where extract(year from data) = p_ano), 0) +
      coalesce((select sum(valor) from public.evento_despesas where extract(year from criado_em) = p_ano), 0)
    ) as total_despesas,
    (
      coalesce((select sum(valor) from public.mensalidades where pago = true and extract(year from competencia) = p_ano), 0) +
      coalesce((select sum(valor) from public.financeiro_receitas where extract(year from data) = p_ano), 0) +
      coalesce((select sum(valor) from public.evento_receitas where extract(year from criado_em) = p_ano), 0)
      -
      coalesce((select sum(valor) from public.financeiro_despesas where extract(year from data) = p_ano), 0) -
      coalesce((select sum(valor) from public.evento_despesas where extract(year from criado_em) = p_ano), 0)
    ) as saldo,
    (select count(*)::integer from public.profiles where status = 'adimplente') as associados_adimplentes,
    (select count(*)::integer from public.profiles) as associados_total
  where auth.uid() is not null;
$$;
