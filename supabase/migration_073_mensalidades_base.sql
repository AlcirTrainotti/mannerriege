-- ============================================================
-- MANNERRIEGE - Mensalidades das Categorias de Base
-- Já funcional desde o lançamento (piloto no plano gratuito gera
-- mensalidade com status 'isento', não fica em branco). Lançar um
-- plano pago no futuro não exige nenhuma migration nova: só cadastrar
-- o plano com valor > 0 e mover os atletas pra ele.
-- Rode DEPOIS do migration_072.
-- ============================================================

create table public.mensalidades_base (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atletas_base (id) on delete cascade,
  competencia date not null, -- sempre o dia 1 do mês de referência
  valor numeric(10, 2) not null,
  status text not null default 'pendente' check (status in ('isento', 'pendente', 'pago')),
  data_pagamento date,
  criado_em timestamptz not null default now(),
  unique (atleta_id, competencia)
);

alter table public.mensalidades_base enable row level security;

create policy "Equipe da base gerencia mensalidades"
  on public.mensalidades_base for all
  using (public.is_coordenador_base())
  with check (public.is_coordenador_base());

create policy "Responsavel ve as mensalidades dos seus atletas"
  on public.mensalidades_base for select
  using (public.responsavel_do_atleta(atleta_id));

create policy "Atleta ve as proprias mensalidades"
  on public.mensalidades_base for select
  using (public.atleta_e_proprio(atleta_id));

-- ============================================================
-- Gera a mensalidade do mês pra todo atleta ativo que ainda não tem
-- uma competência daquele mês (não duplica se rodar de novo sem
-- querer). Valor vem do plano vigente do atleta — se for 0 (plano
-- gratuito), a mensalidade é criada com status 'isento' em vez de
-- ficar sem registro nenhum, pra aparecer certo no painel do
-- responsável.
-- ============================================================
create function public.gerar_mensalidades_base_mes(p_competencia date)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_criadas integer;
begin
  if not public.is_coordenador_base() then
    raise exception 'Apenas a coordenação da base pode gerar mensalidades';
  end if;

  insert into public.mensalidades_base (atleta_id, competencia, valor, status)
  select
    a.id,
    date_trunc('month', p_competencia)::date,
    pb.valor_mensal,
    case when pb.valor_mensal = 0 then 'isento' else 'pendente' end
  from public.atletas_base a
  join public.atleta_plano ap on ap.atleta_id = a.id and ap.data_fim is null
  join public.planos_base pb on pb.id = ap.plano_id
  where a.status = 'ativo'
  on conflict (atleta_id, competencia) do nothing;

  get diagnostics v_criadas = row_count;
  return v_criadas;
end;
$$;
