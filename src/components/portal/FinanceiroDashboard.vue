<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { brl } from '../../data/campeonatos.js'
import { formatarCompetencia } from '../../data/financeiro.js'

const mensalidades = ref([])
const statusAssociados = ref([])
const receitasGerais = ref([])
const despesasGerais = ref([])
const eventoReceitas = ref([])
const eventoDespesas = ref([])
const loading = ref(true)

const anoAtual = new Date().getFullYear()

async function carregar() {
  loading.value = true
  const [mensRes, statusRes, recRes, despRes, evRecRes, evDespRes] = await Promise.all([
    supabase.from('mensalidades').select('competencia, valor, pago'),
    supabase.from('profiles').select('status'),
    supabase.from('financeiro_receitas').select('valor, data'),
    supabase.from('financeiro_despesas').select('valor, data'),
    supabase.from('evento_receitas').select('valor, criado_em'),
    supabase.from('evento_despesas').select('valor, criado_em'),
  ])
  mensalidades.value = mensRes.data ?? []
  statusAssociados.value = statusRes.data ?? []
  receitasGerais.value = recRes.data ?? []
  despesasGerais.value = despRes.data ?? []
  eventoReceitas.value = evRecRes.data ?? []
  eventoDespesas.value = evDespRes.data ?? []
  await Promise.all([carregarFechamentos(), carregarAprovacoes()])
  loading.value = false
}

onMounted(carregar)

const resumoStatus = computed(() => {
  const r = { adimplente: 0, inadimplente: 0, inativo: 0 }
  statusAssociados.value.forEach((p) => { if (r[p.status] !== undefined) r[p.status]++ })
  return r
})

const competenciaAtual = computed(() => {
  const hoje = new Date()
  return `${hoje.getFullYear()}-${String(hoje.getMonth() + 1).padStart(2, '0')}-01`
})

const mensalidadesMesAtual = computed(() => mensalidades.value.filter((m) => m.competencia === competenciaAtual.value))
const receitaRecorrenteMes = computed(() => mensalidadesMesAtual.value.filter((m) => m.pago).reduce((s, m) => s + Number(m.valor || 0), 0))
const esperadoMes = computed(() => mensalidadesMesAtual.value.reduce((s, m) => s + Number(m.valor || 0), 0))

function noAno(dataIso) {
  return dataIso && new Date(dataIso).getFullYear() === anoAtual
}

const saldoGeralAno = computed(() => {
  const receitas =
    mensalidades.value.filter((m) => m.pago && noAno(m.competencia)).reduce((s, m) => s + Number(m.valor || 0), 0) +
    receitasGerais.value.filter((r) => noAno(r.data)).reduce((s, r) => s + Number(r.valor || 0), 0) +
    eventoReceitas.value.filter((r) => noAno(r.criado_em)).reduce((s, r) => s + Number(r.valor || 0), 0)

  const despesas =
    despesasGerais.value.filter((d) => noAno(d.data)).reduce((s, d) => s + Number(d.valor || 0), 0) +
    eventoDespesas.value.filter((d) => noAno(d.criado_em)).reduce((s, d) => s + Number(d.valor || 0), 0)

  return { receitas, despesas, saldo: receitas - despesas }
})

const ultimosMeses = computed(() => {
  const competencias = [...new Set(mensalidades.value.map((m) => m.competencia))].sort().reverse().slice(0, 6)
  return competencias.map((c) => {
    const doMes = mensalidades.value.filter((m) => m.competencia === c)
    const pagas = doMes.filter((m) => m.pago)
    return {
      competencia: c,
      esperado: doMes.reduce((s, m) => s + Number(m.valor || 0), 0),
      arrecadado: pagas.reduce((s, m) => s + Number(m.valor || 0), 0),
      percentual: doMes.length > 0 ? Math.round((pagas.length / doMes.length) * 100) : 0,
    }
  })
})

const totalAssociados = computed(() => statusAssociados.value.length)
const percentualAdimplencia = computed(() => totalAssociados.value > 0 ? Math.round((resumoStatus.value.adimplente / totalAssociados.value) * 100) : 0)

// --- Fechamento anual ---
const fechamentos = ref([])
const fechandoAno = ref(false)
const confirmandoFechamento = ref(false)

async function carregarFechamentos() {
  const { data } = await supabase.from('fechamentos_anuais').select('*').order('ano', { ascending: false })
  fechamentos.value = data ?? []
}

const jaFechouAnoAtual = computed(() => fechamentos.value.some((f) => f.ano === anoAtual))

async function fecharAno() {
  fechandoAno.value = true
  const { error } = await supabase.from('fechamentos_anuais').insert({
    ano: anoAtual,
    total_receitas: saldoGeralAno.value.receitas,
    total_despesas: saldoGeralAno.value.despesas,
    saldo: saldoGeralAno.value.saldo,
  })
  fechandoAno.value = false
  confirmandoFechamento.value = false
  if (!error) await carregarFechamentos()
}

// --- Aprovacao mensal do conselho fiscal ---
const aprovacoes = ref([])

async function carregarAprovacoes() {
  const { data } = await supabase.from('aprovacoes_mensais').select('*')
  aprovacoes.value = data ?? []
}

function aprovacoesDoMes(competencia) {
  return aprovacoes.value.filter((a) => a.competencia === competencia)
}
</script>

