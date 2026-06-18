# Como configurar a Área do Associado (Supabase)

A Área do Associado precisa de um lugar para guardar os logins e os dados dos
associados. Usamos o **Supabase**, que é gratuito para o tamanho do Mannerriege
e não exige que vocês mantenham um servidor próprio.

Siga os passos na ordem. Leva uns 15 minutos na primeira vez.

## 1. Criar o projeto no Supabase

1. Acesse https://supabase.com e crie uma conta gratuita (pode entrar com o
   Google).
2. Clique em "New Project".
3. Dê um nome (ex: `mannerriege`), crie uma senha para o banco de dados (pode
   gerar uma automática - só guarde em um lugar seguro, não vai precisar usá-la
   no dia a dia) e escolha uma região perto do Brasil (ex: South America -
   São Paulo, se disponível).
4. Aguarde 1-2 minutos enquanto o projeto é criado.

## 2. Criar as tabelas

1. No menu da esquerda, clique em "SQL Editor" → "New query".
2. Abra o arquivo `supabase/schema.sql` (está dentro desta mesma pasta do
   projeto), copie todo o conteúdo e cole no editor do Supabase.
3. Clique em "Run". Deve aparecer "Success" no final.

## 3. Pegar as chaves de conexão

O painel da Supabase divide essa informação em dois lugares:

1. No menu da esquerda, em "Integrations" (mais abaixo, fora de
   "Configuration"), clique em "Data API". Copie o valor de "Project URL".
2. Ainda no menu da esquerda, agora em "Configuration", clique em "API
   Keys". Copie a chave mostrada ali - pode aparecer como "Publishable key"
   (projetos novos, começa com `sb_publishable_...`) ou como "anon public"
   (projetos mais antigos). As duas funcionam exatamente da mesma forma com
   o código deste projeto.
3. Na pasta do projeto (no seu computador), crie uma cópia do arquivo
   `.env.example` e renomeie para `.env`. Cole os dois valores que você
   copiou nos campos correspondentes.

## 4. Criar o primeiro usuário (você mesmo, como administrador)

1. No Supabase, vá em "Authentication" → "Users" → "Add user" → "Create new
   user".
2. Preencha seu e-mail e uma senha. Pode desmarcar a opção de exigir
   confirmação por e-mail para este primeiro usuário, para simplificar.
3. Volte no "SQL Editor" e rode este comando, trocando o e-mail pelo que você
   acabou de cadastrar:

```sql
update public.profiles set role = 'admin' where email = 'seuemail@exemplo.com';
```

Isso te torna administrador. Todos os próximos usuários que forem criados já
nascem como "associado" por padrão, e só um administrador pode promover
outra pessoa depois (pela própria tela de Associados no site).

## 5. Testar

1. Na pasta do projeto, rode `npm install` (se ainda não rodou) e depois
   `npm run dev`.
2. Acesse o endereço local que aparecer, e vá até `/#/portal` (ou clique no
   ícone de cadeado no menu do site).
3. Entre com o e-mail e senha que você criou no passo 4. Você deve ver o
   painel da diretoria, com a lista de associados.

## 6. Publicar (Netlify/Vercel)

O arquivo `.env` não é enviado para o GitHub nem para a hospedagem
automaticamente (e não deve ser, por segurança). Ao publicar:

- **Vercel**: vá em Project Settings → Environment Variables, e adicione
  `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY` com os mesmos valores do seu
  `.env`.
- **Netlify**: o caminho equivalente é Site configuration → Environment
  variables.

Depois disso, gere um novo build (`npm run build`) e publique normalmente.

## Como cadastrar novos associados no dia a dia

1. No Supabase, vá em "Authentication" → "Users" → "Add user", e crie o
   login (e-mail + senha temporária) da pessoa.
2. Avise a pessoa da senha temporária (ela pode trocar depois pelo "Esqueci
   minha senha" na tela de login).
3. O cadastro dela já aparece automaticamente na lista de Associados, dentro
   do site. Lá, defina a categoria (35+, 40+...) e a modalidade (Vôlei,
   Vôlei + Dominó, ou Dominó).

## O que NÃO está incluído ainda

Este é o sistema de cadastro e papéis (associado/administrador). Avisos,
controle financeiro (caixa, mensalidades) e envio de e-mail/WhatsApp ainda
não estão conectados a este painel - foram deixados de lado por enquanto,
como combinado, e podem ser adicionados depois em cima dessa mesma base.
