<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { tamanhoOptions, tipoUniformeOptions, estadoOptions, estadoClasses } from '../../data/inventario.js'
import PaginacaoControle from './PaginacaoControle.vue'

const props = defineProps({
  jogo: { type: Object, required: true },
})
const emit = defineEmits(['voltar'])

const pecas = ref([])
const loading = ref(true)
const loadError = ref('')
const busca = ref('')
const savingId = ref(null)
const savedId = ref(null)
const removendoId = ref(null)
const confirmandoId = ref(null)
const paginaAtual = ref(1)
const porPagina = ref(10)

const showModal = ref(false)
const novoTipo = ref('completo')
const novoTamanho = ref('M')
const novoNumero = ref('')
const novoEstado = ref('bom')
const salvandoNovo = ref(false)
const addError = ref('')

async function carregar() {
  loading.value = true
  loadError.value = ''
  const { data, error } = await supabase
    .from('uniformes')
    .select('*')
    .eq('jogo_uniforme_id', props.jogo.id)
    .order('numero')
  if (error) {
    loadError.value = error.message
  } else {
    pecas.value = data
  }
  loading.value = false
}

onMounted(carregar)

const filtrados = computed(() => {
  const termo = busca.value.trim().toLowerCase()
  if (!termo) return pecas.value
  return pecas.value.filter((u) =>
    (u.numero ?? '').toLowerCase().includes(termo) ||
    (u.tamanho ?? '').toLowerCase().includes(termo)
  )
})

const paginados = computed(() => {
  const ini = (paginaAtual.value - 1) * porPagina.value
  return filtrados.value.slice(ini, ini + porPagina.value)
})

watch(busca, () => { paginaAtual.value = 1 })

const resumoEstado = computed(() => {
  const r = {}
  estadoOptions.forEach((e) => { r[e.value] = 0 })
  pecas.value.forEach((u) => { if (r[u.estado] !== undefined) r[u.estado]++ })
  return r
})

async function adicionar() {
  addError.value = ''
  salvandoNovo.value = true
  const { error } = await supabase.from('uniformes').insert({
    jogo_uniforme_id: props.jogo.id,
    tipo: novoTipo.value,
    tamanho: novoTamanho.value,
    numero: novoNumero.value.trim() || null,
    estado: novoEstado.value,
  })
  salvandoNovo.value = false
  if (error) {
    addError.value = error.message
    return
  }
  showModal.value = false
  novoTipo.value = 'completo'
  novoTamanho.value = 'M'
  novoNumero.value = ''
  novoEstado.value = 'bom'
  await carregar()
}

async function salvarCampo(peca, campo, valor) {
  savingId.value = peca.id + campo
  const { error } = await supabase.from('uniformes').update({ [campo]: valor }).eq('id', peca.id)
  savingId.value = null
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  savedId.value = peca.id + campo
  setTimeout(() => { if (savedId.value === peca.id + campo) savedId.value = null }, 1500)
}

async function remover(id) {
  confirmandoId.value = null
  removendoId.value = id
  const { error } = await supabase.from('uniformes').delete().eq('id', id)
  removendoId.value = null
  if (error) {
    loadError.value = 'Não foi possível remover: ' + error.message
    return
  }
  pecas.value = pecas.value.filter((u) => u.id !== id)
}
</script>

