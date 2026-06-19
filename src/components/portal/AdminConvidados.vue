<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { createClient } from '@supabase/supabase-js'
import { supabase } from '../../lib/supabase.js'
import { posicaoOptions } from '../../data/convidados.js'
import { modalidadeOptions } from '../../data/portal.js'
import { calcularCategoria } from '../../lib/categoria.js'
import PaginacaoControle from './PaginacaoControle.vue'
import StarRating from './StarRating.vue'

const convidados = ref([])
const loading = ref(true)
const loadError = ref('')
const busca = ref('')
const savingId = ref(null)
const savedId = ref(null)
const removendoId = ref(null)
const confirmandoId = ref(null)

const paginaAtual = ref(1)
const porPagina = ref(10)

// --- Modal de novo convidado ---
const showModal = ref(false)
const novoNome = ref('')
const novoCpf = ref('')
const novoNascimento = ref('')
const novoPosicao = ref('ponteiro')
const novoTelefone = ref('')
const novoCidade = ref('')
const novoTimeOrigem = ref('')
const salvandoNovo = ref(false)
const addError = ref('')

async function carregar() {
  loading.value = true
  loadError.value = ''
  const { data, error } = await supabase.from('convidados').select('*').order('nome')
  if (error) {
    loadError.value = error.message
  } else {
    convidados.value = data
  }
  loading.value = false
}

onMounted(carregar)

const filtrados = computed(() => {
  const termo = busca.value.trim().toLowerCase()
  if (!termo) return convidados.value
  return convidados.value.filter((c) =>
    c.nome.toLowerCase().includes(termo) ||
    (c.cpf ?? '').includes(termo) ||
    (c.telefone ?? '').includes(termo)
  )
})

const paginados = computed(() => {
  const ini = (paginaAtual.value - 1) * porPagina.value
  return filtrados.value.slice(ini, ini + porPagina.value)
})

watch(busca, () => { paginaAtual.value = 1 })

const resumoPosicao = computed(() => {
  const r = {}
  posicaoOptions.forEach((p) => { r[p.value] = 0 })
  convidados.value.forEach((c) => { if (c.posicao && r[c.posicao] !== undefined) r[c.posicao]++ })
  return r
})

async function adicionarConvidado() {
  addError.value = ''
  if (!novoNome.value.trim()) {
    addError.value = 'Preencha ao menos o nome.'
    return
  }
  salvandoNovo.value = true
  const { error } = await supabase.from('convidados').insert({
    nome: novoNome.value.trim(),
    cpf: novoCpf.value.trim() || null,
    data_nascimento: novoNascimento.value || null,
    posicao: novoPosicao.value,
    telefone: novoTelefone.value.trim() || null,
    cidade: novoCidade.value.trim() || null,
    time_origem: novoTimeOrigem.value.trim() || null,
  })
  salvandoNovo.value = false
  if (error) {
    addError.value = error.message
    return
  }
  showModal.value = false
  novoNome.value = ''
  novoCpf.value = ''
  novoNascimento.value = ''
  novoPosicao.value = 'ponteiro'
  novoTelefone.value = ''
  novoCidade.value = ''
  novoTimeOrigem.value = ''
  await carregar()
}

async function salvarCampo(convidado, campo, valor) {
  savingId.value = convidado.id + campo
  const { error } = await supabase.from('convidados').update({ [campo]: valor }).eq('id', convidado.id)
  savingId.value = null
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  savedId.value = convidado.id + campo
  setTimeout(() => { if (savedId.value === convidado.id + campo) savedId.value = null }, 1500)
}

async function removerConvidado(id) {
  confirmandoId.value = null
  removendoId.value = id
  const { error } = await supabase.from('convidados').delete().eq('id', id)
  removendoId.value = null
  if (error) {
    loadError.value = 'Não foi possível remover: ' + error.message
    return
  }
  convidados.value = convidados.value.filter((c) => c.id !== id)
}

// --- Tornar associado (convidado que decidiu se associar) ---
const converterParaId = ref(null) // id do convidado sendo convertido
const converterEmail = ref('')
const converterSenha = ref('')
const converterModalidade = ref('volei')
const convertendo = ref(false)
const converterError = ref('')

function abrirConverter(c) {
  converterParaId.value = c.id
  converterEmail.value = c.email ?? ''
  converterSenha.value = ''
  converterModalidade.value = 'volei'
  converterError.value = ''
}

function fecharConverter() {
  converterParaId.value = null
}

