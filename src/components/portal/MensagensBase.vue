<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import { formatarData } from '../../lib/categoria.js'
import { destinoMensagemLabel } from '../../data/base.js'

// Mensagens da equipe da base com as famílias (um canal por
// responsável) — espelha o mesmo canal que o responsável vê no próprio
// painel (mensagens_base.responsavel_id).
defineProps({
  embedded: { type: Boolean, default: false },
})

const { profile } = useAuth()

const canais = ref([])
const carregando = ref(true)
const canalAbertoId = ref(null)
const mensagens = ref([])
const carregandoMensagens = ref(false)
const novaMensagem = ref('')
const enviando = ref(false)

// Responsáveis com quem ainda não existe conversa — pra dar pra equipe
// iniciar contato, e não só responder quem já escreveu primeiro.
const todosResponsaveis = ref([]) // [{ id, nome }]
const novoContatoId = ref('')

async function carregarCanais() {
  carregando.value = true
  const [{ data: canaisData }, { data: contatosData }] = await Promise.all([
    supabase.rpc('listar_canais_mensagens_base'),
    supabase.rpc('listar_contatos_responsaveis_base'),
  ])
  canais.value = canaisData ?? []
  const vistos = new Map()
  for (const c of contatosData ?? []) {
    if (!vistos.has(c.responsavel_id)) vistos.set(c.responsavel_id, c.responsavel_nome)
  }
  todosResponsaveis.value = [...vistos.entries()].map(([id, nome]) => ({ id, nome })).sort((a, b) => a.nome.localeCompare(b.nome))
  carregando.value = false
}
onMounted(carregarCanais)

const responsaveisSemCanal = computed(() => {
  const idsComCanal = new Set(canais.value.map((c) => c.responsavel_id))
  return todosResponsaveis.value.filter((r) => !idsComCanal.has(r.id))
})

function iniciarConversa() {
  if (!novoContatoId.value) return
  abrirCanal(novoContatoId.value)
  novoContatoId.value = ''
}

async function abrirCanal(responsavelId) {
  canalAbertoId.value = canalAbertoId.value === responsavelId ? null : responsavelId
  if (canalAbertoId.value === null) return

  carregandoMensagens.value = true
  const { data } = await supabase
    .from('mensagens_base')
    .select('*')
    .eq('responsavel_id', responsavelId)
    .order('criado_em', { ascending: true })
  mensagens.value = data ?? []
  carregandoMensagens.value = false

  const naoLidas = mensagens.value.filter((m) => m.autor_id !== profile.value.id && !m.lida).map((m) => m.id)
  if (naoLidas.length) {
    await supabase.from('mensagens_base').update({ lida: true }).in('id', naoLidas)
    mensagens.value.forEach((m) => { if (naoLidas.includes(m.id)) m.lida = true })
    const canal = canais.value.find((c) => c.responsavel_id === responsavelId)
    if (canal) canal.nao_lidas = 0
  }
}

async function enviarMensagem() {
  if (!novaMensagem.value.trim() || !canalAbertoId.value) return
  enviando.value = true
  const { data, error } = await supabase.from('mensagens_base').insert({
    responsavel_id: canalAbertoId.value, autor_id: profile.value.id, corpo: novaMensagem.value.trim(),
  }).select().single()
  enviando.value = false
  if (!error) {
    mensagens.value.push(data)
    const canal = canais.value.find((c) => c.responsavel_id === canalAbertoId.value)
    if (canal) {
      canal.ultima_mensagem = data.corpo
      canal.ultima_mensagem_em = data.criado_em
    } else {
      const nome = todosResponsaveis.value.find((r) => r.id === canalAbertoId.value)?.nome ?? '—'
      canais.value.unshift({ responsavel_id: canalAbertoId.value, responsavel_nome: nome, ultima_mensagem: data.corpo, ultima_mensagem_em: data.criado_em, nao_lidas: 0 })
    }
    novaMensagem.value = ''
  }
}
</script>

