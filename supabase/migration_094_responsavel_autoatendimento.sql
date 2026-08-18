-- ============================================================
-- MANNERRIEGE - Autoatendimento do responsável: editar o próprio
-- contato, e marcar pra quem é a mensagem (professor/financeiro/
-- coordenação/geral)
-- Rode DEPOIS do migration_093.
-- ============================================================

-- O responsável não consegue dar update em profiles (só admin pode,
-- por causa da policy "Somente admin atualiza perfis" no schema.sql) —
-- essa função dá essa permissão de forma controlada, só pro próprio
-- cadastro e só pra quem é responsavel_base.
create function public.atualizar_meu_contato_responsavel_base(p_telefone text, p_email text)
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
    set telefone = coalesce(nullif(trim(p_telefone), ''), telefone),
        email = coalesce(nullif(trim(p_email), ''), email)
    where id = auth.uid();
end;
$$;

-- Pra quem é a mensagem — deixa o responsável escolher "Professor",
-- "Financeiro" etc. na hora de escrever, e a equipe ver isso na caixa
-- de entrada sem precisar abrir a conversa. Não restringe quem
-- responde (continua sendo qualquer um da equipe, via is_base()) —
-- é só uma etiqueta de roteamento/organização.
alter table public.mensagens_base
  add column destino text not null default 'geral' check (destino in ('professor', 'financeiro', 'coordenacao', 'geral'));
