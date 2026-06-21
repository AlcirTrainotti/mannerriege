<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { formatarDataCurta } from '../../data/campeonatos.js'
import { obterTempoDeslocamento } from '../../lib/distanciaGinasios.js'

const props = defineProps({
  campeonato: { type: Object, required: true },
})

const categorias = ref([])
const jogos = ref([])
const participantes = ref([])
const associadosMap = ref({})
const convidadosMap = ref({})
const loading = ref(true)
const loadError = ref('')

async function carregar() {
  loading.value = true
  loadError.value = ''

  const { data: cats } = await supabase
    .from('campeonato_categorias')
    .select('*')
    .eq('campeonato_id', props.campeonato.id)
    .order('categoria')
  categorias.value = cats ?? []

  const [assocsRes, convsRes] = await Promise.all([
    supabase.rpc('listar_associados_basico'),
    supabase.from('convidados').select('id, nome'),
  ])
  const am = {}
  ;(assocsRes.data ?? []).forEach((a) => { am[a.id] = a })
  associadosMap.value = am
  const cm = {}
  ;(convsRes.data ?? []).forEach((c) => { cm[c.id] = c })
  convidadosMap.value = cm

  if ((cats ?? []).length > 0) {
    const catIds = cats.map((c) => c.id)

    const [jgsRes, partsRes] = await Promise.all([
      supabase.from('campeonato_jogos').select('*').in('campeonato_categoria_id', catIds).order('data').order('hora_inicio'),
      supabase.from('campeonato_participantes').select('*').in('campeonato_categoria_id', catIds),
    ])
    if (jgsRes.error) loadError.value = jgsRes.error.message
    jogos.value = jgsRes.data ?? []
    participantes.value = partsRes.data ?? []
  } else {
    jogos.value = []
    participantes.value = []
  }

  loading.value = false
}

onMounted(async () => {
  await carregar()
  await carregarConflitosSalvos()
})

function jogosDe(categoriaId) {
  return jogos.value.filter((j) => j.campeonato_categoria_id === categoriaId)
}

function nomeCategoria(categoriaId) {
  return categorias.value.find((c) => c.id === categoriaId)?.categoria ?? '?'
}

function nomeDe(p) {
  if (p.tipo === 'associado') return associadosMap.value[p.associado_id]?.nome ?? '(removido)'
  return convidadosMap.value[p.convidado_id]?.nome ?? '(removido)'
}

function chaveParticipante(p) {
  return p.tipo === 'associado' ? `a:${p.associado_id}` : `c:${p.convidado_id}`
}

// --- CRUD de jogos ---
const formAberta = ref(null)
const novoJogo = ref({ data: '', hora_inicio: '', hora_fim: '', ginasio_nome: '', ginasio_endereco: '', adversario: '', observacoes: '' })
const salvandoJogo = ref(false)
const editandoId = ref(null)
const editJogo = ref({})

function abrirNovoJogo(categoriaId) {
  formAberta.value = categoriaId
  novoJogo.value = { data: '', hora_inicio: '', hora_fim: '', ginasio_nome: '', ginasio_endereco: '', adversario: '', observacoes: '' }
}

async function salvarNovoJogo(categoriaId) {
  if (!novoJogo.value.data || !novoJogo.value.hora_inicio) return
  salvandoJogo.value = true
  await supabase.from('campeonato_jogos').insert({
    campeonato_categoria_id: categoriaId,
    data: novoJogo.value.data,
    hora_inicio: novoJogo.value.hora_inicio,
    hora_fim: novoJogo.value.hora_fim || null,
    ginasio_nome: novoJogo.value.ginasio_nome.trim() || null,
    ginasio_endereco: novoJogo.value.ginasio_endereco.trim() || null,
    adversario: novoJogo.value.adversario.trim() || null,
    observacoes: novoJogo.value.observacoes.trim() || null,
  })
  salvandoJogo.value = false
  formAberta.value = null
  await carregar()
}

function iniciarEdicao(jogo) {
  editandoId.value = jogo.id
  editJogo.value = { ...jogo }
}

