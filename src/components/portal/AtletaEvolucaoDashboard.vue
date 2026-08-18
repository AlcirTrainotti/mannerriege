<script setup>
import { computed } from 'vue'
import DonutChart from './DonutChart.vue'
import LineChart from './LineChart.vue'
import { formatarDataCurta } from '../../data/campeonatos.js'
import { tempoNoProjeto, tipoAvaliacaoLabel } from '../../data/base.js'

// Dashboard de evolução do atleta — usado tanto no painel do
// responsável (um por atleta) quanto no painel do próprio atleta.
// Recebe o objeto "atleta" já enriquecido pelo componente pai
// (mensalidades, avaliacoes, historicoEventos/participacoesTotal).
const props = defineProps({
  atleta: { type: Object, required: true },
})

// Prefere a lista completa de participações (participacoesTotal) pra
// não distorcer frequência/nota média por causa do corte de 8 itens
// usado só pra exibir o histórico recente; cai pro historicoEventos
// se o componente pai não mandar a lista completa.
const participacoes = computed(() => props.atleta.participacoesTotal ?? props.atleta.historicoEventos ?? [])

const comPresenca = computed(() => participacoes.value.filter((p) => p.presente !== null && p.presente !== undefined))
const frequenciaPct = computed(() => {
  if (!comPresenca.value.length) return null
  const presentes = comPresenca.value.filter((p) => p.presente).length
  return Math.round((presentes / comPresenca.value.length) * 100)
})

const comNota = computed(() => participacoes.value.filter((p) => p.desempenho_nota !== null && p.desempenho_nota !== undefined))
const notaMedia = computed(() => {
  if (!comNota.value.length) return null
  const soma = comNota.value.reduce((s, p) => s + Number(p.desempenho_nota), 0)
  return (soma / comNota.value.length).toFixed(1)
})

const totalAulas = computed(() => participacoes.value.length)
const tempo = computed(() => tempoNoProjeto(props.atleta.data_ingresso))

function resumoAvaliacaoTipo(tipo) {
  // atleta.avaliacoes já vem ordenado por data desc (query do painel).
  const lista = (props.atleta.avaliacoes ?? []).filter((v) => v.tipo === tipo)
  const atual = lista[0] ?? null
  const anterior = lista[1] ?? null
  let tendencia = null
  if (atual?.nota !== null && atual?.nota !== undefined && anterior?.nota !== null && anterior?.nota !== undefined) {
    tendencia = Number(atual.nota) - Number(anterior.nota)
  }
  return { atual, tendencia }
}

const avaliacoesTiles = computed(() => (['fisico', 'tecnico', 'psicologico']).map((tipo) => ({ tipo, label: tipoAvaliacaoLabel(tipo), ...resumoAvaliacaoTipo(tipo) })))

const mensalidadesResumo = computed(() => {
  const lista = props.atleta.mensalidades ?? []
  if (!lista.length) return null
  const pago = lista.filter((m) => m.status === 'pago').length
  const pendente = lista.filter((m) => m.status === 'pendente').length
  const isento = lista.filter((m) => m.status === 'isento').length
  return { pago, pendente, isento, total: lista.length }
})

const evolucaoNotas = computed(() => {
  const ordenado = [...comNota.value].sort((a, b) => new Date(a.evento?.data ?? a.criado_em ?? 0) - new Date(b.evento?.data ?? b.criado_em ?? 0))
  const ultimos = ordenado.slice(-10)
  return {
    labels: ultimos.map((p) => formatarDataCurta(p.evento?.data ?? p.criado_em)),
    values: ultimos.map((p) => Number(p.desempenho_nota)),
  }
})

const temAlgumDado = computed(() => totalAulas.value > 0 || (props.atleta.avaliacoes ?? []).length > 0)
</script>

