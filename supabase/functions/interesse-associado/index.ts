// Edge Function: interesse-associado
//
// Recebe o formulário público de "Quero ser associado" do site
// institucional (Astro) e envia um e-mail de notificação para os
// responsáveis do clube via Resend (https://resend.com).
//
// Diferente de criar-associado, esta função é PÚBLICA — qualquer
// visitante do site pode chamar, sem login. Não grava nada no banco,
// só notifica por e-mail; o cadastro efetivo do associado continua
// sendo feito manualmente pela diretoria depois do contato.

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

  const { nome, telefone, dataNascimento, posicao, relato } = await req.json().catch(() => ({}))

  if (!nome?.trim() || !telefone?.trim() || !dataNascimento?.trim() || !posicao?.trim() || !relato?.trim()) {
    return new Response(
      JSON.stringify({ error: "Preencha todos os campos: nome, telefone, data de nascimento, posição e relato." }),
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
    <h2>Novo interesse em ser associado — Mannerriege</h2>
    <p><strong>Nome completo:</strong> ${escapeHtml(nome)}</p>
    <p><strong>Telefone / WhatsApp:</strong> ${escapeHtml(telefone)}</p>
    <p><strong>Data de nascimento:</strong> ${escapeHtml(dataNascimento)}</p>
    <p><strong>Posição que joga:</strong> ${escapeHtml(posicao)}</p>
    <p><strong>Relato (onde já jogou):</strong></p>
    <p>${escapeHtml(relato).replace(/\n/g, "<br>")}</p>
    <hr>
    <p style="color:#888;font-size:12px">Enviado pelo formulário "Quero ser associado" em mannerriege.com.br</p>
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
      subject: `Novo interesse em se associar: ${nome}`,
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
