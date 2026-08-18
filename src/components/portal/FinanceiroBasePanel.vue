<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import CurrencyInput from './CurrencyInput.vue'
import { brl } from '../../data/campeonatos.js'
import { mesesOptions } from '../../data/financeiro.js'
import {
  tipoReceitaBaseOptions, tipoReceitaBaseLabel,
  categoriaDespesaBaseOptions, categoriaDespesaBaseLabel,
  statusFinanceiroBaseClasses,
} from '../../data/base.js'

// Financeiro das Categorias de Base — independente do financeiro do
// Master (não compartilha tabelas nem saldo, por pedido explícito).
defineProps({
  embedded: { type: Boolean, default: false },
})

const { profile } = useAuth()

const aba = ref('lancamentos')
const titulos = {
  lancamentos: 'Lançamentos financeiros',
  pagar: 'Contas a pagar',
  receber: 'Contas a receber',
  fechamentos: 'Fechamentos',
  matriculas: 'Gestão de matrículas',
}

const despesas = ref([])
const receitas = ref([])
const fechamentos = ref([])
const matriculas = ref([])
const atletas = ref([])
const planos = ref([])
const carregando = ref(true)

async function carregarTudo() {
  carregando.value = true
  const [{ data: d }, { data: r }, { data: f }, { data: m }, { data: a }, { data: p }] = await Promise.all([
    supabase.from('financeiro_base_despesas').select('*').order('data', { ascending: false }),
    supabase.from('financeiro_base_receitas').select('*').order('data', { ascending: false }),
    supabase.from('fechamentos_base').select('*').order('competencia', { ascending: false }),
    supabase.from('matriculas_base').select('*').order('criado_em', { ascending: false }),
    supabase.from('atletas_base').select('id, nome'),
    supabase.from('planos_base').select('id, nome'),
  ])
  despesas.value = d ?? []
  receitas.value = r ?? []
  fechamentos.value = f ?? []
  matriculas.value = m ?? []
  atletas.value = a ?? []
  planos.value = p ?? []
  carregando.value = false
}
onMounted(carregarTudo)

function nomeAtleta(id) { return atletas.value.find((a) => a.id === id)?.nome ?? '—' }
function nomePlano(id) { return planos.value.find((p) => p.id === id)?.nome ?? '—' }

// --- Lançamentos ---
const movimento = ref('despesa')
const descricao = ref('')
const valor = ref(0)
const data = ref(new Date().toISOString().slice(0, 10))
const categoriaDespesa = ref('material')
const tipoReceita = ref('mensalidade')
const origemReceita = ref('')
const jaPago = ref(true)
const salvandoLancamento = ref(false)
const erroLancamento = ref('')

async function salvarLancamento() {
  erroLancamento.value = ''
  if (!descricao.value.trim() || !valor.value) {
    erroLancamento.value = 'Preencha a descrição e o valor.'
    return
  }
  salvandoLancamento.value = true
  let resultado
  if (movimento.value === 'despesa') {
    resultado = await supabase.from('financeiro_base_despesas').insert({
      descricao: descricao.value.trim(), valor: valor.value, categoria: categoriaDespesa.value, data: data.value,
      status: jaPago.value ? 'pago' : 'pendente', data_pagamento: jaPago.value ? data.value : null,
      criado_por: profile.value?.id ?? null,
    }).select().single()
    if (!resultado.error) despesas.value.unshift(resultado.data)
  } else {
    resultado = await supabase.from('financeiro_base_receitas').insert({
      descricao: descricao.value.trim(), valor: valor.value, tipo: tipoReceita.value,
      origem_nome: origemReceita.value.trim() || null, data: data.value,
      status: jaPago.value ? 'recebido' : 'pendente', data_recebimento: jaPago.value ? data.value : null,
      criado_por: profile.value?.id ?? null,
    }).select().single()
    if (!resultado.error) receitas.value.unshift(resultado.data)
  }
  salvandoLancamento.value = false
  if (resultado.error) {
    erroLancamento.value = resultado.error.message
    return
  }
  descricao.value = ''
  valor.value = 0
  origemReceita.value = ''
}

