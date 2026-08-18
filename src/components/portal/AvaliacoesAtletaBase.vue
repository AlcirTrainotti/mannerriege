<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import { nomeCategoria, tipoAvaliacaoOptions, tipoAvaliacaoLabel } from '../../data/base.js'

// Acompanhamento periódico do atleta (físico/técnico/psicológico) —
// diferente da nota rápida por evento, isso é uma avaliação mais
// completa, associada diretamente ao atleta.
defineProps({
  embedded: { type: Boolean, default: false },
})

const { profile } = useAuth()

const atletas = ref([])
const categorias = ref([])
const avaliacoes = ref([]) // todas, mais recentes primeiro
const carregando = ref(true)
const busca = ref('')

async function carregar() {
  carregando.value = true
  const [{ data: a }, { data: c }, { data: av }] = await Promise.all([
    supabase.from('atletas_base').select('id, nome, categoria_id').eq('status', 'ativo').order('nome'),
    supabase.from('categorias_base').select('*'),
    supabase.from('avaliacoes_atleta_base').select('*').order('data', { ascending: false }),
  ])
  atletas.value = a ?? []
  categorias.value = c ?? []
  avaliacoes.value = av ?? []
  carregando.value = false
}
onMounted(carregar)

const atletasFiltrados = computed(() => {
  const termo = busca.value.trim().toLowerCase()
  if (!termo) return atletas.value
  return atletas.value.filter((a) => a.nome.toLowerCase().includes(termo))
})

function categoriaDoAtleta(a) {
  return categorias.value.find((c) => c.id === a.categoria_id)
}

function avaliacoesDoAtleta(atletaId) {
  return avaliacoes.value.filter((v) => v.atleta_id === atletaId)
}

function ultimaNota(atletaId, tipo) {
  const lista = avaliacoesDoAtleta(atletaId).filter((v) => v.tipo === tipo)
  return lista[0]?.nota ?? null
}

// --- Expandir / cadastrar avaliação ---
const atletaAbertoId = ref(null)
function alternarAberto(atletaId) {
  atletaAbertoId.value = atletaAbertoId.value === atletaId ? null : atletaId
}

function formVazio() {
  return { tipo: 'fisico', data: new Date().toISOString().slice(0, 10), nota: null, observacoes: '' }
}
const formAvaliacao = ref(formVazio())
const salvando = ref(false)

async function salvarAvaliacao(atletaId) {
  const f = formAvaliacao.value
  salvando.value = true
  const { data, error } = await supabase.from('avaliacoes_atleta_base').insert({
    atleta_id: atletaId,
    tipo: f.tipo,
    data: f.data,
    nota: f.nota || null,
    observacoes: f.observacoes.trim() || null,
    avaliador_id: profile.value?.id ?? null,
  }).select().single()
  salvando.value = false
  if (!error) {
    avaliacoes.value.unshift(data)
    formAvaliacao.value = formVazio()
  }
}

async function excluirAvaliacao(v) {
  if (!confirm('Excluir essa avaliação?')) return
  const { error } = await supabase.from('avaliacoes_atleta_base').delete().eq('id', v.id)
  if (!error) avaliacoes.value = avaliacoes.value.filter((x) => x.id !== v.id)
}
</script>

<template>
  <div>
    <div v-if="!embedded">
      <p class="font-mono-label text-[11px] font-bold text-brand-deep">Operação</p>
      <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Gestão de desempenho</h1>
    </div>

    <input v-model="busca" placeholder="Buscar atleta..." :class="embedded ? '' : 'mt-6'" class="w-full max-w-sm rounded-lg border border-ink/15 px-3 py-2 text-sm" />

    <p v-if="carregando" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else class="mt-4 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
      <div v-for="a in atletasFiltrados" :key="a.id" class="px-5 py-4">
        <div class="flex flex-wrap items-center justify-between gap-3">
          <div>
            <p class="text-sm font-semibold text-ink">{{ a.nome }}</p>
            <p class="text-xs text-ink-soft">{{ nomeCategoria(categoriaDoAtleta(a)) }}</p>
          </div>
          <div class="flex items-center gap-3">
            <span v-for="t in tipoAvaliacaoOptions" :key="t.value" class="text-xs text-ink-soft">
              {{ t.label }}: <strong class="text-ink">{{ ultimaNota(a.id, t.value) ?? '—' }}</strong>
            </span>
            <button class="text-xs font-semibold text-brand-deep hover:underline" @click="alternarAberto(a.id)">{{ atletaAbertoId === a.id ? 'Fechar' : 'Ver / avaliar' }}</button>
          </div>
        </div>

        <div v-if="atletaAbertoId === a.id" class="mt-4 space-y-4 rounded-xl bg-paper-dim p-4">
          <form class="grid gap-3 sm:grid-cols-4" @submit.prevent="salvarAvaliacao(a.id)">
            <select v-model="formAvaliacao.tipo" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm">
              <option v-for="t in tipoAvaliacaoOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
            </select>
            <input v-model="formAvaliacao.data" type="date" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model.number="formAvaliacao.nota" type="number" step="0.1" min="0" max="10" placeholder="Nota (0-10)" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <button type="submit" :disabled="salvando" class="rounded-lg bg-brand px-3 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ salvando ? 'Salvando...' : 'Registrar' }}</button>
            <textarea v-model="formAvaliacao.observacoes" placeholder="Observações (opcional)" rows="2" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm sm:col-span-4"></textarea>
          </form>

          <div v-if="avaliacoesDoAtleta(a.id).length" class="space-y-1.5">
            <p class="font-mono-label text-[9px] font-bold text-ink-soft">HISTÓRICO</p>
            <div v-for="v in avaliacoesDoAtleta(a.id)" :key="v.id" class="flex items-start justify-between gap-3 rounded-lg bg-white px-3 py-2 text-xs shadow-card">
              <div>
                <span class="font-semibold text-ink">{{ tipoAvaliacaoLabel(v.tipo) }}</span>
                <span class="text-ink-soft"> · {{ v.data }} · nota {{ v.nota ?? '—' }}</span>
                <p v-if="v.observacoes" class="mt-0.5 text-ink-soft">{{ v.observacoes }}</p>
              </div>
              <button class="text-ink-soft hover:text-brand-deep" @click="excluirAvaliacao(v)">excluir</button>
            </div>
          </div>
          <p v-else class="text-xs text-ink-soft">Nenhuma avaliação registrada ainda.</p>
        </div>
      </div>
    </div>
  </div>
</template>
