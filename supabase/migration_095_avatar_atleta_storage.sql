-- ============================================================
-- MANNERRIEGE - Permite foto do atleta no bucket avatares
-- Rode DEPOIS do migration_094.
--
-- O bucket "avatares" já existe (migration_005) mas as policies de
-- insert/update só liberavam a própria pasta do usuário logado
-- (auth.uid() = pasta). Pra foto de atleta, quem sobe é o responsável
-- (auth.uid() dele) mas a pasta é o id do ATLETA — precisa de policies
-- novas, específicas, sem mexer nas que já existem pra avatar de
-- perfil (sócio/responsável).
-- ============================================================

create policy "Responsavel envia foto do atleta"
  on storage.objects for insert
  with check (
    bucket_id = 'avatares'
    and public.responsavel_do_atleta(((storage.foldername(name))[1])::uuid)
  );

create policy "Responsavel atualiza foto do atleta"
  on storage.objects for update
  using (
    bucket_id = 'avatares'
    and public.responsavel_do_atleta(((storage.foldername(name))[1])::uuid)
  );

create policy "Equipe da base envia foto de atleta"
  on storage.objects for insert
  with check (bucket_id = 'avatares' and public.is_base());

create policy "Equipe da base atualiza foto de atleta"
  on storage.objects for update
  using (bucket_id = 'avatares' and public.is_base());
