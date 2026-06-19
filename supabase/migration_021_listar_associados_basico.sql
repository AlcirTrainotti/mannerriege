-- ============================================================
-- MANNERRIEGE - Lista básica de associados para montar equipe
--
-- O coordenador esportivo não tem acesso à tela de Associados (só a
-- diretoria tem), mas precisa enxergar nome/nascimento/modalidade dos
-- associados para poder escalar quem vai jogar em cada campeonato.
-- Esta função devolve só esses campos, nunca CPF, status financeiro,
-- telefone ou papel - e só funciona para quem já é diretoria ou
-- coordenação esportiva.
-- ============================================================

create function public.listar_associados_basico()
returns table (id uuid, nome text, data_nascimento date, modalidade public.modalidade_jogo)
language sql
security definer
set search_path = public
as $$
  select p.id, p.nome, p.data_nascimento, p.modalidade
  from public.profiles p
  where public.is_esportivo();
$$;
