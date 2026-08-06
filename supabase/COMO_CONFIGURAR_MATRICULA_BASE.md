# Como configurar o e-mail do formulário "Quero matricular" (Vôlei de Base)

O site institucional (site em Astro, pasta `apps/site`) tem uma página
`/base/matricula` com o formulário de matrícula do Vôlei de Base. Quando
alguém preenche e envia, um e-mail precisa chegar para a coordenação com
os dados do atleta. Isso é feito por uma Edge Function do Supabase
(`matricula-base`), que usa o serviço **Resend** (https://resend.com)
para enviar o e-mail — o Supabase sozinho não envia e-mail arbitrário,
só usa e-mail para os fluxos de login.

Sem essa configuração, o formulário mostra erro para quem preencher —
por isso este passo **não é opcional**, precisa ser feito antes de
divulgar a página.

Se você já configurou o `RESEND_API_KEY` para o formulário
`interesse-associado` (ver `COMO_CONFIGURAR_INTERESSE_ASSOCIADO.md`), o
passo 1 e o passo 3 abaixo já estão feitos — é o mesmo segredo,
reaproveitado por todas as funções de e-mail do site. Só falta o passo
2 (deploy desta função nova).

## 1. Criar uma conta no Resend e pegar a chave de API

1. Acesse https://resend.com e crie uma conta (pode ser com o e-mail do
   clube). O plano gratuito já cobre bastante volume para esse uso
   (100 e-mails/dia, 3.000/mês).
2. No painel, vá em **API Keys** → **Create API Key**. Copie a chave
   gerada (começa com `re_`).

## 2. Criar a função no Supabase (pelo próprio painel)

1. No painel do Supabase, vá em **Edge Functions**.
2. Clique em **"Deploy a new function"** → **"Via Editor"**.
3. Dê o nome exato: `matricula-base`
4. Apague o conteúdo de exemplo.
5. Abra o arquivo `supabase/functions/matricula-base/index.ts` (dentro
   da pasta de código deste projeto), copie todo o conteúdo e cole no
   editor do Supabase.
6. Clique em **Deploy**.

## 3. Guardar a chave do Resend como segredo

1. Ainda em Edge Functions, vá em **"Secrets"**.
2. Adicione um novo segredo (pule se já existir de uma função anterior):
   - Nome: `RESEND_API_KEY`
   - Valor: a chave copiada no passo 1 (`re_...`)
3. Salve.

## 4. Confirmar quem recebe o e-mail

Hoje a função envia para dois endereços fixos, definidos direto no
código (`DESTINATARIOS` em `matricula-base/index.ts`):

- `alcir.trainotti@gmail.com`
- `rany041076@gmail.com`

Se precisar adicionar ou trocar destinatário, edite essa lista no
código e faça o deploy de novo (repetir o passo 2).

## 5. Testar

1. No site publicado (ou rodando `npm run dev` em `apps/site`), abra
   `/base/matricula` e preencha o formulário com dados de teste.
2. Envie e confira se o e-mail chega nas duas caixas de entrada
   (verifique a caixa de spam na primeira vez).

Se algo não funcionar, volte em Edge Functions → `matricula-base` →
**Logs**, para ver a mensagem de erro exata.
