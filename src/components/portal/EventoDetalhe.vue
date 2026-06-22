<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { brl } from '../../data/campeonatos.js'
import { useAuth } from '../../lib/useAuth.js'
import CurrencyInput from './CurrencyInput.vue'

const props = defineProps({
  evento: { type: Object, required: true },
})
const emit = defineEmits(['voltar'])

const { profile } = useAuth()

const despesas = ref([])
const receitas = ref([])
const participantes = ref([])
const associadosMap = ref({})
const convidadosMap = ref({})
const loading = ref(true)

async function carregar() {
  loading.value = true
  const [despRes, recRes, partRes, assocsRes, convsRes] = await Promise.all([
    supabase.from('evento_despesas').select('*').eq('evento_id', props.evento.id).order('criado_em'),
    supabase.from('evento_receitas').select('*').eq('evento_id', props.evento.id).order('criado_em'),
    supabase.from('evento_participantes').select('*').eq('evento_id', props.evento.id),
    supabase.rpc('listar_associados_basico'),
    supabase.from('convidados').select('id, nome'),
  ])
  despesas.value = despRes.data ?? []
  receitas.value = recRes.data ?? []
  participantes.value = partRes.data ?? []

  const am = {}
  ;(assocsRes.data ?? []).forEach((a) => { am[a.id] = a })
  associadosMap.value = am

  const cm = {}
  ;(convsRes.data ?? []).forEach((c) => { cm[c.id] = c })
  convidadosMap.value = cm

  loading.value = false
}

onMounted(carregar)

const totalDespesas = computed(() => despesas.value.reduce((s, d) => s + Number(d.valor || 0), 0))
const totalReceitas = computed(() => receitas.value.reduce((s, r) => s + Number(r.valor || 0), 0))
const saldo = computed(() => totalReceitas.value - totalDespesas.value)

const confirmados = computed(() => participantes.value.filter((p) => p.confirmado))
const rateioPorPessoa = computed(() => {
  if (!props.evento.custo_total || confirmados.value.length === 0) return 0
  return Number(props.evento.custo_total) / confirmados.value.length
})

function nomeDe(p) {
  if (p.tipo === 'associado') return associadosMap.value[p.associado_id]?.nome ?? '(associado removido)'
  return convidadosMap.value[p.convidado_id]?.nome ?? '(convidado removido)'
}

function formatarData(d) {
  if (!d) return 'data a definir'
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR', { day: '2-digit', month: 'long', year: 'numeric' })
}

// --- Despesas ---
const showDespesaForm = ref(false)
const novaDespesaDescricao = ref('')
const novaDespesaValor = ref(0)
const salvandoDespesa = ref(false)

async function adicionarDespesa() {
  if (!novaDespesaDescricao.value.trim()) return
  salvandoDespesa.value = true
  await supabase.from('evento_despesas').insert({
    evento_id: props.evento.id,
    descricao: novaDespesaDescricao.value.trim(),
    valor: novaDespesaValor.value || 0,
  })
  salvandoDespesa.value = false
  showDespesaForm.value = false
  novaDespesaDescricao.value = ''
  novaDespesaValor.value = 0
  await carregar()
}

async function removerDespesa(id) {
  await supabase.from('evento_despesas').delete().eq('id', id)
  despesas.value = despesas.value.filter((d) => d.id !== id)
}

// --- Receitas ---
const showReceitaForm = ref(false)
const novaReceitaDescricao = ref('')
const novaReceitaValor = ref(0)
const salvandoReceita = ref(false)

async function adicionarReceita() {
  if (!novaReceitaDescricao.value.trim()) return
  salvandoReceita.value = true
  await supabase.from('evento_receitas').insert({
    evento_id: props.evento.id,
    descricao: novaReceitaDescricao.value.trim(),
    valor: novaReceitaValor.value || 0,
  })
  salvandoReceita.value = false
  showReceitaForm.value = false
  novaReceitaDescricao.value = ''
  novaReceitaValor.value = 0
  await carregar()
}

