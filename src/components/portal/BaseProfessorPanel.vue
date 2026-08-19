<script setup>
import { ref, computed, onMounted, defineAsyncComponent } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'
import AvatarUpload from './AvatarUpload.vue'
import StarRating from './StarRating.vue'
import AudioRecorder from './AudioRecorder.vue'
import {
  idadeAtual, nomeCategoria, statusAtletaLabel, statusAtletaClasses,
  posicaoLabel, tipoEventoLabel, formatarHora,
  estrelasFromNota, notaFromEstrelas, statusExecucaoLabel, statusExecucaoClasses,
} from '../../data/base.js'
import { formatarDataCurta } from '../../data/campeonatos.js'

const MensagensBase = defineAsyncComponent(() => import('./MensagensBase.vue'))

const { profile, logout } = useAuth()

const aba = ref('aulas')
const carregando = ref(true)
const atletas = ref([])
const categorias = ref([])
const categoriaFiltro = ref('todas')

async function carregar() {
  carregando.value = true
  const [{ data: atletasData }, { data: categoriasData }] = await Promise.all([
    supabase.from('atletas_base').select('*').order('nome'),
    supabase.from('categorias_base').select('*').eq('ativo', true).order('nome'),
  ])
  atletas.value = atletasData ?? []
  categorias.value = categoriasData ?? []
  carregando.value = false
}

const atletasFiltrados = computed(() => {
  if (categoriaFiltro.value === 'todas') return atletas.value
  return atletas.value.filter((a) => a.categoria_id === categoriaFiltro.value)
})

function categoriaDoAtleta(atleta) {
  return categorias.value.find((c) => c.id === atleta.categoria_id)
}

// ================================================================
// Mensagens — só o resumo (contagem de não lidas) pro sino do
// cabeçalho; a caixa de fato é a aba "Mensagens" (MensagensBase
// embutido, mesma tela que a coordenação usa).
// ================================================================
const canaisMensagens = ref([])
async function carregarResumoMensagens() {
  const { data } = await supabase.rpc('listar_canais_mensagens_base')
  canaisMensagens.value = data ?? []
}
const totalMensagensNaoLidas = computed(() => canaisMensagens.value.reduce((s, c) => s + (c.nao_lidas || 0), 0))

onMounted(() => {
  carregar()
  carregarResumoMensagens()
})

// ================================================================
// Eventos — preparo da aula, chamada, iniciar/finalizar treino,
// avaliação por estrelas + observações (texto/áudio), relatório.
// ================================================================
const eventos = ref([])
const eventosCarregados = ref(false)
const eventoSelecionadoId = ref(null)
const participantesDoEvento = ref({}) // atleta_id -> row
const exerciciosDoEvento = ref([])
const carregandoDetalheEvento = ref(false)

async function carregarEventos() {
  if (eventosCarregados.value) return
  const { data } = await supabase.from('eventos_base').select('*').order('data', { ascending: false }).limit(60)
  eventos.value = data ?? []
  eventosCarregados.value = true
}

const eventoSelecionado = computed(() => eventos.value.find((e) => e.id === eventoSelecionadoId.value) ?? null)

const atletasDoEventoSelecionado = computed(() => {
  if (!eventoSelecionado.value) return []
  if (!eventoSelecionado.value.categoria_id) return atletas.value
  return atletas.value.filter((a) => a.categoria_id === eventoSelecionado.value.categoria_id)
})

async function selecionarEvento(evento) {
  eventoSelecionadoId.value = evento.id
  carregandoDetalheEvento.value = true
  const [{ data: participantes }, { data: exercicios }] = await Promise.all([
    supabase.from('evento_participantes_base').select('*').eq('evento_id', evento.id),
    supabase.from('evento_exercicios_base').select('*').eq('evento_id', evento.id).order('ordem'),
  ])
  const mapa = {}
  for (const p of participantes ?? []) mapa[p.atleta_id] = p
  participantesDoEvento.value = mapa
  exerciciosDoEvento.value = exercicios ?? []
  carregandoDetalheEvento.value = false
}

