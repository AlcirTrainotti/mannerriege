import { supabase } from './supabase.js'

function normalizarPar(a, b) {
  const x = a.trim()
  const y = b.trim()
  return x <= y ? [x, y] : [y, x]
}

/**
 * Retorna o tempo de deslocamento (em minutos) entre dois enderecos.
 * Usa um cache no banco para nao chamar a API de novo a cada checagem.
 * O calculo em si roda numa Edge Function do Supabase (calcular-deslocamento),
 * que usa a API gratuita do OpenRouteService com a chave guardada em segredo
 * no servidor - o navegador nunca tem acesso a ela.
 * Retorna null se nao for possivel calcular (funcao nao configurada,
 * endereco nao encontrado, etc).
 */
export async function obterTempoDeslocamento(enderecoA, enderecoB) {
  if (!enderecoA || !enderecoB) return null
  if (enderecoA.trim().toLowerCase() === enderecoB.trim().toLowerCase()) return 0

  const [ea, eb] = normalizarPar(enderecoA, enderecoB)

  const { data: cache } = await supabase
    .from('ginasio_distancias')
    .select('duracao_minutos')
    .eq('endereco_a', ea)
    .eq('endereco_b', eb)
    .maybeSingle()

  if (cache) return cache.duracao_minutos

  const { data, error } = await supabase.functions.invoke('calcular-deslocamento', {
    body: { enderecoA, enderecoB },
  })

  if (error || !data?.minutos) return null

  await supabase.from('ginasio_distancias').insert({
    endereco_a: ea,
    endereco_b: eb,
    duracao_minutos: data.minutos,
  })

  return data.minutos
}