async function removerReceita(id) {
  await supabase.from('evento_receitas').delete().eq('id', id)
  receitas.value = receitas.value.filter((r) => r.id !== id)
}

// --- Custo total a ratear ---
async function salvarCustoTotal(valor) {
  await supabase.from('eventos').update({ custo_total: valor }).eq('id', props.evento.id)
  props.evento.custo_total = valor
}

// --- Participantes ---
const formParticipanteAberto = ref(false)
const novoTipoParticipante = ref('associado')
const novoParticipanteId = ref('')
const salvandoParticipante = ref(false)

const associadosDisponiveisLista = computed(() => Object.entries(associadosMap.value).map(([id, a]) => ({ id, ...a })))
const convidadosDisponiveisLista = computed(() => Object.entries(convidadosMap.value).map(([id, c]) => ({ id, ...c })))

async function adicionarParticipante() {
  if (!novoParticipanteId.value) return
  salvandoParticipante.value = true
  await supabase.from('evento_participantes').insert({
    evento_id: props.evento.id,
    tipo: novoTipoParticipante.value,
    associado_id: novoTipoParticipante.value === 'associado' ? novoParticipanteId.value : null,
    convidado_id: novoTipoParticipante.value === 'convidado' ? novoParticipanteId.value : null,
  })
  salvandoParticipante.value = false
  formParticipanteAberto.value = false
  novoParticipanteId.value = ''
  await carregar()
}

async function removerParticipante(id) {
  await supabase.from('evento_participantes').delete().eq('id', id)
  participantes.value = participantes.value.filter((p) => p.id !== id)
}

async function alternarConfirmado(p) {
  const novoValor = !p.confirmado
  await supabase.from('evento_participantes').update({
    confirmado: novoValor,
    data_confirmacao: novoValor ? new Date().toISOString() : null,
  }).eq('id', p.id)
  p.confirmado = novoValor
}

async function alternarPago(p) {
  const novoValor = !p.pago
  await supabase.from('evento_participantes').update({
    pago: novoValor,
    data_pagamento: novoValor ? new Date().toISOString().slice(0, 10) : null,
  }).eq('id', p.id)
  p.pago = novoValor
}

// --- Fechamento ---
const fechando = ref(false)
const confirmandoFechamento = ref(false)

async function fecharEvento() {
  fechando.value = true
  await supabase.from('eventos').update({
    fechado: true,
    fechado_em: new Date().toISOString(),
    fechado_por: profile.value?.id ?? null,
  }).eq('id', props.evento.id)
  props.evento.fechado = true
  props.evento.fechado_em = new Date().toISOString()
  fechando.value = false
  confirmandoFechamento.value = false
}

async function reabrirEvento() {
  await supabase.from('eventos').update({ fechado: false, fechado_em: null }).eq('id', props.evento.id)
  props.evento.fechado = false
  props.evento.fechado_em = null
}
</script>

