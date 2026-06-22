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

// Quando um associado e cadastrado sem e-mail, geramos um a partir do
// telefone so para o login funcionar. Essa funcao esconde esse e-mail
// "de mentira" da tela, mostrando "sem e-mail cadastrado" no lugar.
export function emailExibicao(email) {
  if (!email || email.endsWith('@sememail.mannerriege.com.br')) return null
  return email
}
