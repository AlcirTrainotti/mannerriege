<script setup>
import SectionTag from '../components/SectionTag.vue'
import PageHero from '../components/PageHero.vue'
import CtaButton from '../components/CtaButton.vue'
import Icon from '../components/Icon.vue'

const cotas = [
  {
    name: 'Basic',
    price: '800',
    highlight: false,
    benefits: [
      '1 camiseta exclusiva',
      'Divulgação da empresa nas redes sociais',
      'Menção no intervalo das transmissões',
    ],
  },
  {
    name: 'Exclusive',
    price: '8.000',
    highlight: false,
    benefits: [
      '3 camisetas exclusivas',
      'Destaque secundário nas camisetas de passeio',
      'Destaque secundário nas camisetas de jogo',
      'Divulgação da empresa nas redes sociais',
      'Destaque secundário na bandeira do clube',
      'Propaganda secundária no intervalo das transmissões',
      'Participação na entrega de premiações (na ausência do patrocinador Master)',
    ],
  },
  {
    name: 'Master',
    price: '15.000',
    highlight: true,
    benefits: [
      '10 camisetas exclusivas',
      'Destaque central nas camisetas de passeio',
      'Destaque central nas camisetas de jogo',
      'Divulgações frequentes nas redes sociais',
      'Destaque central na bandeira do clube',
      'Transmissão com o nome do patrocínio Master',
      'Propaganda destacada na transmissão',
      'Participação exclusiva na entrega de premiações',
    ],
  },
]

const ganhos = [
  'Ajuda na saúde mental das pessoas',
  'Ajuda na manutenção da saúde física',
  'Ajuda a reduzir o risco de doenças',
  'Ajuda na transmissão de valores para a sociedade',
  'Ajuda no fortalecimento dos esportes Master',
  'Associação da sua marca com valores éticos e morais do esporte',
  'Associação da sua marca ao cuidado dos idosos por meio do esporte',
  'Divulgação para uma comunidade com dezenas de milhares de pessoas',
]
</script>

<template>
  <div>
    <PageHero
      eyebrow="Parceiros"
      title="Apoie o Mannerriege"
      subtitle="Sua empresa também pode fazer parte dessa história. Ao apoiar o Mannerriege, você contribui diretamente para o desenvolvimento de jovens atletas e para o fortalecimento do esporte em Joinville."
    />

    <!-- COTAS -->
    <section class="bg-paper py-20">
      <div class="mx-auto max-w-6xl px-5 sm:px-8">
        <div v-reveal class="max-w-xl">
          <SectionTag text="Cotas de patrocínio" />
          <h2 class="mt-4 font-display text-4xl font-extrabold text-ink sm:text-5xl">
            Escolha como apoiar
          </h2>
        </div>

        <div class="mt-12 grid gap-6 lg:grid-cols-3 lg:items-stretch">
          <div
            v-for="(c, i) in cotas"
            :key="c.name"
            v-reveal="i * 100"
            class="flex flex-col rounded-3xl p-8"
            :class="c.highlight ? 'bg-ink text-white shadow-lift lg:-translate-y-3' : 'bg-white text-ink shadow-card'"
          >
            <span
              v-if="c.highlight"
              class="mb-4 inline-flex w-fit items-center gap-1.5 rounded-full bg-brand px-3 py-1 font-mono-label text-[10px] font-bold text-white"
            >
              Cota principal
            </span>
            <h3 class="font-display text-2xl font-extrabold uppercase" :class="c.highlight ? 'text-white' : 'text-ink'">
              {{ c.name }}
            </h3>
            <p class="mt-3">
              <span class="font-display text-4xl font-extrabold" :class="c.highlight ? 'text-brand' : 'text-ink'">R$ {{ c.price }}</span>
            </p>
            <ul class="mt-6 flex-1 space-y-3">
              <li v-for="b in c.benefits" :key="b" class="flex items-start gap-2.5 text-sm leading-snug" :class="c.highlight ? 'text-paper/85' : 'text-ink-soft'">
                <Icon name="check" class="mt-0.5 h-4 w-4 flex-shrink-0" :class="c.highlight ? 'text-brand' : 'text-brand-deep'" />
                {{ b }}
              </li>
            </ul>
            <div class="mt-7">
              <CtaButton to="/contato" :variant="c.highlight ? 'primary' : 'outline-dark'">Quero essa cota</CtaButton>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- O QUE VOCE GANHA -->
    <section class="bg-paper-dim py-20">
      <div class="mx-auto max-w-5xl px-5 sm:px-8">
        <div v-reveal class="max-w-xl">
          <SectionTag text="Retorno para sua marca" />
          <h2 class="mt-4 font-display text-4xl font-extrabold text-ink sm:text-5xl">
            O que você ganha
          </h2>
        </div>

        <div class="mt-10 grid gap-3 sm:grid-cols-2">
          <div
            v-for="(g, i) in ganhos"
            :key="g"
            v-reveal="i * 50"
            class="flex items-start gap-3 rounded-xl bg-white px-5 py-4 text-sm leading-snug text-ink shadow-card"
          >
            <Icon name="heart" class="mt-0.5 h-4 w-4 flex-shrink-0 text-brand" />
            {{ g }}
          </div>
        </div>
      </div>
    </section>

    <section class="bg-brand py-20">
      <div class="mx-auto max-w-3xl px-5 text-center sm:px-8">
        <h2 v-reveal class="font-display text-3xl font-extrabold uppercase text-white sm:text-4xl">
          Faça parte desse time
        </h2>
        <p v-reveal="100" class="mx-auto mt-4 max-w-xl leading-relaxed text-white/85">
          Quer saber mais sobre as cotas, propor um formato diferente de parceria ou tirar
          dúvidas? Fale com a diretoria do Mannerriege.
        </p>
        <div v-reveal="160" class="mt-7 flex justify-center">
          <CtaButton to="/contato" variant="outline-light">Fale conosco</CtaButton>
        </div>
      </div>
    </section>
  </div>
</template>
