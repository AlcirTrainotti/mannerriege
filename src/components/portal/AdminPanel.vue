<script setup>
import { ref, defineAsyncComponent } from 'vue'
import { useAuth } from '../../lib/useAuth.js'

// Carregamento sob demanda: cada aba só baixa seu código quando é
// realmente aberta, em vez de tudo junto na primeira tela do portal.
const AdminAssociados = defineAsyncComponent(() => import('./AdminAssociados.vue'))
const AdminAvisos = defineAsyncComponent(() => import('./AdminAvisos.vue'))
const AdminAtas = defineAsyncComponent(() => import('./AdminAtas.vue'))
const EsportivoPanel = defineAsyncComponent(() => import('./EsportivoPanel.vue'))
const FinanceiroPanel = defineAsyncComponent(() => import('./FinanceiroPanel.vue'))

const { profile: meuPerfil, logout } = useAuth()
const aba = ref('associados')

const titulos = {
  associados: 'Associados',
  avisos: 'Avisos',
  atas: 'Atas',
  esportivo: 'Esportivo',
  financeiro: 'Financeiro',
}
</script>

<template>
  <div>
    <div class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <p class="font-mono-label text-[11px] font-bold text-brand-deep">Diretoria</p>
        <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">{{ titulos[aba] }}</h1>
      </div>
      <div class="flex items-center gap-3">
        <span class="text-xs text-ink-soft">Logado como {{ meuPerfil?.nome }}</span>
        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
      </div>
    </div>

    <div class="mt-6 flex flex-wrap gap-2">
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
      <span class="mx-1 hidden w-px self-stretch bg-ink/10 sm:block"></span>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'esportivo' ? 'bg-brand text-white' : 'bg-gold-soft text-ink hover:bg-gold-soft/70'"
        @click="aba = 'esportivo'"
      >🏐 Esportivo</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'financeiro' ? 'bg-[#27500A] text-white' : 'bg-[#EAF3DE] text-[#27500A] hover:bg-[#EAF3DE]/70'"
        @click="aba = 'financeiro'"
      >💰 Financeiro</button>
    </div>

    <div class="mt-8">
      <AdminAssociados v-if="aba === 'associados'" />
      <AdminAvisos v-else-if="aba === 'avisos'" />
      <AdminAtas v-else-if="aba === 'atas'" />
      <EsportivoPanel v-else-if="aba === 'esportivo'" :embedded="true" />
      <FinanceiroPanel v-else :embedded="true" />
    </div>
  </div>
</template>
