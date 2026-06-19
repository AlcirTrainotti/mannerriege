-- ============================================================
-- MANNERRIEGE - Novo papel: Coordenador Esportivo
--
-- IMPORTANTE: rode este script SOZINHO (clique em "Run" só com
-- este conteúdo colado). O banco de dados exige que um novo valor
-- de papel seja confirmado antes de ser usado em outras regras -
-- por isso ele fica separado do migration_011, que deve ser
-- executado logo em seguida, numa segunda execução.
-- ============================================================

alter type public.user_role add value if not exists 'coordenador_esportivo';