<template>
  <div>
    <button class="flex items-center gap-1.5 text-xs font-semibold text-ink-soft hover:text-brand-deep" @click="emit('voltar')">
      ← Voltar aos eventos
    </button>

    <div class="mt-3 rounded-2xl bg-white p-6 shadow-card">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <div>
          <div class="flex items-center gap-2">
            <h2 class="font-display text-2xl font-extrabold text-ink">{{ evento.nome }}</h2>
            <span v-if="evento.fechado" class="rounded-full bg-ink/10 px-3 py-1 text-xs font-bold text-ink-soft">🔒 Fechado</span>
          </div>
          <p class="mt-1 text-sm text-ink-soft">{{ formatarData(evento.data) }}</p>
        </div>
        <span class="font-display text-2xl font-extrabold" :class="saldo >= 0 ? 'text-[#27500A]' : 'text-brand-deep'">
          Saldo: {{ brl(saldo) }}
        </span>
      </div>

      <div v-if="evento.fechado" class="mt-3 rounded-xl bg-[#EAF3DE] p-3 text-xs text-[#27500A]">
        Evento fechado em {{ new Date(evento.fechado_em).toLocaleDateString('pt-BR') }}. Os lançamentos ficam travados.
        <button class="ml-1 font-bold underline" @click="reabrirEvento">reabrir para editar</button>
      </div>
      <div v-else class="mt-4 flex flex-wrap items-center justify-between gap-3">
        <template v-if="confirmandoFechamento">
          <span class="text-xs text-ink-soft">Fechar o evento e travar os lançamentos?</span>
          <div class="flex gap-2">
            <button :disabled="fechando" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="fecharEvento">
              {{ fechando ? 'Fechando...' : 'Sim, fechar' }}
            </button>
            <button class="rounded-full border border-ink/15 px-4 py-2 text-xs text-ink-soft hover:border-ink/30" @click="confirmandoFechamento = false">Cancelar</button>
          </div>
        </template>
        <button v-else class="rounded-full bg-ink px-4 py-2 text-xs font-semibold text-white hover:bg-ink/80" @click="confirmandoFechamento = true">
          🔒 Fechar e fazer prestação de contas
        </button>
      </div>
    </div>

    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <template v-else>
      <!-- Despesas e Receitas -->
      <div class="mt-5 grid gap-5 lg:grid-cols-2">
        <div class="rounded-2xl bg-white p-5 shadow-card">
          <div class="flex items-center justify-between">
            <h3 class="font-display text-lg font-bold text-ink">Despesas</h3>
            <button v-if="!evento.fechado" class="text-xs font-semibold text-brand-deep hover:underline" @click="showDespesaForm = !showDespesaForm">+ adicionar</button>
          </div>
          <p class="mt-2 font-display text-xl font-extrabold text-brand-deep">{{ brl(totalDespesas) }}</p>

          <div v-if="showDespesaForm" class="mt-3 space-y-2 rounded-xl bg-paper-dim p-3">
            <input v-model="novaDespesaDescricao" type="text" placeholder="Descrição" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" />
            <CurrencyInput v-model="novaDespesaValor" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" />
            <div class="flex gap-2">
              <button :disabled="salvandoDespesa" class="rounded-lg bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionarDespesa">Salvar</button>
              <button class="rounded-lg border border-ink/15 px-3 py-1.5 text-xs text-ink-soft hover:border-ink/30" @click="showDespesaForm = false">Cancelar</button>
            </div>
          </div>

          <div class="mt-3 divide-y divide-ink/8">
            <div v-if="despesas.length === 0" class="py-4 text-center text-xs text-ink-soft">Nenhuma despesa lançada.</div>
            <div v-for="d in despesas" :key="d.id" class="flex items-center justify-between py-2 text-sm">
              <span class="text-ink-soft">{{ d.descricao }}</span>
              <span class="flex items-center gap-2 font-semibold text-ink">{{ brl(d.valor) }}
                <button v-if="!evento.fechado" class="text-ink-soft/40 hover:text-brand-deep" @click="removerDespesa(d.id)">✕</button>
              </span>
            </div>
          </div>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow-card">
          <div class="flex items-center justify-between">
            <h3 class="font-display text-lg font-bold text-ink">Receitas</h3>
            <button v-if="!evento.fechado" class="text-xs font-semibold text-brand-deep hover:underline" @click="showReceitaForm = !showReceitaForm">+ adicionar</button>
          </div>
          <p class="mt-2 font-display text-xl font-extrabold text-[#27500A]">{{ brl(totalReceitas) }}</p>

          <div v-if="showReceitaForm" class="mt-3 space-y-2 rounded-xl bg-paper-dim p-3">
            <input v-model="novaReceitaDescricao" type="text" placeholder="Descrição" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" />
            <CurrencyInput v-model="novaReceitaValor" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" />
            <div class="flex gap-2">
              <button :disabled="salvandoReceita" class="rounded-lg bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionarReceita">Salvar</button>
              <button class="rounded-lg border border-ink/15 px-3 py-1.5 text-xs text-ink-soft hover:border-ink/30" @click="showReceitaForm = false">Cancelar</button>
            </div>
          </div>

          <div class="mt-3 divide-y divide-ink/8">
            <div v-if="receitas.length === 0" class="py-4 text-center text-xs text-ink-soft">Nenhuma receita lançada.</div>
            <div v-for="r in receitas" :key="r.id" class="flex items-center justify-between py-2 text-sm">
              <span class="text-ink-soft">{{ r.descricao }}</span>
              <span class="flex items-center gap-2 font-semibold text-[#27500A]">{{ brl(r.valor) }}
                <button v-if="!evento.fechado" class="text-ink-soft/40 hover:text-brand-deep" @click="removerReceita(r.id)">✕</button>
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Convidados / Participantes -->
      <div class="mt-5 rounded-2xl bg-white p-5 shadow-card">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h3 class="font-display text-lg font-bold text-ink">Convidados do evento</h3>
            <p class="text-xs text-ink-soft">{{ confirmados.length }} confirmado(s) de {{ participantes.length }} convidado(s)</p>
          </div>
          <div class="flex items-center gap-2 text-xs text-ink-soft">
            <span>Custo a ratear:</span>
            <CurrencyInput
              :model-value="evento.custo_total"
              :disabled="evento.fechado"
              class="w-28 rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand"
              @update:model-value="salvarCustoTotal"
            />
            <span v-if="rateioPorPessoa > 0">= {{ brl(rateioPorPessoa) }}/pessoa</span>
          </div>
        </div>

        <div class="mt-4 divide-y divide-ink/8">
          <div v-if="participantes.length === 0" class="py-4 text-center text-xs text-ink-soft">Nenhum convidado adicionado ainda.</div>
          <div v-for="p in participantes" :key="p.id" class="flex flex-wrap items-center justify-between gap-2 py-2.5 text-sm">
            <span class="text-ink">{{ nomeDe(p) }} <span v-if="p.tipo === 'convidado'" class="text-xs text-gold">· convidado</span></span>
            <div class="flex items-center gap-2">
              <button
                class="rounded-full px-2.5 py-1 text-[10px] font-bold"
                :class="p.confirmado ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-paper-dim text-ink-soft'"
                @click="alternarConfirmado(p)"
              >{{ p.confirmado ? '✓ confirmado' : 'aguardando' }}</button>
              <button
                v-if="rateioPorPessoa > 0 && p.confirmado"
                class="rounded-full px-2.5 py-1 text-[10px] font-bold"
                :class="p.pago ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-brand-soft text-brand-deep'"
                @click="alternarPago(p)"
              >{{ p.pago ? '✓ pago' : brl(rateioPorPessoa) + ' pendente' }}</button>
              <button v-if="!evento.fechado" class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="removerParticipante(p.id)">remover</button>
            </div>
          </div>
        </div>

        <div v-if="!evento.fechado" class="mt-4">
          <div v-if="formParticipanteAberto" class="rounded-xl bg-paper-dim p-3">
            <div class="grid gap-2 sm:grid-cols-[110px_1fr_auto]">
              <select v-model="novoTipoParticipante" class="rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand">
                <option value="associado">Associado</option>
                <option value="convidado">Convidado</option>
              </select>
              <select v-model="novoParticipanteId" class="rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand">
                <option value="" disabled>Selecione...</option>
                <option v-for="a in (novoTipoParticipante === 'associado' ? associadosDisponiveisLista : convidadosDisponiveisLista)" :key="a.id" :value="a.id">{{ a.nome }}</option>
              </select>
              <div class="flex gap-2">
                <button :disabled="salvandoParticipante || !novoParticipanteId" class="rounded-lg bg-brand px-3 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionarParticipante">Add</button>
                <button class="rounded-lg border border-ink/15 px-3 py-2 text-xs text-ink-soft hover:border-ink/30" @click="formParticipanteAberto = false">✕</button>
              </div>
            </div>
          </div>
          <button v-else class="text-xs font-semibold text-brand-deep hover:underline" @click="formParticipanteAberto = true">+ adicionar convidado</button>
        </div>
      </div>
    </template>
  </div>
</template>
