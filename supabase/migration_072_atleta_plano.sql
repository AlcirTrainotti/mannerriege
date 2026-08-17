-- ============================================================
-- MANNERRIEGE - Plano de cada atleta (histórico) + atribuição
-- automática do plano padrão no cadastro
-- Rode DEPOIS do migration_071.
-- ============================================================

create table public.atleta_plano (
  id uuid primary key default gen_random_uuid(),
  atleta_id uuid not null references public.atletas_base (id) on delete cascade,
  plano_id uuid not null references public.planos_base (id),
  data_inicio date not null default current_date,
  data_fim date, -- nulo = plano vigente
  criado_em timestamptz not null default now()
);

-- Só um plano vigente (data_fim nulo) por atleta ao mesmo tempo
create unique index atleta_plano_vigente_unico
  on public.atleta_plano (atleta_id)
  where data_fim is null;

alter table public.atleta_plano enable row level security;

create policy "Equipe da base gerencia plano do atleta"
  on public.atleta_plano for all
  using (public.is_coordenador_base())
  with check (public.is_coordenador_base());

create policy "Responsavel ve o plano dos seus atletas"
  on public.atleta_plano for select
  using (public.responsavel_do_atleta(atleta_id));

create policy "Atleta ve o proprio plano"
  on public.atleta_plano for select
  using (public.atleta_e_proprio(atleta_id));

-- Ao cadastrar um atleta novo, atribui automaticamente o plano marcado
-- como padrão (hoje, o "Plano Piloto Gratuito").
create function public.atribuir_plano_padrao_atleta()
returns trigger as $$
begin
  insert into public.atleta_plano (atleta_id, plano_id)
  select new.id, id from public.planos_base where padrao limit 1;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

create trigger atletas_base_atribui_plano_padrao
  after insert on public.atletas_base
  for each row execute procedure public.atribuir_plano_padrao_atleta();