<template>
  <div>
    <p v-if="loading" class="text-sm text-ink-soft">Carregando...</p>

    <template v-else>
      <p class="text-xs text-ink-soft/70">
        Este painel cobre o financeiro geral do clube (mensalidades, receitas/despesas gerais e eventos).
        O orçamento de cada campeonato tem sua própria prestação de contas, na aba Esportivo.
      </p>

      <div class="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <div class="rounded-2xl bg-paper-dim p-5">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">Mensalidades arrecadadas (mês)</p>
          <p class="mt-1 font-display text-2xl font-extrabold text-ink">{{ brl(receitaRecorrenteMes) }}</p>
          <p class="text-[10px] text-ink-soft">de {{ brl(esperadoMes) }} esperado</p>
        </div>
        <div class="rounded-2xl bg-[#EAF3DE] p-5">
          <p class="font-mono-label text-[9px] font-bold text-[#27500A]">Associados adimplentes</p>
          <p class="mt-1 font-display text-2xl font-extrabold text-[#27500A]">{{ resumoStatus.adimplente }}/{{ totalAssociados }}</p>
          <p class="text-[10px] text-[#27500A]">{{ percentualAdimplencia }}% do quadro</p>
        </div>
        <div class="rounded-2xl bg-brand-soft p-5">
          <p class="font-mono-label text-[9px] font-bold text-brand-deep">Inadimplentes</p>
          <p class="mt-1 font-display text-2xl font-extrabold text-brand-deep">{{ resumoStatus.inadimplente }}</p>
          <p class="text-[10px] text-brand-deep">{{ resumoStatus.inativo }} inativo(s)</p>
        </div>
        <div class="rounded-2xl p-5" :class="saldoGeralAno.saldo >= 0 ? 'bg-[#EAF3DE]' : 'bg-brand-soft'">
          <p class="font-mono-label text-[9px] font-bold" :class="saldoGeralAno.saldo >= 0 ? 'text-[#27500A]' : 'text-brand-deep'">Saldo geral em {{ anoAtual }}</p>
          <p class="mt-1 font-display text-2xl font-extrabold" :class="saldoGeralAno.saldo >= 0 ? 'text-[#27500A]' : 'text-brand-deep'">{{ brl(saldoGeralAno.saldo) }}</p>
          <p class="text-[10px]" :class="saldoGeralAno.saldo >= 0 ? 'text-[#27500A]' : 'text-brand-deep'">{{ brl(saldoGeralAno.receitas) }} receitas · {{ brl(saldoGeralAno.despesas) }} despesas</p>
        </div>
      </div>

      <div class="mt-6 rounded-2xl bg-white p-6 shadow-card">
        <h3 class="font-display text-lg font-bold text-ink">Recorrência das mensalidades</h3>
        <p class="text-xs text-ink-soft">Últimos meses com cobrança gerada</p>

        <div v-if="ultimosMeses.length === 0" class="mt-4 text-sm text-ink-soft">
          Nenhuma mensalidade gerada ainda. Vá na aba "Mensalidades" para gerar a cobrança do mês.
        </div>
        <div v-else class="mt-4 divide-y divide-ink/8">
          <div v-for="m in ultimosMeses" :key="m.competencia" class="flex items-center justify-between gap-3 py-2.5 text-sm">
            <span class="text-ink">{{ formatarCompetencia(m.competencia) }}</span>
            <div class="flex items-center gap-3">
              <span class="text-xs text-ink-soft">{{ brl(m.arrecadado) }} / {{ brl(m.esperado) }}</span>
              <span
                class="rounded-full px-2.5 py-1 text-[10px] font-bold"
                :class="m.percentual >= 90 ? 'bg-[#EAF3DE] text-[#27500A]' : m.percentual >= 60 ? 'bg-gold-soft text-ink' : 'bg-brand-soft text-brand-deep'"
              >{{ m.percentual }}% pago</span>
              <span
                class="rounded-full px-2.5 py-1 text-[10px] font-bold"
                :class="aprovacoesDoMes(m.competencia).length > 0 ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-ink/8 text-ink-soft'"
              >{{ aprovacoesDoMes(m.competencia).length }} aprovação(ões) do conselho</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Fechamento anual -->
      <div class="mt-6 rounded-2xl bg-white p-6 shadow-card">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h3 class="font-display text-lg font-bold text-ink">Fechamento e prestação de contas do ano</h3>
            <p class="text-xs text-ink-soft">Registra oficialmente o resultado de {{ anoAtual }} para consulta futura.</p>
          </div>
          <div v-if="!jaFechouAnoAtual">
            <template v-if="confirmandoFechamento">
              <span class="text-xs text-ink-soft">Fechar {{ anoAtual }} com saldo de {{ brl(saldoGeralAno.saldo) }}?</span>
              <button :disabled="fechandoAno" class="ml-2 rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="fecharAno">
                {{ fechandoAno ? 'Fechando...' : 'Sim, fechar' }}
              </button>
              <button class="ml-2 rounded-full border border-ink/15 px-4 py-2 text-xs text-ink-soft hover:border-ink/30" @click="confirmandoFechamento = false">Cancelar</button>
            </template>
            <button v-else class="rounded-full bg-ink px-4 py-2 text-xs font-semibold text-white hover:bg-ink/80" @click="confirmandoFechamento = true">
              🔒 Fechar o ano de {{ anoAtual }}
            </button>
          </div>
          <span v-else class="rounded-full bg-[#EAF3DE] px-3 py-1.5 text-xs font-bold text-[#27500A]">✓ {{ anoAtual }} já fechado</span>
        </div>

        <div v-if="fechamentos.length > 0" class="mt-4 divide-y divide-ink/8">
          <div v-for="f in fechamentos" :key="f.id" class="flex items-center justify-between py-2.5 text-sm">
            <span class="text-ink">{{ f.ano }}</span>
            <span class="text-xs text-ink-soft">
              Receitas {{ brl(f.total_receitas) }} · Despesas {{ brl(f.total_despesas) }} ·
              <strong :class="f.saldo >= 0 ? 'text-[#27500A]' : 'text-brand-deep'">Saldo {{ brl(f.saldo) }}</strong>
            </span>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
