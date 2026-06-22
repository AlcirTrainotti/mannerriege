<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { brl } from '../../data/campeonatos.js'
import { tipoReceitaOptions, tipoReceitaLabel, categoriaDespesaOptions, categoriaDespesaLabel } from '../../data/financeiro.js'
import CurrencyInput from './CurrencyInput.vue'

const receitas = ref([])
const despesas = ref([])
const loading = ref(true)

async function carregar() {
  loading.value = true
  const [recRes, despRes] = await Promise.all([
    supabase.from('financeiro_receitas').select('*').order('data', { ascending: false }),
    supabase.from('financeiro_despesas').select('*').order('data', { ascending: false }),
  ])
  receitas.value = recRes.data ?? []
  despesas.value = despRes.data ?? []
  loading.value = false
}

onMounted(carregar)

const totalReceitas = computed(() => receitas.value.reduce((s, r) => s + Number(r.valor || 0), 0))
const totalDespesas = computed(() => despesas.value.reduce((s, d) => s + Number(d.valor || 0), 0))

function formatarData(d) {
  if (!d) return '—'
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR')
}

// --- Nova receita ---
const showReceitaModal = ref(false)
const novaReceitaDescricao = ref('')
const novaReceitaValor = ref(0)
const novaReceitaTipo = ref('doacao')
const novaReceitaOrigem = ref('')
const novaReceitaData = ref(new Date().toISOString().slice(0, 10))
const salvandoReceita = ref(false)

function limparFormReceita() {
  novaReceitaDescricao.value = ''
  novaReceitaValor.value = 0
  novaReceitaTipo.value = 'doacao'
  novaReceitaOrigem.value = ''
  novaReceitaData.value = new Date().toISOString().slice(0, 10)
}

async function adicionarReceita() {
  if (!novaReceitaDescricao.value.trim()) return
  salvandoReceita.value = true
  await supabase.from('financeiro_receitas').insert({
    descricao: novaReceitaDescricao.value.trim(),
    valor: novaReceitaValor.value || 0,
    tipo: novaReceitaTipo.value,
    origem_nome: novaReceitaOrigem.value.trim() || null,
    data: novaReceitaData.value,
  })
  salvandoReceita.value = false
  showReceitaModal.value = false
  limparFormReceita()
  await carregar()
}

async function removerReceita(id) {
  if (!confirm('Remover esta receita?')) return
  await supabase.from('financeiro_receitas').delete().eq('id', id)
  receitas.value = receitas.value.filter((r) => r.id !== id)
}

// --- Nova despesa ---
const showDespesaModal = ref(false)
const novaDespesaDescricao = ref('')
const novaDespesaValor = ref(0)
const novaDespesaCategoria = ref('manutencao')
const novaDespesaData = ref(new Date().toISOString().slice(0, 10))
const salvandoDespesa = ref(false)

function limparFormDespesa() {
  novaDespesaDescricao.value = ''
  novaDespesaValor.value = 0
  novaDespesaCategoria.value = 'manutencao'
  novaDespesaData.value = new Date().toISOString().slice(0, 10)
}

async function adicionarDespesa() {
  if (!novaDespesaDescricao.value.trim()) return
  salvandoDespesa.value = true
  await supabase.from('financeiro_despesas').insert({
    descricao: novaDespesaDescricao.value.trim(),
    valor: novaDespesaValor.value || 0,
    categoria: novaDespesaCategoria.value,
    data: novaDespesaData.value,
  })
  salvandoDespesa.value = false
  showDespesaModal.value = false
  limparFormDespesa()
  await carregar()
}

async function removerDespesa(id) {
  if (!confirm('Remover esta despesa?')) return
  await supabase.from('financeiro_despesas').delete().eq('id', id)
  despesas.value = despesas.value.filter((d) => d.id !== id)
}
</script>

