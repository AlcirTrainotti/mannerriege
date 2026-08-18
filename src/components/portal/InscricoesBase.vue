<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { formatarDataCurta } from '../../data/campeonatos.js'

// Gestão de inscrições da "Experiência Mannerriege" — antes só dava pra
// ver pelo Table Editor do Supabase; aqui a equipe da base acompanha e
// avança o status de cada inscrição (recebida -> ... -> matrícula).
defineProps({
  embedded: { type: Boolean, default: false },
})

const statusOptions = [
  { value: 'recebida', label: 'Recebida' },
  { value: 'em_validacao', label: 'Em validação' },
  { value: 'confirmada', label: 'Confirmada' },
  { value: 'presenca_confirmada', label: 'Presença confirmada' },
  { value: 'compareceu', label: 'Compareceu' },
  { value: 'matricula', label: 'Matrícula' },
  { value: 'lista_espera', label: 'Lista de espera' },
  { value: 'cancelada', label: 'Cancelada' },
]

function statusLabel(v) {
  return statusOptions.find((s) => s.value === v)?.label ?? v
}

function statusClasses(v) {
  if (v === 'matricula') return 'bg-[#EAF3DE] text-[#27500A]'
  if (v === 'cancelada') return 'bg-brand-soft text-brand-deep'
  if (v === 'lista_espera') return 'bg-gold-soft text-ink'
  return 'bg-ink/8 text-ink-soft'
}

const inscricoes = ref([])
const carregando = ref(true)
const filtroStatus = ref('todos')

async function carregar() {
  carregando.value = true
  const { data } = await supabase.from('inscricoes_experiencia_base').select('*').order('criado_em', { ascending: false })
  inscricoes.value = data ?? []
  carregando.value = false
}
onMounted(carregar)

const inscricoesFiltradas = computed(() => {
  if (filtroStatus.value === 'todos') return inscricoes.value
  return inscricoes.value.filter((i) => i.status === filtroStatus.value)
})

async function mudarStatus(insc, novoStatus) {
  const { error } = await supabase.from('inscricoes_experiencia_base').update({ status: novoStatus }).eq('id', insc.id)
  if (!error) insc.status = novoStatus
}

const expandidoId = ref(null)
</script>

<template>
  <div>
    <div v-if="!embedded">
      <p class="font-mono-label text-[11px] font-bold text-brand-deep">Eventos</p>
      <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Gestão de inscrições</h1>
    </div>

    <select v-model="filtroStatus" :class="embedded ? '' : 'mt-6'" class="rounded-lg border border-ink/15 px-3 py-2 text-xs">
      <option value="todos">Todos os status</option>
      <option v-for="s in statusOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
    </select>

    <p v-if="carregando" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else-if="!inscricoesFiltradas.length" class="mt-6 rounded-2xl border border-dashed border-ink/15 p-8 text-center text-sm text-ink-soft">Nenhuma inscrição encontrada com esse filtro.</div>

    <div v-else class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
      <div v-for="i in inscricoesFiltradas" :key="i.id" class="px-5 py-3.5">
        <div class="flex flex-wrap items-center justify-between gap-3 cursor-pointer" @click="expandidoId = expandidoId === i.id ? null : i.id">
          <div>
            <p class="text-sm font-semibold text-ink">{{ i.atleta_nome }}</p>
            <p class="text-xs text-ink-soft">{{ formatarDataCurta(i.atleta_data_nascimento) }} · resp. {{ i.responsavel_nome }} · {{ formatarDataCurta(i.criado_em?.slice(0, 10)) }}</p>
          </div>
          <div class="flex items-center gap-2">
            <span class="rounded-full px-2.5 py-0.5 text-[10px] font-bold" :class="statusClasses(i.status)">{{ statusLabel(i.status) }}</span>
            <select :value="i.status" class="rounded-lg border border-ink/15 px-2 py-1.5 text-xs" @click.stop @change="(ev) => mudarStatus(i, ev.target.value)">
              <option v-for="s in statusOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
            </select>
          </div>
        </div>

        <div v-if="expandidoId === i.id" class="mt-3 grid gap-1.5 rounded-xl bg-paper-dim p-4 text-xs text-ink-soft sm:grid-cols-2">
          <p><strong class="text-ink">WhatsApp:</strong> {{ i.responsavel_whatsapp }}</p>
          <p><strong class="text-ink">E-mail:</strong> {{ i.responsavel_email }}</p>
          <p><strong class="text-ink">Relação:</strong> {{ i.responsavel_relacao }}</p>
          <p><strong class="text-ink">Turma:</strong> {{ i.turma }}</p>
          <p><strong class="text-ink">Já praticou vôlei:</strong> {{ i.pratica_volei }}<span v-if="i.pratica_detalhe"> — {{ i.pratica_detalhe }}</span></p>
          <p><strong class="text-ink">Objetivo:</strong> {{ i.objetivo }}<span v-if="i.objetivo_outro"> — {{ i.objetivo_outro }}</span></p>
          <p v-if="i.condicao_saude" class="sm:col-span-2"><strong class="text-ink">Condição de saúde:</strong> {{ i.condicao_saude }}</p>
          <p><strong class="text-ink">Contato de emergência:</strong> {{ i.contato_emergencia }}</p>
          <p><strong class="text-ink">Origem:</strong> {{ i.origem }}<span v-if="i.origem_outro"> — {{ i.origem_outro }}</span></p>
          <p><strong class="text-ink">Autoriza uso de imagem:</strong> {{ i.autorizacao_imagem === 'autorizo' ? 'Sim' : 'Não' }}</p>
        </div>
      </div>
    </div>
  </div>
</template>
