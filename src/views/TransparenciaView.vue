<script setup>
import { siteConfig } from '../data/site.js'
import PageHero from '../components/PageHero.vue'
import SectionTag from '../components/SectionTag.vue'
import CtaButton from '../components/CtaButton.vue'
import Icon from '../components/Icon.vue'

const documentos = [
  'Estatuto Social',
  'Ata de constituição',
  'Atas de assembleias',
  'Composição da Diretoria',
  'Composição do Conselho Fiscal',
  'CNPJ',
  'Certidões',
  'Relatórios de atividades',
  'Demonstrativos financeiros',
  'Prestação de contas de projetos',
  'Editais e convocações',
]
</script>

<template>
  <div>
    <PageHero
      eyebrow="Compromisso institucional"
      title="Transparência"
      subtitle="Acreditamos que esporte, confiança e transparência caminham juntos."
    />

    <section class="bg-paper py-20">
      <div class="mx-auto max-w-4xl px-5 sm:px-8">
        <div v-reveal class="space-y-5 leading-relaxed text-ink-soft">
          <p class="text-lg text-ink">
            A transparência é um compromisso essencial do Mannerriege. Como associação esportiva
            sem fins lucrativos, entendemos que a confiança de associados, famílias, atletas,
            parceiros e apoiadores depende de uma gestão organizada, documentada e responsável.
          </p>
          <p>
            Por isso, a Associação trabalha para manter seus documentos institucionais, atas,
            demonstrativos financeiros, prestações de contas e informações relevantes organizados
            e disponíveis conforme as exigências legais, estatutárias e administrativas.
          </p>
        </div>
      </div>
    </section>

    <section class="bg-paper-dim py-20">
      <div class="mx-auto max-w-5xl px-5 sm:px-8">
        <div v-reveal class="max-w-xl">
          <SectionTag text="Documentos institucionais" />
          <h2 class="mt-4 font-display text-4xl font-extrabold text-ink sm:text-5xl">
            Nesta seção, poderão ser disponibilizados
          </h2>
        </div>

        <div class="mt-10 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          <div
            v-for="(doc, i) in documentos"
            :key="doc"
            v-reveal="i * 45"
            class="flex items-center gap-3 rounded-xl bg-white px-5 py-4 text-sm font-medium text-ink shadow-card"
          >
            <Icon name="doc" class="h-4 w-4 flex-shrink-0 text-brand" />
            {{ doc }}
          </div>
        </div>
      </div>
    </section>

    <section class="bg-ink py-20">
      <div class="mx-auto max-w-4xl px-5 text-center sm:px-8">
        <Icon name="shield" class="mx-auto h-9 w-9 text-brand" />
        <h2 v-reveal class="mt-5 font-display text-3xl font-extrabold text-white sm:text-4xl">
          Política de transparência
        </h2>
        <p v-reveal="100" class="mt-5 leading-relaxed text-paper/75">
          A {{ siteConfig.legalName }} atua com compromisso de transparência, responsabilidade
          administrativa e prestação de contas. Os recursos captados para projetos esportivos e
          sociais são aplicados conforme suas finalidades, respeitando as normas legais,
          estatutárias e as exigências dos parceiros, patrocinadores, editais e instrumentos de
          financiamento.
        </p>
      </div>
    </section>

    <section class="bg-paper py-20">
      <div class="mx-auto flex max-w-6xl flex-col items-start gap-6 px-5 sm:px-8 sm:flex-row sm:items-center sm:justify-between">
        <h2 v-reveal class="font-display text-3xl font-extrabold text-ink sm:text-4xl">
          Dúvidas sobre nossa gestão?
        </h2>
        <div v-reveal="100">
          <CtaButton to="/contato" variant="primary">Fale com a diretoria <Icon name="arrow-right" class="h-3.5 w-3.5" /></CtaButton>
        </div>
      </div>
    </section>
  </div>
</template>
