-- ============================================================
-- MANNERRIEGE - Novo papel: Coordenador das Categorias de Base
--
-- IMPORTANTE: rode este script SOZINHO, na sua própria execução,
-- depois do migration_062 (mesma exigência do Postgres de confirmar
-- um novo valor de enum antes de usá-lo em outras regras).
-- ============================================================

alter type public.user_role add value if not exists 'coordenador_base';
