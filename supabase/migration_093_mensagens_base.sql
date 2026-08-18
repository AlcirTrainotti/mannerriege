-- ============================================================
-- MANNERRIEGE - Mensagens entre o responsável e a equipe das
-- Categorias de Base
-- Rode DEPOIS do migration_092.
--
-- Um canal por família (responsavel_id), não por atleta — um
-- responsável com mais de um filho no projeto conversa num só lugar.
-- Qualquer pessoa da equipe (admin/professor_base/coordenador_base)
-- pode ver e responder qualquer canal; do lado do responsável, só o
-- dono do canal (responsavel_id = auth.uid()) participa.
-- ============================================================

create table public.mensagens_base (
  id uuid primary key default gen_random_uuid(),
  responsavel_id uuid not null references public.profiles (id) on delete cascade,
  autor_id uuid references public.profiles (id) on delete set null,
  corpo text not null,
  lida boolean not null default false,
  criado_em timestamptz not null default now()
);

create index mensagens_base_responsavel_idx on public.mensagens_base (responsavel_id, criado_em);

alter table public.mensagens_base enable row level security;

create policy "Responsavel ve e envia mensagens do proprio canal"
  on public.mensagens_base for select
  using (responsavel_id = auth.uid());

create policy "Responsavel envia mensagens no proprio canal"
  on public.mensagens_base for insert
  with check (responsavel_id = auth.uid() and autor_id = auth.uid());

create policy "Responsavel marca como lida no proprio canal"
  on public.mensagens_base for update
  using (responsavel_id = auth.uid())
  with check (responsavel_id = auth.uid());

create policy "Equipe da base ve todos os canais"
  on public.mensagens_base for select
  using (public.is_base());

create policy "Equipe da base envia mensagens em qualquer canal"
  on public.mensagens_base for insert
  with check (public.is_base() and autor_id = auth.uid());

create policy "Equipe da base marca como lida em qualquer canal"
  on public.mensagens_base for update
  using (public.is_base())
  with check (public.is_base());

-- Lista, pra equipe da base, um canal por responsável com o nome, a
-- última mensagem e quantas mensagens do responsável ainda estão sem
-- resposta lida pela equipe — evita ter que abrir canal por canal pra
-- saber onde responder.
create function public.listar_canais_mensagens_base()
returns table (
  responsavel_id uuid,
  responsavel_nome text,
  ultima_mensagem text,
  ultima_mensagem_em timestamptz,
  nao_lidas integer
)
language sql
security definer
stable
set search_path = public
as $$
  select
    p.id as responsavel_id,
    p.nome as responsavel_nome,
    (select corpo from public.mensagens_base m2 where m2.responsavel_id = p.id order by m2.criado_em desc limit 1) as ultima_mensagem,
    (select criado_em from public.mensagens_base m2 where m2.responsavel_id = p.id order by m2.criado_em desc limit 1) as ultima_mensagem_em,
    (select count(*)::integer from public.mensagens_base m3 where m3.responsavel_id = p.id and m3.autor_id = p.id and not m3.lida) as nao_lidas
  from public.profiles p
  where p.role = 'responsavel_base'
    and public.is_base()
    and exists (select 1 from public.mensagens_base m where m.responsavel_id = p.id)
  order by ultima_mensagem_em desc nulls last;
$$;
