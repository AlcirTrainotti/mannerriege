<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { categoriaDespesaOptions, tipoReceitaOptions } from '../../data/financeiro.js'
import { statusLabel } from '../../data/portal.js'
import { brl } from '../../data/campeonatos.js'
import CurrencyInput from './CurrencyInput.vue'

// Tela pensada para lançar muitos itens seguidos rapidamente, no lugar
// da planilha: poucos campos, salva e já limpa para o próximo.

const movimento = ref('despesa') // 'despesa' | 'receita' | 'mensalidade'
const descricao = ref('')
const valor = ref(0)
const data = ref(new Date().toISOString().slice(0, 10))
const categoriaDespesa = ref('manutencao')
const tipoReceita = ref('doacao')
const origemReceita = ref('')
const salvando = ref(false)
const erro = ref('')
const inputDescricaoRef = ref(null)

const lancamentosDaSessao = ref([])

// --- Mensalidade / credito antecipado ---
const associadosAtivos = ref([])
const associadoSelecionadoId = ref('')
const mesesAntecipados = ref(1)

async function carregarAssociadosAtivos() {
  const { data: lista } = await supabase.rpc('listar_associados_financeiro')
  associadosAtivos.value = (lista ?? []).filter((a) => a.status !== 'inativo').sort((a, b) => a.nome.localeCompare(b.nome))
}
onMounted(carregarAssociadosAtivos)

async function salvarELimpar() {
  erro.value = ''

  if (movimento.value === 'mensalidade') {
    if (!associadoSelecionadoId.value || !valor.value) {
      erro.value = 'Selecione o associado e informe o valor recebido.'
      return
    }
    salvando.value = true

    const associado = associadosAtivos.value.find((a) => a.id === associadoSelecionadoId.value)
    const desc = descricao.value.trim() || `Adiantamento de mensalidade - ${associado?.nome} (${mesesAntecipados.value} mês(es))`

    // 1) Entra como receita de verdade, recebida agora
    const receitaRes = await supabase.from('financeiro_receitas').insert({
      descricao: desc,
      valor: valor.value,
      tipo: 'mensalidade_adiantada',
      origem_nome: associado?.nome ?? null,
      data: data.value,
    })

    // 2) Vira credito do associado, abatido automaticamente quando as
    // proximas mensalidades forem geradas
    const creditoRes = await supabase.from('associado_creditos_mensalidade').insert({
      associado_id: associadoSelecionadoId.value,
      valor: valor.value,
      tipo: 'credito',
      descricao: desc,
    })

    salvando.value = false

    if (receitaRes.error || creditoRes.error) {
      erro.value = (receitaRes.error || creditoRes.error).message
      return
    }

    lancamentosDaSessao.value.unshift({ tipo: 'mensalidade', descricao: desc, valor: valor.value })

    descricao.value = ''
    valor.value = 0
    associadoSelecionadoId.value = ''
    mesesAntecipados.value = 1
    return
  }

  if (!descricao.value.trim() || !valor.value) {
    erro.value = 'Preencha a descrição e o valor.'
    return
  }
  salvando.value = true

  let resultado
  if (movimento.value === 'despesa') {
    resultado = await supabase.from('financeiro_despesas').insert({
      descricao: descricao.value.trim(),
      valor: valor.value,
      categoria: categoriaDespesa.value,
      data: data.value,
    }).select().single()
  } else {
    resultado = await supabase.from('financeiro_receitas').insert({
      descricao: descricao.value.trim(),
      valor: valor.value,
      tipo: tipoReceita.value,
      origem_nome: origemReceita.value.trim() || null,
      data: data.value,
    }).select().single()
  }

  salvando.value = false

  if (resultado.error) {
    erro.value = resultado.error.message
    return
  }

  lancamentosDaSessao.value.unshift({
    tipo: movimento.value,
    descricao: descricao.value.trim(),
    valor: valor.value,
  })

  // Limpa so o que muda a cada lancamento, mantem o tipo/categoria
  // selecionados (normalmente se lanca varios do mesmo tipo seguidos)
  descricao.value = ''
  valor.value = 0
  origemReceita.value = ''

  await nextTick()
  inputDescricaoRef.value?.focus()
}

function aoApertarEnter(e) {
  // Enter no campo de descricao pula pro valor, nao envia o form
  if (e.target.tagName === 'INPUT' && e.key === 'Enter') {
    e.preventDefault()
  }
}
</script>

