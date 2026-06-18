<script setup>
import { ref, onMounted, computed, watch } from 'vue'
import { supabase } from '../../lib/supabase.js'
import PaginacaoControle from './PaginacaoControle.vue'

const avisos = ref([])
const totalPessoas = ref(0)
const loading = ref(true)
const loadError = ref('')

const titulo = ref('')
const conteudo = ref('')
const linkDrive = ref('')
const publicando = ref(false)
const removendoId = ref(null)
const confirmandoId = ref(null)
const paginaAtual = ref(1)
const porPagina = ref(10)

// Edicao inline
const editandoId = ref(null)
const editTitulo = ref('')
const editConteudo = ref('')
const editLinkDrive = ref('')
const salvandoEdit = ref(false)

function iniciarEdicao(aviso) {
  editandoId.value = aviso.id
  editTitulo.value = aviso.titulo
  editConteudo.value = aviso.conteudo
  editLinkDrive.value = aviso.link_drive ?? ''
}

function cancelarEdicao() {
  editandoId.value = null
  editTitulo.value = ''
  editConteudo.value = ''
  editLinkDrive.value = ''
}

async function salvarEdicao(aviso) {
  if (!editTitulo.value.trim() || !editConteudo.value.trim()) return
  salvandoEdit.value = true
  const { error } = await supabase
    .from('avisos')
    .update({
      titulo: editTitulo.value.trim(),
      conteudo: editConteudo.value.trim(),
      link_drive: editLinkDrive.value.trim() || null,
    })
    .eq('id', aviso.id)
  salvandoEdit.value = false
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  aviso.titulo = editTitulo.value.trim()
  aviso.conteudo = editConteudo.value.trim()
  aviso.link_drive = editLinkDrive.value.trim() || null
  cancelarEdicao()
}

async function carregar() {
  loading.value = true
  loadError.value = ''

  const { count } = await supabase.from('profiles').select('*', { count: 'exact', head: true })
  totalPessoas.value = count ?? 0

  const { data, error } = await supabase
    .from('avisos')
    .select('*')
    .order('criado_em', { ascending: false })
  if (error) {
    loadError.value = error.message
    loading.value = false
    return
  }

  const comContagem = await Promise.all(
    data.map(async (aviso) => {
      const { count: vistos } = await supabase
        .from('avisos_visualizacoes')
        .select('*', { count: 'exact', head: true })
        .eq('aviso_id', aviso.id)
      return { ...aviso, vistoPor: vistos ?? 0 }
    })
  )

  avisos.value = comContagem
  loading.value = false
}

const paginados = computed(() => {
  const ini = (paginaAtual.value - 1) * porPagina.value
  return avisos.value.slice(ini, ini + porPagina.value)
})

// Reset page when data reloads
watch(avisos, () => { paginaAtual.value = 1 })

onMounted(carregar)

async function publicar() {
  if (!titulo.value.trim() || !conteudo.value.trim()) return
  publicando.value = true
  const { error } = await supabase.from('avisos').insert({
    titulo: titulo.value.trim(),
    conteudo: conteudo.value.trim(),
    link_drive: linkDrive.value.trim() || null,
  })
  publicando.value = false
  if (error) {
    loadError.value = 'Não foi possível publicar: ' + error.message
    return
  }
  titulo.value = ''
  conteudo.value = ''
  linkDrive.value = ''
  await carregar()
}

async function remover(id) {
  confirmandoId.value = null
  removendoId.value = id
  const { error } = await supabase.from('avisos').delete().eq('id', id)
  removendoId.value = null
  if (error) {
    loadError.value = 'Não foi possível remover: ' + error.message
    return
  }
  avisos.value = avisos.value.filter((a) => a.id !== id)
}

function formatarDataHora(iso) {
  return new Date(iso).toLocaleString('pt-BR', {
    day: '2-digit', month: '2-digit', year: 'numeric',
    hour: '2-digit', minute: '2-digit',
  })
}
</script>

