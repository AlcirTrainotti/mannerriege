<script setup>
import { ref, computed, onMounted } from 'vue'
import { createClient } from '@supabase/supabase-js'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'
import { brl } from '../../data/campeonatos.js'
import {
  idadeAtual, nomeCategoria, sexoOptions, sexoLabel,
  statusAtletaOptions, statusAtletaLabel, statusAtletaClasses,
} from '../../data/base.js'

const props = defineProps({
  // Quando embedded=true, não mostra o cabeçalho próprio (título +
  // sair), pois já está dentro do AdminPanel.
  embedded: { type: Boolean, default: false },
})

const { profile, logout } = useAuth()
const aba = ref('atletas')

// ================================================================
// Dados compartilhados entre as abas
// ================================================================
const carregando = ref(true)
const atletas = ref([])
const categorias = ref([])
const planos = ref([])
const responsaveisPorAtleta = ref({}) // atleta_id -> [{ nome, parentesco }]

async function carregarTudo() {
  carregando.value = true
  const [{ data: atletasData }, { data: categoriasData }, { data: planosData }] = await Promise.all([
    supabase.from('atletas_base').select('*').order('nome'),
    supabase.from('categorias_base').select('*').order('nome'),
    supabase.from('planos_base').select('*').order('ordem'),
  ])
  atletas.value = atletasData ?? []
  categorias.value = categoriasData ?? []
  planos.value = planosData ?? []
  carregando.value = false
}

function categoriaDoAtleta(atleta) {
  return categorias.value.find((c) => c.id === atleta.categoria_id)
}

onMounted(carregarTudo)

// ================================================================
// Aba Atletas — cadastro (atleta + vínculo com responsável)
// ================================================================
const mostrarFormAtleta = ref(false)
const salvandoAtleta = ref(false)
const erroAtleta = ref('')
const responsaveisDisponiveis = ref([])

const formAtleta = ref({
  nome: '', data_nascimento: '', sexo: 'masculino', categoria_id: '', escola: '',
  parentesco: 'mãe/pai',
  responsavelModo: 'existente', // 'existente' | 'novo'
  responsavelId: '',
  respNome: '', respTelefone: '', respEmail: '', respSenha: '',
})

async function abrirFormAtleta() {
  erroAtleta.value = ''
  mostrarFormAtleta.value = true
  const { data } = await supabase.rpc('listar_responsaveis_base')
  responsaveisDisponiveis.value = data ?? []
}

async function salvarAtleta() {
  erroAtleta.value = ''
  const f = formAtleta.value

  if (!f.nome.trim() || !f.data_nascimento || !f.categoria_id) {
    erroAtleta.value = 'Preencha nome, data de nascimento e categoria.'
    return
  }
  if (f.responsavelModo === 'existente' && !f.responsavelId) {
    erroAtleta.value = 'Selecione o responsável, ou cadastre um novo.'
    return
  }
  if (f.responsavelModo === 'novo' && (!f.respNome.trim() || !f.respTelefone.trim() || !f.respSenha.trim())) {
    erroAtleta.value = 'Preencha nome, telefone e senha do novo responsável.'
    return
  }

  salvandoAtleta.value = true

  // 1. Cria o registro do atleta
  const { data: novoAtleta, error: atletaError } = await supabase
    .from('atletas_base')
    .insert({
      nome: f.nome.trim(), data_nascimento: f.data_nascimento, sexo: f.sexo,
      categoria_id: f.categoria_id, escola: f.escola.trim() || null,
    })
    .select()
    .single()

  if (atletaError) {
    erroAtleta.value = atletaError.message
    salvandoAtleta.value = false
    return
  }

  // 2. Resolve o responsável (existente ou cadastra um novo)
  let responsavelId = f.responsavelId

  if (f.responsavelModo === 'novo') {
    const url = import.meta.env.VITE_SUPABASE_URL
    const key = import.meta.env.VITE_SUPABASE_ANON_KEY
    const clienteTemp = createClient(url, key, { auth: { storageKey: 'signup-temp-responsavel' } })

    const emailParaLogin = f.respEmail.trim() || `${f.respTelefone.replace(/\D/g, '')}@sememail.mannerriege.com.br`
    const { data, error: signupError } = await clienteTemp.auth.signUp({
      email: emailParaLogin,
      password: f.respSenha,
      options: { data: { nome: f.respNome.trim() } },
    })

    if (signupError || !data.user) {
      erroAtleta.value = signupError?.message ?? 'Erro ao cadastrar o responsável.'
      salvandoAtleta.value = false
      return
    }
    await clienteTemp.auth.signOut()

    await new Promise((r) => setTimeout(r, 800)) // aguarda o trigger criar o profile
    await supabase.from('profiles').update({ telefone: f.respTelefone.trim() }).eq('id', data.user.id)
    const { error: roleError } = await supabase.rpc('definir_role_responsavel_base', { p_profile_id: data.user.id })
    if (roleError) {
      erroAtleta.value = roleError.message
      salvandoAtleta.value = false
      return
    }
    responsavelId = data.user.id
  }

  // 3. Vincula atleta e responsável
  const { error: vinculoError } = await supabase
    .from('atleta_responsaveis')
    .insert({ atleta_id: novoAtleta.id, responsavel_id: responsavelId, parentesco: f.parentesco || null })

  salvandoAtleta.value = false

  if (vinculoError) {
    erroAtleta.value = `Atleta criado, mas não consegui vincular o responsável: ${vinculoError.message}`
    return
  }

  atletas.value.push(novoAtleta)
  mostrarFormAtleta.value = false
  formAtleta.value = {
    nome: '', data_nascimento: '', sexo: 'masculino', categoria_id: '', escola: '',
    parentesco: 'mãe/pai', responsavelModo: 'existente', responsavelId: '',
    respNome: '', respTelefone: '', respEmail: '', respSenha: '',
  }
}

