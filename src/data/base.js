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
