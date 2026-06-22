export const tipoReceitaOptions = [
  { value: 'chamada_capital', label: 'Chamada de capital' },
  { value: 'doacao', label: 'Doação' },
  { value: 'patrocinio', label: 'Patrocínio' },
  { value: 'mensalidade_adiantada', label: 'Mensalidade (adiantamento)' },
  { value: 'outro', label: 'Outro' },
]
export function tipoReceitaLabel(value) {
  return tipoReceitaOptions.find((t) => t.value === value)?.label ?? value
}

export const categoriaDespesaOptions = [
  { value: 'benfeitoria', label: 'Benfeitoria' },
  { value: 'manutencao', label: 'Manutenção' },
  { value: 'compra_material', label: 'Compra de material' },
  { value: 'evento', label: 'Evento' },
  { value: 'outro', label: 'Outro' },
]
export function categoriaDespesaLabel(value) {
  return categoriaDespesaOptions.find((c) => c.value === value)?.label ?? value
}

export const tipoPatrocinadorOptions = [
  { value: 'privado', label: 'Privado' },
  { value: 'publico', label: 'Público' },
]

export const nivelPatrocinioOptions = ['Basic', 'Exclusivo', 'Master', 'Outro']

export const mesesOptions = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
]

export function formatarCompetencia(dataIso) {
  if (!dataIso) return '—'
  const d = new Date(dataIso + 'T00:00:00')
  return `${mesesOptions[d.getMonth()]} de ${d.getFullYear()}`
}

export function valorMensalidade(socioGinastico) {
  return socioGinastico ? 30 : 50
}
