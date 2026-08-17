-- ============================================================
-- MANNERRIEGE - Novo papel: Professor (Categorias de Base)
--
-- IMPORTANTE: rode este script SOZINHO (clique em "Run" só com
-- este conteúdo colado). O banco de dados exige que um novo valor
-- de papel seja confirmado antes de ser usado em outras regras -
-- por isso ele fica separado dos migrations seguintes, que devem
-- ser executados logo em seguida, numa segunda execução.
-- ============================================================

alter type public.user_role add value if not exists 'professor_base';
