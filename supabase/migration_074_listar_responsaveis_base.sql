-- ============================================================
-- MANNERRIEGE - Listagem de responsáveis para a equipe da base
--
-- A policy de leitura de profiles é "o próprio perfil ou admin" (ver
-- schema.sql) — coordenador_base/professor_base não são admin, então
-- não conseguem simplesmente fazer select * from profiles pra achar
-- um responsável já cadastrado na hora de vincular um atleta novo.
-- Mesma solução já usada em listar_associados_basico() (módulo
-- Esportivo): uma função security definer que devolve só as colunas
-- necessárias.
-- Rode DEPOIS do migration_071.
-- ============================================================

create function public.listar_responsaveis_base()
returns table (id uuid, nome text, telefone text)
language sql
security definer
stable
set search_path = public
as $$
  select id, nome, telefone
  from public.profiles
  where role = 'responsavel_base' and public.is_base()
  order by nome;
$$;
