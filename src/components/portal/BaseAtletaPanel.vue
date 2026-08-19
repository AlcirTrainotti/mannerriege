<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'
import AvatarUpload from './AvatarUpload.vue'
import AtletaEvolucaoDashboard from './AtletaEvolucaoDashboard.vue'
import StarRating from './StarRating.vue'
import { formatarData } from '../../lib/categoria.js'
import { brl, formatarDataCurta } from '../../data/campeonatos.js'
import { formatarCompetencia } from '../../data/financeiro.js'
import {
  statusAtletaLabel, statusAtletaClasses, idadeAtual, nomeCategoria,
  mensalidadeBaseStatusLabel, mensalidadeBaseStatusClasses,
  posicaoLabel, tipoEventoLabel, tipoAvaliacaoLabel, statusFinanceiroBaseClasses,
  tempoNoProjeto, destinoMensagemOptions, destinoMensagemLabel, estrelasFromNota,
} from '../../data/base.js'

// Painel do próprio atleta — espelha o que o responsável vê no dele,
// mas é só leitura em quase tudo. As únicas exceções (permitidas pela
// trigger atletas_base_bloqueia_campos_staff, migration_097) são:
// foto (avatar_url), nome e escola. Categoria, status, data de
// nascimento, posição, observações e time continuam exclusivos do
// responsável/equipe da base.

const { profile, logout } = useAuth()

const carregando = ref(true)
const meuCadastro = ref(null)

async function carregar() {
  carregando.value = true

  const { data: atleta } = await supabase
    .from('atletas_base')
    .select('*, categoria:categorias_base(*)')
    .eq('profile_id', profile.value.id)
    .maybeSingle()

  if (!atleta) {
    meuCadastro.value = null
    carregando.value = false
    return
  }

  const [{ data: planoVigente }, { data: mensalidades }, { data: eventosParticipados }, { data: avaliacoes }, { data: matricula }] = await Promise.all([
    supabase.from('atleta_plano').select('atleta_id, data_inicio, plano:planos_base(*)').eq('atleta_id', atleta.id).is('data_fim', null).maybeSingle(),
    supabase.from('mensalidades_base').select('*').eq('atleta_id', atleta.id).order('competencia', { ascending: false }),
    supabase.from('evento_participantes_base').select('*, evento:eventos_base(*)').eq('atleta_id', atleta.id).order('criado_em', { ascending: false }),
    supabase.from('avaliacoes_atleta_base').select('*').eq('atleta_id', atleta.id).order('data', { ascending: false }),
    supabase.from('matriculas_base').select('*').eq('atleta_id', atleta.id).maybeSingle(),
  ])

  const participacoes = (eventosParticipados ?? []).filter((p) => p.evento)
  const eventoIds = [...new Set(participacoes.map((p) => p.evento_id))]
  const { data: midias } = eventoIds.length
    ? await supabase.from('evento_midias_base').select('*').in('evento_id', eventoIds).order('criado_em', { ascending: false })
    : { data: [] }

  meuCadastro.value = {
    ...atleta,
    planoVigente: planoVigente ?? null,
    mensalidades: mensalidades ?? [],
    matricula: matricula ?? null,
    participacoesTotal: participacoes,
    historicoEventos: participacoes.slice(0, 8).map((p) => ({ ...p, expandido: false })),
    avaliacoes: avaliacoes ?? [],
    fotosEventos: midias ?? [],
  }

  formEdicao.value = { nome: atleta.nome, escola: atleta.escola ?? '' }

  carregando.value = false
}

onMounted(() => {
  carregar()
  carregarMensagens()
})

// ================================================================
// Autoatendimento: só nome/escola, foto e senha. A trigger no banco
// (migration_097) barra qualquer outro campo se for o próprio atleta
// editando, então nem precisamos validar isso aqui além do form.
// ================================================================
const editando = ref(false)
const formEdicao = ref({ nome: '', escola: '' })
const salvandoEdicao = ref(false)
const erroEdicao = ref('')

