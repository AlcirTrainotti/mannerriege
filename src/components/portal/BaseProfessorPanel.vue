<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'
import {
  idadeAtual, nomeCategoria, statusAtletaLabel, statusAtletaClasses,
  posicaoLabel, tipoEventoOptions, tipoEventoLabel, formatarHora,
} from '../../data/base.js'
import { formatarDataCurta } from '../../data/campeonatos.js'

const { profile, logout } = useAuth()

const aba = ref('atletas')
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

onMounted(carregar)

// ================================================================
// Eventos — chamada e avaliação de desempenho
// ================================================================
const eventos = ref([])
const eventosCarregados = ref(false)
const eventoSelecionadoId = ref(null)
const participantesDoEvento = ref({}) // atleta_id -> row

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
  const { data } = await supabase.from('evento_participantes_base').select('*').eq('evento_id', evento.id)
  const mapa = {}
  for (const p of data ?? []) mapa[p.atleta_id] = p
  participantesDoEvento.value = mapa
}

function participanteDoAtleta(atletaId) {
  return participantesDoEvento.value[atletaId] ?? { presente: null, desempenho_nota: null, desempenho_obs: '' }
}

async function salvarParticipante(atletaId, patch) {
  const atual = participanteDoAtleta(atletaId)
  const linha = {
    evento_id: eventoSelecionadoId.value, atleta_id: atletaId,
    presente: patch.presente !== undefined ? patch.presente : atual.presente,
    desempenho_nota: patch.desempenho_nota !== undefined ? patch.desempenho_nota : atual.desempenho_nota,
    desempenho_obs: patch.desempenho_obs !== undefined ? patch.desempenho_obs : atual.desempenho_obs,
    atualizado_em: new Date().toISOString(),
  }
  const { data, error } = await supabase
    .from('evento_participantes_base')
    .upsert(linha, { onConflict: 'evento_id,atleta_id' })
    .select()
    .single()
  if (!error) participantesDoEvento.value[atletaId] = data
}
</script>

<template>
  <div>
    <div class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <p class="font-mono-label text-[11px] font-bold text-brand-deep">Professor · Categorias de Base</p>
        <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">{{ aba === 'atletas' ? 'Meus atletas' : 'Eventos e desempenho' }}</h1>
      </div>
      <div class="flex items-center gap-3">
        <span class="text-xs text-ink-soft">Logado como {{ profile?.nome }}</span>
        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
      </div>
    </div>

    <div class="mt-6 flex gap-2">
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'atletas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'atletas'">Atletas</button>
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'eventos' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'eventos'; carregarEventos()">Eventos</button>
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

    <!-- ===== EVENTOS ===== -->
    <div v-else class="mt-6 grid gap-4 lg:grid-cols-[18rem_1fr]">
      <div class="max-h-[32rem] overflow-y-auto rounded-2xl bg-white shadow-card">
        <button
          v-for="e in eventos" :key="e.id"
          type="button"
          class="block w-full border-b border-ink/8 px-4 py-3 text-left text-xs last:border-0 hover:bg-paper-dim"
          :class="eventoSelecionadoId === e.id ? 'bg-paper-dim' : ''"
          @click="selecionarEvento(e)"
        >
          <p class="font-semibold text-ink">{{ e.titulo }}</p>
          <p class="text-ink-soft">{{ tipoEventoLabel(e.tipo) }} · {{ formatarDataCurta(e.data) }}</p>
        </button>
        <p v-if="eventosCarregados && eventos.length === 0" class="px-4 py-6 text-center text-xs text-ink-soft">Nenhum evento cadastrado ainda — a coordenação cadastra em Categorias de Base → Eventos.</p>
      </div>

      <div v-if="eventoSelecionado" class="rounded-2xl bg-white p-5 shadow-card">
        <p class="text-sm font-bold text-ink">{{ eventoSelecionado.titulo }}</p>
        <p class="text-xs text-ink-soft">
          {{ tipoEventoLabel(eventoSelecionado.tipo) }} · {{ formatarDataCurta(eventoSelecionado.data) }}
          <span v-if="eventoSelecionado.hora_inicio"> · {{ formatarHora(eventoSelecionado.hora_inicio) }}</span>
          <span v-if="eventoSelecionado.local"> · {{ eventoSelecionado.local }}</span>
        </p>
        <p v-if="eventoSelecionado.plano_atividades" class="mt-2 text-xs text-ink"><strong>Atividades:</strong> {{ eventoSelecionado.plano_atividades }}</p>

        <div class="mt-4 divide-y divide-ink/8 rounded-xl bg-paper-dim">
          <div v-for="a in atletasDoEventoSelecionado" :key="a.id" class="flex flex-wrap items-center gap-2 px-4 py-2.5">
            <span class="min-w-[9rem] flex-1 text-sm text-ink">{{ a.nome }}</span>
            <select
              :value="participanteDoAtleta(a.id).presente === null ? '' : String(participanteDoAtleta(a.id).presente)"
              class="rounded-lg border border-ink/15 bg-white px-2 py-1 text-xs"
              @change="(ev) => salvarParticipante(a.id, { presente: ev.target.value === '' ? null : ev.target.value === 'true' })"
            >
              <option value="">Presença...</option>
              <option value="true">Presente</option>
              <option value="false">Ausente</option>
            </select>
            <input
              type="number" min="0" max="10" step="0.5" placeholder="Nota"
              :value="participanteDoAtleta(a.id).desempenho_nota"
              class="w-20 rounded-lg border border-ink/15 bg-white px-2 py-1 text-xs"
              @change="(ev) => salvarParticipante(a.id, { desempenho_nota: ev.target.value === '' ? null : Number(ev.target.value) })"
            />
            <input
              type="text" placeholder="Observação"
              :value="participanteDoAtleta(a.id).desempenho_obs"
              class="min-w-0 flex-1 rounded-lg border border-ink/15 bg-white px-2 py-1 text-xs"
              @change="(ev) => salvarParticipante(a.id, { desempenho_obs: ev.target.value })"
            />
          </div>
        </div>
      </div>
      <div v-else class="rounded-2xl border border-dashed border-ink/15 p-8 text-center text-sm text-ink-soft">
        Selecione um evento na lista pra registrar presença e desempenho.
      </div>
    </div>

    <div v-if="aba === 'atletas'" class="mt-6 rounded-2xl border border-dashed border-ink/15 p-6 text-center">
      <Icon name="volleyball" class="mx-auto h-6 w-6 text-ink-soft/50" />
      <p class="mt-2 text-sm text-ink-soft">Avaliação por valência (física, técnica, comportamental) detalhada chega numa próxima fase — por enquanto a nota de desempenho é registrada por evento, na aba Eventos.</p>
    </div>
  </div>
</template>