function participanteDoAtleta(atletaId) {
  return participantesDoEvento.value[atletaId] ?? { presente: null, desempenho_nota: null, desempenho_obs: '', desempenho_obs_audio_url: null }
}

async function salvarParticipante(atletaId, patch) {
  const atual = participanteDoAtleta(atletaId)
  const linha = {
    evento_id: eventoSelecionadoId.value, atleta_id: atletaId,
    presente: patch.presente !== undefined ? patch.presente : atual.presente,
    desempenho_nota: patch.desempenho_nota !== undefined ? patch.desempenho_nota : atual.desempenho_nota,
    desempenho_obs: patch.desempenho_obs !== undefined ? patch.desempenho_obs : atual.desempenho_obs,
    desempenho_obs_audio_url: patch.desempenho_obs_audio_url !== undefined ? patch.desempenho_obs_audio_url : atual.desempenho_obs_audio_url,
    atualizado_em: new Date().toISOString(),
  }
  const { data, error } = await supabase
    .from('evento_participantes_base')
    .upsert(linha, { onConflict: 'evento_id,atleta_id' })
    .select()
    .single()
  if (!error) participantesDoEvento.value[atletaId] = data
}

function salvarEstrelasAtleta(atletaId, estrelas) {
  salvarParticipante(atletaId, { desempenho_nota: notaFromEstrelas(estrelas) })
}

// --- Chamada: contagem pra dar o "empurrão" antes de iniciar o treino ---
const registrosPresenca = computed(() => atletasDoEventoSelecionado.value.map((a) => participanteDoAtleta(a.id)))
const totalRegistrados = computed(() => registrosPresenca.value.filter((p) => p.presente !== null).length)
const totalPresentes = computed(() => registrosPresenca.value.filter((p) => p.presente === true).length)

// --- Preparo da aula: objetivo, resumo das atividades, exercícios ---
async function salvarCampoEvento(campo, valor) {
  const { data, error } = await supabase.from('eventos_base').update({ [campo]: valor }).eq('id', eventoSelecionado.value.id).select().single()
  if (!error) Object.assign(eventoSelecionado.value, data)
}

const novoExercicio = ref({ nome: '', descricao: '', duracao_min: null })
const salvandoExercicio = ref(false)

async function adicionarExercicio() {
  if (!novoExercicio.value.nome.trim()) return
  salvandoExercicio.value = true
  const { data, error } = await supabase.from('evento_exercicios_base').insert({
    evento_id: eventoSelecionadoId.value,
    ordem: exerciciosDoEvento.value.length,
    nome: novoExercicio.value.nome.trim(),
    descricao: novoExercicio.value.descricao.trim() || null,
    duracao_min: novoExercicio.value.duracao_min || null,
  }).select().single()
  salvandoExercicio.value = false
  if (!error) {
    exerciciosDoEvento.value.push(data)
    novoExercicio.value = { nome: '', descricao: '', duracao_min: null }
  }
}

async function removerExercicio(ex) {
  const { error } = await supabase.from('evento_exercicios_base').delete().eq('id', ex.id)
  if (!error) exerciciosDoEvento.value = exerciciosDoEvento.value.filter((e) => e.id !== ex.id)
}

// --- Iniciar / finalizar / reabrir o treino ---
const alterandoStatus = ref(false)

async function iniciarTreino() {
  alterandoStatus.value = true
  const { data, error } = await supabase.from('eventos_base')
    .update({ status_execucao: 'em_andamento', iniciado_em: new Date().toISOString() })
    .eq('id', eventoSelecionado.value.id)
    .select()
    .single()
  alterandoStatus.value = false
  if (!error) Object.assign(eventoSelecionado.value, data)
}

