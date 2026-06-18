<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import logo from '../assets/img/logo.png'
import Icon from './Icon.vue'

const route = useRoute()
const scrolled = ref(false)
const menuOpen = ref(false)

const links = [
  { to: '/', label: 'Início' },
  { to: '/sobre', label: 'Sobre' },
  { to: '/historia', label: 'História' },
  { to: '/projetos', label: 'Projetos' },
  { to: '/diretoria', label: 'Diretoria' },
  { to: '/transparencia', label: 'Transparência' },
  { to: '/contato', label: 'Contato' },
]

function onScroll() {
  scrolled.value = window.scrollY > 32
}

onMounted(() => {
  onScroll()
  window.addEventListener('scroll', onScroll, { passive: true })
})
onUnmounted(() => window.removeEventListener('scroll', onScroll))

watch(() => route.fullPath, () => {
  menuOpen.value = false
})

// Transparente apenas na Home, no topo da pagina (sobre a foto do time)
const transparent = computed(() => route.name === 'home' && !scrolled.value && !menuOpen.value)
</script>

<template>
  <header
    class="fixed inset-x-0 top-0 z-50 transition-colors duration-300"
    :class="transparent ? 'bg-transparent' : 'bg-paper/95 backdrop-blur-md shadow-[0_1px_0_rgba(24,19,15,0.08)]'"
  >
    <div class="mx-auto flex max-w-7xl items-center justify-between px-5 py-3 sm:px-8">
      <router-link to="/" class="flex items-center gap-3" @click="menuOpen = false">
        <img :src="logo" alt="Escudo Mannerriege" class="h-11 w-auto drop-shadow-sm" />
        <span
          class="font-display text-xl font-extrabold leading-none tracking-tight sm:text-2xl"
          :class="transparent ? 'text-white' : 'text-ink'"
        >MANNERRIEGE</span>
      </router-link>

      <nav class="hidden items-center gap-7 lg:flex">
        <router-link
          v-for="link in links"
          :key="link.to"
          :to="link.to"
          class="font-mono-label text-[11px] font-bold transition-opacity hover:opacity-70"
          :class="transparent ? 'text-white' : 'text-ink'"
          active-class="!opacity-100 underline underline-offset-[10px] decoration-2 decoration-brand"
        >{{ link.label }}</router-link>

        <router-link
          to="/apoie"
          class="rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white shadow-card transition-transform hover:-translate-y-0.5 hover:bg-brand-deep"
        >Apoie o projeto</router-link>

        <router-link
          to="/portal"
          title="Área do Associado"
          class="flex h-9 w-9 items-center justify-center rounded-full border transition-colors"
          :class="transparent ? 'border-white/40 text-white hover:bg-white/10' : 'border-ink/15 text-ink hover:bg-ink/5'"
        >
          <Icon name="lock" class="h-4 w-4" />
        </router-link>
      </nav>

      <button
        class="flex h-10 w-10 items-center justify-center rounded-full lg:hidden"
        :class="transparent ? 'text-white' : 'text-ink'"
        aria-label="Abrir menu"
        @click="menuOpen = !menuOpen"
      >
        <svg v-if="!menuOpen" width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M3 6h18M3 12h18M3 18h18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
        <svg v-else width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M5 5l14 14M19 5L5 19" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
      </button>
    </div>

    <transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0 -translate-y-2"
      enter-to-class="opacity-100 translate-y-0"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <nav v-if="menuOpen" class="border-t border-ink/10 bg-paper px-5 py-4 lg:hidden">
        <router-link
          v-for="link in links"
          :key="link.to"
          :to="link.to"
          class="block border-b border-ink/8 py-3 font-display text-2xl font-bold text-ink"
        >{{ link.label }}</router-link>
        <router-link
          to="/apoie"
          class="mt-4 block rounded-full bg-brand px-5 py-3 text-center font-mono-label text-[11px] font-bold text-white"
        >Apoie o projeto</router-link>
        <router-link
          to="/portal"
          class="mt-3 flex items-center justify-center gap-2 text-sm font-semibold text-ink-soft"
        >
          <Icon name="lock" class="h-4 w-4" /> Área do Associado
        </router-link>
      </nav>
    </transition>
  </header>
</template>
