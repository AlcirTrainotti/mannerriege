<script setup>
import { ref, computed, onMounted } from 'vue'
import { createClient } from '@supabase/supabase-js'
import { supabase } from '../../lib/supabase.js'
import { calcularCategoria } from '../../lib/categoria.js'
import { modalidadeOptions, roleOptions, statusOptions } from '../../data/portal.js'
import { posicaoOptions } from '../../data/convidados.js'
import DonutChart from './DonutChart.vue'
import AvatarUpload from './AvatarUpload.vue'
import PaginacaoControle from './PaginacaoControle.vue'

const associados = ref([])
const loadingList = ref(true)
const loadError = ref('')
const busca = ref('')
const paginaAtual = ref(1)
const porPagina = ref(10)
const savingId = ref(null)
const savedId = ref(null)
const removendoId = ref(null)
const confirmandoId = ref(null)

async function removerAssociado(id) {
  confirmandoId.value = null
  removendoId.value = id
  const { error } = await supabase.from('profiles').delete().eq('id', id)
  removendoId.value = null
  if (error) {
    loadError.value = 'Não foi possível remover: ' + error.message
    return
  }
  associados.value = associados.value.filter((a) => a.id !== id)
}

// --- Tornar convidado (associado que saiu mas continua jogando) ---
const confirmandoConverterId = ref(null)
const convertendoId = ref(null)

async function converterParaConvidado(a) {
  confirmandoConverterId.value = null
  convertendoId.value = a.id

  const { error: insertError } = await supabase.from('convidados').insert({
    nome: a.nome,
    cpf: a.cpf,
    data_nascimento: a.data_nascimento,
    posicao: a.posicao,
    telefone: a.telefone,
    email: a.email,
  })

  if (insertError) {
    convertendoId.value = null
    loadError.value = 'Não foi possível converter: ' + insertError.message
    return
  }

  const { error: deleteError } = await supabase.from('profiles').delete().eq('id', a.id)
  convertendoId.value = null

  if (deleteError) {
    loadError.value = 'Convidado criado, mas não foi possível remover o cadastro de associado: ' + deleteError.message
    return
  }

  associados.value = associados.value.filter((x) => x.id !== a.id)
}

// --- Modal de novo associado ---
const showModal = ref(false)
const novoNome = ref('')
const novoEmail = ref('')
const novaSenha = ref('')
const novoNascimento = ref('')
const novoAssociacao = ref('')
const novoModalidade = ref('volei')
const novoPosicao = ref(null)
const novoTelefone = ref('')
const adicionando = ref(false)
const addError = ref('')

async function adicionarAssociado() {
  addError.value = ''
  if (!novoNome.value.trim() || !novoEmail.value.trim() || !novaSenha.value.trim()) {
    addError.value = 'Preencha nome, e-mail e senha.'
    return
  }
  adicionando.value = true

  // Cria o usuario em um cliente isolado para nao deslogar o admin
  const url = import.meta.env.VITE_SUPABASE_URL
  const key = import.meta.env.VITE_SUPABASE_ANON_KEY
  const clienteTemp = createClient(url, key, { auth: { storageKey: 'signup-temp' } })

  const { data, error: signupError } = await clienteTemp.auth.signUp({
    email: novoEmail.value.trim(),
    password: novaSenha.value,
    options: { data: { nome: novoNome.value.trim() } },
  })

  if (signupError || !data.user) {
    adicionando.value = false
    addError.value = signupError?.message ?? 'Erro ao criar usuário.'
    return
  }

  // Garante que a sessao temporaria e descartada
  await clienteTemp.auth.signOut()

  // Preenche dados extras no profile criado pelo trigger
  const camposExtras = {}
  if (novoNascimento.value) camposExtras.data_nascimento = novoNascimento.value
  if (novoAssociacao.value) camposExtras.data_associacao = novoAssociacao.value
  if (novoModalidade.value) camposExtras.modalidade = novoModalidade.value
  if (novoTelefone.value) camposExtras.telefone = novoTelefone.value
  if (novoPosicao.value) camposExtras.posicao = novoPosicao.value

  if (Object.keys(camposExtras).length) {
    // Aguarda o trigger criar o profile
    await new Promise((r) => setTimeout(r, 800))
    await supabase.from('profiles').update(camposExtras).eq('id', data.user.id)
  }

  adicionando.value = false
  showModal.value = false
  novoNome.value = ''
  novoEmail.value = ''
  novaSenha.value = ''
  novoNascimento.value = ''
  novoAssociacao.value = ''
  novoModalidade.value = 'volei'
  novoTelefone.value = ''
  novoPosicao.value = null
  await carregar()
}

