<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'
import StarRating from './StarRating.vue'
import { brl } from '../../data/campeonatos.js'

// Cadastro centralizado de quadras/ginásios — usado tanto pelo Vôlei
// Master (EsportivoPanel) quanto pelas Categorias de Base
// (BaseCoordenadorPanel), por isso vive como componente próprio,
// embeddable nos dois lugares.
defineProps({
  embedded: { type: Boolean, default: false },
})

const { profile } = useAuth()

const quadras = ref([])
const fotosPorQuadra = ref({}) // quadra_id -> [row]
const carregando = ref(true)

async function carregar() {
  carregando.value = true
  const [{ data: quadrasData }, { data: fotosData }] = await Promise.all([
    supabase.from('quadras').select('*').order('nome'),
    supabase.from('quadra_fotos').select('*').order('criado_em'),
  ])
  quadras.value = quadrasData ?? []
  const mapa = {}
  for (const f of fotosData ?? []) {
    if (!mapa[f.quadra_id]) mapa[f.quadra_id] = []
    mapa[f.quadra_id].push(f)
  }
  fotosPorQuadra.value = mapa
  carregando.value = false
}

onMounted(carregar)

function formQuadraVazio() {
  return {
    nome: '',
    endereco_rua: '', endereco_numero: '', endereco_complemento: '',
    endereco_bairro: '', endereco_cidade: '', endereco_uf: '', endereco_cep: '',
    valor_locacao: null,
    desconto_ativo: false, desconto_descricao: '', desconto_valor: null,
    info_alimentacao: '', info_estacionamento: '', info_banheiros_vestiario: '',
    tem_arquibancada: null, info_arquibancada: '',
    qualidade_estrutura: 0, qualificacao_geral: 0,
    observacoes: '',
  }
}

// --- Cadastro ---
const mostrarForm = ref(false)
const formQuadra = ref(formQuadraVazio())
const salvando = ref(false)

async function salvarQuadra() {
  const f = formQuadra.value
  if (!f.nome.trim()) return
  salvando.value = true
  const { data, error } = await supabase.from('quadras').insert({
    nome: f.nome.trim(),
    endereco_rua: f.endereco_rua.trim() || null, endereco_numero: f.endereco_numero.trim() || null,
    endereco_complemento: f.endereco_complemento.trim() || null, endereco_bairro: f.endereco_bairro.trim() || null,
    endereco_cidade: f.endereco_cidade.trim() || null, endereco_uf: f.endereco_uf.trim() || null,
    endereco_cep: f.endereco_cep.trim() || null,
    valor_locacao: f.valor_locacao || null,
    desconto_ativo: f.desconto_ativo, desconto_descricao: f.desconto_descricao.trim() || null,
    desconto_valor: f.desconto_ativo ? (f.desconto_valor || null) : null,
    info_alimentacao: f.info_alimentacao.trim() || null, info_estacionamento: f.info_estacionamento.trim() || null,
    info_banheiros_vestiario: f.info_banheiros_vestiario.trim() || null,
    tem_arquibancada: f.tem_arquibancada, info_arquibancada: f.info_arquibancada.trim() || null,
    qualidade_estrutura: f.qualidade_estrutura || null, qualificacao_geral: f.qualificacao_geral || null,
    observacoes: f.observacoes.trim() || null,
    criado_por: profile.value?.id ?? null,
  }).select().single()
  salvando.value = false
  if (!error) {
    quadras.value.push(data)
    quadras.value.sort((a, b) => a.nome.localeCompare(b.nome))
    mostrarForm.value = false
    formQuadra.value = formQuadraVazio()
  }
}

// --- Edição ---
const editandoId = ref(null)
const formEdicao = ref(null)

