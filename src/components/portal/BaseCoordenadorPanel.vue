<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { createClient } from '@supabase/supabase-js'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../lib/useAuth.js'
import Icon from '../Icon.vue'
import { brl } from '../../data/campeonatos.js'
import { formatarDataCurta } from '../../data/campeonatos.js'
import {
  idadeAtual, nomeCategoria, sexoOptions, sexoLabel,
  statusAtletaOptions, statusAtletaLabel, statusAtletaClasses,
  posicaoOptions, posicaoLabel, categoriaPorNascimento,
  tipoEventoOptions, tipoEventoLabel, formatarHora,
  vinculoAtletaOptions, vinculoAtletaLabel,
} from '../../data/base.js'

const props = defineProps({
  // Quando embedded=true, não mostra o cabeçalho próprio (título +
  // sair), pois já está dentro do AdminPanel.
  embedded: { type: Boolean, default: false },
})

const { profile, logout } = useAuth()
const aba = ref('atletas')

// ================================================================
// Dados compartilhados entre as abas
// ================================================================
const carregando = ref(true)
const atletas = ref([])
const categorias = ref([])
const planos = ref([])
const contatosPorAtleta = ref({}) // atleta_id -> [{ responsavel_nome, telefone, email, parentesco }]

async function carregarTudo() {
  carregando.value = true
  const [{ data: atletasData }, { data: categoriasData }, { data: planosData }, { data: contatosData }] = await Promise.all([
    supabase.from('atletas_base').select('*').order('nome'),
    supabase.from('categorias_base').select('*').order('nome'),
    supabase.from('planos_base').select('*').order('ordem'),
    supabase.rpc('listar_contatos_responsaveis_base'),
  ])
  atletas.value = atletasData ?? []
  categorias.value = categoriasData ?? []
  planos.value = planosData ?? []

  const mapa = {}
  for (const c of contatosData ?? []) {
    if (!mapa[c.atleta_id]) mapa[c.atleta_id] = []
    mapa[c.atleta_id].push(c)
  }
  contatosPorAtleta.value = mapa

  carregando.value = false
}

function categoriaDoAtleta(atleta) {
  return categorias.value.find((c) => c.id === atleta.categoria_id)
}

function contatosDoAtleta(atleta) {
  return contatosPorAtleta.value[atleta.id] ?? []
}

onMounted(carregarTudo)

// ================================================================
// Aba Atletas — filtros
// ================================================================
const filtroCategoria = ref('todas')
const filtroStatus = ref('todos')
const filtroSexo = ref('todos')
const filtroBusca = ref('')

const atletasFiltrados = computed(() => {
  return atletas.value.filter((a) => {
    if (filtroCategoria.value !== 'todas' && a.categoria_id !== filtroCategoria.value) return false
    if (filtroStatus.value !== 'todos' && a.status !== filtroStatus.value) return false
    if (filtroSexo.value !== 'todos' && a.sexo !== filtroSexo.value) return false
    if (filtroBusca.value.trim() && !a.nome.toLowerCase().includes(filtroBusca.value.trim().toLowerCase())) return false
    return true
  })
})

// ================================================================
// Aba Atletas — cadastro (atleta + vínculo com responsável)
// ================================================================
const mostrarFormAtleta = ref(false)
const salvandoAtleta = ref(false)
const erroAtleta = ref('')
const inscricoesAtivas = ref([])
const respBuscando = ref(false)
const respEncontrado = ref(null) // { id, nome, telefone, email } quando já existe

function formAtletaVazio() {
  return {
    nome: '', data_nascimento: '', sexo: 'masculino', categoria_id: '', escola: '', posicao: '',
    inscricaoId: '',
    parentesco: 'mãe/pai',
    respNome: '', respTelefone: '', respEmail: '', respSenha: '',
    vinculo: 'projeto',
    eventosSelecionados: [],
  }
}
const formAtleta = ref(formAtletaVazio())

async function abrirFormAtleta() {
  erroAtleta.value = ''
  respEncontrado.value = null
  formAtleta.value = formAtletaVazio()
  mostrarFormAtleta.value = true
  const [{ data }] = await Promise.all([
    supabase.rpc('listar_inscricoes_experiencia_ativas'),
    carregarEventos(),
  ])
  inscricoesAtivas.value = data ?? []
}

// Sugere a categoria automaticamente sempre que a data de nascimento ou
// o sexo mudam — a coordenação ainda pode trocar manualmente depois.
watch([() => formAtleta.value.data_nascimento, () => formAtleta.value.sexo], () => {
  const sugestao = categoriaPorNascimento(formAtleta.value.data_nascimento, formAtleta.value.sexo, categorias.value)
  if (sugestao) formAtleta.value.categoria_id = sugestao
})

function preencherComInscricao() {
  const insc = inscricoesAtivas.value.find((i) => i.id === formAtleta.value.inscricaoId)
  if (!insc) return
  formAtleta.value.nome = insc.atleta_nome
  formAtleta.value.data_nascimento = insc.atleta_data_nascimento
  formAtleta.value.sexo = insc.turma
  formAtleta.value.respNome = insc.responsavel_nome
  formAtleta.value.respTelefone = insc.responsavel_whatsapp
  formAtleta.value.respEmail = insc.responsavel_email
  buscarResponsavelExistente()
}

// Verifica se já existe um responsável cadastrado com esse telefone/e-mail,
// pra reaproveitar o cadastro em vez de criar um login duplicado (comum
// quando dois irmãos entram no projeto).
async function buscarResponsavelExistente() {
  const telefone = formAtleta.value.respTelefone.trim()
  const email = formAtleta.value.respEmail.trim()
  if (!telefone && !email) {
    respEncontrado.value = null
    return
  }
  respBuscando.value = true
  const { data } = await supabase.rpc('buscar_responsavel_base', { p_telefone: telefone || null, p_email: email || null })
  respBuscando.value = false
  const encontrado = Array.isArray(data) ? data[0] : data
  if (encontrado) {
    respEncontrado.value = encontrado
    formAtleta.value.respNome = encontrado.nome
  } else {
    respEncontrado.value = null
  }
}