function iniciarEdicao() {
  formEdicao.value = { nome: meuCadastro.value.nome, escola: meuCadastro.value.escola ?? '' }
  erroEdicao.value = ''
  editando.value = true
}

async function salvarEdicao() {
  if (!formEdicao.value.nome.trim()) {
    erroEdicao.value = 'O nome não pode ficar em branco.'
    return
  }
  salvandoEdicao.value = true
  erroEdicao.value = ''
  const { error } = await supabase
    .from('atletas_base')
    .update({ nome: formEdicao.value.nome.trim(), escola: formEdicao.value.escola.trim() || null })
    .eq('id', meuCadastro.value.id)
  salvandoEdicao.value = false
  if (error) {
    erroEdicao.value = 'Não foi possível salvar: ' + error.message
    return
  }
  meuCadastro.value.nome = formEdicao.value.nome.trim()
  meuCadastro.value.escola = formEdicao.value.escola.trim() || null
  editando.value = false
}

function aoAtualizarMinhaFoto(url) {
  meuCadastro.value.avatar_url = url
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

// ================================================================
// Mensagens com a equipe do projeto — o atleta participa do mesmo
// canal que o(s) responsável(is) já usam (migration_098): é uma
// conversa por família, não uma caixa separada por pessoa. O sino
// mostra quantas mensagens (da equipe ou do próprio responsável)
// ainda não foram vistas.
// ================================================================
const meuCanalId = ref(null)
const mensagens = ref([])
const novaMensagem = ref('')
const destinoMensagem = ref('geral')
const enviandoMensagem = ref(false)
const carregandoMensagens = ref(true)
const sinoAberto = ref(false)

const mensagensNaoLidas = computed(() => mensagens.value.filter((m) => m.autor_id !== profile.value.id && !m.lida))

async function carregarMensagens() {
  carregandoMensagens.value = true
  const { data: canalId } = await supabase.rpc('meu_canal_mensagens_base')
  meuCanalId.value = canalId ?? null
  if (!meuCanalId.value) {
    mensagens.value = []
    carregandoMensagens.value = false
    return
  }
  const { data } = await supabase.rpc('mensagens_canal_base', { p_responsavel_id: meuCanalId.value })
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
  if (!novaMensagem.value.trim() || !meuCanalId.value) return
  enviandoMensagem.value = true
  const { data, error } = await supabase.from('mensagens_base').insert({
    responsavel_id: meuCanalId.value, autor_id: profile.value.id, corpo: novaMensagem.value.trim(), destino: destinoMensagem.value,
  }).select().single()
  enviandoMensagem.value = false
  if (!error) {
    mensagens.value.push({ ...data, autor_nome: profile.value.nome })
    novaMensagem.value = ''
  }
}
</script>

<template>
  <div class="mx-auto max-w-lg">

      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p class="font-mono-label text-[11px] font-bold text-brand-deep">Categorias de Base</p>
          <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Meu desempenho</h1>
        </div>
        <div class="flex items-center gap-3">
          <!-- Sino de notificações / central de mensagens -->
          <div v-if="meuCadastro" class="relative">
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

              <p v-if="!meuCanalId && !carregandoMensagens" class="mt-3 text-xs text-ink-soft">Não encontramos um responsável vinculado ao seu cadastro — fale com a coordenação pra ativar suas mensagens.</p>

              <template v-else>
                <p v-if="carregandoMensagens" class="mt-3 text-sm text-ink-soft">Carregando...</p>
                <div v-else class="mt-3 max-h-64 space-y-2 overflow-y-auto rounded-xl bg-paper-dim p-3">
                  <p v-if="!mensagens.length" class="text-xs text-ink-soft">Nenhuma mensagem ainda — escreva aqui embaixo.</p>
                  <div v-for="m in mensagens" :key="m.id" class="flex" :class="m.autor_id === profile.id ? 'justify-end' : 'justify-start'">
                    <div class="max-w-[85%] rounded-xl px-3 py-2 text-sm" :class="m.autor_id === profile.id ? 'bg-brand text-white' : 'bg-white text-ink shadow-card'">
                      <p v-if="m.autor_id === profile.id" class="mb-0.5 text-[9px] font-bold uppercase opacity-70">{{ destinoMensagemLabel(m.destino) }}</p>
                      <p v-else class="mb-0.5 text-[9px] font-bold uppercase text-ink-soft">{{ m.autor_nome ?? 'Equipe' }}</p>
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
              </template>
            </div>
          </div>

          <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
        </div>
      </div>

      <p v-if="carregando" class="mt-8 text-sm text-ink-soft">Carregando...</p>

      <div v-else-if="!meuCadastro" class="mt-8 rounded-2xl border border-dashed border-ink/15 p-8 text-center">
        <Icon name="volleyball" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Não encontramos seu cadastro de atleta. Fale com seu responsável ou com a coordenação.</p>
      </div>

      <div v-else class="mt-8 space-y-5">

        <!-- Cabeçalho + foto + dados cadastrais (nome/escola editáveis) -->
        <div class="rounded-2xl bg-white p-6 shadow-card">
          <div class="flex items-start justify-between gap-3">
            <div class="flex items-start gap-3">
              <AvatarUpload
                :profile-id="meuCadastro.id"
                :avatar-url="meuCadastro.avatar_url"
                :nome="meuCadastro.nome"
                table="atletas_base"
                editable
                size="md"
                @update:avatar-url="aoAtualizarMinhaFoto"
              />
              <div>
                <h2 class="font-display text-xl font-bold text-ink">{{ meuCadastro.nome }}</h2>
                <p class="mt-0.5 text-xs text-ink-soft">
                  {{ nomeCategoria(meuCadastro.categoria) }} · {{ idadeAtual(meuCadastro.data_nascimento) }} anos
                  <span v-if="meuCadastro.posicao"> · {{ posicaoLabel(meuCadastro.posicao) }}</span>
                </p>
                <p v-if="tempoNoProjeto(meuCadastro.data_ingresso)" class="mt-0.5 text-xs text-ink-soft">No projeto há {{ tempoNoProjeto(meuCadastro.data_ingresso) }} · desde {{ formatarDataCurta(meuCadastro.data_ingresso) }}</p>
              </div>
            </div>
            <span :class="['flex-shrink-0 rounded-full px-3 py-1 text-xs font-semibold', statusAtletaClasses(meuCadastro.status)]">
              {{ statusAtletaLabel(meuCadastro.status) }}
            </span>
          </div>

          <div class="mt-5 rounded-xl bg-paper-dim p-4">
            <div class="flex items-center justify-between">
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">MEUS DADOS</p>
              <button v-if="!editando" class="text-xs font-semibold text-brand-deep hover:underline" @click="iniciarEdicao">Editar nome/escola</button>
            </div>

            <dl v-if="!editando" class="mt-3 space-y-2 text-sm text-ink">
              <div class="flex justify-between"><dt class="text-ink-soft">Nascimento</dt><dd>{{ formatarData(meuCadastro.data_nascimento) }}</dd></div>
              <div class="flex justify-between"><dt class="text-ink-soft">Escola</dt><dd>{{ meuCadastro.escola || '—' }}</dd></div>
              <div class="flex justify-between"><dt class="text-ink-soft">No projeto desde</dt><dd>{{ formatarData(meuCadastro.data_ingresso) }}</dd></div>
            </dl>

            <form v-else class="mt-3 space-y-3" @submit.prevent="salvarEdicao">
              <div>
                <label class="text-xs font-semibold text-ink-soft">Nome</label>
                <input v-model="formEdicao.nome" required class="mt-1 w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
              </div>
              <div>
                <label class="text-xs font-semibold text-ink-soft">Escola</label>
                <input v-model="formEdicao.escola" class="mt-1 w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
              </div>
              <p class="text-[11px] text-ink-soft">Data de nascimento, posição e categoria só podem ser alteradas pelo seu responsável ou pela coordenação.</p>
              <p v-if="erroEdicao" class="text-xs text-brand-deep">{{ erroEdicao }}</p>
              <div class="flex gap-2">
                <button type="submit" :disabled="salvandoEdicao" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ salvandoEdicao ? 'Salvando...' : 'Salvar' }}</button>
                <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="editando = false">Cancelar</button>
              </div>
            </form>
          </div>

          <!-- Troca de senha -->
          <form class="mt-4 flex flex-wrap items-center gap-3 border-t border-ink/10 pt-4" @submit.prevent="trocarMinhaSenha">
            <input v-model="novaSenha" type="password" placeholder="Nova senha (mín. 6 caracteres)" class="min-w-0 flex-1 rounded-lg border border-ink/15 px-3 py-2 text-sm" />
            <button type="submit" :disabled="trocandoSenha" class="rounded-full bg-ink px-4 py-2 text-xs font-bold text-white hover:bg-ink/90 disabled:opacity-50">{{ trocandoSenha ? 'Trocando...' : 'Trocar senha' }}</button>
            <p v-if="erroSenha" class="w-full text-xs text-brand-deep">{{ erroSenha }}</p>
            <p v-if="sucessoSenha" class="w-full text-xs text-[#27500A]">{{ sucessoSenha }}</p>
          </form>
        </div>

        <!-- Evolução e desempenho -->
        <AtletaEvolucaoDashboard :atleta="meuCadastro" />

        <!-- Plano / mensalidades -->
        <div class="rounded-2xl bg-white p-6 shadow-card">
          <div class="flex items-center justify-between">
            <div>
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">PLANO ATUAL</p>
              <p class="mt-1 text-sm font-semibold text-ink">{{ meuCadastro.planoVigente?.plano?.nome ?? '—' }}</p>
              <p v-if="meuCadastro.planoVigente?.plano" class="text-xs text-ink-soft">{{ brl(meuCadastro.planoVigente.plano.valor_mensal) }}/mês</p>
              <p v-if="meuCadastro.planoVigente?.data_inicio" class="text-[11px] text-ink-soft">vigente desde {{ formatarDataCurta(meuCadastro.planoVigente.data_inicio) }}</p>
            </div>
            <div v-if="meuCadastro.matricula" class="text-right">
              <p class="text-xs text-ink-soft">Taxa de matrícula</p>
              <span :class="['mt-1 inline-block rounded-full px-3 py-1 text-xs font-semibold', statusFinanceiroBaseClasses(meuCadastro.matricula.status)]">
                {{ meuCadastro.matricula.status === 'isento' ? 'isenta' : meuCadastro.matricula.status }} · {{ brl(meuCadastro.matricula.valor) }}
              </span>
            </div>
          </div>

          <div v-if="meuCadastro.mensalidades.length" class="mt-3 space-y-1.5 border-t border-ink/10 pt-3">
            <p class="font-mono-label text-[9px] font-bold text-ink-soft">MENSALIDADES</p>
            <div v-for="m in meuCadastro.mensalidades" :key="m.id" class="flex items-center justify-between text-xs">
              <span class="text-ink-soft">{{ formatarCompetencia(m.competencia) }}</span>
              <span class="flex items-center gap-2">
                <span class="text-ink">{{ brl(m.valor) }}</span>
                <span :class="['rounded-full px-2.5 py-0.5 text-[10px] font-semibold', mensalidadeBaseStatusClasses(m.status)]">{{ mensalidadeBaseStatusLabel(m.status) }}</span>
              </span>
            </div>
          </div>
        </div>

        <!-- Avaliações periódicas -->
        <div v-if="meuCadastro.avaliacoes.length" class="rounded-2xl bg-white p-6 shadow-card">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">DESEMPENHO — AVALIAÇÕES PERIÓDICAS</p>
          <div class="mt-2 divide-y divide-ink/8">
            <div v-for="v in meuCadastro.avaliacoes" :key="v.id" class="py-2 text-xs">
              <div class="flex items-center justify-between">
                <span class="font-semibold text-ink">{{ tipoAvaliacaoLabel(v.tipo) }}</span>
                <span class="text-ink-soft">{{ formatarDataCurta(v.data) }}<span v-if="v.nota !== null"> · nota {{ v.nota }}</span></span>
              </div>
              <p v-if="v.observacoes" class="mt-0.5 text-ink-soft">{{ v.observacoes }}</p>
            </div>
          </div>
        </div>

        <!-- Histórico de eventos (frequência + o que foi trabalhado) -->
        <div v-if="meuCadastro.historicoEventos.length" class="rounded-2xl bg-white p-6 shadow-card">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">FREQUÊNCIA E AULAS RECENTES</p>
          <div class="mt-2 divide-y divide-ink/8">
            <div v-for="p in meuCadastro.historicoEventos" :key="p.id" class="py-2 text-xs">
              <div class="flex cursor-pointer items-center justify-between gap-2" @click="p.expandido = !p.expandido">
                <div>
                  <p class="text-ink">{{ p.evento.titulo }}</p>
                  <p class="text-ink-soft">{{ tipoEventoLabel(p.evento.tipo) }} · {{ formatarDataCurta(p.evento.data) }}</p>
                </div>
                <div class="flex items-center gap-2">
                  <div class="text-right">
                    <p v-if="p.presente !== null" :class="p.presente ? 'text-[#27500A]' : 'text-brand-deep'">{{ p.presente ? 'presente' : 'ausente' }}</p>
                    <StarRating v-if="p.desempenho_nota !== null" :model-value="estrelasFromNota(p.desempenho_nota)" readonly size="h-3 w-3" />
                  </div>
                  <span v-if="p.evento.objetivo || p.evento.plano_atividades || p.desempenho_obs" class="text-ink-soft">{{ p.expandido ? '▲' : '▼' }}</span>
                </div>
              </div>
              <template v-if="p.expandido">
                <p v-if="p.evento.objetivo" class="mt-1 text-ink-soft"><strong class="text-ink">Objetivo:</strong> {{ p.evento.objetivo }}</p>
                <p v-if="p.evento.plano_atividades" class="mt-0.5 text-ink-soft"><strong class="text-ink">O que foi feito:</strong> {{ p.evento.plano_atividades }}</p>
                <p v-if="p.desempenho_obs" class="mt-0.5 text-ink-soft"><strong class="text-ink">Observação do professor:</strong> {{ p.desempenho_obs }}</p>
                <audio v-if="p.desempenho_obs_audio_url" :src="p.desempenho_obs_audio_url" controls class="mt-1 h-7" />
                <p v-if="!p.evento.objetivo && !p.evento.plano_atividades && !p.desempenho_obs && !p.desempenho_obs_audio_url" class="mt-1 text-ink-soft">Sem observações registradas nessa aula.</p>
              </template>
            </div>
          </div>
        </div>

        <!-- Fotos e vídeos dos treinos/eventos -->
        <div v-if="meuCadastro.fotosEventos.length" class="rounded-2xl bg-white p-6 shadow-card">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">FOTOS E VÍDEOS DOS TREINOS E EVENTOS</p>
          <div class="mt-2 grid grid-cols-3 gap-2 sm:grid-cols-4">
            <a v-for="m in meuCadastro.fotosEventos" :key="m.id" :href="m.url" target="_blank" rel="noopener" class="overflow-hidden rounded-lg bg-ink/5">
              <img v-if="m.tipo === 'foto'" :src="m.url" class="h-20 w-full object-cover" />
              <video v-else :src="m.url" class="h-20 w-full object-cover"></video>
            </a>
          </div>
        </div>

      </div>

  </div>
</template>
