<script setup>
import PageHero from '../components/PageHero.vue'
import SectionTag from '../components/SectionTag.vue'
import CtaButton from '../components/CtaButton.vue'
import Icon from '../components/Icon.vue'
import timeImg from '../assets/img/projeto-2025-time.jpg'

const objetivos2025 = [
  { icon: 'volleyball', title: 'Preparação', text: 'Preparar as seis categorias para competir durante o ano no mais alto nível.' },
  { icon: 'users', title: 'Competição', text: 'Manter o título geral Catarinense Master com 6 categorias e disputar competições nacionais.' },
  { icon: 'megaphone', title: 'Divulgação', text: 'Ampliar os canais de divulgação nas redes sociais e na mídia local, regional e nacional.' },
]

const recursos = [
  '14 bolas Mikasa',
  '1 rede oficial',
  'Locação de 3h mensais de quadra',
  '1 jogo de uniforme por equipe',
  'Água para hidratação dos atletas',
  'Inscrição nos campeonatos',
]
</script>

<template>
  <div>
    <PageHero
      eyebrow="Frentes de atuação"
      title="Projetos"
      subtitle="O Mannerriege atua para fortalecer o voleibol em diferentes dimensões: formação esportiva, convivência, competição, inclusão e desenvolvimento institucional."
    />

    <!-- VOLEI DE BASE - flagship -->
    <section class="bg-paper py-20">
      <div class="mx-auto max-w-6xl px-5 sm:px-8">
        <div v-reveal class="overflow-hidden rounded-3xl bg-ink p-10 sm:p-14">
          <span class="inline-flex items-center gap-2 rounded-full bg-gold-soft px-4 py-1.5 font-mono-label text-[11px] font-bold text-gold">
            <Icon name="heart" class="h-3.5 w-3.5" /> Em breve
          </span>
          <h2 class="mt-6 font-display text-4xl font-extrabold uppercase text-white sm:text-5xl">
            Mannerriege Vôlei de Base
          </h2>
          <p class="mt-2 font-display text-xl font-semibold text-brand sm:text-2xl">
            Projeto social de formação — formando atletas e cidadãos por meio do voleibol.
          </p>
          <p class="mt-5 max-w-2xl leading-relaxed text-paper/70">
            Nossa história nos trouxe até aqui. Agora, queremos transformar décadas de experiência
            dentro das quadras em oportunidade real para crianças, adolescentes e jovens de
            Joinville. Os detalhes do programa serão anunciados em breve — e parceiros que se
            engajarem agora ajudam a moldar esse próximo capítulo desde o início.
          </p>
          <div class="mt-7">
            <CtaButton to="/apoie" variant="primary">Quero apoiar essa fase</CtaButton>
          </div>
        </div>
      </div>
    </section>

    <!-- DEMAIS PROJETOS -->
    <section class="bg-paper-dim py-20">
      <div class="mx-auto max-w-6xl px-5 sm:px-8">
        <div v-reveal class="grid gap-6 lg:grid-cols-3">
          <article class="rounded-2xl bg-white p-8 shadow-card">
            <div class="flex h-11 w-11 items-center justify-center rounded-xl bg-brand-soft text-brand-deep">
              <Icon name="users" class="h-5 w-5" />
            </div>
            <h3 class="mt-5 font-display text-xl font-bold text-ink">Voleibol Adulto e Master</h3>
            <p class="mt-3 text-sm leading-relaxed text-ink-soft">
              O Mannerriege mantém viva sua tradição por meio do voleibol adulto e master,
              reunindo atletas que representam a história, a amizade e a competitividade saudável
              da Associação. Essa frente fortalece o vínculo entre gerações e mantém ativa a
              cultura esportiva que inspira os projetos de formação.
            </p>
          </article>

          <article class="rounded-2xl bg-white p-8 shadow-card">
            <div class="flex h-11 w-11 items-center justify-center rounded-xl bg-brand-soft text-brand-deep">
              <Icon name="calendar" class="h-5 w-5" />
            </div>
            <h3 class="mt-5 font-display text-xl font-bold text-ink">Eventos, Festivais e Integração</h3>
            <p class="mt-3 text-sm leading-relaxed text-ink-soft">
              A Associação pretende promover eventos esportivos, festivais, encontros de famílias,
              ações comunitárias e atividades de integração. Essas iniciativas aproximam atletas,
              associados, familiares, parceiros e comunidade, fortalecendo o senso de
              pertencimento e a sustentabilidade do projeto.
            </p>
          </article>

          <article class="rounded-2xl bg-white p-8 shadow-card">
            <div class="flex h-11 w-11 items-center justify-center rounded-xl bg-brand-soft text-brand-deep">
              <Icon name="briefcase" class="h-5 w-5" />
            </div>
            <h3 class="mt-5 font-display text-xl font-bold text-ink">Parcerias e Desenvolvimento</h3>
            <p class="mt-3 text-sm leading-relaxed text-ink-soft">
              Para ampliar seu impacto, o Mannerriege busca parcerias com empresas, órgãos
              públicos, instituições de ensino, entidades esportivas e apoiadores da comunidade,
              fortalecendo sua governança e sua capacidade de captar recursos públicos e privados.
            </p>
          </article>
        </div>
      </div>
    </section>

    <!-- PROJETO 2025 - objetivos -->
    <section class="bg-paper py-20">
      <div class="mx-auto max-w-6xl px-5 sm:px-8">
        <div class="grid gap-12 lg:grid-cols-2 lg:items-center">
          <div v-reveal>
            <img :src="timeImg" alt="Equipe Mannerriege reunida na quadra de treino para o Projeto 2025" class="w-full rounded-2xl object-cover shadow-lift" />
          </div>
          <div v-reveal="120">
            <SectionTag text="Projeto 2025" />
            <h2 class="mt-4 font-display text-4xl font-extrabold text-ink sm:text-5xl">
              Venha conosco
            </h2>
            <p class="mt-4 leading-relaxed text-ink-soft">
              Buscaremos unir as gerações novamente em prol da saúde, bem-estar e amizade, usando
              o voleibol master como elo de conexão — preparando as seis categorias para competir
              no mais alto nível durante o ano.
            </p>
          </div>
        </div>

        <div class="mt-16 grid gap-5 sm:grid-cols-3">
          <div v-for="(o, i) in objetivos2025" :key="o.title" v-reveal="i * 90" class="rounded-2xl border border-ink/8 bg-white p-7">
            <div class="flex h-11 w-11 items-center justify-center rounded-xl bg-brand-soft text-brand-deep">
              <Icon :name="o.icon" class="h-5 w-5" />
            </div>
            <h3 class="mt-4 font-display text-xl font-bold text-ink">{{ o.title }}</h3>
            <p class="mt-2 text-sm leading-relaxed text-ink-soft">{{ o.text }}</p>
          </div>
        </div>

        <div v-reveal class="mt-10 rounded-2xl bg-paper-dim p-8">
          <p class="font-mono-label text-[11px] font-bold text-brand-deep">Onde o investimento se transforma</p>
          <h3 class="mt-2 font-display text-2xl font-bold text-ink">O que a temporada exige</h3>
          <ul class="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <li v-for="r in recursos" :key="r" class="flex items-start gap-2.5 text-sm text-ink">
              <Icon name="check" class="mt-0.5 h-4 w-4 flex-shrink-0 text-brand" />
              {{ r }}
            </li>
          </ul>
        </div>
      </div>
    </section>

    <section class="bg-brand py-16">
      <div class="mx-auto flex max-w-6xl flex-col items-start gap-6 px-5 sm:px-8 sm:flex-row sm:items-center sm:justify-between">
        <h2 v-reveal class="font-display text-3xl font-extrabold uppercase text-white sm:text-4xl">
          Ajude a colocar esses projetos em quadra
        </h2>
        <div v-reveal="100">
          <CtaButton to="/apoie" variant="outline-light">Ver cotas de patrocínio</CtaButton>
        </div>
      </div>
    </section>
  </div>
</template>
