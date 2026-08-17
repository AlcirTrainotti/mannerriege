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
  { value: 'coordenador_esportivo', label: 'Coordenador Esportivo' },
  { value: 'tesoureiro', label: 'Tesoureiro' },
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

// Quando um associado e cadastrado sem e-mail, geramos um UUID so
// para o login funcionar. Essa funcao esconde esse e-mail interno
// da tela, mostrando null no lugar (UI exibe "sem e-mail cadastrado").
export function emailExibicao(email) {
  if (!email) return null
  if (email.endsWith('@sem-email.mannerriege.com.br')) return null
  if (email.endsWith('@sememail.mannerriege.com.br')) return null // legado
  return email
}
