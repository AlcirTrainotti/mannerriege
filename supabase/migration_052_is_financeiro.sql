-- ============================================================
-- MANNERRIEGE - Permissões do módulo Financeiro
-- Rode DEPOIS do migration_051 (executado sozinho, numa execução
-- anterior e separada).
--
-- Cria a função is_financeiro() (admin OU tesoureiro) e atualiza todas
-- as regras do financeiro para usá-la, no lugar de só is_admin().
-- ============================================================

create function public.is_financeiro()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'tesoureiro')
  );
$$ language sql security definer stable set search_path = public;

-- Mensalidades
drop policy if exists "Diretoria gerencia mensalidades" on public.mensalidades;
create policy "Diretoria e tesouraria gerenciam mensalidades"
  on public.mensalidades for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

-- Receitas gerais
drop policy if exists "Diretoria gerencia receitas gerais" on public.financeiro_receitas;
create policy "Diretoria e tesouraria gerenciam receitas gerais"
  on public.financeiro_receitas for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

-- Despesas gerais
drop policy if exists "Diretoria gerencia despesas gerais" on public.financeiro_despesas;
create policy "Diretoria e tesouraria gerenciam despesas gerais"
  on public.financeiro_despesas for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

-- Patrocinadores
drop policy if exists "Diretoria gerencia patrocinadores" on public.patrocinadores;
create policy "Diretoria e tesouraria gerenciam patrocinadores"
  on public.patrocinadores for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

-- Parceiros
drop policy if exists "Diretoria gerencia parceiros" on public.parceiros;
create policy "Diretoria e tesouraria gerenciam parceiros"
  on public.parceiros for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

-- Locais para festas
drop policy if exists "Diretoria gerencia locais para festas" on public.locais_festa;
create policy "Diretoria e tesouraria gerenciam locais"
  on public.locais_festa for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

-- Eventos
drop policy if exists "Diretoria gerencia eventos" on public.eventos;
create policy "Diretoria e tesouraria gerenciam eventos"
  on public.eventos for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

drop policy if exists "Diretoria gerencia despesas de eventos" on public.evento_despesas;
create policy "Diretoria e tesouraria gerenciam despesas de eventos"
  on public.evento_despesas for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

drop policy if exists "Diretoria gerencia receitas de eventos" on public.evento_receitas;
create policy "Diretoria e tesouraria gerenciam receitas de eventos"
  on public.evento_receitas for all
  using (public.is_financeiro())
  with check (public.is_financeiro());

-- A funcao de gerar mensalidades tambem passa a aceitar tesoureiro
create or replace function public.gerar_mensalidades_mes(p_competencia date)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_criadas integer;
begin
  if not public.is_financeiro() then
    raise exception 'Apenas administradores ou tesoureiro podem gerar mensalidades';
  end if;

  insert into public.mensalidades (associado_id, competencia, valor)
  select
    p.id,
    date_trunc('month', p_competencia)::date,
    case when p.socio_ginastico then 30 else 50 end
  from public.profiles p
  where p.status <> 'inativo'
  on conflict (associado_id, competencia) do nothing;

  get diagnostics v_criadas = row_count;
  return v_criadas;
end;
$$;