<template>
  <div>
    <button class="flex items-center gap-1.5 text-xs font-semibold text-ink-soft hover:text-brand-deep" @click="emit('voltar')">
      ← Voltar aos conjuntos
    </button>

    <div class="mt-3 flex items-center gap-3">
      <h2 class="font-display text-2xl font-extrabold text-ink">{{ jogo.nome }}</h2>
      <span class="rounded-full bg-gold-soft px-3 py-1 text-xs font-semibold text-ink">
        {{ pecas.length }} peça(s) cadastradas
      </span>
    </div>

    <!-- Estatisticas -->
    <div class="mt-5 grid gap-3 sm:grid-cols-3 lg:grid-cols-6">
      <div class="rounded-2xl bg-paper-dim p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">Total cadastrado</p>
        <p class="mt-1 font-display text-2xl font-extrabold text-ink">{{ pecas.length }}</p>
      </div>
      <div v-for="e in estadoOptions" :key="e.value" class="rounded-2xl bg-paper-dim p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">{{ e.label }}</p>
        <p class="mt-1 font-display text-2xl font-extrabold text-ink">{{ resumoEstado[e.value] }}</p>
      </div>
    </div>

    <div class="mt-6 flex flex-wrap items-center gap-3">
      <input
        v-model="busca"
        type="text"
        placeholder="Buscar por número ou tamanho..."
        class="min-w-0 flex-1 rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
      />
      <button
        class="flex-shrink-0 rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep"
        @click="showModal = true"
      >+ Nova peça</button>
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else class="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
      <div v-if="filtrados.length === 0" class="col-span-full py-8 text-center text-sm text-ink-soft">Nenhuma peça cadastrada ainda neste conjunto.</div>

      <div v-for="u in paginados" :key="u.id" class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex items-start justify-between gap-2">
          <div class="flex items-baseline gap-2">
            <span class="font-display text-3xl font-extrabold text-ink">{{ u.numero || '—' }}</span>
            <span class="text-xs text-ink-soft">nº</span>
          </div>
          <span :class="['rounded-full px-3 py-1 text-xs font-semibold', estadoClasses(u.estado)]">{{ u.estado }}</span>
        </div>

        <div class="mt-4 grid grid-cols-2 gap-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Tamanho</label>
            <select
              :value="u.tamanho"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { u.tamanho = e.target.value; salvarCampo(u, 'tamanho', e.target.value) }"
            >
              <option v-for="t in tamanhoOptions" :key="t" :value="t">{{ t }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Número</label>
            <input
              :value="u.numero"
              type="text"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { u.numero = e.target.value; salvarCampo(u, 'numero', e.target.value) }"
            />
          </div>
          <div class="col-span-2">
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Peças</label>
            <select
              :value="u.tipo"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { u.tipo = e.target.value; salvarCampo(u, 'tipo', e.target.value) }"
            >
              <option v-for="t in tipoUniformeOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
            </select>
          </div>
          <div class="col-span-2">
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Estado de conservação</label>
            <select
              :value="u.estado"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { u.estado = e.target.value; salvarCampo(u, 'estado', e.target.value) }"
            >
              <option v-for="e in estadoOptions" :key="e.value" :value="e.value">{{ e.label }}</option>
            </select>
          </div>
        </div>

        <div class="mt-3">
          <textarea
            :value="u.observacoes"
            rows="2"
            placeholder="Observações (ex: zíper preso, mancha leve...)"
            class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
            @change="(e) => { u.observacoes = e.target.value; salvarCampo(u, 'observacoes', e.target.value) }"
          ></textarea>
        </div>

        <div class="mt-3 flex items-center justify-between">
          <span v-if="savingId?.startsWith(u.id)" class="text-xs text-ink-soft/60">salvando...</span>
          <span v-else-if="savedId?.startsWith(u.id)" class="text-xs text-brand-deep">salvo</span>
          <span v-else></span>

          <template v-if="confirmandoId === u.id">
            <span class="text-xs text-ink-soft">Confirmar?</span>
            <button class="text-xs font-bold text-brand-deep hover:underline" :disabled="removendoId === u.id" @click="remover(u.id)">
              {{ removendoId === u.id ? 'removendo...' : 'sim, remover' }}
            </button>
            <button class="text-xs text-ink-soft hover:underline" @click="confirmandoId = null">cancelar</button>
          </template>
          <button v-else class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="confirmandoId = u.id">remover</button>
        </div>
      </div>
    </div>

    <PaginacaoControle
      v-model:pagina="paginaAtual"
      v-model:por-pagina="porPagina"
      :total="filtrados.length"
    />

    <!-- Modal nova peca -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showModal = false">
      <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
        <h2 class="font-display text-2xl font-extrabold text-ink">Nova peça — {{ jogo.nome }}</h2>

        <div class="mt-6 space-y-3">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Tamanho</label>
              <select v-model="novoTamanho" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
                <option v-for="t in tamanhoOptions" :key="t" :value="t">{{ t }}</option>
              </select>
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Número</label>
              <input v-model="novoNumero" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Peças</label>
            <select v-model="novoTipo" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option v-for="t in tipoUniformeOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Estado de conservação</label>
            <select v-model="novoEstado" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option v-for="e in estadoOptions" :key="e.value" :value="e.value">{{ e.label }}</option>
            </select>
          </div>
          <p v-if="addError" class="text-xs text-brand-deep">{{ addError }}</p>
        </div>

        <div class="mt-6 flex gap-3">
          <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="showModal = false">Cancelar</button>
          <button
            :disabled="salvandoNovo"
            class="flex-1 rounded-full bg-brand py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50"
            @click="adicionar"
          >{{ salvandoNovo ? 'Salvando...' : 'Cadastrar' }}</button>
        </div>
      </div>
    </div>
  </div>
</template>
