<script setup>
import { siteConfig, anosDeHistoria } from '../data/site.js'
import SectionTag from '../components/SectionTag.vue'
import StatBlock from '../components/StatBlock.vue'
import CtaButton from '../components/CtaButton.vue'
import Icon from '../components/Icon.vue'

import heroImg from '../assets/img/hero-time.jpg'
import convivioImg from '../assets/img/clube-convivio.jpg'
import conquistasImg from '../assets/img/conquistas-2024.jpg'

const valores = [
  'Tradição', 'Respeito', 'Disciplina', 'Compromisso', 'Espírito coletivo',
  'Transparência', 'Inclusão', 'Formação humana', 'Responsabilidade social', 'Amor pelo voleibol',
]

const frentes = [
  {
    icon: 'volleyball',
    title: 'Vôlei de Base',
    tag: 'Em breve',
    text: 'Levar a tradição do Mannerriege para uma nova geração de atletas e cidadãos.',
  },
  {
    icon: 'users',
    title: 'Voleibol Adulto e Master',
    tag: null,
    text: 'Seis categorias competitivas que mantêm viva a história e a amizade da Associação.',
  },
  {
    icon: 'calendar',
    title: 'Eventos, Festivais e Integração',
    tag: null,
    text: 'Encontros, festivais e ações comunitárias que aproximam atletas, famílias e parceiros.',
  },
  {
    icon: 'briefcase',
    title: 'Parcerias e Desenvolvimento',
    tag: null,
    text: 'Governança e captação de recursos para ampliar o impacto social do projeto.',
  },
]

const conquistas2024 = [
  'Campeão Geral — Campeonato Catarinense Master',
  'Vice-Campeão Brasileiro Santos 50+',
  'Vice-Campeão Superliga Master 50+ (Pró-Kombat RJ)',
  'Campeão Serra Master Lages 40+',
]
</script>

