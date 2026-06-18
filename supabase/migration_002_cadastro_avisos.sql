-- ============================================================
-- MANNERRIEGE - Cadastro completo, status e avisos da diretoria
-- Rode este script no SQL Editor da Supabase DEPOIS do schema.sql
-- (Project > SQL Editor > New query, cola tudo, clica em "Run")
-- ============================================================

create extension if not exists pgcrypto;

-- Novos dados de cadastro do associado.
alter table public.profiles
  add column cpf text,
  add column data_nascimento date,
  add column status text not null default 'adimplente'
    check (status in ('adimplente', 'inadimplente', 'inativo'));

-- A categoria (35+, 40+...) agora e calculada automaticamente a partir da
-- data de nascimento, direto no site - por isso a coluna antiga "categoria"
-- (que era preenchida manualmente) nao e mais necessaria.
alter table public.profiles drop column if exists categoria;

-- ============================================================
-- Avisos da diretoria, com controle de quem ja visualizou
-- ============================================================
create table public.avisos (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  conteudo text not null,
  criado_por uuid references public.profiles (id),
  criado_em timestamptz not null default now()
);

create table public.avisos_visualizacoes (
  aviso_id uuid references public.avisos (id) on delete cascade,
  profile_id uuid references public.profiles (id) on delete cascade,
  visualizado_em timestamptz not null default now(),
  primary key (aviso_id, profile_id)
);

alter table public.avisos enable row level security;
alter table public.avisos_visualizacoes enable row level security;

create policy "Logados veem avisos"
  on public.avisos for select
  using (auth.uid() is not null);

create policy "Somente admin cria avisos"
  on public.avisos for insert
  with check (public.is_admin());

create policy "Somente admin edita avisos"
  on public.avisos for update
  using (public.is_admin());

create policy "Somente admin remove avisos"
  on public.avisos for delete
  using (public.is_admin());

create policy "Marca a propria visualizacao"
  on public.avisos_visualizacoes for insert
  with check (profile_id = auth.uid());

create policy "Ve as propias visualizacoes ou e admin"
  on public.avisos_visualizacoes for select
  using (profile_id = auth.uid() or public.is_admin());
