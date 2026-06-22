-- ============================================================
-- MANNERRIEGE - Cadastro de parceiros
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.parceiros (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  tipo_parceria text,
  contato_nome text,
  contato_telefone text,
  contato_email text,
  ativo boolean not null default true,
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.parceiros enable row level security;

create policy "Diretoria gerencia parceiros"
  on public.parceiros for all
  using (public.is_admin())
  with check (public.is_admin());
