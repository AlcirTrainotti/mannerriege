# Como configurar a Edge Function "criar-associado"

Essa Edge Function cria novos associados via API administrativa do
Supabase — o que permite que o e-mail seja genuinamente opcional, sem
precisar de nenhum "e-mail fantasma".

A chave de serviço (`SUPABASE_SERVICE_ROLE_KEY`) é injetada
**automaticamente** pelo Supabase em todas as Edge Functions do projeto.
Não precisa configurar nenhum secret manualmente para essa função.

## Passos para fazer o deploy

### Opção A — Pelo painel do Supabase (mais fácil)

1. No painel do seu projeto, vá em **Edge Functions**.
2. Clique em **"Deploy a new function"** → **"Via Editor"**.
3. Dê o nome exato: `criar-associado`
4. Apague o conteúdo de exemplo.
5. Abra o arquivo
   `supabase/functions/criar-associado/index.ts` do código-fonte,
   copie todo o conteúdo e cole no editor.
6. Clique em **Deploy**.

### Opção B — Pelo CLI do Supabase

```bash
supabase functions deploy criar-associado --project-ref SEU_PROJECT_REF
```

## Testando

Depois do deploy, tente cadastrar um novo associado sem e-mail pelo
portal. O cadastro deve funcionar normalmente, sem erros de e-mail.

## Como funciona

1. O frontend chama a Edge Function com nome, telefone e senha (e-mail
   é opcional).
2. A Edge Function verifica que quem está chamando é um administrador.
3. Usa a API administrativa do Supabase para criar o usuário — essa
   API aceita criação sem e-mail, ao contrário do signup público.
4. Retorna o ID do novo usuário para o frontend preencher os dados
   extras no `profiles`.