const lancamentosRecentes = computed(() => {
  const todos = [
    ...despesas.value.map((d) => ({ ...d, movimento: 'despesa' })),
    ...receitas.value.map((r) => ({ ...r, movimento: 'receita' })),
  ]
  return todos.sort((a, b) => (a.data < b.data ? 1 : -1)).slice(0, 30)
})

// --- Contas a pagar / a receber ---
const despesasPendentes = computed(() => despesas.value.filter((d) => d.status === 'pendente'))
const receitasPendentes = computed(() => receitas.value.filter((r) => r.status === 'pendente'))

async function marcarPago(d) {
  const hoje = new Date().toISOString().slice(0, 10)
  const { error } = await supabase.from('financeiro_base_despesas').update({ status: 'pago', data_pagamento: hoje }).eq('id', d.id)
  if (!error) { d.status = 'pago'; d.data_pagamento = hoje }
}
async function marcarRecebido(r) {
  const hoje = new Date().toISOString().slice(0, 10)
  const { error } = await supabase.from('financeiro_base_receitas').update({ status: 'recebido', data_recebimento: hoje }).eq('id', r.id)
  if (!error) { r.status = 'recebido'; r.data_recebimento = hoje }
}

// --- Fechamentos ---
const competenciaFechamento = ref(new Date().toISOString().slice(0, 7))
const fechando = ref(false)

async function fecharMes() {
  fechando.value = true
  const competencia = `${competenciaFechamento.value}-01`
  const mesSeguinte = new Date(competencia)
  mesSeguinte.setMonth(mesSeguinte.getMonth() + 1)
  const fimMes = mesSeguinte.toISOString().slice(0, 10)

  const totalReceitas = receitas.value
    .filter((r) => r.data >= competencia && r.data < fimMes)
    .reduce((s, r) => s + Number(r.valor), 0)
  const totalDespesas = despesas.value
    .filter((d) => d.data >= competencia && d.data < fimMes)
    .reduce((s, d) => s + Number(d.valor), 0)

  const { data: novo, error } = await supabase.from('fechamentos_base').insert({
    competencia, total_receitas: totalReceitas, total_despesas: totalDespesas,
    saldo: totalReceitas - totalDespesas, fechado_por: profile.value?.id ?? null,
  }).select().single()
  fechando.value = false
  if (error) {
    alert(error.code === '23505' ? 'Esse mês já foi fechado.' : error.message)
    return
  }
  fechamentos.value.unshift(novo)
}

function competenciaLabel(dataIso) {
  const d = new Date(dataIso + 'T00:00:00')
  return `${mesesOptions[d.getMonth()]} de ${d.getFullYear()}`
}

// --- Matrículas ---
async function marcarMatriculaPaga(m) {
  const { error } = await supabase.from('matriculas_base').update({ status: 'pago', data_pagamento: new Date().toISOString().slice(0, 10) }).eq('id', m.id)
  if (!error) { m.status = 'pago'; m.data_pagamento = new Date().toISOString().slice(0, 10) }
}
</script>

