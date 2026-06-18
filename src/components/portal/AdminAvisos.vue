<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'

const avisos = ref([])
const totalPessoas = ref(0)
const loading = ref(true)
const loadError = ref('')

const titulo = ref('')
const conteudo = ref('')
const publicando = ref(false)
const removendoId = ref(null)

// Edicao inline
const editandoId = ref(null)
const editTitulo = ref('')
const editConteudo = ref('')
const salvandoEdit = ref(false)

function iniciarEdicao(aviso) {
  editandoId.value = aviso.id
  editTitulo.value = aviso.titulo
  editConteudo.value = aviso.conteudo
}

function cancelarEdicao() {
  editandoId.value = null
  editTitulo.value = ''
  editConteudo.value = ''
}

async function salvarEdicao(aviso) {
  if (!editTitulo.value.trim() || !editConteudo.value.trim()) return
  salvandoEdit.value = true
  const { error } = await supabase
    .from('avisos')
    .update({ titulo: editTitulo.value.trim(), conteudo: editConteudo.value.trim() })
    .eq('id', aviso.id)
  salvandoEdit.value = false
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  aviso.titulo = editTitulo.value.trim()
  aviso.conteudo = editConteudo.value.trim()
  cancelarEdicao()
}

async function carregar() {
  loading.value = true
  loadError.value = ''

  const { count } = await supabase.from('profiles').select('*', { count: 'exact', head: true })
  totalPessoas.value = count ?? 0

  const { data, error } = await supabase.from('avisos').select('*').order('criado_em', { ascending: false })
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

onMounted(carregar)

async function publicar() {
  if (!titulo.value.trim() || !conteudo.value.trim()) return
  publicando.value = true
  const { error } = await supabase.from('avisos').insert({
    titulo: titulo.value.trim(),
    conteudo: conteudo.value.trim(),
  })
  publicando.value = false
  if (error) {
    loadError.value = 'Não foi possível publicar: ' + error.message
    return
  }
  titulo.value = ''
  conteudo.value = ''
  await carregar()
}

async function remover(id) {
  if (!confirm('Remover este aviso? Essa ação não pode ser desfeita.')) return
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
          placeholder="Título do aviso"
          class="w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
        />
        <textarea
          v-model="conteudo"
          rows="3"
          placeholder="Mensagem para os associados..."
          class="w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
        ></textarea>
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

      <div v-for="a in avisos" :key="a.id" class="rounded-2xl bg-white p-5 shadow-card">

        <!-- Modo visualizacao -->
        <template v-if="editandoId !== a.id">
          <div class="flex items-start justify-between gap-4">
            <div>
              <p class="font-display text-lg font-bold text-ink">{{ a.titulo }}</p>
              <p class="mt-1 text-xs text-ink-soft">{{ formatarDataHora(a.criado_em) }}</p>
            </div>
            <div class="flex items-center gap-3">
              <button class="text-xs font-semibold text-ink-soft hover:text-ink" @click="iniciarEdicao(a)">editar</button>
              <button
                :disabled="removendoId === a.id"
                class="text-xs font-semibold text-ink-soft hover:text-brand-deep"
                @click="remover(a.id)"
              >{{ removendoId === a.id ? 'removendo...' : 'remover' }}</button>
            </div>
          </div>
          <p class="mt-3 text-sm leading-relaxed text-ink-soft">{{ a.conteudo }}</p>
          <p class="mt-3 font-mono-label text-[10px] font-bold text-brand-deep">
            Visualizado por {{ a.vistoPor }} de {{ totalPessoas }}
          </p>
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
  </div>
</template>
