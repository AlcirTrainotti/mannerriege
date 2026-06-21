-- ============================================================
-- MANNERRIEGE - Regulamento do campeonato (PDF)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

insert into storage.buckets (id, name, public)
values ('regulamentos', 'regulamentos', true)
on conflict (id) do nothing;

create policy "Regulamentos visiveis para logados"
  on storage.objects for select
  using (bucket_id = 'regulamentos' and auth.uid() is not null);

create policy "Diretoria e coordenacao enviam regulamentos"
  on storage.objects for insert
  with check (bucket_id = 'regulamentos' and public.is_esportivo());

create policy "Diretoria e coordenacao atualizam regulamentos"
  on storage.objects for update
  using (bucket_id = 'regulamentos' and public.is_esportivo());
