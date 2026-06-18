<script setup>
import { ref } from 'vue'
import { useAuth } from '../../lib/useAuth.js'
import AdminAssociados from './AdminAssociados.vue'
import AdminAvisos from './AdminAvisos.vue'
import AdminAtas from './AdminAtas.vue'

const { profile: meuPerfil, logout } = useAuth()
const aba = ref('associados')
</script>

<template>
  <div>
    <div class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <p class="font-mono-label text-[11px] font-bold text-brand-deep">Diretoria</p>
        <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">
          {{ aba === 'associados' ? 'Associados' : aba === 'avisos' ? 'Avisos' : 'Atas' }}
        </h1>
      </div>
      <div class="flex items-center gap-3">
        <span class="text-xs text-ink-soft">Logado como {{ meuPerfil?.nome }}</span>
        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
      </div>
    </div>

    <div class="mt-6 flex gap-2">
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'associados' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'associados'"
      >Associados</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'avisos' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'avisos'"
      >Avisos</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'atas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'atas'"
      >Atas</button>
    </div>

    <div class="mt-8">
      <AdminAssociados v-if="aba === 'associados'" />
      <AdminAvisos v-else-if="aba === 'avisos'" />
      <AdminAtas v-else />
    </div>
  </div>
</template>
