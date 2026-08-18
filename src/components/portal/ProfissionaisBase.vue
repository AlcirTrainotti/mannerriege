<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import { cargoProfissionalOptions, cargosProfissionalLabel } from '../../data/base.js'

// Cadastro dos profissionais do projeto (coordenador/técnico/
// colaborador) — dado documental, independente do login no portal. O
// profissional pode já ser sócio da Mannerriege (socio_id, opcional) e
// pode ou não ter acesso ao sistema (profile_id, opcional).
defineProps({
  embedded: { type: Boolean, default: false },
})

const { profile } = useAuth()

const profissionais = ref([])
const carregando = ref(true)

async function carregar() {
  carregando.value = true
  const { data } = await supabase.from('profissionais_base').select('*').order('nome')
  profissionais.value = data ?? []
  carregando.value = false
}
onMounted(carregar)

// --- Busca de sócio / usuário do portal (autocomplete simples) ---
async function buscarPerfis(termo) {
  if (!termo || termo.trim().length < 2) return []
  const { data } = await supabase.from('profiles').select('id, nome, email, role').ilike('nome', `%${termo.trim()}%`).limit(8)
  return data ?? []
}

function formVazio() {
  return {
    nome: '', cpf: '', rg: '', data_nascimento: '', telefone: '', email: '', endereco: '',
    cargos: [], eh_socio: false, socio_id: null, socio_nome: '', profile_id: null, profile_nome: '',
    observacoes: '',
  }
}

// --- Cadastro ---
const mostrarForm = ref(false)
const formProf = ref(formVazio())
const salvando = ref(false)
const erroForm = ref('')
const buscaSocio = ref('')
const resultadosSocio = ref([])
const buscaLogin = ref('')
const resultadosLogin = ref([])

async function aoDigitarSocio() {
  resultadosSocio.value = await buscarPerfis(buscaSocio.value)
}
async function aoDigitarLogin() {
  resultadosLogin.value = await buscarPerfis(buscaLogin.value)
}

function selecionarSocio(f, p) {
  f.socio_id = p.id
  f.socio_nome = p.nome
  resultadosSocio.value = []
  buscaSocio.value = ''
}
function selecionarLogin(f, p) {
  f.profile_id = p.id
  f.profile_nome = p.nome
  resultadosLogin.value = []
  buscaLogin.value = ''
}

async function salvarProfissional() {
  erroForm.value = ''
  const f = formProf.value
  if (!f.nome.trim() || !f.cargos.length) {
    erroForm.value = 'Preencha o nome e pelo menos um cargo.'
    return
  }
  salvando.value = true
  const { data, error } = await supabase.from('profissionais_base').insert({
    nome: f.nome.trim(),
    cpf: f.cpf.trim() || null,
    rg: f.rg.trim() || null,
    data_nascimento: f.data_nascimento || null,
    telefone: f.telefone.trim() || null,
    email: f.email.trim() || null,
    endereco: f.endereco.trim() || null,
    cargos: f.cargos,
    eh_socio: f.eh_socio,
    socio_id: f.eh_socio ? f.socio_id : null,
    profile_id: f.profile_id,
    observacoes: f.observacoes.trim() || null,
    criado_por: profile.value?.id ?? null,
  }).select().single()
  salvando.value = false
  if (error) {
    erroForm.value = error.message
    return
  }
  profissionais.value.push(data)
  profissionais.value.sort((a, b) => a.nome.localeCompare(b.nome))
  mostrarForm.value = false
  formProf.value = formVazio()
}

// --- Edição ---
const editandoId = ref(null)
const formEdicao = ref(null)

function abrirEdicao(p) {
  editandoId.value = p.id
  formEdicao.value = {
    nome: p.nome, cpf: p.cpf ?? '', rg: p.rg ?? '', data_nascimento: p.data_nascimento ?? '',
    telefone: p.telefone ?? '', email: p.email ?? '', endereco: p.endereco ?? '',
    cargos: [...(p.cargos ?? [])], eh_socio: p.eh_socio, socio_id: p.socio_id, profile_id: p.profile_id,
    observacoes: p.observacoes ?? '',
  }
}

