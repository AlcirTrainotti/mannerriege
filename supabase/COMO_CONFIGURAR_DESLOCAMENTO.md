# Como configurar o cálculo de deslocamento entre ginásios (gratuito)

Essa configuração é **opcional**. Sem ela, o sistema ainda funciona
normalmente — só não consegue calcular automaticamente quanto tempo leva
para ir de um ginásio a outro quando duas categorias têm jogos em locais
diferentes no mesmo dia.

Usamos o **OpenRouteService** (openrouteservice.org), um serviço gratuito
baseado em dados abertos (OpenStreetMap). Não precisa de cartão de
crédito. A cota gratuita é de 2.500 cálculos por dia — bem mais do que um
clube usa, ainda mais que cada combinação de ginásios só é calculada uma
vez (o sistema guarda em cache).

Por uma exigência de segurança do próprio OpenRouteService, a chave não
pode ficar no código do site (ela ficaria visível para qualquer pessoa).
Por isso, o cálculo roda numa pequena função no servidor do Supabase
("Edge Function"), que guarda a chave em segredo. Você não precisa saber
programar para configurar isso — é só copiar e colar.

## 1. Criar a conta gratuita no OpenRouteService

1. Acesse https://openrouteservice.org/dev/#/signup e crie uma conta
   (pode usar o e-mail do clube).
2. Confirme o e-mail.
3. Entre no painel ("Dashboard") e clique em "Request a token" (ou
   "Create token"). Escolha o plano "Standard" (gratuito).
4. Copie a chave (token) gerada - uma sequência longa de letras e
   números.

## 2. Criar a função no Supabase (pelo próprio painel, sem instalar nada)

1. No painel do Supabase, vá em **Edge Functions** no menu lateral.
2. Clique em **"Deploy a new function"** → **"Via Editor"**.
3. Dê o nome exato: `calcular-deslocamento`
4. Apague o conteúdo de exemplo que aparecer no editor.
5. Abra o arquivo `supabase/functions/calcular-deslocamento/index.ts`
   (dentro do zip do código-fonte deste projeto), copie todo o conteúdo
   e cole no editor do Supabase.
6. Clique em **Deploy**.

## 3. Guardar a chave do OpenRouteService como segredo

1. Ainda em Edge Functions, procure **"Secrets"** ou **"Manage secrets"**
   (gerenciar segredos) no menu.
2. Adicione um novo segredo:
   - Nome: `ORS_API_KEY`
   - Valor: a chave que você copiou no passo 1.
3. Salve.

## 4. Testar

1. No site, vá em um campeonato → aba "Jogos e Conflitos".
2. Cadastre dois jogos de categorias diferentes no mesmo dia, em
   ginásios com endereços diferentes, com pelo menos um atleta em comum
   entre as duas categorias.
3. Clique em "Verificar conflitos de horário". Se a configuração deu
   certo, o sistema calcula o tempo de deslocamento entre os dois
   endereços automaticamente.

Se algo não funcionar, volte em Edge Functions → `calcular-deslocamento`
→ **Logs**, para ver a mensagem de erro exata.

## Sem essa configuração

O sistema continua funcionando normalmente. A verificação de conflitos
ainda identifica jogos com horários sobrepostos no mesmo ginásio; só não
calcula o tempo de deslocamento quando os ginásios são diferentes - nesse
caso, mostra um aviso para a diretoria conferir manualmente.