<template>
  <div class="mx-auto max-w-lg">
    <div class="rounded-2xl bg-white p-6 shadow-card">
      <div class="flex gap-2">
        <button
          class="flex-1 rounded-full py-2.5 text-xs font-bold transition-colors"
          :class="movimento === 'despesa' ? 'bg-brand text-white' : 'bg-paper-dim text-ink-soft'"
          @click="movimento = 'despesa'"
        >− Despesa</button>
        <button
          class="flex-1 rounded-full py-2.5 text-xs font-bold transition-colors"
          :class="movimento === 'receita' ? 'bg-[#27500A] text-white' : 'bg-paper-dim text-ink-soft'"
          @click="movimento = 'receita'"
        >+ Receita</button>
        <button
          class="flex-1 rounded-full py-2.5 text-xs font-bold transition-colors"
          :class="movimento === 'mensalidade' ? 'bg-gold text-white' : 'bg-paper-dim text-ink-soft'"
          @click="movimento = 'mensalidade'"
        >💳 Mensalidade</button>
      </div>

      <form v-if="movimento === 'mensalidade'" class="mt-5 space-y-3" @submit.prevent="salvarELimpar">
        <div>
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Sócio que pagou</label>
          <select v-model="associadoSelecionadoId" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand">
            <option value="" disabled>Selecione...</option>
            <option v-for="a in associadosAtivos" :key="a.id" :value="a.id">{{ a.nome }} ({{ statusLabel(a.status) }})</option>
          </select>
        </div>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Valor recebido (PIX)</label>
            <CurrencyInput v-model="valor" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-base text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Refere-se a quantos meses</label>
            <input v-model.number="mesesAntecipados" type="number" min="1" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
          </div>
        </div>
        <div>
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Descrição (opcional)</label>
          <input v-model="descricao" type="text" placeholder="Preenchido automaticamente se deixar em branco" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
        </div>
        <div>
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Data</label>
          <input v-model="data" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
        </div>
        <p class="text-[10px] text-ink-soft/70">
          Esse valor entra como receita recebida hoje, e fica guardado como crédito do associado - as próximas
          mensalidades geradas para ele já são marcadas como pagas automaticamente, até o crédito acabar.
        </p>

        <p v-if="erro" class="text-xs text-brand-deep">{{ erro }}</p>

        <button type="submit" :disabled="salvando" class="w-full rounded-full bg-gold py-3.5 font-mono-label text-[12px] font-bold text-white hover:opacity-90 disabled:opacity-50">
          {{ salvando ? 'Salvando...' : 'Salvar e lançar o próximo' }}
        </button>
      </form>

      <form v-else class="mt-5 space-y-3" @keydown="aoApertarEnter" @submit.prevent="salvarELimpar">
        <div>
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Descrição</label>
          <input
            ref="inputDescricaoRef"
            v-model="descricao"
            type="text"
            autofocus
            placeholder="Ex: Conta de luz, mensalidade extra..."
            class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-base text-ink outline-none focus:border-brand"
          />
        </div>

        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Valor</label>
            <CurrencyInput v-model="valor" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-base text-ink outline-none focus:border-brand" />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Data</label>
            <input v-model="data" type="date" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
          </div>
        </div>

        <div v-if="movimento === 'despesa'">
          <label class="font-mono-label text-[9px] font-bold text-ink-soft">Categoria</label>
          <select v-model="categoriaDespesa" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand">
            <option v-for="c in categoriaDespesaOptions" :key="c.value" :value="c.value">{{ c.label }}</option>
          </select>
        </div>
        <template v-else>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Tipo</label>
            <select v-model="tipoReceita" class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand">
              <option v-for="t in tipoReceitaOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">De quem (opcional)</label>
            <input v-model="origemReceita" type="text" placeholder="Nome do doador, patrocinador..." class="mt-1 w-full rounded-xl border border-ink/15 bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand" />
          </div>
        </template>

        <p v-if="erro" class="text-xs text-brand-deep">{{ erro }}</p>

        <button
          type="submit"
          :disabled="salvando"
          class="w-full rounded-full py-3.5 font-mono-label text-[12px] font-bold text-white disabled:opacity-50"
          :class="movimento === 'despesa' ? 'bg-brand hover:bg-brand-deep' : 'bg-[#27500A] hover:opacity-90'"
        >{{ salvando ? 'Salvando...' : 'Salvar e lançar o próximo' }}</button>
      </form>
    </div>

    <!-- Feedback dos lancamentos da sessao -->
    <div v-if="lancamentosDaSessao.length > 0" class="mt-5">
      <p class="font-mono-label text-[10px] font-bold text-ink-soft">LANÇADOS AGORA</p>
      <div class="mt-2 space-y-1.5">
        <div v-for="(l, i) in lancamentosDaSessao" :key="i" class="flex items-center justify-between rounded-xl bg-white px-4 py-2.5 text-sm shadow-card">
          <span class="text-ink-soft">{{ l.descricao }}</span>
          <span class="font-semibold" :class="l.tipo === 'despesa' ? 'text-brand-deep' : l.tipo === 'mensalidade' ? 'text-gold' : 'text-[#27500A]'">
            {{ l.tipo === 'despesa' ? '−' : '+' }} {{ brl(l.valor) }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>