<template>
  <div>
    <p v-if="loading" class="text-sm text-ink-soft">Carregando...</p>

    <div v-else class="grid gap-5 lg:grid-cols-2">
      <!-- Receitas -->
      <div class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="font-display text-lg font-bold text-ink">Receitas extras</h3>
            <p class="text-xs text-ink-soft">Chamadas de capital, doações e patrocínios</p>
          </div>
          <button class="rounded-full bg-brand px-4 py-2 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep" @click="showReceitaModal = true">+ Adicionar</button>
        </div>
        <p class="mt-3 font-display text-2xl font-extrabold text-[#27500A]">{{ brl(totalReceitas) }}</p>

        <div class="mt-4 divide-y divide-ink/8">
          <div v-if="receitas.length === 0" class="py-6 text-center text-xs text-ink-soft">Nenhuma receita extra lançada ainda.</div>
          <div v-for="r in receitas" :key="r.id" class="flex items-center justify-between gap-2 py-2.5 text-sm">
            <div>
              <p class="text-ink">{{ r.descricao }}</p>
              <p class="text-xs text-ink-soft">{{ tipoReceitaLabel(r.tipo) }}<span v-if="r.origem_nome"> · {{ r.origem_nome }}</span> · {{ formatarData(r.data) }}</p>
            </div>
            <span class="flex items-center gap-2 font-semibold text-[#27500A]">{{ brl(r.valor) }}
              <button class="text-ink-soft/40 hover:text-brand-deep" @click="removerReceita(r.id)">✕</button>
            </span>
          </div>
        </div>
      </div>

      <!-- Despesas -->
      <div class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="font-display text-lg font-bold text-ink">Despesas gerais</h3>
            <p class="text-xs text-ink-soft">Benfeitorias, manutenções, compras de material</p>
          </div>
          <button class="rounded-full bg-brand px-4 py-2 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep" @click="showDespesaModal = true">+ Adicionar</button>
        </div>
        <p class="mt-3 font-display text-2xl font-extrabold text-brand-deep">{{ brl(totalDespesas) }}</p>

        <div class="mt-4 divide-y divide-ink/8">
          <div v-if="despesas.length === 0" class="py-6 text-center text-xs text-ink-soft">Nenhuma despesa lançada ainda.</div>
          <div v-for="d in despesas" :key="d.id" class="flex items-center justify-between gap-2 py-2.5 text-sm">
            <div>
              <p class="text-ink">{{ d.descricao }}</p>
              <p class="text-xs text-ink-soft">{{ categoriaDespesaLabel(d.categoria) }} · {{ formatarData(d.data) }}</p>
            </div>
            <span class="flex items-center gap-2 font-semibold text-ink">{{ brl(d.valor) }}
              <button class="text-ink-soft/40 hover:text-brand-deep" @click="removerDespesa(d.id)">✕</button>
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal nova receita -->
    <div v-if="showReceitaModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showReceitaModal = false; limparFormReceita()">
      <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
        <h2 class="font-display text-2xl font-extrabold text-ink">Nova receita</h2>
        <div class="mt-6 space-y-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Descrição</label>
            <input v-model="novaReceitaDescricao" type="text" placeholder="Ex: Doação aniversário do clube" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Valor</label>
              <CurrencyInput v-model="novaReceitaValor" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Data</label>
              <input v-model="novaReceitaData" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Tipo</label>
            <select v-model="novaReceitaTipo" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option v-for="t in tipoReceitaOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">De quem (opcional)</label>
            <input v-model="novaReceitaOrigem" type="text" placeholder="Nome do doador, patrocinador..." class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
        </div>
        <div class="mt-6 flex gap-3">
          <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="showReceitaModal = false; limparFormReceita()">Cancelar</button>
          <button :disabled="salvandoReceita" class="flex-1 rounded-full bg-brand py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionarReceita">
            {{ salvandoReceita ? 'Salvando...' : 'Salvar' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal nova despesa -->
    <div v-if="showDespesaModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showDespesaModal = false; limparFormDespesa()">
      <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
        <h2 class="font-display text-2xl font-extrabold text-ink">Nova despesa</h2>
        <div class="mt-6 space-y-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Descrição</label>
            <input v-model="novaDespesaDescricao" type="text" placeholder="Ex: Pintura da sala de eventos" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Valor</label>
              <CurrencyInput v-model="novaDespesaValor" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Data</label>
              <input v-model="novaDespesaData" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Categoria</label>
            <select v-model="novaDespesaCategoria" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option v-for="c in categoriaDespesaOptions" :key="c.value" :value="c.value">{{ c.label }}</option>
            </select>
          </div>
        </div>
        <div class="mt-6 flex gap-3">
          <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="showDespesaModal = false; limparFormDespesa()">Cancelar</button>
          <button :disabled="salvandoDespesa" class="flex-1 rounded-full bg-brand py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionarDespesa">
            {{ salvandoDespesa ? 'Salvando...' : 'Salvar' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
