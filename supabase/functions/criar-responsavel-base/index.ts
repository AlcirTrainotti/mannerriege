// Edge Function: criar-responsavel-base
//
// Cria o login do responsável no cadastro de atleta das Categorias de
// Base, usando a API administrativa (service role) em vez do signUp()
// público que o frontend usava antes. Dois bugs reais motivaram essa
// troca:
//
// 1. "email rate limit exceeded" / 429 no /auth/v1/signup — o signUp()
//    público dispara e-mail de confirmação e esbarra no limite padrão,
//    bem baixo, do provedor de e-mail do Supabase. A API administrativa
//    com email_confirm:true não manda e-mail nenhum, então não esbarra
//    nesse limite (mesma solução já usada em criar-associado).
// 2. "insert or update on table atleta_responsaveis violates foreign
//    key constraint" — quando o e-mail informado já pertencia a um
//    usuário existente, o signUp() público (com confirmação de e-mail
//    ligada no projeto) devolve um objeto de usuário "ofuscado" por
//    segurança (pra não vazar quais e-mails já estão cadastrados), cujo
//    id não corresponde a nenhuma linha real em auth.users/profiles —
//    o insert seguinte em atleta_responsaveis quebrava por causa disso.
//    A API administrativa nunca faz isso: ou cria de verdade, ou
//    devolve um erro nítido de "já cadastrado", que esta função trata
//    reaproveitando o cadastro existente.
//
// A SUPABASE_SERVICE_ROLE_KEY é injetada automaticamente pelo Supabase
// em todas as Edge Functions do projeto — não precisa configurar nada.

import { createClient } from "npm:@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}

function normalizaTelefone(t: string | null) {
  return (t ?? "").replace(/\D/g, "")
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!

  const authHeader = req.headers.get("Authorization")
  if (!authHeader) return jsonResponse({ error: "Não autorizado" }, 401)

  const supabaseCaller = createClient(supabaseUrl, serviceRoleKey)
  const { data: { user: caller }, error: authError } = await supabaseCaller.auth.getUser(
    authHeader.replace("Bearer ", "")
  )
  if (authError || !caller) return jsonResponse({ error: "Sessão inválida" }, 401)

  const { data: callerProfile } = await supabaseCaller
    .from("profiles")
    .select("role")
    .eq("id", caller.id)
    .single()
  const callerIsEquipeBase = callerProfile?.role && ["admin", "professor_base", "coordenador_base"].includes(callerProfile.role)
  if (!callerIsEquipeBase) {
    return jsonResponse({ error: "Somente a equipe das Categorias de Base pode cadastrar responsáveis" }, 403)
  }

  const { nome, telefone, senha, email } = await req.json()
  if (!nome || !telefone || !senha) {
    return jsonResponse({ error: "Nome, telefone e senha são obrigatórios" }, 400)
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey)

  // Rede de segurança: confere de novo (agora com telefone normalizado,
  // só dígitos) se já existe um responsável com esse contato — evita
  // duplicar mesmo que a checagem do frontend não tenha pego a tempo.
  const telefoneDigits = normalizaTelefone(telefone)
  const { data: existentes } = await supabaseAdmin
    .from("profiles")
    .select("id, nome, telefone, email")
    .eq("role", "responsavel_base")
  const jaExiste = (existentes ?? []).find((p) =>
    (telefoneDigits && normalizaTelefone(p.telefone) === telefoneDigits) ||
    (email && p.email && p.email.toLowerCase() === String(email).toLowerCase())
  )
  if (jaExiste) {
    return jsonResponse({ userId: jaExiste.id, reaproveitado: true })
  }

  const payload: Record<string, unknown> = {
    password: senha,
    email_confirm: true,
    user_metadata: { nome },
  }
  payload.email = (email && String(email).trim()) || `${telefoneDigits}@sememail.mannerriege.com.br`

  const { data, error } = await supabaseAdmin.auth.admin.createUser(payload)

  if (error) {
    // E-mail já cadastrado só que não é responsavel_base ainda (ex: era
    // associado do Master) — busca o profile por e-mail e reaproveita.
    const msg = (error.message || "").toLowerCase()
    if (msg.includes("already been registered") || msg.includes("already registered") || msg.includes("já cadastrado")) {
      const { data: porEmail } = await supabaseAdmin
        .from("profiles")
        .select("id")
        .eq("email", String(payload.email).toLowerCase())
        .maybeSingle()
      if (porEmail?.id) {
        await supabaseAdmin.from("profiles").update({ telefone, role: "responsavel_base" }).eq("id", porEmail.id)
        return jsonResponse({ userId: porEmail.id, reaproveitado: true })
      }
    }
    return jsonResponse({ error: error.message }, 400)
  }

  const userId = data.user.id
  await supabaseAdmin.from("profiles").update({ telefone, role: "responsavel_base" }).eq("id", userId)

  return jsonResponse({ userId })
})
