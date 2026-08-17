-- ============================================================
-- MANNERRIEGE - Novo papel: Responsável (pai/mãe/responsável legal
-- de atleta das Categorias de Base)
--
-- IMPORTANTE: rode este script SOZINHO, na sua própria execução,
-- depois do migration_063.
-- ============================================================

alter type public.user_role add value if not exists 'responsavel_base';
