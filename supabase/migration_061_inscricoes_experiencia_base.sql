-- ============================================================
-- MANNERRIEGE - Inscrições da "Experiência Mannerriege: A Nova
-- Geração" (aula inaugural do Vôlei de Base, 29/08/2026)
-- Rode no Supabase SQL Editor depois das migrations anteriores
-- ============================================================

create table public.inscricoes_experiencia_base (
  id uuid primary key default gen_random_uuid(),
  criado_em timestamptz not null default now(),

  -- Responsável
  responsavel_nome text not null,
  responsavel_whatsapp text not null,
  responsavel_email text not null,
  responsavel_relacao text not null,

  -- Atleta
  atleta_nome text not null,
  atleta_data_nascimento date not null,
  turma text not null check (turma in ('masculino', 'feminino')),
  pratica_volei text not null,
  pratica_detalhe text,
  objetivo text not null,
  objetivo_outro text,
  condicao_saude text,
  contato_emergencia text not null,

  -- Origem
  origem text not null,
  origem_outro text,

  -- Autorizações
  declaracao_ciencia boolean not null default false,
  autorizacao_dados boolean not null default false,
  autorizacao_imagem text not null check (autorizacao_imagem in ('autorizo', 'nao_autorizo')),

  -- Controle de vaga — ver supabase/COMO_CONFIGURAR_INSCRICAO_EXPERIENCIA.md
  -- Fluxo de status: recebida -> em_validacao -> confirmada ->
  -- presenca_confirmada -> compareceu -> matricula (ou lista_espera /
  -- cancelada a qualquer momento)
  status text not null default 'recebida' check (
    status in ('recebida', 'lista_espera', 'em_validacao', 'confirmada', 'presenca_confirmada', 'compareceu', 'matricula', 'cancelada')
  ),

  constraint declaracao_ciencia_obrigatoria check (declaracao_ciencia = true),
  constraint autorizacao_dados_obrigatoria check (autorizacao_dados = true)
);

comment on table public.inscricoes_experiencia_base is
  'Inscrições do formulário público /experiencia (aula inaugural do Vôlei de Base). Gravadas só pela Edge Function inscricao-experiencia, via service role.';

alter table public.inscricoes_experiencia_base enable row level security;

-- Nenhuma policy criada de propósito: com RLS ligado e sem policy,
-- anon/authenticated não conseguem ler nem escrever nada nesta tabela
-- via API pública. A única escrita permitida é pela Edge Function
-- (usa a service role, que ignora RLS). A leitura é feita direto pela
-- diretoria no Table Editor do Supabase (login do projeto também usa
-- service role) — os dados aqui incluem saúde e contato de emergência
-- de menores de idade, então não expor por API pública é proposital.
