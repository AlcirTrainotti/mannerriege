<script setup>
import { ref, computed, onMounted, watch, defineAsyncComponent } from 'vue'
import { supabase } from '../../lib/supabase.js'
import PaginacaoControle from './PaginacaoControle.vue'
import UniformeFoto from './UniformeFoto.vue'

const AdminUniformePecas = defineAsyncComponent(() => import('./AdminUniformePecas.vue'))

const jogos = ref([])
const camisasPorJogo = ref({})
const bermudasPorJogo = ref({})
const participacoesPorJogo = ref({})
const titulosPorJogo = ref({})
const loading = ref(true)
const loadError = ref('')
const busca = ref('')
const paginaAtual = ref(1)
const porPagina = ref(10)
const savingId = ref(null)
const savedId = ref(null)
const removendoId = ref(null)
const confirmandoId = ref(null)

const jogoSelecionado = ref(null)

const showModal = ref(false)
const novoNome = ref('')
const novaDataConfeccao = ref('')
const salvandoNovo = ref(false)
const addError = ref('')

const fileInputNovo = ref(null)
const novaFoto = ref(null)
const novaFotoPreview = ref(null)

async function carregar() {
  loading.value = true
  loadError.value = ''

  const [jogosRes, pecasRes, emprestimosRes] = await Promise.all([
    supabase.from('jogos_uniforme').select('*').order('criado_em', { ascending: false }),
    supabase.from('uniformes').select('jogo_uniforme_id, tipo'),
    supabase.from('campeonato_emprestimos').select('jogo_uniforme_id, campeonato_id, campeonato_categorias(colocacao)').eq('tipo_ativo', 'conjunto_uniforme').not('jogo_uniforme_id', 'is', null),
  ])

  if (jogosRes.error) {
    loadError.value = jogosRes.error.message
    loading.value = false
    return
  }
  jogos.value = jogosRes.data

  // Quantidades calculadas a partir das pecas individuais cadastradas:
  // toda peca tem camiseta; so as do tipo "completo" tem bermuda tambem.
  const camisas = {}
  const bermudas = {}
  ;(pecasRes.data ?? []).forEach((p) => {
    if (!p.jogo_uniforme_id) return
    camisas[p.jogo_uniforme_id] = (camisas[p.jogo_uniforme_id] ?? 0) + 1
    if (p.tipo === 'completo') {
      bermudas[p.jogo_uniforme_id] = (bermudas[p.jogo_uniforme_id] ?? 0) + 1
    }
  })
  camisasPorJogo.value = camisas
  bermudasPorJogo.value = bermudas

  // Campeonatos participados e titulos: calculados automaticamente a
  // partir dos emprestimos do conjunto completo registrados em cada
  // campeonato (aba Empréstimos de cada campeonato).
  const participacoesSets = {}
  const titulos = {}
  ;(emprestimosRes.data ?? []).forEach((e) => {
    if (!e.jogo_uniforme_id) return
    if (!participacoesSets[e.jogo_uniforme_id]) participacoesSets[e.jogo_uniforme_id] = new Set()
    participacoesSets[e.jogo_uniforme_id].add(e.campeonato_id)
    if (e.campeonato_categorias?.colocacao === 'Campeão') {
      titulos[e.jogo_uniforme_id] = (titulos[e.jogo_uniforme_id] ?? 0) + 1
    }
  })
  const participacoes = {}
  Object.keys(participacoesSets).forEach((id) => { participacoes[id] = participacoesSets[id].size })
  participacoesPorJogo.value = participacoes
  titulosPorJogo.value = titulos

  loading.value = false
}

function anosEmUso(dataConfeccao) {
  if (!dataConfeccao) return null
  const inicio = new Date(dataConfeccao + 'T00:00:00')
  const hoje = new Date()
  let anos = hoje.getFullYear() - inicio.getFullYear()
  const aniversarioPassou = hoje.getMonth() > inicio.getMonth() ||
    (hoje.getMonth() === inicio.getMonth() && hoje.getDate() >= inicio.getDate())
  if (!aniversarioPassou) anos -= 1
  return Math.max(0, anos)
}

onMounted(carregar)

const filtrados = computed(() => {
  const termo = busca.value.trim().toLowerCase()
  if (!termo) return jogos.value
  return jogos.value.filter((j) => j.nome.toLowerCase().includes(termo))
})

const paginados = computed(() => {
  const ini = (paginaAtual.value - 1) * porPagina.value
  return filtrados.value.slice(ini, ini + porPagina.value)
})

watch(busca, () => { paginaAtual.value = 1 })

function abrirSeletorFotoNova() {
  fileInputNovo.value?.click()
}

