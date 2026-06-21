<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { tipoAtivoOptions } from '../../data/campeonatos.js'

const props = defineProps({
  campeonato: { type: Object, required: true },
})

const emprestimos = ref([])
const uniformesDisponiveis = ref([])
const bolasDisponiveis = ref([])
const jogosUniformeDisponiveis = ref([])
const categorias = ref([])
const responsaveisElegiveis = ref([])
const loading = ref(true)
const loadError = ref('')

async function carregar() {
  loading.value = true
  loadError.value = ''

  const [empRes, unisRes, blsRes, jogosRes, catsRes, elegiveisRes] = await Promise.all([
    supabase.from('campeonato_emprestimos').select('*').eq('campeonato_id', props.campeonato.id).order('criado_em', { ascending: false }),
    supabase.from('uniformes').select('id, numero, tamanho, jogos_uniforme(nome)'),
    supabase.from('bolas').select('id, modelo, marca'),
    supabase.from('jogos_uniforme').select('id, nome'),
    supabase.from('campeonato_categorias').select('id, categoria').eq('campeonato_id', props.campeonato.id).order('categoria'),
    supabase.rpc('listar_responsaveis_elegiveis', { p_campeonato_id: props.campeonato.id }),
  ])

  if (empRes.error) {
    loadError.value = empRes.error.message
    loading.value = false
    return
  }
  emprestimos.value = empRes.data
  uniformesDisponiveis.value = unisRes.data ?? []
  bolasDisponiveis.value = blsRes.data ?? []
  jogosUniformeDisponiveis.value = jogosRes.data ?? []
  categorias.value = catsRes.data ?? []
  responsaveisElegiveis.value = elegiveisRes.data ?? []

  loading.value = false
}

onMounted(carregar)

function nomeUniforme(id) {
  const u = uniformesDisponiveis.value.find((x) => x.id === id)
  if (!u) return '(uniforme removido)'
  return `Nº ${u.numero || '—'} · ${u.tamanho || '—'}${u.jogos_uniforme?.nome ? ' · ' + u.jogos_uniforme.nome : ''}`
}

function nomeBola(id) {
  const b = bolasDisponiveis.value.find((x) => x.id === id)
  if (!b) return '(bola removida)'
  return `${b.modelo}${b.marca ? ' · ' + b.marca : ''}`
}

function nomeConjunto(id) {
  const j = jogosUniformeDisponiveis.value.find((x) => x.id === id)
  return j ? `${j.nome} (conjunto completo)` : '(conjunto removido)'
}

function nomeAtivo(emp) {
  if (emp.tipo_ativo === 'uniforme') return nomeUniforme(emp.uniforme_id)
  if (emp.tipo_ativo === 'bola') return nomeBola(emp.bola_id)
  return nomeConjunto(emp.jogo_uniforme_id)
}

function nomeCategoria(id) {
  return categorias.value.find((c) => c.id === id)?.categoria ?? null
}

function formatarDataHora(iso) {
  if (!iso) return '—'
  return new Date(iso).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
}

// --- Novo emprestimo ---
const showModal = ref(false)
const novoTipoAtivo = ref('conjunto_uniforme')
const novoAtivoId = ref('')
const novaCategoriaId = ref('')
const novoResponsavel = ref('')
const confirmaRetirada = ref(false)
const salvandoNovo = ref(false)
const addError = ref('')

function limparForm() {
  novoTipoAtivo.value = 'conjunto_uniforme'
  novoAtivoId.value = ''
  novaCategoriaId.value = ''
  novoResponsavel.value = ''
  confirmaRetirada.value = false
  addError.value = ''
}