async function salvarEdicao() {
  salvandoJogo.value = true
  await supabase.from('campeonato_jogos').update({
    data: editJogo.value.data,
    hora_inicio: editJogo.value.hora_inicio,
    hora_fim: editJogo.value.hora_fim || null,
    ginasio_nome: editJogo.value.ginasio_nome,
    ginasio_endereco: editJogo.value.ginasio_endereco,
    adversario: editJogo.value.adversario,
    observacoes: editJogo.value.observacoes,
  }).eq('id', editJogo.value.id)
  salvandoJogo.value = false
  editandoId.value = null
  await carregar()
}

async function removerJogo(id) {
  if (!confirm('Remover este jogo da agenda?')) return
  await supabase.from('campeonato_jogos').delete().eq('id', id)
  jogos.value = jogos.value.filter((j) => j.id !== id)
}

// --- Deteccao de conflitos ---
const verificando = ref(false)
const conflitos = ref([])
const jaVerificou = computed(() => Boolean(props.campeonato.conflitos_verificados_em))

function paraMinutos(hora) {
  if (!hora) return null
  const [h, m] = hora.split(':').map(Number)
  return h * 60 + m
}

async function carregarConflitosSalvos() {
  const { data } = await supabase
    .from('campeonato_conflitos')
    .select('*')
    .eq('campeonato_id', props.campeonato.id)

  conflitos.value = (data ?? []).map((c) => ({
    pessoas: c.pessoas ?? [],
    jogoPrimeiro: jogos.value.find((j) => j.id === c.jogo_a_id) ?? { campeonato_categoria_id: c.campeonato_categoria_id_a, hora_inicio: null, ginasio_nome: null },
    jogoSegundo: jogos.value.find((j) => j.id === c.jogo_b_id) ?? { campeonato_categoria_id: c.campeonato_categoria_id_b, hora_inicio: null, ginasio_nome: null },
    motivo: c.motivo,
    deslocamentoMin: c.deslocamento_minutos,
  }))
}

async function verificarConflitos() {
  verificando.value = true

  const encontrados = []

  for (let i = 0; i < jogos.value.length; i++) {
    for (let j = i + 1; j < jogos.value.length; j++) {
      const jogoA = jogos.value[i]
      const jogoB = jogos.value[j]

      if (jogoA.campeonato_categoria_id === jogoB.campeonato_categoria_id) continue
      if (jogoA.data !== jogoB.data) continue

      const partsA = participantes.value.filter((p) => p.campeonato_categoria_id === jogoA.campeonato_categoria_id)
      const partsB = participantes.value.filter((p) => p.campeonato_categoria_id === jogoB.campeonato_categoria_id)
      const chavesA = new Set(partsA.map(chaveParticipante))
      const pessoasComuns = partsB.filter((p) => chavesA.has(chaveParticipante(p)))
      if (pessoasComuns.length === 0) continue

      const inicioA = paraMinutos(jogoA.hora_inicio)
      const fimA = paraMinutos(jogoA.hora_fim) ?? inicioA + 90
      const inicioB = paraMinutos(jogoB.hora_inicio)
      const fimB = paraMinutos(jogoB.hora_fim) ?? inicioB + 90

      const mesmoGinasio = jogoA.ginasio_endereco && jogoB.ginasio_endereco
        ? jogoA.ginasio_endereco.trim().toLowerCase() === jogoB.ginasio_endereco.trim().toLowerCase()
        : jogoA.ginasio_nome && jogoB.ginasio_nome && jogoA.ginasio_nome.trim().toLowerCase() === jogoB.ginasio_nome.trim().toLowerCase()

      const [primeiro, segundo] = inicioA <= inicioB ? [jogoA, jogoB] : [jogoB, jogoA]
      const fimPrimeiro = inicioA <= inicioB ? fimA : fimB
      const inicioSegundo = inicioA <= inicioB ? inicioB : inicioA

      let conflita = false
      let motivo = ''
      let deslocamentoMin = null

      if (mesmoGinasio) {
        if (inicioSegundo < fimPrimeiro) {
          conflita = true
          motivo = 'Mesmo ginásio, horários sobrepostos'
        }
      } else if (jogoA.ginasio_endereco && jogoB.ginasio_endereco) {
        deslocamentoMin = await obterTempoDeslocamento(jogoA.ginasio_endereco, jogoB.ginasio_endereco)
        const folga = inicioSegundo - fimPrimeiro
        if (deslocamentoMin === null) {
          motivo = 'Não foi possível calcular o deslocamento entre os endereços informados'
          conflita = folga < 0
        } else if (folga < deslocamentoMin) {
          conflita = true
          motivo = `Apenas ${Math.max(folga, 0)} min de intervalo, mas o deslocamento leva ~${deslocamentoMin} min`
        }
      } else {
        if (inicioSegundo < fimPrimeiro) {
          conflita = true
          motivo = 'Horários sobrepostos (endereços não informados para conferir deslocamento)'
        }
      }

      if (conflita) {
        encontrados.push({
          pessoas: pessoasComuns.map(nomeDe),
          jogoPrimeiro: primeiro,
          jogoSegundo: segundo,
          motivo,
          deslocamentoMin,
        })
      }
    }
  }

  // Salva o resultado no banco para nao precisar recalcular toda vez
  await supabase.from('campeonato_conflitos').delete().eq('campeonato_id', props.campeonato.id)
  if (encontrados.length > 0) {
    await supabase.from('campeonato_conflitos').insert(encontrados.map((c) => ({
      campeonato_id: props.campeonato.id,
      campeonato_categoria_id_a: c.jogoPrimeiro.campeonato_categoria_id,
      campeonato_categoria_id_b: c.jogoSegundo.campeonato_categoria_id,
      jogo_a_id: c.jogoPrimeiro.id ?? null,
      jogo_b_id: c.jogoSegundo.id ?? null,
      pessoas: c.pessoas,
      motivo: c.motivo,
      deslocamento_minutos: c.deslocamentoMin,
    })))
  }
  const agora = new Date().toISOString()
  await supabase.from('campeonatos').update({ conflitos_verificados_em: agora }).eq('id', props.campeonato.id)
  props.campeonato.conflitos_verificados_em = agora

  conflitos.value = encontrados
  verificando.value = false
}
</script>

