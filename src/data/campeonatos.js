export const categoriaOptions = ['Livre', '35+', '40+', '45+', '50+', '55+', '60+']

// Indice maior = categoria mais "velha" (exige mais idade). Um atleta so
// pode jogar na categoria dele ou em categorias MAIS VELHAS (indice maior
// ou igual), nunca em uma mais jovem que a dele.
export function categoriaIndex(categoria) {
  return categoriaOptions.indexOf(categoria)
}

export function categoriaElegivel(categoriaAtleta, categoriaAlvo) {
  const idxAtleta = categoriaIndex(categoriaAtleta)
  const idxAlvo = categoriaIndex(categoriaAlvo)
  if (idxAtleta === -1 || idxAlvo === -1) return true // sem dado suficiente, nao bloqueia
  return idxAtleta >= idxAlvo
}

export const colocacaoOptions = ['Campeão', 'Vice', 'Terceiro', 'Quarto', 'Quinto', 'Sexto', 'Outro']

export const premiacaoTipoOptions = [
  { value: 'dinheiro', label: 'Dinheiro' },
  { value: 'vaga_outro_campeonato', label: 'Vaga em outro campeonato' },
  { value: 'medalha_trofeu', label: 'Medalha / Troféu' },
  { value: 'outro', label: 'Outro' },
]

export function premiacaoTipoLabel(value) {
  return premiacaoTipoOptions.find((p) => p.value === value)?.label ?? value
}

export const origemReceitaOptions = [
  { value: 'associacao', label: 'Verba da associação' },
  { value: 'aporte_pessoal', label: 'Aporte pessoal' },
  { value: 'outro', label: 'Outro' },
]

export function origemReceitaLabel(value) {
  return origemReceitaOptions.find((o) => o.value === value)?.label ?? value
}

export const tipoDespesaOptions = [
  { value: 'rateado', label: 'Rateado entre os atletas' },
  { value: 'assumido', label: 'Assumido por alguém' },
]

export function tipoDespesaLabel(value) {
  return tipoDespesaOptions.find((t) => t.value === value)?.label ?? value
}

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
  { value: 'conjunto_uniforme', label: 'Conjunto de uniforme completo' },
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
