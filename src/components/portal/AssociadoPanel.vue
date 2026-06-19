<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import { modalidadeLabel, statusLabel } from '../../data/portal.js'
import { posicaoLabel } from '../../data/convidados.js'
import { calcularCategoria, formatarData } from '../../lib/categoria.js'
import Icon from '../Icon.vue'
import AvatarUpload from './AvatarUpload.vue'
import MarkdownContent from './MarkdownContent.vue'
import { brl, formatarDataCurta } from '../../data/campeonatos.js'

const { profile, logout } = useAuth()

const PAGE = 5

// --- Avisos ---
const avisos = ref([])
const loadingAvisos = ref(true)
const toastNovoAviso = ref(null)
const paginaAvisos = ref(1)
const avisosVisiveis = computed(() => avisos.value.slice(0, paginaAvisos.value * PAGE))
const temMaisAvisos = computed(() => avisos.value.length > paginaAvisos.value * PAGE)
let canal = null

async function carregarAvisos() {
  loadingAvisos.value = true
  const { data, error } = await supabase
    .from('avisos')
    .select('*')
    .order('criado_em', { ascending: false })
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

function iniciarRealtime() {
  canal = supabase
    .channel('avisos-publicos')
    .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'avisos' }, async (payload) => {
      const novoAviso = payload.new
      avisos.value = [novoAviso, ...avisos.value]
      if (profile.value) {
        await supabase.from('avisos_visualizacoes').upsert(
          [{ aviso_id: novoAviso.id, profile_id: profile.value.id }],
          { onConflict: 'aviso_id,profile_id', ignoreDuplicates: true }
        )
      }
      toastNovoAviso.value = novoAviso.titulo
      setTimeout(() => { toastNovoAviso.value = null }, 5000)
    })
    .subscribe()
}

// --- Campeonatos em que participo ---
const meusCampeonatos = ref([]) // [{ campeonato, categorias: [{...categoria}] }]
const loadingCampeonatos = ref(true)
const equipePorCategoria = ref({}) // categoriaId -> [{ id, tipo, nome, funcao }]
const carregandoEquipe = ref({}) // categoriaId -> bool
const categoriaExpandida = ref(null)

async function carregarMeusCampeonatos() {
  loadingCampeonatos.value = true
  if (!profile.value) {
    loadingCampeonatos.value = false
    return
  }

  const { data: minhasParticipacoes } = await supabase
    .from('campeonato_participantes')
    .select('campeonato_categoria_id')
    .eq('tipo', 'associado')
    .eq('associado_id', profile.value.id)

  const categoriaIds = [...new Set((minhasParticipacoes ?? []).map((p) => p.campeonato_categoria_id))]

  if (categoriaIds.length === 0) {
    meusCampeonatos.value = []
    loadingCampeonatos.value = false
    return
  }

  const { data: categorias } = await supabase
    .from('campeonato_categorias')
    .select('*')
    .in('id', categoriaIds)

  const campeonatoIds = [...new Set((categorias ?? []).map((c) => c.campeonato_id))]

  const { data: campeonatos } = await supabase
    .from('campeonatos')
    .select('*')
    .in('id', campeonatoIds)
    .order('data_inicio', { ascending: false, nullsFirst: false })

  meusCampeonatos.value = (campeonatos ?? []).map((camp) => ({
    campeonato: camp,
    categorias: (categorias ?? []).filter((c) => c.campeonato_id === camp.id),
  }))

  loadingCampeonatos.value = false
}

async function alternarEquipe(categoriaId) {
  if (categoriaExpandida.value === categoriaId) {
    categoriaExpandida.value = null
    return
  }
  categoriaExpandida.value = categoriaId
  if (equipePorCategoria.value[categoriaId]) return

  carregandoEquipe.value = { ...carregandoEquipe.value, [categoriaId]: true }
  const { data } = await supabase.rpc('listar_equipe_campeonato_categoria', { p_categoria_id: categoriaId })
  equipePorCategoria.value = { ...equipePorCategoria.value, [categoriaId]: data ?? [] }
  carregandoEquipe.value = { ...carregandoEquipe.value, [categoriaId]: false }
}

function rateioDaCategoria(categoria) {
  const equipe = equipePorCategoria.value[categoria.id]
  if (!equipe) return null
  const atletas = equipe.filter((p) => p.funcao === 'atleta')
  if (atletas.length === 0) return 0
  return Number(categoria.custo_inscricao || 0) / atletas.length
}