<template>
  <div>
    <div class="flex flex-wrap items-center justify-between gap-3">
      <h3 class="font-display text-xl font-bold text-ink">Agenda de jogos</h3>
      <button :disabled="verificando" class="rounded-full bg-ink px-4 py-2 text-xs font-semibold text-white hover:bg-ink/80 disabled:opacity-50" @click="verificarConflitos">
        {{ verificando ? 'Verificando...' : jaVerificou ? '🔄 Verificar conflitos novamente' : '⚠️ Verificar conflitos de horário' }}
      </button>
    </div>

    <p v-if="jaVerificou" class="mt-1.5 text-xs text-ink-soft/70">
      Última verificação: {{ new Date(campeonato.conflitos_verificados_em).toLocaleString('pt-BR') }}.
      Verifique de novo depois de editar jogos.
    </p>

    <p class="mt-2 text-xs text-ink-soft/70">
      O cálculo de deslocamento entre ginásios usa o serviço gratuito OpenRouteService.
      Se ainda não configurou, veja o guia em supabase/COMO_CONFIGURAR_DESLOCAMENTO.md.
    </p>

    <div v-if="jaVerificou" class="mt-4">
      <div v-if="conflitos.length === 0" class="rounded-2xl bg-[#EAF3DE] p-4 text-sm text-[#27500A]">
        ✓ Nenhum conflito de horário encontrado entre as categorias.
      </div>
      <div v-else class="space-y-3">
        <div v-for="(c, i) in conflitos" :key="i" class="rounded-2xl bg-brand-soft p-4">
          <p class="text-sm font-bold text-brand-deep">⚠️ Possível conflito: {{ c.pessoas.join(', ') }}</p>
          <p class="mt-1 text-xs text-brand-deep">
            {{ nomeCategoria(c.jogoPrimeiro.campeonato_categoria_id) }} às {{ c.jogoPrimeiro.hora_inicio?.slice(0, 5) }}
            ({{ c.jogoPrimeiro.ginasio_nome || 'local não informado' }})
            e {{ nomeCategoria(c.jogoSegundo.campeonato_categoria_id) }} às {{ c.jogoSegundo.hora_inicio?.slice(0, 5) }}
            ({{ c.jogoSegundo.ginasio_nome || 'local não informado' }})
          </p>
          <p class="mt-1 text-xs text-brand-deep">{{ c.motivo }}</p>
        </div>
      </div>
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loading" class="mt-6 text-sm text-ink-soft">Carregando...</p>
    <p v-else-if="categorias.length === 0" class="mt-6 text-sm text-ink-soft">Cadastre categorias na aba "Categorias e Equipe" antes de lançar os jogos.</p>

    <div v-else class="mt-6 space-y-5">
      <div v-for="cat in categorias" :key="cat.id" class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex items-center justify-between">
          <span class="rounded-full bg-brand px-3 py-1 font-mono-label text-[11px] font-bold text-white">{{ cat.categoria }}</span>
          <button class="text-xs font-semibold text-brand-deep hover:underline" @click="abrirNovoJogo(cat.id)">+ adicionar jogo</button>
        </div>

        <div class="mt-3 divide-y divide-ink/8">
          <div v-for="j in jogosDe(cat.id)" :key="j.id" class="py-3">
            <template v-if="editandoId !== j.id">
              <div class="flex flex-wrap items-start justify-between gap-2">
                <div class="text-sm">
                  <p class="font-semibold text-ink">
                    {{ formatarDataCurta(j.data) }} · {{ j.hora_inicio?.slice(0, 5) }}<span v-if="j.hora_fim"> – {{ j.hora_fim.slice(0, 5) }}</span>
                  </p>
                  <p class="text-xs text-ink-soft">
                    {{ j.ginasio_nome || 'ginásio não informado' }}<span v-if="j.ginasio_endereco"> · {{ j.ginasio_endereco }}</span>
                  </p>
                  <p v-if="j.adversario" class="text-xs text-ink-soft">vs. {{ j.adversario }}</p>
                  <p v-if="j.observacoes" class="text-xs text-ink-soft">{{ j.observacoes }}</p>
                </div>
                <div class="flex gap-2">
                  <button class="text-xs text-ink-soft hover:text-ink" @click="iniciarEdicao(j)">editar</button>
                  <button class="text-xs text-ink-soft/50 hover:text-brand-deep" @click="removerJogo(j.id)">remover</button>
                </div>
              </div>
            </template>
            <template v-else>
              <div class="grid gap-2 sm:grid-cols-2">
                <input v-model="editJogo.data" type="date" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
                <div class="grid grid-cols-2 gap-2">
                  <input v-model="editJogo.hora_inicio" type="time" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
                  <input v-model="editJogo.hora_fim" type="time" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
                </div>
                <input v-model="editJogo.ginasio_nome" type="text" placeholder="Ginásio" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
                <input v-model="editJogo.ginasio_endereco" type="text" placeholder="Endereço do ginásio" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
                <input v-model="editJogo.adversario" type="text" placeholder="Adversário" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
                <input v-model="editJogo.observacoes" type="text" placeholder="Observações" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
              </div>
              <div class="mt-2 flex gap-2">
                <button :disabled="salvandoJogo" class="rounded-lg bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="salvarEdicao">Salvar</button>
                <button class="rounded-lg border border-ink/15 px-3 py-1.5 text-xs text-ink-soft hover:border-ink/30" @click="editandoId = null">Cancelar</button>
              </div>
            </template>
          </div>
          <p v-if="jogosDe(cat.id).length === 0" class="py-2 text-xs text-ink-soft/60">Nenhum jogo cadastrado ainda.</p>
        </div>

        <div v-if="formAberta === cat.id" class="mt-3 rounded-xl bg-paper-dim p-4">
          <div class="grid gap-2 sm:grid-cols-2">
            <input v-model="novoJogo.data" type="date" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
            <div class="grid grid-cols-2 gap-2">
              <input v-model="novoJogo.hora_inicio" type="time" placeholder="Início" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
              <input v-model="novoJogo.hora_fim" type="time" placeholder="Fim" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
            </div>
            <input v-model="novoJogo.ginasio_nome" type="text" placeholder="Ginásio" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
            <input v-model="novoJogo.ginasio_endereco" type="text" placeholder="Endereço do ginásio" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
            <input v-model="novoJogo.adversario" type="text" placeholder="Adversário (opcional)" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
            <input v-model="novoJogo.observacoes" type="text" placeholder="Observações" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs text-ink outline-none focus:border-brand" />
          </div>
          <div class="mt-2 flex gap-2">
            <button :disabled="salvandoJogo" class="rounded-lg bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="salvarNovoJogo(cat.id)">Salvar</button>
            <button class="rounded-lg border border-ink/15 px-3 py-1.5 text-xs text-ink-soft hover:border-ink/30" @click="formAberta = null">Cancelar</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
