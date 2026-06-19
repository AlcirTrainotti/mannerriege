-- ============================================================
-- MANNERRIEGE - Empréstimo de uniformes e bolas por campeonato
-- Rode no Supabase SQL Editor depois do migration_024
-- ============================================================

create table public.campeonato_emprestimos (
  id uuid primary key default gen_random_uuid(),
  campeonato_id uuid not null references public.campeonatos (id) on delete cascade,
  tipo_ativo text not null check (tipo_ativo in ('uniforme', 'bola')),
  uniforme_id uuid references public.uniformes (id),
  bola_id uuid references public.bolas (id),
  responsavel_nome text not null,
  retirado_em timestamptz,
  visto_retirada boolean not null default false,
  devolvido_em timestamptz,
  visto_devolucao boolean not null default false,
  foto_devolucao_url text,
  observacoes text,
  criado_em timestamptz not null default now(),
  check (
    (tipo_ativo = 'uniforme' and uniforme_id is not null and bola_id is null) or
    (tipo_ativo = 'bola' and bola_id is not null and uniforme_id is null)
  )
);

alter table public.campeonato_emprestimos enable row level security;

create policy "Diretoria e coordenacao veem emprestimos"
  on public.campeonato_emprestimos for select
  using (public.is_esportivo());

create policy "Diretoria e coordenacao criam emprestimos"
  on public.campeonato_emprestimos for insert
  with check (public.is_esportivo());

create policy "Diretoria e coordenacao editam emprestimos"
  on public.campeonato_emprestimos for update
  using (public.is_esportivo());

create policy "Diretoria e coordenacao removem emprestimos"
  on public.campeonato_emprestimos for delete
  using (public.is_esportivo());

-- ============================================================
-- Bucket de fotos de devolucao dos materiais
-- ============================================================
insert into storage.buckets (id, name, public)
values ('emprestimos', 'emprestimos', true)
on conflict (id) do nothing;

create policy "Fotos de devolucao visiveis para diretoria e coordenacao"
  on storage.objects for select
  using (bucket_id = 'emprestimos' and public.is_esportivo());

create policy "Diretoria e coordenacao enviam fotos de devolucao"
  on storage.objects for insert
  with check (bucket_id = 'emprestimos' and public.is_esportivo());

create policy "Diretoria e coordenacao atualizam fotos de devolucao"
  on storage.objects for update
  using (bucket_id = 'emprestimos' and public.is_esportivo());
