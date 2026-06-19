-- ============================================================
-- MANNERRIEGE - Correção: recursão infinita na regra de participantes
--
-- A regra anterior fazia uma subconsulta direta na própria tabela
-- campeonato_participantes dentro da política de SELECT dela mesma,
-- o que o Postgres não permite (gera "infinite recursion"). A correção
-- é igual ao padrão já usado em is_admin()/is_esportivo(): mover a
-- checagem para uma função "security definer", que não reaciona as
-- regras de segurança ao consultar a tabela.
-- ============================================================

create function public.participo_da_categoria(p_categoria_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.campeonato_participantes
    where tipo = 'associado'
      and associado_id = auth.uid()
      and campeonato_categoria_id = p_categoria_id
  );
$$;

drop policy if exists "Associado ve equipe dos campeonatos que participa" on public.campeonato_participantes;

create policy "Associado ve equipe dos campeonatos que participa"
  on public.campeonato_participantes for select
  using (public.participo_da_categoria(campeonato_categoria_id));
