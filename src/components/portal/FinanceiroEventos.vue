<script setup>
import { ref, computed, onMounted, defineAsyncComponent } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { formatarDataCurta } from '../../data/campeonatos.js'
import PaginacaoControle from './PaginacaoControle.vue'

const EventoDetalhe = defineAsyncComponent(() => import('./EventoDetalhe.vue'))

const eventos = ref([])
const locaisDisponiveis = ref([])
const loading = ref(true)
const loadError = ref('')
const busca = ref('')
const paginaAtual = ref(1)
const porPagina = ref(10)
const removendoId = ref(null)
const confirmandoId = ref(null)

const eventoSelecionado = ref(null)

const showModal = ref(false)
const novoNome = ref('')
const novaData = ref('')
const novoLocalId = ref('')
const novasObservacoes = ref('')
const salvandoNovo = ref(false)
const addError = ref('')

async function carregar() {
  loading.value = true
  loadError.value = ''
  const [eventosRes, locaisRes] = await Promise.all([
    supabase.from('eventos').select('*').order('data', { ascending: false, nullsFirst: false }),
    supabase.from('locais_festa').select('id, nome'),
  ])
  if (eventosRes.error) {
    loadError.value = eventosRes.error.message
    loading.value = false
    return
  }
  eventos.value = eventosRes.data
  locaisDisponiveis.value = locaisRes.data ?? []
  loading.value = false
}

onMounted(carregar)

function nomeLocal(id) {
  return locaisDisponiveis.value.find((l) => l.id === id)?.nome ?? null
}

const filtrados = computed(() => {
  const termo = busca.value.trim().toLowerCase()
  if (!termo) return eventos.value
  return eventos.value.filter((e) => e.nome.toLowerCase().includes(termo))
})

const paginados = computed(() => {
  const ini = (paginaAtual.value - 1) * porPagina.value
  return filtrados.value.slice(ini, ini + porPagina.value)
})

async function adicionar() {
  addError.value = ''
  if (!novoNome.value.trim()) {
    addError.value = 'Preencha o nome do evento.'
    return
  }
  salvandoNovo.value = true
  const { error } = await supabase.from('eventos').insert({
    nome: novoNome.value.trim(),
    data: novaData.value || null,
    local_festa_id: novoLocalId.value || null,
    observacoes: novasObservacoes.value.trim() || null,
  })
  salvandoNovo.value = false
  if (error) {
    addError.value = error.message
    return
  }
  showModal.value = false
  novoNome.value = ''
  novaData.value = ''
  novoLocalId.value = ''
  novasObservacoes.value = ''
  await carregar()
}

async function remover(id) {
  confirmandoId.value = null
  removendoId.value = id
  const { error } = await supabase.from('eventos').delete().eq('id', id)
  removendoId.value = null
  if (error) {
    loadError.value = 'Não foi possível remover: ' + error.message
    return
  }
  eventos.value = eventos.value.filter((e) => e.id !== id)
}

function abrir(e) {
  eventoSelecionado.value = e
}

function voltar() {
  eventoSelecionado.value = null
}
</script>

<template>
  <div>
    <EventoDetalhe v-if="eventoSelecionado" :evento="eventoSelecionado" @voltar="voltar" />

    <template v-else>
      <div class="flex flex-wrap items-center gap-3">
        <input
          v-model="busca"
          type="text"
          placeholder="Buscar por nome do evento..."
          class="min-w-0 flex-1 rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
        />
        <button class="flex-shrink-0 rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep" @click="showModal = true">
          + Novo evento
        </button>
      </div>

      <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
      <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

      <div v-else class="mt-5 space-y-3">
        <div v-if="filtrados.length === 0" class="py-8 text-center text-sm text-ink-soft">Nenhum evento cadastrado ainda. Que tal começar pela costelada?</div>

        <div v-for="e in paginados" :key="e.id" class="rounded-2xl bg-white p-5 shadow-card">
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div class="cursor-pointer" @click="abrir(e)">
              <p class="font-display text-lg font-bold text-ink hover:text-brand-deep">{{ e.nome }}</p>
              <p class="mt-1 text-xs text-ink-soft">
                <span v-if="e.data">{{ formatarDataCurta(e.data) }}</span><span v-else>data a definir</span>
                <span v-if="nomeLocal(e.local_festa_id)"> · {{ nomeLocal(e.local_festa_id) }}</span>
              </p>
            </div>
            <div class="flex items-center gap-3">
              <button class="rounded-full bg-ink px-4 py-2 text-xs font-semibold text-white hover:bg-ink/80" @click="abrir(e)">Abrir</button>
              <template v-if="confirmandoId === e.id">
                <span class="text-xs text-ink-soft">Confirmar?</span>
                <button class="text-xs font-bold text-brand-deep hover:underline" :disabled="removendoId === e.id" @click="remover(e.id)">{{ removendoId === e.id ? '...' : 'sim' }}</button>
                <button class="text-xs text-ink-soft hover:underline" @click="confirmandoId = null">não</button>
              </template>
              <button v-else class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="confirmandoId = e.id">remover</button>
            </div>
          </div>
        </div>
      </div>

      <PaginacaoControle v-model:pagina="paginaAtual" v-model:por-pagina="porPagina" :total="filtrados.length" />

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showModal = false">
        <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
          <h2 class="font-display text-2xl font-extrabold text-ink">Novo evento</h2>
          <div class="mt-6 space-y-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nome do evento *</label>
              <input v-model="novoNome" type="text" placeholder="Ex: Costelada 2026" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Data</label>
              <input v-model="novaData" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Local</label>
              <select v-model="novoLocalId" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
                <option value="">Não definido</option>
                <option v-for="l in locaisDisponiveis" :key="l.id" :value="l.id">{{ l.nome }}</option>
              </select>
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Observações</label>
              <textarea v-model="novasObservacoes" rows="2" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"></textarea>
            </div>
            <p v-if="addError" class="text-xs text-brand-deep">{{ addError }}</p>
          </div>
          <div class="mt-6 flex gap-3">
            <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="showModal = false">Cancelar</button>
            <button :disabled="salvandoNovo" class="flex-1 rounded-full bg-brand py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionar">
              {{ salvandoNovo ? 'Salvando...' : 'Cadastrar' }}
            </button>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
