<script setup>
import { ref, onMounted, defineAsyncComponent } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { ufOptions, formatarDataCurta } from '../../data/campeonatos.js'

const CampeonatoEquipe = defineAsyncComponent(() => import('./CampeonatoEquipe.vue'))
const CampeonatoJogos = defineAsyncComponent(() => import('./CampeonatoJogos.vue'))
const CampeonatoContas = defineAsyncComponent(() => import('./CampeonatoContas.vue'))
const CampeonatoEmprestimos = defineAsyncComponent(() => import('./CampeonatoEmprestimos.vue'))
const MarkdownContent = defineAsyncComponent(() => import('./MarkdownContent.vue'))
const MarkdownEditor = defineAsyncComponent(() => import('./MarkdownEditor.vue'))

const props = defineProps({
  campeonato: { type: Object, required: true },
})
const emit = defineEmits(['voltar'])

const subaba = ref('equipe')
const editando = ref(false)
const salvando = ref(false)

const form = ref({ ...props.campeonato })

const associadosLista = ref([]) // para selecionar o responsavel
async function carregarAssociados() {
  const { data } = await supabase.rpc('listar_associados_basico')
  associadosLista.value = data ?? []
}
onMounted(carregarAssociados)

function nomeResponsavel(id) {
  return associadosLista.value.find((a) => a.id === id)?.nome ?? null
}

async function salvar() {
  salvando.value = true
  const { error } = await supabase.from('campeonatos').update({
    nome: form.value.nome,
    cidade: form.value.cidade,
    estado: form.value.estado,
    contato_nome: form.value.contato_nome,
    contato_telefone: form.value.contato_telefone,
    contato_email: form.value.contato_email,
    data_inicio: form.value.data_inicio || null,
    data_fim: form.value.data_fim || null,
    data_inscricao_equipe: form.value.data_inscricao_equipe || null,
    data_inscricao_atletas: form.value.data_inscricao_atletas || null,
    responsavel_id: form.value.responsavel_id || null,
    observacoes: form.value.observacoes,
  }).eq('id', props.campeonato.id)
  salvando.value = false
  if (!error) {
    Object.assign(props.campeonato, form.value)
    editando.value = false
  }
}

// --- Regulamento (PDF) ---
const enviandoRegulamento = ref(false)
const fileInputRegulamento = ref(null)
const resumoEditando = ref(false)
const resumoTexto = ref(props.campeonato.regulamento_resumo || '')
const salvandoResumo = ref(false)

function abrirSeletorRegulamento() {
  fileInputRegulamento.value?.click()
}

async function aoSelecionarRegulamento(e) {
  const file = e.target.files?.[0]
  if (!file) return
  if (file.type !== 'application/pdf') {
    alert('Envie um arquivo em PDF.')
    return
  }
  if (file.size > 15 * 1024 * 1024) {
    alert('O arquivo deve ter no máximo 15 MB.')
    return
  }
  enviandoRegulamento.value = true
  const caminho = `${props.campeonato.id}/regulamento.pdf`
  const { error: upError } = await supabase.storage
    .from('regulamentos')
    .upload(caminho, file, { upsert: true, contentType: 'application/pdf' })

  if (!upError) {
    const { data } = supabase.storage.from('regulamentos').getPublicUrl(caminho)
    const url = data.publicUrl + '?t=' + Date.now()
    await supabase.from('campeonatos').update({ regulamento_url: url }).eq('id', props.campeonato.id)
    props.campeonato.regulamento_url = url
  }
  enviandoRegulamento.value = false
  e.target.value = ''
}

async function salvarResumo() {
  salvandoResumo.value = true
  await supabase.from('campeonatos').update({ regulamento_resumo: resumoTexto.value }).eq('id', props.campeonato.id)
  props.campeonato.regulamento_resumo = resumoTexto.value
  salvandoResumo.value = false
  resumoEditando.value = false
}

const gerandoResumoIA = ref(false)
const erroResumoIA = ref('')

async function gerarResumoComIA() {
  if (!props.campeonato.regulamento_url) return
  erroResumoIA.value = ''
  gerandoResumoIA.value = true
  const { data, error } = await supabase.functions.invoke('resumir-regulamento', {
    body: { regulamentoUrl: props.campeonato.regulamento_url },
  })
  gerandoResumoIA.value = false
  if (error || data?.error) {
    erroResumoIA.value = data?.error || 'Não foi possível gerar o resumo automático. Verifique a configuração em supabase/COMO_CONFIGURAR_RESUMO_IA.md.'
    return
  }
  resumoTexto.value = data.resumo
  resumoEditando.value = true
}
</script>

