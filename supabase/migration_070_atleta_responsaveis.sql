-- ============================================================
-- MANNERRIEGE - Vínculo atleta x responsável, e acesso do responsável
-- ao cadastro do(s) próprio(s) filho(s)
-- Rode DEPOIS do migration_069.
-- ============================================================

create table public.atleta_responsaveis (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atletas_base (id) on delete cascade,
  responsavel_id uuid not null references public.profiles (id) on delete cascade,
  parentesco text, -- ex: 'mãe', 'pai', 'responsável legal'
  contato_preferencial boolean not null default false,
  criado_em timestamptz not null default now(),
  unique (atleta_id, responsavel_id)
);

-- Um atleta pode ter mais de um responsável (mãe + pai); um responsável
-- pode ter mais de um atleta (irmãos no projeto) — por isso é N:N.

create function public.responsavel_do_atleta(p_atleta_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.atleta_responsaveis
    where atleta_id = p_atleta_id and responsavel_id = auth.uid()
  );
$$ language sql security definer stable set search_path = public;

alter table public.atleta_responsaveis enable row level security;

create policy "Equipe da base gerencia vinculos"
  on public.atleta_responsaveis for all
  using (public.is_base())
  with check (public.is_base());

create policy "Responsavel ve os proprios vinculos"
  on public.atleta_responsaveis for select
  using (responsavel_id = auth.uid());

-- --------------------------------------------------------------
-- Estende o acesso de atletas_base: responsável vê e edita os dados
-- cadastrais do(s) próprio(s) atleta(s) (nunca cria/exclui — isso
-- continua exclusivo da equipe, migration_069).
-- --------------------------------------------------------------

create policy "Responsavel ve seus atletas"
  on public.atletas_base for select
  using (public.responsavel_do_atleta(id));

create policy "Responsavel edita dados cadastrais dos seus atletas"
  on public.atletas_base for update
  using (public.responsavel_do_atleta(id))
  with check (public.responsavel_do_atleta(id));

-- Bloqueia o responsável de mexer em campos que são de gestão da
-- equipe (categoria, status) mesmo tendo permissão de UPDATE na linha
-- — RLS não faz controle por coluna, então isso é feito com um
-- trigger. O campo profile_id (login do atleta) tem uma regra à
-- parte: o responsável pode ATIVAR o login (de nulo pra um valor,
-- fluxo de "criar acesso do meu filho" no próprio painel dele), mas
-- não pode trocar ou remover um login já existente — isso continua
-- exclusivo da equipe.
create function public.atletas_base_bloqueia_campos_staff()
returns trigger as $$
begin
  if public.is_base() or auth.uid() is null then
    -- is_base(): membro da equipe logado no portal.
    -- auth.uid() is null: chamada feita com a service role (ex: uma
    -- Edge Function futura), sem sessão de usuário — código de
    -- backend confiável, não uma sessão de responsável.
    return new;
  end if;

  if new.categoria_id is distinct from old.categoria_id
     or new.status is distinct from old.status then
    raise exception 'Somente a equipe da base pode alterar categoria ou status do atleta';
  end if;

  if new.profile_id is distinct from old.profile_id
     and not (old.profile_id is null and public.responsavel_do_atleta(old.id)) then
    raise exception 'Somente a equipe da base pode alterar o login já vinculado ao atleta';
  end if;

  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger atletas_base_protege_campos_staff
  before update on public.atletas_base
  for each row execute procedure public.atletas_base_bloqueia_campos_staff();
