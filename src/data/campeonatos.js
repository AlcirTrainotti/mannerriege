export const categoriaOptions = ['Livre', '35+', '40+', '45+', '50+', '55+', '60+']

export const ufOptions = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG',
  'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
]

export const funcaoOptions = [
  { value: 'atleta', label: 'Atleta' },
  { value: 'comissao_tecnica', label: 'Comissão Técnica' },
]

export function funcaoLabel(value) {
  return funcaoOptions.find((f) => f.value === value)?.label ?? value
}

export const tipoAtivoOptions = [
  { value: 'uniforme', label: 'Uniforme' },
  { value: 'bola', label: 'Bola' },
]

export function brl(v) {
  return (Number(v) || 0).toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' })
}

export function formatarDataCurta(d) {
  if (!d) return '—'
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

export function formatarDataLonga(d) {
  if (!d) return '—'
  return new Date(d + 'T00:00:00').toLocaleDateString('pt-BR', { day: '2-digit', month: 'long', year: 'numeric' })
}
