-- ============================================================
-- MANNERRIEGE - Mensalidades dos associados
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.mensalidades (
  id uuid primary key default gen_random_uuid(),
  associado_id uuid not null references public.profiles (id) on delete cascade,
  competencia date not null, -- sempre o dia 1 do mes de referencia
  valor numeric(10, 2) not null,
  pago boolean not null default false,
  data_pagamento date,
  criado_em timestamptz not null default now(),
  unique (associado_id, competencia)
);

alter table public.mensalidades enable row level security;

create policy "Diretoria gerencia mensalidades"
  on public.mensalidades for all
  using (public.is_admin())
  with check (public.is_admin());

create policy "Associado ve as proprias mensalidades"
  on public.mensalidades for select
  using (associado_id = auth.uid());

-- ============================================================
-- Gera a mensalidade do mes para todo associado que ainda nao tem uma
-- competencia daquele mes (nao duplica se rodar de novo sem querer).
-- O valor e definido automaticamente: R$30 para socio do ginastico,
-- R$50 para quem nao e. Associados inativos nao geram cobranca.
-- ============================================================
create function public.gerar_mensalidades_mes(p_competencia date)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_criadas integer;
begin
  if not public.is_admin() then
    raise exception 'Apenas administradores podem gerar mensalidades';
  end if;

  insert into public.mensalidades (associado_id, competencia, valor)
  select
    p.id,
    date_trunc('month', p_competencia)::date,
    case when p.socio_ginastico then 30 else 50 end
  from public.profiles p
  where p.status <> 'inativo'
  on conflict (associado_id, competencia) do nothing;

  get diagnostics v_criadas = row_count;
  return v_criadas;
end;
$$;
