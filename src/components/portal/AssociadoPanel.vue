<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import { modalidadeLabel, statusLabel } from '../../data/portal.js'
import { calcularCategoria, formatarData } from '../../lib/categoria.js'
import Icon from '../Icon.vue'

const { profile, logout } = useAuth()

const avisos = ref([])
const loadingAvisos = ref(true)
const toastNovoAviso = ref(null) // texto do aviso que chegou em realtime
let canal = null

function statusClasses(status) {
  if (status === 'adimplente') return 'bg-[#EAF3DE] text-[#27500A]'
  if (status === 'inadimplente') return 'bg-brand-soft text-brand-deep'
  return 'bg-ink/8 text-ink-soft'
}

async function carregarAvisos() {
  loadingAvisos.value = true
  const { data, error } = await supabase.from('avisos').select('*').order('criado_em', { ascending: false })
  if (!error) {
    avisos.value = data
    marcarVisualizados(data)
  }
  loadingAvisos.value = false
}

async function marcarVisualizados(lista) {
  if (!profile.value || lista.length === 0) return
  const linhas = lista.map((a) => ({ aviso_id: a.id, profile_id: profile.value.id }))
  await supabase.from('avisos_visualizacoes').upsert(linhas, {
    onConflict: 'aviso_id,profile_id',
    ignoreDuplicates: true,
  })
}

function formatarDataHora(iso) {
  return new Date(iso).toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

// Realtime: escuta novos avisos enquanto o associado esta com o site aberto
function iniciarRealtime() {
  canal = supabase
    .channel('avisos-publicos')
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'avisos' }, async (payload) => {
      const novoAviso = payload.new
      // Coloca o aviso no topo da lista
      avisos.value = [novoAviso, ...avisos.value]
      // Marca como visualizado
      if (profile.value) {
        await supabase.from('avisos_visualizacoes').upsert(
          [{ aviso_id: novoAviso.id, profile_id: profile.value.id }],
          { onConflict: 'aviso_id,profile_id', ignoreDuplicates: true }
        )
      }
      // Mostra toast
      toastNovoAviso.value = novoAviso.titulo
      setTimeout(() => { toastNovoAviso.value = null }, 5000)
    })
    .subscribe()
}

onMounted(async () => {
  await carregarAvisos()
  iniciarRealtime()
})

onUnmounted(() => {
  if (canal) supabase.removeChannel(canal)
})
</script>

<template>
  <div class="mx-auto max-w-lg">
    <!-- Toast de novo aviso -->
    <transition name="slide-down">
      <div
        v-if="toastNovoAviso"
        class="fixed left-1/2 top-6 z-50 -translate-x-1/2 rounded-full bg-ink px-5 py-3 text-sm font-semibold text-white shadow-card"
      >
        📣 Novo aviso: {{ toastNovoAviso }}
      </div>
    </transition>

    <div class="flex items-center justify-between">
      <div>
        <p class="font-mono-label text-[11px] font-bold text-brand-deep">Área do associado</p>
        <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">{{ profile?.nome }}</h1>
      </div>
      <button
        class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30"
        @click="logout"
      >Sair</button>
    </div>

    <div class="mt-8 rounded-2xl bg-white p-7 shadow-card">
      <dl class="space-y-5">
        <div class="flex items-center justify-between border-b border-ink/8 pb-4">
          <dt class="text-sm text-ink-soft">Categoria</dt>
          <dd class="font-display text-xl font-bold text-ink">{{ calcularCategoria(profile?.data_nascimento) || '—' }}</dd>
        </div>
        <div class="flex items-center justify-between border-b border-ink/8 pb-4">
          <dt class="text-sm text-ink-soft">Modalidade</dt>
          <dd class="font-display text-xl font-bold text-ink">{{ modalidadeLabel(profile?.modalidade) }}</dd>
        </div>
        <div class="flex items-center justify-between border-b border-ink/8 pb-4">
          <dt class="text-sm text-ink-soft">Situação</dt>
          <dd>
            <span :class="['rounded-full px-3 py-1 text-xs font-semibold', statusClasses(profile?.status)]">
              {{ statusLabel(profile?.status) }}
            </span>
          </dd>
        </div>
        <div v-if="profile?.data_associacao" class="flex items-center justify-between border-b border-ink/8 pb-4">
          <dt class="text-sm text-ink-soft">Associado desde</dt>
          <dd class="text-sm font-semibold text-ink">{{ formatarData(profile?.data_associacao) }}</dd>
        </div>
        <div class="flex items-center justify-between">
          <dt class="text-sm text-ink-soft">E-mail</dt>
          <dd class="text-sm text-ink">{{ profile?.email }}</dd>
        </div>
      </dl>
    </div>

    <h2 class="mt-10 font-display text-xl font-bold text-ink">Avisos da diretoria</h2>
    <p class="mt-1 text-xs text-ink-soft">Você recebe uma notificação ao vivo quando um novo aviso é publicado.</p>

    <p v-if="loadingAvisos" class="mt-4 text-sm text-ink-soft">Carregando avisos...</p>
    <div v-else class="mt-4 space-y-3">
      <div v-if="avisos.length === 0" class="rounded-2xl border border-dashed border-ink/15 p-6 text-center">
        <Icon name="calendar" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Nenhum aviso por aqui ainda.</p>
      </div>
      <div v-for="a in avisos" :key="a.id" class="rounded-2xl bg-white p-5 shadow-card">
        <p class="font-display text-lg font-bold text-ink">{{ a.titulo }}</p>
        <p class="mt-1 text-xs text-ink-soft">{{ formatarDataHora(a.criado_em) }}</p>
        <p class="mt-3 text-sm leading-relaxed text-ink-soft">{{ a.conteudo }}</p>
      </div>
    </div>

    <div class="mt-6 rounded-2xl border border-dashed border-ink/15 p-6 text-center">
      <Icon name="calendar" class="mx-auto h-6 w-6 text-ink-soft/50" />
      <p class="mt-2 text-sm text-ink-soft">Em breve: lista de mensalidades pagas e pendentes.</p>
    </div>
  </div>
</template>

<style scoped>
.slide-down-enter-active, .slide-down-leave-active {
  transition: all 0.3s ease;
}
.slide-down-enter-from, .slide-down-leave-to {
  opacity: 0;
  transform: translate(-50%, -1.5rem);
}
</style>