// --- Atas ---
const atas = ref([])
const loadingAtas = ref(true)
const paginaAtas = ref(1)
const atasVisiveis = computed(() => atas.value.slice(0, paginaAtas.value * PAGE))
const temMaisAtas = computed(() => atas.value.length > paginaAtas.value * PAGE)

async function carregarAtas() {
  loadingAtas.value = true
  const { data, error } = await supabase
    .from('atas')
    .select('*')
    .order('data_reuniao', { ascending: false })
  if (!error) atas.value = data
  loadingAtas.value = false
}

// --- Utils ---
function statusClasses(status) {
  if (status === 'adimplente') return 'bg-[#EAF3DE] text-[#27500A]'
  if (status === 'inadimplente') return 'bg-brand-soft text-brand-deep'
  return 'bg-ink/8 text-ink-soft'
}

function formatarDataHora(iso) {
  return new Date(iso).toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

function formatarDataAta(d) {
  if (!d) return '—'
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR', { day: '2-digit', month: 'long', year: 'numeric' })
}

onMounted(async () => {
  await carregarAvisos()
  await carregarAtas()
  await carregarMeusCampeonatos()
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

    <!-- Cabecalho com avatar -->
    <div class="flex items-start justify-between gap-4">
      <div class="flex items-center gap-4">
        <AvatarUpload
          v-if="profile"
          :profile-id="profile.id"
          :avatar-url="profile.avatar_url"
          :nome="profile.nome"
          size="lg"
          :editable="true"
          @update:avatar-url="(url) => profile.avatar_url = url"
        />
        <div>
          <p class="font-mono-label text-[11px] font-bold text-brand-deep">Área do associado</p>
          <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">{{ profile?.nome }}</h1>
        </div>
      </div>
      <button
        class="flex-shrink-0 rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30"
        @click="logout"
      >Sair</button>
    </div>

    <!-- Dados do associado -->
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
        <div v-if="profile?.posicao" class="flex items-center justify-between border-b border-ink/8 pb-4">
          <dt class="text-sm text-ink-soft">Posição</dt>
          <dd class="font-display text-xl font-bold text-ink">{{ posicaoLabel(profile?.posicao) }}</dd>
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
        <div v-if="profile?.telefone" class="flex items-center justify-between border-b border-ink/8 pb-4">
          <dt class="text-sm text-ink-soft">Telefone / WhatsApp</dt>
          <dd class="text-sm text-ink">{{ profile.telefone }}</dd>
        </div>
        <div class="flex items-center justify-between">
          <dt class="text-sm text-ink-soft">E-mail</dt>
          <dd class="text-sm text-ink">{{ profile?.email }}</dd>
        </div>
      </dl>
    </div>

    <!-- Placeholder financeiro -->
    <div class="mt-6 rounded-2xl border border-dashed border-ink/15 p-6 text-center">
      <Icon name="calendar" class="mx-auto h-6 w-6 text-ink-soft/50" />
      <p class="mt-2 text-sm text-ink-soft">Em breve: lista de mensalidades pagas e pendentes.</p>
    </div>

    <!-- ===== AVISOS ===== -->
    <div class="mt-10 flex items-baseline justify-between">
      <div>
        <h2 class="font-display text-xl font-bold text-ink">Avisos da diretoria</h2>
        <p class="mt-0.5 text-xs text-ink-soft">Você recebe uma notificação ao vivo quando um novo aviso é publicado.</p>
      </div>
      <span v-if="avisos.length > 0" class="font-mono-label text-[10px] text-ink-soft">{{ avisos.length }} total</span>
    </div>

    <p v-if="loadingAvisos" class="mt-4 text-sm text-ink-soft">Carregando avisos...</p>
    <div v-else class="mt-4 space-y-3">
      <div v-if="avisos.length === 0" class="rounded-2xl border border-dashed border-ink/15 p-6 text-center">
        <Icon name="calendar" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Nenhum aviso por aqui ainda.</p>
      </div>

      <div v-for="a in avisosVisiveis" :key="a.id" class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex items-start gap-2">
          <p class="font-display text-lg font-bold text-ink">{{ a.titulo }}</p>
          <span v-if="a.link_drive" class="mt-1 flex-shrink-0 rounded-full bg-gold-soft px-2 py-0.5 font-mono-label text-[9px] font-bold text-ink">ANEXO</span>
        </div>
        <p class="mt-1 text-xs text-ink-soft">{{ formatarDataHora(a.criado_em) }}</p>
        <MarkdownContent :content="a.conteudo" collapsible :collapsed-height="120" class="mt-3" />
        <a
          v-if="a.link_drive"
          :href="a.link_drive"
          target="_blank"
          rel="noopener"
          class="mt-3 inline-flex items-center gap-1.5 rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep"
        >
          <svg class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="currentColor"><path d="M6.28 3l5.72 9.89L4.04 21H2l7.38-12.78L5.72 3h.56zm5.44 0l7.24 12.55L22 21h-2.04l-7.38-12.78L8.16 3h3.56zm4.72 0h2.04l-7.24 12.55L8.16 3h3.56l2.72 4.72L15.44 3z"/></svg>
          Abrir documento no Drive
        </a>
      </div>

      <!-- Paginacao avisos -->
      <div v-if="temMaisAvisos || paginaAvisos > 1" class="flex items-center justify-center gap-3 pt-2">
        <button
          v-if="temMaisAvisos"
          class="rounded-full border border-ink/15 px-5 py-2 text-xs font-semibold text-ink-soft hover:border-brand hover:text-brand-deep"
          @click="paginaAvisos++"
        >
          Ver mais {{ Math.min(avisos.length - paginaAvisos * PAGE, PAGE) }} avisos
        </button>
        <button
          v-if="paginaAvisos > 1"
          class="rounded-full border border-ink/15 px-5 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30"
          @click="paginaAvisos = 1"
        >
          Recolher
        </button>
      </div>
    </div>

    <!-- ===== ATAS ===== -->
    <div class="mt-10 flex items-baseline justify-between">
      <div>
        <h2 class="font-display text-xl font-bold text-ink">Atas das assembleias</h2>
        <p class="mt-0.5 text-xs text-ink-soft">Acesse os documentos das assembleias gerais.</p>
      </div>
      <span v-if="atas.length > 0" class="font-mono-label text-[10px] text-ink-soft">{{ atas.length }} total</span>
    </div>

    <p v-if="loadingAtas" class="mt-4 text-sm text-ink-soft">Carregando atas...</p>
    <div v-else class="mt-4 space-y-3">
      <div v-if="atas.length === 0" class="rounded-2xl border border-dashed border-ink/15 p-6 text-center">
        <Icon name="calendar" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Nenhuma ata disponível ainda.</p>
      </div>

      <div v-for="a in atasVisiveis" :key="a.id" class="rounded-2xl bg-white p-5 shadow-card">
        <p class="font-display text-lg font-bold text-ink">{{ a.titulo }}</p>
        <p class="mt-1 text-xs text-ink-soft">
          {{ formatarDataAta(a.data_reuniao) }}
          <span v-if="a.hora_reuniao"> · {{ a.hora_reuniao.slice(0, 5) }}</span>
          <span v-if="a.local"> · {{ a.local }}</span>
        </p>
        <div v-if="a.ordem_do_dia" class="mt-3 rounded-xl bg-paper-dim p-3">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">ORDEM DO DIA</p>
          <MarkdownContent :content="a.ordem_do_dia" collapsible :collapsed-height="100" class="mt-1" />
        </div>
        <a
          :href="a.link_drive"
          target="_blank"
          rel="noopener"
          class="mt-3 inline-flex items-center gap-1.5 rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep"
        >
          <svg class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="currentColor"><path d="M6.28 3l5.72 9.89L4.04 21H2l7.38-12.78L5.72 3h.56zm5.44 0l7.24 12.55L22 21h-2.04l-7.38-12.78L8.16 3h3.56zm4.72 0h2.04l-7.24 12.55L8.16 3h3.56l2.72 4.72L15.44 3z"/></svg>
          Abrir no Google Drive
        </a>
      </div>

      <!-- Paginacao atas -->
      <div v-if="temMaisAtas || paginaAtas > 1" class="flex items-center justify-center gap-3 pt-2">
        <button
          v-if="temMaisAtas"
          class="rounded-full border border-ink/15 px-5 py-2 text-xs font-semibold text-ink-soft hover:border-brand hover:text-brand-deep"
          @click="paginaAtas++"
        >
          Ver mais {{ Math.min(atas.length - paginaAtas * PAGE, PAGE) }} atas
        </button>
        <button
          v-if="paginaAtas > 1"
          class="rounded-full border border-ink/15 px-5 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30"
          @click="paginaAtas = 1"
        >
          Recolher
        </button>
      </div>
    </div>

    <!-- ===== CAMPEONATOS ===== -->
    <div class="mt-10">
      <h2 class="font-display text-xl font-bold text-ink">Meus campeonatos</h2>
      <p class="mt-0.5 text-xs text-ink-soft">Campeonatos em que você está escalado pela coordenação esportiva.</p>
    </div>

    <p v-if="loadingCampeonatos" class="mt-4 text-sm text-ink-soft">Carregando...</p>
    <div v-else class="mt-4 space-y-3">
      <div v-if="meusCampeonatos.length === 0" class="rounded-2xl border border-dashed border-ink/15 p-6 text-center">
        <Icon name="trophy" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Você ainda não está escalado em nenhum campeonato.</p>
      </div>

      <div v-for="item in meusCampeonatos" :key="item.campeonato.id" class="rounded-2xl bg-white p-5 shadow-card">
        <p class="font-display text-lg font-bold text-ink">{{ item.campeonato.nome }}</p>
        <p class="mt-1 text-xs text-ink-soft">
          <span v-if="item.campeonato.cidade || item.campeonato.estado">{{ item.campeonato.cidade }}<span v-if="item.campeonato.cidade && item.campeonato.estado">/</span>{{ item.campeonato.estado }} · </span>
          <span v-if="item.campeonato.data_inicio">{{ formatarDataCurta(item.campeonato.data_inicio) }}<span v-if="item.campeonato.data_fim"> a {{ formatarDataCurta(item.campeonato.data_fim) }}</span></span>
          <span v-else>data a definir</span>
        </p>
        <p v-if="item.campeonato.contato_nome || item.campeonato.contato_telefone || item.campeonato.contato_email" class="mt-1 text-xs text-ink-soft">
          Contato: {{ item.campeonato.contato_nome }}<span v-if="item.campeonato.contato_nome && item.campeonato.contato_telefone"> · </span>{{ item.campeonato.contato_telefone }}<span v-if="item.campeonato.contato_email"><span v-if="item.campeonato.contato_nome || item.campeonato.contato_telefone"> · </span>{{ item.campeonato.contato_email }}</span>
        </p>

        <div class="mt-3 flex flex-wrap gap-2">
          <button
            v-for="cat in item.categorias"
            :key="cat.id"
            class="rounded-full px-3 py-1.5 text-xs font-semibold transition-colors"
            :class="categoriaExpandida === cat.id ? 'bg-ink text-white' : 'bg-paper-dim text-ink hover:bg-ink/10'"
            @click="alternarEquipe(cat.id)"
          >Categoria {{ cat.categoria }}</button>
        </div>

        <div v-for="cat in item.categorias" :key="'detalhe-' + cat.id">
          <div v-if="categoriaExpandida === cat.id" class="mt-3 rounded-xl bg-paper-dim p-4">
            <p v-if="carregandoEquipe[cat.id]" class="text-xs text-ink-soft">Carregando equipe...</p>
            <template v-else-if="equipePorCategoria[cat.id]">
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">ATLETAS</p>
              <ul class="mt-1.5 space-y-1">
                <li v-for="p in equipePorCategoria[cat.id].filter((p) => p.funcao === 'atleta')" :key="p.id" class="text-sm text-ink">
                  {{ p.nome }} <span v-if="p.tipo === 'convidado'" class="text-xs text-gold">· convidado</span>
                </li>
              </ul>

              <p class="mt-3 font-mono-label text-[9px] font-bold text-ink-soft">COMISSÃO TÉCNICA</p>
              <ul class="mt-1.5 space-y-1">
                <li v-for="p in equipePorCategoria[cat.id].filter((p) => p.funcao === 'comissao_tecnica')" :key="p.id" class="text-sm text-ink">
                  {{ p.nome }} <span v-if="p.tipo === 'convidado'" class="text-xs text-gold">· convidado</span>
                </li>
              </ul>

              <p class="mt-3 text-sm font-semibold text-ink">
                Sua parte do rateio: <span class="text-brand-deep">{{ brl(rateioDaCategoria(cat)) }}</span>
              </p>
            </template>
          </div>
        </div>
      </div>
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
