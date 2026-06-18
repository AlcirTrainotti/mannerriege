<script setup>
import { anosDeHistoria, siteConfig } from '../data/site.js'
import PageHero from '../components/PageHero.vue'
import SectionTag from '../components/SectionTag.vue'
import CtaButton from '../components/CtaButton.vue'
import Icon from '../components/Icon.vue'
import historiaImg from '../assets/img/historia-50anos.jpg'
import conquistasImg from '../assets/img/conquistas-2024.jpg'

const conquistas = [
  'Campeão Geral — Campeonato Catarinense Master',
  'Campeão Catarinense Master 35+',
  'Vice-Campeão Catarinense Master 40+',
  '5º lugar Catarinense Master 45+',
  'Vice-Campeão Catarinense Master 50+',
  'Vice-Campeão Catarinense Master 55+',
  'Vice-Campeão Brasileiro Santos 50+',
  'Vice-Campeão Superliga Master 50+ (parceria Pró-Kombat RJ)',
  'Atletas campeões Superliga Master 40+ (parceria Corinthians SP)',
  'Campeão Serra Master Lages 40+',
  'Campeão Copa AABB Joinville 40+',
  '6º lugar da Superliga Master 55+',
]
</script>

<template>
  <div>
    <PageHero
      :eyebrow="`Desde ${siteConfig.foundedYear}`"
      title="Nossa História"
      subtitle="Uma tradição do voleibol joinvilense, construída por gerações de atletas, associados e famílias."
    />

    <section class="bg-paper py-20">
      <div class="mx-auto grid max-w-6xl gap-12 px-5 sm:px-8 lg:grid-cols-2 lg:items-center">
        <div v-reveal class="order-2 lg:order-1">
          <img :src="historiaImg" alt="Equipe Mannerriege em foto histórica de comemoração de 50 anos" class="w-full rounded-2xl object-cover shadow-lift" />
          <p class="mt-3 text-center text-xs text-ink-soft/70">Celebração dos 50 anos da Associação</p>
        </div>
        <div v-reveal="120" class="order-1 space-y-5 leading-relaxed text-ink-soft lg:order-2">
          <SectionTag text="Tradição joinvilense" />
          <p class="text-lg text-ink">
            O Mannerriege carrega uma trajetória construída por atletas, associados, famílias e
            apaixonados pelo voleibol. Mais do que uma equipe, a Associação representa uma cultura
            esportiva baseada em amizade, disciplina, dedicação e respeito à história da
            modalidade em Joinville.
          </p>
          <p>
            Ao longo de sua caminhada, o Mannerriege reuniu gerações em torno do voleibol,
            participando de competições, encontros esportivos e iniciativas que mantêm viva a
            prática da modalidade.
          </p>
          <p>
            Essa tradição agora se conecta a uma nova fase: transformar a experiência acumulada
            dentro das quadras em oportunidade para jovens atletas. O projeto Mannerriege Vôlei de
            Base nasce justamente desse encontro entre passado, presente e futuro.
          </p>
        </div>
      </div>
    </section>

    <section class="bg-ink py-20">
      <div class="mx-auto max-w-4xl px-5 text-center sm:px-8">
        <p v-reveal class="font-display text-3xl font-bold leading-snug text-white sm:text-4xl">
          “Nossa história nos trouxe até aqui.<br />Nosso compromisso com a base vai nos levar adiante.”
        </p>
      </div>
    </section>

    <section class="bg-paper py-20">
      <div class="mx-auto max-w-4xl px-5 text-center sm:px-8">
        <SectionTag text="Amizade, saúde e lazer" />
        <p v-reveal class="mt-5 text-lg leading-relaxed text-ink-soft">
          Há {{ anosDeHistoria() }} anos unimos gerações para a prática do voleibol e do dominó em
          prol da amizade, saúde e lazer para ex-atletas. Contamos com mais de
          {{ siteConfig.associados }} associados que voluntariamente constroem essa história, com
          muita dedicação e recursos próprios, distribuídos nas categorias
          {{ siteConfig.categorias.join(', ') }}.
        </p>
      </div>
    </section>

    <section class="bg-paper-dim py-20">
      <div class="mx-auto grid max-w-6xl gap-12 px-5 sm:px-8 lg:grid-cols-2 lg:items-start">
        <div v-reveal>
          <img :src="conquistasImg" alt="Atletas do Mannerriege com troféus do Campeonato Catarinense Master 2024" class="w-full rounded-2xl object-cover shadow-lift" />
        </div>
        <div v-reveal="120">
          <SectionTag text="Temporada 2024" />
          <h2 class="mt-4 font-display text-4xl font-extrabold text-ink sm:text-5xl">
            Conquistas
          </h2>
          <p class="mt-4 leading-relaxed text-ink-soft">
            Pela primeira vez conquistamos o lugar mais alto do pódium Catarinense Master Geral, e
            nos posicionamos no cenário nacional — apenas com recursos financeiros internos dos
            associados.
          </p>
          <ul class="mt-6 grid gap-3 sm:grid-cols-2">
            <li
              v-for="item in conquistas"
              :key="item"
              class="flex items-start gap-2.5 rounded-xl bg-white px-4 py-3 text-sm leading-snug text-ink shadow-card"
            >
              <Icon name="trophy" class="mt-0.5 h-4 w-4 flex-shrink-0 text-gold" />
              {{ item }}
            </li>
          </ul>
        </div>
      </div>
    </section>

    <section class="bg-paper py-20">
      <div class="mx-auto flex max-w-6xl flex-col items-start gap-6 px-5 sm:px-8 sm:flex-row sm:items-center sm:justify-between">
        <h2 v-reveal class="font-display text-3xl font-extrabold text-ink sm:text-4xl">
          Conheça o projeto que vai escrever o próximo capítulo
        </h2>
        <div v-reveal="100">
          <CtaButton to="/projetos" variant="primary">Ver projetos <Icon name="arrow-right" class="h-3.5 w-3.5" /></CtaButton>
        </div>
      </div>
    </section>
  </div>
</template>
