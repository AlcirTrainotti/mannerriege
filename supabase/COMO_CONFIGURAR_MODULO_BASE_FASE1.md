# Categorias de Base — Fase 1 (fundação)

Como aplicar este pacote no seu checkout local (`Desenvolvimento_Mannerriege/mannerriege`):

1. Descompacte `modulo-categorias-base.zip` na raiz do repositório — os caminhos já
   batem exatamente com a estrutura atual (substitui `src/components/portal/AdminPanel.vue`
   e `src/views/PortalView.vue`, cria os arquivos novos).
2. `npm run build` já foi testado aqui e passou limpo (154+ módulos, sem erro).

## Rodar as migrations no Supabase (SQL Editor), NESTA ORDEM

062, 063, 064 e 065 **cada uma sozinha, numa execução própria** — é a mesma exigência
de confirmar um valor novo de enum antes de usar, já usada em migration_010/051.
Depois, 066 a 074 podem rodar juntas ou uma a uma, sempre nessa ordem:

```
062_role_professor_base        (SOZINHA)
063_role_coordenador_base      (SOZINHA)
064_role_responsavel_base      (SOZINHA)
065_role_atleta_base           (SOZINHA)
066_funcoes_base
067_categorias_base            (já semeia Sub-13/Sub-15, masc/fem)
068_planos_base                (já semeia "Plano Piloto Gratuito")
069_atletas_base
070_atleta_responsaveis
071_atleta_login
072_atleta_plano
073_mensalidades_base
074_listar_responsaveis_base
```

## Deploy da Edge Function

Só uma função nova: `resetar-senha-atleta` (Supabase → Edge Functions → Deploy a new
function → Via Editor → nome exato `resetar-senha-atleta` → colar o conteúdo de
`supabase/functions/resetar-senha-atleta/index.ts` → Deploy). Não precisa de segredo
novo — usa a `SUPABASE_SERVICE_ROLE_KEY` que já é injetada automaticamente.

Criar login de responsável e de atleta **não** passa por Edge Function — acontece
direto no frontend com um cliente Supabase temporário, mesmo padrão que
`AdminAssociados.vue` já usa pra cadastrar associado sem deslogar quem está
cadastrando.

## O que já funciona nesta Fase 1

- 4 papéis novos: `professor_base`, `coordenador_base`, `responsavel_base` (leitura +
  edição do cadastro do próprio atleta), `atleta_base` (só leitura, nunca escreve).
- Cadastro de atleta pela coordenação (`Portal → Categorias de Base → Atletas → Novo
  atleta`), com vínculo a um responsável existente ou recém-cadastrado ali mesmo.
- Responsável edita dados cadastrais do(s) filho(s) e cria a senha de acesso (leitura)
  do atleta, tudo dentro do próprio painel dele.
- Categorias (Sub-13/Sub-15) e Planos (com o Plano Piloto Gratuito já como padrão) com
  CRUD simples pela coordenação.
- Estrutura de mensalidade já funcional (`mensalidades_base`), gerando `isento`
  enquanto o plano vigente for gratuito — lançar um plano pago no futuro é só
  cadastrar o plano com valor e mover os atletas pra ele, sem deploy novo.
- Aba "🏐 Categorias de Base" dentro do `AdminPanel` pra visão consolidada do admin.

## O que ainda NÃO está nesta Fase 1 (fica pra Fase 2/3/5 do documento de
especificação, `Sistemas/Modulo_Base_Especificacao.md`)

Calendário de treinos, chamada/presença, avaliação por valência (0–10), planos de
treino individuais, recursos (quadra/materiais), viagens/competições, parceiros por
frente, contratos, mensagens. O painel do professor e do atleta já mostram um aviso
nesse sentido nas telas onde essas features vão entrar.

## Pontos pra você revisar com atenção

- Categorias semeadas com faixa etária estimada (Sub-13: 11–13, Sub-15: 14–15) —
  ajustável na própria tela de Categorias, é só um chute inicial pra não deixar
  o campo vazio.
- Onboarding do atleta hoje é: coordenação cadastra o atleta + vincula/cadastra o
  responsável → responsável entra no próprio painel e cria a senha do filho. Se
  preferir que a coordenação já crie a senha do atleta na hora do cadastro (sem
  depender do responsável logar depois), me avisa que eu ajusto o fluxo.
