-- ============================================================
-- MANNERRIEGE - Vínculo do atleta: "do projeto" (mensalista) ou
-- "somente evento(s)"
-- Rode DEPOIS do migration_081.
--
-- Até aqui, todo atleta cadastrado virava mensalista automaticamente
-- (trigger atribuindo o plano padrão + entrando na geração mensal de
-- mensalidade). O Alcir pediu uma via mais leve: cadastrar alguém só
-- vinculado a um ou mais eventos específicos (ex: dia de experiência,
-- festival aberto), sem compromisso de mensalidade — e, quando quiser,
-- promover esse cadastro pra "atleta do projeto", aí sim virando
-- mensalista (ganhando um plano vigente em atleta_plano).
-- ============================================================

alter table public.atletas_base
  add column vinculo text not null default 'projeto' check (vinculo in ('projeto', 'evento'));

comment on column public.atletas_base.vinculo is
  'projeto = atleta do projeto, mensalista (entra na geração automática de mensalidade). evento = cadastro leve, vinculado só a evento(s) específicos, sem mensalidade até ser promovido a "projeto".';

-- O plano padrão só é atribuído automaticamente pra quem já nasce
-- "do projeto". Quem nasce "somente evento" não ganha plano nenhum até
-- ser promovido (a tela de Atletas faz isso explicitamente).
create or replace function public.atribuir_plano_padrao_atleta()
returns trigger as $$
begin
  if new.vinculo = 'projeto' then
    insert into public.atleta_plano (atleta_id, plano_id)
    select new.id, id from public.planos_base where padrao limit 1;
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;
