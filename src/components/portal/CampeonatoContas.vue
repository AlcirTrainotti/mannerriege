<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { brl, formatarDataCurta, premiacaoTipoLabel } from '../../data/campeonatos.js'
import { calcularRateio } from '../../lib/historicoCampeonatos.js'

const props = defineProps({
  campeonato: { type: Object, required: true },
})

const categorias = ref([])
const participantes = ref([])
const despesasPorCategoria = ref({})
const receitasPorCategoria = ref({})
const pagamentosPorParticipante = ref({})
const loading = ref(true)

async function carregar() {
  loading.value = true

  const { data: cats } = await supabase
    .from('campeonato_categorias')
    .select('*')
    .eq('campeonato_id', props.campeonato.id)
    .order('categoria')
  categorias.value = cats ?? []

  if ((cats ?? []).length > 0) {
    const catIds = cats.map((c) => c.id)

    const [partsRes, despRes, recRes] = await Promise.all([
      supabase.from('campeonato_participantes').select('*').in('campeonato_categoria_id', catIds),
      supabase.from('campeonato_categoria_despesas').select('*').in('campeonato_categoria_id', catIds),
      supabase.from('campeonato_categoria_receitas').select('*').in('campeonato_categoria_id', catIds),
    ])

    const parts = partsRes.data ?? []
    participantes.value = parts

    const dMap = {}
    ;(despRes.data ?? []).forEach((d) => {
      if (!dMap[d.campeonato_categoria_id]) dMap[d.campeonato_categoria_id] = []
      dMap[d.campeonato_categoria_id].push(d)
    })
    despesasPorCategoria.value = dMap

    const rMap = {}
    ;(recRes.data ?? []).forEach((r) => {
      if (!rMap[r.campeonato_categoria_id]) rMap[r.campeonato_categoria_id] = []
      rMap[r.campeonato_categoria_id].push(r)
    })
    receitasPorCategoria.value = rMap

    if (parts.length > 0) {
      const { data: pags } = await supabase
        .from('campeonato_participante_pagamentos')
        .select('*')
        .in('campeonato_participante_id', parts.map((p) => p.id))
      const pMap = {}
      ;(pags ?? []).forEach((pg) => {
        if (!pMap[pg.campeonato_participante_id]) pMap[pg.campeonato_participante_id] = []
        pMap[pg.campeonato_participante_id].push(pg)
      })
      pagamentosPorParticipante.value = pMap
    } else {
      pagamentosPorParticipante.value = {}
    }
  } else {
    participantes.value = []
    despesasPorCategoria.value = {}
    receitasPorCategoria.value = {}
    pagamentosPorParticipante.value = {}
  }

  loading.value = false
}

onMounted(carregar)

function atletasDe(categoriaId) {
  return participantes.value.filter((p) => p.campeonato_categoria_id === categoriaId && p.funcao === 'atleta')
}

function medalhasEntregues(categoriaId) {
  return participantes.value.filter((p) => p.campeonato_categoria_id === categoriaId && p.medalha_entregue).length
}

function rateioDe(categoria) {
  const atletas = atletasDe(categoria.id)
  return calcularRateio(categoria, despesasPorCategoria.value[categoria.id], receitasPorCategoria.value[categoria.id], atletas.length)
}

function totalPagoDe(participanteId) {
  return (pagamentosPorParticipante.value[participanteId] ?? []).reduce((s, pg) => s + Number(pg.valor || 0), 0)
}

