<script setup>
import { ref, defineAsyncComponent } from 'vue'
import { useAuth } from '../../lib/useAuth.js'

const FinanceiroDashboard = defineAsyncComponent(() => import('./FinanceiroDashboard.vue'))
const FinanceiroLancamentoRapido = defineAsyncComponent(() => import('./FinanceiroLancamentoRapido.vue'))
const FinanceiroMensalidades = defineAsyncComponent(() => import('./FinanceiroMensalidades.vue'))
const FinanceiroReceitasDespesas = defineAsyncComponent(() => import('./FinanceiroReceitasDespesas.vue'))
const FinanceiroEventos = defineAsyncComponent(() => import('./FinanceiroEventos.vue'))
const FinanceiroCadastros = defineAsyncComponent(() => import('./FinanceiroCadastros.vue'))

const props = defineProps({
  embedded: { type: Boolean, default: false },
})

const { profile: meuPerfil, logout } = useAuth()
const aba = ref('painel')

const titulos = {
  painel: 'Painel',
  lancamento: 'Lançamento Rápido',
  mensalidades: 'Mensalidades',
  receitasDespesas: 'Receitas e Despesas',
  eventos: 'Eventos',
  cadastros: 'Cadastros',
}
</script>

<template>
  <div>
    <div v-if="!embedded" class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <p class="font-mono-label text-[11px] font-bold text-[#27500A]">Tesouraria</p>
        <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">{{ titulos[aba] }}</h1>
      </div>
      <div class="flex items-center gap-3">
        <span class="text-xs text-ink-soft">Logado como {{ meuPerfil?.nome }}</span>
        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
      </div>
    </div>

    <div :class="embedded ? 'flex flex-wrap gap-2' : 'mt-6 flex flex-wrap gap-2'">
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'painel' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'painel'"
      >Painel</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'lancamento' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'lancamento'"
      >⚡ Lançamento Rápido</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'mensalidades' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'mensalidades'"
      >Mensalidades</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'receitasDespesas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'receitasDespesas'"
      >Receitas e Despesas</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'eventos' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'eventos'"
      >Eventos</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="aba === 'cadastros' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="aba = 'cadastros'"
      >Cadastros</button>
    </div>

    <div class="mt-8">
      <FinanceiroDashboard v-if="aba === 'painel'" />
      <FinanceiroLancamentoRapido v-else-if="aba === 'lancamento'" />
      <FinanceiroMensalidades v-else-if="aba === 'mensalidades'" />
      <FinanceiroReceitasDespesas v-else-if="aba === 'receitasDespesas'" />
      <FinanceiroEventos v-else-if="aba === 'eventos'" />
      <FinanceiroCadastros v-else />
    </div>
  </div>
</template>