async function confirmarConversao(c) {
  converterError.value = ''
  if (!converterEmail.value.trim() || !converterSenha.value.trim()) {
    converterError.value = 'Preencha e-mail e senha temporária para criar o login.'
    return
  }
  convertendo.value = true

  const url = import.meta.env.VITE_SUPABASE_URL
  const key = import.meta.env.VITE_SUPABASE_ANON_KEY
  const clienteTemp = createClient(url, key, { auth: { storageKey: 'signup-temp-convidado' } })

  const { data, error: signupError } = await clienteTemp.auth.signUp({
    email: converterEmail.value.trim(),
    password: converterSenha.value,
    options: { data: { nome: c.nome } },
  })

  if (signupError || !data.user) {
    convertendo.value = false
    converterError.value = signupError?.message ?? 'Erro ao criar usuário.'
    return
  }

  await clienteTemp.auth.signOut()

  // Aguarda o trigger criar o profile, depois preenche com os dados do convidado
  await new Promise((r) => setTimeout(r, 800))
  await supabase.from('profiles').update({
    cpf: c.cpf,
    data_nascimento: c.data_nascimento,
    telefone: c.telefone,
    posicao: c.posicao,
    modalidade: converterModalidade.value,
    data_associacao: new Date().toISOString().slice(0, 10),
  }).eq('id', data.user.id)

  // Remove o registro de convidado, ja que agora ele e associado
  await supabase.from('convidados').delete().eq('id', c.id)

  convertendo.value = false
  converterParaId.value = null
  convidados.value = convidados.value.filter((x) => x.id !== c.id)
}
</script>

