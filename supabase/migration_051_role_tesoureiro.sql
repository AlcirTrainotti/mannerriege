-- ============================================================
-- MANNERRIEGE - Novo papel: Tesoureiro
--
-- IMPORTANTE: rode este script SOZINHO (clique em "Run" só com este
-- conteúdo colado). Igual fizemos com coordenador_esportivo, o banco
-- exige que o novo valor seja confirmado antes de ser usado em outras
-- regras - por isso ele fica separado da migration_052, que deve ser
-- executada logo em seguida, numa segunda execução.
-- ============================================================

alter type public.user_role add value if not exists 'tesoureiro';
