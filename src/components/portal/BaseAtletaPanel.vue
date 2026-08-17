<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'
import { formatarData } from '../../lib/categoria.js'
import { brl } from '../../data/campeonatos.js'
import { formatarCompetencia } from '../../data/financeiro.js'
import {
  statusAtletaLabel, statusAtletaClasses, idadeAtual, nomeCategoria,
  mensalidadeBaseStatusLabel, mensalidadeBaseStatusClasses,
} from '../../data/base.js'

// Painel só de leitura — nenhum botão de edição em nenhuma tela.
// Quem gerencia o cadastro é o responsável (BaseResponsavelPanel).

const { profile, logout } = useAuth()

const carregando = ref(true)
const meuCadastro = ref(null)
const minhasMensalidades = ref([])

async function carregar() {
  carregando.value = true

  const { data: atleta } = await supabase
    .from('atletas_base')
    .select('*, categoria:categorias_base(*)')
    .eq('profile_id', profile.value.id)
    .maybeSingle()

  meuCadastro.value = atleta

  if (atleta) {
    const [{ data: planoVigente }, { data: mensalidades }] = await Promise.all([
      supabase.from('atleta_plano').select('plano:planos_base(*)').eq('atleta_id', atleta.id).is('data_fim', null).maybeSingle(),
      supabase.from('mensalidades_base').select('*').eq('atleta_id', atleta.id).order('competencia', { ascending: false }).limit(6),
    ])
    meuCadastro.value.plano = planoVigente?.plano ?? null
    minhasMensalidades.value = mensalidades ?? []
  }

  carregando.value = false
}

onMounted(carregar)
</script>

<template>
  <div class="mx-auto max-w-lg">

      <div class="flex items-center justify-between gap-4">
        <div>
          <p class="font-mono-label text-[11px] font-bold text-brand-deep">Categorias de Base</p>
          <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Meu desempenho</h1>
        </div>
        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
      </div>

      <p v-if="carregando" class="mt-8 text-sm text-ink-soft">Carregando...</p>

      <div v-else-if="!meuCadastro" class="mt-8 rounded-2xl border border-dashed border-ink/15 p-8 text-center">
        <Icon name="volleyball" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Não encontramos seu cadastro de atleta. Fale com seu responsável ou com a coordenação.</p>
      </div>

      <div v-else class="mt-8 space-y-6">
        <div class="rounded-2xl bg-white p-7 shadow-card">
          <h2 class="font-display text-2xl font-bold text-ink">{{ meuCadastro.nome }}</h2>
          <p class="mt-1 text-sm text-ink-soft">{{ nomeCategoria(meuCadastro.categoria) }} · {{ idadeAtual(meuCadastro.data_nascimento) }} anos</p>
          <span :class="['mt-3 inline-block rounded-full px-3 py-1 text-xs font-semibold', statusAtletaClasses(meuCadastro.status)]">
            {{ statusAtletaLabel(meuCadastro.status) }}
          </span>

          <dl class="mt-5 space-y-3 border-t border-ink/8 pt-4">
            <div class="flex justify-between text-sm"><dt class="text-ink-soft">No projeto desde</dt><dd class="text-ink">{{ formatarData(meuCadastro.data_ingresso) }}</dd></div>
            <div v-if="meuCadastro.escola" class="flex justify-between text-sm"><dt class="text-ink-soft">Escola</dt><dd class="text-ink">{{ meuCadastro.escola }}</dd></div>
          </dl>
        </div>

        <div v-if="meuCadastro.plano" class="rounded-2xl bg-white p-6 shadow-card">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">MEU PLANO</p>
          <p class="mt-1 text-lg font-bold text-ink">{{ meuCadastro.plano.nome }}</p>
          <p class="text-sm text-ink-soft">{{ brl(meuCadastro.plano.valor_mensal) }}/mês</p>
        </div>

        <div v-if="minhasMensalidades.length" class="rounded-2xl bg-white p-6 shadow-card">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">SITUAÇÃO RECENTE</p>
          <div class="mt-3 divide-y divide-ink/8">
            <div v-for="m in minhasMensalidades" :key="m.id" class="flex items-center justify-between py-2 text-sm">
              <span class="text-ink">{{ formatarCompetencia(m.competencia) }}</span>
              <span :class="['rounded-full px-3 py-1 text-xs font-semibold', mensalidadeBaseStatusClasses(m.status)]">{{ mensalidadeBaseStatusLabel(m.status) }}</span>
            </div>
          </div>
        </div>

        <div class="rounded-2xl border border-dashed border-ink/15 p-6 text-center">
          <Icon name="calendar" class="mx-auto h-6 w-6 text-ink-soft/50" />
          <p class="mt-2 text-sm text-ink-soft">Calendário de treinos e avaliações por critério chegam nas próximas fases do módulo.</p>
        </div>
      </div>

  </div>
</template>
