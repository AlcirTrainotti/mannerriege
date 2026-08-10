# Como configurar a inscrição da "Experiência Mannerriege: A Nova Geração"

A página `/experiencia` do site (Astro, pasta `apps/site`) tem o
formulário de inscrição da aula inaugural do Vôlei de Base, dia
29/08/2026. Diferente dos outros formulários do site (que só mandam
e-mail), este **grava cada inscrição numa tabela do Supabase** e
controla automaticamente as 20 vagas de cada turma — depois disso,
envia os e-mails.

## Projeto Supabase

Esse formulário usa o projeto Supabase **próprio do site**
(`https://hmenxikzihzyutkkxfsr.supabase.co`), o mesmo dos outros
formulários públicos (`/associe-se`, `/base/matricula`, `/apoie`,
`/contato`) — ver `COMO_CONFIGURAR_SUPABASE_SITE.md` para o setup
completo desse projeto do zero. Esse banco é **desvinculado do portal**
(que será refeito à parte, mais adiante) — nada aqui depende do banco
antigo do portal. As variáveis `PUBLIC_SUPABASE_URL` /
`PUBLIC_SUPABASE_ANON_KEY` já usadas no resto do site cobrem o
`/experiencia` também; não precisa adicionar nada novo no Vercel além
do que já está documentado nos outros `COMO_CONFIGURAR_*.md`.

São dois passos de configuração: a tabela no banco e a Edge Function.
Sem os dois, o formulário não funciona.

## 1. Criar a tabela no banco (SQL Editor do Supabase)

1. No painel do Supabase, vá em **SQL Editor** → **New query**.
2. Abra o arquivo `supabase/migration_061_inscricoes_experiencia_base.sql`
   (dentro da pasta de código deste projeto), copie todo o conteúdo e
   cole no editor.
3. Rode a query (**Run**).

Isso cria a tabela `inscricoes_experiencia_base` com todos os campos do
formulário e um status de controle de vaga (`recebida`, `lista_espera`,
`em_validacao`, `confirmada`, `presenca_confirmada`, `compareceu`,
`matricula`, `cancelada`).

**Importante sobre privacidade:** a tabela é criada com RLS ligado e
**sem nenhuma policy** — de propósito. Isso significa que ninguém
consegue ler ou escrever nela pela API pública (nem logado, nem anônimo).
A única escrita é feita pela Edge Function (usa a chave de service role,
que ignora RLS). Para você ver e gerenciar as inscrições, use o **Table
Editor** do Supabase (login do projeto já usa a service role) — é lá
que os dados de saúde e contato de emergência de menores de idade ficam
protegidos.

## 2. Criar a Edge Function (pelo próprio painel)

1. No painel do Supabase, vá em **Edge Functions**.
2. Clique em **"Deploy a new function"** → **"Via Editor"**.
3. Dê o nome exato: `inscricao-experiencia`
4. Apague o conteúdo de exemplo.
5. Abra o arquivo `supabase/functions/inscricao-experiencia/index.ts`
   (dentro da pasta de código deste projeto), copie todo o conteúdo e
   cole no editor do Supabase.
6. Clique em **Deploy**.

A função usa `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY`, que o
Supabase já injeta automaticamente em toda Edge Function — não precisa
configurar nada a mais para isso.

## 3. Confirmar o segredo do Resend

A função também envia e-mail via Resend, usando o mesmo segredo
`RESEND_API_KEY` já configurado para `interesse-associado`,
`matricula-base`, `interesse-apoio` e `fale-conosco`. Se você já
configurou esse segredo antes, não precisa fazer nada — se ainda não
configurou nenhum formulário do site, siga o passo 1 e 3 de
`COMO_CONFIGURAR_INTERESSE_ASSOCIADO.md`.

Se o segredo não estiver configurado, a inscrição continua sendo salva
normalmente no banco — só o e-mail não é enviado (a função registra o
erro nos logs, mas não trava a inscrição).

## 4. Como funciona o controle de vagas

Cada turma (`masculino` e `feminino`) tem 20 vagas. A cada nova
inscrição, a função conta quantas inscrições da mesma turma já estão
com status `recebida`, `em_validacao`, `confirmada`,
`presenca_confirmada`, `compareceu` ou `matricula` (ou seja, tudo que
não é lista de espera nem cancelamento):

- Se ainda houver vaga (menos de 20): a inscrição entra como
  **`recebida`**, e a pessoa recebe o e-mail de confirmação normal.
- Se a turma já estiver com 20: a inscrição entra direto como
  **`lista_espera`**, e a pessoa recebe um e-mail avisando disso.

Em ambos os casos, a diretoria (`alcir.trainotti@gmail.com` e
`rany041076@gmail.com`) recebe um e-mail com todos os dados da
inscrição e o status atribuído.

## 5. Gerenciando o dia a dia (fluxo de status)

Use o Table Editor do Supabase para avançar cada inscrição pelo fluxo:

```
recebida → em_validacao → confirmada → presenca_confirmada → compareceu → matricula
```

(ou `lista_espera` / `cancelada` a qualquer momento). Isso é feito
manualmente por enquanto — não há tela de administração para isso
ainda. Se fizer sentido mais pra frente, dá pra construir uma tela no
portal para gerenciar isso sem precisar abrir o Supabase.

Combinado com a diretoria: na sexta-feira 28/08, solicitar resposta
"SIM" das famílias com inscrição `recebida` até as 18h. Depois disso,
liberar as vagas não confirmadas para quem estiver em `lista_espera`.

## 6. Testar

1. No site publicado (ou rodando `npm run dev` em `apps/site`), abra
   `/experiencia` e preencha o formulário com dados de teste.
2. Envie e confira:
   - se a linha apareceu na tabela `inscricoes_experiencia_base` (Table
     Editor do Supabase);
   - se o e-mail de confirmação chegou no e-mail de teste usado;
   - se o e-mail de notificação chegou nas duas caixas da diretoria.
3. Para testar a lista de espera, crie manualmente 20 linhas de teste
   numa turma (ou baixe temporariamente o limite no código da função) e
   confirme que a 21ª inscrição entra como `lista_espera`.

Se algo não funcionar, volte em Edge Functions → `inscricao-experiencia`
→ **Logs**, para ver a mensagem de erro exata.
