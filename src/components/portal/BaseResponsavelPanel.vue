<script setup>
import { ref, onMounted } from 'vue'
import { createClient } from '@supabase/supabase-js'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'
import { formatarData } from '../../lib/categoria.js'
import { brl, formatarDataCurta } from '../../data/campeonatos.js'
import { formatarCompetencia } from '../../data/financeiro.js'
import {
  statusAtletaLabel, statusAtletaClasses, idadeAtual, nomeCategoria,
  mensalidadeBaseStatusLabel, mensalidadeBaseStatusClasses,
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

  const [{ data: atletas }, { data: categorias }, { data: planosVigentes }, { data: mensalidades }] = await Promise.all([
    supabase.from('atletas_base').select('*').in('id', atletaIds),
    supabase.from('categorias_base').select('*'),
    supabase.from('atleta_plano').select('atleta_id, plano:planos_base(*)').in('atleta_id', atletaIds).is('data_fim', null),
    supabase.from('mensalidades_base').select('*').in('atleta_id', atletaIds).order('competencia', { ascending: false }),
  ])

  meusAtletas.value = (atletas ?? []).map((a) => ({
    ...a,
    categoria: (categorias ?? []).find((c) => c.id === a.categoria_id) ?? null,
    plano: (planosVigentes ?? []).find((p) => p.atleta_id === a.id)?.plano ?? null,
    ultimaMensalidade: (mensalidades ?? []).find((m) => m.atleta_id === a.id) ?? null,
    editando: false,
    formEdicao: { nome: a.nome, escola: a.escola ?? '', data_nascimento: a.data_nascimento },
    criandoLogin: false,
    senhaLogin: '',
    erroLogin: '',
  }))

  carregando.value = false
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

onMounted(carregarMeusAtletas)
</script>

<template>
  <div class="mx-auto max-w-3xl">

      <div class="flex flex-wrap items-center justify-between gap-4">
        <div>
          <p class="font-mono-label text-[11px] font-bold text-brand-deep">Categorias de Base</p>
          <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Meus atletas</h1>
        </div>
        <div class="flex items-center gap-3">
          <span class="text-xs text-ink-soft">Logado como {{ profile?.nome }}</span>
          <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
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
            <div>
              <h2 class="font-display text-xl font-bold text-ink">{{ atleta.nome }}</h2>
              <p class="mt-0.5 text-xs text-ink-soft">
                {{ nomeCategoria(atleta.categoria) }} · {{ idadeAtual(atleta.data_nascimento) }} anos
              </p>
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

          <!-- Plano / mensalidade -->
          <div class="mt-4 flex items-center justify-between rounded-xl bg-paper-dim p-4">
            <div>
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">PLANO ATUAL</p>
              <p class="mt-1 text-sm font-semibold text-ink">{{ atleta.plano?.nome ?? '—' }}</p>
              <p v-if="atleta.plano" class="text-xs text-ink-soft">{{ brl(atleta.plano.valor_mensal) }}/mês</p>
            </div>
            <div v-if="atleta.ultimaMensalidade" class="text-right">
              <p class="text-xs text-ink-soft">{{ formatarCompetencia(atleta.ultimaMensalidade.competencia) }}</p>
              <span :class="['mt-1 inline-block rounded-full px-3 py-1 text-xs font-semibold', mensalidadeBaseStatusClasses(atleta.ultimaMensalidade.status)]">
                {{ mensalidadeBaseStatusLabel(atleta.ultimaMensalidade.status) }}
              </span>
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

        </div>
      </div>

  </div>
</template>
