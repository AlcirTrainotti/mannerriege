-- ============================================================
-- MANNERRIEGE - Status ativo/inativo dos eventos, com desativação
-- automática de eventos com data no passado
-- Rode DEPOIS do migration_087.
--
-- ativo continua editável manualmente (mesmo padrão de categorias e
-- planos), mas um job diário (pg_cron, já habilitado desde o
-- migration_060) desativa sozinho qualquer evento cuja data já passou
-- — não depende de ninguém abrir a tela pra isso acontecer.
-- ============================================================

alter table public.eventos_base add column ativo boolean not null default true;

-- Já nasce coerente pros eventos que já existem.
update public.eventos_base set ativo = false where data < current_date;

create function public._desativar_eventos_base_passados_core()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_atualizados integer;
begin
  update public.eventos_base set ativo = false where data < current_date and ativo = true;
  get diagnostics v_atualizados = row_count;
  return v_atualizados;
end;
$$;

revoke execute on function public._desativar_eventos_base_passados_core() from public, anon, authenticated;

select cron.schedule(
  'desativar-eventos-base-passados',
  '0 6 * * *', -- todo dia às 6h UTC (3h da manhã em Brasília)
  $$select public._desativar_eventos_base_passados_core()$$
);
