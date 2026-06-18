-- ============================================================
-- MANNERRIEGE - Foto de perfil (avatar)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

-- Coluna para guardar a URL publica da foto
alter table public.profiles
  add column if not exists avatar_url text;

-- Bucket de armazenamento publico para as fotos
-- (Se aparecer erro de "already exists", pode ignorar e continuar)
insert into storage.buckets (id, name, public)
values ('avatares', 'avatares', true)
on conflict (id) do nothing;

-- Qualquer pessoa autenticada pode ver as fotos (bucket publico ja garante,
-- mas a policy de SELECT e necessaria para o client JS)
create policy "Avatares visíveis para todos"
  on storage.objects for select
  using (bucket_id = 'avatares');

-- Cada usuario so pode fazer upload na propria pasta (avatares/{seu-id}/...)
create policy "Upload do proprio avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatares'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Atualizacao do proprio avatar
create policy "Atualizar proprio avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatares'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Admin pode fazer upload/atualizar avatar de qualquer associado
create policy "Admin faz upload de qualquer avatar"
  on storage.objects for insert
  with check (bucket_id = 'avatares' and public.is_admin());

create policy "Admin atualiza qualquer avatar"
  on storage.objects for update
  using (bucket_id = 'avatares' and public.is_admin());
