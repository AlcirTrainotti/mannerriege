-- ============================================================
-- MANNERRIEGE - Empréstimo do conjunto de uniforme completo,
-- e categoria de destino em qualquer empréstimo
--
-- ATENÇÃO: se o "drop constraint" der erro de "does not exist", é
-- porque o nome da regra no seu banco ficou diferente. Nesse caso, vá
-- em Database > Tables > campeonato_emprestimos > pasta "Constraints"
-- no painel do Supabase, veja o nome real e ajuste os dois comandos de
-- "drop constraint" abaixo antes de rodar de novo.
-- ============================================================

alter table public.campeonato_emprestimos
  add column if not exists campeonato_categoria_id uuid references public.campeonato_categorias (id) on delete set null,
  add column if not exists jogo_uniforme_id uuid references public.jogos_uniforme (id);

alter table public.campeonato_emprestimos drop constraint if exists campeonato_emprestimos_tipo_ativo_check;
alter table public.campeonato_emprestimos add constraint campeonato_emprestimos_tipo_ativo_check
  check (tipo_ativo in ('uniforme', 'bola', 'conjunto_uniforme'));

alter table public.campeonato_emprestimos drop constraint if exists campeonato_emprestimos_check;
alter table public.campeonato_emprestimos add constraint campeonato_emprestimos_check
  check (
    (tipo_ativo = 'uniforme' and uniforme_id is not null and bola_id is null and jogo_uniforme_id is null) or
    (tipo_ativo = 'bola' and bola_id is not null and uniforme_id is null and jogo_uniforme_id is null) or
    (tipo_ativo = 'conjunto_uniforme' and jogo_uniforme_id is not null and uniforme_id is null and bola_id is null)
  );
