-- ============================================================
-- MANNERRIEGE - Associados elegíveis para responder pela retirada
-- de materiais (uniformes/bolas) de um campeonato
--
-- Só aparece quem: (1) é adimplente com a associação, e (2) está
-- escalado em alguma categoria deste campeonato. A função nunca expõe
-- o status financeiro em si para o coordenador esportivo - só devolve
-- os nomes de quem já atende aos dois critérios.
-- ============================================================

create function public.listar_responsaveis_elegiveis(p_campeonato_id uuid)
returns table (id uuid, nome text)
language sql
security definer
set search_path = public
as $$
  select distinct p.id, p.nome
  from public.profiles p
  join public.campeonato_participantes cp on cp.associado_id = p.id and cp.tipo = 'associado'
  join public.campeonato_categorias cc on cc.id = cp.campeonato_categoria_id
  where cc.campeonato_id = p_campeonato_id
    and p.status = 'adimplente'
    and public.is_esportivo();
$$;
