<script setup>
import PageHero from '../components/PageHero.vue'
import SectionTag from '../components/SectionTag.vue'
import CtaButton from '../components/CtaButton.vue'
import Icon from '../components/Icon.vue'

const cards = [
  { icon: 'shield', title: 'Tradição', text: 'Uma história construída por gerações apaixonadas pelo voleibol.' },
  { icon: 'volleyball', title: 'Formação', text: 'Treinamento, disciplina e desenvolvimento humano para jovens atletas.' },
  { icon: 'users', title: 'Comunidade', text: 'Esporte como ferramenta de convivência, inclusão e cidadania.' },
  { icon: 'heart', title: 'Futuro', text: 'O Mannerriege Vôlei de Base nasce para preparar novas gerações.' },
  { icon: 'doc', title: 'Transparência', text: 'Gestão responsável, organização documental e prestação de contas.' },
  { icon: 'handshake', title: 'Parcerias', text: 'Empresas e instituições podem fazer parte dessa transformação.' },
]
</script>

<template>
  <div>
    <PageHero
      eyebrow="Sobre a associação"
      title="Quem somos"
      subtitle="Uma entidade esportiva sem fins lucrativos que acredita no voleibol como instrumento de convivência, formação e transformação social."
    />

    <section class="bg-paper py-20">
      <div class="mx-auto grid max-w-6xl gap-12 px-5 sm:px-8 lg:grid-cols-[1.1fr_0.9fr]">
        <div v-reveal class="space-y-5 leading-relaxed text-ink-soft">
          <p class="text-lg text-ink">
            A Mannerriege Associação Desportiva de Voleibol é uma entidade esportiva sem fins
            lucrativos, formada por pessoas que acreditam no poder do voleibol como instrumento
            de convivência, formação e transformação social.
          </p>
          <p>
            Nossa história está ligada à tradição esportiva de Joinville e à paixão de seus
            associados pelo voleibol. Ao longo dos anos, o Mannerriege se consolidou como um
            espaço de prática esportiva, amizade, competição saudável e valorização da
            modalidade.
          </p>
          <p>
            Hoje, a Associação vive um novo momento institucional, com foco na organização
            administrativa, fortalecimento da governança, ampliação de parcerias e
            desenvolvimento do projeto Mannerriege Vôlei de Base, criado para levar o voleibol a
            novas gerações.
          </p>
          <p>
            Nosso compromisso é atuar com responsabilidade, transparência e seriedade,
            preservando a tradição do clube e preparando o futuro do voleibol em Joinville.
          </p>
        </div>

        <aside v-reveal="120" class="self-start rounded-2xl bg-ink p-8 text-white">
          <Icon name="volleyball" class="h-8 w-8 text-brand" />
          <p class="mt-5 font-display text-2xl font-semibold leading-snug">
            "O Mannerriege é uma associação esportiva dedicada ao voleibol, à formação humana e à
            promoção do esporte como ferramenta de desenvolvimento social."
          </p>
        </aside>
      </div>
    </section>

    <section class="bg-paper-dim py-20">
      <div class="mx-auto max-w-6xl px-5 sm:px-8">
        <div v-reveal class="max-w-xl">
          <SectionTag text="O que nos move" />
          <h2 class="mt-4 font-display text-4xl font-extrabold text-ink sm:text-5xl">
            Identidade em 6 palavras
          </h2>
        </div>

        <div class="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
          <div v-for="(c, i) in cards" :key="c.title" v-reveal="i * 70" class="rounded-2xl bg-white p-7 shadow-card">
            <div class="flex h-11 w-11 items-center justify-center rounded-xl bg-brand-soft text-brand-deep">
              <Icon :name="c.icon" class="h-5 w-5" />
            </div>
            <h3 class="mt-4 font-display text-xl font-bold text-ink">{{ c.title }}</h3>
            <p class="mt-2 text-sm leading-relaxed text-ink-soft">{{ c.text }}</p>
          </div>
        </div>
      </div>
    </section>

    <section class="bg-paper py-20">
      <div class="mx-auto flex max-w-6xl flex-col items-start gap-6 px-5 sm:px-8 sm:flex-row sm:items-center sm:justify-between">
        <h2 v-reveal class="font-display text-3xl font-extrabold text-ink sm:text-4xl">
          Quer conhecer nossa trajetória completa?
        </h2>
        <div v-reveal="100">
          <CtaButton to="/historia" variant="primary">Nossa história <Icon name="arrow-right" class="h-3.5 w-3.5" /></CtaButton>
        </div>
      </div>
    </section>
  </div>
</template>
