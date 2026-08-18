<script setup>
import { ref, computed, onMounted } from 'vue'
import { createClient } from '@supabase/supabase-js'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'
import AvatarUpload from './AvatarUpload.vue'
import { formatarData } from '../../lib/categoria.js'
import { brl, formatarDataCurta } from '../../data/campeonatos.js'
import { formatarCompetencia } from '../../data/financeiro.js'
import {
  statusAtletaLabel, statusAtletaClasses, idadeAtual, nomeCategoria,
  mensalidadeBaseStatusLabel, mensalidadeBaseStatusClasses,
  posicaoLabel, tipoEventoLabel, tipoAvaliacaoLabel, statusFinanceiroBaseClasses,
  tempoNoProjeto, destinoMensagemOptions, destinoMensagemLabel,
} from '../../data/base.js'

const { profile, logout } = useAuth()

const carregando = ref(true)
const meusAtletas = ref([])

async function carregarMeusAtletas() {
  carregando.value = true

  const { data: vinculos } = await supabase
    .from('atleta_responsaveis')
    .select('atleta_id')
    .eq('responsavel_id', profile.value.id)

  const atletaIds = [...new Set((vinculos ?? []).map((v) => v.atleta_id))]
  if (atletaIds.length === 0) {
    meusAtletas.value = []
    carregando.value = false
    return
  }

  const [{ data: atletas }, { data: categorias }, { data: planosVigentes }, { data: mensalidades }, { data: eventosParticipados }, { data: avaliacoes }, { data: matriculas }] = await Promise.all([
    supabase.from('atletas_base').select('*').in('id', atletaIds),
    supabase.from('categorias_base').select('*'),
    supabase.from('atleta_plano').select('atleta_id, data_inicio, plano:planos_base(*)').in('atleta_id', atletaIds).is('data_fim', null),
    supabase.from('mensalidades_base').select('*').in('atleta_id', atletaIds).order('competencia', { ascending: false }),
    supabase.from('evento_participantes_base').select('*, evento:eventos_base(*)').in('atleta_id', atletaIds).order('criado_em', { ascending: false }),
    supabase.from('avaliacoes_atleta_base').select('*').in('atleta_id', atletaIds).order('data', { ascending: false }),
    supabase.from('matriculas_base').select('*').in('atleta_id', atletaIds),
  ])

  // Fotos e vídeos dos eventos/treinos que os atletas participaram
  const todosEventoIds = [...new Set((eventosParticipados ?? []).map((p) => p.evento_id))]
  const { data: midias } = todosEventoIds.length
    ? await supabase.from('evento_midias_base').select('*').in('evento_id', todosEventoIds).order('criado_em', { ascending: false })
    : { data: [] }

  meusAtletas.value = (atletas ?? []).map((a) => {
    const participacoesDoAtleta = (eventosParticipados ?? []).filter((p) => p.atleta_id === a.id && p.evento)
    const eventoIdsDoAtleta = new Set(participacoesDoAtleta.map((p) => p.evento_id))
    return {
      ...a,
      categoria: (categorias ?? []).find((c) => c.id === a.categoria_id) ?? null,
      planoVigente: (planosVigentes ?? []).find((p) => p.atleta_id === a.id) ?? null,
      mensalidades: (mensalidades ?? []).filter((m) => m.atleta_id === a.id),
      matricula: (matriculas ?? []).find((m) => m.atleta_id === a.id) ?? null,
      historicoEventos: participacoesDoAtleta.slice(0, 8).map((p) => ({ ...p, expandido: false })),
      avaliacoes: (avaliacoes ?? []).filter((v) => v.atleta_id === a.id),
      fotosEventos: (midias ?? []).filter((m) => eventoIdsDoAtleta.has(m.evento_id)),
      editando: false,
      formEdicao: { nome: a.nome, escola: a.escola ?? '', data_nascimento: a.data_nascimento },
      criandoLogin: false,
      senhaLogin: '',
      erroLogin: '',
    }
  })

  carregando.value = false
}