<template>
  <div>
    <div v-if="!embedded">
      <p class="font-mono-label text-[11px] font-bold text-brand-deep">Operação</p>
      <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Mensagens</h1>
    </div>

    <div v-if="!carregando && responsaveisSemCanal.length" :class="embedded ? '' : 'mt-6'" class="flex flex-wrap items-center gap-2">
      <select v-model="novoContatoId" class="rounded-lg border border-ink/15 px-3 py-2 text-xs">
        <option value="" disabled>+ Iniciar conversa com...</option>
        <option v-for="r in responsaveisSemCanal" :key="r.id" :value="r.id">{{ r.nome }}</option>
      </select>
      <button type="button" :disabled="!novoContatoId" class="rounded-full bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="iniciarConversa">Abrir</button>
    </div>

    <p v-if="carregando" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else-if="!canais.length && canalAbertoId === null" class="mt-6 rounded-2xl border border-dashed border-ink/15 p-8 text-center text-sm text-ink-soft">
      Nenhuma família mandou mensagem ainda — os canais aparecem aqui assim que um responsável escrever pelo próprio painel, ou você pode iniciar uma conversa acima.
    </div>

    <div v-if="canalAbertoId && !canais.some((c) => c.responsavel_id === canalAbertoId)" class="mt-6 rounded-2xl bg-white p-5 shadow-card">
      <p class="text-sm font-semibold text-ink">{{ todosResponsaveis.find((r) => r.id === canalAbertoId)?.nome }}</p>
      <p class="mt-2 text-xs text-ink-soft">Nenhuma mensagem ainda — escreva a primeira.</p>
      <form class="mt-3 flex gap-2" @submit.prevent="enviarMensagem">
        <input v-model="novaMensagem" placeholder="Escrever..." class="min-w-0 flex-1 rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <button type="submit" :disabled="enviando" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ enviando ? 'Enviando...' : 'Enviar' }}</button>
      </form>
    </div>

    <div v-if="canais.length" class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
      <div v-for="c in canais" :key="c.responsavel_id" class="px-5 py-3.5">
        <div class="flex flex-wrap items-center justify-between gap-2 cursor-pointer" @click="abrirCanal(c.responsavel_id)">
          <div class="min-w-0">
            <p class="flex items-center gap-2 text-sm font-semibold text-ink">
              {{ c.responsavel_nome }}
              <span v-if="c.nao_lidas > 0" class="rounded-full bg-brand px-2 py-0.5 text-[10px] font-bold text-white">{{ c.nao_lidas }} nova(s)</span>
            </p>
            <p class="truncate text-xs text-ink-soft">{{ c.ultima_mensagem }}</p>
          </div>
          <span class="flex-shrink-0 text-[10px] text-ink-soft">{{ formatarData(c.ultima_mensagem_em?.slice(0, 10)) }}</span>
        </div>

        <div v-if="canalAbertoId === c.responsavel_id" class="mt-3 rounded-xl bg-paper-dim p-4">
          <p v-if="carregandoMensagens" class="text-xs text-ink-soft">Carregando...</p>
          <div v-else class="max-h-80 space-y-2 overflow-y-auto">
            <div v-for="m in mensagens" :key="m.id" class="flex" :class="m.autor_id === profile.id ? 'justify-end' : 'justify-start'">
              <div class="max-w-[80%] rounded-xl px-3 py-2 text-sm" :class="m.autor_id === profile.id ? 'bg-brand text-white' : 'bg-white text-ink shadow-card'">
                <p v-if="m.autor_id !== profile.id" class="mb-0.5 text-[9px] font-bold uppercase opacity-70">{{ destinoMensagemLabel(m.destino) }}</p>
                <p>{{ m.corpo }}</p>
                <p class="mt-1 text-[10px] opacity-70">{{ formatarData(m.criado_em?.slice(0, 10)) }}</p>
              </div>
            </div>
          </div>

          <form class="mt-3 flex gap-2" @submit.prevent="enviarMensagem">
            <input v-model="novaMensagem" placeholder="Responder..." class="min-w-0 flex-1 rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <button type="submit" :disabled="enviando" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ enviando ? 'Enviando...' : 'Enviar' }}</button>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>
