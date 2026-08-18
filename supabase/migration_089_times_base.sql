-- ============================================================
-- MANNERRIEGE - Times (subdivisão dentro de uma categoria)
-- Rode DEPOIS do migration_088.
--
-- Ex: dentro do Sub-13 masculino podem existir o "Time A" (mais
-- avançado) e o "Time B" (iniciantes) — cada atleta pertence a no
-- máximo um time por vez, mas o time é opcional (pode ficar sem time
-- definido ainda).
-- ============================================================

create table public.times_base (
  id uuid primary key default gen_random_uuid(),
  categoria_id uuid not null references public.categorias_base (id) on delete cascade,
  nome text not null,
  descricao text,
  ativo boolean not null default true,
  criado_por uuid references public.profiles (id) on delete set null,
  criado_em timestamptz not null default now()
);

alter table public.times_base enable row level security;

create policy "Equipe da base gerencia times"
  on public.times_base for all
  using (public.is_base())
  with check (public.is_base());

create policy "Participantes da base leem times"
  on public.times_base for select
  using (public.is_participante_base());

alter table public.atletas_base
  add column time_id uuid references public.times_base (id) on delete set null;
