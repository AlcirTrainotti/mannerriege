<script setup>
import { ref } from 'vue'
import { useAuth } from '../../lib/useAuth.js'
import AdminConvidados from './AdminConvidados.vue'
import AdminInventario from './AdminInventario.vue'
import AdminCampeonatos from './AdminCampeonatos.vue'

const props = defineProps({
  // Quando embedded=true, nao mostra o cabecalho proprio (titulo + sair),
  // pois ja esta dentro do AdminPanel, que tem seu proprio cabecalho.
  embedded: { type: Boolean, default: false },
})

const { profile: meuPerfil, logout } = useAuth()
const aba = ref('convidados')
</script>

<template>
  <div>
    <div v-if="!embedded" class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <p class="font-mono-label text-[11px] font-bold text-brand-deep">Coordenação esportiva</p>
        <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">
          {{ aba === 'convidados' ? 'Convidados' : aba === 'inventario' ? 'Inventário' : 'Campeonatos' }}
        </h1>
      </div>
      <div class="flex items-center gap-3">
        <span class="text-xs text-ink-soft">Logado como {{ meuPerfil?.nome }}</span>
        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
      </div>
    </div>

    <div :class="embedded ? 'flex gap-2' : 'mt-6 flex gap-2'">
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'convidados' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'convidados'"
      >Convidados</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'inventario' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'inventario'"
      >Inventário</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'campeonatos' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'campeonatos'"
      >Campeonatos</button>
    </div>

    <div class="mt-8">
      <AdminConvidados v-if="aba === 'convidados'" />

      <AdminInventario v-else-if="aba === 'inventario'" />

      <AdminCampeonatos v-else />
    </div>
  </div>
</template>
