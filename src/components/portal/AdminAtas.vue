<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { supabase } from '../../lib/supabase.js'
import PaginacaoControle from './PaginacaoControle.vue'
import MarkdownEditor from './MarkdownEditor.vue'
import MarkdownContent from './MarkdownContent.vue'

const atas = ref([])
const loading = ref(true)
const loadError = ref('')
const salvando = ref(false)
const removendoId = ref(null)
const confirmandoId = ref(null)
const editandoId = ref(null)
const paginaAtual = ref(1)
const porPagina = ref(10)

// Formulario de nova ata
const form = ref(formVazio())
function formVazio() {
  return { titulo: '', data_reuniao: '', hora_reuniao: '', local: '', ordem_do_dia: '', link_drive: '' }
}

// Edicao inline
const edit = ref({})

async function carregar() {
  loading.value = true
  loadError.value = ''
  const { data, error } = await supabase
    .from('atas')
    .select('*')
    .order('data_reuniao', { ascending: false })
  if (error) {
    loadError.value = error.message
  } else {
    atas.value = data
  }
  loading.value = false
}

const paginados = computed(() => {
  const ini = (paginaAtual.value - 1) * porPagina.value
  return atas.value.slice(ini, ini + porPagina.value)
})

watch(atas, () => { paginaAtual.value = 1 })

onMounted(carregar)

async function cadastrar() {
  if (!form.value.titulo.trim() || !form.value.data_reuniao || !form.value.link_drive.trim()) {
    loadError.value = 'Preencha título, data e link do Google Drive.'
    return
  }
  salvando.value = true
  loadError.value = ''
  const payload = {
    titulo: form.value.titulo.trim(),
    data_reuniao: form.value.data_reuniao,
    hora_reuniao: form.value.hora_reuniao || null,
    local: form.value.local.trim() || null,
    ordem_do_dia: form.value.ordem_do_dia.trim() || null,
    link_drive: form.value.link_drive.trim(),
  }
  const { error } = await supabase.from('atas').insert(payload)
  salvando.value = false
  if (error) {
    loadError.value = 'Não foi possível cadastrar: ' + error.message
    return
  }
  form.value = formVazio()
  await carregar()
}

function iniciarEdicao(ata) {
  editandoId.value = ata.id
  edit.value = { ...ata }
}

function cancelarEdicao() {
  editandoId.value = null
  edit.value = {}
}

async function salvarEdicao() {
  if (!edit.value.titulo?.trim() || !edit.value.data_reuniao || !edit.value.link_drive?.trim()) {
    loadError.value = 'Preencha título, data e link.'
    return
  }
  salvando.value = true
  const { error } = await supabase.from('atas').update({
    titulo: edit.value.titulo.trim(),
    data_reuniao: edit.value.data_reuniao,
    hora_reuniao: edit.value.hora_reuniao || null,
    local: edit.value.local?.trim() || null,
    ordem_do_dia: edit.value.ordem_do_dia?.trim() || null,
    link_drive: edit.value.link_drive.trim(),
  }).eq('id', edit.value.id)
  salvando.value = false
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  const idx = atas.value.findIndex((a) => a.id === edit.value.id)
  if (idx !== -1) atas.value[idx] = { ...atas.value[idx], ...edit.value }
  cancelarEdicao()
}

async function remover(id) {
  confirmandoId.value = null
  removendoId.value = id
  const { error } = await supabase.from('atas').delete().eq('id', id)
  removendoId.value = null
  if (error) {
    loadError.value = 'Não foi possível remover: ' + error.message
    return
  }
  atas.value = atas.value.filter((a) => a.id !== id)
}

function formatarData(d) {
  if (!d) return '—'
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR', { day: '2-digit', month: 'long', year: 'numeric' })
}
</script>

