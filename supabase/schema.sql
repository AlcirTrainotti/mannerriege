-- ============================================================
-- MANNERRIEGE - Area do Associado
-- Rode este arquivo inteiro no Supabase: Project > SQL Editor > New query
-- Pode colar tudo e clicar em "Run" de uma vez so.
-- ============================================================

-- Tipos usados nos campos do associado
create type public.user_role as enum ('associado', 'admin');
create type public.modalidade_jogo as enum ('volei', 'volei_domino', 'domino');

-- Tabela com os dados de cada associado (alem do login, que fica no
-- sistema de autenticacao interno do Supabase)
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nome text not null,
  email text not null,
  role public.user_role not null default 'associado',
  categoria text check (categoria in ('35+', '40+', '45+', '50+', '55+', '60+')),
  modalidade public.modalidade_jogo not null default 'volei',
  criado_em timestamptz not null default now()
);

comment on column public.profiles.modalidade is 'volei = so volei, volei_domino = volei e domino, domino = so domino';

-- Sempre que alguem novo for criado em Authentication > Users, isso cria
-- automaticamente a linha correspondente em profiles, com papel "associado"
-- por padrao (o primeiro admin precisa ser promovido manualmente, veja o
-- guia de configuracao).
create function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, nome, email)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'nome', new.email), new.email);
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Funcao auxiliar para checar se quem esta logado e admin, sem causar
-- recursao nas regras de seguranca abaixo
create function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from public.profiles where id = auth.uid() and role = 'admin'
  );
$$ language sql security definer stable set search_path = public;

-- Regras de seguranca (RLS): cada associado so ve o proprio cadastro;
-- administradores veem e editam todo mundo.
alter table public.profiles enable row level security;

create policy "Ver proprio perfil ou ser admin"
  on public.profiles for select
  using (auth.uid() = id or public.is_admin());

create policy "Somente admin atualiza perfis"
  on public.profiles for update
  using (public.is_admin())
  with check (public.is_admin());

-- ============================================================
-- Depois de rodar este script, va em Authentication > Users e crie o
-- primeiro usuario manualmente (seu proprio e-mail). Depois, volte aqui
-- no SQL Editor e rode o comando abaixo, trocando o e-mail, para se
-- tornar administrador:
--
-- update public.profiles set role = 'admin' where email = 'seuemail@mannerriege.com.br';
-- ============================================================
