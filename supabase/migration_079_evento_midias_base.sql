-- ============================================================
-- MANNERRIEGE - Fotos e vídeos dos eventos das Categorias de Base
-- Rode DEPOIS do migration_078.
-- ============================================================

create table public.evento_midias_base (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null references public.eventos_base (id) on delete cascade,
  tipo text not null check (tipo in ('foto', 'video')),
  url text not null,
  storage_path text not null,
  criado_por uuid references public.profiles (id),
  criado_em timestamptz not null default now()
);

alter table public.evento_midias_base enable row level security;

create policy "Equipe da base gerencia midias de eventos"
  on public.evento_midias_base for all
  using (public.is_base())
  with check (public.is_base());

create policy "Participantes da base veem midias de eventos"
  on public.evento_midias_base for select
  using (public.is_participante_base());

-- Bucket público, mesmo padrão já usado em avatares/uniformes/regulamentos
-- (arquivo só é alcançável por quem tem a URL, que carrega um nome
-- gerado aleatoriamente — não é listado nem indexado publicamente).
insert into storage.buckets (id, name, public)
values ('midias-base', 'midias-base', true)
on conflict (id) do nothing;

create policy "Midias de eventos visiveis para todos"
  on storage.objects for select
  using (bucket_id = 'midias-base');

create policy "Equipe da base envia midias de eventos"
  on storage.objects for insert
  with check (bucket_id = 'midias-base' and public.is_base());

create policy "Equipe da base remove midias de eventos"
  on storage.objects for delete
  using (bucket_id = 'midias-base' and public.is_base());
