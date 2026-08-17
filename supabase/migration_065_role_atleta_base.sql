-- ============================================================
-- MANNERRIEGE - Novo papel: Atleta (Categorias de Base)
--
-- Conta somente de leitura: o atleta acompanha seus próprios dados,
-- treinos e avaliações, mas nunca edita nada no sistema — quem
-- gerencia o perfil do atleta é o responsável (ver migration_070).
--
-- IMPORTANTE: rode este script SOZINHO, na sua própria execução,
-- depois do migration_064. É o último dos 4 papéis novos do módulo.
-- ============================================================

alter type public.user_role add value if not exists 'atleta_base';
