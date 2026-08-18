<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import { nomeCategoria } from '../../data/base.js'

// Times: subdivisão opcional dentro de uma categoria (ex: Time A / Time
// B dentro do Sub-13 masculino). Cada atleta pertence a no máximo um
// time por vez (atletas_base.time_id).
defineProps({
  embedded: { type: Boolean, default: false },
})

const { profile } = useAuth()

const categorias = ref([])
const times = ref([])
const atletas = ref([])
const carregando = ref(true)

async function carregar() {
  carregando.value = true
  const [{ data: c }, { data: t }, { data: a }] = await Promise.all([
    supabase.from('categorias_base').select('*').order('nome'),
    supabase.from('times_base').select('*').order('nome'),
    supabase.from('atletas_base').select('id, nome, categoria_id, time_id').order('nome'),
  ])
  categorias.value = c ?? []
  times.value = t ?? []
  atletas.value = a ?? []
  carregando.value = false
}
onMounted(carregar)

const timesPorCategoria = computed(() => {
  const mapa = {}
  for (const t of times.value) {
    if (!mapa[t.categoria_id]) mapa[t.categoria_id] = []
    mapa[t.categoria_id].push(t)
  }
  return mapa
})

function atletasDoTime(timeId) {
  return atletas.value.filter((a) => a.time_id === timeId)
}

function atletasSemTime(categoriaId) {
  return atletas.value.filter((a) => a.categoria_id === categoriaId && !a.time_id)
}

// --- Cadastro ---
const mostrarForm = ref(false)
const formTime = ref({ categoria_id: '', nome: '', descricao: '' })
const salvando = ref(false)

async function salvarTime() {
  const f = formTime.value
  if (!f.categoria_id || !f.nome.trim()) return
  salvando.value = true
  const { data, error } = await supabase.from('times_base').insert({
    categoria_id: f.categoria_id,
    nome: f.nome.trim(),
    descricao: f.descricao.trim() || null,
    criado_por: profile.value?.id ?? null,
  }).select().single()
  salvando.value = false
  if (!error) {
    times.value.push(data)
    mostrarForm.value = false
    formTime.value = { categoria_id: '', nome: '', descricao: '' }
  }
}

// --- Edição ---
const editandoId = ref(null)
const formEdicao = ref(null)

function abrirEdicao(t) {
  editandoId.value = t.id
  formEdicao.value = { nome: t.nome, descricao: t.descricao ?? '' }
}

async function salvarEdicao(t) {
  const f = formEdicao.value
  const { error } = await supabase.from('times_base').update({ nome: f.nome.trim(), descricao: f.descricao.trim() || null }).eq('id', t.id)
  if (!error) {
    t.nome = f.nome.trim()
    t.descricao = f.descricao.trim() || null
    editandoId.value = null
  }
}

async function alternarAtivo(t) {
  const { error } = await supabase.from('times_base').update({ ativo: !t.ativo }).eq('id', t.id)
  if (!error) t.ativo = !t.ativo
}

async function excluirTime(t) {
  if (!confirm(`Excluir o time "${t.nome}"? Os atletas dele ficam sem time (não são excluídos).`)) return
  const { error } = await supabase.from('times_base').delete().eq('id', t.id)
  if (!error) times.value = times.value.filter((x) => x.id !== t.id)
}

async function moverAtleta(atletaId, timeId) {
  const { error } = await supabase.from('atletas_base').update({ time_id: timeId || null }).eq('id', atletaId)
  if (!error) {
    const a = atletas.value.find((x) => x.id === atletaId)
    if (a) a.time_id = timeId || null
  }
}
</script>