function abrirEdicao(q) {
  editandoId.value = q.id
  formEdicao.value = {
    nome: q.nome,
    endereco_rua: q.endereco_rua ?? '', endereco_numero: q.endereco_numero ?? '', endereco_complemento: q.endereco_complemento ?? '',
    endereco_bairro: q.endereco_bairro ?? '', endereco_cidade: q.endereco_cidade ?? '', endereco_uf: q.endereco_uf ?? '', endereco_cep: q.endereco_cep ?? '',
    valor_locacao: q.valor_locacao,
    desconto_ativo: q.desconto_ativo, desconto_descricao: q.desconto_descricao ?? '', desconto_valor: q.desconto_valor,
    info_alimentacao: q.info_alimentacao ?? '', info_estacionamento: q.info_estacionamento ?? '',
    info_banheiros_vestiario: q.info_banheiros_vestiario ?? '',
    tem_arquibancada: q.tem_arquibancada, info_arquibancada: q.info_arquibancada ?? '',
    qualidade_estrutura: q.qualidade_estrutura ?? 0, qualificacao_geral: q.qualificacao_geral ?? 0,
    observacoes: q.observacoes ?? '',
  }
}

async function salvarEdicao(q) {
  const f = formEdicao.value
  const patch = {
    nome: f.nome.trim(),
    endereco_rua: f.endereco_rua.trim() || null, endereco_numero: f.endereco_numero.trim() || null,
    endereco_complemento: f.endereco_complemento.trim() || null, endereco_bairro: f.endereco_bairro.trim() || null,
    endereco_cidade: f.endereco_cidade.trim() || null, endereco_uf: f.endereco_uf.trim() || null,
    endereco_cep: f.endereco_cep.trim() || null,
    valor_locacao: f.valor_locacao || null,
    desconto_ativo: f.desconto_ativo, desconto_descricao: f.desconto_descricao.trim() || null,
    desconto_valor: f.desconto_ativo ? (f.desconto_valor || null) : null,
    info_alimentacao: f.info_alimentacao.trim() || null, info_estacionamento: f.info_estacionamento.trim() || null,
    info_banheiros_vestiario: f.info_banheiros_vestiario.trim() || null,
    tem_arquibancada: f.tem_arquibancada, info_arquibancada: f.info_arquibancada.trim() || null,
    qualidade_estrutura: f.qualidade_estrutura || null, qualificacao_geral: f.qualificacao_geral || null,
    observacoes: f.observacoes.trim() || null,
  }
  const { error } = await supabase.from('quadras').update(patch).eq('id', q.id)
  if (error) {
    alert('Não foi possível salvar: ' + error.message)
    return
  }
  Object.assign(q, patch)
  editandoId.value = null
}

async function alternarAtivo(q) {
  const { error } = await supabase.from('quadras').update({ ativo: !q.ativo }).eq('id', q.id)
  if (!error) q.ativo = !q.ativo
}

async function excluirQuadra(q) {
  if (!confirm(`Excluir a quadra "${q.nome}"? Só funciona se nenhum evento já tiver usado essa quadra.`)) return
  const fotos = fotosPorQuadra.value[q.id] ?? []
  const { error } = await supabase.from('quadras').delete().eq('id', q.id)
  if (error) {
    alert(error.code === '23503'
      ? 'Não é possível excluir: já existem eventos vinculados a essa quadra. Desative em vez de excluir.'
      : error.message)
    return
  }
  if (fotos.length) await supabase.storage.from('quadras').remove(fotos.map((f) => f.storage_path))
  quadras.value = quadras.value.filter((x) => x.id !== q.id)
}

// --- Fotos ---
const enviandoFoto = ref(null) // quadra_id em envio

async function enviarFotos(q, fileList) {
  const files = Array.from(fileList || [])
  if (!files.length) return
  enviandoFoto.value = q.id
  for (const file of files) {
    const ext = file.name.includes('.') ? file.name.split('.').pop() : 'jpg'
    const nomeArquivo = `${crypto.randomUUID()}.${ext}`
    const caminho = `quadra-${q.id}/${nomeArquivo}`
    const { error: upError } = await supabase.storage.from('quadras').upload(caminho, file, { contentType: file.type })
    if (upError) {
      alert(`Erro ao enviar ${file.name}: ${upError.message}`)
      continue
    }
    const { data: pub } = supabase.storage.from('quadras').getPublicUrl(caminho)
    const { data: foto, error } = await supabase.from('quadra_fotos').insert({
      quadra_id: q.id, url: pub.publicUrl, storage_path: caminho,
    }).select().single()
    if (!error) {
      if (!fotosPorQuadra.value[q.id]) fotosPorQuadra.value[q.id] = []
      fotosPorQuadra.value[q.id].push(foto)
    }
  }
  enviandoFoto.value = null
}