<template>
  <div>
    <!-- Formulario nova ata -->
    <div class="rounded-2xl bg-white p-6 shadow-card">
      <h2 class="font-display text-xl font-bold text-ink">Cadastrar nova ata</h2>
      <p class="mt-1 text-xs text-ink-soft">Preencha os dados da assembleia e cole o link de compartilhamento do Google Drive.</p>

      <div class="mt-5 grid gap-3 sm:grid-cols-2">
        <div class="sm:col-span-2">
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Título da assembleia *</label>
          <input v-model="form.titulo" type="text" placeholder="Ex: Assembleia Geral Ordinária — 1º semestre 2025"
            class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
        </div>
        <div>
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Data *</label>
          <input v-model="form.data_reuniao" type="date"
            class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
        </div>
        <div>
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Horário</label>
          <input v-model="form.hora_reuniao" type="time"
            class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
        </div>
        <div class="sm:col-span-2">
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Local</label>
          <input v-model="form.local" type="text" placeholder="Ex: Sede do Mannerriege, Joinville/SC"
            class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
        </div>
        <div class="sm:col-span-2">
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Ordem do dia</label>
          <MarkdownEditor
            v-model="form.ordem_do_dia"
            :rows="4"
            placeholder="1. Aprovação da ata anterior&#10;2. Prestação de contas&#10;3. Eleição de diretoria..."
          />
        </div>
        <div class="sm:col-span-2">
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Link do Google Drive *</label>
          <input v-model="form.link_drive" type="url" placeholder="https://drive.google.com/file/d/..."
            class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          <p class="mt-1 text-[10px] text-ink-soft/70">No Drive: botão direito no arquivo → Compartilhar → "Qualquer pessoa com o link" → Copiar link</p>
        </div>
      </div>

      <p v-if="loadError" class="mt-3 text-xs text-brand-deep">{{ loadError }}</p>

      <button
        :disabled="salvando"
        class="mt-4 rounded-full bg-brand px-6 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50"
        @click="cadastrar"
      >{{ salvando ? 'Salvando...' : 'Cadastrar ata' }}</button>
    </div>

    <!-- Lista de atas -->
    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando atas...</p>

    <div v-else class="mt-6 space-y-3">
      <p v-if="atas.length === 0" class="py-8 text-center text-sm text-ink-soft">Nenhuma ata cadastrada ainda.</p>

      <div v-for="a in paginados" :key="a.id" class="rounded-2xl bg-white p-5 shadow-card">

        <!-- Modo visualizacao -->
        <template v-if="editandoId !== a.id">
          <div class="flex items-start justify-between gap-4">
            <div>
              <p class="font-display text-lg font-bold text-ink">{{ a.titulo }}</p>
              <p class="mt-1 text-xs text-ink-soft">
                {{ formatarData(a.data_reuniao) }}
                <span v-if="a.hora_reuniao"> · {{ a.hora_reuniao.slice(0, 5) }}</span>
                <span v-if="a.local"> · {{ a.local }}</span>
              </p>
            </div>
            <div class="flex flex-shrink-0 items-center gap-3">
              <button class="text-xs font-semibold text-ink-soft hover:text-ink" @click="iniciarEdicao(a)">editar</button>
              <template v-if="confirmandoId === a.id">
                <button class="text-xs font-bold text-brand-deep hover:underline" :disabled="removendoId === a.id" @click="remover(a.id)">
                  {{ removendoId === a.id ? 'removendo...' : 'sim, remover' }}
                </button>
                <button class="text-xs text-ink-soft hover:underline" @click="confirmandoId = null">cancelar</button>
              </template>
              <button v-else class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="confirmandoId = a.id">remover</button>
            </div>
          </div>

          <div v-if="a.ordem_do_dia" class="mt-3 rounded-xl bg-paper-dim p-3">
            <p class="font-mono-label text-[9px] font-bold text-ink-soft">ORDEM DO DIA</p>
            <MarkdownContent :content="a.ordem_do_dia" collapsible :collapsed-height="120" class="mt-1" />
          </div>

          <a
            :href="a.link_drive"
            target="_blank"
            rel="noopener"
            class="mt-3 inline-flex items-center gap-1.5 rounded-full border border-ink/15 px-4 py-1.5 text-xs font-semibold text-ink hover:border-brand hover:text-brand-deep"
          >
            <svg class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="currentColor"><path d="M6.28 3l5.72 9.89L4.04 21H2l7.38-12.78L5.72 3h.56zm5.44 0l7.24 12.55L22 21h-2.04l-7.38-12.78L8.16 3h3.56zm4.72 0h2.04l-7.24 12.55L8.16 3h3.56l2.72 4.72L15.44 3z"/></svg>
            Abrir no Google Drive
          </a>
        </template>

        <!-- Modo edicao -->
        <template v-else>
          <div class="grid gap-3 sm:grid-cols-2">
            <div class="sm:col-span-2">
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Título *</label>
              <input v-model="edit.titulo" type="text" class="mt-1 w-full rounded-xl border border-brand bg-white px-4 py-2.5 text-sm text-ink outline-none" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Data *</label>
              <input v-model="edit.data_reuniao" type="date" class="mt-1 w-full rounded-xl border border-brand bg-white px-4 py-2.5 text-sm text-ink outline-none" />
            </div>
            <div>
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Horário</label>
              <input v-model="edit.hora_reuniao" type="time" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div class="sm:col-span-2">
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Local</label>
              <input v-model="edit.local" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
            </div>
            <div class="sm:col-span-2">
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Ordem do dia</label>
              <MarkdownEditor v-model="edit.ordem_do_dia" :rows="4" />
            </div>
            <div class="sm:col-span-2">
              <label class="font-mono-label text-[9px] font-bold text-ink-soft">Link do Google Drive *</label>
              <input v-model="edit.link_drive" type="url" class="mt-1 w-full rounded-xl border border-brand bg-white px-4 py-2.5 text-sm text-ink outline-none" />
            </div>
          </div>
          <div class="mt-4 flex gap-2">
            <button :disabled="salvando" class="rounded-full bg-brand px-5 py-2 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="salvarEdicao">
              {{ salvando ? 'Salvando...' : 'Salvar' }}
            </button>
            <button class="rounded-full border border-ink/15 px-5 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="cancelarEdicao">Cancelar</button>
          </div>
        </template>

      </div>
    </div>

    <PaginacaoControle
      v-model:pagina="paginaAtual"
      v-model:por-pagina="porPagina"
      :total="atas.length"
    />
  </div>
</template>
