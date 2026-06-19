<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { estadoOptions, estadoClasses } from '../../data/inventario.js'
import PaginacaoControle from './PaginacaoControle.vue'

const bolas = ref([])
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
const novoModelo = ref('')
const novaMarca = ref('Mikasa')
const novoEstado = ref('bom')
const novoValor = ref('')
const novaData = ref('')
const salvandoNovo = ref(false)
const addError = ref('')

async function carregar() {
  loading.value = true
  loadError.value = ''
  const { data, error } = await supabase.from('bolas').select('*').order('criado_em')
  if (error) {
    loadError.value = error.message
  } else {
    bolas.value = data
  }
  loading.value = false
}

onMounted(carregar)

const filtrados = computed(() => {
  const termo = busca.value.trim().toLowerCase()
  if (!termo) return bolas.value
  return bolas.value.filter((b) =>
    (b.modelo ?? '').toLowerCase().includes(termo) ||
    (b.marca ?? '').toLowerCase().includes(termo)
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
  bolas.value.forEach((b) => { if (r[b.estado] !== undefined) r[b.estado]++ })
  return r
})

const valorTotal = computed(() =>
  bolas.value.reduce((soma, b) => soma + (Number(b.valor_pago) || 0), 0)
)

function brl(v) {
  return (v || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

async function adicionar() {
  addError.value = ''
  if (!novoModelo.value.trim()) {
    addError.value = 'Preencha ao menos o modelo.'
    return
  }
  salvandoNovo.value = true
  const { error } = await supabase.from('bolas').insert({
    modelo: novoModelo.value.trim(),
    marca: novaMarca.value.trim() || null,
    estado: novoEstado.value,
    valor_pago: novoValor.value ? Number(novoValor.value) : null,
    data_compra: novaData.value || null,
  })
  salvandoNovo.value = false
  if (error) {
    addError.value = error.message
    return
  }
  showModal.value = false
  novoModelo.value = ''
  novaMarca.value = 'Mikasa'
  novoEstado.value = 'bom'
  novoValor.value = ''
  novaData.value = ''
  await carregar()
}

async function salvarCampo(bola, campo, valor) {
  savingId.value = bola.id + campo
  const { error } = await supabase.from('bolas').update({ [campo]: valor }).eq('id', bola.id)
  savingId.value = null
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  savedId.value = bola.id + campo
  setTimeout(() => { if (savedId.value === bola.id + campo) savedId.value = null }, 1500)
}

async function remover(id) {
  confirmandoId.value = null
  removendoId.value = id
  const { error } = await supabase.from('bolas').delete().eq('id', id)
  removendoId.value = null
  if (error) {
    loadError.value = 'Não foi possível remover: ' + error.message
    return
  }
  bolas.value = bolas.value.filter((b) => b.id !== id)
}
</script>

<template>
  <div>
    <!-- Estatisticas -->
    <div class="grid gap-3 sm:grid-cols-3 lg:grid-cols-7">
      <div class="rounded-2xl bg-paper-dim p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">Total</p>
        <p class="mt-1 font-display text-2xl font-extrabold text-ink">{{ bolas.length }}</p>
      </div>
      <div v-for="e in estadoOptions" :key="e.value" class="rounded-2xl bg-paper-dim p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">{{ e.label }}</p>
        <p class="mt-1 font-display text-2xl font-extrabold text-ink">{{ resumoEstado[e.value] }}</p>
      </div>
      <div class="rounded-2xl bg-gold-soft p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">Valor investido</p>
        <p class="mt-1 font-display text-xl font-extrabold text-ink">{{ brl(valorTotal) }}</p>
      </div>
    </div>

    <div class="mt-8 flex flex-wrap items-center gap-3">
      <input
        v-model="busca"
        type="text"
        placeholder="Buscar por modelo ou marca..."
        class="min-w-0 flex-1 rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
      />
      <button
        class="flex-shrink-0 rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep"
        @click="showModal = true"
      >+ Nova bola</button>
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else class="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
      <div v-if="filtrados.length === 0" class="col-span-full py-8 text-center text-sm text-ink-soft">Nenhuma bola encontrada.</div>

      <div v-for="b in paginados" :key="b.id" class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex items-start justify-between gap-2">
          <input
            :value="b.modelo"
            type="text"
            class="w-full rounded-lg border border-transparent bg-transparent px-0 py-0.5 font-display text-lg font-bold text-ink outline-none hover:border-ink/15 focus:border-brand focus:bg-paper-dim focus:px-2"
            @change="(e) => { b.modelo = e.target.value; salvarCampo(b, 'modelo', e.target.value) }"
          />
          <span :class="['flex-shrink-0 rounded-full px-3 py-1 text-xs font-semibold', estadoClasses(b.estado)]">{{ b.estado }}</span>
        </div>

        <div class="mt-3 grid grid-cols-2 gap-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Marca</label>
            <input
              :value="b.marca"
              type="text"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { b.marca = e.target.value; salvarCampo(b, 'marca', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Estado</label>
            <select
              :value="b.estado"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { b.estado = e.target.value; salvarCampo(b, 'estado', e.target.value) }"
            >
              <option v-for="e in estadoOptions" :key="e.value" :value="e.value">{{ e.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Valor pago</label>
            <input
              :value="b.valor_pago"
              type="number"
              step="0.01"
              placeholder="0,00"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { b.valor_pago = e.target.value; salvarCampo(b, 'valor_pago', e.target.value ? Number(e.target.value) : null) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Data da compra</label>
            <input
              :value="b.data_compra"
              type="date"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { b.data_compra = e.target.value; salvarCampo(b, 'data_compra', e.target.value) }"
            />
          </div>
        </div>

        <div class="mt-3">
          <textarea
            :value="b.observacoes"
            rows="2"
            placeholder="Observações..."
            class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
            @change="(e) => { b.observacoes = e.target.value; salvarCampo(b, 'observacoes', e.target.value) }"
          ></textarea>
        </div>

        <div class="mt-3 flex items-center justify-between">
          <span v-if="savingId?.startsWith(b.id)" class="text-xs text-ink-soft/60">salvando...</span>
          <span v-else-if="savedId?.startsWith(b.id)" class="text-xs text-brand-deep">salvo</span>
          <span v-else></span>

          <template v-if="confirmandoId === b.id">
            <span class="text-xs text-ink-soft">Confirmar?</span>
            <button class="text-xs font-bold text-brand-deep hover:underline" :disabled="removendoId === b.id" @click="remover(b.id)">
              {{ removendoId === b.id ? 'removendo...' : 'sim, remover' }}
            </button>
            <button class="text-xs text-ink-soft hover:underline" @click="confirmandoId = null">cancelar</button>
          </template>
          <button v-else class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="confirmandoId = b.id">remover</button>
        </div>
      </div>
    </div>

    <PaginacaoControle
      v-model:pagina="paginaAtual"
      v-model:por-pagina="porPagina"
      :total="filtrados.length"
    />

    <!-- Modal nova bola -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showModal = false">
      <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
        <h2 class="font-display text-2xl font-extrabold text-ink">Nova bola</h2>

        <div class="mt-6 space-y-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Modelo *</label>
            <input v-model="novoModelo" type="text" placeholder="Ex: V200W" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Marca</label>
            <input v-model="novaMarca" type="text" placeholder="Mikasa, Penalty..." class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Valor pago</label>
              <input v-model="novoValor" type="number" step="0.01" placeholder="0,00" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Data da compra</label>
              <input v-model="novaData" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
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
