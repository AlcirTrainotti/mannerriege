<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { ufOptions, formatarDataCurta } from '../../data/campeonatos.js'
import PaginacaoControle from './PaginacaoControle.vue'
import CampeonatoDetalhe from './CampeonatoDetalhe.vue'

const campeonatos = ref([])
const loading = ref(true)
const loadError = ref('')
const busca = ref('')
const paginaAtual = ref(1)
const porPagina = ref(10)
const removendoId = ref(null)
const confirmandoId = ref(null)

const campeonatoSelecionado = ref(null)

const showModal = ref(false)
const novoNome = ref('')
const novaCidade = ref('')
const novoEstado = ref('SC')
const novoContatoNome = ref('')
const novoContatoTelefone = ref('')
const novoContatoEmail = ref('')
const novaDataInicio = ref('')
const novaDataFim = ref('')
const salvandoNovo = ref(false)
const addError = ref('')

async function carregar() {
  loading.value = true
  loadError.value = ''
  const { data, error } = await supabase
    .from('campeonatos')
    .select('*')
    .order('data_inicio', { ascending: false, nullsFirst: false })
  if (error) {
    loadError.value = error.message
  } else {
    campeonatos.value = data
  }
  loading.value = false
}

onMounted(carregar)

const filtrados = computed(() => {
  const termo = busca.value.trim().toLowerCase()
  if (!termo) return campeonatos.value
  return campeonatos.value.filter((c) =>
    c.nome.toLowerCase().includes(termo) ||
    (c.cidade ?? '').toLowerCase().includes(termo)
  )
})

const paginados = computed(() => {
  const ini = (paginaAtual.value - 1) * porPagina.value
  return filtrados.value.slice(ini, ini + porPagina.value)
})

watch(busca, () => { paginaAtual.value = 1 })

async function adicionar() {
  addError.value = ''
  if (!novoNome.value.trim()) {
    addError.value = 'Preencha ao menos o nome do campeonato.'
    return
  }
  salvandoNovo.value = true
  const { error } = await supabase.from('campeonatos').insert({
    nome: novoNome.value.trim(),
    cidade: novaCidade.value.trim() || null,
    estado: novoEstado.value || null,
    contato_nome: novoContatoNome.value.trim() || null,
    contato_telefone: novoContatoTelefone.value.trim() || null,
    contato_email: novoContatoEmail.value.trim() || null,
    data_inicio: novaDataInicio.value || null,
    data_fim: novaDataFim.value || null,
  })
  salvandoNovo.value = false
  if (error) {
    addError.value = error.message
    return
  }
  showModal.value = false
  novoNome.value = ''
  novaCidade.value = ''
  novoEstado.value = 'SC'
  novoContatoNome.value = ''
  novoContatoTelefone.value = ''
  novoContatoEmail.value = ''
  novaDataInicio.value = ''
  novaDataFim.value = ''
  await carregar()
}

async function remover(id) {
  confirmandoId.value = null
  removendoId.value = id
  const { error } = await supabase.from('campeonatos').delete().eq('id', id)
  removendoId.value = null
  if (error) {
    loadError.value = 'Não foi possível remover: ' + error.message
    return
  }
  campeonatos.value = campeonatos.value.filter((c) => c.id !== id)
}

function abrir(c) {
  campeonatoSelecionado.value = c
}

function voltar() {
  campeonatoSelecionado.value = null
  carregar()
}
</script>

<template>
  <div>
    <CampeonatoDetalhe v-if="campeonatoSelecionado" :campeonato="campeonatoSelecionado" @voltar="voltar" />

    <template v-else>
      <div class="flex flex-wrap items-center gap-3">
        <input
          v-model="busca"
          type="text"
          placeholder="Buscar por nome ou cidade..."
          class="min-w-0 flex-1 rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
        />
        <button
          class="flex-shrink-0 rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep"
          @click="showModal = true"
        >+ Novo campeonato</button>
      </div>

      <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
      <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

      <div v-else class="mt-5 space-y-3">
        <div v-if="filtrados.length === 0" class="py-8 text-center text-sm text-ink-soft">Nenhum campeonato cadastrado ainda.</div>

        <div v-for="c in paginados" :key="c.id" class="rounded-2xl bg-white p-5 shadow-card">
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div class="cursor-pointer" @click="abrir(c)">
              <p class="font-display text-lg font-bold text-ink hover:text-brand-deep">{{ c.nome }}</p>
              <p class="mt-1 text-xs text-ink-soft">
                <span v-if="c.cidade || c.estado">{{ c.cidade }}<span v-if="c.cidade && c.estado">/</span>{{ c.estado }} · </span>
                <span v-if="c.data_inicio">{{ formatarDataCurta(c.data_inicio) }}<span v-if="c.data_fim"> a {{ formatarDataCurta(c.data_fim) }}</span></span>
                <span v-else>data a definir</span>
              </p>
            </div>
            <div class="flex items-center gap-3">
              <button class="rounded-full bg-ink px-4 py-2 text-xs font-semibold text-white hover:bg-ink/80" @click="abrir(c)">Abrir</button>
              <template v-if="confirmandoId === c.id">
                <span class="text-xs text-ink-soft">Confirmar?</span>
                <button class="text-xs font-bold text-brand-deep hover:underline" :disabled="removendoId === c.id" @click="remover(c.id)">
                  {{ removendoId === c.id ? '...' : 'sim' }}
                </button>
                <button class="text-xs text-ink-soft hover:underline" @click="confirmandoId = null">não</button>
              </template>
              <button v-else class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="confirmandoId = c.id">remover</button>
            </div>
          </div>
        </div>
      </div>

      <PaginacaoControle
        v-model:pagina="paginaAtual"
        v-model:por-pagina="porPagina"
        :total="filtrados.length"
      />

      <!-- Modal novo campeonato -->
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showModal = false">
        <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
          <h2 class="font-display text-2xl font-extrabold text-ink">Novo campeonato</h2>
          <p class="mt-1 text-xs text-ink-soft">Categorias, equipe e empréstimos são cadastrados depois, dentro do campeonato.</p>

          <div class="mt-6 space-y-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nome do campeonato *</label>
              <input v-model="novoNome" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div class="grid grid-cols-[1fr_90px] gap-3">
              <div>
                <label class="font-mono-label text-[9px] font-bold text-ink-soft">Cidade</label>
                <input v-model="novaCidade" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
              </div>
              <div>
                <label class="font-mono-label text-[9px] font-bold text-ink-soft">UF</label>
                <select v-model="novoEstado" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-2 py-2.5 text-sm text-ink outline-none focus:border-brand">
                  <option v-for="uf in ufOptions" :key="uf" :value="uf">{{ uf }}</option>
                </select>
              </div>
            </div>
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="font-mono-label text-[9px] font-bold text-ink-soft">Início</label>
                <input v-model="novaDataInicio" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
              </div>
              <div>
                <label class="font-mono-label text-[9px] font-bold text-ink-soft">Fim</label>
                <input v-model="novaDataFim" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
              </div>
            </div>
            <div class="grid grid-cols-2 gap-3">
              <div>
                <label class="font-mono-label text-[9px] font-bold text-ink-soft">Contato</label>
                <input v-model="novoContatoNome" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
              </div>
              <div>
                <label class="font-mono-label text-[9px] font-bold text-ink-soft">Telefone</label>
                <input v-model="novoContatoTelefone" type="tel" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
              </div>
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">E-mail do contato</label>
              <input v-model="novoContatoEmail" type="email" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
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
    </template>
  </div>
</template>
