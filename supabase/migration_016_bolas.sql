-- ============================================================
-- MANNERRIEGE - Inventário de bolas
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.bolas (
  id uuid primary key default gen_random_uuid(),
  modelo text not null,
  marca text,
  estado text not null check (estado in ('novo', 'bom', 'regular', 'avariado', 'baixado')) default 'bom',
  valor_pago numeric(10, 2),
  data_compra date,
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.bolas enable row level security;

create policy "Diretoria e coordenacao veem bolas"
  on public.bolas for select
  using (public.is_esportivo());

create policy "Diretoria e coordenacao criam bolas"
  on public.bolas for insert
  with check (public.is_esportivo());

create policy "Diretoria e coordenacao editam bolas"
  on public.bolas for update
  using (public.is_esportivo());

create policy "Diretoria e coordenacao removem bolas"
  on public.bolas for delete
  using (public.is_esportivo());