// Alterar categoria/status de um atleta já cadastrado (exclusivo da equipe)
const editandoGestaoId = ref(null)
async function salvarGestaoAtleta(atleta, novaCategoriaId, novoStatus) {
  const { error } = await supabase
    .from('atletas_base')
    .update({ categoria_id: novaCategoriaId, status: novoStatus })
    .eq('id', atleta.id)
  if (!error) {
    atleta.categoria_id = novaCategoriaId
    atleta.status = novoStatus
    editandoGestaoId.value = null
  }
}

// ================================================================
// Aba Categorias
// ================================================================
const mostrarFormCategoria = ref(false)
const formCategoria = ref({ nome: '', sexo: 'masculino', faixa_etaria_min: null, faixa_etaria_max: null })

async function salvarCategoria() {
  const f = formCategoria.value
  if (!f.nome.trim()) return
  const { data, error } = await supabase.from('categorias_base').insert({
    nome: f.nome.trim(), sexo: f.sexo,
    faixa_etaria_min: f.faixa_etaria_min || null, faixa_etaria_max: f.faixa_etaria_max || null,
  }).select().single()
  if (!error) {
    categorias.value.push(data)
    mostrarFormCategoria.value = false
    formCategoria.value = { nome: '', sexo: 'masculino', faixa_etaria_min: null, faixa_etaria_max: null }
  }
}

async function alternarAtivoCategoria(categoria) {
  const { error } = await supabase.from('categorias_base').update({ ativo: !categoria.ativo }).eq('id', categoria.id)
  if (!error) categoria.ativo = !categoria.ativo
}

// ================================================================
// Aba Planos
// ================================================================
const mostrarFormPlano = ref(false)
const formPlano = ref({ nome: '', valor_mensal: 0, descricao: '' })

async function salvarPlano() {
  const f = formPlano.value
  if (!f.nome.trim()) return
  const { data, error } = await supabase.from('planos_base').insert({
    nome: f.nome.trim(), valor_mensal: f.valor_mensal || 0, descricao: f.descricao.trim() || null,
    ordem: planos.value.length + 1,
  }).select().single()
  if (!error) {
    planos.value.push(data)
    mostrarFormPlano.value = false
    formPlano.value = { nome: '', valor_mensal: 0, descricao: '' }
  }
}

async function definirPlanoPadrao(plano) {
  // Só um plano padrão por vez (índice único no banco) — desmarca o
  // atual antes de marcar o novo.
  await supabase.from('planos_base').update({ padrao: false }).eq('padrao', true)
  const { error } = await supabase.from('planos_base').update({ padrao: true }).eq('id', plano.id)
  if (!error) {
    planos.value.forEach((p) => { p.padrao = p.id === plano.id })
  }
}

async function alternarAtivoPlano(plano) {
  const { error } = await supabase.from('planos_base').update({ ativo: !plano.ativo }).eq('id', plano.id)
  if (!error) plano.ativo = !plano.ativo
}
</script>

