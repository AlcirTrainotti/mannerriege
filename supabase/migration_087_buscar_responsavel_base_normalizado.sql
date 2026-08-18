-- ============================================================
-- MANNERRIEGE - Corrige buscar_responsavel_base pra comparar telefone
-- normalizado (só dígitos) e e-mail sem diferenciar maiúsculas/minúsculas
-- Rode DEPOIS do migration_086.
--
-- Causa raiz de um bug real: o telefone do responsável ficou salvo com
-- uma formatação (ex: "(47) 99925-7045") e o telefone digitado depois
-- (ex: "47999257045") não batia na comparação exata (telefone = p_telefone),
-- então a busca não encontrava o responsável já cadastrado e o sistema
-- tentava criar um responsável duplicado.
-- ============================================================

create or replace function public.buscar_responsavel_base(p_telefone text, p_email text)
returns table (id uuid, nome text, telefone text, email text)
language sql
security definer
stable
set search_path = public
as $$
  select id, nome, telefone, email
  from public.profiles
  where role = 'responsavel_base'
    and public.is_base()
    and (
      (p_telefone is not null and p_telefone <> '' and regexp_replace(telefone, '\D', '', 'g') = regexp_replace(p_telefone, '\D', '', 'g'))
      or (p_email is not null and p_email <> '' and lower(email) = lower(p_email))
    )
  order by criado_em
  limit 1;
$$;
