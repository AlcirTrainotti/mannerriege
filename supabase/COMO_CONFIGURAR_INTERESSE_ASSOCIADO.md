# Como configurar o e-mail do formulário "Quero ser associado"

O site institucional (site em Astro, pasta `apps/site`) tem uma página
`/associe-se` com um formulário público. Quando alguém preenche e envia,
um e-mail precisa chegar para a diretoria com os dados da pessoa. Isso é
feito por uma Edge Function do Supabase (`interesse-associado`), que usa
o serviço **Resend** (https://resend.com) para efetivamente enviar o
e-mail — o Supabase sozinho não envia e-mail arbitrário, só usa e-mail
para os fluxos de login.

Sem essa configuração, o formulário mostra erro para quem preencher —
por isso este passo **não é opcional**, precisa ser feito antes de
divulgar a página.

## 1. Criar uma conta no Resend e pegar a chave de API

1. Acesse https://resend.com e crie uma conta (pode ser com o e-mail do
   clube). O plano gratuito já cobre bastante volume para esse uso
   (100 e-mails/dia, 3.000/mês).
2. No painel, vá em **API Keys** → **Create API Key**. Copie a chave
   gerada (começa com `re_`).

⚠️ Por padrão, o Resend só permite remetente `onboarding@resend.dev`
sem verificar domínio — funciona para começar, mas e-mails assim têm
mais chance de cair em spam. Quando quiser, dá pra verificar o domínio
`mannerriege.com.br` no Resend (adiciona uns registros DNS no
Registro.br) e trocar o remetente da função para
`associe-se@mannerriege.com.br` — não é bloqueante pra funcionar agora.

## 2. Criar a função no Supabase (pelo próprio painel)

1. No painel do Supabase, vá em **Edge Functions**.
2. Clique em **"Deploy a new function"** → **"Via Editor"**.
3. Dê o nome exato: `interesse-associado`
4. Apague o conteúdo de exemplo.
5. Abra o arquivo `supabase/functions/interesse-associado/index.ts`
   (dentro da pasta de código deste projeto), copie todo o conteúdo e
   cole no editor do Supabase.
6. Clique em **Deploy**.

## 3. Guardar a chave do Resend como segredo

1. Ainda em Edge Functions, vá em **"Secrets"**.
2. Adicione um novo segredo:
   - Nome: `RESEND_API_KEY`
   - Valor: a chave copiada no passo 1 (`re_...`)
3. Salve.

## 4. Confirmar quem recebe o e-mail

Hoje a função envia para dois endereços fixos, definidos direto no
código (`DESTINATARIOS` em `interesse-associado/index.ts`):

- `alcir.trainotti@gmail.com`
- `rany041076@gmail.com`

Se precisar adicionar ou trocar destinatário, edite essa lista no
código e faça o deploy de novo (repetir o passo 2).

## 5. Testar

1. No site publicado (ou rodando `npm run dev` em `apps/site`), abra
   `/associe-se` e preencha o formulário com um dado de teste.
2. Envie e confira se o e-mail chega nas duas caixas de entrada
   (verifique a caixa de spam na primeira vez).

Se algo não funcionar, volte em Edge Functions → `interesse-associado`
→ **Logs**, para ver a mensagem de erro exata.