async function salvarEdicao(p) {
  const f = formEdicao.value
  const patch = {
    nome: f.nome.trim(), cpf: f.cpf.trim() || null, rg: f.rg.trim() || null,
    data_nascimento: f.data_nascimento || null, telefone: f.telefone.trim() || null,
    email: f.email.trim() || null, endereco: f.endereco.trim() || null,
    cargos: f.cargos, eh_socio: f.eh_socio, socio_id: f.eh_socio ? f.socio_id : null,
    observacoes: f.observacoes.trim() || null,
  }
  const { error } = await supabase.from('profissionais_base').update(patch).eq('id', p.id)
  if (!error) {
    Object.assign(p, patch)
    editandoId.value = null
  }
}

async function alternarAtivo(p) {
  const { error } = await supabase.from('profissionais_base').update({ ativo: !p.ativo }).eq('id', p.id)
  if (!error) p.ativo = !p.ativo
}

async function excluirProfissional(p) {
  if (!confirm(`Excluir o cadastro de "${p.nome}"?`)) return
  const { error } = await supabase.from('profissionais_base').delete().eq('id', p.id)
  if (!error) profissionais.value = profissionais.value.filter((x) => x.id !== p.id)
}
</script>

<template>
  <div>
    <div v-if="!embedded">
      <p class="font-mono-label text-[11px] font-bold text-brand-deep">Administrativo</p>
      <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Profissionais do projeto</h1>
    </div>

    <button v-if="!mostrarForm" :class="embedded ? '' : 'mt-6'" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep" @click="mostrarForm = true">+ Novo profissional</button>

    <form v-if="mostrarForm" class="mt-4 space-y-4 rounded-2xl bg-white p-6 shadow-card" @submit.prevent="salvarProfissional">
      <div class="grid gap-3 sm:grid-cols-2">
        <input v-model="formProf.nome" placeholder="Nome completo" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formProf.data_nascimento" type="date" placeholder="Data de nascimento" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formProf.cpf" placeholder="CPF" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formProf.rg" placeholder="RG" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formProf.telefone" placeholder="Telefone" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formProf.email" type="email" placeholder="E-mail" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formProf.endereco" placeholder="Endereço" class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
      </div>

      <div>
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">CARGO(S)</p>
        <div class="mt-1.5 flex flex-wrap gap-3">
          <label v-for="c in cargoProfissionalOptions" :key="c.value" class="flex items-center gap-1.5 text-xs text-ink">
            <input v-model="formProf.cargos" type="checkbox" :value="c.value" class="h-3.5 w-3.5 rounded border-ink/30" />
            {{ c.label }}
          </label>
        </div>
      </div>

      <div class="relative">
        <label class="flex items-center gap-2 text-xs text-ink">
          <input v-model="formProf.eh_socio" type="checkbox" class="h-3.5 w-3.5 rounded border-ink/30" />
          Já é sócio(a) da Mannerriege
        </label>
        <div v-if="formProf.eh_socio" class="mt-2">
          <p v-if="formProf.socio_nome" class="text-xs text-ink-soft">Vinculado a: <strong class="text-ink">{{ formProf.socio_nome }}</strong> <button type="button" class="ml-1 text-brand-deep hover:underline" @click="formProf.socio_id = null; formProf.socio_nome = ''">trocar</button></p>
          <input v-else v-model="buscaSocio" placeholder="Buscar sócio pelo nome..." class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" @input="aoDigitarSocio" />
          <div v-if="resultadosSocio.length" class="mt-1 divide-y divide-ink/8 rounded-lg border border-ink/15 bg-white">
            <button v-for="r in resultadosSocio" :key="r.id" type="button" class="block w-full px-3 py-1.5 text-left text-xs text-ink hover:bg-paper-dim" @click="selecionarSocio(formProf, r)">{{ r.nome }} <span class="text-ink-soft">({{ r.email }})</span></button>
          </div>
        </div>
      </div>

      <div>
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">LOGIN NO PORTAL (OPCIONAL)</p>
        <p v-if="formProf.profile_nome" class="mt-1 text-xs text-ink-soft">Vinculado a: <strong class="text-ink">{{ formProf.profile_nome }}</strong> <button type="button" class="ml-1 text-brand-deep hover:underline" @click="formProf.profile_id = null; formProf.profile_nome = ''">trocar</button></p>
        <input v-else v-model="buscaLogin" placeholder="Buscar usuário com acesso ao portal..." class="mt-1 w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" @input="aoDigitarLogin" />
        <div v-if="resultadosLogin.length" class="mt-1 divide-y divide-ink/8 rounded-lg border border-ink/15 bg-white">
          <button v-for="r in resultadosLogin" :key="r.id" type="button" class="block w-full px-3 py-1.5 text-left text-xs text-ink hover:bg-paper-dim" @click="selecionarLogin(formProf, r)">{{ r.nome }} <span class="text-ink-soft">({{ r.role }})</span></button>
        </div>
      </div>

      <textarea v-model="formProf.observacoes" placeholder="Observações (opcional)" rows="2" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm"></textarea>

      <p v-if="erroForm" class="text-xs text-brand-deep">{{ erroForm }}</p>

      <div class="flex gap-2">
        <button type="submit" :disabled="salvando" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ salvando ? 'Salvando...' : 'Salvar' }}</button>
        <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="mostrarForm = false">Cancelar</button>
      </div>
    </form>

    <p v-if="carregando" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
      <div v-for="p in profissionais" :key="p.id" class="px-5 py-4">
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p class="text-sm font-semibold text-ink">{{ p.nome }}</p>
            <p class="text-xs text-ink-soft">{{ cargosProfissionalLabel(p.cargos) }}<span v-if="p.eh_socio"> · sócio(a)</span><span v-if="p.profile_id"> · tem acesso ao portal</span></p>
            <p v-if="p.telefone || p.email" class="mt-0.5 text-xs text-ink-soft">{{ [p.telefone, p.email].filter(Boolean).join(' · ') }}</p>
          </div>
          <div class="flex items-center gap-2">
            <button class="rounded-full px-3 py-1 text-xs font-semibold" :class="p.ativo ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-ink/8 text-ink-soft'" @click="alternarAtivo(p)">{{ p.ativo ? 'ativo' : 'inativo' }}</button>
            <button class="text-xs font-semibold text-brand-deep hover:underline" @click="editandoId === p.id ? (editandoId = null) : abrirEdicao(p)">{{ editandoId === p.id ? 'Fechar' : 'Editar' }}</button>
            <button class="text-xs font-semibold text-ink-soft hover:text-brand-deep hover:underline" @click="excluirProfissional(p)">Excluir</button>
          </div>
        </div>

        <form v-if="editandoId === p.id && formEdicao" class="mt-4 space-y-3 rounded-xl bg-paper-dim p-4" @submit.prevent="salvarEdicao(p)">
          <div class="grid gap-3 sm:grid-cols-2">
            <input v-model="formEdicao.nome" required class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.data_nascimento" type="date" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.cpf" placeholder="CPF" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.rg" placeholder="RG" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.telefone" placeholder="Telefone" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.email" type="email" placeholder="E-mail" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.endereco" placeholder="Endereço" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm sm:col-span-2" />
          </div>
          <div class="flex flex-wrap gap-3">
            <label v-for="c in cargoProfissionalOptions" :key="c.value" class="flex items-center gap-1.5 text-xs text-ink">
              <input v-model="formEdicao.cargos" type="checkbox" :value="c.value" class="h-3.5 w-3.5 rounded border-ink/30" />
              {{ c.label }}
            </label>
          </div>
          <label class="flex items-center gap-2 text-xs text-ink">
            <input v-model="formEdicao.eh_socio" type="checkbox" class="h-3.5 w-3.5 rounded border-ink/30" />
            É sócio(a) da Mannerriege
          </label>
          <textarea v-model="formEdicao.observacoes" placeholder="Observações" rows="2" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm"></textarea>
          <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
        </form>
      </div>
    </div>
  </div>
</template>
