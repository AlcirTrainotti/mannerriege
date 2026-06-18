// Calcula a categoria master (35+, 40+...) a partir da data de nascimento,
// usando a idade que a pessoa completa no ano corrente - convencao usual
// das categorias master de voleibol.
export function calcularCategoria(dataNascimento) {
  if (!dataNascimento) return null
  const nascimento = new Date(dataNascimento + 'T00:00:00')
  if (Number.isNaN(nascimento.getTime())) return null

  const anoAtual = new Date().getFullYear()
  const idade = anoAtual - nascimento.getFullYear()

  if (idade < 35) return 'Livre'
  if (idade < 40) return '35+'
  if (idade < 45) return '40+'
  if (idade < 50) return '45+'
  if (idade < 55) return '50+'
  if (idade < 60) return '55+'
  return '60+'
}

export function formatarData(dataIso) {
  if (!dataIso) return '—'
  const d = new Date(dataIso + 'T00:00:00')
  if (Number.isNaN(d.getTime())) return '—'
  return d.toLocaleDateString('pt-BR')
}
