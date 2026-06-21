# Como configurar o resumo automático do regulamento (IA)

Essa configuração é **opcional**. Sem ela, o resumo continua podendo ser
escrito manualmente - só o botão "Gerar resumo automático" não funciona.

O resumo é gerado pela Claude, a IA da Anthropic (a mesma empresa por
trás deste assistente que ajudou a construir o site). Ela lê o PDF do
regulamento e escreve um resumo em português com os pontos principais.

⚠️ Essa é uma API paga, mas o custo por resumo é bem baixo (poucos
centavos de dólar por PDF, já que só roda quando você clica no botão -
não fica calculando o tempo todo).

## 1. Criar uma chave de API da Anthropic

1. Acesse https://console.anthropic.com e crie uma conta (pode ser com o
   e-mail do clube).
2. Adicione um cartão de crédito e carregue um pequeno saldo (ex: US$ 5,
   que dá para gerar centenas de resumos).
3. Vá em "API Keys" → "Create Key". Copie a chave gerada (começa com
   `sk-ant-`).

## 2. Criar a função no Supabase (pelo próprio painel)

1. No painel do Supabase, vá em **Edge Functions**.
2. Clique em **"Deploy a new function"** → **"Via Editor"**.
3. Dê o nome exato: `resumir-regulamento`
4. Apague o conteúdo de exemplo.
5. Abra o arquivo
   `supabase/functions/resumir-regulamento/index.ts` (dentro do zip do
   código-fonte deste projeto), copie todo o conteúdo e cole no editor
   do Supabase.
6. Clique em **Deploy**.

## 3. Guardar a chave da Anthropic como segredo

1. Ainda em Edge Functions, vá em **"Secrets"** (gerenciar segredos).
2. Adicione um novo segredo:
   - Nome: `ANTHROPIC_API_KEY`
   - Valor: a chave que você copiou no passo 1.
3. Salve.

## 4. Testar

1. No site, abra um campeonato que já tenha um regulamento em PDF
   importado.
2. Clique em "✨ Gerar resumo automático".
3. Em alguns segundos, o resumo aparece pronto para você revisar e
   ajustar antes de salvar.

Se algo não funcionar, volte em Edge Functions → `resumir-regulamento`
→ **Logs**, para ver a mensagem de erro exata.