async function salvarAtleta() {
  erroAtleta.value = ''
  const f = formAtleta.value

  if (!f.nome.trim() || !f.data_nascimento || !f.categoria_id) {
    erroAtleta.value = 'Preencha nome, data de nascimento e categoria.'
    return
  }
  if (!respEncontrado.value && (!f.respNome.trim() || !f.respTelefone.trim() || !f.respSenha.trim())) {
    erroAtleta.value = 'Preencha nome, telefone e senha do responsável.'
    return
  }

  salvandoAtleta.value = true

  // 1. Cria o registro do atleta
  const { data: novoAtleta, error: atletaError } = await supabase
    .from('atletas_base')
    .insert({
      nome: f.nome.trim(), data_nascimento: f.data_nascimento, sexo: f.sexo,
      categoria_id: f.categoria_id, escola: f.escola.trim() || null,
      posicao: f.posicao || null,
      inscricao_experiencia_id: f.inscricaoId || null,
      vinculo: f.vinculo,
    })
    .select()
    .single()

  if (atletaError) {
    erroAtleta.value = atletaError.message
    salvandoAtleta.value = false
    return
  }

  // 2. Resolve o responsável (reaproveita um já cadastrado, ou cria um novo)
  let responsavelId = respEncontrado.value?.id

  if (!responsavelId) {
    const url = import.meta.env.VITE_SUPABASE_URL
    const key = import.meta.env.VITE_SUPABASE_ANON_KEY
    const clienteTemp = createClient(url, key, { auth: { storageKey: 'signup-temp-responsavel' } })

    const emailParaLogin = f.respEmail.trim() || `${f.respTelefone.replace(/\D/g, '')}@sememail.mannerriege.com.br`
    const { data, error: signupError } = await clienteTemp.auth.signUp({
      email: emailParaLogin,
      password: f.respSenha,
      options: { data: { nome: f.respNome.trim() } },
    })

    if (signupError || !data.user) {
      erroAtleta.value = signupError?.message ?? 'Erro ao cadastrar o responsável.'
      salvandoAtleta.value = false
      return
    }
    await clienteTemp.auth.signOut()

    await new Promise((r) => setTimeout(r, 800)) // aguarda o trigger criar o profile
    await supabase.from('profiles').update({ telefone: f.respTelefone.trim() }).eq('id', data.user.id)
    const { error: roleError } = await supabase.rpc('definir_role_responsavel_base', { p_profile_id: data.user.id })
    if (roleError) {
      erroAtleta.value = roleError.message
      salvandoAtleta.value = false
      return
    }
    responsavelId = data.user.id
  }

  // 3. Vincula atleta e responsável
  const { error: vinculoError } = await supabase
    .from('atleta_responsaveis')
    .insert({ atleta_id: novoAtleta.id, responsavel_id: responsavelId, parentesco: f.parentesco || null })

  if (vinculoError) {
    erroAtleta.value = `Atleta criado, mas não consegui vincular o responsável: ${vinculoError.message}`
    salvandoAtleta.value = false
    return
  }

  // 4. Se veio de uma inscrição da Experiência, fecha o ciclo marcando como matrícula
  if (f.inscricaoId) {
    await supabase.from('inscricoes_experiencia_base').update({ status: 'matricula' }).eq('id', f.inscricaoId)
  }

  // 5. Vincula aos eventos selecionados (se houver)
  if (f.eventosSelecionados.length) {
    await supabase.from('evento_participantes_base').insert(
      f.eventosSelecionados.map((eventoId) => ({ evento_id: eventoId, atleta_id: novoAtleta.id }))
    )
  }

  // 6. Atualiza os contatos locais pra já aparecer na lista sem precisar recarregar
  const nomeResp = respEncontrado.value?.nome ?? f.respNome.trim()
  const telResp = respEncontrado.value?.telefone ?? f.respTelefone.trim()
  const emailResp = respEncontrado.value?.email ?? (f.respEmail.trim() || null)
  contatosPorAtleta.value[novoAtleta.id] = [{
    atleta_id: novoAtleta.id, responsavel_id: responsavelId,
    responsavel_nome: nomeResp, telefone: telResp, email: emailResp, parentesco: f.parentesco || null,
  }]

  salvandoAtleta.value = false
  atletas.value.push(novoAtleta)
  mostrarFormAtleta.value = false
  formAtleta.value = formAtletaVazio()
  respEncontrado.value = null
}

// ================================================================
// Aba Atletas — editar cadastro completo de um atleta existente
// ================================================================
const editandoAtletaId = ref(null)
const formEdicaoAtleta = ref(null)
const salvandoEdicaoAtleta = ref(false)

function abrirEdicaoAtleta(atleta) {
  editandoAtletaId.value = atleta.id
  formEdicaoAtleta.value = {
    nome: atleta.nome, data_nascimento: atleta.data_nascimento, sexo: atleta.sexo,
    escola: atleta.escola ?? '', posicao: atleta.posicao ?? '',
    categoria_id: atleta.categoria_id, status: atleta.status,
    observacoes_gerais: atleta.observacoes_gerais ?? '',
    contatos: contatosDoAtleta(atleta).map((c) => ({
      responsavel_id: c.responsavel_id,
      nome: c.responsavel_nome ?? '', telefone: c.telefone ?? '', email: c.email ?? '', parentesco: c.parentesco ?? '',
    })),
  }
}

watch(() => formEdicaoAtleta.value?.data_nascimento, () => {
  if (!formEdicaoAtleta.value) return
  const sugestao = categoriaPorNascimento(formEdicaoAtleta.value.data_nascimento, formEdicaoAtleta.value.sexo, categorias.value)
  if (sugestao) formEdicaoAtleta.value.categoria_id = sugestao
})

async function salvarEdicaoAtleta(atleta) {
  salvandoEdicaoAtleta.value = true
  const f = formEdicaoAtleta.value
  const { error } = await supabase.from('atletas_base').update({
    nome: f.nome.trim(), data_nascimento: f.data_nascimento, sexo: f.sexo,
    escola: f.escola.trim() || null, posicao: f.posicao || null,
    categoria_id: f.categoria_id, status: f.status,
    observacoes_gerais: f.observacoes_gerais.trim() || null,
  }).eq('id', atleta.id)
  if (error) {
    salvandoEdicaoAtleta.value = false
    alert('Não foi possível salvar: ' + error.message)
    return
  }
  Object.assign(atleta, {
    nome: f.nome.trim(), data_nascimento: f.data_nascimento, sexo: f.sexo,
    escola: f.escola.trim() || null, posicao: f.posicao || null,
    categoria_id: f.categoria_id, status: f.status,
    observacoes_gerais: f.observacoes_gerais.trim() || null,
  })

  // Atualiza o(s) contato(s) do(s) responsável(is), se houver
  for (const c of f.contatos) {
    const { error: contatoError } = await supabase.rpc('atualizar_contato_responsavel_base', {
      p_atleta_id: atleta.id, p_responsavel_id: c.responsavel_id,
      p_nome: c.nome, p_telefone: c.telefone, p_email: c.email, p_parentesco: c.parentesco,
    })
    if (contatoError) {
      alert(`Dados do atleta salvos, mas não consegui atualizar o contato de ${c.nome}: ${contatoError.message}`)
    }
  }
  contatosPorAtleta.value[atleta.id] = f.contatos.map((c) => ({
    atleta_id: atleta.id, responsavel_id: c.responsavel_id,
    responsavel_nome: c.nome.trim() || c.nome, telefone: c.telefone.trim() || null, email: c.email.trim() || null,
    parentesco: c.parentesco.trim() || null,
  }))

  salvandoEdicaoAtleta.value = false
  editandoAtletaId.value = null
}

// ================================================================
// Aba Atletas — promover um atleta "somente evento" a "atleta do
// projeto" (mensalista), atribuindo um plano vigente
// ================================================================
const promovendoAtletaId = ref(null)
const planoPromocao = ref('')

function abrirPromocao(atleta) {
  promovendoAtletaId.value = atleta.id
  planoPromocao.value = planos.value.find((p) => p.padrao)?.id ?? planos.value[0]?.id ?? ''
}

async function confirmarPromocao(atleta) {
  if (!planoPromocao.value) return
  const { error: e1 } = await supabase.from('atletas_base').update({ vinculo: 'projeto' }).eq('id', atleta.id)
  if (e1) {
    alert('Não foi possível promover: ' + e1.message)
    return
  }
  const { error: e2 } = await supabase.from('atleta_plano').insert({ atleta_id: atleta.id, plano_id: planoPromocao.value })
  if (e2) {
    alert('Vínculo atualizado, mas não consegui atribuir o plano: ' + e2.message)
  }
  atleta.vinculo = 'projeto'
  promovendoAtletaId.value = null
}