<template>
  <div>
    <!-- Formulario novo aviso -->
    <div class="rounded-2xl bg-white p-6 shadow-card">
      <h2 class="font-display text-xl font-bold text-ink">Publicar novo aviso</h2>
      <div class="mt-4 space-y-3">
        <input
          v-model="titulo"
          type="text"
          placeholder="Título do aviso ou edital"
          class="w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
        />
        <textarea
          v-model="conteudo"
          rows="3"
          placeholder="Mensagem para os associados..."
          class="w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
        ></textarea>
        <div>
          <input
            v-model="linkDrive"
            type="url"
            placeholder="Link do Google Drive (opcional — para editais e documentos)"
            class="w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
          />
          <p class="mt-1 text-[10px] text-ink-soft/70">Opcional. No Drive: botão direito → Compartilhar → "Qualquer pessoa com o link" → Copiar link</p>
        </div>
        <button
          :disabled="publicando || !titulo.trim() || !conteudo.trim()"
          class="rounded-full bg-brand px-6 py-2.5 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50"
          @click="publicar"
        >{{ publicando ? 'Publicando...' : 'Publicar aviso' }}</button>
      </div>
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando avisos...</p>

    <div v-else class="mt-6 space-y-3">
      <p v-if="avisos.length === 0" class="py-8 text-center text-sm text-ink-soft">Nenhum aviso publicado ainda.</p>

      <div v-for="a in paginados" :key="a.id" class="rounded-2xl bg-white p-5 shadow-card">

        <!-- Modo visualizacao -->
        <template v-if="editandoId !== a.id">
          <div class="flex items-start justify-between gap-4">
            <div>
              <div class="flex items-center gap-2">
                <p class="font-display text-lg font-bold text-ink">{{ a.titulo }}</p>
                <span v-if="a.link_drive" class="rounded-full bg-gold-soft px-2 py-0.5 font-mono-label text-[9px] font-bold text-ink">
                  COM ANEXO
                </span>
              </div>
              <p class="mt-1 text-xs text-ink-soft">{{ formatarDataHora(a.criado_em) }}</p>
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

          <p class="mt-3 text-sm leading-relaxed text-ink-soft">{{ a.conteudo }}</p>

          <div class="mt-3 flex flex-wrap items-center gap-3">
            <p class="font-mono-label text-[10px] font-bold text-brand-deep">
              Visualizado por {{ a.vistoPor }} de {{ totalPessoas }}
            </p>
            <a
              v-if="a.link_drive"
              :href="a.link_drive"
              target="_blank"
              rel="noopener"
              class="inline-flex items-center gap-1.5 rounded-full border border-ink/15 px-3 py-1 text-xs font-semibold text-ink hover:border-brand hover:text-brand-deep"
            >
              <svg class="h-3 w-3" viewBox="0 0 24 24" fill="currentColor"><path d="M6.28 3l5.72 9.89L4.04 21H2l7.38-12.78L5.72 3h.56zm5.44 0l7.24 12.55L22 21h-2.04l-7.38-12.78L8.16 3h3.56zm4.72 0h2.04l-7.24 12.55L8.16 3h3.56l2.72 4.72L15.44 3z"/></svg>
              Ver anexo no Drive
            </a>
          </div>
        </template>

        <!-- Modo edicao -->
        <template v-else>
          <div class="space-y-3">
            <input
              v-model="editTitulo"
              type="text"
              class="w-full rounded-xl border border-brand bg-white px-4 py-2.5 text-sm font-semibold text-ink outline-none"
            />
            <textarea
              v-model="editConteudo"
              rows="3"
              class="w-full rounded-xl border border-brand bg-white px-4 py-2.5 text-sm text-ink outline-none"
            ></textarea>
            <input
              v-model="editLinkDrive"
              type="url"
              placeholder="Link do Google Drive (opcional)"
              class="w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
            />
            <div class="flex gap-2">
              <button
                :disabled="salvandoEdit"
                class="rounded-full bg-brand px-5 py-2 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50"
                @click="salvarEdicao(a)"
              >{{ salvandoEdit ? 'Salvando...' : 'Salvar' }}</button>
              <button class="rounded-full border border-ink/15 px-5 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="cancelarEdicao">
                Cancelar
              </button>
            </div>
          </div>
        </template>

      </div>
    </div>

    <PaginacaoControle
      v-model:pagina="paginaAtual"
      v-model:por-pagina="porPagina"
      :total="avisos.length"
    />
  </div>
</template>