// ================================================================
// Meus dados de contato (telefone/e-mail do próprio responsável) e
// troca de senha — o responsável não é dono de nenhuma linha de
// atleta, é do próprio profile, por isso fica separado dos cards
// ================================================================
const mostrarMeusDados = ref(false)
const formMeusDados = ref({ telefone: profile.value?.telefone ?? '', email: profile.value?.email ?? '' })
const salvandoMeusDados = ref(false)
const erroMeusDados = ref('')
const sucessoMeusDados = ref('')

function abrirMeusDados() {
  formMeusDados.value = { telefone: profile.value?.telefone ?? '', email: profile.value?.email ?? '' }
  erroMeusDados.value = ''
  sucessoMeusDados.value = ''
  mostrarMeusDados.value = !mostrarMeusDados.value
}

async function salvarMeusDados() {
  erroMeusDados.value = ''
  sucessoMeusDados.value = ''
  salvandoMeusDados.value = true
  const { error } = await supabase.rpc('atualizar_meu_contato_responsavel_base', {
    p_telefone: formMeusDados.value.telefone, p_email: formMeusDados.value.email,
  })
  salvandoMeusDados.value = false
  if (error) {
    erroMeusDados.value = error.message
    return
  }
  profile.value.telefone = formMeusDados.value.telefone
  profile.value.email = formMeusDados.value.email
  sucessoMeusDados.value = 'Dados atualizados.'
}

const novaSenha = ref('')
const trocandoSenha = ref(false)
const erroSenha = ref('')
const sucessoSenha = ref('')

async function trocarMinhaSenha() {
  erroSenha.value = ''
  sucessoSenha.value = ''
  if (!novaSenha.value || novaSenha.value.length < 6) {
    erroSenha.value = 'A senha deve ter pelo menos 6 caracteres.'
    return
  }
  trocandoSenha.value = true
  const { error } = await supabase.auth.updateUser({ password: novaSenha.value })
  trocandoSenha.value = false
  if (error) {
    erroSenha.value = error.message
    return
  }
  novaSenha.value = ''
  sucessoSenha.value = 'Senha atualizada.'
}

// ================================================================
// Mensagens com a equipe do projeto (um canal por família) — o sino
// no cabeçalho é a central de notificações: mostra quantas mensagens
// da equipe ainda não foram vistas, e é onde o responsável escreve pra
// professor/financeiro/coordenação.
// ================================================================
const mensagens = ref([])
const novaMensagem = ref('')
const destinoMensagem = ref('geral')
const enviandoMensagem = ref(false)
const carregandoMensagens = ref(true)
const sinoAberto = ref(false)

const mensagensNaoLidas = computed(() => mensagens.value.filter((m) => m.autor_id !== profile.value.id && !m.lida))

async function carregarMensagens() {
  carregandoMensagens.value = true
  const { data } = await supabase
    .from('mensagens_base')
    .select('*')
    .eq('responsavel_id', profile.value.id)
    .order('criado_em', { ascending: true })
  mensagens.value = data ?? []
  carregandoMensagens.value = false
}

async function alternarSino() {
  sinoAberto.value = !sinoAberto.value
  if (!sinoAberto.value) return
  const naoLidasIds = mensagensNaoLidas.value.map((m) => m.id)
  if (naoLidasIds.length) {
    await supabase.from('mensagens_base').update({ lida: true }).in('id', naoLidasIds)
    mensagens.value.forEach((m) => { if (naoLidasIds.includes(m.id)) m.lida = true })
  }
}

async function enviarMensagem() {
  if (!novaMensagem.value.trim()) return
  enviandoMensagem.value = true
  const { data, error } = await supabase.from('mensagens_base').insert({
    responsavel_id: profile.value.id, autor_id: profile.value.id, corpo: novaMensagem.value.trim(), destino: destinoMensagem.value,
  }).select().single()
  enviandoMensagem.value = false
  if (!error) {
    mensagens.value.push(data)
    novaMensagem.value = ''
  }
}

