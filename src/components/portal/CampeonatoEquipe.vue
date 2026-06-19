<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { categoriaOptions, funcaoOptions, brl, formatarDataCurta } from '../../data/campeonatos.js'

const props = defineProps({
  campeonato: { type: Object, required: true },
})

const categorias = ref([])
const participantes = ref([]) // todos os participantes de todas as categorias deste campeonato
const associadosMap = ref({}) // id -> { nome, data_nascimento, modalidade }
const convidadosMap = ref({}) // id -> { nome, posicao }
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

  if (cats.length > 0) {
    const { data: parts } = await supabase
      .from('campeonato_participantes')
      .select('*')
      .in('campeonato_categoria_id', cats.map((c) => c.id))
    participantes.value = parts ?? []
  } else {
    participantes.value = []
  }

  const { data: assocs } = await supabase.rpc('listar_associados_basico')
  const am = {}
  ;(assocs ?? []).forEach((a) => { am[a.id] = a })
  associadosMap.value = am

  const { data: convs } = await supabase.from('convidados').select('id, nome, posicao')
  const cm = {}
  ;(convs ?? []).forEach((c) => { cm[c.id] = c })
  convidadosMap.value = cm

  loading.value = false
}

onMounted(carregar)

function participantesDe(categoriaId) {
  return participantes.value.filter((p) => p.campeonato_categoria_id === categoriaId)
}

function nomeDe(p) {
  if (p.tipo === 'associado') return associadosMap.value[p.associado_id]?.nome ?? '(associado removido)'
  return convidadosMap.value[p.convidado_id]?.nome ?? '(convidado removido)'
}

function posicaoDe(p) {
  if (p.tipo === 'convidado') return convidadosMap.value[p.convidado_id]?.posicao
  return null
}

function rateioDe(categoria) {
  const atletas = participantesDe(categoria.id).filter((p) => p.funcao === 'atleta')
  if (atletas.length === 0) return 0
  return Number(categoria.custo_inscricao || 0) / atletas.length
}

// --- Adicionar categoria ---
const showAddCategoria = ref(false)
const novaCategoria = ref('Livre')
const novoCusto = ref('')
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
    custo_inscricao: novoCusto.value ? Number(novoCusto.value) : 0,
  })
  salvandoCategoria.value = false
  if (error) {
    categoriaError.value = error.message
    return
  }
  showAddCategoria.value = false
  novoCusto.value = ''
  await carregar()
}

async function removerCategoria(id) {
  if (!confirm('Remover esta categoria? Os participantes cadastrados nela também serão removidos.')) return
  await supabase.from('campeonato_categorias').delete().eq('id', id)
  await carregar()
}

async function salvarCusto(categoria, valor) {
  await supabase.from('campeonato_categorias').update({ custo_inscricao: valor }).eq('id', categoria.id)
  categoria.custo_inscricao = valor
}

// --- Adicionar participante ---
const formAddParticipante = ref(null) // id da categoria com formulario aberto
const novoTipoParticipante = ref('associado')
const novoParticipanteId = ref('')
const novaFuncao = ref('atleta')
const salvandoParticipante = ref(false)

function abrirFormParticipante(categoriaId) {
  formAddParticipante.value = categoriaId
  novoTipoParticipante.value = 'associado'
  novoParticipanteId.value = ''
  novaFuncao.value = 'atleta'
}

const associadosDisponiveisLista = computed(() => Object.entries(associadosMap.value).map(([id, a]) => ({ id, ...a })))
const convidadosDisponiveisLista = computed(() => Object.entries(convidadosMap.value).map(([id, c]) => ({ id, ...c })))

async function adicionarParticipante(categoriaId) {
  if (!novoParticipanteId.value) return
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

// --- Impressao ---
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
          <div class="flex items-center gap-3">
            <span class="rounded-full bg-brand px-3 py-1 font-mono-label text-[11px] font-bold text-white">{{ cat.categoria }}</span>
            <div class="flex items-center gap-1.5 text-xs text-ink-soft">
              <span>Inscrição:</span>
              <input
                :value="cat.custo_inscricao"
                type="number"
                step="0.01"
                class="w-20 rounded-lg border border-ink/15 bg-white px-2 py-1 text-xs text-ink outline-none focus:border-brand"
                @change="(e) => salvarCusto(cat, Number(e.target.value) || 0)"
              />
            </div>
            <span class="text-xs text-ink-soft">
              Rateio por atleta: <strong class="text-ink">{{ brl(rateioDe(cat)) }}</strong>
            </span>
          </div>
          <button class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="removerCategoria(cat.id)">remover categoria</button>
        </div>

        <!-- Atletas -->
        <div class="mt-4">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">ATLETAS</p>
          <div class="mt-2 divide-y divide-ink/8">
            <div
              v-for="p in participantesDe(cat.id).filter((p) => p.funcao === 'atleta')"
              :key="p.id"
              class="flex items-center justify-between py-2 text-sm"
            >
              <span class="text-ink">{{ nomeDe(p) }} <span v-if="p.tipo === 'convidado'" class="text-xs text-gold">· convidado</span></span>
              <div class="flex items-center gap-3">
                <span class="text-xs text-ink-soft">{{ brl(rateioDe(cat)) }}</span>
                <button class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="removerParticipante(p.id)">remover</button>
              </div>
            </div>
            <p v-if="participantesDe(cat.id).filter((p) => p.funcao === 'atleta').length === 0" class="py-2 text-xs text-ink-soft/60">Nenhum atleta escalado ainda.</p>
          </div>
        </div>

        <!-- Comissao tecnica -->
        <div class="mt-4">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">COMISSÃO TÉCNICA</p>
          <div class="mt-2 divide-y divide-ink/8">
            <div
              v-for="p in participantesDe(cat.id).filter((p) => p.funcao === 'comissao_tecnica')"
              :key="p.id"
              class="flex items-center justify-between py-2 text-sm"
            >
              <span class="text-ink">{{ nomeDe(p) }} <span v-if="p.tipo === 'convidado'" class="text-xs text-gold">· convidado</span></span>
              <button class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="removerParticipante(p.id)">remover</button>
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
                :disabled="salvandoParticipante || !novoParticipanteId"
                class="rounded-lg bg-brand px-3 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50"
                @click="adicionarParticipante(cat.id)"
              >Add</button>
              <button class="rounded-lg border border-ink/15 px-3 py-2 text-xs text-ink-soft hover:border-ink/30" @click="formAddParticipante = null">✕</button>
            </div>
          </div>
        </div>
        <button v-else class="mt-4 text-xs font-semibold text-brand-deep hover:underline" @click="abrirFormParticipante(cat.id)">
          + adicionar participante
        </button>
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
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Custo de inscrição (R$)</label>
            <input v-model="novoCusto" type="number" step="0.01" placeholder="0,00" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
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