// --- Dados e filtros ---
async function carregar() {
  loadingList.value = true
  loadError.value = ''
  const { data, error } = await supabase.from('profiles').select('*').order('nome')
  if (error) {
    loadError.value = error.message
  } else {
    associados.value = data
  }
  loadingList.value = false
}

onMounted(carregar)

const filtrados = computed(() => {
  const termo = busca.value.trim().toLowerCase()
  if (!termo) return associados.value
  return associados.value.filter((a) =>
    a.nome.toLowerCase().includes(termo) ||
    a.email.toLowerCase().includes(termo) ||
    (a.cpf ?? '').includes(termo)
  )
})

const paginados = computed(() => {
  const ini = (paginaAtual.value - 1) * porPagina.value
  return filtrados.value.slice(ini, ini + porPagina.value)
})

// Reset pagina ao buscar
import { watch } from 'vue'
watch(busca, () => { paginaAtual.value = 1 })

// --- Resumos para graficos ---
const resumoStatus = computed(() => {
  const r = { adimplente: 0, inadimplente: 0, inativo: 0 }
  associados.value.forEach((a) => { if (r[a.status] !== undefined) r[a.status]++ })
  return r
})
const resumoModalidade = computed(() => {
  const r = { volei: 0, volei_domino: 0, domino: 0 }
  associados.value.forEach((a) => { if (r[a.modalidade] !== undefined) r[a.modalidade]++ })
  return r
})

function anosAssociado(data) {
  if (!data) return null
  const anos = new Date().getFullYear() - new Date(data + 'T00:00:00').getFullYear()
  return anos
}

async function salvarCampo(associado, campo, valor) {
  savingId.value = associado.id + campo
  const { error } = await supabase.from('profiles').update({ [campo]: valor }).eq('id', associado.id)
  savingId.value = null
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  savedId.value = associado.id + campo
  setTimeout(() => { if (savedId.value === associado.id + campo) savedId.value = null }, 1500)
}

function statusClasses(status) {
  if (status === 'adimplente') return 'bg-[#EAF3DE] text-[#27500A]'
  if (status === 'inadimplente') return 'bg-brand-soft text-brand-deep'
  return 'bg-ink/8 text-ink-soft'
}
</script>

