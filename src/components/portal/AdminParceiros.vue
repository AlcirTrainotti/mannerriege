<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import PaginacaoControle from './PaginacaoControle.vue'
import StarRating from './StarRating.vue'

const itens = ref([])
const loading = ref(true)
const loadError = ref('')
const busca = ref('')
const paginaAtual = ref(1)
const porPagina = ref(10)
const savingId = ref(null)
const savedId = ref(null)
const removendoId = ref(null)
const confirmandoId = ref(null)

const showModal = ref(false)
const novoNome = ref('')
const novoTipoParceria = ref('')
const novoContatoNome = ref('')
const novoContatoTelefone = ref('')
const novoContatoEmail = ref('')
const salvandoNovo = ref(false)
const addError = ref('')

async function carregar() {
  loading.value = true
  loadError.value = ''
  const { data, error } = await supabase.from('parceiros').select('*').order('nome')
  if (error) {
    loadError.value = error.message
  } else {
    itens.value = data
  }
  loading.value = false
}
onMounted(carregar)

const filtrados = computed(() => {
  const termo = busca.value.trim().toLowerCase()
  if (!termo) return itens.value
  return itens.value.filter((i) => i.nome.toLowerCase().includes(termo))
})
const paginados = computed(() => {
  const ini = (paginaAtual.value - 1) * porPagina.value
  return filtrados.value.slice(ini, ini + porPagina.value)
})

function limparForm() {
  novoNome.value = ''
  novoTipoParceria.value = ''
  novoContatoNome.value = ''
  novoContatoTelefone.value = ''
  novoContatoEmail.value = ''
  addError.value = ''
}

async function adicionar() {
  addError.value = ''
  if (!novoNome.value.trim()) {
    addError.value = 'Preencha ao menos o nome.'
    return
  }
  salvandoNovo.value = true
  const { error } = await supabase.from('parceiros').insert({
    nome: novoNome.value.trim(),
    tipo_parceria: novoTipoParceria.value.trim() || null,
    contato_nome: novoContatoNome.value.trim() || null,
    contato_telefone: novoContatoTelefone.value.trim() || null,
    contato_email: novoContatoEmail.value.trim() || null,
  })
  salvandoNovo.value = false
  if (error) {
    addError.value = error.message
    return
  }
  showModal.value = false
  limparForm()
  await carregar()
}

async function salvarCampo(item, campo, valor) {
  savingId.value = item.id + campo
  const { error } = await supabase.from('parceiros').update({ [campo]: valor }).eq('id', item.id)
  savingId.value = null
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  savedId.value = item.id + campo
  setTimeout(() => { if (savedId.value === item.id + campo) savedId.value = null }, 1500)
}

async function remover(id) {
  confirmandoId.value = null
  removendoId.value = id
  const { error } = await supabase.from('parceiros').delete().eq('id', id)
  removendoId.value = null
  if (error) {
    loadError.value = 'Não foi possível remover: ' + error.message
    return
  }
  itens.value = itens.value.filter((i) => i.id !== id)
}

// --- Historico de negociacoes ---
const historicoAberto = ref(null)
const negociacoesPorItem = ref({})
const carregandoNegociacoes = ref({})
const novaNegociacaoDescricao = ref('')
const novaNegociacaoData = ref(new Date().toISOString().slice(0, 10))
const salvandoNegociacao = ref(false)

async function alternarHistorico(id) {
  if (historicoAberto.value === id) {
    historicoAberto.value = null
    return
  }
  historicoAberto.value = id
  await carregarNegociacoes(id)
}

async function carregarNegociacoes(id) {
  carregandoNegociacoes.value = { ...carregandoNegociacoes.value, [id]: true }
  const { data } = await supabase.from('parceiro_negociacoes').select('*').eq('parceiro_id', id).order('data', { ascending: false })
  negociacoesPorItem.value = { ...negociacoesPorItem.value, [id]: data ?? [] }
  carregandoNegociacoes.value = { ...carregandoNegociacoes.value, [id]: false }
}

async function adicionarNegociacao(id) {
  if (!novaNegociacaoDescricao.value.trim()) return
  salvandoNegociacao.value = true
  await supabase.from('parceiro_negociacoes').insert({
    parceiro_id: id,
    descricao: novaNegociacaoDescricao.value.trim(),
    data: novaNegociacaoData.value,
  })
  salvandoNegociacao.value = false
  novaNegociacaoDescricao.value = ''
  novaNegociacaoData.value = new Date().toISOString().slice(0, 10)
  await carregarNegociacoes(id)
}

async function removerNegociacao(negId, parceiroId) {
  await supabase.from('parceiro_negociacoes').delete().eq('id', negId)
  negociacoesPorItem.value[parceiroId] = (negociacoesPorItem.value[parceiroId] ?? []).filter((n) => n.id !== negId)
}

function formatarData(d) {
  if (!d) return '—'
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR')
}
</script>

