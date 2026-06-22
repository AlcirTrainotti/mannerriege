<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { brl } from '../../data/campeonatos.js'
import { formatarCompetencia } from '../../data/financeiro.js'
import PaginacaoControle from './PaginacaoControle.vue'
import CurrencyInput from './CurrencyInput.vue'

const mensalidades = ref([])
const associadosMap = ref({})
const loading = ref(true)
const loadError = ref('')
const busca = ref('')
const paginaAtual = ref(1)
const porPagina = ref(25)

const competenciasDisponiveis = ref([])
const competenciaFiltro = ref('todas')

const gerandoMes = ref(false)
const mesParaGerar = ref(proximoMesPadrao())
const resultadoGeracao = ref('')

function proximoMesPadrao() {
  const hoje = new Date()
  return `${hoje.getFullYear()}-${String(hoje.getMonth() + 1).padStart(2, '0')}-01`
}

async function carregar() {
  loading.value = true
  loadError.value = ''

  const [mensRes, assocsRes] = await Promise.all([
    supabase.from('mensalidades').select('*').order('competencia', { ascending: false }),
    supabase.rpc('listar_associados_basico'),
  ])

  if (mensRes.error) {
    loadError.value = mensRes.error.message
    loading.value = false
    return
  }
  mensalidades.value = mensRes.data ?? []

  const am = {}
  ;(assocsRes.data ?? []).forEach((a) => { am[a.id] = a })
  associadosMap.value = am

  competenciasDisponiveis.value = [...new Set(mensalidades.value.map((m) => m.competencia))].sort().reverse()

  loading.value = false
}

onMounted(carregar)

function nomeAssociado(id) {
  return associadosMap.value[id]?.nome ?? '(associado removido)'
}

const filtradas = computed(() => {
  let lista = mensalidades.value
  if (competenciaFiltro.value !== 'todas') {
    lista = lista.filter((m) => m.competencia === competenciaFiltro.value)
  }
  const termo = busca.value.trim().toLowerCase()
  if (termo) {
    lista = lista.filter((m) => nomeAssociado(m.associado_id).toLowerCase().includes(termo))
  }
  return lista
})

const paginadas = computed(() => {
  const ini = (paginaAtual.value - 1) * porPagina.value
  return filtradas.value.slice(ini, ini + porPagina.value)
})

watch([busca, competenciaFiltro], () => { paginaAtual.value = 1 })

const resumo = computed(() => {
  const lista = competenciaFiltro.value === 'todas' ? mensalidades.value : mensalidades.value.filter((m) => m.competencia === competenciaFiltro.value)
  const pagas = lista.filter((m) => m.pago)
  return {
    total: lista.length,
    pagas: pagas.length,
    pendentes: lista.length - pagas.length,
    valorArrecadado: pagas.reduce((s, m) => s + Number(m.valor || 0), 0),
    valorPendente: lista.filter((m) => !m.pago).reduce((s, m) => s + Number(m.valor || 0), 0),
  }
})

async function gerarMensalidades() {
  gerandoMes.value = true
  resultadoGeracao.value = ''
  const { data, error } = await supabase.rpc('gerar_mensalidades_mes', { p_competencia: mesParaGerar.value })
  gerandoMes.value = false
  if (error) {
    resultadoGeracao.value = 'Erro: ' + error.message
    return
  }
  resultadoGeracao.value = data > 0
    ? `${data} mensalidade(s) gerada(s) com sucesso.`
    : 'Nenhuma mensalidade nova - esse mês já tinha sido gerado para todos.'
  await carregar()
}

async function alternarPago(m) {
  const novoValor = !m.pago
  await supabase.from('mensalidades').update({
    pago: novoValor,
    data_pagamento: novoValor ? new Date().toISOString().slice(0, 10) : null,
  }).eq('id', m.id)
  m.pago = novoValor
  m.data_pagamento = novoValor ? new Date().toISOString().slice(0, 10) : null
}

// --- Editar / excluir ---
const editandoId = ref(null)
const editValor = ref(0)
const editCompetencia = ref('')
const salvandoEdicao = ref(false)
const confirmandoExclusaoId = ref(null)
const excluindoId = ref(null)

function iniciarEdicao(m) {
  editandoId.value = m.id
  editValor.value = m.valor
  editCompetencia.value = m.competencia
}

async function salvarEdicao(m) {
  salvandoEdicao.value = true
  const { error } = await supabase.from('mensalidades').update({
    valor: editValor.value,
    competencia: editCompetencia.value,
  }).eq('id', m.id)
  salvandoEdicao.value = false
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  m.valor = editValor.value
  m.competencia = editCompetencia.value
  editandoId.value = null
  competenciasDisponiveis.value = [...new Set(mensalidades.value.map((x) => x.competencia))].sort().reverse()
}