<template>
  <div>
    <div v-if="!embedded">
      <p class="font-mono-label text-[11px] font-bold text-brand-deep">Operação</p>
      <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Times</h1>
    </div>

    <button v-if="!mostrarForm" :class="embedded ? '' : 'mt-6'" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep" @click="mostrarForm = true">+ Novo time</button>

    <form v-if="mostrarForm" class="mt-4 space-y-3 rounded-2xl bg-white p-6 shadow-card" @submit.prevent="salvarTime">
      <select v-model="formTime.categoria_id" required class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm">
        <option value="" disabled>Categoria...</option>
        <option v-for="c in categorias" :key="c.id" :value="c.id">{{ nomeCategoria(c) }}</option>
      </select>
      <input v-model="formTime.nome" placeholder="Nome do time (ex: Time A)" required class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
      <textarea v-model="formTime.descricao" placeholder="Descrição (opcional)" rows="2" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm"></textarea>
      <div class="flex gap-2">
        <button type="submit" :disabled="salvando" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ salvando ? 'Salvando...' : 'Salvar' }}</button>
        <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="mostrarForm = false">Cancelar</button>
      </div>
    </form>

    <p v-if="carregando" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else class="mt-6 space-y-6">
      <div v-for="c in categorias" :key="c.id">
        <p v-if="(timesPorCategoria[c.id] ?? []).length || atletasSemTime(c.id).length" class="font-mono-label text-[10px] font-bold text-ink-soft">{{ nomeCategoria(c) }}</p>

        <div v-if="(timesPorCategoria[c.id] ?? []).length" class="mt-2 space-y-3">
          <div v-for="t in timesPorCategoria[c.id]" :key="t.id" class="rounded-2xl bg-white p-5 shadow-card">
            <div class="flex flex-wrap items-start justify-between gap-3">
              <div>
                <p class="text-sm font-semibold text-ink">{{ t.nome }}</p>
                <p v-if="t.descricao" class="text-xs text-ink-soft">{{ t.descricao }}</p>
                <p class="mt-1 text-xs text-ink-soft">{{ atletasDoTime(t.id).length }} atleta(s)</p>
              </div>
              <div class="flex items-center gap-2">
                <button class="rounded-full px-3 py-1 text-xs font-semibold" :class="t.ativo ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-ink/8 text-ink-soft'" @click="alternarAtivo(t)">{{ t.ativo ? 'ativo' : 'inativo' }}</button>
                <button class="text-xs font-semibold text-brand-deep hover:underline" @click="editandoId === t.id ? (editandoId = null) : abrirEdicao(t)">{{ editandoId === t.id ? 'Fechar' : 'Editar' }}</button>
                <button class="text-xs font-semibold text-ink-soft hover:text-brand-deep hover:underline" @click="excluirTime(t)">Excluir</button>
              </div>
            </div>

            <div v-if="atletasDoTime(t.id).length" class="mt-3 flex flex-wrap gap-1.5">
              <span v-for="a in atletasDoTime(t.id)" :key="a.id" class="flex items-center gap-1 rounded-full bg-paper-dim px-2.5 py-1 text-xs text-ink">
                {{ a.nome }}
                <button class="text-ink-soft hover:text-brand-deep" title="Remover do time" @click="moverAtleta(a.id, null)">×</button>
              </span>
            </div>

            <form v-if="editandoId === t.id && formEdicao" class="mt-4 space-y-3 rounded-xl bg-paper-dim p-4" @submit.prevent="salvarEdicao(t)">
              <input v-model="formEdicao.nome" required class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
              <textarea v-model="formEdicao.descricao" rows="2" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm"></textarea>
              <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
            </form>
          </div>
        </div>

        <div v-if="atletasSemTime(c.id).length" class="mt-3 rounded-2xl border border-dashed border-ink/15 p-4">
          <p class="text-xs font-semibold text-ink-soft">Sem time definido</p>
          <div class="mt-2 flex flex-wrap items-center gap-2">
            <div v-for="a in atletasSemTime(c.id)" :key="a.id" class="flex items-center gap-1.5 rounded-full bg-white px-2.5 py-1 text-xs text-ink shadow-card">
              {{ a.nome }}
              <select class="rounded border-none bg-transparent text-[10px] text-brand-deep outline-none" @change="(e) => moverAtleta(a.id, e.target.value)">
                <option value="" selected>+ time</option>
                <option v-for="t in timesPorCategoria[c.id] ?? []" :key="t.id" :value="t.id">{{ t.nome }}</option>
              </select>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
