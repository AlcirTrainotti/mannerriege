-- ============================================================
-- MANNERRIEGE - Atas das assembleias gerais
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.atas (
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  data_reuniao date not null,
  hora_reuniao time,
  local text,
  ordem_do_dia text,
  link_drive text not null,
  criado_por uuid references public.profiles (id),
  criado_em timestamptz not null default now()
);

alter table public.atas enable row level security;

create policy "Associados podem ver atas"
  on public.atas for select
  using (auth.uid() is not null);

create policy "Somente admin cadastra atas"
  on public.atas for insert
  with check (public.is_admin());

create policy "Somente admin edita atas"
  on public.atas for update
  using (public.is_admin());

create policy "Somente admin remove atas"
  on public.atas for delete
  using (public.is_admin());