// ================================================================
// Aba Categorias
// ================================================================
const mostrarFormCategoria = ref(false)
const formCategoria = ref({ nome: '', sexo: 'masculino', data_corte_min: '', data_corte_max: '' })

async function salvarCategoria() {
  const f = formCategoria.value
  if (!f.nome.trim()) return
  const { data, error } = await supabase.from('categorias_base').insert({
    nome: f.nome.trim(), sexo: f.sexo,
    data_corte_min: f.data_corte_min || null, data_corte_max: f.data_corte_max || null,
  }).select().single()
  if (!error) {
    categorias.value.push(data)
    mostrarFormCategoria.value = false
    formCategoria.value = { nome: '', sexo: 'masculino', data_corte_min: '', data_corte_max: '' }
  }
}

async function alternarAtivoCategoria(categoria) {
  const { error } = await supabase.from('categorias_base').update({ ativo: !categoria.ativo }).eq('id', categoria.id)
  if (!error) categoria.ativo = !categoria.ativo
}

const editandoCategoriaId = ref(null)
const formEdicaoCategoria = ref(null)

function abrirEdicaoCategoria(categoria) {
  editandoCategoriaId.value = categoria.id
  formEdicaoCategoria.value = {
    nome: categoria.nome, sexo: categoria.sexo,
    data_corte_min: categoria.data_corte_min ?? '', data_corte_max: categoria.data_corte_max ?? '',
  }
}

async function salvarEdicaoCategoria(categoria) {
  const f = formEdicaoCategoria.value
  const { error } = await supabase.from('categorias_base').update({
    nome: f.nome.trim(), sexo: f.sexo,
    data_corte_min: f.data_corte_min || null, data_corte_max: f.data_corte_max || null,
  }).eq('id', categoria.id)
  if (error) {
    alert('Não foi possível salvar: ' + error.message)
    return
  }
  Object.assign(categoria, { nome: f.nome.trim(), sexo: f.sexo, data_corte_min: f.data_corte_min || null, data_corte_max: f.data_corte_max || null })
  editandoCategoriaId.value = null
}

async function excluirCategoria(categoria) {
  if (!confirm(`Excluir a categoria "${nomeCategoria(categoria)}"? Só funciona se não houver nenhum atleta cadastrado nela.`)) return
  const { error } = await supabase.from('categorias_base').delete().eq('id', categoria.id)
  if (error) {
    alert(error.code === '23503'
      ? 'Não é possível excluir: existem atletas cadastrados nessa categoria. Mude-os de categoria primeiro, ou apenas desative esta categoria.'
      : error.message)
    return
  }
  categorias.value = categorias.value.filter((c) => c.id !== categoria.id)
}

// ================================================================
// Aba Planos
// ================================================================
const mostrarFormPlano = ref(false)
const formPlano = ref({ nome: '', valor_mensal: 0, descricao: '' })

async function salvarPlano() {
  const f = formPlano.value
  if (!f.nome.trim()) return
  const { data, error } = await supabase.from('planos_base').insert({
    nome: f.nome.trim(), valor_mensal: f.valor_mensal || 0, descricao: f.descricao.trim() || null,
    ordem: planos.value.length + 1,
  }).select().single()
  if (!error) {
    planos.value.push(data)
    mostrarFormPlano.value = false
    formPlano.value = { nome: '', valor_mensal: 0, descricao: '' }
  }
}

async function definirPlanoPadrao(plano) {
  // Só um plano padrão por vez (índice único no banco) — desmarca o
  // atual antes de marcar o novo.
  await supabase.from('planos_base').update({ padrao: false }).eq('padrao', true)
  const { error } = await supabase.from('planos_base').update({ padrao: true }).eq('id', plano.id)
  if (!error) {
    planos.value.forEach((p) => { p.padrao = p.id === plano.id })
  }
}

async function alternarAtivoPlano(plano) {
  const { error } = await supabase.from('planos_base').update({ ativo: !plano.ativo }).eq('id', plano.id)
  if (!error) plano.ativo = !plano.ativo
}

const editandoPlanoId = ref(null)
const formEdicaoPlano = ref(null)

function abrirEdicaoPlano(plano) {
  editandoPlanoId.value = plano.id
  formEdicaoPlano.value = { nome: plano.nome, valor_mensal: plano.valor_mensal, descricao: plano.descricao ?? '' }
}

async function salvarEdicaoPlano(plano) {
  const f = formEdicaoPlano.value
  const { error } = await supabase.from('planos_base').update({
    nome: f.nome.trim(), valor_mensal: f.valor_mensal || 0, descricao: f.descricao.trim() || null,
  }).eq('id', plano.id)
  if (error) {
    alert('Não foi possível salvar: ' + error.message)
    return
  }
  Object.assign(plano, { nome: f.nome.trim(), valor_mensal: f.valor_mensal || 0, descricao: f.descricao.trim() || null })
  editandoPlanoId.value = null
}

async function excluirPlano(plano) {
  if (!confirm(`Excluir o plano "${plano.nome}"? Só funciona se nenhum atleta já tiver usado esse plano.`)) return
  const { error } = await supabase.from('planos_base').delete().eq('id', plano.id)
  if (error) {
    alert(error.code === '23503'
      ? 'Não é possível excluir: existem atletas vinculados a esse plano (atual ou histórico). Desative o plano em vez de excluir.'
      : error.message)
    return
  }
  planos.value = planos.value.filter((p) => p.id !== plano.id)
}

// ================================================================
// Aba Eventos
// ================================================================
const eventos = ref([])
const eventosCarregados = ref(false)
const mostrarFormEvento = ref(false)
const filtroEventoCategoria = ref('todas')
const formEvento = ref({ categoria_id: '', tipo: 'treino', titulo: '', data: '', hora_inicio: '', hora_fim: '', local: '', plano_id: '', plano_atividades: '', observacoes: '' })

function planoDoEvento(evento) {
  return planos.value.find((p) => p.id === evento.plano_id)
}

async function carregarEventos() {
  if (eventosCarregados.value) return
  const { data } = await supabase.from('eventos_base').select('*').order('data', { ascending: false })
  eventos.value = data ?? []
  eventosCarregados.value = true
}

const eventosFiltrados = computed(() => {
  if (filtroEventoCategoria.value === 'todas') return eventos.value
  return eventos.value.filter((e) => e.categoria_id === filtroEventoCategoria.value)
})

async function salvarEvento() {
  const f = formEvento.value
  if (!f.titulo.trim() || !f.data) return
  const { data, error } = await supabase.from('eventos_base').insert({
    categoria_id: f.categoria_id || null, tipo: f.tipo, titulo: f.titulo.trim(),
    data: f.data, hora_inicio: f.hora_inicio || null, hora_fim: f.hora_fim || null,
    local: f.local.trim() || null, plano_id: f.plano_id || null, plano_atividades: f.plano_atividades.trim() || null,
    observacoes: f.observacoes.trim() || null, criado_por: profile.value.id,
  }).select().single()
  if (!error) {
    eventos.value.unshift(data)
    mostrarFormEvento.value = false
    formEvento.value = { categoria_id: '', tipo: 'treino', titulo: '', data: '', hora_inicio: '', hora_fim: '', local: '', plano_id: '', plano_atividades: '', observacoes: '' }
  }
}

const editandoEventoId = ref(null)
const formEdicaoEvento = ref(null)

