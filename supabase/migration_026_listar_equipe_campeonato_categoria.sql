-- ============================================================
-- MANNERRIEGE - Equipe de uma categoria, visível para quem participa
--
-- Permite que um associado veja os nomes dos colegas de equipe
-- (associados e convidados) de uma categoria de campeonato em que ele
-- mesmo está escalado - sem dar acesso geral à lista de associados ou
-- convidados. Diretoria e coordenação sempre veem tudo.
-- ============================================================

create function public.listar_equipe_campeonato_categoria(p_categoria_id uuid)
returns table (id uuid, tipo text, nome text, funcao text)
language sql
security definer
set search_path = public
as $$
  select
    cp.id,
    cp.tipo,
    case when cp.tipo = 'associado' then assoc.nome else conv.nome end as nome,
    cp.funcao
  from public.campeonato_participantes cp
  left join public.profiles assoc on assoc.id = cp.associado_id
  left join public.convidados conv on conv.id = cp.convidado_id
  where cp.campeonato_categoria_id = p_categoria_id
    and (
      public.is_esportivo()
      or exists (
        select 1 from public.campeonato_participantes minha
        where minha.tipo = 'associado'
          and minha.associado_id = auth.uid()
          and minha.campeonato_categoria_id = p_categoria_id
      )
    );
$$;
