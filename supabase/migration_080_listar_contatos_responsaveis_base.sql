-- ============================================================
-- MANNERRIEGE - Contato dos responsáveis, pra equipe da base ver na
-- lista de atletas (telefone/e-mail)
-- Rode DEPOIS do migration_076.
--
-- A policy de leitura de profiles é "o próprio perfil ou admin" — como
-- professor_base/coordenador_base não são admin, um select comum com
-- join embutido em profiles (responsavel:profiles(...)) não traria o
-- contato de outra pessoa. Mesma solução já usada em
-- listar_responsaveis_base() e buscar_responsavel_base().
-- ============================================================

create function public.listar_contatos_responsaveis_base()
returns table (atleta_id uuid, responsavel_id uuid, responsavel_nome text, telefone text, email text, parentesco text)
language sql
security definer
stable
set search_path = public
as $$
  select ar.atleta_id, ar.responsavel_id, p.nome, p.telefone, p.email, ar.parentesco
  from public.atleta_responsaveis ar
  join public.profiles p on p.id = ar.responsavel_id
  where public.is_base();
$$;
