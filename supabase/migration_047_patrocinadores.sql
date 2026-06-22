-- ============================================================
-- MANNERRIEGE - Cadastro de patrocinadores
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.patrocinadores (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  tipo text not null check (tipo in ('privado', 'publico')) default 'privado',
  nivel text, -- ex: Básico, Exclusivo, Master (livre, sem padrão fixo)
  valor_anual numeric(10, 2),
  contato_nome text,
  contato_telefone text,
  contato_email text,
  ativo boolean not null default true,
  observacoes text,
  criado_em timestamptz not null default now()
);

alter table public.patrocinadores enable row level security;

create policy "Diretoria gerencia patrocinadores"
  on public.patrocinadores for all
  using (public.is_admin())
  with check (public.is_admin());

-- Agora que a tabela existe, liga a referencia que ja estava prevista
-- em financeiro_receitas
alter table public.financeiro_receitas
  add constraint financeiro_receitas_patrocinador_fkey
  foreign key (patrocinador_id) references public.patrocinadores (id) on delete set null;
