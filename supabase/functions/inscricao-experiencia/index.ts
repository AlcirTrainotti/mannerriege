// Edge Function: inscricao-experiencia
//
// Recebe o formulário público de inscrição da "Experiência Mannerriege:
// A Nova Geração" (site em Astro, página /experiencia), grava na tabela
// public.inscricoes_experiencia_base (usando a service role, que
// ignora RLS — ver migration_061) e envia dois e-mails via Resend:
// um de confirmação para o responsável, outro de notificação para a
// diretoria.
//
// Controle automático de vagas: cada turma (masculino/feminino) tem 20
// vagas. A função conta quantas inscrições da turma já estão em um
// status que "segura" vaga (tudo exceto lista_espera/cancelada). Se já
// tiver 20, a nova inscrição entra direto como lista_espera.

import { createClient } from "npm:@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const DESTINATARIOS_DIRETORIA = ["alcir.trainotti@gmail.com", "rany041076@gmail.com"]
const VAGAS_POR_TURMA = 20
const STATUS_QUE_OCUPA_VAGA = [
  "recebida",
  "em_validacao",
  "confirmada",
  "presenca_confirmada",
  "compareceu",
  "matricula",
]

const CAMPOS_OBRIGATORIOS = [
  "responsavelNome",
  "responsavelWhatsapp",
  "responsavelEmail",
  "responsavelRelacao",
  "atletaNome",
  "atletaDataNascimento",
  "turma",
  "praticaVolei",
  "objetivo",
  "contatoEmergencia",
  "origem",
  "autorizacaoImagem",
] as const

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Método não permitido" }),
      { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  const body = await req.json().catch(() => ({}))

  const faltando = CAMPOS_OBRIGATORIOS.filter((campo) => !String(body[campo] ?? "").trim())
  if (faltando.length > 0 || !body.declaracaoCiencia || !body.autorizacaoDados) {
    return new Response(
      JSON.stringify({ error: "Preencha todos os campos obrigatórios e marque as duas declarações." }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  if (!["masculino", "feminino"].includes(body.turma)) {
    return new Response(
      JSON.stringify({ error: "Turma inválida." }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  const supabase = createClient(supabaseUrl, serviceRoleKey)

  // Conta quantas vagas da turma já estão ocupadas (qualquer status
  // exceto lista_espera/cancelada) para decidir se esta inscrição entra
  // direto ou vai para a lista de espera.
  const { count, error: countError } = await supabase
    .from("inscricoes_experiencia_base")
    .select("id", { count: "exact", head: true })
    .eq("turma", body.turma)
    .in("status", STATUS_QUE_OCUPA_VAGA)

  if (countError) {
    console.error("Erro ao contar vagas:", countError)
    return new Response(
      JSON.stringify({ error: "Não foi possível verificar as vagas agora. Tente novamente." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  const vagaDisponivel = (count ?? 0) < VAGAS_POR_TURMA
  const status = vagaDisponivel ? "recebida" : "lista_espera"

  const { error: insertError } = await supabase.from("inscricoes_experiencia_base").insert({
    responsavel_nome: body.responsavelNome,
    responsavel_whatsapp: body.responsavelWhatsapp,
    responsavel_email: body.responsavelEmail,
    responsavel_relacao: body.responsavelRelacao,
    atleta_nome: body.atletaNome,
    atleta_data_nascimento: body.atletaDataNascimento,
    turma: body.turma,
    pratica_volei: body.praticaVolei,
    pratica_detalhe: body.praticaDetalhe || null,
    objetivo: body.objetivo,
    objetivo_outro: body.objetivoOutro || null,
    condicao_saude: body.condicaoSaude || null,
    contato_emergencia: body.contatoEmergencia,
    origem: body.origem,
    origem_outro: body.origemOutro || null,
    declaracao_ciencia: true,
    autorizacao_dados: true,
    autorizacao_imagem: body.autorizacaoImagem,
    status,
  })

  if (insertError) {
    console.error("Erro ao gravar inscrição:", insertError)
    return new Response(
      JSON.stringify({ error: "Não foi possível registrar a inscrição agora. Tente novamente." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  // E-mails — não bloqueiam a resposta de sucesso se falharem, já que a
  // inscrição já foi gravada no banco (fonte da verdade).
  const resendApiKey = Deno.env.get("RESEND_API_KEY")
  if (resendApiKey) {
    const escapeHtml = (s: string) =>
      String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

    const turmaLabel = body.turma === "masculino" ? "Masculino — 17h00 às 18h30" : "Feminino — 13h30 às 15h00"

    const htmlResponsavel = vagaDisponivel
      ? `
        <h2>Inscrição recebida! 🏐</h2>
        <p>Olá, ${escapeHtml(body.responsavelNome)}!</p>
        <p>Recebemos a inscrição de <strong>${escapeHtml(body.atletaNome)}</strong> para a
        <strong>Experiência Mannerriege — A Nova Geração</strong>, turma <strong>${turmaLabel}</strong>,
        no dia 29/08.</p>
        <p>A vaga ainda será validada pela equipe do Mannerriege. Você vai receber uma mensagem no
        WhatsApp informado no formulário confirmando oficialmente sua participação.</p>
        <p>Salve nosso contato e acompanhe o Instagram <strong>@mannerriege</strong> para receber as
        novidades da Experiência.</p>
        <p style="color:#888;font-size:12px">Importante: a inscrição estará confirmada somente após o
        recebimento da mensagem oficial da organização.</p>
      `
      : `
        <h2>Inscrição recebida — lista de espera</h2>
        <p>Olá, ${escapeHtml(body.responsavelNome)}!</p>
        <p>Recebemos a inscrição de <strong>${escapeHtml(body.atletaNome)}</strong> para a
        <strong>Experiência Mannerriege — A Nova Geração</strong>, turma <strong>${turmaLabel}</strong>.</p>
        <p>As 20 vagas dessa turma já estão preenchidas, então a inscrição entrou na
        <strong>lista de espera</strong>. Se uma vaga abrir, a equipe do Mannerriege entra em contato
        pelo WhatsApp informado no formulário.</p>
      `

    await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${resendApiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        from: "Mannerriege <onboarding@resend.dev>",
        to: [body.responsavelEmail],
        subject: vagaDisponivel ? "Inscrição recebida — Experiência Mannerriege" : "Você está na lista de espera — Experiência Mannerriege",
        html: htmlResponsavel,
      }),
    }).catch((err) => console.error("Falha ao enviar e-mail ao responsável:", err))

    const linha = (label: string, valor: string) =>
      `<p><strong>${label}:</strong> ${escapeHtml(valor)}</p>`

    const htmlDiretoria = `
      <h2>Nova inscrição — Experiência Mannerriege: A Nova Geração</h2>
      ${linha("Status atribuído", status === "recebida" ? "Recebida (dentro das 20 vagas)" : "Lista de espera (turma lotada)")}
      ${linha("Turma", turmaLabel)}

      <h3>Atleta</h3>
      ${linha("Nome", body.atletaNome)}
      ${linha("Data de nascimento", body.atletaDataNascimento)}
      ${linha("Já pratica vôlei?", body.praticaVolei)}
      ${body.praticaDetalhe ? linha("Onde/há quanto tempo", body.praticaDetalhe) : ""}
      ${linha("O que deseja desenvolver", body.objetivo)}
      ${body.objetivoOutro ? linha("Objetivo (outro)", body.objetivoOutro) : ""}
      ${body.condicaoSaude ? linha("Condição de saúde / restrição", body.condicaoSaude) : ""}
      ${linha("Contato de emergência", body.contatoEmergencia)}

      <h3>Responsável</h3>
      ${linha("Nome", body.responsavelNome)}
      ${linha("Relação com o atleta", body.responsavelRelacao)}
      ${linha("WhatsApp", body.responsavelWhatsapp)}
      ${linha("E-mail", body.responsavelEmail)}

      <h3>Origem</h3>
      ${linha("Como conheceu", body.origem)}
      ${body.origemOutro ? linha("Origem (outro)", body.origemOutro) : ""}

      <h3>Autorização de imagem</h3>
      ${linha("Resposta", body.autorizacaoImagem === "autorizo" ? "Autorizo" : "Não autorizo")}

      <hr>
      <p style="color:#888;font-size:12px">Enviado pelo formulário /experiencia em mannerriege.com.br.
      Registro completo salvo na tabela inscricoes_experiencia_base do Supabase.</p>
    `

    await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: { Authorization: `Bearer ${resendApiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        from: "Mannerriege <onboarding@resend.dev>",
        to: DESTINATARIOS_DIRETORIA,
        subject: `Nova inscrição Experiência (${turmaLabel}): ${body.atletaNome}${status === "lista_espera" ? " [LISTA DE ESPERA]" : ""}`,
        html: htmlDiretoria,
      }),
    }).catch((err) => console.error("Falha ao enviar e-mail à diretoria:", err))
  } else {
    console.error("RESEND_API_KEY não configurada — inscrição gravada, mas nenhum e-mail foi enviado")
  }

  return new Response(
    JSON.stringify({ ok: true, status }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } }
  )
})