async function finalizarTreino() {
  alterandoStatus.value = true
  const { data, error } = await supabase.from('eventos_base')
    .update({ status_execucao: 'concluido', concluido_em: new Date().toISOString() })
    .eq('id', eventoSelecionado.value.id)
    .select()
    .single()
  alterandoStatus.value = false
  if (!error) Object.assign(eventoSelecionado.value, data)
}

async function reabrirTreino() {
  alterandoStatus.value = true
  const { data, error } = await supabase.from('eventos_base')
    .update({ status_execucao: 'em_andamento', concluido_em: null })
    .eq('id', eventoSelecionado.value.id)
    .select()
    .single()
  alterandoStatus.value = false
  if (!error) Object.assign(eventoSelecionado.value, data)
}

function duracaoTreinoMin(evento) {
  if (!evento.iniciado_em || !evento.concluido_em) return null
  return Math.round((new Date(evento.concluido_em) - new Date(evento.iniciado_em)) / 60000)
}

// iniciado_em/concluido_em sao timestamptz (UTC) — formata no horario
// local do navegador, nao so corta a string (senao mostra hora UTC).
function horaLocal(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })
}

// ================================================================
// Meu perfil — foto, nome, telefone, e-mail, senha
// ================================================================
const formPerfil = ref({ nome: profile.value?.nome ?? '', telefone: profile.value?.telefone ?? '', email: profile.value?.email ?? '' })
const salvandoPerfil = ref(false)
const erroPerfil = ref('')
const sucessoPerfil = ref('')

async function salvarPerfil() {
  erroPerfil.value = ''
  sucessoPerfil.value = ''
  if (!formPerfil.value.nome.trim()) {
    erroPerfil.value = 'O nome não pode ficar em branco.'
    return
  }
  salvandoPerfil.value = true
  const { error } = await supabase.rpc('atualizar_meu_perfil_professor_base', {
    p_nome: formPerfil.value.nome, p_telefone: formPerfil.value.telefone, p_email: formPerfil.value.email,
  })
  salvandoPerfil.value = false
  if (error) {
    erroPerfil.value = 'Não foi possível salvar: ' + error.message
    return
  }
  profile.value.nome = formPerfil.value.nome.trim()
  profile.value.telefone = formPerfil.value.telefone.trim() || null
  profile.value.email = formPerfil.value.email.trim() || null
  sucessoPerfil.value = 'Dados atualizados!'
}

function aoAtualizarMinhaFoto(url) {
  profile.value.avatar_url = url
}

const novaSenha = ref('')
const trocandoSenha = ref(false)
const erroSenha = ref('')
const sucessoSenha = ref('')

async function trocarMinhaSenha() {
  erroSenha.value = ''
  sucessoSenha.value = ''
  if (novaSenha.value.length < 6) {
    erroSenha.value = 'A senha precisa ter pelo menos 6 caracteres.'
    return
  }
  trocandoSenha.value = true
  const { error } = await supabase.auth.updateUser({ password: novaSenha.value })
  trocandoSenha.value = false
  if (error) {
    erroSenha.value = 'Não foi possível trocar a senha: ' + error.message
    return
  }
  novaSenha.value = ''
  sucessoSenha.value = 'Senha atualizada!'
}
</script>

