<script setup>
import { siteConfig } from '../data/site.js'
import PageHero from '../components/PageHero.vue'
</script>

<template>
  <div>
    <PageHero eyebrow="Jurídico" title="Política de Privacidade" />

    <section class="bg-paper py-20">
      <div class="mx-auto max-w-3xl space-y-5 px-5 text-sm leading-relaxed text-ink-soft sm:px-8">
        <p>
          Esta página descreve, de forma simples, como a {{ siteConfig.legalName }} trata as
          informações de quem visita este site.
        </p>
        <p>
          O formulário de contato deste site não envia dados para nenhum servidor: ao clicar em
          "Enviar mensagem", o seu próprio aplicativo de e-mail é aberto com o conteúdo já
          preenchido, e o envio só acontece se você concluir o envio do e-mail. Não armazenamos
          nem processamos automaticamente as informações digitadas no formulário.
        </p>
        <p>
          Caso você opte por nos enviar um e-mail, uma mensagem de WhatsApp ou um contato pelo
          Instagram, utilizaremos essas informações apenas para responder ao seu contato, tratar
          de parcerias, dúvidas ou solicitações relacionadas à Associação.
        </p>
        <p>
          Este site não utiliza cookies de rastreamento nem compartilha dados de visitantes com
          terceiros para fins de publicidade.
        </p>
        <p>
          Em caso de dúvidas sobre esta política, entre em contato pelo e-mail
          <a :href="`mailto:${siteConfig.email}`" class="font-semibold text-brand-deep">{{ siteConfig.email }}</a>.
        </p>
        <p class="text-xs text-ink-soft/60">
          Última atualização: {{ new Date().toLocaleDateString('pt-BR', { month: 'long', year: 'numeric' }) }}.
        </p>
      </div>
    </section>
  </div>
</template>
