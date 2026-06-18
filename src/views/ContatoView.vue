<script setup>
import { ref } from 'vue'
import { siteConfig } from '../data/site.js'
import PageHero from '../components/PageHero.vue'
import Icon from '../components/Icon.vue'

const assuntos = [
  'Quero apoiar o projeto',
  'Quero ser parceiro',
  'Tenho interesse no Vôlei de Base',
  'Quero falar com a Diretoria',
  'Imprensa / divulgação',
  'Outros assuntos',
]

const form = ref({ nome: '', email: '', telefone: '', assunto: assuntos[0], mensagem: '' })
const sent = ref(false)

// Sem backend conectado: o envio abre o app de e-mail do visitante com os
// dados ja preenchidos. Para receber as mensagens direto em um banco de dados
// ou enviar e-mails automaticamente, integre futuramente um servico como
// Formspree, EmailJS ou um backend proprio.
function handleSubmit() {
  const body = [
    `Nome: ${form.value.nome}`,
    `Telefone: ${form.value.telefone || '-'}`,
    '',
    form.value.mensagem,
  ].join('\n')

  const mailto = `mailto:${siteConfig.email}?subject=${encodeURIComponent('[Site] ' + form.value.assunto)}&body=${encodeURIComponent(body)}`
  window.location.href = mailto
  sent.value = true
}
</script>

<template>
  <div>
    <PageHero
      eyebrow="Fale com a gente"
      title="Contato"
      subtitle="Quer saber mais sobre a Associação, apoiar o projeto, inscrever um atleta, propor uma parceria ou conversar com nossa diretoria?"
    />

    <section class="bg-paper py-20">
      <div class="mx-auto grid max-w-6xl gap-12 px-5 sm:px-8 lg:grid-cols-[0.85fr_1.15fr]">
        <!-- INFO -->
        <div v-reveal class="space-y-7">
          <p class="leading-relaxed text-ink-soft">
            Entre em contato com o Mannerriege. Será um prazer apresentar nossa história, nossos
            projetos e nossas possibilidades de colaboração.
          </p>

          <div class="flex items-start gap-3">
            <Icon name="pin" class="mt-0.5 h-5 w-5 flex-shrink-0 text-brand" />
            <p class="text-sm text-ink">
              {{ siteConfig.address.street }}<br />
              {{ siteConfig.address.district }}, {{ siteConfig.address.city }}/{{ siteConfig.address.state }}
            </p>
          </div>

          <div class="flex items-start gap-3">
            <Icon name="mail" class="mt-0.5 h-5 w-5 flex-shrink-0 text-brand" />
            <a :href="`mailto:${siteConfig.email}`" class="text-sm text-ink hover:text-brand-deep">{{ siteConfig.email }}</a>
          </div>

          <div class="flex items-start gap-3">
            <Icon name="whatsapp" class="mt-0.5 h-5 w-5 flex-shrink-0 text-brand" />
            <a :href="`https://wa.me/${siteConfig.whatsappNumber}`" target="_blank" rel="noopener" class="text-sm text-ink hover:text-brand-deep">{{ siteConfig.phone }} (WhatsApp)</a>
          </div>

          <div class="flex items-start gap-3">
            <Icon name="instagram" class="mt-0.5 h-5 w-5 flex-shrink-0 text-brand" />
            <a :href="siteConfig.instagramUrl" target="_blank" rel="noopener" class="text-sm text-ink hover:text-brand-deep">{{ siteConfig.instagramHandle }}</a>
          </div>
        </div>

        <!-- FORM -->
        <div v-reveal="120" class="rounded-3xl bg-paper-dim p-7 sm:p-9">
          <form v-if="!sent" class="space-y-5" @submit.prevent="handleSubmit">
            <div>
              <label class="font-mono-label text-[10px] font-bold text-ink-soft">Nome</label>
              <input v-model="form.nome" type="text" required class="mt-2 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div class="grid gap-5 sm:grid-cols-2">
              <div>
                <label class="font-mono-label text-[10px] font-bold text-ink-soft">E-mail</label>
                <input v-model="form.email" type="email" required class="mt-2 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
              </div>
              <div>
                <label class="font-mono-label text-[10px] font-bold text-ink-soft">Telefone</label>
                <input v-model="form.telefone" type="tel" class="mt-2 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
              </div>
            </div>
            <div>
              <label class="font-mono-label text-[10px] font-bold text-ink-soft">Assunto</label>
              <select v-model="form.assunto" class="mt-2 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand">
                <option v-for="a in assuntos" :key="a" :value="a">{{ a }}</option>
              </select>
            </div>
            <div>
              <label class="font-mono-label text-[10px] font-bold text-ink-soft">Mensagem</label>
              <textarea v-model="form.mensagem" required rows="4" class="mt-2 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand"></textarea>
            </div>
            <button type="submit" class="w-full rounded-full bg-brand px-6 py-3.5 font-mono-label text-[11px] font-bold text-white transition-colors hover:bg-brand-deep">
              Enviar mensagem
            </button>
            <p class="text-center text-xs text-ink-soft/70">Ao enviar, seu aplicativo de e-mail será aberto com a mensagem pronta para {{ siteConfig.email }}.</p>
          </form>

          <div v-else class="py-6 text-center">
            <Icon name="check" class="mx-auto h-10 w-10 text-brand" />
            <h3 class="mt-4 font-display text-2xl font-bold text-ink">Quase lá!</h3>
            <p class="mt-2 text-sm leading-relaxed text-ink-soft">
              Abrimos seu aplicativo de e-mail com a mensagem pronta. Se ele não abriu
              automaticamente, escreva direto para
              <a :href="`mailto:${siteConfig.email}`" class="font-semibold text-brand-deep">{{ siteConfig.email }}</a>.
            </p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