function aoSelecionarFotoNova(e) {
  const file = e.target.files?.[0]
  if (!file) return
  if (file.size > 5 * 1024 * 1024) {
    addError.value = 'A imagem deve ter no máximo 5 MB.'
    e.target.value = ''
    return
  }
  novaFoto.value = file
  if (novaFotoPreview.value) URL.revokeObjectURL(novaFotoPreview.value)
  novaFotoPreview.value = URL.createObjectURL(file)
}

function limparFormNovo() {
  novoNome.value = ''
  novaDataConfeccao.value = ''
  novaFoto.value = null
  if (novaFotoPreview.value) { URL.revokeObjectURL(novaFotoPreview.value); novaFotoPreview.value = null }
}

async function adicionar() {
  addError.value = ''
  if (!novoNome.value.trim()) {
    addError.value = 'Preencha o nome do conjunto.'
    return
  }
  salvandoNovo.value = true

  const { data: inserido, error } = await supabase
    .from('jogos_uniforme')
    .insert({
      nome: novoNome.value.trim(),
      data_confeccao: novaDataConfeccao.value || null,
    })
    .select()
    .single()

  if (error) {
    salvandoNovo.value = false
    addError.value = error.message
    return
  }

  if (novaFoto.value) {
    const ext = novaFoto.value.name.split('.').pop()
    const caminho = `${inserido.id}/foto.${ext}`
    const { error: upError } = await supabase.storage
      .from('uniformes')
      .upload(caminho, novaFoto.value, { upsert: true, contentType: novaFoto.value.type })
    if (!upError) {
      const { data: pub } = supabase.storage.from('uniformes').getPublicUrl(caminho)
      await supabase.from('jogos_uniforme').update({ foto_url: pub.publicUrl + '?t=' + Date.now() }).eq('id', inserido.id)
    }
  }

  salvandoNovo.value = false
  showModal.value = false
  limparFormNovo()
  await carregar()
}

async function salvarCampo(jogo, campo, valor) {
  savingId.value = jogo.id + campo
  const { error } = await supabase.from('jogos_uniforme').update({ [campo]: valor }).eq('id', jogo.id)
  savingId.value = null
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  savedId.value = jogo.id + campo
  setTimeout(() => { if (savedId.value === jogo.id + campo) savedId.value = null }, 1500)
}

async function remover(id) {
  confirmandoId.value = null
  removendoId.value = id
  const { error } = await supabase.from('jogos_uniforme').delete().eq('id', id)
  removendoId.value = null
  if (error) {
    loadError.value = 'Não foi possível remover: ' + error.message
    return
  }
  jogos.value = jogos.value.filter((j) => j.id !== id)
}

function abrirJogo(j) {
  jogoSelecionado.value = j
}

function voltarLista() {
  jogoSelecionado.value = null
  carregar()
}
</script>

