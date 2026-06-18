# Site Mannerriege Vôlei — projeto Vue.js

Site institucional da Mannerriege, construído em Vue 3 + Vite + Tailwind CSS.

## Como ver o site no seu computador

Pré-requisito: ter o Node.js instalado (https://nodejs.org), versão 18 ou mais recente.

```bash
npm install
npm run dev
```

Isso vai abrir um endereço local (algo como http://localhost:5173) onde você pode navegar
pelo site e ver as alterações em tempo real conforme edita os arquivos.

## Como gerar a versão final para publicar

```bash
npm run build
```

Isso cria uma pasta `dist/` com o site já compilado (HTML, CSS e JS otimizados). É essa pasta
`dist/` que deve ser publicada na internet — não a pasta `src/`.

## Como publicar (hospedagem)

A forma mais simples, sem precisar saber programação:

1. Crie uma conta gratuita no Netlify (https://app.netlify.com) ou na Vercel (https://vercel.com).
2. Depois de rodar `npm run build`, arraste a pasta `dist/` para a área de upload do Netlify
   ("Deploy manually" / "Drag and drop").
3. Em poucos segundos o site estará no ar, com um endereço temporário que pode depois ser
   trocado por um domínio próprio (ex: mannerriege.com.br).

Alternativa um pouco mais avançada: conectar este projeto a um repositório no GitHub e ligar o
Netlify/Vercel diretamente nele — assim, toda vez que você atualizar o conteúdo, o site
republica automaticamente.

## Antes de publicar, atualize estas informações (ATENCAO)

Estão centralizadas no arquivo `src/data/site.js` para facilitar a edição:

- E-mail de contato (`email`) — está com um valor temporário.
- Telefone/WhatsApp (`phone` e `whatsappNumber`) — está com um valor temporário.
- Grafia oficial do nome jurídico e do CNPJ — confirme no Estatuto Social se é
  "Mannerriege" ou "Manneriegue" na razão social.

Esses pontos aparecem comentados com "ATENCAO" no topo do arquivo `src/data/site.js`.

## Onde editar cada parte do conteúdo

- `src/data/site.js` — dados gerais (contato, diretoria, endereço, ano de fundação).
- `src/views/` — uma pasta com um arquivo por página (HomeView, SobreView, HistoriaView,
  ProjetosView, DiretoriaView, TransparenciaView, ApoieView, ContatoView). O texto de cada
  página está dentro do respectivo arquivo, dentro das tags `<template>`.
- `src/assets/img/` — fotos usadas no site. Para trocar uma foto, basta substituir o arquivo
  mantendo o mesmo nome, ou trocar o nome no `import` correspondente dentro do arquivo da
  página.

## Sobre o formulário de contato

O formulário da página "Contato" não tem um servidor por trás: ao enviar, ele abre o
aplicativo de e-mail do visitante já com a mensagem preenchida. Se no futuro vocês quiserem
receber as mensagens diretamente em um banco de dados ou enviar e-mails automáticos sem
depender do app de e-mail do visitante, será necessário integrar um serviço como Formspree,
EmailJS, ou um backend próprio.

## Stack utilizada

- Vue 3 (Composition API, `<script setup>`)
- Vue Router 4 (rotas em modo hash, funciona em qualquer hospedagem estática sem configuração extra)
- Tailwind CSS v4
- Vite como ferramenta de build
