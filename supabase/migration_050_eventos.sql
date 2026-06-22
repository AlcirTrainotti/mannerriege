-- ============================================================
-- MANNERRIEGE - Eventos do clube (costelada, festas, etc.)
-- com orçamento próprio, igual aos campeonatos
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.eventos (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  data date,
  local_festa_id uuid references public.locais_festa (id) on delete set null,
  responsavel_id uuid references public.profiles (id),
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.eventos enable row level security;

create policy "Diretoria gerencia eventos"
  on public.eventos for all
  using (public.is_admin())
  with check (public.is_admin());

create table public.evento_despesas (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null references public.eventos (id) on delete cascade,
  descricao text not null,
  valor numeric(10, 2) not null default 0,
  criado_em timestamptz not null default now()
);

alter table public.evento_despesas enable row level security;

create policy "Diretoria gerencia despesas de eventos"
  on public.evento_despesas for all
  using (public.is_admin())
  with check (public.is_admin());

create table public.evento_receitas (
  id uuid primary key default gen_random_uuid(),
  evento_id uuid not null references public.eventos (id) on delete cascade,
  descricao text not null,
  valor numeric(10, 2) not null default 0,
  criado_em timestamptz not null default now()
);

alter table public.evento_receitas enable row level security;

create policy "Diretoria gerencia receitas de eventos"
  on public.evento_receitas for all
  using (public.is_admin())
  with check (public.is_admin());