<template>
  <div>
    <AdminUniformePecas v-if="jogoSelecionado" :jogo="jogoSelecionado" @voltar="voltarLista" />

    <template v-else>
      <div class="flex flex-wrap items-center gap-3">
        <input
          v-model="busca"
          type="text"
          placeholder="Buscar por nome do conjunto..."
          class="min-w-0 flex-1 rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
        />
        <button
          class="flex-shrink-0 rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep"
          @click="showModal = true"
        >+ Novo conjunto</button>
      </div>

      <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
      <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

      <div v-else class="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <div v-if="filtrados.length === 0" class="col-span-full py-8 text-center text-sm text-ink-soft">Nenhum conjunto de uniforme cadastrado ainda.</div>

        <div v-for="j in paginados" :key="j.id" class="overflow-hidden rounded-2xl bg-white shadow-card">
          <UniformeFoto
            :jogo-id="j.id"
            :foto-url="j.foto_url"
            @update:foto-url="(url) => j.foto_url = url"
          />

          <div class="p-5">
            <input
              :value="j.nome"
              type="text"
              class="w-full rounded-lg border border-transparent bg-transparent px-0 py-0.5 font-display text-lg font-bold text-ink outline-none hover:border-ink/15 focus:border-brand focus:bg-paper-dim focus:px-2"
              @change="(e) => { j.nome = e.target.value; salvarCampo(j, 'nome', e.target.value) }"
            />

            <div class="mt-3 grid grid-cols-2 gap-2 text-center">
              <div class="rounded-lg bg-paper-dim py-2">
                <p class="font-display text-xl font-extrabold text-ink">{{ camisasPorJogo[j.id] ?? 0 }}</p>
                <p class="font-mono-label text-[9px] text-ink-soft">camisas</p>
              </div>
              <div class="rounded-lg bg-paper-dim py-2">
                <p class="font-display text-xl font-extrabold text-ink">{{ bermudasPorJogo[j.id] ?? 0 }}</p>
                <p class="font-mono-label text-[9px] text-ink-soft">bermudas</p>
              </div>
            </div>
            <p class="mt-1.5 text-center text-[10px] text-ink-soft/60">calculado a partir das peças cadastradas</p>

            <div class="mt-3 grid grid-cols-3 gap-2 text-center">
              <div class="rounded-lg bg-gold-soft py-2" title="Calculado a partir dos empréstimos registrados nos campeonatos">
                <p class="font-display text-lg font-extrabold text-ink">{{ participacoesPorJogo[j.id] ?? 0 }}</p>
                <p class="font-mono-label text-[8px] text-ink-soft">campeonatos</p>
              </div>
              <div class="rounded-lg bg-gold-soft py-2" title="Categorias em que este conjunto foi campeão">
                <p class="font-display text-lg font-extrabold text-ink">🏆 {{ titulosPorJogo[j.id] ?? 0 }}</p>
                <p class="font-mono-label text-[8px] text-ink-soft">títulos</p>
              </div>
              <div class="rounded-lg bg-gold-soft py-2">
                <p class="font-display text-lg font-extrabold text-ink">{{ anosEmUso(j.data_confeccao) ?? '—' }}</p>
                <p class="font-mono-label text-[8px] text-ink-soft">anos de uso</p>
              </div>
            </div>

            <div class="mt-3">
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Confeccionado em</label>
              <input
                :value="j.data_confeccao"
                type="date"
                class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
                @change="(e) => { j.data_confeccao = e.target.value; salvarCampo(j, 'data_confeccao', e.target.value) }"
              />
            </div>

            <div class="mt-4 flex items-center justify-between">
              <button
                class="rounded-full bg-ink px-4 py-2 text-xs font-semibold text-white hover:bg-ink/80"
                @click="abrirJogo(j)"
              >Ver peças</button>

              <div class="flex items-center gap-2">
                <span v-if="savingId?.startsWith(j.id)" class="text-xs text-ink-soft/60">salvando...</span>
                <span v-else-if="savedId?.startsWith(j.id)" class="text-xs text-brand-deep">salvo</span>

                <template v-if="confirmandoId === j.id">
                  <span class="text-xs text-ink-soft">Confirmar?</span>
                  <button class="text-xs font-bold text-brand-deep hover:underline" :disabled="removendoId === j.id" @click="remover(j.id)">
                    {{ removendoId === j.id ? '...' : 'sim' }}
                  </button>
                  <button class="text-xs text-ink-soft hover:underline" @click="confirmandoId = null">não</button>
                </template>
                <button v-else class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="confirmandoId = j.id">remover</button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <PaginacaoControle
        v-model:pagina="paginaAtual"
        v-model:por-pagina="porPagina"
        :total="filtrados.length"
      />

      <!-- Modal novo conjunto -->
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showModal = false; limparFormNovo()">
        <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
          <h2 class="font-display text-2xl font-extrabold text-ink">Novo conjunto de uniforme</h2>
          <p class="mt-1 text-xs text-ink-soft">A quantidade de camisas e bermudas é calculada automaticamente conforme você cadastrar cada peça individual.</p>

          <div class="mt-6 space-y-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nome do conjunto *</label>
              <input v-model="novoNome" type="text" placeholder="Ex: Uniforme Vermelho 2024" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Data de confecção</label>
              <input v-model="novaDataConfeccao" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Foto do uniforme</label>
              <div class="mt-1 flex items-center gap-3">
                <div class="h-16 w-16 flex-shrink-0 overflow-hidden rounded-lg bg-paper-dim">
                  <img v-if="novaFotoPreview" :src="novaFotoPreview" class="h-full w-full object-cover" alt="" />
                  <div v-else class="flex h-full w-full items-center justify-center text-ink-soft/40">
                    <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.5">
                      <path d="M3 16.5l4.5-4.5a2 2 0 012.8 0L15 16.5M3 8.5h18M5 4h14a2 2 0 012 2v12a2 2 0 01-2 2H5a2 2 0 01-2-2V6a2 2 0 012-2z" stroke-linecap="round" stroke-linejoin="round" />
                    </svg>
                  </div>
                </div>
                <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="abrirSeletorFotoNova">
                  {{ novaFoto ? 'Trocar imagem' : 'Importar imagem' }}
                </button>
                <input ref="fileInputNovo" type="file" accept="image/jpeg,image/png,image/webp" class="hidden" @change="aoSelecionarFotoNova" />
              </div>
            </div>
            <p v-if="addError" class="text-xs text-brand-deep">{{ addError }}</p>
          </div>

          <div class="mt-6 flex gap-3">
            <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="showModal = false; limparFormNovo()">Cancelar</button>
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
