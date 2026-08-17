<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'
import { idadeAtual, nomeCategoria, statusAtletaLabel, statusAtletaClasses } from '../../data/base.js'

// Fase 1: lista de atletas por categoria, pra o professor já conhecer
// o grupo antes do calendário de treinos e avaliações chegarem
// (Fase 2/3 do módulo).

const { profile, logout } = useAuth()

const carregando = ref(true)
const atletas = ref([])
const categorias = ref([])
const categoriaFiltro = ref('todas')

async function carregar() {
  carregando.value = true
  const [{ data: atletasData }, { data: categoriasData }] = await Promise.all([
    supabase.from('atletas_base').select('*').order('nome'),
    supabase.from('categorias_base').select('*').eq('ativo', true).order('nome'),
  ])
  atletas.value = atletasData ?? []
  categorias.value = categoriasData ?? []
  carregando.value = false
}

const atletasFiltrados = computed(() => {
  if (categoriaFiltro.value === 'todas') return atletas.value
  return atletas.value.filter((a) => a.categoria_id === categoriaFiltro.value)
})

function categoriaDoAtleta(atleta) {
  return categorias.value.find((c) => c.id === atleta.categoria_id)
}

onMounted(carregar)
</script>

<template>
  <div>
    <div class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <p class="font-mono-label text-[11px] font-bold text-brand-deep">Professor · Categorias de Base</p>
        <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Meus atletas</h1>
      </div>
      <div class="flex items-center gap-3">
        <span class="text-xs text-ink-soft">Logado como {{ profile?.nome }}</span>
        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
      </div>
    </div>

    <div class="mt-6 flex flex-wrap gap-2">
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="categoriaFiltro === 'todas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="categoriaFiltro = 'todas'"
      >Todas</button>
      <button
        v-for="c in categorias"
        :key="c.id"
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="categoriaFiltro === c.id ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="categoriaFiltro = c.id"
      >{{ nomeCategoria(c) }}</button>
    </div>

    <p v-if="carregando" class="mt-8 text-sm text-ink-soft">Carregando...</p>

    <div v-else-if="atletasFiltrados.length === 0" class="mt-8 rounded-2xl border border-dashed border-ink/15 p-8 text-center">
      <Icon name="users" class="mx-auto h-6 w-6 text-ink-soft/50" />
      <p class="mt-2 text-sm text-ink-soft">Nenhum atleta cadastrado nessa categoria ainda.</p>
    </div>

    <div v-else class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
      <div v-for="a in atletasFiltrados" :key="a.id" class="flex items-center justify-between gap-3 px-5 py-3.5">
        <div>
          <p class="text-sm font-semibold text-ink">{{ a.nome }}</p>
          <p class="text-xs text-ink-soft">{{ nomeCategoria(categoriaDoAtleta(a)) }} · {{ idadeAtual(a.data_nascimento) }} anos</p>
        </div>
        <span :class="['rounded-full px-3 py-1 text-xs font-semibold', statusAtletaClasses(a.status)]">{{ statusAtletaLabel(a.status) }}</span>
      </div>
    </div>

    <div class="mt-6 rounded-2xl border border-dashed border-ink/15 p-6 text-center">
      <Icon name="calendar" class="mx-auto h-6 w-6 text-ink-soft/50" />
      <p class="mt-2 text-sm text-ink-soft">Calendário de treinos, chamada e avaliação por valência chegam na Fase 2/3 do módulo.</p>
    </div>
  </div>
</template>