function abrirEdicaoEvento(evento) {
  editandoEventoId.value = evento.id
  formEdicaoEvento.value = {
    categoria_id: evento.categoria_id ?? '', tipo: evento.tipo, titulo: evento.titulo,
    data: evento.data, hora_inicio: evento.hora_inicio ?? '', hora_fim: evento.hora_fim ?? '',
    local: evento.local ?? '', plano_id: evento.plano_id ?? '',
    plano_atividades: evento.plano_atividades ?? '', observacoes: evento.observacoes ?? '',
  }
}

async function salvarEdicaoEvento(evento) {
  const f = formEdicaoEvento.value
  if (!f.titulo.trim() || !f.data) return
  const patch = {
    categoria_id: f.categoria_id || null, tipo: f.tipo, titulo: f.titulo.trim(),
    data: f.data, hora_inicio: f.hora_inicio || null, hora_fim: f.hora_fim || null,
    local: f.local.trim() || null, plano_id: f.plano_id || null,
    plano_atividades: f.plano_atividades.trim() || null, observacoes: f.observacoes.trim() || null,
  }
  const { error } = await supabase.from('eventos_base').update(patch).eq('id', evento.id)
  if (error) {
    alert('Não foi possível salvar: ' + error.message)
    return
  }
  Object.assign(evento, patch)
  editandoEventoId.value = null
}

const eventoExpandidoId = ref(null)
const participantesPorEvento = ref({}) // evento_id -> { atleta_id -> row }
const midiasPorEvento = ref({}) // evento_id -> [row]
const enviandoMidia = ref(false)

// A lista de chamada de um evento é a categoria dele (conveniência, pra
// treino de categoria fechada não precisar adicionar um por um) somada a
// qualquer atleta explicitamente adicionado ao evento (evento_participantes_base) —
// útil pra convidados de outra categoria, ou eventos sem categoria fixa.
function atletasDoEvento(evento) {
  const daCategoria = evento.categoria_id ? atletas.value.filter((a) => a.categoria_id === evento.categoria_id) : atletas.value
  const idsExtras = Object.keys(participantesPorEvento.value[evento.id] ?? {})
  const idsDaCategoria = new Set(daCategoria.map((a) => a.id))
  const extras = atletas.value.filter((a) => idsExtras.includes(a.id) && !idsDaCategoria.has(a.id))
  return [...daCategoria, ...extras]
}

function atletasForaDoEvento(evento) {
  const idsNoEvento = new Set(atletasDoEvento(evento).map((a) => a.id))
  return atletas.value.filter((a) => !idsNoEvento.has(a.id))
}

async function adicionarAtletaAoEvento(evento, atletaId) {
  if (!atletaId) return
  await salvarParticipante(evento, atletaId, {})
}

// Cadastrar um atleta novo direto a partir do evento — troca pra aba
// Atletas, abre o formulário de cadastro já com este evento marcado.
async function irParaCadastroNovoAtleta(evento) {
  aba.value = 'atletas'
  await abrirFormAtleta()
  formAtleta.value.eventosSelecionados = [evento.id]
}

async function abrirEvento(evento) {
  if (eventoExpandidoId.value === evento.id) {
    eventoExpandidoId.value = null
    return
  }
  eventoExpandidoId.value = evento.id
  if (!participantesPorEvento.value[evento.id]) {
    const [{ data: participantesData }, { data: midiasData }] = await Promise.all([
      supabase.from('evento_participantes_base').select('*').eq('evento_id', evento.id),
      supabase.from('evento_midias_base').select('*').eq('evento_id', evento.id).order('criado_em'),
    ])
    const mapa = {}
    for (const p of participantesData ?? []) mapa[p.atleta_id] = p
    participantesPorEvento.value[evento.id] = mapa
    midiasPorEvento.value[evento.id] = midiasData ?? []
  }
}

function participanteDoAtleta(evento, atletaId) {
  return participantesPorEvento.value[evento.id]?.[atletaId] ?? { presente: null, desempenho_nota: null, desempenho_obs: '' }
}

async function salvarParticipante(evento, atletaId, patch) {
  const atual = participanteDoAtleta(evento, atletaId)
  const linha = {
    evento_id: evento.id, atleta_id: atletaId,
    presente: patch.presente !== undefined ? patch.presente : atual.presente,
    desempenho_nota: patch.desempenho_nota !== undefined ? patch.desempenho_nota : atual.desempenho_nota,
    desempenho_obs: patch.desempenho_obs !== undefined ? patch.desempenho_obs : atual.desempenho_obs,
    atualizado_em: new Date().toISOString(),
  }
  const { data, error } = await supabase
    .from('evento_participantes_base')
    .upsert(linha, { onConflict: 'evento_id,atleta_id' })
    .select()
    .single()
  if (!error) {
    if (!participantesPorEvento.value[evento.id]) participantesPorEvento.value[evento.id] = {}
    participantesPorEvento.value[evento.id][atletaId] = data
  }
}

async function enviarMidias(evento, fileList) {
  const files = Array.from(fileList || [])
  if (!files.length) return
  enviandoMidia.value = true
  for (const file of files) {
    const tipo = file.type.startsWith('video') ? 'video' : 'foto'
    const ext = file.name.includes('.') ? file.name.split('.').pop() : (tipo === 'video' ? 'mp4' : 'jpg')
    const nomeArquivo = `${crypto.randomUUID()}.${ext}`
    const caminho = `evento-${evento.id}/${nomeArquivo}`

    const { error: upError } = await supabase.storage.from('midias-base').upload(caminho, file, { contentType: file.type })
    if (upError) {
      alert(`Erro ao enviar ${file.name}: ${upError.message}`)
      continue
    }
    const { data: pub } = supabase.storage.from('midias-base').getPublicUrl(caminho)
    const { data: midia, error } = await supabase.from('evento_midias_base').insert({
      evento_id: evento.id, tipo, url: pub.publicUrl, storage_path: caminho, criado_por: profile.value.id,
    }).select().single()
    if (!error) {
      if (!midiasPorEvento.value[evento.id]) midiasPorEvento.value[evento.id] = []
      midiasPorEvento.value[evento.id].push(midia)
    }
  }
  enviandoMidia.value = false
}

async function excluirMidia(evento, midia) {
  if (!confirm('Excluir esta mídia?')) return
  await supabase.storage.from('midias-base').remove([midia.storage_path])
  await supabase.from('evento_midias_base').delete().eq('id', midia.id)
  midiasPorEvento.value[evento.id] = (midiasPorEvento.value[evento.id] ?? []).filter((m) => m.id !== midia.id)
}

async function excluirEvento(evento) {
  if (!confirm(`Excluir o evento "${evento.titulo}"? Isso remove também a chamada, avaliações e mídias vinculadas a ele.`)) return
  const midias = midiasPorEvento.value[evento.id] ?? []
  if (midias.length) await supabase.storage.from('midias-base').remove(midias.map((m) => m.storage_path))
  const { error } = await supabase.from('eventos_base').delete().eq('id', evento.id)
  if (!error) {
    eventos.value = eventos.value.filter((e) => e.id !== evento.id)
    if (eventoExpandidoId.value === evento.id) eventoExpandidoId.value = null
  }
}
</script>