<template>
  <div>
    <!-- Graficos e estatisticas -->
    <div class="grid gap-6 sm:grid-cols-2">
      <!-- Card status -->
      <div class="rounded-2xl bg-white p-6 shadow-card">
        <p class="font-mono-label text-[10px] font-bold text-ink-soft">Situação financeira</p>
        <div class="mt-4 flex items-center gap-6">
          <div class="relative h-28 w-28 flex-shrink-0">
            <DonutChart
              :labels="['Adimplentes', 'Inadimplentes', 'Inativos']"
              :values="[resumoStatus.adimplente, resumoStatus.inadimplente, resumoStatus.inativo]"
              :colors="['#4a7c2a', '#ED1B24', '#b0a99e']"
            />
            <div class="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
              <span class="font-display text-2xl font-extrabold text-ink">{{ associados.length }}</span>
              <span class="font-mono-label text-[9px] text-ink-soft">total</span>
            </div>
          </div>
          <div class="space-y-2 text-sm">
            <div class="flex items-center gap-2">
              <span class="h-2.5 w-2.5 rounded-full bg-[#4a7c2a]"></span>
              <span class="text-ink-soft">Adimplentes</span>
              <span class="ml-auto font-bold text-ink">{{ resumoStatus.adimplente }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="h-2.5 w-2.5 rounded-full bg-brand"></span>
              <span class="text-ink-soft">Inadimplentes</span>
              <span class="ml-auto font-bold text-ink">{{ resumoStatus.inadimplente }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="h-2.5 w-2.5 rounded-full bg-ink/30"></span>
              <span class="text-ink-soft">Inativos</span>
              <span class="ml-auto font-bold text-ink">{{ resumoStatus.inativo }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Card modalidade -->
      <div class="rounded-2xl bg-white p-6 shadow-card">
        <p class="font-mono-label text-[10px] font-bold text-ink-soft">Modalidade</p>
        <div class="mt-4 flex items-center gap-6">
          <div class="relative h-28 w-28 flex-shrink-0">
            <DonutChart
              :labels="['Vôlei', 'Vôlei + Dominó', 'Só Dominó']"
              :values="[resumoModalidade.volei, resumoModalidade.volei_domino, resumoModalidade.domino]"
              :colors="['#ED1B24', '#c08a2e', '#18130f']"
            />
            <div class="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
              <span class="font-display text-2xl font-extrabold text-ink">{{ associados.length }}</span>
              <span class="font-mono-label text-[9px] text-ink-soft">atletas</span>
            </div>
          </div>
          <div class="space-y-2 text-sm">
            <div class="flex items-center gap-2">
              <span class="h-2.5 w-2.5 rounded-full bg-brand"></span>
              <span class="text-ink-soft">Vôlei</span>
              <span class="ml-auto font-bold text-ink">{{ resumoModalidade.volei }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="h-2.5 w-2.5 rounded-full bg-gold"></span>
              <span class="text-ink-soft">Vôlei + Dominó</span>
              <span class="ml-auto font-bold text-ink">{{ resumoModalidade.volei_domino }}</span>
            </div>
            <div class="flex items-center gap-2">
              <span class="h-2.5 w-2.5 rounded-full bg-ink"></span>
              <span class="text-ink-soft">Só Dominó</span>
              <span class="ml-auto font-bold text-ink">{{ resumoModalidade.domino }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Barra de busca + botao -->
    <div class="mt-8 flex flex-wrap items-center gap-3">
      <input
        v-model="busca"
        type="text"
        placeholder="Buscar por nome, e-mail ou CPF..."
        class="min-w-0 flex-1 rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
      />
      <button
        class="flex-shrink-0 rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep"
        @click="showModal = true"
      >+ Novo associado</button>
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loadingList" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <!-- Lista de associados -->
    <div v-else class="mt-5 space-y-3">
      <div v-if="filtrados.length === 0" class="py-8 text-center text-sm text-ink-soft">Nenhum associado encontrado.</div>

      <div v-for="a in paginados" :key="a.id" class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div class="flex min-w-[200px] flex-1 items-center gap-3">
            <AvatarUpload
              :profile-id="a.id"
              :avatar-url="a.avatar_url"
              :nome="a.nome"
              size="sm"
              :editable="true"
              @update:avatar-url="(url) => a.avatar_url = url"
            />
            <div class="min-w-0 flex-1">
              <input
                :value="a.nome"
                type="text"
                class="w-full rounded-lg border border-transparent bg-transparent px-0 py-0.5 text-sm font-semibold text-ink outline-none hover:border-ink/15 focus:border-brand focus:bg-paper-dim focus:px-2"
                @change="(e) => { a.nome = e.target.value; salvarCampo(a, 'nome', e.target.value) }"
              />
              <p class="text-xs text-ink-soft">{{ a.email }}</p>
            </div>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <span v-if="anosAssociado(a.data_associacao) !== null" class="rounded-full bg-gold-soft px-3 py-1 text-xs font-semibold text-ink">
              {{ anosAssociado(a.data_associacao) }}{{ anosAssociado(a.data_associacao) === 1 ? ' ano' : ' anos' }}
            </span>
            <span :class="['rounded-full px-3 py-1 text-xs font-semibold', statusClasses(a.status)]">{{ a.status }}</span>
            <span v-if="savingId?.startsWith(a.id)" class="text-xs text-ink-soft/60">salvando...</span>
            <span v-else-if="savedId?.startsWith(a.id)" class="text-xs text-brand-deep">salvo</span>
            <!-- Tornar convidado -->
            <template v-if="confirmandoConverterId === a.id">
              <span class="text-xs text-ink-soft">Criar convidado e remover associado?</span>
              <button class="text-xs font-bold text-gold hover:underline" :disabled="convertendoId === a.id" @click="converterParaConvidado(a)">
                {{ convertendoId === a.id ? 'convertendo...' : 'sim, converter' }}
              </button>
              <button class="text-xs text-ink-soft hover:underline" @click="confirmandoConverterId = null">cancelar</button>
            </template>
            <button
              v-else-if="confirmandoId !== a.id"
              class="text-xs text-ink-soft/50 hover:text-ink"
              title="O associado sai do quadro de sócios, mas continua disponível como convidado para campeonatos"
              @click="confirmandoConverterId = a.id"
            >tornar convidado</button>
            <!-- Remover -->
            <template v-if="confirmandoId === a.id">
              <span class="text-xs text-ink-soft">Confirmar exclusão?</span>
              <button class="text-xs font-bold text-brand-deep hover:underline" :disabled="removendoId === a.id" @click="removerAssociado(a.id)">
                {{ removendoId === a.id ? 'removendo...' : 'sim, remover' }}
              </button>
              <button class="text-xs text-ink-soft hover:underline" @click="confirmandoId = null">cancelar</button>
            </template>
            <button v-else-if="confirmandoConverterId !== a.id" class="ml-1 text-xs text-ink-soft/50 hover:text-brand-deep" @click="confirmandoId = a.id">remover</button>
          </div>
        </div>

        <div class="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">CPF</label>
            <input
              :value="a.cpf"
              type="text"
              placeholder="000.000.000-00"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.cpf = e.target.value; salvarCampo(a, 'cpf', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nascimento</label>
            <input
              :value="a.data_nascimento"
              type="date"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.data_nascimento = e.target.value; salvarCampo(a, 'data_nascimento', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Associado desde</label>
            <input
              :value="a.data_associacao"
              type="date"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.data_associacao = e.target.value; salvarCampo(a, 'data_associacao', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Telefone / WhatsApp</label>
            <input
              :value="a.telefone"
              type="tel"
              placeholder="(47) 9 9999-9999"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.telefone = e.target.value; salvarCampo(a, 'telefone', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Categoria</label>
            <p class="mt-1 rounded-lg bg-paper-dim px-3 py-2 text-xs font-semibold text-ink">
              {{ calcularCategoria(a.data_nascimento) || '—' }}
            </p>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Modalidade</label>
            <select
              :value="a.modalidade"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.modalidade = e.target.value; salvarCampo(a, 'modalidade', e.target.value) }"
            >
              <option v-for="m in modalidadeOptions" :key="m.value" :value="m.value">{{ m.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Posição</label>
            <select
              :value="a.posicao"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.posicao = e.target.value; salvarCampo(a, 'posicao', e.target.value) }"
            >
              <option :value="null">—</option>
              <option v-for="p in posicaoOptions" :key="p.value" :value="p.value">{{ p.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Status</label>
            <select
              :value="a.status"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.status = e.target.value; salvarCampo(a, 'status', e.target.value) }"
            >
              <option v-for="s in statusOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Papel</label>
            <select
              :value="a.role"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.role = e.target.value; salvarCampo(a, 'role', e.target.value) }"
            >
              <option v-for="r in roleOptions" :key="r.value" :value="r.value">{{ r.label }}</option>
            </select>
          </div>
        </div>
      </div>
    </div>

    <!-- Modal novo associado -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showModal = false">
      <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
        <h2 class="font-display text-2xl font-extrabold text-ink">Novo associado</h2>
        <p class="mt-1 text-xs text-ink-soft">Um e-mail de confirmação será enviado automaticamente pela Supabase.</p>

        <div class="mt-6 space-y-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nome completo *</label>
            <input v-model="novoNome" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">E-mail *</label>
            <input v-model="novoEmail" type="email" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Senha temporária *</label>
            <input v-model="novaSenha" type="text" placeholder="mín. 8 caracteres" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nascimento</label>
              <input v-model="novoNascimento" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Associado desde</label>
              <input v-model="novoAssociacao" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
          </div>
          <div class="sm:col-span-2">
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Telefone / WhatsApp</label>
            <input v-model="novoTelefone" type="tel" placeholder="(47) 9 9999-9999"
              class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Modalidade</label>
              <select v-model="novoModalidade" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
                <option v-for="m in modalidadeOptions" :key="m.value" :value="m.value">{{ m.label }}</option>
              </select>
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Posição</label>
              <select v-model="novoPosicao" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
                <option :value="null">Não joga</option>
                <option v-for="p in posicaoOptions" :key="p.value" :value="p.value">{{ p.label }}</option>
              </select>
            </div>
          </div>
          <p v-if="addError" class="text-xs text-brand-deep">{{ addError }}</p>
        </div>

        <div class="mt-6 flex gap-3">
          <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="showModal = false">Cancelar</button>
          <button
            :disabled="adicionando"
            class="flex-1 rounded-full bg-brand py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50"
            @click="adicionarAssociado"
          >{{ adicionando ? 'Criando...' : 'Criar associado' }}</button>
        </div>
      </div>
    </div>
  </div>
</template>
