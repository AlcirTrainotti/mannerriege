# Como configurar o Supabase do site (projeto novo, do zero)

O site institucional (Astro, pasta `apps/site`) agora tem seu **próprio
projeto Supabase**, separado do banco do portal de associados — o
portal será refeito à parte, mais adiante, e não deve depender de nada
que estiver aqui.

Projeto do site:

- URL: `https://hmenxikzihzyutkkxfsr.supabase.co`
- Anon/publishable key: `sb_publishable_ow0eChkzvfiDT_hRL4uPVw_A1xZEtF4`

Já estão em `apps/site/.env` como `PUBLIC_SUPABASE_URL` /
`PUBLIC_SUPABASE_ANON_KEY`. Este documento é o roteiro único para deixar
esse projeto novo funcionando do zero — os `COMO_CONFIGURAR_*.md`
individuais de cada formulário continuam valendo para detalhes, mas
comece por aqui.

## 1. Criar a tabela de inscrições da Experiência

A única tabela que o site precisa hoje é a `inscricoes_experiencia_base`
(usada pelo formulário `/experiencia`). Os outros formulários
(`/associe-se`, `/base/matricula`, `/apoie`, `/contato`) não gravam
nada no banco, só mandam e-mail.

1. No painel do Supabase (projeto `hmenxikzihzyutkkxfsr`), vá em
   **SQL Editor** → **New query**.
2. Abra `supabase/migration_061_inscricoes_experiencia_base.sql`, copie
   todo o conteúdo e cole no editor.
3. Rode a query (**Run**).

Detalhes sobre a tabela (campos, RLS, fluxo de status) estão em
`COMO_CONFIGURAR_INSCRICAO_EXPERIENCIA.md`.

## 2. Configurar o segredo do Resend

Todos os formulários do site enviam e-mail via Resend, usando o segredo
`RESEND_API_KEY`. Ele é configurado **uma vez só**, no nível do
projeto, e vale para todas as Edge Functions dele:

1. No projeto novo, vá em **Edge Functions** → **Secrets**.
2. Adicione: Nome `RESEND_API_KEY`, Valor a chave do Resend
   (`re_...` — crie uma conta em https://resend.com se ainda não tiver,
   o passo 1 de `COMO_CONFIGURAR_INTERESSE_ASSOCIADO.md` explica).
3. Salve.

## 3. Deploy das Edge Functions

Deploy cada uma pelo painel (**Edge Functions** → **Deploy a new
function** → **Via Editor**), usando o nome exato e colando o conteúdo
do arquivo correspondente:

| Nome exato da function | Arquivo fonte |
|---|---|
| `interesse-associado` | `supabase/functions/interesse-associado/index.ts` |
| `matricula-base` | `supabase/functions/matricula-base/index.ts` |
| `interesse-apoio` | `supabase/functions/interesse-apoio/index.ts` |
| `fale-conosco` | `supabase/functions/fale-conosco/index.ts` |
| `inscricao-experiencia` | `supabase/functions/inscricao-experiencia/index.ts` |

Não faça deploy de `criar-associado` neste projeto — essa função é do
portal (cria login de associado), que fica de fora por enquanto.

Todas usam `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY`, injetadas
automaticamente pelo Supabase em toda Edge Function do projeto — não
precisa configurar nada a mais para isso.

## 4. Atualizar o Vercel

No painel do Vercel, projeto `mannerriege` → **Settings** →
**Environment Variables**, atualize (ou confira, se já tiver sido
criado antes com o banco antigo):

- `PUBLIC_SUPABASE_URL` = `https://hmenxikzihzyutkkxfsr.supabase.co`
- `PUBLIC_SUPABASE_ANON_KEY` = `sb_publishable_ow0eChkzvfiDT_hRL4uPVw_A1xZEtF4`

Depois de salvar, faça um **Redeploy** do último deployment (Deployments
→ ⋯ → Redeploy) para o build pegar os valores novos.

## 5. Testar

Depois dos passos acima, teste cada formulário do site
(`/associe-se`, `/base/matricula`, `/apoie`, `/contato`,
`/experiencia`) e confira:

- se o e-mail chegou em `alcir.trainotti@gmail.com` e
  `rany041076@gmail.com`;
- no caso do `/experiencia`, se a linha apareceu na tabela
  `inscricoes_experiencia_base` (Table Editor do projeto novo).

Se algo não funcionar, confira os logs em Edge Functions → (nome da
function) → **Logs**.

## O que fica de fora, por enquanto

O portal de associados (login, financeiro, módulo esportivo,
campeonatos — os `migration_002` a `migration_060` e a function
`criar-associado`) **não** faz parte deste projeto novo. Ele continua
sendo tratado à parte, quando chegar a vez de refazer o portal.
