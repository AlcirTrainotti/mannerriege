// Edge Function: criar-associado
//
// Cria um novo usuário no Supabase Auth usando a API administrativa
// (service role key), que permite e-mail opcional. A chamada pública
// de signUp exige e-mail válido — por isso usamos essa Edge Function
// como intermediária segura.
//
// A SUPABASE_SERVICE_ROLE_KEY é injetada automaticamente pelo Supabase
// em todas as Edge Functions do projeto — não precisa configurar nada.

import { createClient } from "npm:@supabase/supabase-js@2"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!

  // Verifica se quem está chamando é admin/financeiro do projeto,
  // usando o JWT do usuário logado no frontend.
  const authHeader = req.headers.get("Authorization")
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: "Não autorizado" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  const supabaseUser = createClient(supabaseUrl, serviceRoleKey)
  const { data: { user: caller }, error: authError } = await supabaseUser.auth.getUser(
    authHeader.replace("Bearer ", "")
  )

  if (authError || !caller) {
    return new Response(
      JSON.stringify({ error: "Sessão inválida" }),
      { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  // Confere se quem chama é admin no banco
  const { data: callerProfile } = await supabaseUser
    .from("profiles")
    .select("role")
    .eq("id", caller.id)
    .single()

  if (!callerProfile || callerProfile.role !== "admin") {
    return new Response(
      JSON.stringify({ error: "Somente administradores podem cadastrar associados" }),
      { status: 403, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  const { nome, telefone, senha, email } = await req.json()

  if (!nome || !telefone || !senha) {
    return new Response(
      JSON.stringify({ error: "Nome, telefone e senha são obrigatórios" }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey)

  // Monta o payload: e-mail só vai se for informado
  const payload: Record<string, unknown> = {
    password: senha,
    phone: telefone,
    email_confirm: true,
    user_metadata: { nome },
    app_metadata: {},
  }

  if (email && email.trim()) {
    payload.email = email.trim()
  }

  const { data, error } = await supabaseAdmin.auth.admin.createUser(payload)

  if (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  return new Response(
    JSON.stringify({ userId: data.user.id }),
    { headers: { ...corsHeaders, "Content-Type": "application/json" } }
  )
})