async function excluir(id) {
  confirmandoExclusaoId.value = null
  excluindoId.value = id
  const { error } = await supabase.from('mensalidades').delete().eq('id', id)
  excluindoId.value = null
  if (error) {
    loadError.value = 'Não foi possível excluir: ' + error.message
    return
  }
  mensalidades.value = mensalidades.value.filter((m) => m.id !== id)
}
</script>

<template>
  <div>
    <div class="rounded-2xl bg-white p-6 shadow-card">
      <h3 class="font-display text-lg font-bold text-ink">Gerar mensalidades do mês</h3>
      <p class="mt-1 text-xs text-ink-soft">
        Cria a cobrança do mês para todo associado ativo, com o valor certo conforme ele seja ou não sócio do ginástico
        (R$ 30 / R$ 50). Se já tiver sido gerado antes, não duplica.
      </p>
      <div class="mt-4 flex flex-wrap items-center gap-3">
        <input v-model="mesParaGerar" type="date" class="rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
        <button :disabled="gerandoMes" class="rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="gerarMensalidades">
          {{ gerandoMes ? 'Gerando...' : 'Gerar mensalidades' }}
        </button>
      </div>
      <p v-if="resultadoGeracao" class="mt-2 text-xs text-brand-deep">{{ resultadoGeracao }}</p>
    </div>

    <div class="mt-6 grid gap-3 sm:grid-cols-4">
      <div class="rounded-2xl bg-paper-dim p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">Arrecadado</p>
        <p class="mt-1 font-display text-xl font-extrabold text-ink">{{ brl(resumo.valorArrecadado) }}</p>
      </div>
      <div class="rounded-2xl bg-paper-dim p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">Pendente</p>
        <p class="mt-1 font-display text-xl font-extrabold text-ink">{{ brl(resumo.valorPendente) }}</p>
      </div>
      <div class="rounded-2xl bg-paper-dim p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">Pagas</p>
        <p class="mt-1 font-display text-xl font-extrabold text-ink">{{ resumo.pagas }}/{{ resumo.total }}</p>
      </div>
      <div class="rounded-2xl bg-paper-dim p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">Inadimplentes no período</p>
        <p class="mt-1 font-display text-xl font-extrabold text-ink">{{ resumo.pendentes }}</p>
      </div>
    </div>

    <div class="mt-6 flex flex-wrap items-center gap-3">
      <select v-model="competenciaFiltro" class="rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
        <option value="todas">Todos os meses</option>
        <option v-for="c in competenciasDisponiveis" :key="c" :value="c">{{ formatarCompetencia(c) }}</option>
      </select>
      <input v-model="busca" type="text" placeholder="Buscar por nome..." class="min-w-0 flex-1 rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else class="mt-5 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
      <div v-if="filtradas.length === 0" class="py-8 text-center text-sm text-ink-soft">Nenhuma mensalidade encontrada.</div>
      <div v-for="m in paginadas" :key="m.id" class="px-5 py-3">
        <template v-if="editandoId !== m.id">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-ink">{{ nomeAssociado(m.associado_id) }}</p>
              <p class="text-xs text-ink-soft">{{ formatarCompetencia(m.competencia) }} · {{ brl(m.valor) }}</p>
            </div>
            <div class="flex items-center gap-2">
              <button
                class="rounded-full px-3 py-1.5 text-xs font-bold"
                :class="m.pago ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-brand-soft text-brand-deep'"
                @click="alternarPago(m)"
              >{{ m.pago ? '✓ pago' : 'pendente' }}</button>
              <button class="text-xs text-ink-soft hover:text-ink" @click="iniciarEdicao(m)">editar</button>
              <template v-if="confirmandoExclusaoId === m.id">
                <button class="text-xs font-bold text-brand-deep hover:underline" :disabled="excluindoId === m.id" @click="excluir(m.id)">sim, excluir</button>
                <button class="text-xs text-ink-soft hover:underline" @click="confirmandoExclusaoId = null">cancelar</button>
              </template>
              <button v-else class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="confirmandoExclusaoId = m.id">excluir</button>
            </div>
          </div>
        </template>
        <template v-else>
          <div class="flex flex-wrap items-center gap-2">
            <span class="text-sm font-semibold text-ink">{{ nomeAssociado(m.associado_id) }}</span>
            <input v-model="editCompetencia" type="date" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
            <CurrencyInput v-model="editValor" class="w-28 rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
            <button :disabled="salvandoEdicao" class="rounded-lg bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="salvarEdicao(m)">Salvar</button>
            <button class="rounded-lg border border-ink/15 px-3 py-1.5 text-xs text-ink-soft hover:border-ink/30" @click="editandoId = null">Cancelar</button>
          </div>
        </template>
      </div>
    </div>

    <PaginacaoControle
      v-model:pagina="paginaAtual"
      v-model:por-pagina="porPagina"
      :total="filtradas.length"
      :opcoes-por-pagina="[25, 50, 100]"
    />
  </div>
</template>
