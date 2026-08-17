-- ============================================================
-- MANNERRIEGE - Funções de permissão do módulo Categorias de Base
-- Rode DEPOIS do migration_065 (os 4 papéis novos precisam já
-- estar confirmados no enum).
-- ============================================================

-- Equipe do módulo (professor OU coordenador OU admin) — usada nas
-- telas de gestão (cadastro de atleta, categorias, planos etc).
create function public.is_professor_base()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'professor_base')
  );
$$ language sql security definer stable set search_path = public;

create function public.is_coordenador_base()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'coordenador_base')
  );
$$ language sql security definer stable set search_path = public;

create function public.is_base()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'professor_base', 'coordenador_base')
  );
$$ language sql security definer stable set search_path = public;

-- Qualquer um dos 5 papéis do módulo (equipe + responsável + atleta) —
-- usada só nas tabelas de referência compartilhada (categorias, planos),
-- onde todo mundo do módulo pode ler, mas só a equipe edita.
create function public.is_participante_base()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid()
      and role in ('admin', 'professor_base', 'coordenador_base', 'responsavel_base', 'atleta_base')
  );
$$ language sql security definer stable set search_path = public;