function resumoCategoria(categoria) {
  const atletas = atletasDe(categoria.id)
  const rateio = rateioDe(categoria)
  const pagosCompletos = atletas.filter((a) => totalPagoDe(a.id) >= rateio - 0.005)

  const despesasRateadas = (despesasPorCategoria.value[categoria.id] ?? [])
    .filter((d) => d.tipo === 'rateado')
    .reduce((s, d) => s + Number(d.valor || 0), 0)
  const totalDespesas = Number(categoria.custo_inscricao || 0) + despesasRateadas +
    (despesasPorCategoria.value[categoria.id] ?? [])
      .filter((d) => d.tipo === 'assumido')
      .reduce((s, d) => s + Number(d.valor || 0), 0)

  const totalRecebidoRateio = atletas.reduce((s, a) => s + totalPagoDe(a.id), 0)
  const totalReceitasExtras = (receitasPorCategoria.value[categoria.id] ?? []).reduce((s, r) => s + Number(r.valor || 0), 0)
  const totalReceitas = totalRecebidoRateio + totalReceitasExtras

  const valorPendente = atletas.reduce((s, a) => s + Math.max(0, rateio - totalPagoDe(a.id)), 0)

  return {
    totalDespesas,
    totalReceitas,
    saldo: totalReceitas - totalDespesas,
    atletasTotal: atletas.length,
    atletasPagos: pagosCompletos.length,
    atletasPendentes: atletas.length - pagosCompletos.length,
    valorPendente,
  }
}

const resumoGeral = computed(() => {
  return categorias.value.reduce((acc, cat) => {
    const r = resumoCategoria(cat)
    acc.totalDespesas += r.totalDespesas
    acc.totalReceitas += r.totalReceitas
    acc.saldo += r.saldo
    acc.valorPendente += r.valorPendente
    acc.atletasPendentes += r.atletasPendentes
    return acc
  }, { totalDespesas: 0, totalReceitas: 0, saldo: 0, valorPendente: 0, atletasPendentes: 0 })
})

function imprimir() {
  window.print()
}
</script>

