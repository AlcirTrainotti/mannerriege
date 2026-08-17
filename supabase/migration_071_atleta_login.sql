-- ============================================================
-- MANNERRIEGE - Acesso do próprio atleta (conta só de leitura) e
-- funções que finalizam a criação de login sem precisar de Edge
-- Function (a conta em si é criada no frontend com um cliente
-- Supabase temporário, mesmo padrão de AdminAssociados.vue — só o
-- papel/vínculo final precisa rodar com privilégio elevado, porque a
-- policy de update de profiles é "somente admin").
-- Rode DEPOIS do migration_070.
-- ============================================================

create function public.atleta_e_proprio(p_atleta_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.atletas_base
    where id = p_atleta_id and profile_id = auth.uid()
  );
$$ language sql security definer stable set search_path = public;

-- Só SELECT — nenhuma policy de insert/update/delete é criada para o
-- atleta em nenhuma tabela do módulo, de propósito. Toda escrita fica
-- com a equipe (is_base()) ou com o responsável (responsavel_do_atleta),
-- nunca com o próprio menor.
create policy "Atleta ve o proprio cadastro"
  on public.atletas_base for select
  using (public.atleta_e_proprio(id));

-- --------------------------------------------------------------
-- Ativa o login (só leitura) de um atleta: o responsável (ou a
-- equipe) já criou a conta no Supabase Auth pelo frontend (signUp
-- com e-mail-alias interno); esta função só confirma o papel
-- correto e vincula o atleta a essa conta. security definer porque
-- alterar profiles.role exige ser admin (RLS), e um responsável comum
-- não é.
-- --------------------------------------------------------------
create function public.ativar_login_atleta(p_atleta_id uuid, p_profile_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not (public.is_base() or public.responsavel_do_atleta(p_atleta_id)) then
    raise exception 'Sem permissão para ativar esse login';
  end if;

  if exists (select 1 from public.atletas_base where id = p_atleta_id and profile_id is not null) then
    raise exception 'Este atleta já tem um login criado';
  end if;

  update public.profiles set role = 'atleta_base' where id = p_profile_id;
  update public.atletas_base set profile_id = p_profile_id where id = p_atleta_id;
end;
$$;

-- --------------------------------------------------------------
-- Mesma lógica pro cadastro do responsável: a equipe (coordenação da
-- base) cria a conta pelo frontend com o cliente temporário, e esta
-- função confirma o papel 'responsavel_base'.
-- --------------------------------------------------------------
create function public.definir_role_responsavel_base(p_profile_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_coordenador_base() then
    raise exception 'Sem permissão para cadastrar responsável';
  end if;

  update public.profiles set role = 'responsavel_base' where id = p_profile_id;
end;
$$;
