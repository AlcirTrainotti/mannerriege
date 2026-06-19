<script setup>
import { ref } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { ufOptions, formatarDataCurta } from '../../data/campeonatos.js'
import CampeonatoEquipe from './CampeonatoEquipe.vue'
import CampeonatoEmprestimos from './CampeonatoEmprestimos.vue'

const props = defineProps({
  campeonato: { type: Object, required: true },
})
const emit = defineEmits(['voltar'])

const subaba = ref('equipe')
const editando = ref(false)
const salvando = ref(false)

const form = ref({ ...props.campeonato })

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
    observacoes: form.value.observacoes,
  }).eq('id', props.campeonato.id)
  salvando.value = false
  if (!error) {
    Object.assign(props.campeonato, form.value)
    editando.value = false
  }
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

    <!-- Sub-abas -->
    <div class="mt-6 flex gap-2">
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'equipe' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'equipe'"
      >Categorias e Equipe</button>
      <button
        class="rounded-full px-4 py-2 text-xs font-semibold transition-colors"
        :class="subaba === 'emprestimos' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'"
        @click="subaba = 'emprestimos'"
      >Empréstimos</button>
    </div>

    <div class="mt-6">
      <CampeonatoEquipe v-if="subaba === 'equipe'" :campeonato="campeonato" />
      <CampeonatoEmprestimos v-else :campeonato="campeonato" />
    </div>
  </div>
</template>