<template>
  <div>
    <div v-if="!embedded" class="flex flex-wrap items-center justify-between gap-4">
      <div>
        <p class="font-mono-label text-[11px] font-bold text-brand-deep">Coordenação · Categorias de Base</p>
        <h1 class="mt-1 font-display text-3xl font-extrabold text-ink">
          {{ { atletas: 'Atletas', categorias: 'Categorias', planos: 'Planos', eventos: 'Eventos' }[aba] }}
        </h1>
      </div>
      <div class="flex items-center gap-3">
        <span class="text-xs text-ink-soft">Logado como {{ profile?.nome }}</span>
        <button class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft hover:border-ink/30" @click="logout">Sair</button>
      </div>
    </div>

    <div :class="embedded ? 'flex flex-wrap gap-2' : 'mt-6 flex flex-wrap gap-2'">
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'atletas' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'atletas'">Atletas</button>
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'eventos' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'eventos'; carregarEventos()">Eventos</button>
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'categorias' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'categorias'">Categorias</button>
      <button class="rounded-full px-4 py-2 text-xs font-semibold transition-colors" :class="aba === 'planos' ? 'bg-ink text-white' : 'bg-paper-dim text-ink-soft hover:bg-ink/10'" @click="aba = 'planos'">Planos</button>
    </div>

    <p v-if="carregando" class="mt-8 text-sm text-ink-soft">Carregando...</p>

    <!-- ===== ATLETAS ===== -->
    <div v-else-if="aba === 'atletas'" class="mt-6">
      <div class="flex flex-wrap items-center gap-2">
        <button v-if="!mostrarFormAtleta" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep" @click="abrirFormAtleta">+ Novo atleta</button>
        <input v-model="filtroBusca" placeholder="Buscar por nome..." class="min-w-0 flex-1 rounded-lg border border-ink/15 px-3 py-2 text-xs" />
        <select v-model="filtroCategoria" class="rounded-lg border border-ink/15 px-2 py-2 text-xs">
          <option value="todas">Todas as categorias</option>
          <option v-for="c in categorias" :key="c.id" :value="c.id">{{ nomeCategoria(c) }}</option>
        </select>
        <select v-model="filtroStatus" class="rounded-lg border border-ink/15 px-2 py-2 text-xs">
          <option value="todos">Todos os status</option>
          <option v-for="s in statusAtletaOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
        </select>
        <select v-model="filtroSexo" class="rounded-lg border border-ink/15 px-2 py-2 text-xs">
          <option value="todos">Ambos os sexos</option>
          <option v-for="s in sexoOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
        </select>
      </div>

      <form v-if="mostrarFormAtleta" class="mt-4 space-y-4 rounded-2xl bg-white p-6 shadow-card" @submit.prevent="salvarAtleta">
        <div v-if="inscricoesAtivas.length">
          <p class="font-mono-label text-[9px] font-bold text-ink-soft">PRÉ-PREENCHER A PARTIR DE UMA MATRÍCULA</p>
          <select v-model="formAtleta.inscricaoId" class="mt-1 w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" @change="preencherComInscricao">
            <option value="">Cadastro do zero (sem vincular a uma inscrição)</option>
            <option v-for="i in inscricoesAtivas" :key="i.id" :value="i.id">{{ i.atleta_nome }} — {{ i.responsavel_nome }} ({{ i.status }})</option>
          </select>
        </div>

        <p class="font-mono-label text-[9px] font-bold text-ink-soft pt-2">DADOS DO ATLETA</p>
        <div class="grid gap-3 sm:grid-cols-2">
          <input v-model="formAtleta.nome" placeholder="Nome completo" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
          <input v-model="formAtleta.data_nascimento" type="date" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <select v-model="formAtleta.sexo" class="rounded-lg border border-ink/15 px-3 py-2 text-sm">
            <option v-for="s in sexoOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
          </select>
          <select v-model="formAtleta.categoria_id" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm">
            <option value="" disabled>Categoria...</option>
            <option v-for="c in categorias" :key="c.id" :value="c.id">{{ nomeCategoria(c) }}</option>
          </select>
          <select v-model="formAtleta.posicao" class="rounded-lg border border-ink/15 px-3 py-2 text-sm">
            <option value="">Posição (opcional)</option>
            <option v-for="p in posicaoOptions" :key="p.value" :value="p.value">{{ p.label }}</option>
          </select>
          <input v-model="formAtleta.escola" placeholder="Escola (opcional)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
        </div>
        <p class="text-[11px] text-ink-soft">A categoria é sugerida automaticamente pela data de nascimento — pode trocar se precisar.</p>

        <p class="font-mono-label text-[9px] font-bold text-ink-soft pt-2">VÍNCULO</p>
        <div class="flex flex-wrap gap-4">
          <label v-for="v in vinculoAtletaOptions" :key="v.value" class="flex items-center gap-1.5 text-xs text-ink">
            <input type="radio" :value="v.value" v-model="formAtleta.vinculo" class="h-3.5 w-3.5" />
            {{ v.label }}
          </label>
        </div>
        <p class="text-[11px] text-ink-soft">"Somente evento(s)" cadastra sem mensalidade — dá pra promover a atleta do projeto depois, na lista.</p>

        <p class="font-mono-label text-[9px] font-bold text-ink-soft pt-2">EVENTOS (opcional)</p>
        <div v-if="eventos.length" class="max-h-32 space-y-1.5 overflow-y-auto rounded-lg border border-ink/15 p-2.5">
          <label v-for="e in eventos" :key="e.id" class="flex items-center gap-1.5 text-xs text-ink">
            <input type="checkbox" :value="e.id" v-model="formAtleta.eventosSelecionados" class="h-3.5 w-3.5 rounded border-ink/30" />
            {{ e.titulo }} — {{ tipoEventoLabel(e.tipo) }} · {{ formatarDataCurta(e.data) }}
          </label>
        </div>
        <p v-else class="text-[11px] text-ink-soft">Nenhum evento cadastrado ainda — pode vincular depois pela aba Eventos.</p>

        <p class="font-mono-label text-[9px] font-bold text-ink-soft pt-2">RESPONSÁVEL</p>
        <div class="grid gap-3 sm:grid-cols-2">
          <input v-model="formAtleta.respNome" placeholder="Nome do responsável" :disabled="!!respEncontrado" class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2 disabled:bg-paper-dim" />
          <input v-model="formAtleta.respTelefone" placeholder="WhatsApp" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" @blur="buscarResponsavelExistente" />
          <input v-model="formAtleta.respEmail" placeholder="E-mail (opcional)" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" @blur="buscarResponsavelExistente" />
        </div>
        <p v-if="respBuscando" class="text-xs text-ink-soft">Verificando se esse responsável já está cadastrado...</p>
        <p v-else-if="respEncontrado" class="rounded-lg bg-[#EAF3DE] px-3 py-2 text-xs text-[#27500A]">
          ✓ Responsável já cadastrado — vamos reaproveitar o cadastro de <strong>{{ respEncontrado.nome }}</strong>, sem criar um novo login.
        </p>
        <input v-if="!respEncontrado" v-model="formAtleta.respSenha" type="password" placeholder="Senha de acesso do responsável" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />

        <input v-model="formAtleta.parentesco" placeholder="Parentesco (ex: mãe, pai, avó)" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />

        <p v-if="erroAtleta" class="text-xs text-brand-deep">{{ erroAtleta }}</p>

        <div class="flex gap-2">
          <button type="submit" :disabled="salvandoAtleta" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ salvandoAtleta ? 'Salvando...' : 'Salvar atleta' }}</button>
          <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="mostrarFormAtleta = false">Cancelar</button>
        </div>
      </form>

      <div v-if="atletasFiltrados.length === 0" class="mt-6 rounded-2xl border border-dashed border-ink/15 p-8 text-center">
        <Icon name="users" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Nenhum atleta encontrado com esses filtros.</p>
      </div>

      <div v-else class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
        <div v-for="a in atletasFiltrados" :key="a.id" class="px-5 py-3.5">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-ink">{{ a.nome }}</p>
              <p class="text-xs text-ink-soft">
                {{ nomeCategoria(categoriaDoAtleta(a)) }} · {{ idadeAtual(a.data_nascimento) }} anos
                <span v-if="a.posicao"> · {{ posicaoLabel(a.posicao) }}</span>
                <span v-if="a.profile_id"> · acesso ativo</span>
                <span v-if="a.inscricao_experiencia_id"> · veio de matrícula</span>
              </p>
              <p v-if="contatosDoAtleta(a).length" class="mt-0.5 text-xs text-ink-soft">
                📞 {{ contatosDoAtleta(a).map((c) => `${c.responsavel_nome} (${c.telefone})`).join(' · ') }}
              </p>
            </div>
            <div class="flex items-center gap-2">
              <span :class="['rounded-full px-3 py-1 text-xs font-semibold', a.vinculo === 'evento' ? 'bg-gold-soft text-ink' : 'bg-ink/8 text-ink-soft']">{{ vinculoAtletaLabel(a.vinculo) }}</span>
              <span :class="['rounded-full px-3 py-1 text-xs font-semibold', statusAtletaClasses(a.status)]">{{ statusAtletaLabel(a.status) }}</span>
              <button v-if="a.vinculo === 'evento'" class="text-xs font-semibold text-brand-deep hover:underline" @click="promovendoAtletaId === a.id ? (promovendoAtletaId = null) : abrirPromocao(a)">{{ promovendoAtletaId === a.id ? 'Fechar' : 'Tornar do projeto' }}</button>
              <button class="text-xs font-semibold text-brand-deep hover:underline" @click="editandoAtletaId === a.id ? (editandoAtletaId = null) : abrirEdicaoAtleta(a)">{{ editandoAtletaId === a.id ? 'Fechar' : 'Editar' }}</button>
            </div>
          </div>

          <div v-if="promovendoAtletaId === a.id" class="mt-3 flex flex-wrap items-center gap-2 rounded-xl bg-paper-dim p-4">
            <span class="text-xs text-ink-soft">Vira mensalista no plano:</span>
            <select v-model="planoPromocao" class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs">
              <option v-for="p in planos.filter((pl) => pl.ativo)" :key="p.id" :value="p.id">{{ p.nome }} ({{ brl(p.valor_mensal) }}/mês)</option>
            </select>
            <button type="button" class="rounded-full bg-brand px-3 py-1.5 text-xs font-bold text-white hover:bg-brand-deep" @click="confirmarPromocao(a)">Confirmar</button>
          </div>

          <form v-if="editandoAtletaId === a.id && formEdicaoAtleta" class="mt-3 space-y-3 rounded-xl bg-paper-dim p-4" @submit.prevent="salvarEdicaoAtleta(a)">
            <div class="grid gap-3 sm:grid-cols-2">
              <input v-model="formEdicaoAtleta.nome" placeholder="Nome completo" required class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm sm:col-span-2" />
              <input v-model="formEdicaoAtleta.data_nascimento" type="date" required class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
              <select v-model="formEdicaoAtleta.sexo" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm">
                <option v-for="s in sexoOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
              </select>
              <select v-model="formEdicaoAtleta.categoria_id" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm">
                <option v-for="c in categorias" :key="c.id" :value="c.id">{{ nomeCategoria(c) }}</option>
              </select>
              <select v-model="formEdicaoAtleta.status" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm">
                <option v-for="s in statusAtletaOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
              </select>
              <select v-model="formEdicaoAtleta.posicao" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm">
                <option value="">Posição (opcional)</option>
                <option v-for="p in posicaoOptions" :key="p.value" :value="p.value">{{ p.label }}</option>
              </select>
              <input v-model="formEdicaoAtleta.escola" placeholder="Escola" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            </div>
            <textarea v-model="formEdicaoAtleta.observacoes_gerais" placeholder="Observações gerais (evite linguagem clínica/diagnóstica)" rows="2" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm"></textarea>

            <div v-if="formEdicaoAtleta.contatos.length" class="space-y-3 border-t border-ink/10 pt-3">
              <p class="font-mono-label text-[9px] font-bold text-ink-soft">CONTATO DO(S) RESPONSÁVEL(IS)</p>
              <div v-for="c in formEdicaoAtleta.contatos" :key="c.responsavel_id" class="grid gap-2 sm:grid-cols-2">
                <input v-model="c.nome" placeholder="Nome do responsável" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm sm:col-span-2" />
                <input v-model="c.telefone" placeholder="WhatsApp" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
                <input v-model="c.email" placeholder="E-mail" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
                <input v-model="c.parentesco" placeholder="Parentesco (ex: mãe, pai, avó)" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm sm:col-span-2" />
              </div>
            </div>

            <div class="flex gap-2">
              <button type="submit" :disabled="salvandoEdicaoAtleta" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep disabled:opacity-50">{{ salvandoEdicaoAtleta ? 'Salvando...' : 'Salvar' }}</button>
              <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="editandoAtletaId = null">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
    </div>

    <!-- ===== EVENTOS ===== -->
    <div v-else-if="aba === 'eventos'" class="mt-6">
      <div class="flex flex-wrap items-center gap-2">
        <button v-if="!mostrarFormEvento" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep" @click="mostrarFormEvento = true">+ Novo evento</button>
        <select v-model="filtroEventoCategoria" class="rounded-lg border border-ink/15 px-2 py-2 text-xs">
          <option value="todas">Todas as categorias</option>
          <option v-for="c in categorias" :key="c.id" :value="c.id">{{ nomeCategoria(c) }}</option>
        </select>
      </div>

      <form v-if="mostrarFormEvento" class="mt-4 space-y-3 rounded-2xl bg-white p-6 shadow-card" @submit.prevent="salvarEvento">
        <div class="grid gap-3 sm:grid-cols-2">
          <input v-model="formEvento.titulo" placeholder="Título (ex: Treino técnico, Amistoso x Clube X)" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2" />
          <select v-model="formEvento.tipo" class="rounded-lg border border-ink/15 px-3 py-2 text-sm">
            <option v-for="t in tipoEventoOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
          </select>
          <select v-model="formEvento.categoria_id" class="rounded-lg border border-ink/15 px-3 py-2 text-sm">
            <option value="">Todas as categorias</option>
            <option v-for="c in categorias" :key="c.id" :value="c.id">{{ nomeCategoria(c) }}</option>
          </select>
          <input v-model="formEvento.data" type="date" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <input v-model="formEvento.local" placeholder="Local" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <input v-model="formEvento.hora_inicio" type="time" placeholder="Início" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <input v-model="formEvento.hora_fim" type="time" placeholder="Fim" class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
          <select v-model="formEvento.plano_id" class="rounded-lg border border-ink/15 px-3 py-2 text-sm sm:col-span-2">
            <option value="">Sem plano vinculado</option>
            <option v-for="p in planos" :key="p.id" :value="p.id">{{ p.nome }} ({{ brl(p.valor_mensal) }}/mês)</option>
          </select>
        </div>
        <textarea v-model="formEvento.plano_atividades" placeholder="Plano de atividades / o que será trabalhado" rows="2" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm"></textarea>
        <textarea v-model="formEvento.observacoes" placeholder="Observações (opcional)" rows="2" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm"></textarea>
        <div class="flex gap-2">
          <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
          <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="mostrarFormEvento = false">Cancelar</button>
        </div>
      </form>

      <div v-if="eventosFiltrados.length === 0" class="mt-6 rounded-2xl border border-dashed border-ink/15 p-8 text-center">
        <Icon name="calendar" class="mx-auto h-6 w-6 text-ink-soft/50" />
        <p class="mt-2 text-sm text-ink-soft">Nenhum evento cadastrado ainda.</p>
      </div>

      <div v-else class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
        <div v-for="e in eventosFiltrados" :key="e.id" class="px-5 py-3.5">
          <div class="flex flex-wrap items-center justify-between gap-3 cursor-pointer" @click="abrirEvento(e)">
            <div>
              <p class="text-sm font-semibold text-ink">{{ e.titulo }}</p>
              <p class="text-xs text-ink-soft">
                {{ tipoEventoLabel(e.tipo) }} · {{ formatarDataCurta(e.data) }}
                <span v-if="e.hora_inicio"> · {{ formatarHora(e.hora_inicio) }}<span v-if="e.hora_fim">–{{ formatarHora(e.hora_fim) }}</span></span>
                <span v-if="e.local"> · {{ e.local }}</span>
                · {{ nomeCategoria(categoriaDoAtleta({ categoria_id: e.categoria_id })) === '—' ? 'Todas as categorias' : nomeCategoria(categoriaDoAtleta({ categoria_id: e.categoria_id })) }}
                <span v-if="planoDoEvento(e)"> · plano {{ planoDoEvento(e).nome }}</span>
              </p>
            </div>
            <div class="flex items-center gap-2">
              <button type="button" class="text-xs font-semibold text-brand-deep hover:underline" @click.stop="editandoEventoId === e.id ? (editandoEventoId = null) : abrirEdicaoEvento(e)">{{ editandoEventoId === e.id ? 'Fechar' : 'Editar' }}</button>
              <button type="button" class="text-xs font-semibold text-brand-deep hover:underline" @click.stop="abrirEvento(e)">{{ eventoExpandidoId === e.id ? 'Fechar' : 'Gerenciar' }}</button>
            </div>
          </div>

          <form v-if="editandoEventoId === e.id && formEdicaoEvento" class="mt-3 space-y-3 rounded-xl bg-paper-dim p-4" @submit.prevent="salvarEdicaoEvento(e)">
            <div class="grid gap-3 sm:grid-cols-2">
              <input v-model="formEdicaoEvento.titulo" placeholder="Título" required class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm sm:col-span-2" />
              <select v-model="formEdicaoEvento.tipo" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm">
                <option v-for="t in tipoEventoOptions" :key="t.value" :value="t.value">{{ t.label }}</option>
              </select>
              <select v-model="formEdicaoEvento.categoria_id" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm">
                <option value="">Todas as categorias</option>
                <option v-for="c in categorias" :key="c.id" :value="c.id">{{ nomeCategoria(c) }}</option>
              </select>
              <input v-model="formEdicaoEvento.data" type="date" required class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
              <input v-model="formEdicaoEvento.local" placeholder="Local" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
              <input v-model="formEdicaoEvento.hora_inicio" type="time" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
              <input v-model="formEdicaoEvento.hora_fim" type="time" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
              <select v-model="formEdicaoEvento.plano_id" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm sm:col-span-2">
                <option value="">Sem plano vinculado</option>
                <option v-for="p in planos" :key="p.id" :value="p.id">{{ p.nome }} ({{ brl(p.valor_mensal) }}/mês)</option>
              </select>
            </div>
            <textarea v-model="formEdicaoEvento.plano_atividades" placeholder="Plano de atividades / o que será trabalhado" rows="2" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm"></textarea>
            <textarea v-model="formEdicaoEvento.observacoes" placeholder="Observações (opcional)" rows="2" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm"></textarea>
            <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
          </form>

          <div v-if="eventoExpandidoId === e.id" class="mt-4 space-y-4 rounded-xl bg-paper-dim p-4">
            <p v-if="e.plano_atividades" class="text-xs text-ink"><strong>Atividades:</strong> {{ e.plano_atividades }}</p>

            <div>
              <div class="flex flex-wrap items-center justify-between gap-2">
                <p class="font-mono-label text-[9px] font-bold text-ink-soft">CHAMADA E DESEMPENHO</p>
                <div class="flex flex-wrap items-center gap-2">
                  <select
                    class="rounded-lg border border-ink/15 bg-white px-2 py-1.5 text-xs"
                    @change="(ev) => { adicionarAtletaAoEvento(e, ev.target.value); ev.target.value = '' }"
                  >
                    <option value="">+ Adicionar atleta já cadastrado...</option>
                    <option v-for="a in atletasForaDoEvento(e)" :key="a.id" :value="a.id">{{ a.nome }} — {{ nomeCategoria(categoriaDoAtleta(a)) }}</option>
                  </select>
                  <button type="button" class="text-xs font-semibold text-brand-deep hover:underline" @click="irParaCadastroNovoAtleta(e)">+ Cadastrar novo atleta</button>
                </div>
              </div>
              <div class="mt-2 divide-y divide-ink/8 rounded-xl bg-white">
                <div v-for="a in atletasDoEvento(e)" :key="a.id" class="flex flex-wrap items-center gap-2 px-4 py-2.5">
                  <span class="min-w-[9rem] flex-1 text-sm text-ink">{{ a.nome }}</span>
                  <select
                    :value="participanteDoAtleta(e, a.id).presente === null ? '' : String(participanteDoAtleta(e, a.id).presente)"
                    class="rounded-lg border border-ink/15 px-2 py-1 text-xs"
                    @change="(ev) => salvarParticipante(e, a.id, { presente: ev.target.value === '' ? null : ev.target.value === 'true' })"
                  >
                    <option value="">Presença...</option>
                    <option value="true">Presente</option>
                    <option value="false">Ausente</option>
                  </select>
                  <input
                    type="number" min="0" max="10" step="0.5" placeholder="Nota"
                    :value="participanteDoAtleta(e, a.id).desempenho_nota"
                    class="w-20 rounded-lg border border-ink/15 px-2 py-1 text-xs"
                    @change="(ev) => salvarParticipante(e, a.id, { desempenho_nota: ev.target.value === '' ? null : Number(ev.target.value) })"
                  />
                  <input
                    type="text" placeholder="Observação"
                    :value="participanteDoAtleta(e, a.id).desempenho_obs"
                    class="min-w-0 flex-1 rounded-lg border border-ink/15 px-2 py-1 text-xs"
                    @change="(ev) => salvarParticipante(e, a.id, { desempenho_obs: ev.target.value })"
                  />
                </div>
              </div>
            </div>

            <div>
              <div class="flex items-center justify-between">
                <p class="font-mono-label text-[9px] font-bold text-ink-soft">FOTOS E VÍDEOS</p>
                <label class="cursor-pointer text-xs font-semibold text-brand-deep hover:underline">
                  <Icon name="camera" class="inline h-3.5 w-3.5 -mt-0.5 mr-1" />{{ enviandoMidia ? 'Enviando...' : 'Adicionar' }}
                  <input type="file" accept="image/*,video/*" multiple class="hidden" :disabled="enviandoMidia" @change="(ev) => enviarMidias(e, ev.target.files)" />
                </label>
              </div>
              <div v-if="(midiasPorEvento[e.id] ?? []).length" class="mt-2 grid grid-cols-3 gap-2 sm:grid-cols-4">
                <div v-for="m in midiasPorEvento[e.id]" :key="m.id" class="group relative overflow-hidden rounded-lg bg-ink/5">
                  <img v-if="m.tipo === 'foto'" :src="m.url" class="h-24 w-full object-cover" />
                  <video v-else :src="m.url" class="h-24 w-full object-cover" controls></video>
                  <button type="button" class="absolute right-1 top-1 hidden rounded-full bg-white/90 px-2 py-0.5 text-[10px] font-bold text-brand-deep group-hover:block" @click="excluirMidia(e, m)">remover</button>
                </div>
              </div>
              <p v-else class="mt-2 text-xs text-ink-soft">Nenhuma foto ou vídeo enviado ainda.</p>
            </div>

            <button type="button" class="text-xs font-semibold text-brand-deep hover:underline" @click="excluirEvento(e)">Excluir evento</button>
          </div>
        </div>
      </div>
    </div>

    <!-- ===== CATEGORIAS ===== -->
    <div v-else-if="aba === 'categorias'" class="mt-6">
      <button v-if="!mostrarFormCategoria" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep" @click="mostrarFormCategoria = true">+ Nova categoria</button>

      <form v-if="mostrarFormCategoria" class="mt-4 flex flex-wrap items-end gap-3 rounded-2xl bg-white p-5 shadow-card" @submit.prevent="salvarCategoria">
        <input v-model="formCategoria.nome" placeholder="Nome (ex: Sub-17)" required class="rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <select v-model="formCategoria.sexo" class="rounded-lg border border-ink/15 px-3 py-2 text-sm">
          <option v-for="s in sexoOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
        </select>
        <label class="text-xs text-ink-soft">Nascidos de<input v-model="formCategoria.data_corte_min" type="date" class="ml-1 rounded-lg border border-ink/15 px-2 py-2 text-sm" /></label>
        <label class="text-xs text-ink-soft">até<input v-model="formCategoria.data_corte_max" type="date" class="ml-1 rounded-lg border border-ink/15 px-2 py-2 text-sm" /></label>
        <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
        <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="mostrarFormCategoria = false">Cancelar</button>
      </form>

      <div class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
        <div v-for="c in categorias" :key="c.id" class="px-5 py-3.5">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-ink">{{ nomeCategoria(c) }}</p>
              <p class="text-xs text-ink-soft" v-if="c.data_corte_min || c.data_corte_max">Nascidos de {{ formatarDataCurta(c.data_corte_min) }} até {{ formatarDataCurta(c.data_corte_max) }}</p>
            </div>
            <div class="flex items-center gap-2">
              <button class="rounded-full px-3 py-1 text-xs font-semibold" :class="c.ativo ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-ink/8 text-ink-soft'" @click="alternarAtivoCategoria(c)">{{ c.ativo ? 'ativa' : 'inativa' }}</button>
              <button class="text-xs font-semibold text-brand-deep hover:underline" @click="editandoCategoriaId === c.id ? (editandoCategoriaId = null) : abrirEdicaoCategoria(c)">{{ editandoCategoriaId === c.id ? 'Fechar' : 'Editar' }}</button>
              <button class="text-xs font-semibold text-ink-soft hover:text-brand-deep hover:underline" @click="excluirCategoria(c)">Excluir</button>
            </div>
          </div>

          <form v-if="editandoCategoriaId === c.id && formEdicaoCategoria" class="mt-3 flex flex-wrap items-end gap-3 rounded-xl bg-paper-dim p-4" @submit.prevent="salvarEdicaoCategoria(c)">
            <input v-model="formEdicaoCategoria.nome" required class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <select v-model="formEdicaoCategoria.sexo" class="rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm">
              <option v-for="s in sexoOptions" :key="s.value" :value="s.value">{{ s.label }}</option>
            </select>
            <label class="text-xs text-ink-soft">Nascidos de<input v-model="formEdicaoCategoria.data_corte_min" type="date" class="ml-1 rounded-lg border border-ink/15 bg-white px-2 py-2 text-sm" /></label>
            <label class="text-xs text-ink-soft">até<input v-model="formEdicaoCategoria.data_corte_max" type="date" class="ml-1 rounded-lg border border-ink/15 bg-white px-2 py-2 text-sm" /></label>
            <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
          </form>
        </div>
      </div>
    </div>

    <!-- ===== PLANOS ===== -->
    <div v-else class="mt-6">
      <button v-if="!mostrarFormPlano" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep" @click="mostrarFormPlano = true">+ Novo plano</button>

      <form v-if="mostrarFormPlano" class="mt-4 space-y-3 rounded-2xl bg-white p-5 shadow-card" @submit.prevent="salvarPlano">
        <input v-model="formPlano.nome" placeholder="Nome do plano" required class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model.number="formPlano.valor_mensal" type="number" step="0.01" placeholder="Valor mensal (0 = gratuito)" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <input v-model="formPlano.descricao" placeholder="Descrição (opcional)" class="w-full rounded-lg border border-ink/15 px-3 py-2 text-sm" />
        <div class="flex gap-2">
          <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
          <button type="button" class="rounded-full border border-ink/15 px-4 py-2 text-xs font-semibold text-ink-soft" @click="mostrarFormPlano = false">Cancelar</button>
        </div>
      </form>

      <div class="mt-6 divide-y divide-ink/8 rounded-2xl bg-white shadow-card">
        <div v-for="p in planos" :key="p.id" class="px-5 py-3.5">
          <div class="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p class="text-sm font-semibold text-ink">{{ p.nome }} <span v-if="p.padrao" class="ml-1 rounded-full bg-gold-soft px-2 py-0.5 text-[10px] font-bold text-ink">PADRÃO</span></p>
              <p class="text-xs text-ink-soft">{{ brl(p.valor_mensal) }}/mês <span v-if="p.descricao"> · {{ p.descricao }}</span></p>
            </div>
            <div class="flex items-center gap-2">
              <button v-if="!p.padrao" class="text-xs font-semibold text-brand-deep hover:underline" @click="definirPlanoPadrao(p)">Tornar padrão</button>
              <button class="rounded-full px-3 py-1 text-xs font-semibold" :class="p.ativo ? 'bg-[#EAF3DE] text-[#27500A]' : 'bg-ink/8 text-ink-soft'" @click="alternarAtivoPlano(p)">{{ p.ativo ? 'ativo' : 'inativo' }}</button>
              <button class="text-xs font-semibold text-brand-deep hover:underline" @click="editandoPlanoId === p.id ? (editandoPlanoId = null) : abrirEdicaoPlano(p)">{{ editandoPlanoId === p.id ? 'Fechar' : 'Editar' }}</button>
              <button class="text-xs font-semibold text-ink-soft hover:text-brand-deep hover:underline" @click="excluirPlano(p)">Excluir</button>
            </div>
          </div>

          <form v-if="editandoPlanoId === p.id && formEdicaoPlano" class="mt-3 space-y-2 rounded-xl bg-paper-dim p-4" @submit.prevent="salvarEdicaoPlano(p)">
            <input v-model="formEdicaoPlano.nome" required class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model.number="formEdicaoPlano.valor_mensal" type="number" step="0.01" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <input v-model="formEdicaoPlano.descricao" class="w-full rounded-lg border border-ink/15 bg-white px-3 py-2 text-sm" />
            <button type="submit" class="rounded-full bg-brand px-4 py-2 text-xs font-bold text-white hover:bg-brand-deep">Salvar</button>
          </form>
        </div>
      </div>
    </div>

  </div>
</template>