<template>
  <div>
    <!-- Estatisticas por posicao -->
    <div class="grid gap-3 sm:grid-cols-4 lg:grid-cols-8">
      <div class="rounded-2xl bg-paper-dim p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">Total</p>
        <p class="mt-1 font-display text-2xl font-extrabold text-ink">{{ convidados.length }}</p>
      </div>
      <div v-for="p in posicaoOptions" :key="p.value" class="rounded-2xl bg-paper-dim p-4">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">{{ p.label }}</p>
        <p class="mt-1 font-display text-2xl font-extrabold text-ink">{{ resumoPosicao[p.value] }}</p>
      </div>
    </div>

    <!-- Busca + novo -->
    <div class="mt-8 flex flex-wrap items-center gap-3">
      <input
        v-model="busca"
        type="text"
        placeholder="Buscar por nome, CPF ou telefone..."
        class="min-w-0 flex-1 rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
      />
      <button
        class="flex-shrink-0 rounded-full bg-brand px-5 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep"
        @click="showModal = true"
      >+ Novo convidado</button>
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <!-- Lista -->
    <div v-else class="mt-5 space-y-3">
      <div v-if="filtrados.length === 0" class="py-8 text-center text-sm text-ink-soft">Nenhum convidado encontrado.</div>

      <div v-for="c in paginados" :key="c.id" class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div class="min-w-[200px] flex-1">
            <input
              :value="c.nome"
              type="text"
              class="w-full rounded-lg border border-transparent bg-transparent px-0 py-0.5 text-sm font-semibold text-ink outline-none hover:border-ink/15 focus:border-brand focus:bg-paper-dim focus:px-2"
              @change="(e) => { c.nome = e.target.value; salvarCampo(c, 'nome', e.target.value) }"
            />
            <p v-if="c.data_nascimento" class="text-xs text-ink-soft">Categoria {{ calcularCategoria(c.data_nascimento) }}</p>
          </div>

          <div class="flex flex-wrap items-center gap-3">
            <StarRating
              :model-value="c.avaliacao_nota || 0"
              @update:model-value="(v) => { c.avaliacao_nota = v; salvarCampo(c, 'avaliacao_nota', v || null) }"
            />
            <span v-if="savingId?.startsWith(c.id)" class="text-xs text-ink-soft/60">salvando...</span>
            <span v-else-if="savedId?.startsWith(c.id)" class="text-xs text-brand-deep">salvo</span>

            <button class="text-xs font-semibold text-gold hover:underline" @click="abrirConverter(c)">tornar associado</button>

            <template v-if="confirmandoId === c.id">
              <span class="text-xs text-ink-soft">Confirmar exclusão?</span>
              <button class="text-xs font-bold text-brand-deep hover:underline" :disabled="removendoId === c.id" @click="removerConvidado(c.id)">
                {{ removendoId === c.id ? 'removendo...' : 'sim, remover' }}
              </button>
              <button class="text-xs text-ink-soft hover:underline" @click="confirmandoId = null">cancelar</button>
            </template>
            <button v-else class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="confirmandoId = c.id">remover</button>
          </div>
        </div>

        <div class="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">CPF</label>
            <input
              :value="c.cpf"
              type="text"
              placeholder="000.000.000-00"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { c.cpf = e.target.value; salvarCampo(c, 'cpf', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nascimento</label>
            <input
              :value="c.data_nascimento"
              type="date"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { c.data_nascimento = e.target.value; salvarCampo(c, 'data_nascimento', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Telefone / WhatsApp</label>
            <input
              :value="c.telefone"
              type="tel"
              placeholder="(47) 9 9999-9999"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { c.telefone = e.target.value; salvarCampo(c, 'telefone', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Posição</label>
            <select
              :value="c.posicao"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { c.posicao = e.target.value; salvarCampo(c, 'posicao', e.target.value) }"
            >
              <option v-for="p in posicaoOptions" :key="p.value" :value="p.value">{{ p.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Cidade</label>
            <input
              :value="c.cidade"
              type="text"
              placeholder="Joinville/SC"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { c.cidade = e.target.value; salvarCampo(c, 'cidade', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Time de origem</label>
            <input
              :value="c.time_origem"
              type="text"
              placeholder="Se joga por outro clube"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { c.time_origem = e.target.value; salvarCampo(c, 'time_origem', e.target.value) }"
            />
          </div>
        </div>

        <div class="mt-3">
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Observações da avaliação</label>
          <textarea
            :value="c.avaliacao_obs"
            rows="2"
            placeholder="Como foi a participação dele nos campeonatos, pontos fortes, combinados..."
            class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
            @change="(e) => { c.avaliacao_obs = e.target.value; salvarCampo(c, 'avaliacao_obs', e.target.value) }"
          ></textarea>
        </div>

        <div class="mt-3 rounded-xl border border-dashed border-ink/15 p-3 text-center">
          <p class="text-xs text-ink-soft/70">Histórico de campeonatos aparecerá aqui assim que o módulo de Campeonatos for cadastrado.</p>
        </div>
      </div>
    </div>

    <PaginacaoControle
      v-model:pagina="paginaAtual"
      v-model:por-pagina="porPagina"
      :total="filtrados.length"
    />

    <!-- Modal novo convidado -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="showModal = false">
      <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
        <h2 class="font-display text-2xl font-extrabold text-ink">Novo convidado</h2>
        <p class="mt-1 text-xs text-ink-soft">Parceiros e amigos que jogam com o Mannerriege em campeonatos.</p>

        <div class="mt-6 space-y-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nome completo *</label>
            <input v-model="novoNome" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">CPF</label>
              <input v-model="novoCpf" type="text" placeholder="000.000.000-00" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nascimento</label>
              <input v-model="novoNascimento" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Telefone / WhatsApp</label>
            <input v-model="novoTelefone" type="tel" placeholder="(47) 9 9999-9999" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Posição</label>
            <select v-model="novoPosicao" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option v-for="p in posicaoOptions" :key="p.value" :value="p.value">{{ p.label }}</option>
            </select>
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Cidade</label>
              <input v-model="novoCidade" type="text" placeholder="Joinville/SC" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Time de origem</label>
              <input v-model="novoTimeOrigem" type="text" placeholder="Se houver" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
          </div>
          <p v-if="addError" class="text-xs text-brand-deep">{{ addError }}</p>
        </div>

        <div class="mt-6 flex gap-3">
          <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="showModal = false">Cancelar</button>
          <button
            :disabled="salvandoNovo"
            class="flex-1 rounded-full bg-brand py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50"
            @click="adicionarConvidado"
          >{{ salvandoNovo ? 'Salvando...' : 'Cadastrar convidado' }}</button>
        </div>
      </div>
    </div>

    <!-- Modal tornar associado -->
    <div v-if="converterParaId" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4" @click.self="fecharConverter">
      <div class="w-full max-w-md rounded-2xl bg-white p-8 shadow-card">
        <h2 class="font-display text-2xl font-extrabold text-ink">Tornar associado</h2>
        <p class="mt-1 text-xs text-ink-soft">
          Nome, CPF, nascimento, telefone e posição serão copiados do cadastro de convidado.
          Falta só criar o login de acesso ao portal.
        </p>

        <div class="mt-6 space-y-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">E-mail *</label>
            <input v-model="converterEmail" type="email" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Senha temporária *</label>
            <input v-model="converterSenha" type="text" placeholder="mín. 8 caracteres" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Modalidade</label>
            <select v-model="converterModalidade" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option v-for="m in modalidadeOptions" :key="m.value" :value="m.value">{{ m.label }}</option>
            </select>
          </div>
          <p v-if="converterError" class="text-xs text-brand-deep">{{ converterError }}</p>
        </div>

        <div class="mt-6 flex gap-3">
          <button class="flex-1 rounded-full border border-ink/15 py-2.5 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="fecharConverter">Cancelar</button>
          <button
            :disabled="convertendo"
            class="flex-1 rounded-full bg-gold py-2.5 font-mono-label text-[11px] font-bold text-white hover:opacity-90 disabled:opacity-50"
            @click="confirmarConversao(convidados.find((c) => c.id === converterParaId))"
          >{{ convertendo ? 'Convertendo...' : 'Tornar associado' }}</button>
        </div>
      </div>
    </div>
  </div>
</template>