function iniciarEdicao(atleta) {
  atleta.formEdicao = { nome: atleta.nome, escola: atleta.escola ?? '', data_nascimento: atleta.data_nascimento }
  atleta.editando = true
}

async function salvarEdicao(atleta) {
  const { error } = await supabase
    .from('atletas_base')
    .update({
      nome: atleta.formEdicao.nome,
      escola: atleta.formEdicao.escola || null,
      data_nascimento: atleta.formEdicao.data_nascimento,
    })
    .eq('id', atleta.id)

  if (!error) {
    atleta.nome = atleta.formEdicao.nome
    atleta.escola = atleta.formEdicao.escola || null
    atleta.data_nascimento = atleta.formEdicao.data_nascimento
    atleta.editando = false
  }
}

// --- Criar o acesso (só leitura) do atleta ---
async function criarLoginAtleta(atleta) {
  atleta.erroLogin = ''
  if (!atleta.senhaLogin || atleta.senhaLogin.length < 6) {
    atleta.erroLogin = 'Escolha uma senha com pelo menos 6 caracteres.'
    return
  }
  atleta.criandoLogin = true

  // Cliente temporário e isolado, pra não deslogar o responsável no
  // meio da criação da conta do filho (mesmo padrão usado em
  // AdminAssociados.vue pra cadastrar associado).
  const url = import.meta.env.VITE_SUPABASE_URL
  const key = import.meta.env.VITE_SUPABASE_ANON_KEY
  const clienteTemp = createClient(url, key, { auth: { storageKey: 'signup-temp-atleta' } })

  const emailAlias = `atleta.${atleta.id}@login.mannerriege.com.br`
  const { data, error: signupError } = await clienteTemp.auth.signUp({
    email: emailAlias,
    password: atleta.senhaLogin,
    options: { data: { nome: atleta.nome } },
  })

  if (signupError || !data.user) {
    atleta.erroLogin = signupError?.message ?? 'Erro ao criar o acesso.'
    atleta.criandoLogin = false
    return
  }
  await clienteTemp.auth.signOut()

  // Aguarda o trigger handle_new_user() criar a linha em profiles,
  // depois confirma o papel 'atleta_base' e vincula ao cadastro.
  await new Promise((r) => setTimeout(r, 800))
  const { error: ativarError } = await supabase.rpc('ativar_login_atleta', {
    p_atleta_id: atleta.id,
    p_profile_id: data.user.id,
  })

  atleta.criandoLogin = false
  if (ativarError) {
    atleta.erroLogin = ativarError.message
    return
  }
  atleta.profile_id = data.user.id
  atleta.senhaLogin = ''
}

onMounted(() => {
  carregarMeusAtletas()
  carregarMensagens()
})
</script>

