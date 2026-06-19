-- ============================================================
-- MANNERRIEGE - Convidados (parceiros que jogam em campeonatos)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.convidados (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  cpf text,
  data_nascimento date,
  posicao text check (posicao in ('ponteiro', 'libero', 'levantador', 'meio', 'oposto', 'tecnico', 'outro')),
  telefone text,
  avaliacao_nota integer check (avaliacao_nota between 1 and 5),
  avaliacao_obs text,
  criado_por uuid references public.profiles (id),
  criado_em timestamptz not null default now()
);

alter table public.convidados enable row level security;

-- Por enquanto, somente a diretoria gerencia e ve convidados.
-- Quando o modulo de Campeonatos for criado, podemos revisar esta regra
-- para liberar aos associados a visualizacao de convidados que jogaram
-- com eles em um campeonato especifico.
create policy "Somente admin ve convidados"
  on public.convidados for select
  using (public.is_admin());

create policy "Somente admin cria convidados"
  on public.convidados for insert
  with check (public.is_admin());

create policy "Somente admin edita convidados"
  on public.convidados for update
  using (public.is_admin());

create policy "Somente admin remove convidados"
  on public.convidados for delete
  using (public.is_admin());
