import { supabase } from './supabase.js'

/**
 * Calcula o rateio por atleta de uma categoria, considerando despesas
 * extras rateadas (aumentam o valor) e receitas extras / verba / aportes
 * (diminuem o valor). Nunca fica negativo - se as receitas cobrirem tudo,
 * o rateio vira zero.
 */
export function calcularRateio(categoria, despesas, receitas, quantidadeAtletas) {
  if (quantidadeAtletas === 0) return 0
  const despesasRateadas = (despesas ?? [])
    .filter((d) => d.tipo === 'rateado')
    .reduce((s, d) => s + Number(d.valor || 0), 0)
  const totalReceitas = (receitas ?? []).reduce((s, r) => s + Number(r.valor || 0), 0)
  const total = Number(categoria.custo_inscricao || 0) + despesasRateadas - totalReceitas
  return Math.max(0, total / quantidadeAtletas)
}

export function statusPagamento(totalPago, rateio) {
  if (rateio <= 0) return 'sem_custo'
  if (totalPago >= rateio - 0.005) return 'pago'
  if (totalPago > 0) return 'parcial'
  return 'pendente'
}

/**
 * Busca o histórico de participações em campeonatos de um associado ou
 * convidado, com o valor do rateio de cada categoria e quanto já foi
 * pago - para saber quem costuma pagar direitinho e quem fica devendo.
 */
export async function buscarHistoricoParticipacoes(tipo, id) {
  const coluna = tipo === 'associado' ? 'associado_id' : 'convidado_id'

  const { data: participacoes } = await supabase
    .from('campeonato_participantes')
    .select('*')
    .eq('tipo', tipo)
    .eq(coluna, id)
    .eq('funcao', 'atleta')

  if (!participacoes || participacoes.length === 0) return []

  const categoriaIds = [...new Set(participacoes.map((p) => p.campeonato_categoria_id))]

  const [categoriasRes, todosParticipantesRes, despesasRes, receitasRes, pagamentosRes] = await Promise.all([
    supabase.from('campeonato_categorias').select('*').in('id', categoriaIds),
    supabase.from('campeonato_participantes').select('id, campeonato_categoria_id, funcao').in('campeonato_categoria_id', categoriaIds),
    supabase.from('campeonato_categoria_despesas').select('campeonato_categoria_id, valor, tipo').in('campeonato_categoria_id', categoriaIds),
    supabase.from('campeonato_categoria_receitas').select('campeonato_categoria_id, valor').in('campeonato_categoria_id', categoriaIds),
    supabase.from('campeonato_participante_pagamentos').select('campeonato_participante_id, valor').in('campeonato_participante_id', participacoes.map((p) => p.id)),
  ])

  const categorias = categoriasRes.data
  const todosParticipantes = todosParticipantesRes.data
  const despesas = despesasRes.data
  const receitas = receitasRes.data
  const pagamentos = pagamentosRes.data

  const campeonatoIds = [...new Set((categorias ?? []).map((c) => c.campeonato_id))]

  const { data: campeonatos } = await supabase
    .from('campeonatos')
    .select('id, nome, data_inicio')
    .in('id', campeonatoIds)

  return participacoes
    .map((p) => {
      const cat = (categorias ?? []).find((c) => c.id === p.campeonato_categoria_id)
      const camp = (campeonatos ?? []).find((c) => c.id === cat?.campeonato_id)
      const atletasDaCategoria = (todosParticipantes ?? []).filter(
        (x) => x.campeonato_categoria_id === p.campeonato_categoria_id && x.funcao === 'atleta'
      )
      const despesasCategoria = (despesas ?? []).filter((d) => d.campeonato_categoria_id === p.campeonato_categoria_id)
      const receitasCategoria = (receitas ?? []).filter((r) => r.campeonato_categoria_id === p.campeonato_categoria_id)
      const rateio = cat ? calcularRateio(cat, despesasCategoria, receitasCategoria, atletasDaCategoria.length) : 0
      const totalPago = (pagamentos ?? [])
        .filter((pg) => pg.campeonato_participante_id === p.id)
        .reduce((s, pg) => s + Number(pg.valor || 0), 0)

      return {
        campeonatoNome: camp?.nome ?? '—',
        dataInicio: camp?.data_inicio ?? null,
        categoria: cat?.categoria ?? '—',
        rateio,
        totalPago,
        status: statusPagamento(totalPago, rateio),
      }
    })
    .sort((a, b) => (b.dataInicio ?? '').localeCompare(a.dataInicio ?? ''))
}