<template>
  <div>
    <div class="flex flex-wrap items-center justify-between gap-3">
      <h3 class="font-display text-xl font-bold text-ink">Prestação de contas</h3>
      <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="imprimir">
        🖨️ Imprimir
      </button>
    </div>

    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <template v-else>
      <div class="mt-5 grid gap-3 sm:grid-cols-4">
        <div class="rounded-2xl bg-paper-dim p-4">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">Total de despesas</p>
          <p class="mt-1 font-display text-xl font-extrabold text-ink">{{ brl(resumoGeral.totalDespesas) }}</p>
        </div>
        <div class="rounded-2xl bg-paper-dim p-4">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">Total de receitas</p>
          <p class="mt-1 font-display text-xl font-extrabold text-ink">{{ brl(resumoGeral.totalReceitas) }}</p>
        </div>
        <div class="rounded-2xl p-4" :class="resumoGeral.saldo >= 0 ? 'bg-[#EAF3DE]' : 'bg-brand-soft'">
          <p class="font-mono-label text-[9px] font-bold" :class="resumoGeral.saldo >= 0 ? 'text-[#27500A]' : 'text-brand-deep'">Saldo</p>
          <p class="mt-1 font-display text-xl font-extrabold" :class="resumoGeral.saldo >= 0 ? 'text-[#27500A]' : 'text-brand-deep'">{{ brl(resumoGeral.saldo) }}</p>
        </div>
        <div class="rounded-2xl bg-gold-soft p-4">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">Pendente de recebimento</p>
          <p class="mt-1 font-display text-xl font-extrabold text-ink">{{ brl(resumoGeral.valorPendente) }}</p>
          <p class="text-[10px] text-ink-soft">{{ resumoGeral.atletasPendentes }} atleta(s) ainda não pagaram</p>
        </div>
      </div>

      <div class="mt-6 space-y-3">
        <div v-for="cat in categorias" :key="cat.id" class="rounded-2xl bg-white p-5 shadow-card">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div class="flex flex-wrap items-center gap-2">
              <span class="rounded-full bg-brand px-3 py-1 font-mono-label text-[11px] font-bold text-white">{{ cat.categoria }}</span>
              <span v-if="cat.colocacao" class="rounded-full bg-gold-soft px-3 py-1 text-xs font-bold text-ink">🏆 {{ cat.colocacao }}</span>
              <span v-if="medalhasEntregues(cat.id) > 0" class="rounded-full bg-ink/8 px-3 py-1 text-xs font-semibold text-ink-soft">🏅 {{ medalhasEntregues(cat.id) }} entregue(s)</span>
            </div>
            <span class="font-display text-lg font-extrabold" :class="resumoCategoria(cat).saldo >= 0 ? 'text-[#27500A]' : 'text-brand-deep'">
              Saldo: {{ brl(resumoCategoria(cat).saldo) }}
            </span>
          </div>
          <p v-if="cat.premiacao_tipo" class="mt-2 text-xs text-ink-soft">
            Premiação: <strong class="text-ink">{{ cat.premiacao_tipo === 'dinheiro' ? brl(cat.premiacao_valor) : (cat.premiacao_descricao || premiacaoTipoLabel(cat.premiacao_tipo)) }}</strong>
          </p>
          <div class="mt-3 grid grid-cols-2 gap-3 text-xs sm:grid-cols-4">
            <div><span class="text-ink-soft">Despesas:</span> <strong class="text-ink">{{ brl(resumoCategoria(cat).totalDespesas) }}</strong></div>
            <div><span class="text-ink-soft">Receitas:</span> <strong class="text-ink">{{ brl(resumoCategoria(cat).totalReceitas) }}</strong></div>
            <div><span class="text-ink-soft">Atletas pagos:</span> <strong class="text-ink">{{ resumoCategoria(cat).atletasPagos }}/{{ resumoCategoria(cat).atletasTotal }}</strong></div>
            <div><span class="text-ink-soft">Pendente:</span> <strong class="text-ink">{{ brl(resumoCategoria(cat).valorPendente) }}</strong></div>
          </div>
        </div>
        <p v-if="categorias.length === 0" class="py-8 text-center text-sm text-ink-soft">Nenhuma categoria cadastrada ainda.</p>
      </div>
    </template>

    <div class="print-area hidden print:block">
      <h1 class="text-2xl font-bold">Mannerriege Vôlei Master</h1>
      <h2 class="mt-1 text-lg font-semibold">Prestação de contas — {{ campeonato.nome }}</h2>
      <p class="text-sm text-gray-600">
        <span v-if="campeonato.data_inicio">{{ formatarDataCurta(campeonato.data_inicio) }}<span v-if="campeonato.data_fim"> a {{ formatarDataCurta(campeonato.data_fim) }}</span></span>
      </p>

      <table class="mt-6 w-full border-collapse text-sm">
        <thead>
          <tr class="border-b-2 border-black text-left">
            <th class="py-1">Categoria</th>
            <th class="py-1">Despesas</th>
            <th class="py-1">Receitas</th>
            <th class="py-1">Saldo</th>
            <th class="py-1">Resultado</th>
            <th class="py-1">Premiação</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="cat in categorias" :key="'print-' + cat.id" class="border-b border-gray-300">
            <td class="py-1">{{ cat.categoria }}</td>
            <td class="py-1">{{ brl(resumoCategoria(cat).totalDespesas) }}</td>
            <td class="py-1">{{ brl(resumoCategoria(cat).totalReceitas) }}</td>
            <td class="py-1">{{ brl(resumoCategoria(cat).saldo) }}</td>
            <td class="py-1">{{ cat.colocacao || '—' }}</td>
            <td class="py-1">{{ cat.premiacao_tipo === 'dinheiro' ? brl(cat.premiacao_valor) : (cat.premiacao_descricao || (cat.premiacao_tipo ? premiacaoTipoLabel(cat.premiacao_tipo) : '—')) }}</td>
          </tr>
        </tbody>
        <tfoot>
          <tr class="border-t-2 border-black font-bold">
            <td class="py-1">Total</td>
            <td class="py-1">{{ brl(resumoGeral.totalDespesas) }}</td>
            <td class="py-1">{{ brl(resumoGeral.totalReceitas) }}</td>
            <td class="py-1">{{ brl(resumoGeral.saldo) }}</td>
            <td class="py-1"></td>
            <td class="py-1"></td>
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
</template>
