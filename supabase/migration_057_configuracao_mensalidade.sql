-- ============================================================
-- MANNERRIEGE - Configuração dos valores de mensalidade
-- Permite ajustar os valores sem precisar mexer em código.
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.configuracao_mensalidade (
  id integer primary key default 1,
  valor_socio_ginastico numeric(10, 2) not null default 30,
  valor_padrao numeric(10, 2) not null default 50,
  atualizado_em timestamptz not null default now(),
  atualizado_por uuid references public.profiles (id),
  constraint configuracao_mensalidade_singleton check (id = 1)
);

insert into public.configuracao_mensalidade (id, valor_socio_ginastico, valor_padrao)
values (1, 30, 50)
on conflict (id) do nothing;

alter table public.configuracao_mensalidade enable row level security;

create policy "Diretoria e tesouraria veem a configuracao"
  on public.configuracao_mensalidade for select
  using (public.is_financeiro());

create policy "Diretoria e tesouraria atualizam a configuracao"
  on public.configuracao_mensalidade for update
  using (public.is_financeiro())
  with check (public.is_financeiro());

-- Atualiza a geracao de mensalidades para usar os valores configuraveis
create or replace function public.gerar_mensalidades_mes(p_competencia date)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_criadas integer;
  v_valor_socio numeric(10, 2);
  v_valor_padrao numeric(10, 2);
begin
  if not public.is_financeiro() then
    raise exception 'Apenas administradores ou tesoureiro podem gerar mensalidades';
  end if;

  select valor_socio_ginastico, valor_padrao
    into v_valor_socio, v_valor_padrao
    from public.configuracao_mensalidade where id = 1;

  insert into public.mensalidades (associado_id, competencia, valor)
  select
    p.id,
    date_trunc('month', p_competencia)::date,
    case when p.socio_ginastico then coalesce(v_valor_socio, 30) else coalesce(v_valor_padrao, 50) end
  from public.profiles p
  where p.status <> 'inativo'
  on conflict (associado_id, competencia) do nothing;

  get diagnostics v_criadas = row_count;
  return v_criadas;
end;
$$;