<template>
  <div class="mx-auto max-w-3xl">

      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p class="font-mono-label text-[11px] font-bold text-brand-deep">Categorias de Base</p>
          <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Meus atletas</h1>
        </div>
        <div class="flex items-center gap-3">
          <span class="hidden text-xs text-ink-soft sm:inline">Logado como {{ profile?.nome }}</span>

          <!-- Sino de notificações / central de mensagens -->
          <div class="relative">
            <button
              class="relative flex h-9 w-9 items-center justify-center rounded-full border border-ink/15 text-ink-soft hover:border-ink/30"
              title="Mensagens"
              @click="alternarSino"
            >
              <Icon name="mail" class="h-4 w-4" />
              <span v-if="mensagensNaoLidas.length" class="absolute -right-1 -top-1 flex h-4 min-w-[16px] items-center justify-center rounded-full bg-brand px-1 text-[9px] font-bold text-white">{{ mensagensNaoLidas.length }}</span>
            </button>

            <div v-if="sinoAberto" class="absolute right-0 top-11 z-20 w-80 rounded-2xl bg-white p-4 shadow-card sm:w-96">
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">MENSAGENS COM A EQUIPE DO PROJETO</p>

              <p v-if="carregandoMensagens" class="mt-3 text-sm text-ink-soft">Carregando...</p>
              <div v-else class="mt-3 max-h-64 space-y-2 overflow-y-auto rounded-xl bg-paper-dim p-3">
                <p v-if="!mensagens.length" class="text-xs text-ink-soft">Nenhuma mensagem ainda — escreva aqui embaixo.</p>
                <div v-for="m in mensagens" :key="m.id" class="flex" :class="m.autor_id === profile.id ? 'justify-end' : 'justify-start'">
                  <div class="max-w-[85%] rounded-xl px-3 py-2 text-sm" :class="m.autor_id === profile.id ? 'bg-brand text-white' : 'bg-white text-ink shadow-card'">
                    <p v-if="m.autor_id === profile.id" class="mb-0.5 text-[9px] font-bold uppercase opacity-70">{{ destinoMensagemLabel(m.destino) }}</p>
                    <p>{{ m.corpo }}</p>
                    <p class="mt-1 text-[10px] opacity-70">{{ formatarData(m.criado_em?.slice(0, 10)) }}</p>
                  </div>
                </div>
              </div>

              <form class="mt-3 space-y-2" @submit.prevent="enviarMensagem">
                <select v-model="destinoMensagem" class="w-full rounded-lg border border-ink/15 px-2 py-1.5 text-xs">
                  <option v-for="d in destinoMensagemOptions" :key="d.value" :value="d.value">Falar com: {{ d.label }}</option>
                </select>
                <div class="flex gap-2">
                  <input v-model="novaMensagem" placeholder="Escreva sua mensagem..." class="min-w-0 flex-1 rounded-lg border border-ink/15 px-3 py-2 text-sm" />
                  <button type="submit" :disabled="enviandoMensagem" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ enviandoMensagem ? '...' : 'Enviar' }}</button>
                </div>
              </form>
            </div>
          </div>

          <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
        </div>
      </div>

      <!-- Meus dados de contato -->
      <div class="mt-4 rounded-2xl bg-white p-5 shadow-card">
        <div class="flex items-center justify-between">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">MEUS DADOS DE CONTATO</p>
          <button class="text-xs font-semibold text-brand-deep hover:underline" @click="abrirMeusDados">{{ mostrarMeusDados ? 'Fechar' : 'Editar telefone, e-mail e senha' }}</button>
        </div>
        <p v-if="!mostrarMeusDados" class="mt-2 text-sm text-ink-soft">{{ profile?.telefone || '—' }} · {{ profile?.email }}</p>

        <div v-else class="mt-3 space-y-4">
          <form class="grid gap-3 sm:grid-cols-2" @submit.prevent="salvarMeusDados">
            <input v-model="formMeusDados.telefone" placeholder="Telefone / WhatsApp" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
            <input v-model="formMeusDados.email" type="email" placeholder="E-mail" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
            <div class="sm:col-span-2 flex items-center gap-3">
              <button type="submit" :disabled="salvandoMeusDados" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ salvandoMeusDados ? 'Salvando...' : 'Salvar contato' }}</button>
              <p v-if="erroMeusDados" class="text-xs text-brand-deep">{{ erroMeusDados }}</p>
              <p v-if="sucessoMeusDados" class="text-xs text-[#27500A]">{{ sucessoMeusDados }}</p>
            </div>
          </form>

          <form class="flex flex-wrap items-center gap-3 border-t border-ink/10 pt-3" @submit.prevent="trocarMinhaSenha">
            <input v-model="novaSenha" type="password" placeholder="Nova senha (mín. 6 caracteres)" class="min-w-0 flex-1 rounded-lg border border-ink/15 px-3 py-2 text-sm" />
            <button type="submit" :disabled="trocandoSenha" class="rounded-full bg-ink px-4 py-2 text-xs font-bold text-white hover:bg-ink/90 disabled:opacity-50">{{ trocandoSenha ? 'Trocando...' : 'Trocar senha' }}</button>
            <p v-if="erroSenha" class="text-xs text-brand-deep">{{ erroSenha }}</p>
            <p v-if="sucessoSenha" class="text-xs text-[#27500A]">{{ sucessoSenha }}</p>
          </form>
        </div>
      </div>

      <p v-if="carregando" class="mt-8 text-sm text-ink-soft">Carregando...</p>

      <div v-else-if="meusAtletas.length === 0" class="mt-8 rounded-2xl border border-dashed border-ink/15 p-8 text-center">
        <Icon name="users" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Nenhum atleta vinculado ao seu cadastro ainda. Fale com a coordenação das Categorias de Base.</p>
      </div>

      <div v-else class="mt-8 space-y-5">
        <div v-for="atleta in meusAtletas" :key="atleta.id" class="rounded-2xl bg-white p-6 shadow-card">

          <div class="flex items-start justify-between gap-3">
            <div class="flex items-start gap-3">
              <AvatarUpload
                :profile-id="atleta.id"
                :avatar-url="atleta.avatar_url"
                :nome="atleta.nome"
                table="atletas_base"
                editable
                size="md"
                @update:avatar-url="(url) => (atleta.avatar_url = url)"
              />
              <div>
                <h2 class="font-display text-xl font-bold text-ink">{{ atleta.nome }}</h2>
                <p class="mt-0.5 text-xs text-ink-soft">
                  {{ nomeCategoria(atleta.categoria) }} · {{ idadeAtual(atleta.data_nascimento) }} anos
                  <span v-if="atleta.posicao"> · {{ posicaoLabel(atleta.posicao) }}</span>
                </p>
                <p v-if="tempoNoProjeto(atleta.data_ingresso)" class="mt-0.5 text-xs text-ink-soft">No projeto há {{ tempoNoProjeto(atleta.data_ingresso) }} · desde {{ formatarDataCurta(atleta.data_ingresso) }}</p>
              </div>
            </div>
            <span :class="['flex-shrink-0 rounded-full px-3 py-1 text-xs font-semibold', statusAtletaClasses(atleta.status)]">
              {{ statusAtletaLabel(atleta.status) }}
            </span>
          </div>

          <!-- Dados cadastrais -->
          <div class="mt-5 rounded-xl bg-paper-dim p-4">
            <div class="flex items-center justify-between">
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">DADOS CADASTRAIS</p>
              <button v-if="!atleta.editando" class="text-xs font-semibold text-brand-deep hover:underline" @click="iniciarEdicao(atleta)">Editar</button>
            </div>

            <dl v-if="!atleta.editando" class="mt-3 space-y-2 text-sm text-ink">
              <div class="flex justify-between"><dt class="text-ink-soft">Nascimento</dt><dd>{{ formatarData(atleta.data_nascimento) }}</dd></div>
              <div class="flex justify-between"><dt class="text-ink-soft">Escola</dt><dd>{{ atleta.escola || '—' }}</dd></div>
              <div class="flex justify-between"><dt class="text-ink-soft">No projeto desde</dt><dd>{{ formatarData(atleta.data_ingresso) }}</dd></div>
            </dl>

            <form v-else class="mt-3 space-y-3" @submit.prevent="salvarEdicao(atleta)">
              <div>
                <label class="text-xs font-semibold text-ink-soft">Nome</label>
                <input v-model="atleta.formEdicao.nome" required class="mt-1 w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
              </div>
              <div>
                <label class="text-xs font-semibold text-ink-soft">Data de nascimento</label>
                <input v-model="atleta.formEdicao.data_nascimento" type="date" required class="mt-1 w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
              </div>
              <div>
                <label class="text-xs font-semibold text-ink-soft">Escola</label>
                <input v-model="atleta.formEdicao.escola" class="mt-1 w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
              </div>
              <p class="text-[11px] text-ink-soft">Categoria e status só podem ser alterados pela equipe da base.</p>
              <div class="flex gap-2">
                <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
                <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="atleta.editando = false">Cancelar</button>
              </div>
            </form>
          </div>

          <!-- Plano / mensalidades -->
          <div class="mt-4 rounded-xl bg-paper-dim p-4">
            <div class="flex items-center justify-between">
              <div>
                <p class="font-mono-label text-[9px] font-bold text-ink-soft">PLANO ATUAL</p>
                <p class="mt-1 text-sm font-semibold text-ink">{{ atleta.planoVigente?.plano?.nome ?? '—' }}</p>
                <p v-if="atleta.planoVigente?.plano" class="text-xs text-ink-soft">{{ brl(atleta.planoVigente.plano.valor_mensal) }}/mês</p>
                <p v-if="atleta.planoVigente?.data_inicio" class="text-[11px] text-ink-soft">vigente desde {{ formatarDataCurta(atleta.planoVigente.data_inicio) }}</p>
              </div>
              <div v-if="atleta.matricula" class="text-right">
                <p class="text-xs text-ink-soft">Taxa de matrícula</p>
                <span :class="['mt-1 inline-block rounded-full px-3 py-1 text-xs font-semibold', statusFinanceiroBaseClasses(atleta.matricula.status)]">
                  {{ atleta.matricula.status === 'isento' ? 'isenta' : atleta.matricula.status }} · {{ brl(atleta.matricula.valor) }}
                </span>
              </div>
            </div>

            <div v-if="atleta.mensalidades.length" class="mt-3 space-y-1.5 border-t border-ink/10 pt-3">
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">MENSALIDADES</p>
              <div v-for="m in atleta.mensalidades" :key="m.id" class="flex items-center justify-between text-xs">
                <span class="text-ink-soft">{{ formatarCompetencia(m.competencia) }}</span>
                <span class="flex items-center gap-2">
                  <span class="text-ink">{{ brl(m.valor) }}</span>
                  <span :class="['rounded-full px-2.5 py-0.5 text-[10px] font-semibold', mensalidadeBaseStatusClasses(m.status)]">{{ mensalidadeBaseStatusLabel(m.status) }}</span>
                </span>
              </div>
              <p class="pt-1 text-[11px] text-ink-soft">Mensalidade em aberto? Fale com a coordenação pelas mensagens, aqui embaixo.</p>
            </div>
          </div>

          <!-- Avaliações periódicas -->
          <div v-if="atleta.avaliacoes.length" class="mt-4 rounded-xl bg-paper-dim p-4">
            <p class="font-mono-label text-[9px] font-bold text-ink-soft">DESEMPENHO — AVALIAÇÕES PERIÓDICAS</p>
            <div class="mt-2 divide-y divide-ink/8">
              <div v-for="v in atleta.avaliacoes" :key="v.id" class="py-2 text-xs">
                <div class="flex items-center justify-between">
                  <span class="font-semibold text-ink">{{ tipoAvaliacaoLabel(v.tipo) }}</span>
                  <span class="text-ink-soft">{{ formatarDataCurta(v.data) }}<span v-if="v.nota !== null"> · nota {{ v.nota }}</span></span>
                </div>
                <p v-if="v.observacoes" class="mt-0.5 text-ink-soft">{{ v.observacoes }}</p>
              </div>
            </div>
          </div>

          <!-- Acesso do atleta -->
          <div class="mt-4 rounded-xl border border-dashed border-ink/15 p-4">
            <div class="flex items-center gap-2">
              <Icon name="lock" class="h-4 w-4 text-ink-soft" />
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">ACESSO DO ATLETA (SÓ LEITURA)</p>
            </div>

            <p v-if="atleta.profile_id" class="mt-2 text-sm text-ink-soft">
              ✓ Acesso já criado — {{ atleta.nome.split(' ')[0] }} pode entrar e acompanhar o próprio desempenho, sem editar nada.
            </p>

            <div v-else class="mt-2">
              <p class="text-xs text-ink-soft">
                Crie uma senha pra {{ atleta.nome.split(' ')[0] }} acompanhar os próprios treinos e avaliações. Você define e guarda essa senha.
              </p>
              <div class="mt-2 flex flex-wrap gap-2">
                <input
                  v-model="atleta.senhaLogin"
                  type="password"
                  placeholder="Senha (mín. 6 caracteres)"
                  class="min-w-0 flex-1 rounded-lg border border-ink/15 px-3 py-2 text-sm"
                />
                <button
                  :disabled="atleta.criandoLogin"
                  class="rounded-full bg-ink px-4 py-2 text-xs font-bold text-white hover:bg-ink/90 disabled:opacity-50"
                  @click="criarLoginAtleta(atleta)"
                >{{ atleta.criandoLogin ? 'Criando...' : 'Criar acesso' }}</button>
              </div>
              <p v-if="atleta.erroLogin" class="mt-2 text-xs text-brand-deep">{{ atleta.erroLogin }}</p>
            </div>
          </div>

          <!-- Histórico de eventos (frequência + o que foi trabalhado) -->
          <div v-if="atleta.historicoEventos.length" class="mt-4 rounded-xl bg-paper-dim p-4">
            <p class="font-mono-label text-[9px] font-bold text-ink-soft">FREQUÊNCIA E AULAS RECENTES</p>
            <div class="mt-2 divide-y divide-ink/8">
              <div v-for="p in atleta.historicoEventos" :key="p.id" class="py-2 text-xs">
                <div class="flex cursor-pointer items-center justify-between gap-2" @click="p.expandido = !p.expandido">
                  <div>
                    <p class="text-ink">{{ p.evento.titulo }}</p>
                    <p class="text-ink-soft">{{ tipoEventoLabel(p.evento.tipo) }} · {{ formatarDataCurta(p.evento.data) }}</p>
                  </div>
                  <div class="flex items-center gap-2">
                    <div class="text-right">
                      <p v-if="p.presente !== null" :class="p.presente ? 'text-[#27500A]' : 'text-brand-deep'">{{ p.presente ? 'presente' : 'ausente' }}</p>
                      <p v-if="p.desempenho_nota !== null" class="text-ink-soft">nota {{ p.desempenho_nota }}</p>
                    </div>
                    <span v-if="p.evento.plano_atividades || p.desempenho_obs" class="text-ink-soft">{{ p.expandido ? '▲' : '▼' }}</span>
                  </div>
                </div>
                <template v-if="p.expandido">
                  <p v-if="p.evento.plano_atividades" class="mt-1 text-ink-soft"><strong class="text-ink">O que foi feito:</strong> {{ p.evento.plano_atividades }}</p>
                  <p v-if="p.desempenho_obs" class="mt-0.5 text-ink-soft"><strong class="text-ink">Observação do professor:</strong> {{ p.desempenho_obs }}</p>
                  <p v-if="!p.evento.plano_atividades && !p.desempenho_obs" class="mt-1 text-ink-soft">Sem observações registradas nessa aula.</p>
                </template>
              </div>
            </div>
          </div>

          <!-- Fotos e vídeos dos treinos/eventos -->
          <div v-if="atleta.fotosEventos.length" class="mt-4 rounded-xl bg-paper-dim p-4">
            <p class="font-mono-label text-[9px] font-bold text-ink-soft">FOTOS E VÍDEOS DOS TREINOS E EVENTOS</p>
            <div class="mt-2 grid grid-cols-3 gap-2 sm:grid-cols-4">
              <a v-for="m in atleta.fotosEventos" :key="m.id" :href="m.url" target="_blank" rel="noopener" class="overflow-hidden rounded-lg bg-ink/5">
                <img v-if="m.tipo === 'foto'" :src="m.url" class="h-20 w-full object-cover" />
                <video v-else :src="m.url" class="h-20 w-full object-cover"></video>
              </a>
            </div>
          </div>

        </div>
      </div>

  </div>
</template>
