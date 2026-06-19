-- ============================================================
-- MANNERRIEGE - Fotos dos conjuntos de uniforme
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- (Se aparecer erro de "already exists" no insert do bucket, pode ignorar)
-- ============================================================

insert into storage.buckets (id, name, public)
values ('uniformes', 'uniformes', true)
on conflict (id) do nothing;

create policy "Fotos de uniformes visiveis para logados"
  on storage.objects for select
  using (bucket_id = 'uniformes' and auth.uid() is not null);

create policy "Diretoria e coordenacao enviam fotos de uniformes"
  on storage.objects for insert
  with check (bucket_id = 'uniformes' and public.is_esportivo());

create policy "Diretoria e coordenacao atualizam fotos de uniformes"
  on storage.objects for update
  using (bucket_id = 'uniformes' and public.is_esportivo());
