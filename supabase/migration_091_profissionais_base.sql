-- ============================================================
-- MANNERRIEGE - Cadastro de profissionais do projeto (Categorias de
-- Base): Coordenador, Técnico, Colaborador
-- Rode DEPOIS do migration_090.
--
-- É um cadastro documental (dados pessoais/de contato), independente
-- do login no portal. O profissional pode já ser um sócio (associado)
-- da Mannerriege, e pode ou não ter acesso ao sistema — as duas coisas
-- são opcionais e independentes:
--   - socio_id: se ele já é sócio, aponta pro profile de associado dele
--   - profile_id: se ele tem login no portal (professor_base/
--     coordenador_base), aponta pro profile de acesso dele
-- ============================================================

create table public.profissionais_base (
  id uuid primary key default gen_random_uuid(),

  nome text not null,
  cpf text,
  rg text,
  data_nascimento date,
  telefone text,
  email text,
  endereco text,

  cargos text[] not null default '{}',

  eh_socio boolean not null default false,
  socio_id uuid references public.profiles (id) on delete set null,
  profile_id uuid references public.profiles (id) on delete set null,

  observacoes text,
  ativo boolean not null default true,
  criado_por uuid references public.profiles (id) on delete set null,
  criado_em timestamptz not null default now(),

  constraint profissionais_base_cargos_validos check (
    cargos <@ array['coordenador', 'tecnico', 'colaborador']::text[]
  )
);

alter table public.profissionais_base enable row level security;

create policy "Equipe da base gerencia profissionais"
  on public.profissionais_base for all
  using (public.is_base())
  with check (public.is_base());
