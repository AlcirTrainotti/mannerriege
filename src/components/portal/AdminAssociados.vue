<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { calcularCategoria } from '../../lib/categoria.js'
import { modalidadeOptions, roleOptions, statusOptions } from '../../data/portal.js'

const associados = ref([])
const loadingList = ref(true)
const loadError = ref('')
const busca = ref('')
const savingId = ref(null)
const savedId = ref(null)

async function carregar() {
  loadingList.value = true
  loadError.value = ''
  const { data, error } = await supabase.from('profiles').select('*').order('nome')
  if (error) {
    loadError.value = error.message
  } else {
    associados.value = data
  }
  loadingList.value = false
}

onMounted(carregar)

const filtrados = computed(() => {
  const termo = busca.value.trim().toLowerCase()
  if (!termo) return associados.value
  return associados.value.filter((a) =>
    a.nome.toLowerCase().includes(termo) ||
    a.email.toLowerCase().includes(termo) ||
    (a.cpf ?? '').includes(termo)
  )
})

const resumoModalidade = computed(() => {
  const r = { volei: 0, volei_domino: 0, domino: 0 }
  associados.value.forEach((a) => { if (r[a.modalidade] !== undefined) r[a.modalidade]++ })
  return r
})

const resumoStatus = computed(() => {
  const r = { adimplente: 0, inadimplente: 0, inativo: 0 }
  associados.value.forEach((a) => { if (r[a.status] !== undefined) r[a.status]++ })
  return r
})

async function salvarCampo(associado, campo, valor) {
  savingId.value = associado.id + campo
  const { error } = await supabase.from('profiles').update({ [campo]: valor }).eq('id', associado.id)
  savingId.value = null
  if (error) {
    loadError.value = 'Não foi possível salvar: ' + error.message
    return
  }
  savedId.value = associado.id + campo
  setTimeout(() => { if (savedId.value === associado.id + campo) savedId.value = null }, 1500)
}

function statusClasses(status) {
  if (status === 'adimplente') return 'bg-[#EAF3DE] text-[#27500A]'
  if (status === 'inadimplente') return 'bg-brand-soft text-brand-deep'
  return 'bg-ink/8 text-ink-soft'
}
</script>

