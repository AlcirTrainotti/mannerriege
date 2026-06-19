-- ============================================================
-- MANNERRIEGE - Permissões do módulo Esportivo
-- Rode DEPOIS do migration_010 (que precisa ser executado sozinho,
-- numa execução anterior e separada).
-- ============================================================

-- Coordenadores esportivos têm acesso às telas do módulo esportivo
-- (Convidados, Inventário, Campeonatos), assim como os administradores.
-- Administradores continuam tendo acesso a tudo (is_admin() já cobre isso
-- nas telas de Associados, Avisos e Atas).
create function public.is_esportivo()
returns boolean as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role in ('admin', 'coordenador_esportivo')
  );
$$ language sql security definer stable set search_path = public;

-- Atualiza as regras de Convidados para liberar tambem aos coordenadores
-- esportivos, e nao somente aos administradores.
drop policy if exists "Somente admin ve convidados" on public.convidados;
drop policy if exists "Somente admin cria convidados" on public.convidados;
drop policy if exists "Somente admin edita convidados" on public.convidados;
drop policy if exists "Somente admin remove convidados" on public.convidados;

create policy "Diretoria e coordenacao veem convidados"
  on public.convidados for select
  using (public.is_esportivo());

create policy "Diretoria e coordenacao criam convidados"
  on public.convidados for insert
  with check (public.is_esportivo());

create policy "Diretoria e coordenacao editam convidados"
  on public.convidados for update
  using (public.is_esportivo());

create policy "Diretoria e coordenacao removem convidados"
  on public.convidados for delete
  using (public.is_esportivo());
