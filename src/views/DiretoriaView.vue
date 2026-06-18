<script setup>
import { siteConfig } from '../data/site.js'
import PageHero from '../components/PageHero.vue'
import SectionTag from '../components/SectionTag.vue'
import CtaButton from '../components/CtaButton.vue'
import Icon from '../components/Icon.vue'

function initials(name) {
  return name.split(' ').filter((w) => w[0] === w[0].toUpperCase()).slice(0, 2).map((w) => w[0]).join('')
}
</script>

<template>
  <div>
    <PageHero
      eyebrow="Governança"
      title="Diretoria"
      subtitle="Gestão com responsabilidade e transparência."
    />

    <section class="bg-paper py-20">
      <div class="mx-auto max-w-4xl px-5 text-center sm:px-8">
        <p v-reveal class="text-lg leading-relaxed text-ink-soft">
          A {{ siteConfig.legalName }} é conduzida por uma Diretoria Executiva eleita em
          Assembleia, conforme previsto em seu Estatuto Social. A gestão
          <strong class="text-ink">{{ siteConfig.diretoria.gestao }}</strong> tem como propósito
          fortalecer a organização administrativa da entidade, ampliar sua atuação social e
          estruturar o projeto Mannerriege Vôlei de Base como uma iniciativa permanente de
          formação esportiva.
        </p>
      </div>
    </section>

    <section class="bg-paper-dim py-16">
      <div class="mx-auto max-w-4xl px-5 sm:px-8">
        <div v-reveal class="mb-10 text-center">
          <SectionTag text="Diretoria Executiva" />
        </div>
        <div class="grid gap-6 sm:grid-cols-2">
          <div v-reveal class="rounded-2xl bg-white p-8 text-center shadow-card">
            <div class="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-brand font-display text-2xl font-bold text-white">
              {{ initials(siteConfig.diretoria.presidente) }}
            </div>
            <h3 class="mt-5 font-display text-2xl font-bold text-ink">{{ siteConfig.diretoria.presidente }}</h3>
            <p class="mt-1 font-mono-label text-[11px] font-bold text-brand-deep">Presidente</p>
          </div>
          <div v-reveal="120" class="rounded-2xl bg-white p-8 text-center shadow-card">
            <div class="mx-auto flex h-20 w-20 items-center justify-center rounded-full bg-ink font-display text-2xl font-bold text-white">
              {{ initials(siteConfig.diretoria.vicePresidente) }}
            </div>
            <h3 class="mt-5 font-display text-2xl font-bold text-ink">{{ siteConfig.diretoria.vicePresidente }}</h3>
            <p class="mt-1 font-mono-label text-[11px] font-bold text-brand-deep">Vice-Presidente</p>
          </div>
        </div>
      </div>
    </section>

    <section class="bg-ink py-20">
      <div class="mx-auto grid max-w-5xl gap-10 px-5 sm:px-8 lg:grid-cols-[auto_1fr] lg:items-start">
        <Icon name="shield" class="hidden h-14 w-14 text-brand lg:block" />
        <div>
          <h2 v-reveal class="font-display text-3xl font-extrabold text-white sm:text-4xl">
            Como governamos
          </h2>
          <p v-reveal="100" class="mt-5 leading-relaxed text-paper/75">
            A governança do Mannerriege é baseada na participação dos associados, no cumprimento
            do Estatuto Social, na organização documental, na responsabilidade financeira e na
            transparência das ações realizadas.
          </p>
          <p v-reveal="160" class="mt-4 leading-relaxed text-paper/75">
            Esse compromisso é fundamental para a sustentabilidade da Associação e para a
            participação em projetos, parcerias, editais, convênios e instrumentos de
            financiamento público ou privado. A Associação busca atuar com responsabilidade,
            transparência, prestação de contas e compromisso com seus associados, parceiros,
            atletas, famílias e comunidade.
          </p>
        </div>
      </div>
    </section>

    <section class="bg-paper py-20">
      <div class="mx-auto flex max-w-6xl flex-col items-start gap-6 px-5 sm:px-8 sm:flex-row sm:items-center sm:justify-between">
        <h2 v-reveal class="font-display text-3xl font-extrabold text-ink sm:text-4xl">
          Veja como prestamos contas
        </h2>
        <div v-reveal="100">
          <CtaButton to="/transparencia" variant="primary">Transparência <Icon name="arrow-right" class="h-3.5 w-3.5" /></CtaButton>
        </div>
      </div>
    </section>
  </div>
</template>
