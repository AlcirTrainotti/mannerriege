-- ============================================================
-- MANNERRIEGE - Editar contato do responsável a partir da tela de
-- Atletas (edição do cadastro)
-- Rode DEPOIS do migration_082.
--
-- Mesma razão de sempre: RLS de profiles é "próprio perfil ou admin",
-- então staff da base (não-admin) não pode dar update direto no
-- profile de outra pessoa (o responsável). Esta RPC faz a checagem
-- própria (is_base()) e atualiza nome/telefone/e-mail do responsável
-- em profiles + o parentesco em atleta_responsaveis.
-- ============================================================

create function public.atualizar_contato_responsavel_base(
  p_atleta_id uuid,
  p_responsavel_id uuid,
  p_nome text,
  p_telefone text,
  p_email text,
  p_parentesco text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_base() then
    raise exception 'Sem permissão para atualizar este contato.';
  end if;

  update public.profiles
  set
    nome = coalesce(nullif(trim(p_nome), ''), nome),
    telefone = nullif(trim(p_telefone), ''),
    email = coalesce(nullif(trim(p_email), ''), email)
  where id = p_responsavel_id;

  update public.atleta_responsaveis
  set parentesco = nullif(trim(p_parentesco), '')
  where atleta_id = p_atleta_id and responsavel_id = p_responsavel_id;
end;
$$;
