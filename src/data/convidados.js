export const posicaoOptions = [
  { value: 'ponteiro', label: 'Ponteiro' },
  { value: 'libero', label: 'Líbero' },
  { value: 'levantador', label: 'Levantador' },
  { value: 'meio', label: 'Meio' },
  { value: 'oposto', label: 'Oposto' },
  { value: 'tecnico', label: 'Técnico' },
  { value: 'outro', label: 'Outro' },
]

export function posicaoLabel(value) {
  return posicaoOptions.find((p) => p.value === value)?.label ?? value ?? '—'
}
