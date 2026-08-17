-- ============================================================
-- MANNERRIEGE - Cadastro de atletas das Categorias de Base
-- Rode DEPOIS do migration_068.
--
-- O cadastro em si (criação do registro) é feito pela equipe do
-- módulo (professor/coordenador/admin) — normalmente ao aprovar uma
-- inscrição/matrícula. Depois de criado, o responsável ganha acesso
-- de edição aos dados cadastrais do próprio atleta (ver migration_070).
-- ============================================================

create table public.atletas_base (
  id uuid primary key default gen_random_uuid(),

  -- Login de leitura do atleta (opcional, ativado quando o responsável
  -- cria o acesso do filho — ver Edge Function criar-login-base)
  profile_id uuid references public.profiles (id) on delete set null,

  categoria_id uuid not null references public.categorias_base (id),
  nome text not null,
  data_nascimento date not null,
  sexo text not null check (sexo in ('masculino', 'feminino')),
  escola text,
  data_ingresso date not null default current_date,
  status text not null default 'ativo' check (status in ('ativo', 'inativo', 'lesionado', 'desligado')),
  avatar_url text,
  observacoes_gerais text,
  criado_em timestamptz not null default now(),

  unique (profile_id)
);

comment on column public.atletas_base.observacoes_gerais is
  'Observações cadastrais gerais (ex: alergia, restrição alimentar). Evitar linguagem clínica/diagnóstica aqui — isso é dado sensível de saúde sob a LGPD.';

alter table public.atletas_base enable row level security;

create policy "Equipe da base gerencia atletas"
  on public.atletas_base for all
  using (public.is_base())
  with check (public.is_base());
