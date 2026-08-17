// Edge Function: interesse-apoio
//
// Recebe o formulário público de "Apoie o projeto" (site institucional
// em Astro, página /apoie) e envia um e-mail de notificação para os
// responsáveis do clube via Resend (https://resend.com).
//
// Assim como interesse-associado e matricula-base, esta função é
// PÚBLICA — qualquer visitante pode chamar, sem login. Não grava nada
// no banco, só notifica por e-mail. A conversa sobre valores e cotas de
// patrocínio acontece depois, diretamente com a diretoria — de
// propósito, esse formulário não pede nem mostra valores.

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

  const { nome, email, telefone } = await req.json().catch(() => ({}))

  if (!nome?.trim() || !email?.trim() || !telefone?.trim()) {
    return new Response(
      JSON.stringify({ error: "Preencha todos os campos: nome, e-mail e telefone." }),
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
    <h2>Novo interesse em apoiar o projeto — Mannerriege</h2>
    <p><strong>Nome:</strong> ${escapeHtml(nome)}</p>
    <p><strong>E-mail:</strong> ${escapeHtml(email)}</p>
    <p><strong>Telefone / WhatsApp:</strong> ${escapeHtml(telefone)}</p>
    <hr>
    <p style="color:#888;font-size:12px">Enviado pelo formulário "Apoie o projeto" em mannerriege.com.br/apoie</p>
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
      subject: `Novo interesse em apoiar o projeto: ${nome}`,
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