<template>
  <div>
    <div v-if="!embedded">
      <p class="font-mono-label text-[11px] font-bold text-brand-deep">Administrativo</p>
      <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">{{ titulos[aba] }}</h1>
    </div>

    <div :class="embedded ? 'flex flex-wrap gap-2' : 'mt-6 flex flex-wrap gap-2'">
      <button v-for="(t, k) in titulos" :key="k" class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === k ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = k">{{ t }}</button>
    </div>

    <p v-if="carregando" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else class="mt-6">
      <!-- Lançamentos -->
      <div v-if="aba === 'lancamentos'" class="mx-auto max-w-lg">
        <div class="rounded-2xl bg-white p-6 shadow-card">
          <div class="flex gap-2">
            <button class="flex-1 rounded-full py-2.5 text-xs font-bold transition-colors" :class="movimento === 'despesa' ? 'bg-brand text-white' : 'bg-paper-dim text-ink-soft'" @click="movimento = 'despesa'">− Despesa</button>
            <button class="flex-1 rounded-full py-2.5 text-xs font-bold transition-colors" :class="movimento === 'receita' ? 'bg-[#27500A] text-white' : 'bg-paper-dim text-ink-soft'" @click="movimento = 'receita'">+ Receita</button>
          </div>

          <form class="mt-5 space-y-3" @submit.prevent="salvarLancamento">
            <input v-model="descricao" placeholder="Descrição" class="w-full rounded-xl border border-ink/15 px-4 py-3 text-sm" />
            <div class="grid grid-cols-2 gap-3">
              <CurrencyInput v-model="valor" class="w-full rounded-xl border border-ink/15 px-4 py-3 text-base" />
              <input v-model="data" type="date" class="w-full rounded-xl border border-ink/15 px-4 py-3 text-sm" />
            </div>
            <select v-if="movimento === 'despesa'" v-model="categoriaDespesa" class="w-full rounded-xl border border-ink/15 px-4 py-3 text-sm">
              <option v-for="c in categoriaDespesaBaseOptions" :key="c.value" :value="c.value">{{ c.label }}</option>
            </select>
            <template v-else>
              <select v-model="tipoReceita" class="w-full rounded-xl border border-ink/15 px-4 py-3 text-sm">
                <option v-for="t in tipoReceitaBaseOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
              </select>
              <input v-model="origemReceita" placeholder="De quem (opcional)" class="w-full rounded-xl border border-ink/15 px-4 py-3 text-sm" />
            </template>
            <label class="flex items-center gap-2 text-xs text-ink">
              <input v-model="jaPago" type="checkbox" class="h-3.5 w-3.5 rounded border-ink/30" />
              {{ movimento === 'despesa' ? 'Já foi pago' : 'Já foi recebido' }} (senão entra como pendente)
            </label>
            <p v-if="erroLancamento" class="text-xs text-brand-deep">{{ erroLancamento }}</p>
            <button type="submit" :disabled="salvandoLancamento" class="w-full rounded-full py-3.5 font-mono-label text-[12px] font-bold text-white disabled:opacity-50" :class="movimento === 'despesa' ? 'bg-brand hover:bg-brand-deep' : 'bg-[#27500A] hover:opacity-90'">{{ salvandoLancamento ? 'Salvando...' : 'Salvar lançamento' }}</button>
          </form>
        </div>

        <div v-if="lancamentosRecentes.length" class="mt-5 space-y-1.5">
          <p class="font-mono-label text-[10px] font-bold text-ink-soft">RECENTES</p>
          <div v-for="l in lancamentosRecentes" :key="l.movimento + l.id" class="flex items-center justify-between rounded-xl bg-white px-4 py-2.5 text-sm shadow-card">
            <div>
              <span class="text-ink-soft">{{ l.descricao }}</span>
              <span class="ml-2 rounded-full px-2 py-0.5 text-[9px] font-bold" :class="statusFinanceiroBaseClasses(l.status)">{{ l.status }}</span>
            </div>
            <span class="font-semibold" :class="l.movimento === 'despesa' ? 'text-brand-deep' : 'text-[#27500A]'">{{ l.movimento === 'despesa' ? '−' : '+' }} {{ brl(l.valor) }}</span>
          </div>
        </div>
      </div>

      <!-- Contas a pagar -->
      <div v-else-if="aba === 'pagar'">
        <div v-if="!despesasPendentes.length" class="rounded-2xl border border-dashed border-ink/15 p-8 text-center text-sm text-ink-soft">Nenhuma conta a pagar em aberto.</div>
        <div v-else class="divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
          <div v-for="d in despesasPendentes" :key="d.id" class="flex flex-wrap items-center justify-between gap-2 px-5 py-3">
            <div>
              <p class="text-sm text-ink">{{ d.descricao }}</p>
              <p class="text-xs text-ink-soft">{{ categoriaDespesaBaseLabel(d.categoria) }} · vence {{ d.vencimento ?? d.data }}</p>
            </div>
            <div class="flex items-center gap-3">
              <span class="text-sm font-semibold text-brand-deep">{{ brl(d.valor) }}</span>
              <button class="rounded-full bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep" @click="marcarPago(d)">Marcar como pago</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Contas a receber -->
      <div v-else-if="aba === 'receber'">
        <div v-if="!receitasPendentes.length" class="rounded-2xl border border-dashed border-ink/15 p-8 text-center text-sm text-ink-soft">Nenhuma conta a receber em aberto.</div>
        <div v-else class="divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
          <div v-for="r in receitasPendentes" :key="r.id" class="flex flex-wrap items-center justify-between gap-2 px-5 py-3">
            <div>
              <p class="text-sm text-ink">{{ r.descricao }}</p>
              <p class="text-xs text-ink-soft">{{ tipoReceitaBaseLabel(r.tipo) }}<span v-if="r.origem_nome"> · {{ r.origem_nome }}</span> · vence {{ r.vencimento ?? r.data }}</p>
            </div>
            <div class="flex items-center gap-3">
              <span class="text-sm font-semibold text-[#27500A]">{{ brl(r.valor) }}</span>
              <button class="rounded-full bg-[#27500A] px-3 py-1.5 text-xs font-bold text-white hover:opacity-90" @click="marcarRecebido(r)">Marcar como recebido</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Fechamentos -->
      <div v-else-if="aba === 'fechamentos'">
        <div class="flex flex-wrap items-end gap-3 rounded-2xl bg-white p-5 shadow-card">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Mês a fechar</label>
            <input v-model="competenciaFechamento" type="month" class="mt-1 rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          </div>
          <button :disabled="fechando" class="rounded-full bg-ink px-4 py-2 text-xs font-bold text-white hover:opacity-90 disabled:opacity-50" @click="fecharMes">{{ fechando ? 'Fechando...' : 'Fechar mês' }}</button>
        </div>

        <div v-if="fechamentos.length" class="mt-4 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
          <div v-for="f in fechamentos" :key="f.id" class="flex flex-wrap items-center justify-between gap-2 px-5 py-3">
            <p class="text-sm font-semibold text-ink">{{ competenciaLabel(f.competencia) }}</p>
            <p class="text-xs text-ink-soft">receitas {{ brl(f.total_receitas) }} · despesas {{ brl(f.total_despesas) }}</p>
            <p class="text-sm font-bold" :class="f.saldo >= 0 ? 'text-[#27500A]' : 'text-brand-deep'">saldo {{ brl(f.saldo) }}</p>
          </div>
        </div>
      </div>

      <!-- Matrículas -->
      <div v-else-if="aba === 'matriculas'">
        <div v-if="!matriculas.length" class="rounded-2xl border border-dashed border-ink/15 p-8 text-center text-sm text-ink-soft">Nenhuma taxa de matrícula gerada ainda — só é gerada quando o plano do atleta cobra taxa de matrícula.</div>
        <div v-else class="divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
          <div v-for="m in matriculas" :key="m.id" class="flex flex-wrap items-center justify-between gap-2 px-5 py-3">
            <div>
              <p class="text-sm text-ink">{{ nomeAtleta(m.atleta_id) }}</p>
              <p class="text-xs text-ink-soft">{{ nomePlano(m.plano_id) }}</p>
            </div>
            <div class="flex items-center gap-3">
              <span class="text-sm font-semibold text-ink">{{ brl(m.valor) }}</span>
              <span class="rounded-full px-2.5 py-0.5 text-[10px] font-bold" :class="statusFinanceiroBaseClasses(m.status)">{{ m.status }}</span>
              <button v-if="m.status === 'pendente'" class="rounded-full bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep" @click="marcarMatriculaPaga(m)">Marcar como pago</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
