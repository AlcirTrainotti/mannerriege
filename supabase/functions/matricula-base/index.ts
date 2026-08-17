// Edge Function: matricula-base
//
// Recebe o formulário público de "Quero matricular" do Vôlei de Base
// (site institucional em Astro, página /base/matricula) e envia um
// e-mail de notificação para os responsáveis do clube via Resend
// (https://resend.com).
//
// Assim como interesse-associado, esta função é PÚBLICA — qualquer
// visitante pode chamar, sem login. Não grava nada no banco, só
// notifica por e-mail; a matrícula efetiva é conduzida manualmente
// pela coordenação depois do contato.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const DESTINATARIOS = ["alcir.trainotti@gmail.com", "rany041076@gmail.com"]

const CAMPOS_OBRIGATORIOS = [
  "nome",
  "dataNascimento",
  "documento",
  "endereco",
  "telefone",
  "email",
  "experiencia",
  "posicao",
  "altura",
  "nomePai",
  "nomeMae",
  "escola",
  "serie",
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
  if (faltando.length > 0) {
    return new Response(
      JSON.stringify({ error: "Preencha todos os campos obrigatórios do formulário." }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  const {
    nome, dataNascimento, documento, endereco, telefone, email,
    experiencia, posicao, altura, nomePai, nomeMae, escola, serie,
  } = body

  const resendApiKey = Deno.env.get("RESEND_API_KEY")
  if (!resendApiKey) {
    console.error("RESEND_API_KEY não configurada nos Secrets do projeto Supabase")
    return new Response(
      JSON.stringify({ error: "Envio de e-mail não configurado. Avise o administrador do site." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  const escapeHtml = (s: string) =>
    String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

  const linha = (label: string, valor: string) =>
    `<p><strong>${label}:</strong> ${escapeHtml(valor)}</p>`

  const html = `
    <h2>Nova matrícula — Vôlei de Base Mannerriege</h2>

    <h3>Atleta</h3>
    ${linha("Nome completo", nome)}
    ${linha("Data de nascimento", dataNascimento)}
    ${linha("RG e/ou CPF", documento)}
    ${linha("Endereço residencial", endereco)}
    ${linha("Altura", `${altura} cm`)}
    ${linha("Já jogou vôlei antes?", experiencia)}
    ${linha("Posição que joga / gostaria de jogar", posicao)}

    <h3>Contato</h3>
    ${linha("Telefone / WhatsApp", telefone)}
    ${linha("E-mail", email)}

    <h3>Responsáveis</h3>
    ${linha("Nome do pai", nomePai)}
    ${linha("Nome da mãe", nomeMae)}

    <h3>Escola</h3>
    ${linha("Escola que estuda", escola)}
    ${linha("Série", serie)}

    <hr>
    <p style="color:#888;font-size:12px">Enviado pelo formulário "Quero matricular" em mannerriege.com.br/base/matricula</p>
  `

  const resendRes = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "Mannerriege <naoresponder@mannerriege.com.br>",
      to: DESTINATARIOS,
      subject: `Nova matrícula Vôlei de Base: ${nome}`,
      html,
    }),
  })

  if (!resendRes.ok) {
    const errBody = await resendRes.text()
    console.error("Falha ao enviar via Resend:", resendRes.status, errBody)
    return new Response(
      JSON.stringify({ error: "Não foi possível enviar o e-mail agora. Tente novamente em instantes." }),
      { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  return new Response(
    JSON.stringify({ ok: true }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } }
  )
})