<template>
  <div class="rounded-xl bg-paper-dim p-4">
    <p class="font-mono-label text-[9px] font-bold text-ink-soft">EVOLUÇÃO E DESEMPENHO</p>

    <p v-if="!temAlgumDado" class="mt-2 text-xs text-ink-soft">Ainda não há aulas ou avaliações registradas pra mostrar aqui.</p>

    <template v-else>
      <!-- Indicadores principais -->
      <div class="mt-3 grid grid-cols-2 gap-2 sm:grid-cols-4">
        <div class="rounded-lg bg-white p-3 shadow-card">
          <p class="font-mono-label text-[8px] font-bold text-ink-soft">FREQUÊNCIA</p>
          <p class="mt-1 font-display text-lg font-extrabold text-ink">{{ frequenciaPct !== null ? `${frequenciaPct}%` : '—' }}</p>
        </div>
        <div class="rounded-lg bg-white p-3 shadow-card">
          <p class="font-mono-label text-[8px] font-bold text-ink-soft">NOTA MÉDIA</p>
          <p class="mt-1 font-display text-lg font-extrabold text-ink">{{ notaMedia ?? '—' }}</p>
        </div>
        <div class="rounded-lg bg-white p-3 shadow-card">
          <p class="font-mono-label text-[8px] font-bold text-ink-soft">TOTAL DE AULAS</p>
          <p class="mt-1 font-display text-lg font-extrabold text-ink">{{ totalAulas }}</p>
        </div>
        <div class="rounded-lg bg-white p-3 shadow-card">
          <p class="font-mono-label text-[8px] font-bold text-ink-soft">NO PROJETO</p>
          <p class="mt-1 font-display text-lg font-extrabold text-ink">{{ tempo ?? '—' }}</p>
        </div>
      </div>

      <!-- Avaliações periódicas -->
      <div class="mt-3 grid grid-cols-1 gap-2 sm:grid-cols-3">
        <div v-for="av in avaliacoesTiles" :key="av.tipo" class="rounded-lg bg-white p-3 shadow-card">
          <p class="font-mono-label text-[8px] font-bold text-ink-soft">{{ av.label.toUpperCase() }}</p>
          <div class="mt-1 flex items-center gap-1.5">
            <p class="font-display text-lg font-extrabold text-ink">{{ av.atual?.nota ?? '—' }}</p>
            <span v-if="av.tendencia !== null" :class="av.tendencia > 0 ? 'text-[#27500A]' : av.tendencia < 0 ? 'text-brand-deep' : 'text-ink-soft'" class="text-xs font-semibold">
              {{ av.tendencia > 0 ? `▲ +${av.tendencia}` : av.tendencia < 0 ? `▼ ${av.tendencia}` : '—' }}
            </span>
          </div>
          <p v-if="av.atual" class="text-[10px] text-ink-soft">{{ formatarDataCurta(av.atual.data) }}</p>
          <p v-else class="text-[10px] text-ink-soft">Sem avaliação ainda</p>
        </div>
      </div>

      <!-- Gráficos -->
      <div v-if="mensalidadesResumo || evolucaoNotas.values.length" class="mt-3 grid grid-cols-1 gap-3 sm:grid-cols-2">
        <div v-if="mensalidadesResumo" class="rounded-lg bg-white p-3 shadow-card">
          <p class="font-mono-label text-[8px] font-bold text-ink-soft">MENSALIDADES</p>
          <div class="mt-2 flex items-center gap-4">
            <div class="relative h-20 w-20 flex-shrink-0">
              <DonutChart
                :labels="['Pagas', 'Pendentes', 'Isentas']"
                :values="[mensalidadesResumo.pago, mensalidadesResumo.pendente, mensalidadesResumo.isento]"
                :colors="['#4a7c2a', '#ED1B24', '#c08a2e']"
              />
              <div class="pointer-events-none absolute inset-0 flex items-center justify-center">
                <span class="font-display text-sm font-extrabold text-ink">{{ mensalidadesResumo.total }}</span>
              </div>
            </div>
            <div class="space-y-1 text-[11px]">
              <p><span class="inline-block h-2 w-2 rounded-full" style="background:#4a7c2a"></span> Pagas: {{ mensalidadesResumo.pago }}</p>
              <p><span class="inline-block h-2 w-2 rounded-full" style="background:#ED1B24"></span> Pendentes: {{ mensalidadesResumo.pendente }}</p>
              <p><span class="inline-block h-2 w-2 rounded-full" style="background:#c08a2e"></span> Isentas: {{ mensalidadesResumo.isento }}</p>
            </div>
          </div>
        </div>

        <div v-if="evolucaoNotas.values.length" class="rounded-lg bg-white p-3 shadow-card">
          <p class="font-mono-label text-[8px] font-bold text-ink-soft">NOTA DE DESEMPENHO AO LONGO DO TEMPO</p>
          <div class="mt-2 h-24">
            <LineChart :labels="evolucaoNotas.labels" :values="evolucaoNotas.values" color="#ed1b24" />
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
