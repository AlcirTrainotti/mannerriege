-- ============================================================
-- MANNERRIEGE - Cadastro de locais para festas
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.locais_festa (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  endereco text,
  capacidade integer,
  contato_nome text,
  contato_telefone text,
  valor_locacao numeric(10, 2),
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.locais_festa enable row level security;

create policy "Diretoria gerencia locais para festas"
  on public.locais_festa for all
  using (public.is_admin())
  with check (public.is_admin());