<template>
  <div>
    <div class="grid gap-4 sm:grid-cols-3 lg:grid-cols-6">
      <div class="rounded-2xl bg-paper-dim p-5">
        <p class="font-mono-label text-[10px] font-bold text-ink-soft">Total</p>
        <p class="mt-1 font-display text-3xl font-extrabold text-ink">{{ associados.length }}</p>
      </div>
      <div class="rounded-2xl bg-paper-dim p-5">
        <p class="font-mono-label text-[10px] font-bold text-ink-soft">Adimplentes</p>
        <p class="mt-1 font-display text-3xl font-extrabold text-ink">{{ resumoStatus.adimplente }}</p>
      </div>
      <div class="rounded-2xl bg-paper-dim p-5">
        <p class="font-mono-label text-[10px] font-bold text-ink-soft">Inadimplentes</p>
        <p class="mt-1 font-display text-3xl font-extrabold text-ink">{{ resumoStatus.inadimplente }}</p>
      </div>
      <div class="rounded-2xl bg-paper-dim p-5">
        <p class="font-mono-label text-[10px] font-bold text-ink-soft">Inativos</p>
        <p class="mt-1 font-display text-3xl font-extrabold text-ink">{{ resumoStatus.inativo }}</p>
      </div>
      <div class="rounded-2xl bg-paper-dim p-5">
        <p class="font-mono-label text-[10px] font-bold text-ink-soft">Vôlei</p>
        <p class="mt-1 font-display text-3xl font-extrabold text-ink">{{ resumoModalidade.volei }}</p>
      </div>
      <div class="rounded-2xl bg-paper-dim p-5">
        <p class="font-mono-label text-[10px] font-bold text-ink-soft">Dominó (+Vôlei ou só)</p>
        <p class="mt-1 font-display text-3xl font-extrabold text-ink">{{ resumoModalidade.volei_domino + resumoModalidade.domino }}</p>
      </div>
    </div>

    <div class="mt-8 flex items-center justify-between gap-4">
      <input
        v-model="busca"
        type="text"
        placeholder="Buscar por nome, e-mail ou CPF..."
        class="w-full max-w-sm rounded-xl border border-ink/15 bg-white px-4 py-2.5 text-sm text-ink outline-none focus:border-brand"
      />
      <span class="hidden text-xs text-ink-soft sm:inline">{{ filtrados.length }} associado(s)</span>
    </div>

    <p v-if="loadError" class="mt-4 text-sm text-brand-deep">{{ loadError }}</p>
    <p v-if="loadingList" class="mt-6 text-sm text-ink-soft">Carregando associados...</p>

    <div v-else class="mt-5 space-y-3">
      <div v-if="filtrados.length === 0" class="py-8 text-center text-sm text-ink-soft">Nenhum associado encontrado.</div>

      <div v-for="a in filtrados" :key="a.id" class="rounded-2xl bg-white p-5 shadow-card">
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div class="min-w-[200px] flex-1">
            <input
              :value="a.nome"
              type="text"
              class="w-full rounded-lg border border-transparent bg-transparent px-0 py-0.5 text-sm font-semibold text-ink outline-none hover:border-ink/15 focus:border-brand focus:bg-paper-dim focus:px-2"
              @change="(e) => { a.nome = e.target.value; salvarCampo(a, 'nome', e.target.value) }"
            />
            <p class="text-xs text-ink-soft">{{ a.email }}</p>
          </div>
          <div class="flex items-center gap-2">
            <span :class="['rounded-full px-3 py-1 text-xs font-semibold', statusClasses(a.status)]">{{ a.status }}</span>
            <span v-if="savingId?.startsWith(a.id)" class="text-xs text-ink-soft/60">salvando...</span>
            <span v-else-if="savedId?.startsWith(a.id)" class="text-xs text-brand-deep">salvo</span>
          </div>
        </div>

        <div class="mt-4 grid gap-3 sm:grid-cols-3 lg:grid-cols-6">
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">CPF</label>
            <input
              :value="a.cpf"
              type="text"
              placeholder="000.000.000-00"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.cpf = e.target.value; salvarCampo(a, 'cpf', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Nascimento</label>
            <input
              :value="a.data_nascimento"
              type="date"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.data_nascimento = e.target.value; salvarCampo(a, 'data_nascimento', e.target.value) }"
            />
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Categoria</label>
            <p class="mt-1 rounded-lg bg-paper-dim px-3 py-2 text-xs font-semibold text-ink">
              {{ calcularCategoria(a.data_nascimento) || 'preencha o nascimento' }}
            </p>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Modalidade</label>
            <select
              :value="a.modalidade"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.modalidade = e.target.value; salvarCampo(a, 'modalidade', e.target.value) }"
            >
              <option v-for="m in modalidadeOptions" :key="m.value" :value="m.value">{{ m.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Status</label>
            <select
              :value="a.status"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.status = e.target.value; salvarCampo(a, 'status', e.target.value) }"
            >
              <option v-for="s in statusOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
            </select>
          </div>
          <div>
            <label class="font-mono-label text-[9px] font-bold text-ink-soft">Papel</label>
            <select
              :value="a.role"
              class="mt-1 w-full rounded-lg border border-ink/15 bg-white px-2 py-2 text-xs text-ink outline-none focus:border-brand"
              @change="(e) => { a.role = e.target.value; salvarCampo(a, 'role', e.target.value) }"
            >
              <option v-for="r in roleOptions" :key="r.value" :value="r.value">{{ r.label }}</option>
            </select>
          </div>
        </div>
      </div>
    </div>

    <p class="mt-8 text-xs text-ink-soft/70">
      Para cadastrar um novo associado: crie o login em Supabase → Authentication → Users, e ele
      aparecerá automaticamente nesta lista para você preencher os dados.
    </p>
  </div>
</template>