<template>
  <div>
    <!-- HERO -->
    <section class="relative flex min-h-[94vh] items-end overflow-hidden bg-ink">
      <img :src="heroImg" alt="Equipe Mannerriege reunida na quadra com a bandeira do clube" class="absolute inset-0 h-full w-full object-cover object-[50%_30%]" />
      <div class="absolute inset-0 bg-gradient-to-t from-ink via-ink/70 to-ink/10"></div>
      <div class="absolute inset-0 bg-gradient-to-r from-ink/60 via-transparent to-transparent"></div>

      <div class="relative z-10 mx-auto w-full max-w-7xl px-5 pb-16 pt-40 sm:px-8 sm:pb-20">
        <p class="font-mono-label text-[11px] font-bold text-brand">
          Associação Desportiva de Voleibol &middot; Joinville/SC &middot; desde {{ siteConfig.foundedYear }}
        </p>
        <h1 class="mt-5 font-display text-[15vw] font-extrabold uppercase leading-none text-white sm:text-7xl lg:text-8xl">
          Mannerriege
        </h1>
        <p class="mt-2 max-w-2xl font-display text-2xl font-semibold text-white/90 sm:text-3xl">
          Tradição joinvilense no voleibol nacional
        </p>
        <p class="mt-5 max-w-xl text-base leading-relaxed text-paper/75 sm:text-lg">
          Há décadas, o Mannerriege carrega a paixão pelo voleibol, a força da amizade e o
          compromisso com o esporte em Joinville.
        </p>

        <div class="mt-8 flex flex-wrap gap-4">
          <CtaButton to="/sobre" variant="primary">Conheça o projeto</CtaButton>
          <CtaButton to="/apoie" variant="outline-light">Quero apoiar</CtaButton>
        </div>
      </div>
    </section>

    <!-- SCOREBOARD STRIP -->
    <section class="bg-ink py-10">
      <div class="mx-auto grid max-w-7xl grid-cols-2 gap-8 px-5 sm:grid-cols-4 sm:px-8">
        <StatBlock :value="`${anosDeHistoria()}+`" label="Anos de história" light />
        <StatBlock :value="String(siteConfig.foundedYear)" label="Ano de fundação" light />
        <StatBlock value="6" label="Categorias: 35+ a 60+" light />
        <StatBlock :value="siteConfig.associados" label="Associados voluntários" light />
      </div>
    </section>

    <!-- MISSAO / VISAO / VALORES -->
    <section class="bg-paper py-24">
      <div class="mx-auto max-w-7xl px-5 sm:px-8">
        <div v-reveal class="max-w-2xl">
          <SectionTag text="Propósito" />
          <h2 class="mt-4 font-display text-4xl font-extrabold text-ink sm:text-5xl">
            Missão, visão e valores
          </h2>
        </div>

        <div class="mt-12 grid gap-6 sm:grid-cols-2">
          <div v-reveal class="rounded-2xl bg-white p-8 shadow-card">
            <Icon name="shield" class="h-8 w-8 text-brand" />
            <h3 class="mt-5 font-display text-2xl font-bold text-ink">Missão</h3>
            <p class="mt-3 leading-relaxed text-ink-soft">
              Oferecer lazer por meio do voleibol, promovendo disciplina, saúde, cidadania,
              convivência e oportunidades para a população de Joinville.
            </p>
          </div>
          <div v-reveal="120" class="rounded-2xl bg-white p-8 shadow-card">
            <Icon name="arrow-right" class="h-8 w-8 text-brand" />
            <h3 class="mt-5 font-display text-2xl font-bold text-ink">Visão</h3>
            <p class="mt-3 leading-relaxed text-ink-soft">
              Ser referência no voleibol master, reconhecida pela tradição, seriedade, excelência
              esportiva, impacto social e compromisso com o desenvolvimento humano.
            </p>
          </div>
        </div>

        <div v-reveal class="mt-10 flex flex-wrap gap-2.5">
          <span
            v-for="valor in valores"
            :key="valor"
            class="rounded-full border border-brand/25 bg-brand-soft px-4 py-2 font-mono-label text-[11px] font-bold text-brand-deep"
          >{{ valor }}</span>
        </div>
      </div>
    </section>

    <!-- QUEM SOMOS -->
    <section class="bg-paper-dim py-24">
      <div class="mx-auto grid max-w-7xl gap-12 px-5 sm:px-8 lg:grid-cols-2 lg:items-center">
        <div v-reveal>
          <SectionTag text="Quem somos" />
          <h2 class="mt-4 font-display text-4xl font-extrabold text-ink sm:text-5xl">
            Mais que um time,<br />uma confraria.
          </h2>
          <p class="mt-5 leading-relaxed text-ink-soft">
            O Mannerriege é uma associação esportiva dedicada ao voleibol, à formação humana e à
            promoção do esporte como ferramenta de desenvolvimento social. Nossa atuação une
            tradição, voluntariado, gestão e compromisso com a comunidade.
          </p>
          <p class="mt-4 leading-relaxed text-ink-soft">
            Hoje a Associação vive um novo momento institucional, com foco em governança,
            parcerias e no desenvolvimento do projeto Mannerriege Vôlei de Base — criado para
            levar o voleibol a novas gerações.
          </p>
          <div class="mt-7">
            <CtaButton to="/historia" variant="outline-dark">Conheça nossa história</CtaButton>
          </div>
        </div>

        <div v-reveal="150" class="relative">
          <img :src="convivioImg" alt="Associados do Mannerriege reunidos na sede do clube" class="w-full rounded-2xl object-cover shadow-lift" />
          <div class="absolute -bottom-6 -left-6 hidden rounded-2xl bg-white px-6 py-5 shadow-lift sm:block">
            <p class="font-display text-3xl font-extrabold text-brand">{{ siteConfig.associados }}</p>
            <p class="font-mono-label text-[10px] font-bold text-ink-soft">Associados voluntários</p>
          </div>
        </div>
      </div>
    </section>

    <!-- VOLEI DE BASE — EM BREVE -->
    <section class="relative overflow-hidden bg-ink py-24">
      <div class="hatch-mark pointer-events-none absolute -right-16 -top-16 h-64 w-64 rotate-12 text-brand/60"></div>
      <div class="relative mx-auto max-w-4xl px-5 text-center sm:px-8">
        <span v-reveal class="inline-flex items-center gap-2 rounded-full bg-gold-soft px-4 py-1.5 font-mono-label text-[11px] font-bold text-gold">
          <Icon name="heart" class="h-3.5 w-3.5" /> Em breve
        </span>
        <h2 v-reveal="80" class="mt-6 font-display text-4xl font-extrabold uppercase text-white sm:text-5xl">
          Mannerriege Vôlei de Base
        </h2>
        <p v-reveal="140" class="mt-2 font-display text-xl font-semibold text-brand sm:text-2xl">
          Formando atletas e cidadãos por meio do voleibol.
        </p>
        <p v-reveal="200" class="mx-auto mt-5 max-w-xl leading-relaxed text-paper/70">
          Nossa história nos trouxe até aqui. Agora, transformamos décadas de experiência dentro
          das quadras em oportunidade para crianças, adolescentes e jovens de Joinville.
        </p>
        <div v-reveal="260" class="mt-8 flex justify-center">
          <CtaButton to="/apoie" variant="primary">Ajude a tirar do papel</CtaButton>
        </div>
      </div>
    </section>

    <!-- FRENTES DE ATUACAO -->
    <section class="bg-paper py-24">
      <div class="mx-auto max-w-7xl px-5 sm:px-8">
        <div v-reveal class="flex flex-wrap items-end justify-between gap-6">
          <div class="max-w-xl">
            <SectionTag text="Frentes de atuação" />
            <h2 class="mt-4 font-display text-4xl font-extrabold text-ink sm:text-5xl">
              Onde a Mannerriege atua
            </h2>
          </div>
          <CtaButton to="/projetos" variant="ghost">
            Ver todos os projetos <Icon name="arrow-right" class="h-3.5 w-3.5" />
          </CtaButton>
        </div>

        <div class="mt-12 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          <div
            v-for="(f, i) in frentes"
            :key="f.title"
            v-reveal="i * 90"
            class="group rounded-2xl border border-ink/8 bg-white p-7 transition-shadow hover:shadow-lift"
          >
            <div class="flex h-11 w-11 items-center justify-center rounded-xl bg-brand-soft text-brand-deep">
              <Icon :name="f.icon" class="h-5 w-5" />
            </div>
            <span v-if="f.tag" class="mt-4 inline-block rounded-full bg-gold-soft px-2.5 py-1 font-mono-label text-[10px] font-bold text-gold">{{ f.tag }}</span>
            <h3 class="mt-4 font-display text-xl font-bold text-ink">{{ f.title }}</h3>
            <p class="mt-2 text-sm leading-relaxed text-ink-soft">{{ f.text }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- CONQUISTAS -->
    <section class="bg-paper-dim py-24">
      <div class="mx-auto grid max-w-7xl gap-12 px-5 sm:px-8 lg:grid-cols-2 lg:items-center">
        <div v-reveal class="order-2 lg:order-1">
          <img :src="conquistasImg" alt="Atletas do Mannerriege com troféus do Campeonato Catarinense Master 2024" class="w-full rounded-2xl object-cover shadow-lift" />
        </div>
        <div v-reveal="120" class="order-1 lg:order-2">
          <SectionTag text="História gloriosa" />
          <h2 class="mt-4 font-display text-4xl font-extrabold text-ink sm:text-5xl">
            Conquistas 2024
          </h2>
          <p class="mt-4 leading-relaxed text-ink-soft">
            Pela primeira vez conquistamos o lugar mais alto do pódium Catarinense Master Geral —
            com recursos financeiros internos dos associados.
          </p>
          <ul class="mt-6 space-y-3">
            <li v-for="item in conquistas2024" :key="item" class="flex items-start gap-3 text-sm text-ink">
              <Icon name="trophy" class="mt-0.5 h-4 w-4 flex-shrink-0 text-gold" />
              {{ item }}
            </li>
          </ul>
          <div class="mt-7">
            <CtaButton to="/historia" variant="outline-dark">Ver história completa</CtaButton>
          </div>
        </div>
      </div>
    </section>

    <!-- APOIE CTA -->
    <section class="bg-brand py-20">
      <div class="mx-auto flex max-w-7xl flex-col items-start justify-between gap-8 px-5 sm:px-8 lg:flex-row lg:items-center">
        <div v-reveal class="max-w-xl">
          <h2 class="font-display text-3xl font-extrabold uppercase text-white sm:text-4xl">
            Sua empresa pode ajudar a formar o futuro
          </h2>
          <p class="mt-3 leading-relaxed text-white/85">
            Ao apoiar o Mannerriege, você contribui diretamente para o desenvolvimento de jovens
            atletas e para o fortalecimento do esporte em Joinville.
          </p>
        </div>
        <div v-reveal="120" class="flex flex-shrink-0 gap-4">
          <CtaButton to="/apoie" variant="outline-light">Ver cotas de patrocínio</CtaButton>
          <CtaButton to="/contato" variant="outline-light">Fale conosco</CtaButton>
        </div>
      </div>
    </section>
  </div>
</template>
