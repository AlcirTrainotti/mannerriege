// Labels e helpers do módulo Categorias de Base.

export const statusAtletaOptions = [
  { value: 'ativo', label: 'Ativo' },
  { value: 'inativo', label: 'Inativo' },
  { value: 'lesionado', label: 'Lesionado' },
  { value: 'desligado', label: 'Desligado' },
]

export function statusAtletaLabel(v) {
  return statusAtletaOptions.find((s) => s.value === v)?.label ?? v
}

export function statusAtletaClasses(v) {
  if (v === 'ativo') return 'bg-[#EAF3DE] text-[#27500A]'
  if (v === 'lesionado') return 'bg-gold-soft text-ink'
  if (v === 'desligado') return 'bg-brand-soft text-brand-deep'
  return 'bg-ink/8 text-ink-soft' // inativo
}

export const vinculoAtletaOptions = [
  { value: 'projeto', label: 'Atleta do projeto (mensalista)' },
  { value: 'evento', label: 'Somente evento(s)' },
]

export function vinculoAtletaLabel(v) {
  return vinculoAtletaOptions.find((o) => o.value === v)?.label ?? v
}

export const sexoOptions = [
  { value: 'masculino', label: 'Masculino' },
  { value: 'feminino', label: 'Feminino' },
]

export function sexoLabel(v) {
  return sexoOptions.find((s) => s.value === v)?.label ?? v
}

export function mensalidadeBaseStatusLabel(v) {
  if (v === 'isento') return 'plano gratuito'
  if (v === 'pago') return 'pago'
  return 'pendente'
}

export function mensalidadeBaseStatusClasses(v) {
  if (v === 'isento') return 'bg-ink/8 text-ink-soft'
  if (v === 'pago') return 'bg-[#EAF3DE] text-[#27500A]'
  return 'bg-brand-soft text-brand-deep'
}

export function idadeAtual(dataNascimento) {
  if (!dataNascimento) return null
  const nascimento = new Date(dataNascimento + 'T00:00:00')
  if (Number.isNaN(nascimento.getTime())) return null
  const hoje = new Date()
  let idade = hoje.getFullYear() - nascimento.getFullYear()
  const aindaNaoFezAniversario =
    hoje.getMonth() < nascimento.getMonth() ||
    (hoje.getMonth() === nascimento.getMonth() && hoje.getDate() < nascimento.getDate())
  if (aindaNaoFezAniversario) idade--
  return idade
}

export function nomeCategoria(categoria) {
  if (!categoria) return '—'
  return `${categoria.nome} · ${sexoLabel(categoria.sexo)}`
}

// Sugere a categoria certa a partir da data de nascimento + sexo do
// atleta, usando as datas de corte cadastradas em cada categoria.
// Compara strings ISO (YYYY-MM-DD), que ordenam corretamente sem
// precisar converter pra Date.
export function categoriaPorNascimento(dataNascimento, sexo, categorias) {
  if (!dataNascimento || !sexo) return null
  const encontrada = (categorias ?? []).find((c) => (
    c.ativo !== false &&
    c.sexo === sexo &&
    c.data_corte_min && c.data_corte_max &&
    dataNascimento >= c.data_corte_min && dataNascimento <= c.data_corte_max
  ))
  return encontrada?.id ?? null
}

export const posicaoOptions = [
  { value: 'ponteiro', label: 'Ponteiro(a)' },
  { value: 'libero', label: 'Líbero' },
  { value: 'levantador', label: 'Levantador(a)' },
  { value: 'meio', label: 'Meio de rede' },
  { value: 'oposto', label: 'Oposto(a)' },
  { value: 'tecnico', label: 'Técnico(a)' },
  { value: 'outro', label: 'Outro' },
]

export function posicaoLabel(v) {
  return posicaoOptions.find((p) => p.value === v)?.label ?? '—'
}

export const tipoEventoOptions = [
  { value: 'treino', label: 'Treino' },
  { value: 'jogo', label: 'Jogo' },
  { value: 'campeonato', label: 'Campeonato' },
  { value: 'festival', label: 'Festival' },
  { value: 'reuniao', label: 'Reunião' },
  { value: 'outro', label: 'Outro' },
]

