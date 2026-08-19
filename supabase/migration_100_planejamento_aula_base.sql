-- ============================================================
-- MANNERRIEGE - Planejamento da aula: expectativa por atleta
-- Rode DEPOIS do migration_099.
--
-- O professor pediu uma etapa clara de PLANEJAMENTO, antes do dia do
-- treino: além do objetivo geral e das atividades (já existiam),
-- ele precisa registrar o que espera de CADA atleta nessa aula
-- especificamente. Isso mora na mesma linha de evento_participantes_base
-- (já é "por atleta, por evento"), então não precisa de tabela nova —
-- só uma coluna a mais, sem mudar nenhuma policy (o "select *" já
-- existente nos painéis de responsável/atleta/professor passa a trazer
-- o campo sozinho).
-- ============================================================

alter table public.evento_participantes_base
  add column expectativa text;

comment on column public.evento_participantes_base.expectativa is
  'O que o professor espera desse atleta especificamente nessa aula — definido no planejamento, antes do treino acontecer (diferente de desempenho_obs, que é o registro DEPOIS do treino).';