<template>
  <div>
    <div class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <p class="font-mono-label text-[11px] font-bold text-brand-deep">Professor · Categorias de Base</p>
        <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">
          {{ { aulas: 'Minhas aulas', atletas: 'Meus atletas', mensagens: 'Mensagens', perfil: 'Meu perfil' }[aba] }}
        </h1>
      </div>
      <div class="flex items-center gap-3">
        <span class="hidden text-xs text-ink-soft sm:inline">Logado como {{ profile?.nome }}</span>

        <!-- Sino de notificações — abre a aba de mensagens -->
        <button
          class="relative flex h-9 w-9 items-center justify-center rounded-full border border-ink/15 text-ink-soft hover:border-ink/30"
          title="Mensagens"
          @click="aba = 'mensagens'"
        >
          <Icon name="mail" class="h-4 w-4" />
          <span v-if="totalMensagensNaoLidas > 0" class="absolute -right-1 -top-1 flex h-4 min-w-[16px] items-center justify-center rounded-full bg-brand px-1 text-[9px] font-bold text-white">{{ totalMensagensNaoLidas }}</span>
        </button>

        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
      </div>
    </div>

    <div class="mt-6 flex flex-wrap gap-2">
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'aulas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'aulas'; carregarEventos()">Minhas aulas</button>
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'atletas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'atletas'">Atletas</button>
      <button class="relative rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'mensagens' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'mensagens'">
        Mensagens
        <span v-if="totalMensagensNaoLidas > 0" class="ml-1 rounded-full bg-brand px-1.5 py-0.5 text-[9px] font-bold text-white">{{ totalMensagensNaoLidas }}</span>
      </button>
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'perfil' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'perfil'">Meu perfil</button>
    </div>

    <!-- ===== ATLETAS ===== -->
    <div v-if="aba === 'atletas'" class="mt-6">
      <div class="flex flex-wrap gap-2">
        <button
          class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
          :class="categoriaFiltro === 'todas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
          @click="categoriaFiltro = 'todas'"
        >Todas</button>
        <button
          v-for="c in categorias"
          :key="c.id"
          class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
          :class="categoriaFiltro === c.id ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
          @click="categoriaFiltro = c.id"
        >{{ nomeCategoria(c) }}</button>
      </div>

      <p v-if="carregando" class="mt-8 text-sm text-ink-soft">Carregando...</p>

      <div v-else-if="atletasFiltrados.length === 0" class="mt-8 rounded-2xl border border-dashed border-ink/15 p-8 text-center">
        <Icon name="users" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Nenhum atleta cadastrado nessa categoria ainda.</p>
      </div>

      <div v-else class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
        <div v-for="a in atletasFiltrados" :key="a.id" class="flex items-center justify-between gap-3 px-5 py-3.5">
          <div>
            <p class="text-sm font-semibold text-ink">{{ a.nome }}</p>
            <p class="text-xs text-ink-soft">{{ nomeCategoria(categoriaDoAtleta(a)) }} · {{ idadeAtual(a.data_nascimento) }} anos<span v-if="a.posicao"> · {{ posicaoLabel(a.posicao) }}</span></p>
          </div>
          <span :class="['rounded-full px-3 py-1 text-xs font-semibold', statusAtletaClasses(a.status)]">{{ statusAtletaLabel(a.status) }}</span>
        </div>
      </div>
    </div>

    <!-- ===== MENSAGENS ===== -->
    <MensagensBase v-else-if="aba === 'mensagens'" class="mt-6" :embedded="true" />

    <!-- ===== MEU PERFIL ===== -->
    <div v-else-if="aba === 'perfil'" class="mt-6 max-w-lg space-y-5">
      <div class="rounded-2xl bg-white p-6 shadow-card">
        <p class="font-mono-label text-[9px] font-bold text-ink-soft">FOTO E DADOS</p>
        <div class="mt-3 flex items-center gap-3">
          <AvatarUpload :profile-id="profile.id" :avatar-url="profile?.avatar_url" :nome="profile?.nome" editable size="md" @update:avatar-url="aoAtualizarMinhaFoto" />
          <p class="text-xs text-ink-soft">Clique na foto pra trocar.</p>
        </div>

        <form class="mt-4 grid gap-3 sm:grid-cols-2" @submit.prevent="salvarPerfil">
          <input v-model="formPerfil.nome" placeholder="Seu nome" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
          <input v-model="formPerfil.telefone" placeholder="Telefone / WhatsApp" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <input v-model="formPerfil.email" type="email" placeholder="E-mail" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <div class="sm:col-span-2 flex items-center gap-3">
            <button type="submit" :disabled="salvandoPerfil" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ salvandoPerfil ? 'Salvando...' : 'Salvar dados' }}</button>
            <p v-if="erroPerfil" class="text-xs text-brand-deep">{{ erroPerfil }}</p>
            <p v-if="sucessoPerfil" class="text-xs text-[#27500A]">{{ sucessoPerfil }}</p>
          </div>
        </form>

        <form class="mt-4 flex flex-wrap items-center gap-3 border-t border-ink/10 pt-4" @submit.prevent="trocarMinhaSenha">
          <input v-model="novaSenha" type="password" placeholder="Nova senha (mín. 6 caracteres)" class="min-w-0 flex-1 rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <button type="submit" :disabled="trocandoSenha" class="rounded-full bg-ink px-4 py-2 text-xs font-bold text-white hover:bg-ink/90 disabled:opacity-50">{{ trocandoSenha ? 'Trocando...' : 'Trocar senha' }}</button>
          <p v-if="erroSenha" class="w-full text-xs text-brand-deep">{{ erroSenha }}</p>
          <p v-if="sucessoSenha" class="w-full text-xs text-[#27500A]">{{ sucessoSenha }}</p>
        </form>
      </div>
    </div>

    <!-- ===== MINHAS AULAS ===== -->
    <div v-else class="mt-6 grid gap-4 lg:grid-cols-[18rem_1fr]">
      <div class="max-h-[40rem] overflow-y-auto rounded-2xl bg-white shadow-card">
        <button
          v-for="e in eventos" :key="e.id"
          type="button"
          class="block w-full border-b border-ink/8 px-4 py-3 text-left text-xs last:border-0 hover:bg-paper-dim"
          :class="eventoSelecionadoId === e.id ? 'bg-paper-dim' : ''"
          @click="selecionarEvento(e)"
        >
          <div class="flex items-center justify-between gap-2">
            <p class="font-semibold text-ink">{{ e.titulo }}</p>
            <span :class="['flex-shrink-0 rounded-full px-2 py-0.5 text-[9px] font-semibold', statusExecucaoClasses(e.status_execucao)]">{{ statusExecucaoLabel(e.status_execucao) }}</span>
          </div>
          <p class="text-ink-soft">{{ tipoEventoLabel(e.tipo) }} · {{ formatarDataCurta(e.data) }}</p>
        </button>
        <p v-if="eventosCarregados && eventos.length === 0" class="px-4 py-6 text-center text-xs text-ink-soft">Nenhum evento cadastrado ainda — a coordenação cadastra em Categorias de Base → Eventos.</p>
      </div>

      <div v-if="carregandoDetalheEvento" class="rounded-2xl border border-dashed border-ink/15 p-8 text-center text-sm text-ink-soft">Carregando...</div>

      <div v-else-if="eventoSelecionado" class="space-y-4">
        <!-- Cabeçalho do evento -->
        <div class="rounded-2xl bg-white p-5 shadow-card">
          <div class="flex flex-wrap items-center justify-between gap-2">
            <p class="text-sm font-bold text-ink">{{ eventoSelecionado.titulo }}</p>
            <span :class="['rounded-full px-3 py-1 text-xs font-semibold', statusExecucaoClasses(eventoSelecionado.status_execucao)]">{{ statusExecucaoLabel(eventoSelecionado.status_execucao) }}</span>
          </div>
          <p class="text-xs text-ink-soft">
            {{ tipoEventoLabel(eventoSelecionado.tipo) }} · {{ formatarDataCurta(eventoSelecionado.data) }}
            <span v-if="eventoSelecionado.hora_inicio"> · {{ formatarHora(eventoSelecionado.hora_inicio) }}</span>
            <span v-if="eventoSelecionado.local"> · {{ eventoSelecionado.local }}</span>
          </p>
        </div>

        <!-- Preparo da aula -->
        <div class="rounded-2xl bg-white p-5 shadow-card">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">PREPARO DA AULA</p>

          <div class="mt-3">
            <label class="text-xs font-semibold text-ink-soft">Objetivo da aula</label>
            <textarea
              :value="eventoSelecionado.objetivo"
              placeholder="Ex: melhorar a recepção de saque e o posicionamento em quadra"
              rows="2"
              class="mt-1 w-full rounded-lg border border-ink/15 px-3 py-2 text-sm"
              @change="(ev) => salvarCampoEvento('objetivo', ev.target.value)"
            ></textarea>
          </div>

          <div class="mt-3">
            <label class="text-xs font-semibold text-ink-soft">Resumo das atividades (aparece pro responsável e pro atleta no histórico)</label>
            <textarea
              :value="eventoSelecionado.plano_atividades"
              placeholder="O que foi/será trabalhado nessa aula"
              rows="2"
              class="mt-1 w-full rounded-lg border border-ink/15 px-3 py-2 text-sm"
              @change="(ev) => salvarCampoEvento('plano_atividades', ev.target.value)"
            ></textarea>
          </div>

          <div class="mt-4 border-t border-ink/10 pt-3">
            <p class="text-xs font-semibold text-ink-soft">Exercícios</p>
            <div v-if="exerciciosDoEvento.length" class="mt-2 space-y-1.5">
              <div v-for="(ex, i) in exerciciosDoEvento" :key="ex.id" class="flex items-start justify-between gap-2 rounded-lg bg-paper-dim px-3 py-2 text-xs">
                <div>
                  <p class="font-semibold text-ink">{{ i + 1 }}. {{ ex.nome }}<span v-if="ex.duracao_min"> · {{ ex.duracao_min }} min</span></p>
                  <p v-if="ex.descricao" class="text-ink-soft">{{ ex.descricao }}</p>
                </div>
                <button type="button" class="flex-shrink-0 text-ink-soft hover:text-brand-deep" title="Remover" @click="removerExercicio(ex)">
                  <Icon name="trash" class="h-3.5 w-3.5" />
                </button>
              </div>
            </div>
            <p v-else class="mt-2 text-xs text-ink-soft">Nenhum exercício adicionado ainda.</p>

            <form class="mt-3 grid gap-2 sm:grid-cols-[1fr_1fr_5rem_auto]" @submit.prevent="adicionarExercicio">
              <input v-model="novoExercicio.nome" placeholder="Nome do exercício" class="rounded-lg border border-ink/15 px-3 py-2 text-xs" />
              <input v-model="novoExercicio.descricao" placeholder="Descrição (opcional)" class="rounded-lg border border-ink/15 px-3 py-2 text-xs" />
              <input v-model.number="novoExercicio.duracao_min" type="number" min="0" placeholder="Min" class="rounded-lg border border-ink/15 px-3 py-2 text-xs" />
              <button type="submit" :disabled="salvandoExercicio || !novoExercicio.nome.trim()" class="rounded-full bg-ink px-4 py-2 text-xs font-bold text-white hover:bg-ink/90 disabled:opacity-50">+ Add</button>
            </form>
          </div>
        </div>

        <!-- Chamada -->
        <div class="rounded-2xl bg-white p-5 shadow-card">
          <div class="flex items-center justify-between">
            <p class="font-mono-label text-[9px] font-bold text-ink-soft">CHAMADA</p>
            <p class="text-xs text-ink-soft">{{ totalPresentes }} presentes · {{ totalRegistrados }}/{{ atletasDoEventoSelecionado.length }} registrados</p>
          </div>

          <div class="mt-3 divide-y divide-ink/8 rounded-xl bg-paper-dim">
            <div v-for="a in atletasDoEventoSelecionado" :key="a.id" class="flex flex-wrap items-center gap-2 px-4 py-2.5">
              <span class="min-w-[9rem] flex-1 text-sm text-ink">{{ a.nome }}</span>
              <div class="flex gap-1.5">
                <button
                  type="button"
                  class="rounded-full px-3 py-1 text-xs font-semibold transition-colors"
                  :class="participanteDoAtleta(a.id).presente === true ? 'bg-[#27500A] text-white' : 'bg-white text-ink-soft border border-ink/15 hover:border-[#27500A]'"
                  @click="salvarParticipante(a.id, { presente: true })"
                >✓ Presente</button>
                <button
                  type="button"
                  class="rounded-full px-3 py-1 text-xs font-semibold transition-colors"
                  :class="participanteDoAtleta(a.id).presente === false ? 'bg-brand-deep text-white' : 'bg-white text-ink-soft border border-ink/15 hover:border-brand-deep'"
                  @click="salvarParticipante(a.id, { presente: false })"
                >✕ Ausente</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Ações de fluxo -->
        <div v-if="eventoSelecionado.status_execucao === 'planejado'" class="rounded-2xl bg-white p-5 text-center shadow-card">
          <p class="text-xs text-ink-soft">Feita a chamada, é só iniciar o treino — o cronômetro da aula começa a contar.</p>
          <button type="button" :disabled="alterandoStatus" class="mt-3 rounded-full bg-brand px-6 py-2.5 text-sm font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="iniciarTreino">
            ▶ Iniciar treino
          </button>
        </div>

        <!-- Avaliação (durante o treino) -->
        <div v-if="eventoSelecionado.status_execucao === 'em_andamento'" class="rounded-2xl bg-white p-5 shadow-card">
          <div class="flex flex-wrap items-center justify-between gap-2">
            <p class="font-mono-label text-[9px] font-bold text-ink-soft">TREINO EM ANDAMENTO — INICIADO ÀS {{ horaLocal(eventoSelecionado.iniciado_em) }}</p>
          </div>

          <div class="mt-3">
            <label class="text-xs font-semibold text-ink-soft">Observação geral do treino (vale pra todos)</label>
            <textarea
              :value="eventoSelecionado.observacoes"
              placeholder="Como foi o treino no geral..."
              rows="2"
              class="mt-1 w-full rounded-lg border border-ink/15 px-3 py-2 text-sm"
              @change="(ev) => salvarCampoEvento('observacoes', ev.target.value)"
            ></textarea>
            <div class="mt-2">
              <AudioRecorder
                :model-value="eventoSelecionado.observacoes_audio_url"
                :path-prefix="`evento-${eventoSelecionado.id}/geral`"
                @update:model-value="(url) => salvarCampoEvento('observacoes_audio_url', url)"
              />
            </div>
          </div>

          <div class="mt-4 divide-y divide-ink/8 border-t border-ink/10 pt-3">
            <p class="pb-2 text-xs font-semibold text-ink-soft">Avaliação por atleta</p>
            <div v-for="a in atletasDoEventoSelecionado" :key="a.id" class="py-3">
              <div class="flex flex-wrap items-center justify-between gap-2">
                <span class="text-sm font-semibold text-ink">{{ a.nome }}</span>
                <StarRating
                  :model-value="estrelasFromNota(participanteDoAtleta(a.id).desempenho_nota)"
                  size="h-5 w-5"
                  @update:model-value="(n) => salvarEstrelasAtleta(a.id, n)"
                />
              </div>
              <textarea
                :value="participanteDoAtleta(a.id).desempenho_obs"
                placeholder="Observação sobre este atleta..."
                rows="1"
                class="mt-1.5 w-full rounded-lg border border-ink/15 px-3 py-1.5 text-xs"
                @change="(ev) => salvarParticipante(a.id, { desempenho_obs: ev.target.value })"
              ></textarea>
              <div class="mt-1.5">
                <AudioRecorder
                  :model-value="participanteDoAtleta(a.id).desempenho_obs_audio_url"
                  :path-prefix="`evento-${eventoSelecionado.id}/atleta-${a.id}`"
                  @update:model-value="(url) => salvarParticipante(a.id, { desempenho_obs_audio_url: url })"
                />
              </div>
            </div>
          </div>

          <button type="button" :disabled="alterandoStatus" class="mt-4 w-full rounded-full bg-ink px-6 py-2.5 text-sm font-bold text-white hover:bg-ink/90 disabled:opacity-50" @click="finalizarTreino">
            ■ Finalizar treino
          </button>
        </div>

        <!-- Relatório (treino concluído) -->
        <div v-if="eventoSelecionado.status_execucao === 'concluido'" class="rounded-2xl bg-white p-5 shadow-card">
          <div class="flex items-center justify-between">
            <p class="font-mono-label text-[9px] font-bold text-ink-soft">RELATÓRIO DO TREINO</p>
            <button type="button" class="text-xs font-semibold text-brand-deep hover:underline" @click="reabrirTreino">Reabrir pra corrigir</button>
          </div>

          <dl class="mt-3 space-y-1.5 text-xs">
            <div v-if="eventoSelecionado.objetivo" class="flex gap-2"><dt class="flex-shrink-0 font-semibold text-ink-soft">Objetivo:</dt><dd class="text-ink">{{ eventoSelecionado.objetivo }}</dd></div>
            <div v-if="duracaoTreinoMin(eventoSelecionado)" class="flex gap-2"><dt class="flex-shrink-0 font-semibold text-ink-soft">Duração:</dt><dd class="text-ink">{{ duracaoTreinoMin(eventoSelecionado) }} min</dd></div>
            <div class="flex gap-2"><dt class="flex-shrink-0 font-semibold text-ink-soft">Presença:</dt><dd class="text-ink">{{ totalPresentes }} de {{ atletasDoEventoSelecionado.length }}</dd></div>
          </dl>

          <div v-if="exerciciosDoEvento.length" class="mt-3 border-t border-ink/10 pt-3">
            <p class="text-xs font-semibold text-ink-soft">Exercícios realizados</p>
            <ol class="mt-1 list-decimal space-y-0.5 pl-4 text-xs text-ink">
              <li v-for="ex in exerciciosDoEvento" :key="ex.id">{{ ex.nome }}<span v-if="ex.duracao_min"> ({{ ex.duracao_min }} min)</span></li>
            </ol>
          </div>

          <div v-if="eventoSelecionado.observacoes || eventoSelecionado.observacoes_audio_url" class="mt-3 border-t border-ink/10 pt-3">
            <p class="text-xs font-semibold text-ink-soft">Observação geral</p>
            <p v-if="eventoSelecionado.observacoes" class="mt-1 text-xs text-ink">{{ eventoSelecionado.observacoes }}</p>
            <audio v-if="eventoSelecionado.observacoes_audio_url" :src="eventoSelecionado.observacoes_audio_url" controls class="mt-1 h-8" />
          </div>

          <div class="mt-3 divide-y divide-ink/8 border-t border-ink/10 pt-3">
            <p class="pb-2 text-xs font-semibold text-ink-soft">Avaliação por atleta</p>
            <div v-for="a in atletasDoEventoSelecionado" :key="a.id" class="flex flex-wrap items-center justify-between gap-2 py-2 text-xs">
              <div>
                <p class="font-semibold text-ink">{{ a.nome }} <span :class="participanteDoAtleta(a.id).presente ? 'text-[#27500A]' : 'text-brand-deep'">· {{ participanteDoAtleta(a.id).presente ? 'presente' : 'ausente' }}</span></p>
                <p v-if="participanteDoAtleta(a.id).desempenho_obs" class="text-ink-soft">{{ participanteDoAtleta(a.id).desempenho_obs }}</p>
                <audio v-if="participanteDoAtleta(a.id).desempenho_obs_audio_url" :src="participanteDoAtleta(a.id).desempenho_obs_audio_url" controls class="mt-1 h-7" />
              </div>
              <StarRating :model-value="estrelasFromNota(participanteDoAtleta(a.id).desempenho_nota)" readonly size="h-4 w-4" />
            </div>
          </div>
        </div>
      </div>

      <div v-else class="rounded-2xl border border-dashed border-ink/15 p-8 text-center text-sm text-ink-soft">
        Selecione uma aula na lista pra preparar, fazer a chamada e avaliar.
      </div>
    </div>
  </div>
</template>