export function tipoEventoLabel(v) {
  return tipoEventoOptions.find((t) => t.value === v)?.label ?? v
}

export function formatarHora(hhmmss) {
  if (!hhmmss) return ''
  return hhmmss.slice(0, 5)
}

// --- Profissionais do projeto ---
export const cargoProfissionalOptions = [
  { value: 'coordenador', label: 'Coordenador(a)' },
  { value: 'tecnico', label: 'Técnico(a)' },
  { value: 'colaborador', label: 'Colaborador(a)' },
]

export function cargoProfissionalLabel(v) {
  return cargoProfissionalOptions.find((c) => c.value === v)?.label ?? v
}

export function cargosProfissionalLabel(cargos) {
  if (!cargos || !cargos.length) return '—'
  return cargos.map(cargoProfissionalLabel).join(', ')
}

// --- Avaliações periódicas do atleta ---
export const tipoAvaliacaoOptions = [
  { value: 'fisico', label: 'Físico' },
  { value: 'tecnico', label: 'Técnico' },
  { value: 'psicologico', label: 'Psicológico' },
]

export function tipoAvaliacaoLabel(v) {
  return tipoAvaliacaoOptions.find((t) => t.value === v)?.label ?? v
}

// --- Financeiro da Base (separado do financeiro do Master) ---
export const tipoReceitaBaseOptions = [
  { value: 'matricula', label: 'Taxa de matrícula' },
  { value: 'mensalidade', label: 'Mensalidade' },
  { value: 'doacao', label: 'Doação' },
  { value: 'patrocinio', label: 'Patrocínio' },
  { value: 'outro', label: 'Outro' },
]

export function tipoReceitaBaseLabel(v) {
  return tipoReceitaBaseOptions.find((t) => t.value === v)?.label ?? v
}

export const categoriaDespesaBaseOptions = [
  { value: 'material', label: 'Material esportivo' },
  { value: 'quadra', label: 'Locação de quadra' },
  { value: 'transporte', label: 'Transporte' },
  { value: 'uniforme', label: 'Uniforme' },
  { value: 'alimentacao', label: 'Alimentação' },
  { value: 'evento', label: 'Evento' },
  { value: 'outro', label: 'Outro' },
]

export function categoriaDespesaBaseLabel(v) {
  return categoriaDespesaBaseOptions.find((c) => c.value === v)?.label ?? v
}

export function statusFinanceiroBaseClasses(status) {
  if (status === 'pago' || status === 'recebido') return 'bg-[#EAF3DE] text-[#27500A]'
  return 'bg-brand-soft text-brand-deep' // pendente
}

// --- Tempo de casa do atleta ---
export function tempoNoProjeto(dataIngresso) {
  if (!dataIngresso) return null
  const inicio = new Date(dataIngresso + 'T00:00:00')
  if (Number.isNaN(inicio.getTime())) return null
  const hoje = new Date()
  let meses = (hoje.getFullYear() - inicio.getFullYear()) * 12 + (hoje.getMonth() - inicio.getMonth())
  if (hoje.getDate() < inicio.getDate()) meses--
  if (meses < 0) meses = 0
  if (meses < 1) return 'menos de 1 mês'
  const anos = Math.floor(meses / 12)
  const mesesRestantes = meses % 12
  const partes = []
  if (anos > 0) partes.push(`${anos} ano${anos > 1 ? 's' : ''}`)
  if (mesesRestantes > 0) partes.push(`${mesesRestantes} mês${mesesRestantes > 1 ? 'es' : ''}`)
  return partes.join(' e ')
}

// --- Mensagens: pra quem é a mensagem ---
export const destinoMensagemOptions = [
  { value: 'geral', label: 'Coordenação (geral)' },
  { value: 'professor', label: 'Técnico(a) / Professor(a)' },
  { value: 'financeiro', label: 'Financeiro' },
  { value: 'coordenacao', label: 'Coordenação' },
]

export function destinoMensagemLabel(v) {
  return destinoMensagemOptions.find((d) => d.value === v)?.label ?? v
}
