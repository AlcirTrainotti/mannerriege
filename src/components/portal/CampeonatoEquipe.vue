<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { calcularCategoria } from '../../lib/categoria.js'
import { calcularRateio, statusPagamento } from '../../lib/historicoCampeonatos.js'
import {
  categoriaOptions, categoriaElegivel, funcaoOptions, brl, formatarDataCurta,
  colocacaoOptions, premiacaoTipoOptions, origemReceitaOptions, tipoDespesaOptions,
} from '../../data/campeonatos.js'
import CurrencyInput from './CurrencyInput.vue'

const props = defineProps({
  campeonato: { type: Object, required: true },
})

const categorias = ref([])
const participantes = ref([])
const associadosMap = ref({})
const convidadosMap = ref({})
const despesasPorCategoria = ref({})
const receitasPorCategoria = ref({})
const pagamentosPorParticipante = ref({}) // participanteId -> [{ id, valor, data_pagamento }]
const conflitosPorCategoria = ref({})
const loading = ref(true)
const loadError = ref('')

async function carregar() {
  loading.value = true
  loadError.value = ''

  const { data: cats, error: catsError } = await supabase
    .from('campeonato_categorias')
    .select('*')
    .eq('campeonato_id', props.campeonato.id)
    .order('categoria')

  if (catsError) {
    loadError.value = catsError.message
    loading.value = false
    return
  }
  categorias.value = cats
  const catIds = cats.map((c) => c.id)

  // Buscas independentes entre si rodam em paralelo, em vez de uma fila
  const [assocsRes, convsRes, confRes] = await Promise.all([
    supabase.rpc('listar_associados_basico'),
    supabase.from('convidados').select('id, nome, posicao, data_nascimento'),
    supabase.from('campeonato_conflitos').select('campeonato_categoria_id_a, campeonato_categoria_id_b').eq('campeonato_id', props.campeonato.id),
  ])

  const am = {}
  ;(assocsRes.data ?? []).forEach((a) => { am[a.id] = a })
  associadosMap.value = am

  const cm = {}
  ;(convsRes.data ?? []).forEach((c) => { cm[c.id] = c })
  convidadosMap.value = cm

  const contagemConflitos = {}
  ;(confRes.data ?? []).forEach((c) => {
    contagemConflitos[c.campeonato_categoria_id_a] = (contagemConflitos[c.campeonato_categoria_id_a] ?? 0) + 1
    contagemConflitos[c.campeonato_categoria_id_b] = (contagemConflitos[c.campeonato_categoria_id_b] ?? 0) + 1
  })
  conflitosPorCategoria.value = contagemConflitos

  if (catIds.length > 0) {
    const [partsRes, despRes, recRes] = await Promise.all([
      supabase.from('campeonato_participantes').select('*').in('campeonato_categoria_id', catIds),
      supabase.from('campeonato_categoria_despesas').select('*').in('campeonato_categoria_id', catIds).order('criado_em'),
      supabase.from('campeonato_categoria_receitas').select('*').in('campeonato_categoria_id', catIds).order('criado_em'),
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
        .order('data_pagamento')
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

function participantesDe(categoriaId) {
  return participantes.value.filter((p) => p.campeonato_categoria_id === categoriaId)
}

function nomeDe(p) {
  if (!p) return '—'
  if (p.tipo === 'associado') return associadosMap.value[p.associado_id]?.nome ?? '(associado removido)'
  return convidadosMap.value[p.convidado_id]?.nome ?? '(convidado removido)'
}

function nomeDoParticipante(participanteId) {
  if (!participanteId) return null
  return nomeDe(participantes.value.find((x) => x.id === participanteId))
}

function nascimentoDe(p) {
  if (p.tipo === 'associado') return associadosMap.value[p.associado_id]?.data_nascimento
  return convidadosMap.value[p.convidado_id]?.data_nascimento
}

function posicaoDe(p) {
  if (p.tipo === 'convidado') return convidadosMap.value[p.convidado_id]?.posicao
  return null
}

// Pessoas unicas cadastradas em QUALQUER categoria deste campeonato,
// usadas para selecionar quem assumiu uma despesa ou fez um aporte.
const pessoasDoCampeonato = computed(() => {
  const vistos = new Set()
  const lista = []
  participantes.value.forEach((p) => {
    const chave = p.tipo === 'associado' ? `a:${p.associado_id}` : `c:${p.convidado_id}`
    if (vistos.has(chave)) return
    vistos.add(chave)
    lista.push({ participanteId: p.id, nome: nomeDe(p) })
  })
  return lista.sort((a, b) => a.nome.localeCompare(b.nome))
})

function totalPagoDe(participanteId) {
  return (pagamentosPorParticipante.value[participanteId] ?? []).reduce((s, pg) => s + Number(pg.valor || 0), 0)
}

function rateioDe(categoria) {
  const atletas = participantesDe(categoria.id).filter((p) => p.funcao === 'atleta')
  return calcularRateio(categoria, despesasPorCategoria.value[categoria.id], receitasPorCategoria.value[categoria.id], atletas.length)
}

function capitaoDe(categoria) {
  if (!categoria.capitao_participante_id) return null
  return nomeDoParticipante(categoria.capitao_participante_id)
}

// --- Colocacao (lista + "outro") ---
function colocacaoSelectValor(cat) {
  if (!cat.colocacao) return ''
  return colocacaoOptions.includes(cat.colocacao) ? cat.colocacao : 'Outro'
}
function aoMudarColocacao(cat, valor) {
  if (valor === 'Outro') {
    salvarCampoCategoria(cat, 'colocacao', colocacaoOptions.includes(cat.colocacao) ? '' : (cat.colocacao || ''))
  } else {
    salvarCampoCategoria(cat, 'colocacao', valor)
  }
}

// --- Adicionar categoria ---
const showAddCategoria = ref(false)
const novaCategoria = ref('Livre')
const novoCusto = ref(0)
const salvandoCategoria = ref(false)
const categoriaError = ref('')

const categoriasDisponiveis = computed(() =>
  categoriaOptions.filter((c) => !categorias.value.some((existing) => existing.categoria === c))
)

async function adicionarCategoria() {
  categoriaError.value = ''
  salvandoCategoria.value = true
  const { error } = await supabase.from('campeonato_categorias').insert({
    campeonato_id: props.campeonato.id,
    categoria: novaCategoria.value,
    custo_inscricao: novoCusto.value || 0,
  })
  salvandoCategoria.value = false
  if (error) {
    categoriaError.value = error.message
    return
  }
  showAddCategoria.value = false
  novoCusto.value = 0
  await carregar()
}

async function removerCategoria(id) {
  if (!confirm('Remover esta categoria? Equipe, despesas e receitas cadastradas nela também serão removidas.')) return
  await supabase.from('campeonato_categorias').delete().eq('id', id)
  await carregar()
}

async function salvarCampoCategoria(categoria, campo, valor) {
  await supabase.from('campeonato_categorias').update({ [campo]: valor }).eq('id', categoria.id)
  categoria[campo] = valor
}

// --- Adicionar participante ---
const formAddParticipante = ref(null)
const novoTipoParticipante = ref('associado')
const novoParticipanteId = ref('')
const novaFuncao = ref('atleta')
const confirmaExcecaoCategoria = ref(false)
const salvandoParticipante = ref(false)

function abrirFormParticipante(categoriaId) {
  formAddParticipante.value = categoriaId
  novoTipoParticipante.value = 'associado'
  novoParticipanteId.value = ''
  novaFuncao.value = 'atleta'
  confirmaExcecaoCategoria.value = false
}

const associadosDisponiveisLista = computed(() => Object.entries(associadosMap.value).map(([id, a]) => ({ id, ...a })))
const convidadosDisponiveisLista = computed(() => Object.entries(convidadosMap.value).map(([id, c]) => ({ id, ...c })))

function nascimentoDoSelecionado() {
  if (!novoParticipanteId.value) return null
  if (novoTipoParticipante.value === 'associado') return associadosMap.value[novoParticipanteId.value]?.data_nascimento
  return convidadosMap.value[novoParticipanteId.value]?.data_nascimento
}

const categoriaAtualForm = computed(() => categorias.value.find((c) => c.id === formAddParticipante.value))

const violaCategoria = computed(() => {
  if (novaFuncao.value !== 'atleta') return false
  const nasc = nascimentoDoSelecionado()
  if (!nasc || !categoriaAtualForm.value) return false
  const catNatural = calcularCategoria(nasc)
  return !categoriaElegivel(catNatural, categoriaAtualForm.value.categoria)
})

watch([novoParticipanteId, novaFuncao], () => { confirmaExcecaoCategoria.value = false })

async function adicionarParticipante(categoriaId) {
  if (!novoParticipanteId.value) return
  if (violaCategoria.value && !confirmaExcecaoCategoria.value) return

  salvandoParticipante.value = true
  const payload = {
    campeonato_categoria_id: categoriaId,
    tipo: novoTipoParticipante.value,
    funcao: novaFuncao.value,
    associado_id: novoTipoParticipante.value === 'associado' ? novoParticipanteId.value : null,
    convidado_id: novoTipoParticipante.value === 'convidado' ? novoParticipanteId.value : null,
  }
  const { error } = await supabase.from('campeonato_participantes').insert(payload)
  salvandoParticipante.value = false
  if (error) {
    loadError.value = 'Não foi possível adicionar: ' + error.message
    return
  }
  formAddParticipante.value = null
  await carregar()
}

async function removerParticipante(id) {
  await supabase.from('campeonato_participantes').delete().eq('id', id)
  participantes.value = participantes.value.filter((p) => p.id !== id)
}

async function alternarMedalha(p) {
  const novoValor = !p.medalha_entregue
  await supabase.from('campeonato_participantes').update({ medalha_entregue: novoValor }).eq('id', p.id)
  p.medalha_entregue = novoValor
}

// --- Pagamentos (parciais) ---
const formPagamentoAberto = ref(null) // participanteId
const novoPagamentoValor = ref(0)
const novoPagamentoData = ref(new Date().toISOString().slice(0, 10))
const salvandoPagamento = ref(false)
const historicoAberto = ref(null) // participanteId

function abrirFormPagamento(participanteId, rateio) {
  formPagamentoAberto.value = participanteId
  const faltante = Math.max(0, rateio - totalPagoDe(participanteId))
  novoPagamentoValor.value = faltante
  novoPagamentoData.value = new Date().toISOString().slice(0, 10)
}

async function registrarPagamento(participanteId) {
  if (!novoPagamentoValor.value || novoPagamentoValor.value <= 0) return
  salvandoPagamento.value = true
  await supabase.from('campeonato_participante_pagamentos').insert({
    campeonato_participante_id: participanteId,
    valor: novoPagamentoValor.value,
    data_pagamento: novoPagamentoData.value,
  })
  salvandoPagamento.value = false
  formPagamentoAberto.value = null
  await carregar()
}

async function removerPagamento(pagamentoId, participanteId) {
  await supabase.from('campeonato_participante_pagamentos').delete().eq('id', pagamentoId)
  pagamentosPorParticipante.value[participanteId] = (pagamentosPorParticipante.value[participanteId] ?? []).filter((p) => p.id !== pagamentoId)
}

function statusClasses(status) {
  if (status === 'pago') return 'bg-[#EAF3DE] text-[#27500A]'
  if (status === 'parcial') return 'bg-gold-soft text-ink'
  if (status === 'sem_custo') return 'bg-ink/8 text-ink-soft'
  return 'bg-brand-soft text-brand-deep'
}
function statusLabel(status, rateio, totalPago) {
  if (status === 'pago') return '✓ pago'
  if (status === 'sem_custo') return 'sem custo'
  if (status === 'parcial') return `${brl(totalPago)} de ${brl(rateio)}`
  return `${brl(rateio)} pendente`
}

// --- Despesas ---
const formDespesaAberta = ref(null)
const novaDespesaDescricao = ref('')
const novaDespesaValor = ref(0)
const novaDespesaTipo = ref('rateado')
const novaDespesaAssumidoParticipanteId = ref('')
const salvandoDespesa = ref(false)

function abrirFormDespesa(categoriaId) {
  formDespesaAberta.value = categoriaId
  novaDespesaDescricao.value = ''
  novaDespesaValor.value = 0
  novaDespesaTipo.value = 'rateado'
  novaDespesaAssumidoParticipanteId.value = ''
}

async function adicionarDespesa(categoriaId) {
  if (!novaDespesaDescricao.value.trim()) return
  salvandoDespesa.value = true
  await supabase.from('campeonato_categoria_despesas').insert({
    campeonato_categoria_id: categoriaId,
    descricao: novaDespesaDescricao.value.trim(),
    valor: novaDespesaValor.value || 0,
    tipo: novaDespesaTipo.value,
    assumido_participante_id: novaDespesaTipo.value === 'assumido' ? (novaDespesaAssumidoParticipanteId.value || null) : null,
  })
  salvandoDespesa.value = false
  formDespesaAberta.value = null
  await carregar()
}

async function removerDespesa(id, categoriaId) {
  await supabase.from('campeonato_categoria_despesas').delete().eq('id', id)
  despesasPorCategoria.value[categoriaId] = (despesasPorCategoria.value[categoriaId] ?? []).filter((d) => d.id !== id)
}

// --- Receitas ---
const formReceitaAberta = ref(null)
const novaReceitaDescricao = ref('')
const novaReceitaValor = ref(0)
const novaReceitaOrigem = ref('associacao')
const novaReceitaAportadoParticipanteId = ref('')
const salvandoReceita = ref(false)

function abrirFormReceita(categoriaId) {
  formReceitaAberta.value = categoriaId
  novaReceitaDescricao.value = ''
  novaReceitaValor.value = 0
  novaReceitaOrigem.value = 'associacao'
  novaReceitaAportadoParticipanteId.value = ''
}

async function adicionarReceita(categoriaId) {
  if (!novaReceitaDescricao.value.trim()) return
  salvandoReceita.value = true
  await supabase.from('campeonato_categoria_receitas').insert({
    campeonato_categoria_id: categoriaId,
    descricao: novaReceitaDescricao.value.trim(),
    valor: novaReceitaValor.value || 0,
    origem: novaReceitaOrigem.value,
    aportado_participante_id: novaReceitaOrigem.value === 'aporte_pessoal' ? (novaReceitaAportadoParticipanteId.value || null) : null,
  })
  salvandoReceita.value = false
  formReceitaAberta.value = null
  await carregar()
}

async function removerReceita(id, categoriaId) {
  await supabase.from('campeonato_categoria_receitas').delete().eq('id', id)
  receitasPorCategoria.value[categoriaId] = (receitasPorCategoria.value[categoriaId] ?? []).filter((r) => r.id !== id)
}

function imprimir() {
  window.print()
}
</script>

<template>
  <div>
    <div class="flex flex-wrap items-center justify-between gap-3">
      <h3 class="font-display text-xl font-bold text-ink">Categorias inscritas</h3>
      <div class="flex gap-2">
        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="imprimir">
          🖨️ Imprimir relação
        </button>
        <button
          v-if="categoriasDisponiveis.length > 0"
          class="rounded-full bg-brand px-4 py-2 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep"
          @click="showAddCategoria = true"
        >+ Categoria</button>
      </div>
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>
    <p v-else-if="categorias.length === 0" class="mt-6 text-sm text-ink-soft">Nenhuma categoria inscrita ainda. Clique em "+ Categoria" para começar.</p>

    <div v-else class="mt-5 space-y-5">
      <div v-for="cat in categorias" :key="cat.id" class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div class="flex flex-wrap items-center gap-3">
            <span class="rounded-full bg-brand px-3 py-1 font-mono-label text-[11px] font-bold text-white">{{ cat.categoria }}</span>
            <div class="flex items-center gap-1.5 text-xs text-ink-soft">
              <span>Inscrição:</span>
              <CurrencyInput
                :model-value="cat.custo_inscricao"
                class="w-24 rounded-lg border border-ink/15 bg-white px-2 py-1 text-xs text-ink outline-none focus:border-brand"
                @update:model-value="(v) => salvarCampoCategoria(cat, 'custo_inscricao', v)"
              />
            </div>
            <span class="text-xs text-ink-soft">
              Rateio: <strong class="text-ink">{{ brl(rateioDe(cat)) }}</strong>/atleta
            </span>
            <span v-if="capitaoDe(cat)" class="rounded-full bg-gold-soft px-2.5 py-1 text-xs font-semibold text-ink">
              🎖️ {{ capitaoDe(cat) }}
            </span>
            <span v-if="conflitosPorCategoria[cat.id]" class="rounded-full bg-brand px-2.5 py-1 text-xs font-bold text-white" title="Veja os detalhes na aba Jogos e Conflitos">
              ⚠️ {{ conflitosPorCategoria[cat.id] }} conflito(s) de horário
            </span>
          </div>
          <button class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="removerCategoria(cat.id)">remover categoria</button>
        </div>

        <!-- Capitao -->
        <div class="mt-3">
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Capitão da categoria</label>
          <select
            :value="cat.capitao_participante_id"
            class="mt-1 w-full max-w-xs rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
            @change="(e) => salvarCampoCategoria(cat, 'capitao_participante_id', e.target.value || null)"
          >
            <option :value="null">Não definido</option>
            <option v-for="p in participantesDe(cat.id).filter((p) => p.funcao === 'atleta')" :key="p.id" :value="p.id">{{ nomeDe(p) }}</option>
          </select>
        </div>

        <!-- Atletas -->
        <div class="mt-4">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">ATLETAS</p>
          <div class="mt-2 divide-y divide-ink/8">
            <div v-for="p in participantesDe(cat.id).filter((p) => p.funcao === 'atleta')" :key="p.id" class="py-2">
              <div class="flex flex-wrap items-center justify-between gap-2 text-sm">
                <span class="text-ink">{{ nomeDe(p) }} <span v-if="p.tipo === 'convidado'" class="text-xs text-gold">· convidado</span></span>
                <div class="flex items-center gap-2">
                  <button
                    class="rounded-full px-2.5 py-1 text-[10px] font-bold"
                    :class="statusClasses(statusPagamento(totalPagoDe(p.id), rateioDe(cat)))"
                    @click="historicoAberto = historicoAberto === p.id ? null : p.id"
                  >{{ statusLabel(statusPagamento(totalPagoDe(p.id), rateioDe(cat)), rateioDe(cat), totalPagoDe(p.id)) }}</button>
                  <button v-if="statusPagamento(totalPagoDe(p.id), rateioDe(cat)) !== 'pago'" class="text-[10px] font-semibold text-brand-deep hover:underline" @click="abrirFormPagamento(p.id, rateioDe(cat))">
                    + pagamento
                  </button>
                  <label class="flex items-center gap-1 text-[10px] text-ink-soft">
                    <input type="checkbox" :checked="p.medalha_entregue" class="h-3.5 w-3.5 rounded border-ink/30" @change="alternarMedalha(p)" />
                    🏅
                  </label>
                  <button class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="removerParticipante(p.id)">remover</button>
                </div>
              </div>

              <!-- Form registrar pagamento -->
              <div v-if="formPagamentoAberto === p.id" class="mt-2 flex flex-wrap items-center gap-2 rounded-lg bg-paper-dim p-2.5">
                <CurrencyInput v-model="novoPagamentoValor" class="w-28 rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
                <input v-model="novoPagamentoData" type="date" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
                <button :disabled="salvandoPagamento" class="rounded-lg bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="registrarPagamento(p.id)">Salvar</button>
                <button class="rounded-lg border border-ink/15 px-3 py-1.5 text-xs text-ink-soft hover:border-ink/30" @click="formPagamentoAberto = null">Cancelar</button>
              </div>

              <!-- Historico de pagamentos -->
              <div v-if="historicoAberto === p.id && (pagamentosPorParticipante[p.id] ?? []).length > 0" class="mt-2 rounded-lg bg-paper-dim p-2.5">
                <p class="font-mono-label text-[9px] font-bold text-ink-soft">PAGAMENTOS REGISTRADOS</p>
                <div v-for="pg in pagamentosPorParticipante[p.id]" :key="pg.id" class="mt-1 flex items-center justify-between text-xs">
                  <span class="text-ink-soft">{{ formatarDataCurta(pg.data_pagamento) }}</span>
                  <span class="flex items-center gap-2 font-semibold text-ink">{{ brl(pg.valor) }}
                    <button class="text-ink-soft/40 hover:text-brand-deep" @click="removerPagamento(pg.id, p.id)">✕</button>
                  </span>
                </div>
              </div>
            </div>
            <p v-if="participantesDe(cat.id).filter((p) => p.funcao === 'atleta').length === 0" class="py-2 text-xs text-ink-soft/60">Nenhum atleta escalado ainda.</p>
          </div>
        </div>

        <!-- Comissao tecnica -->
        <div class="mt-4">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">COMISSÃO TÉCNICA</p>
          <div class="mt-2 divide-y divide-ink/8">
            <div v-for="p in participantesDe(cat.id).filter((p) => p.funcao === 'comissao_tecnica')" :key="p.id" class="flex items-center justify-between py-2 text-sm">
              <span class="text-ink">{{ nomeDe(p) }} <span v-if="p.tipo === 'convidado'" class="text-xs text-gold">· convidado</span></span>
              <div class="flex items-center gap-3">
                <label class="flex items-center gap-1 text-[10px] text-ink-soft">
                  <input type="checkbox" :checked="p.medalha_entregue" class="h-3.5 w-3.5 rounded border-ink/30" @change="alternarMedalha(p)" />
                  🏅
                </label>
                <button class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="removerParticipante(p.id)">remover</button>
              </div>
            </div>
            <p v-if="participantesDe(cat.id).filter((p) => p.funcao === 'comissao_tecnica').length === 0" class="py-2 text-xs text-ink-soft/60">Ninguém cadastrado ainda.</p>
          </div>
        </div>

        <!-- Form adicionar participante -->
        <div v-if="formAddParticipante === cat.id" class="mt-4 rounded-xl bg-paper-dim p-4">
          <div class="grid gap-2 sm:grid-cols-[110px_1fr_140px_auto]">
            <select v-model="novoTipoParticipante" class="rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand">
              <option value="associado">Associado</option>
              <option value="convidado">Convidado</option>
            </select>
            <select v-model="novoParticipanteId" class="rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand">
              <option value="" disabled>Selecione...</option>
              <option v-for="a in (novoTipoParticipante === 'associado' ? associadosDisponiveisLista : convidadosDisponiveisLista)" :key="a.id" :value="a.id">
                {{ a.nome }}
              </option>
            </select>
            <select v-model="novaFuncao" class="rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand">
              <option v-for="f in funcaoOptions" :key="f.value" :value="f.value">{{ f.label }}</option>
            </select>
            <div class="flex gap-2">
              <button
                :disabled="salvandoParticipante || !novoParticipanteId || (violaCategoria && !confirmaExcecaoCategoria)"
                class="rounded-lg bg-brand px-3 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50"
                @click="adicionarParticipante(cat.id)"
              >Add</button>
              <button class="rounded-lg border border-ink/15 px-3 py-2 text-xs text-ink-soft hover:border-ink/30" @click="formAddParticipante = null">✕</button>
            </div>
          </div>
          <div v-if="violaCategoria" class="mt-2 rounded-lg bg-brand-soft p-3">
            <p class="text-xs text-brand-deep">
              Esta pessoa nasceu em {{ formatarDataCurta(nascimentoDoSelecionado()) }} e a categoria mínima dela é
              <strong>{{ calcularCategoria(nascimentoDoSelecionado()) }}</strong> — mais jovem que <strong>{{ cat.categoria }}</strong>.
              Atletas mais jovens não podem subir de categoria, a não ser que o regulamento permita.
            </p>
            <label class="mt-2 flex items-center gap-2 text-xs text-brand-deep">
              <input v-model="confirmaExcecaoCategoria" type="checkbox" class="h-3.5 w-3.5 rounded border-brand-deep/40" />
              Confirmo que o regulamento deste campeonato permite essa exceção
            </label>
          </div>
        </div>
        <button v-else class="mt-4 text-xs font-semibold text-brand-deep hover:underline" @click="abrirFormParticipante(cat.id)">
          + adicionar participante
        </button>

        <!-- Premiacao -->
        <div class="mt-5 rounded-xl bg-paper-dim p-4">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">RESULTADO E PREMIAÇÃO</p>
          <div class="mt-2 grid gap-2 sm:grid-cols-3">
            <div>
              <select
                :value="colocacaoSelectValor(cat)"
                class="w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
                @change="(e) => aoMudarColocacao(cat, e.target.value)"
              >
                <option value="" disabled>Colocação...</option>
                <option v-for="c in colocacaoOptions" :key="c" :value="c">{{ c }}</option>
              </select>
              <input
                v-if="colocacaoSelectValor(cat) === 'Outro'"
                :value="cat.colocacao"
                type="text"
                placeholder="Descreva a colocação"
                class="mt-1.5 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
                @change="(e) => salvarCampoCategoria(cat, 'colocacao', e.target.value)"
              />
            </div>
            <select
              :value="cat.premiacao_tipo"
              class="rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => salvarCampoCategoria(cat, 'premiacao_tipo', e.target.value || null)"
            >
              <option :value="null">Sem premiação</option>
              <option v-for="t in premiacaoTipoOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
            </select>
            <CurrencyInput
              v-if="cat.premiacao_tipo === 'dinheiro'"
              :model-value="cat.premiacao_valor"
              class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @update:model-value="(v) => salvarCampoCategoria(cat, 'premiacao_valor', v)"
            />
            <input
              v-else
              :value="cat.premiacao_descricao"
              type="text"
              placeholder="Descrição do prêmio"
              class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => salvarCampoCategoria(cat, 'premiacao_descricao', e.target.value)"
            />
          </div>
        </div>

        <!-- Orcamento: despesas e receitas -->
        <div class="mt-4 grid gap-4 sm:grid-cols-2">
          <!-- Despesas -->
          <div class="rounded-xl bg-paper-dim p-4">
            <div class="flex items-center justify-between">
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">DESPESAS EXTRAS</p>
              <button class="text-xs font-semibold text-brand-deep hover:underline" @click="abrirFormDespesa(cat.id)">+ adicionar</button>
            </div>
            <div class="mt-2 space-y-1.5">
              <div v-for="d in despesasPorCategoria[cat.id] ?? []" :key="d.id" class="flex items-center justify-between text-xs">
                <span class="text-ink-soft">{{ d.descricao }}<span v-if="d.tipo === 'assumido'"> · {{ nomeDoParticipante(d.assumido_participante_id) || d.assumido_por || '—' }}</span></span>
                <span class="flex items-center gap-2 font-semibold text-ink">{{ brl(d.valor) }}
                  <button class="text-ink-soft/40 hover:text-brand-deep" @click="removerDespesa(d.id, cat.id)">✕</button>
                </span>
              </div>
              <p v-if="(despesasPorCategoria[cat.id] ?? []).length === 0" class="text-xs text-ink-soft/50">Nenhuma despesa extra.</p>
            </div>

            <div v-if="formDespesaAberta === cat.id" class="mt-3 space-y-2 border-t border-ink/10 pt-3">
              <input v-model="novaDespesaDescricao" type="text" placeholder="Ex: Água, taxa extra..." class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" />
              <CurrencyInput v-model="novaDespesaValor" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" />
              <select v-model="novaDespesaTipo" class="w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand">
                <option v-for="t in tipoDespesaOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
              </select>
              <select v-if="novaDespesaTipo === 'assumido'" v-model="novaDespesaAssumidoParticipanteId" class="w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand">
                <option value="">Quem assumiu...</option>
                <option v-for="pessoa in pessoasDoCampeonato" :key="pessoa.participanteId" :value="pessoa.participanteId">{{ pessoa.nome }}</option>
              </select>
              <div class="flex gap-2">
                <button :disabled="salvandoDespesa" class="rounded-lg bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionarDespesa(cat.id)">Salvar</button>
                <button class="rounded-lg border border-ink/15 px-3 py-1.5 text-xs text-ink-soft hover:border-ink/30" @click="formDespesaAberta = null">Cancelar</button>
              </div>
            </div>
          </div>

          <!-- Receitas -->
          <div class="rounded-xl bg-paper-dim p-4">
            <div class="flex items-center justify-between">
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">VERBA E APORTES</p>
              <button class="text-xs font-semibold text-brand-deep hover:underline" @click="abrirFormReceita(cat.id)">+ adicionar</button>
            </div>
            <div class="mt-2 space-y-1.5">
              <div v-for="r in receitasPorCategoria[cat.id] ?? []" :key="r.id" class="flex items-center justify-between text-xs">
                <span class="text-ink-soft">{{ r.descricao }}<span v-if="r.origem === 'aporte_pessoal'"> · {{ nomeDoParticipante(r.aportado_participante_id) || r.aportado_por || '—' }}</span></span>
                <span class="flex items-center gap-2 font-semibold text-[#27500A]">{{ brl(r.valor) }}
                  <button class="text-ink-soft/40 hover:text-brand-deep" @click="removerReceita(r.id, cat.id)">✕</button>
                </span>
              </div>
              <p v-if="(receitasPorCategoria[cat.id] ?? []).length === 0" class="text-xs text-ink-soft/50">Nenhuma verba ou aporte registrado.</p>
            </div>

            <div v-if="formReceitaAberta === cat.id" class="mt-3 space-y-2 border-t border-ink/10 pt-3">
              <input v-model="novaReceitaDescricao" type="text" placeholder="Ex: Verba da associação" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" />
              <CurrencyInput v-model="novaReceitaValor" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" />
              <select v-model="novaReceitaOrigem" class="w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand">
                <option v-for="o in origemReceitaOptions" :key="o.value" :value="o.value">{{ o.label }}</option>
              </select>
              <select v-if="novaReceitaOrigem === 'aporte_pessoal'" v-model="novaReceitaAportadoParticipanteId" class="w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand">
                <option value="">Quem aportou...</option>
                <option v-for="pessoa in pessoasDoCampeonato" :key="pessoa.participanteId" :value="pessoa.participanteId">{{ pessoa.nome }}</option>
              </select>
              <div class="flex gap-2">
                <button :disabled="salvandoReceita" class="rounded-lg bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionarReceita(cat.id)">Salvar</button>
                <button class="rounded-lg border border-ink/15 px-3 py-1.5 text-xs text-ink-soft hover:border-ink/30" @click="formReceitaAberta = null">Cancelar</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal nova categoria -->
    <div v-if="showAddCategoria" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showAddCategoria = false">
      <div class="w-full max-w-sm rounded-2xl bg-white p-8 shadow-card">
        <h2 class="font-display text-xl font-extrabold text-ink">Adicionar categoria</h2>
        <div class="mt-5 space-y-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Categoria</label>
            <select v-model="novaCategoria" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option v-for="c in categoriasDisponiveis" :key="c" :value="c">{{ c }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Custo de inscrição</label>
            <CurrencyInput v-model="novoCusto" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <p v-if="categoriaError" class="text-xs text-brand-deep">{{ categoriaError }}</p>
        </div>
        <div class="mt-6 flex gap-3">
          <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="showAddCategoria = false">Cancelar</button>
          <button :disabled="salvandoCategoria" class="flex-1 rounded-full bg-brand py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionarCategoria">
            {{ salvandoCategoria ? 'Salvando...' : 'Adicionar' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Area de impressao -->
    <div class="print-area hidden print:block">
      <h1 class="text-2xl font-bold">Mannerriege Vôlei Master</h1>
      <h2 class="mt-1 text-lg font-semibold">{{ campeonato.nome }}</h2>
      <p class="text-sm text-gray-600">
        <span v-if="campeonato.cidade || campeonato.estado">{{ campeonato.cidade }}<span v-if="campeonato.cidade && campeonato.estado">/</span>{{ campeonato.estado }} · </span>
        <span v-if="campeonato.data_inicio">{{ formatarDataCurta(campeonato.data_inicio) }}<span v-if="campeonato.data_fim"> a {{ formatarDataCurta(campeonato.data_fim) }}</span></span>
      </p>

      <div v-for="cat in categorias" :key="'print-' + cat.id" class="mt-6">
        <h3 class="border-b border-black pb-1 text-base font-bold">Categoria {{ cat.categoria }}</h3>
        <p v-if="capitaoDe(cat)" class="mt-1 text-sm">Capitão: {{ capitaoDe(cat) }}</p>

        <p class="mt-2 text-sm font-semibold">Atletas</p>
        <ol class="ml-5 list-decimal text-sm">
          <li v-for="p in participantesDe(cat.id).filter((p) => p.funcao === 'atleta')" :key="'pa-' + p.id">
            {{ nomeDe(p) }}<span v-if="posicaoDe(p)"> — {{ posicaoDe(p) }}</span>
          </li>
        </ol>

        <p class="mt-3 text-sm font-semibold">Comissão Técnica</p>
        <ol class="ml-5 list-decimal text-sm">
          <li v-for="p in participantesDe(cat.id).filter((p) => p.funcao === 'comissao_tecnica')" :key="'pc-' + p.id">
            {{ nomeDe(p) }}
          </li>
        </ol>
      </div>
    </div>
  </div>
</template>
