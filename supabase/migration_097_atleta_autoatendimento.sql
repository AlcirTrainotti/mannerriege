-- ============================================================
-- MANNERRIEGE - Autoatendimento do ATLETA: foto, senha e "informações
-- básicas" (nome e escola) — o resto do cadastro continua exclusivo
-- do responsável/equipe. Senha é self-service via
-- supabase.auth.updateUser(), não precisa de policy nova.
-- Rode DEPOIS do migration_096.
-- ============================================================

-- Até aqui só existia SELECT pro próprio atleta (migration_071,
-- comentário "nenhuma policy de insert/update/delete é criada").
create policy "Atleta atualiza dados basicos proprios"
  on public.atletas_base for update
  using (public.atleta_e_proprio(id))
  with check (public.atleta_e_proprio(id));

-- A trigger que já existia (migration_070) bloqueava categoria/status/
-- profile_id pra qualquer um que não seja equipe — agora, além disso,
-- quando quem está editando é o PRÓPRIO ATLETA (não o responsável),
-- restringe ainda mais: só nome, escola e avatar_url passam.
create or replace function public.atletas_base_bloqueia_campos_staff()
returns trigger as $$
begin
  if public.is_base() or auth.uid() is null then
    return new;
  end if;

  if new.categoria_id is distinct from old.categoria_id
     or new.status is distinct from old.status then
    raise exception 'Somente a equipe da base pode alterar categoria ou status do atleta';
  end if;

  if new.profile_id is distinct from old.profile_id
     and not (old.profile_id is null and public.responsavel_do_atleta(old.id)) then
    raise exception 'Somente a equipe da base pode alterar o login já vinculado ao atleta';
  end if;

  if public.atleta_e_proprio(old.id) and not public.responsavel_do_atleta(old.id) then
    if new.data_nascimento is distinct from old.data_nascimento
       or new.posicao is distinct from old.posicao
       or new.observacoes_gerais is distinct from old.observacoes_gerais
       or new.time_id is distinct from old.time_id then
      raise exception 'Você só pode alterar seu nome, escola e foto — o resto é com seu responsável ou a coordenação';
    end if;
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- Foto do atleta subida pelo PRÓPRIO atleta (pasta = id do atleta,
-- igual ao que já existe pro responsável desde o migration_095, só
-- que aqui checando atleta_e_proprio em vez de responsavel_do_atleta).
create policy "Atleta envia a propria foto"
  on storage.objects for insert
  with check (
    bucket_id = 'avatares'
    and public.atleta_e_proprio(((storage.foldername(name))[1])::uuid)
  );

create policy "Atleta atualiza a propria foto"
  on storage.objects for update
  using (
    bucket_id = 'avatares'
    and public.atleta_e_proprio(((storage.foldername(name))[1])::uuid)
  );
