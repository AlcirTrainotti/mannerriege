-- ============================================================
-- MANNERRIEGE - Inventário de uniformes
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.uniformes (
  id uuid primary key default gen_random_uuid(),
  tipo text not null check (tipo in ('completo', 'somente_camiseta')) default 'completo',
  tamanho text check (tamanho in ('P', 'M', 'G', 'GG', 'G1', 'G2', 'G3', 'XG', 'XGG', 'EXG')),
  numero text,
  estado text not null check (estado in ('novo', 'bom', 'regular', 'avariado', 'baixado')) default 'bom',
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.uniformes enable row level security;

create policy "Diretoria e coordenacao veem uniformes"
  on public.uniformes for select
  using (public.is_esportivo());

create policy "Diretoria e coordenacao criam uniformes"
  on public.uniformes for insert
  with check (public.is_esportivo());

create policy "Diretoria e coordenacao editam uniformes"
  on public.uniformes for update
  using (public.is_esportivo());

create policy "Diretoria e coordenacao removem uniformes"
  on public.uniformes for delete
  using (public.is_esportivo());