<template>
  <div>
    <button class="flex items-center gap-1.5 text-xs font-semibold text-ink-soft hover:text-brand-deep" @click="emit('voltar')">
      ← Voltar aos campeonatos
    </button>

    <!-- Cabecalho / dados do campeonato -->
    <div class="mt-3 rounded-2xl bg-white p-6 shadow-card">
      <div v-if="!editando" class="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 class="font-display text-2xl font-extrabold text-ink">{{ campeonato.nome }}</h2>
          <p class="mt-1 text-sm text-ink-soft">
            <span v-if="campeonato.cidade || campeonato.estado">{{ campeonato.cidade }}<span v-if="campeonato.cidade && campeonato.estado">/</span>{{ campeonato.estado }} · </span>
            <span v-if="campeonato.data_inicio">{{ formatarDataCurta(campeonato.data_inicio) }}<span v-if="campeonato.data_fim"> a {{ formatarDataCurta(campeonato.data_fim) }}</span></span>
            <span v-else>data a definir</span>
          </p>
          <p v-if="campeonato.contato_nome || campeonato.contato_telefone || campeonato.contato_email" class="mt-1 text-sm text-ink-soft">
            Contato: {{ campeonato.contato_nome }}<span v-if="campeonato.contato_nome && campeonato.contato_telefone"> · </span>{{ campeonato.contato_telefone }}<span v-if="campeonato.contato_email"><span v-if="campeonato.contato_nome || campeonato.contato_telefone"> · </span>{{ campeonato.contato_email }}</span>
          </p>
          <p v-if="campeonato.responsavel_id" class="mt-1 text-sm text-ink-soft">
            Responsável pelo campeonato: <strong class="text-ink">{{ nomeResponsavel(campeonato.responsavel_id) }}</strong>
          </p>
          <p v-if="campeonato.data_inscricao_equipe || campeonato.data_inscricao_atletas" class="mt-1 text-sm text-ink-soft">
            <span v-if="campeonato.data_inscricao_equipe">Inscrição da equipe até {{ formatarDataCurta(campeonato.data_inscricao_equipe) }}</span>
            <span v-if="campeonato.data_inscricao_equipe && campeonato.data_inscricao_atletas"> · </span>
            <span v-if="campeonato.data_inscricao_atletas">Inscrição dos atletas até {{ formatarDataCurta(campeonato.data_inscricao_atletas) }}</span>
          </p>
          <p v-if="campeonato.observacoes" class="mt-2 text-sm text-ink-soft">{{ campeonato.observacoes }}</p>
        </div>
        <button class="flex-shrink-0 rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="editando = true; form = { ...campeonato }">
          Editar dados
        </button>
      </div>

      <div v-else class="space-y-3">
        <div>
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nome</label>
          <input v-model="form.nome" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
        </div>
        <div class="grid grid-cols-[1fr_90px] gap-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Cidade</label>
            <input v-model="form.cidade" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">UF</label>
            <select v-model="form.estado" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-2 py-2.5 text-sm text-ink outline-none focus:border-brand">
              <option v-for="uf in ufOptions" :key="uf" :value="uf">{{ uf }}</option>
            </select>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Início</label>
            <input v-model="form.data_inicio" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Fim</label>
            <input v-model="form.data_fim" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Inscrição da equipe até</label>
            <input v-model="form.data_inscricao_equipe" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Inscrição dos atletas até</label>
            <input v-model="form.data_inscricao_atletas" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
        </div>
        <div>
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Responsável pelo campeonato</label>
          <select v-model="form.responsavel_id" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand">
            <option :value="null">Não definido</option>
            <option v-for="a in associadosLista" :key="a.id" :value="a.id">{{ a.nome }}</option>
          </select>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Contato</label>
            <input v-model="form.contato_nome" type="text" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Telefone</label>
            <input v-model="form.contato_telefone" type="tel" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-3 py-2.5 text-sm text-ink outline-none focus:border-brand" />
          </div>
        </div>
        <div>
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">E-mail do contato</label>
          <input v-model="form.contato_email" type="email" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand" />
        </div>
        <div>
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Observações</label>
          <textarea v-model="form.observacoes" rows="2" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"></textarea>
        </div>
        <div class="flex gap-2">
          <button :disabled="salvando" class="rounded-full bg-brand px-5 py-2 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="salvar">
            {{ salvando ? 'Salvando...' : 'Salvar' }}
          </button>
          <button class="rounded-full border border-ink/15 px-5 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="editando = false">Cancelar</button>
        </div>
      </div>
    </div>

    <!-- Regulamento -->
    <div class="mt-4 rounded-2xl bg-white p-6 shadow-card">
      <div class="flex flex-wrap items-center justify-between gap-3">
        <h3 class="font-display text-lg font-bold text-ink">Regulamento</h3>
        <div class="flex items-center gap-2">
          <a
            v-if="campeonato.regulamento_url"
            :href="campeonato.regulamento_url"
            target="_blank"
            rel="noopener"
            class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30"
          >Abrir PDF</a>
          <button :disabled="enviandoRegulamento" class="rounded-full bg-brand px-4 py-2 font-mono-label text-[11px] font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="abrirSeletorRegulamento">
            {{ enviandoRegulamento ? 'Enviando...' : campeonato.regulamento_url ? 'Trocar PDF' : 'Importar PDF' }}
          </button>
          <input ref="fileInputRegulamento" type="file" accept="application/pdf" class="hidden" @change="aoSelecionarRegulamento" />
        </div>
      </div>

      <div class="mt-3">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">RESUMO</p>
          <div class="flex items-center gap-3">
            <button
              v-if="campeonato.regulamento_url && !resumoEditando"
              :disabled="gerandoResumoIA"
              class="text-xs font-semibold text-gold hover:underline disabled:opacity-50"
              @click="gerarResumoComIA"
            >{{ gerandoResumoIA ? '✨ Gerando...' : '✨ Gerar resumo automático' }}</button>
            <button v-if="!resumoEditando" class="text-xs font-semibold text-brand-deep hover:underline" @click="resumoEditando = true; resumoTexto = campeonato.regulamento_resumo || ''">
              {{ campeonato.regulamento_resumo ? 'editar' : '+ escrever resumo' }}
            </button>
          </div>
        </div>
        <p v-if="erroResumoIA" class="mt-1 text-xs text-brand-deep">{{ erroResumoIA }}</p>
        <MarkdownContent v-if="!resumoEditando && campeonato.regulamento_resumo" :content="campeonato.regulamento_resumo" collapsible :collapsed-height="160" class="mt-1" />
        <p v-else-if="!resumoEditando" class="mt-1 text-xs text-ink-soft/60">
          Nenhum resumo cadastrado ainda. Importe o PDF e clique em "Gerar resumo automático", ou escreva você mesmo os pontos principais.
        </p>
        <div v-else class="mt-2">
          <MarkdownEditor v-model="resumoTexto" :rows="6" placeholder="Ex: ## Formato de disputa&#10;- Grupos, melhor de 3 sets..." />
          <div class="mt-2 flex gap-2">
            <button :disabled="salvandoResumo" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50" @click="salvarResumo">
              {{ salvandoResumo ? 'Salvando...' : 'Salvar resumo' }}
            </button>
            <button class="rounded-full border border-ink/15 px-4 py-2 text-xs text-ink-soft hover:border-ink/30" @click="resumoEditando = false">Cancelar</button>
          </div>
        </div>
      </div>
    </div>

    <!-- Sub-abas -->
    <div class="mt-6 flex flex-wrap gap-2">
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'equipe' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'equipe'"
      >Categorias e Equipe</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'jogos' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'jogos'"
      >Jogos e Conflitos</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'contas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'contas'"
      >Prestação de Contas</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'emprestimos' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'emprestimos'"
      >Empréstimos</button>
    </div>

    <div class="mt-6">
      <CampeonatoEquipe v-if="subaba === 'equipe'" :campeonato="campeonato" />
      <CampeonatoJogos v-else-if="subaba === 'jogos'" :campeonato="campeonato" />
      <CampeonatoContas v-else-if="subaba === 'contas'" :campeonato="campeonato" />
      <CampeonatoEmprestimos v-else :campeonato="campeonato" />
    </div>
  </div>
</template>
