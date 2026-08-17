// Edge Function: fale-conosco
//
// Recebe o formulário público de "Fale conosco" (site institucional em
// Astro, página /contato) e envia um e-mail de notificação para os
// responsáveis do clube via Resend (https://resend.com).
//
// Assim como as demais funções públicas do site (interesse-associado,
// matricula-base, interesse-apoio), esta função não exige login e não
// grava nada no banco — apenas repassa a mensagem por e-mail.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const DESTINATARIOS = ["alcir.trainotti@gmail.com", "rany041076@gmail.com"]

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

  const { nome, email, telefone, mensagem } = await req.json().catch(() => ({}))

  if (!nome?.trim() || !email?.trim() || !telefone?.trim() || !mensagem?.trim()) {
    return new Response(
      JSON.stringify({ error: "Preencha todos os campos: nome, e-mail, telefone e mensagem." }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  const resendApiKey = Deno.env.get("RESEND_API_KEY")
  if (!resendApiKey) {
    console.error("RESEND_API_KEY não configurada nos Secrets do projeto Supabase")
    return new Response(
      JSON.stringify({ error: "Envio de e-mail não configurado. Avise o administrador do site." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  const escapeHtml = (s: string) =>
    s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")

  const html = `
    <h2>Nova mensagem — Fale conosco Mannerriege</h2>
    <p><strong>Nome:</strong> ${escapeHtml(nome)}</p>
    <p><strong>E-mail:</strong> ${escapeHtml(email)}</p>
    <p><strong>Telefone / WhatsApp:</strong> ${escapeHtml(telefone)}</p>
    <p><strong>Mensagem:</strong></p>
    <p>${escapeHtml(mensagem).replace(/\n/g, "<br>")}</p>
    <hr>
    <p style="color:#888;font-size:12px">Enviado pelo formulário "Fale conosco" em mannerriege.com.br/contato</p>
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
      subject: `Nova mensagem de contato: ${nome}`,
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
