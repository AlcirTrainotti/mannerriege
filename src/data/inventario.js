export const tamanhoOptions = ['P', 'M', 'G', 'GG', 'G1', 'G2', 'G3', 'XG', 'XGG', 'EXG']

export const tipoUniformeOptions = [
  { value: 'completo', label: 'Camiseta + Calção' },
  { value: 'somente_camiseta', label: 'Só camiseta' },
]

export function tipoUniformeLabel(value) {
  return tipoUniformeOptions.find((t) => t.value === value)?.label ?? value
}

export const estadoOptions = [
  { value: 'novo', label: 'Novo' },
  { value: 'bom', label: 'Bom' },
  { value: 'regular', label: 'Regular' },
  { value: 'avariado', label: 'Avariado' },
  { value: 'baixado', label: 'Baixado' },
]

export function estadoLabel(value) {
  return estadoOptions.find((e) => e.value === value)?.label ?? value
}

export function estadoClasses(value) {
  if (value === 'novo') return 'bg-[#EAF3DE] text-[#27500A]'
  if (value === 'bom') return 'bg-gold-soft text-ink'
  if (value === 'regular') return 'bg-paper-dim text-ink-soft'
  if (value === 'avariado') return 'bg-brand-soft text-brand-deep'
  return 'bg-ink/10 text-ink-soft' // baixado
}