async function excluirFoto(q, foto) {
  if (!confirm('Excluir esta foto?')) return
  await supabase.storage.from('quadras').remove([foto.storage_path])
  await supabase.from('quadra_fotos').delete().eq('id', foto.id)
  fotosPorQuadra.value[q.id] = (fotosPorQuadra.value[q.id] ?? []).filter((f) => f.id !== foto.id)
}

function enderecoResumo(q) {
  const partes = [q.endereco_rua && `${q.endereco_rua}${q.endereco_numero ? ', ' + q.endereco_numero : ''}`, q.endereco_bairro, q.endereco_cidade && q.endereco_uf ? `${q.endereco_cidade}/${q.endereco_uf}` : q.endereco_cidade]
  return partes.filter(Boolean).join(' · ')
}
</script>

<template>
  <div>
    <div v-if="!embedded">
      <p class="font-mono-label text-[11px] font-bold text-brand-deep">Quadras</p>
      <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">Cadastro de Quadras</h1>
    </div>

    <button v-if="!mostrarForm" :class="embedded ? '' : 'mt-6'" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep" @click="mostrarForm = true">+ Nova quadra</button>

    <form v-if="mostrarForm" class="mt-4 space-y-4 rounded-2xl bg-white p-6 shadow-card" @submit.prevent="salvarQuadra">
      <input v-model="formQuadra.nome" placeholder="Nome da quadra/ginásio" required class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />

      <p class="font-mono-label text-[9px] font-bold text-ink-soft pt-1">ENDEREÇO</p>
      <div class="grid gap-3 sm:grid-cols-4">
        <input v-model="formQuadra.endereco_rua" placeholder="Rua" class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
        <input v-model="formQuadra.endereco_numero" placeholder="Número" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formQuadra.endereco_complemento" placeholder="Complemento" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formQuadra.endereco_bairro" placeholder="Bairro" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formQuadra.endereco_cidade" placeholder="Cidade" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formQuadra.endereco_uf" placeholder="UF" maxlength="2" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formQuadra.endereco_cep" placeholder="CEP" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
      </div>

      <p class="font-mono-label text-[9px] font-bold text-ink-soft pt-1">VALOR DE LOCAÇÃO</p>
      <div class="grid gap-3 sm:grid-cols-2">
        <input v-model.number="formQuadra.valor_locacao" type="number" step="0.01" placeholder="Valor da locação (R$)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <label class="flex items-center gap-2 text-xs text-ink">
          <input v-model="formQuadra.desconto_ativo" type="checkbox" class="h-3.5 w-3.5 rounded border-ink/30" />
          Tem desconto momentâneo ativo
        </label>
        <template v-if="formQuadra.desconto_ativo">
          <input v-model="formQuadra.desconto_descricao" placeholder="Descrição do desconto (ex: 20% até dez/2026)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <input v-model.number="formQuadra.desconto_valor" type="number" step="0.01" placeholder="Valor já com desconto (R$)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        </template>
      </div>

      <p class="font-mono-label text-[9px] font-bold text-ink-soft pt-1">ESTRUTURA</p>
      <div class="grid gap-3 sm:grid-cols-2">
        <input v-model="formQuadra.info_alimentacao" placeholder="Alimentação (opcional)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formQuadra.info_estacionamento" placeholder="Estacionamento (opcional)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formQuadra.info_banheiros_vestiario" placeholder="Banheiros / vestiário (opcional)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
        <label class="flex items-center gap-2 text-xs text-ink">
          <input :checked="formQuadra.tem_arquibancada === true" type="checkbox" class="h-3.5 w-3.5 rounded border-ink/30" @change="(e) => formQuadra.tem_arquibancada = e.target.checked" />
          Tem arquibancada
        </label>
        <input v-model="formQuadra.info_arquibancada" placeholder="Detalhe da arquibancada (opcional)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
      </div>

      <div class="grid gap-4 sm:grid-cols-2">
        <div>
          <p class="text-xs text-ink-soft">Qualidade da estrutura/quadra</p>
          <StarRating v-model="formQuadra.qualidade_estrutura" class="mt-1" />
        </div>
        <div>
          <p class="text-xs text-ink-soft">Qualificação geral do local</p>
          <StarRating v-model="formQuadra.qualificacao_geral" class="mt-1" />
        </div>
      </div>

      <textarea v-model="formQuadra.observacoes" placeholder="Observações (opcional)" rows="2" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm"></textarea>

      <div class="flex gap-2">
        <button type="submit" :disabled="salvando" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ salvando ? 'Salvando...' : 'Salvar' }}</button>
        <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="mostrarForm = false">Cancelar</button>
      </div>
    </form>

    <p v-if="carregando" class="mt-6 text-sm text-ink-soft">Carregando...</p>

    <div v-else-if="quadras.length === 0" class="mt-6 rounded-2xl border border-dashed border-ink/15 p-8 text-center">
      <Icon name="calendar" class="mx-auto h-6 w-6 text-ink-soft/50" />
      <p class="mt-2 text-sm text-ink-soft">Nenhuma quadra cadastrada ainda.</p>
    </div>

    <div v-else class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
      <div v-for="q in quadras" :key="q.id" class="px-5 py-4">
        <div class="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p class="text-sm font-semibold text-ink">{{ q.nome }}</p>
            <p v-if="enderecoResumo(q)" class="text-xs text-ink-soft">{{ enderecoResumo(q) }}</p>
            <p class="mt-1 text-xs text-ink-soft">
              <span v-if="q.valor_locacao">{{ brl(q.valor_locacao) }}<span v-if="q.desconto_ativo"> (com desconto: {{ brl(q.desconto_valor) }} — {{ q.desconto_descricao }})</span></span>
              <span v-else>Valor não informado</span>
            </p>
            <div class="mt-1.5 flex flex-wrap items-center gap-3">
              <span v-if="q.qualidade_estrutura" class="flex items-center gap-1 text-xs text-ink-soft">Estrutura <StarRating :model-value="q.qualidade_estrutura" readonly size="h-3 w-3" /></span>
              <span v-if="q.qualificacao_geral" class="flex items-center gap-1 text-xs text-ink-soft">Geral <StarRating :model-value="q.qualificacao_geral" readonly size="h-3 w-3" /></span>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <button class="rounded-full px-3 py-1 text-xs font-semibold" :class="q.ativo ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-ink/8 text-ink-soft'" @click="alternarAtivo(q)">{{ q.ativo ? 'ativa' : 'inativa' }}</button>
            <button class="text-xs font-semibold text-brand-deep hover:underline" @click="editandoId === q.id ? (editandoId = null) : abrirEdicao(q)">{{ editandoId === q.id ? 'Fechar' : 'Editar' }}</button>
            <button class="text-xs font-semibold text-ink-soft hover:text-brand-deep hover:underline" @click="excluirQuadra(q)">Excluir</button>
          </div>
        </div>

        <div class="mt-3 flex items-center justify-between">
          <p v-if="q.info_alimentacao || q.info_estacionamento || q.info_banheiros_vestiario" class="text-xs text-ink-soft">
            <span v-if="q.info_alimentacao">🍽️ {{ q.info_alimentacao }}</span>
            <span v-if="q.info_estacionamento"> · 🅿️ {{ q.info_estacionamento }}</span>
            <span v-if="q.info_banheiros_vestiario"> · 🚿 {{ q.info_banheiros_vestiario }}</span>
            <span v-if="q.tem_arquibancada"> · 🪑 arquibancada{{ q.info_arquibancada ? ` (${q.info_arquibancada})` : '' }}</span>
          </p>
          <label class="ml-auto cursor-pointer text-xs font-semibold text-brand-deep hover:underline">
            <Icon name="camera" class="inline h-3.5 w-3.5 -mt-0.5 mr-1" />{{ enviandoFoto === q.id ? 'Enviando...' : 'Fotos' }}
            <input type="file" accept="image/*" multiple class="hidden" :disabled="enviandoFoto === q.id" @change="(ev) => enviarFotos(q, ev.target.files)" />
          </label>
        </div>

        <div v-if="(fotosPorQuadra[q.id] ?? []).length" class="mt-2 grid grid-cols-4 gap-2 sm:grid-cols-6">
          <div v-for="f in fotosPorQuadra[q.id]" :key="f.id" class="group relative overflow-hidden rounded-lg bg-ink/5">
            <img :src="f.url" class="h-16 w-full object-cover" />
            <button type="button" class="absolute right-1 top-1 hidden rounded-full bg-white/90 px-1.5 py-0.5 text-[9px] font-bold text-brand-deep group-hover:block" @click="excluirFoto(q, f)">remover</button>
          </div>
        </div>

        <form v-if="editandoId === q.id && formEdicao" class="mt-4 space-y-4 rounded-xl bg-paper-dim p-4" @submit.prevent="salvarEdicao(q)">
          <input v-model="formEdicao.nome" required class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
          <div class="grid gap-3 sm:grid-cols-4">
            <input v-model="formEdicao.endereco_rua" placeholder="Rua" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm sm:col-span-2" />
            <input v-model="formEdicao.endereco_numero" placeholder="Número" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.endereco_complemento" placeholder="Complemento" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.endereco_bairro" placeholder="Bairro" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.endereco_cidade" placeholder="Cidade" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.endereco_uf" placeholder="UF" maxlength="2" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.endereco_cep" placeholder="CEP" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
          </div>
          <div class="grid gap-3 sm:grid-cols-2">
            <input v-model.number="formEdicao.valor_locacao" type="number" step="0.01" placeholder="Valor da locação (R$)" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <label class="flex items-center gap-2 text-xs text-ink">
              <input v-model="formEdicao.desconto_ativo" type="checkbox" class="h-3.5 w-3.5 rounded border-ink/30" />
              Tem desconto momentâneo ativo
            </label>
            <template v-if="formEdicao.desconto_ativo">
              <input v-model="formEdicao.desconto_descricao" placeholder="Descrição do desconto" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
              <input v-model.number="formEdicao.desconto_valor" type="number" step="0.01" placeholder="Valor com desconto (R$)" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            </template>
          </div>
          <div class="grid gap-3 sm:grid-cols-2">
            <input v-model="formEdicao.info_alimentacao" placeholder="Alimentação" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.info_estacionamento" placeholder="Estacionamento" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicao.info_banheiros_vestiario" placeholder="Banheiros / vestiário" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm sm:col-span-2" />
            <label class="flex items-center gap-2 text-xs text-ink">
              <input :checked="formEdicao.tem_arquibancada === true" type="checkbox" class="h-3.5 w-3.5 rounded border-ink/30" @change="(e) => formEdicao.tem_arquibancada = e.target.checked" />
              Tem arquibancada
            </label>
            <input v-model="formEdicao.info_arquibancada" placeholder="Detalhe da arquibancada" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
          </div>
          <div class="grid gap-4 sm:grid-cols-2">
            <div>
              <p class="text-xs text-ink-soft">Qualidade da estrutura/quadra</p>
              <StarRating v-model="formEdicao.qualidade_estrutura" class="mt-1" />
            </div>
            <div>
              <p class="text-xs text-ink-soft">Qualificação geral do local</p>
              <StarRating v-model="formEdicao.qualificacao_geral" class="mt-1" />
            </div>
          </div>
          <textarea v-model="formEdicao.observacoes" placeholder="Observações" rows="2" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm"></textarea>
          <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
        </form>
      </div>
    </div>
  </div>
</template>
