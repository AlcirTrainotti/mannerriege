-- ============================================================
-- MANNERRIEGE - Avaliação e histórico de negociações: locais para festa
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

alter table public.locais_festa
  add column if not exists avaliacao_nota integer check (avaliacao_nota between 1 and 5);

create table public.local_festa_negociacoes (
  id uuid primary key default gen_random_uuid(),
  local_festa_id uuid not null references public.locais_festa (id) on delete cascade,
  descricao text not null,
  data date not null default current_date,
  criado_por uuid references public.profiles (id),
  criado_em timestamptz not null default now()
);

alter table public.local_festa_negociacoes enable row level security;

create policy "Diretoria e tesouraria gerenciam negociacoes de local"
  on public.local_festa_negociacoes for all
  using (public.is_financeiro())
  with check (public.is_financeiro());
