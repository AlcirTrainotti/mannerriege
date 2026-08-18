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