<template>
  <div>
    <div class="flex flex-wrap items-center gap-3">
      <input v-model="busca" type="text" placeholder="Buscar por nome..." class="min-w-0 flex-1 rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
      <button class="flex-shrink-0 rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep" @click="showModal = true">+ Novo parceiro</button>
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else class="mt-5 space-y-3">
      <div v-if="filtrados.length === 0" class="py-8 text-center text-sm text-ink-soft">Nenhum parceiro cadastrado ainda.</div>

      <div v-for="i in paginados" :key="i.id" class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex flex-wrap items-start justify-between gap-3">
          <input
            :value="i.nome" type="text"
            class="min-w-[180px] flex-1 rounded-lg border border-transparent bg-transparent px-0 py-0.5 text-sm font-semibold text-ink outline-none hover:border-ink/15 focus:border-brand focus:bg-paper-dim focus:px-2"
            @change="(e) => { i.nome = e.target.value; salvarCampo(i, 'nome', e.target.value) }"
          />
          <div class="flex items-center gap-2">
            <StarRating
              :model-value="i.avaliacao_nota || 0"
              @update:model-value="(v) => { i.avaliacao_nota = v; salvarCampo(i, 'avaliacao_nota', v || null) }"
            />
            <label class="flex items-center gap-1.5 text-xs text-ink-soft">
              <input type="checkbox" :checked="i.ativo" class="h-3.5 w-3.5 rounded border-ink/30" @change="(e) => { i.ativo = e.target.checked; salvarCampo(i, 'ativo', e.target.checked) }" />
              ativo
            </label>
            <span v-if="savingId?.startsWith(i.id)" class="text-xs text-ink-soft/60">salvando...</span>
            <span v-else-if="savedId?.startsWith(i.id)" class="text-xs text-brand-deep">salvo</span>
            <template v-if="confirmandoId === i.id">
              <button class="text-xs font-bold text-brand-deep hover:underline" :disabled="removendoId === i.id" @click="remover(i.id)">sim, remover</button>
              <button class="text-xs text-ink-soft hover:underline" @click="confirmandoId = null">cancelar</button>
            </template>
            <button v-else class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="confirmandoId = i.id">remover</button>
          </div>
        </div>

        <div class="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Tipo de parceria</label>
            <input :value="i.tipo_parceria" type="text" placeholder="Ex: desconto p/ associados" class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" @change="(e) => { i.tipo_parceria = e.target.value; salvarCampo(i, 'tipo_parceria', e.target.value) }" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Contato</label>
            <input :value="i.contato_nome" type="text" class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" @change="(e) => { i.contato_nome = e.target.value; salvarCampo(i, 'contato_nome', e.target.value) }" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Telefone</label>
            <input :value="i.contato_telefone" type="tel" class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" @change="(e) => { i.contato_telefone = e.target.value; salvarCampo(i, 'contato_telefone', e.target.value) }" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">E-mail</label>
            <input :value="i.contato_email" type="email" class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" @change="(e) => { i.contato_email = e.target.value; salvarCampo(i, 'contato_email', e.target.value) }" />
          </div>
        </div>

        <div class="mt-3">
          <button class="text-xs font-semibold text-brand-deep hover:underline" @click="alternarHistorico(i.id)">
            {{ historicoAberto === i.id ? 'ocultar histórico de negociações' : 'ver histórico de negociações' }}
          </button>

          <div v-if="historicoAberto === i.id" class="mt-2 rounded-xl bg-paper-dim p-3">
            <div class="flex flex-wrap items-center gap-2">
              <input v-model="novaNegociacaoDescricao" type="text" placeholder="Ex: Combinamos novo desconto para 2026" class="min-w-0 flex-1 rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand" />
              <input v-model="novaNegociacaoData" type="date" class="rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand" />
              <button :disabled="salvandoNegociacao" class="rounded-lg bg-brand px-3 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionarNegociacao(i.id)">+ registrar</button>
            </div>

            <p v-if="carregandoNegociacoes[i.id]" class="mt-2 text-xs text-ink-soft">Carregando...</p>
            <div v-else class="mt-2 space-y-1.5">
              <p v-if="(negociacoesPorItem[i.id] ?? []).length === 0" class="text-xs text-ink-soft/60">Nenhuma negociação registrada ainda.</p>
              <div v-for="n in negociacoesPorItem[i.id] ?? []" :key="n.id" class="flex items-center justify-between gap-2 text-xs">
                <span class="text-ink-soft"><strong class="text-ink">{{ formatarData(n.data) }}</strong> · {{ n.descricao }}</span>
                <button class="text-ink-soft/40 hover:text-brand-deep" @click="removerNegociacao(n.id, i.id)">✕</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <PaginacaoControle v-model:pagina="paginaAtual" v-model:por-pagina="porPagina" :total="filtrados.length" />

    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showModal = false; limparForm()">
      <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
        <h2 class="font-display text-2xl font-extrabold text-ink">Novo parceiro</h2>
        <div class="mt-6 space-y-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nome *</label>
            <input v-model="novoNome" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Tipo de parceria</label>
            <input v-model="novoTipoParceria" type="text" placeholder="Ex: desconto para associados" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
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
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">E-mail</label>
            <input v-model="novoContatoEmail" type="email" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <p v-if="addError" class="text-xs text-brand-deep">{{ addError }}</p>
        </div>
        <div class="mt-6 flex gap-3">
          <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="showModal = false; limparForm()">Cancelar</button>
          <button :disabled="salvandoNovo" class="flex-1 rounded-full bg-brand py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="adicionar">
            {{ salvandoNovo ? 'Salvando...' : 'Cadastrar' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