<template>
  <div>
    <div v-if="!embedded" class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <p class="font-mono-label text-[11px] font-bold text-brand-deep">Coordenação · Categorias de Base</p>
        <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">
          {{ aba === 'atletas' ? 'Atletas' : aba === 'categorias' ? 'Categorias' : 'Planos' }}
        </h1>
      </div>
      <div class="flex items-center gap-3">
        <span class="text-xs text-ink-soft">Logado como {{ profile?.nome }}</span>
        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
      </div>
    </div>

    <div :class="embedded ? 'flex gap-2' : 'mt-6 flex gap-2'">
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'atletas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'atletas'">Atletas</button>
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'categorias' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'categorias'">Categorias</button>
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'planos' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'planos'">Planos</button>
    </div>

    <p v-if="carregando" class="mt-8 text-sm text-ink-soft">Carregando...</p>

    <!-- ===== ATLETAS ===== -->
    <div v-else-if="aba === 'atletas'" class="mt-6">
      <button v-if="!mostrarFormAtleta" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep" @click="abrirFormAtleta">+ Novo atleta</button>

      <form v-if="mostrarFormAtleta" class="mt-4 space-y-4 rounded-2xl bg-white p-6 shadow-card" @submit.prevent="salvarAtleta">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">DADOS DO ATLETA</p>
        <div class="grid gap-3 sm:grid-cols-2">
          <input v-model="formAtleta.nome" placeholder="Nome completo" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
          <input v-model="formAtleta.data_nascimento" type="date" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <select v-model="formAtleta.sexo" class="rounded-lg border border-ink/15 px-3 py-2 text-sm">
            <option v-for="s in sexoOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
          </select>
          <select v-model="formAtleta.categoria_id" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2">
            <option value="" disabled>Categoria...</option>
            <option v-for="c in categorias" :key="c.id" :value="c.id">{{ nomeCategoria(c) }}</option>
          </select>
          <input v-model="formAtleta.escola" placeholder="Escola (opcional)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
        </div>

        <p class="font-mono-label text-[9px] font-bold text-ink-soft pt-2">RESPONSÁVEL</p>
        <div class="flex gap-2">
          <button type="button" class="rounded-full px-3 py-1.5 text-xs font-semibold" :class="formAtleta.responsavelModo === 'existente' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft'" @click="formAtleta.responsavelModo = 'existente'">Já cadastrado</button>
          <button type="button" class="rounded-full px-3 py-1.5 text-xs font-semibold" :class="formAtleta.responsavelModo === 'novo' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft'" @click="formAtleta.responsavelModo = 'novo'">Cadastrar novo</button>
        </div>

        <div v-if="formAtleta.responsavelModo === 'existente'">
          <select v-model="formAtleta.responsavelId" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm">
            <option value="" disabled>Selecione o responsável...</option>
            <option v-for="r in responsaveisDisponiveis" :key="r.id" :value="r.id">{{ r.nome }} — {{ r.telefone }}</option>
          </select>
        </div>
        <div v-else class="grid gap-3 sm:grid-cols-2">
          <input v-model="formAtleta.respNome" placeholder="Nome do responsável" class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
          <input v-model="formAtleta.respTelefone" placeholder="WhatsApp" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <input v-model="formAtleta.respEmail" placeholder="E-mail (opcional)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <input v-model="formAtleta.respSenha" type="password" placeholder="Senha de acesso" class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
        </div>

        <input v-model="formAtleta.parentesco" placeholder="Parentesco (ex: mãe, pai, avó)" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />

        <p v-if="erroAtleta" class="text-xs text-brand-deep">{{ erroAtleta }}</p>

        <div class="flex gap-2">
          <button type="submit" :disabled="salvandoAtleta" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ salvandoAtleta ? 'Salvando...' : 'Salvar atleta' }}</button>
          <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="mostrarFormAtleta = false">Cancelar</button>
        </div>
      </form>

      <div v-if="atletas.length === 0" class="mt-6 rounded-2xl border border-dashed border-ink/15 p-8 text-center">
        <Icon name="users" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Nenhum atleta cadastrado ainda.</p>
      </div>

      <div v-else class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
        <div v-for="a in atletas" :key="a.id" class="px-5 py-3.5">
          <div class="flex items-center justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-ink">{{ a.nome }}</p>
              <p class="text-xs text-ink-soft">{{ nomeCategoria(categoriaDoAtleta(a)) }} · {{ idadeAtual(a.data_nascimento) }} anos {{ a.profile_id ? '· acesso ativo' : '' }}</p>
            </div>
            <div class="flex items-center gap-2">
              <span :class="['rounded-full px-3 py-1 text-xs font-semibold', statusAtletaClasses(a.status)]">{{ statusAtletaLabel(a.status) }}</span>
              <button class="text-xs font-semibold text-brand-deep hover:underline" @click="editandoGestaoId = editandoGestaoId === a.id ? null : a.id">{{ editandoGestaoId === a.id ? 'Fechar' : 'Gerenciar' }}</button>
            </div>
          </div>

          <div v-if="editandoGestaoId === a.id" class="mt-3 flex flex-wrap items-center gap-2 rounded-xl bg-paper-dim p-3">
            <select :value="a.categoria_id" class="rounded-lg border border-ink/15 px-2 py-1.5 text-xs" @change="(e) => salvarGestaoAtleta(a, e.target.value, a.status)">
              <option v-for="c in categorias" :key="c.id" :value="c.id">{{ nomeCategoria(c) }}</option>
            </select>
            <select :value="a.status" class="rounded-lg border border-ink/15 px-2 py-1.5 text-xs" @change="(e) => salvarGestaoAtleta(a, a.categoria_id, e.target.value)">
              <option v-for="s in statusAtletaOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
            </select>
          </div>
        </div>
      </div>
    </div>

    <!-- ===== CATEGORIAS ===== -->
    <div v-else-if="aba === 'categorias'" class="mt-6">
      <button v-if="!mostrarFormCategoria" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep" @click="mostrarFormCategoria = true">+ Nova categoria</button>

      <form v-if="mostrarFormCategoria" class="mt-4 flex flex-wrap items-end gap-3 rounded-2xl bg-white p-5 shadow-card" @submit.prevent="salvarCategoria">
        <input v-model="formCategoria.nome" placeholder="Nome (ex: Sub-17)" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <select v-model="formCategoria.sexo" class="rounded-lg border border-ink/15 px-3 py-2 text-sm">
          <option v-for="s in sexoOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
        </select>
        <input v-model.number="formCategoria.faixa_etaria_min" type="number" placeholder="Idade mín." class="w-28 rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model.number="formCategoria.faixa_etaria_max" type="number" placeholder="Idade máx." class="w-28 rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
        <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="mostrarFormCategoria = false">Cancelar</button>
      </form>

      <div class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
        <div v-for="c in categorias" :key="c.id" class="flex items-center justify-between gap-3 px-5 py-3.5">
          <div>
            <p class="text-sm font-semibold text-ink">{{ nomeCategoria(c) }}</p>
            <p class="text-xs text-ink-soft" v-if="c.faixa_etaria_min || c.faixa_etaria_max">{{ c.faixa_etaria_min ?? '?' }}–{{ c.faixa_etaria_max ?? '?' }} anos</p>
          </div>
          <button class="rounded-full px-3 py-1 text-xs font-semibold" :class="c.ativo ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-ink/8 text-ink-soft'" @click="alternarAtivoCategoria(c)">{{ c.ativo ? 'ativa' : 'inativa' }}</button>
        </div>
      </div>
    </div>

    <!-- ===== PLANOS ===== -->
    <div v-else class="mt-6">
      <button v-if="!mostrarFormPlano" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep" @click="mostrarFormPlano = true">+ Novo plano</button>

      <form v-if="mostrarFormPlano" class="mt-4 space-y-3 rounded-2xl bg-white p-5 shadow-card" @submit.prevent="salvarPlano">
        <input v-model="formPlano.nome" placeholder="Nome do plano" required class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model.number="formPlano.valor_mensal" type="number" step="0.01" placeholder="Valor mensal (0 = gratuito)" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formPlano.descricao" placeholder="Descrição (opcional)" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <div class="flex gap-2">
          <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
          <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="mostrarFormPlano = false">Cancelar</button>
        </div>
      </form>

      <div class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
        <div v-for="p in planos" :key="p.id" class="flex items-center justify-between gap-3 px-5 py-3.5">
          <div>
            <p class="text-sm font-semibold text-ink">{{ p.nome }} <span v-if="p.padrao" class="ml-1 rounded-full bg-gold-soft px-2 py-0.5 text-[10px] font-bold text-ink">PADRÃO</span></p>
            <p class="text-xs text-ink-soft">{{ brl(p.valor_mensal) }}/mês <span v-if="p.descricao"> · {{ p.descricao }}</span></p>
          </div>
          <div class="flex items-center gap-2">
            <button v-if="!p.padrao" class="text-xs font-semibold text-brand-deep hover:underline" @click="definirPlanoPadrao(p)">Tornar padrão</button>
            <button class="rounded-full px-3 py-1 text-xs font-semibold" :class="p.ativo ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-ink/8 text-ink-soft'" @click="alternarAtivoPlano(p)">{{ p.ativo ? 'ativo' : 'inativo' }}</button>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>
