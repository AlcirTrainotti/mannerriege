-- ============================================================
-- MANNERRIEGE - "Meu perfil" do responsável: agora também dá pra
-- alterar o próprio nome (além de telefone/e-mail, que já dava desde
-- o migration_094). A foto usa o bucket "avatares" que já existia — a
-- policy "Atualizar proprio avatar" (migration_005) já cobre a pasta
-- {auth.uid()}/..., então não precisa de policy nova pra isso.
-- Rode DEPOIS do migration_095.
-- ============================================================

-- A versão anterior tinha só (p_telefone, p_email) — assinatura
-- diferente, então precisa dropar explicitamente pra não ficar uma
-- função "fantasma" de 2 parâmetros esquecida no banco.
drop function if exists public.atualizar_meu_contato_responsavel_base(text, text);

create or replace function public.atualizar_meu_contato_responsavel_base(p_nome text, p_telefone text, p_email text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and role = 'responsavel_base') then
    raise exception 'Somente responsáveis das Categorias de Base podem usar esta função';
  end if;

  update public.profiles
    set nome = coalesce(nullif(trim(p_nome), ''), nome),
        telefone = coalesce(nullif(trim(p_telefone), ''), telefone),
        email = coalesce(nullif(trim(p_email), ''), email)
    where id = auth.uid();
end;
$$;