async function registrarRetirada() {
  addError.value = ''
  if (!novoAtivoId.value || !novoResponsavel.value.trim() || !confirmaRetirada.value) {
    addError.value = 'Selecione o item, informe o responsável e confirme a retirada.'
    return
  }
  salvandoNovo.value = true
  const { error } = await supabase.from('campeonato_emprestimos').insert({
    campeonato_id: props.campeonato.id,
    campeonato_categoria_id: novaCategoriaId.value || null,
    tipo_ativo: novoTipoAtivo.value,
    uniforme_id: novoTipoAtivo.value === 'uniforme' ? novoAtivoId.value : null,
    bola_id: novoTipoAtivo.value === 'bola' ? novoAtivoId.value : null,
    jogo_uniforme_id: novoTipoAtivo.value === 'conjunto_uniforme' ? novoAtivoId.value : null,
    responsavel_nome: novoResponsavel.value.trim(),
    retirado_em: new Date().toISOString(),
    visto_retirada: true,
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

// --- Devolucao ---
const devolucaoAbertaId = ref(null)
const devolucaoResponsavel = ref('')
const devolucaoConfirma = ref(false)
const devolucaoFoto = ref(null)
const devolucaoFotoPreview = ref(null)
const devolvendo = ref(false)
const devolucaoError = ref('')
const fileInputDevolucao = ref(null)

function abrirDevolucao(emp) {
  devolucaoAbertaId.value = emp.id
  devolucaoResponsavel.value = emp.responsavel_nome
  devolucaoConfirma.value = false
  devolucaoFoto.value = null
  devolucaoFotoPreview.value = null
  devolucaoError.value = ''
}

function fecharDevolucao() {
  devolucaoAbertaId.value = null
}

function aoSelecionarFotoDevolucao(e) {
  const file = e.target.files?.[0]
  if (!file) return
  if (file.size > 5 * 1024 * 1024) {
    devolucaoError.value = 'A foto deve ter no máximo 5 MB.'
    return
  }
  devolucaoFoto.value = file
  if (devolucaoFotoPreview.value) URL.revokeObjectURL(devolucaoFotoPreview.value)
  devolucaoFotoPreview.value = URL.createObjectURL(file)
}

async function confirmarDevolucao(emp) {
  devolucaoError.value = ''
  if (!devolucaoResponsavel.value.trim() || !devolucaoConfirma.value) {
    devolucaoError.value = 'Informe quem devolveu e confirme a devolução.'
    return
  }
  devolvendo.value = true

  let fotoUrl = null
  if (devolucaoFoto.value) {
    const ext = devolucaoFoto.value.name.split('.').pop()
    const caminho = `${emp.id}/devolucao.${ext}`
    const { error: upError } = await supabase.storage
      .from('emprestimos')
      .upload(caminho, devolucaoFoto.value, { upsert: true, contentType: devolucaoFoto.value.type })
    if (!upError) {
      const { data: pub } = supabase.storage.from('emprestimos').getPublicUrl(caminho)
      fotoUrl = pub.publicUrl + '?t=' + Date.now()
    }
  }

  const { error } = await supabase.from('campeonato_emprestimos').update({
    responsavel_nome: devolucaoResponsavel.value.trim(),
    devolvido_em: new Date().toISOString(),
    visto_devolucao: true,
    foto_devolucao_url: fotoUrl,
  }).eq('id', emp.id)

  devolvendo.value = false
  if (error) {
    devolucaoError.value = error.message
    return
  }
  devolucaoAbertaId.value = null
  await carregar()
}

const ativosOptions = computed(() => {
  if (novoTipoAtivo.value === 'bola') return bolasDisponiveis.value.map((b) => ({ id: b.id, label: nomeBola(b.id) }))
  return jogosUniformeDisponiveis.value.map((j) => ({ id: j.id, label: j.nome }))
})

const pendentes = computed(() => emprestimos.value.filter((e) => !e.devolvido_em))
const concluidos = computed(() => emprestimos.value.filter((e) => e.devolvido_em))
</script>

<template>
  <div>
    <div class="flex flex-wrap items-center justify-between gap-3">
      <h3 class="font-display text-xl font-bold text-ink">Empréstimo de materiais</h3>
      <button class="rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep" @click="showModal = true">
        + Registrar retirada
      </button>
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <template v-else>
      <!-- Pendentes -->
      <h4 class="mt-6 font-mono-label text-[10px] font-bold text-brand-deep">EMPRÉSTIMOS EM ABERTO</h4>
      <div class="mt-3 space-y-3">
        <p v-if="pendentes.length === 0" class="text-sm text-ink-soft">Nenhum material emprestado no momento.</p>

        <div v-for="emp in pendentes" :key="emp.id" class="rounded-2xl bg-white p-5 shadow-card">
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-ink">
                <span class="rounded-full bg-gold-soft px-2 py-0.5 text-[10px] font-bold uppercase">{{ emp.tipo_ativo }}</span>
                {{ nomeAtivo(emp) }}
                <span v-if="nomeCategoria(emp.campeonato_categoria_id)" class="rounded-full bg-brand px-2 py-0.5 text-[10px] font-bold text-white">{{ nomeCategoria(emp.campeonato_categoria_id) }}</span>
              </p>
              <p class="mt-1 text-xs text-ink-soft">Retirado por {{ emp.responsavel_nome }} em {{ formatarDataHora(emp.retirado_em) }}</p>
            </div>
            <button class="rounded-full bg-ink px-4 py-2 text-xs font-semibold text-white hover:bg-ink/80" @click="abrirDevolucao(emp)">
              Confirmar devolução
            </button>
          </div>

          <!-- Form devolucao -->
          <div v-if="devolucaoAbertaId === emp.id" class="mt-4 rounded-xl bg-paper-dim p-4">
            <div class="grid gap-3 sm:grid-cols-2">
              <div>
                <label class="font-mono-label text-[9px] font-bold text-ink-soft">Quem devolveu</label>
                <select v-model="devolucaoResponsavel" class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand">
                  <option value="" disabled>Selecione...</option>
                  <option v-for="r in responsaveisElegiveis" :key="r.id" :value="r.nome">{{ r.nome }}</option>
                </select>
              </div>
              <div>
                <label class="font-mono-label text-[9px] font-bold text-ink-soft">Foto da devolução (opcional)</label>
                <div class="mt-1 flex items-center gap-2">
                  <div class="h-10 w-10 flex-shrink-0 overflow-hidden rounded-lg bg-white">
                    <img v-if="devolucaoFotoPreview" :src="devolucaoFotoPreview" class="h-full w-full object-cover" alt="" />
                  </div>
                  <button type="button" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink-soft hover:border-ink/30" @click="fileInputDevolucao?.click()">
                    {{ devolucaoFoto ? 'Trocar foto' : 'Adicionar foto' }}
                  </button>
                  <input ref="fileInputDevolucao" type="file" accept="image/jpeg,image/png,image/webp" class="hidden" @change="aoSelecionarFotoDevolucao" />
                </div>
              </div>
            </div>
            <label class="mt-3 flex items-center gap-2 text-xs text-ink">
              <input v-model="devolucaoConfirma" type="checkbox" class="h-4 w-4 rounded border-ink/30" />
              Confirmo que o material foi devolvido conforme cadastro
            </label>
            <p v-if="devolucaoError" class="mt-2 text-xs text-brand-deep">{{ devolucaoError }}</p>
            <div class="mt-3 flex gap-2">
              <button :disabled="devolvendo" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="confirmarDevolucao(emp)">
                {{ devolvendo ? 'Salvando...' : 'Confirmar devolução' }}
              </button>
              <button class="rounded-full border border-ink/15 px-4 py-2 text-xs text-ink-soft hover:border-ink/30" @click="fecharDevolucao">Cancelar</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Concluidos -->
      <h4 class="mt-8 font-mono-label text-[10px] font-bold text-ink-soft">DEVOLVIDOS</h4>
      <div class="mt-3 space-y-3">
        <p v-if="concluidos.length === 0" class="text-sm text-ink-soft">Nenhuma devolução registrada ainda.</p>

        <div v-for="emp in concluidos" :key="emp.id" class="rounded-2xl bg-white p-5 shadow-card opacity-75">
          <div class="flex flex-wrap items-start justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-ink">
                <span class="rounded-full bg-[#EAF3DE] px-2 py-0.5 text-[10px] font-bold uppercase text-[#27500A]">{{ emp.tipo_ativo }}</span>
                {{ nomeAtivo(emp) }}
                <span v-if="nomeCategoria(emp.campeonato_categoria_id)" class="rounded-full bg-ink/10 px-2 py-0.5 text-[10px] font-bold text-ink-soft">{{ nomeCategoria(emp.campeonato_categoria_id) }}</span>
              </p>
              <p class="mt-1 text-xs text-ink-soft">
                Retirado por {{ emp.responsavel_nome }} em {{ formatarDataHora(emp.retirado_em) }} ·
                devolvido em {{ formatarDataHora(emp.devolvido_em) }}
              </p>
            </div>
            <a v-if="emp.foto_devolucao_url" :href="emp.foto_devolucao_url" target="_blank" rel="noopener">
              <img :src="emp.foto_devolucao_url" class="h-12 w-12 rounded-lg object-cover" alt="Foto da devolução" />
            </a>
          </div>
        </div>
      </div>
    </template>

    <!-- Modal novo emprestimo -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showModal = false; limparForm()">
      <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
        <h2 class="font-display text-2xl font-extrabold text-ink">Registrar retirada</h2>

        <div class="mt-6 space-y-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Tipo de material</label>
            <select v-model="novoTipoAtivo" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" @change="novoAtivoId = ''">
              <option v-for="t in tipoAtivoOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Item</label>
            <select v-model="novoAtivoId" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option value="" disabled>Selecione...</option>
              <option v-for="a in ativosOptions" :key="a.id" :value="a.id">{{ a.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Para qual categoria</label>
            <select v-model="novaCategoriaId" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option value="">Não vinculado a uma categoria</option>
              <option v-for="c in categorias" :key="c.id" :value="c.id">{{ c.categoria }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Responsável pela retirada</label>
            <select v-model="novoResponsavel" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option value="" disabled>Selecione...</option>
              <option v-for="r in responsaveisElegiveis" :key="r.id" :value="r.nome">{{ r.nome }}</option>
            </select>
            <p v-if="responsaveisElegiveis.length === 0" class="mt-1 text-[10px] text-brand-deep">
              Nenhum associado adimplente escalado neste campeonato ainda. Cadastre a equipe e confirme os pagamentos em dia na aba "Categorias e Equipe".
            </p>
          </div>
          <label class="flex items-center gap-2 text-xs text-ink">
            <input v-model="confirmaRetirada" type="checkbox" class="h-4 w-4 rounded border-ink/30" />
            Confirmo que o material foi retirado conforme cadastro
          </label>
          <p v-if="addError" class="text-xs text-brand-deep">{{ addError }}</p>
        </div>

        <div class="mt-6 flex gap-3">
          <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="showModal = false; limparForm()">Cancelar</button>
          <button :disabled="salvandoNovo" class="flex-1 rounded-full bg-brand py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="registrarRetirada">
            {{ salvandoNovo ? 'Salvando...' : 'Registrar' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
