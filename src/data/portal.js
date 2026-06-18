export const modalidadeOptions = [
  { value: 'volei', label: 'Vôlei' },
  { value: 'volei_domino', label: 'Vôlei + Dominó' },
  { value: 'domino', label: 'Dominó' },
]

export function modalidadeLabel(value) {
  return modalidadeOptions.find((m) => m.value === value)?.label ?? value
}

export const roleOptions = [
  { value: 'associado', label: 'Associado' },
  { value: 'admin', label: 'Administrador' },
]

export const statusOptions = [
  { value: 'adimplente', label: 'Adimplente' },
  { value: 'inadimplente', label: 'Inadimplente' },
  { value: 'inativo', label: 'Inativo' },
]

export function statusLabel(value) {
  return statusOptions.find((s) => s.value === value)?.label ?? value
}
