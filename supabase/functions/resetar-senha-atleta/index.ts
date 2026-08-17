// Edge Function: resetar-senha-atleta
//
// A criação do login do responsável e do login (só leitura) do atleta
// acontece direto no frontend, com um cliente Supabase temporário e
// isolado (mesmo padrão já usado em AdminAssociados.vue pra cadastrar
// associado sem deslogar quem está fazendo o cadastro) — não precisa
// de Edge Function pra isso.
//
// Trocar a senha de OUTRA pessoa (o responsável trocando a senha do
// login do próprio filho) é a única parte que exige privilégio de
// admin do Supabase Auth (service role), porque um usuário comum só
// pode trocar a própria senha. Por isso essa é a única ação que esta
// função cobre.
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

  const { atletaId, senha } = await req.json()
  if (!atletaId || !senha) {
    return jsonResponse({ error: "atletaId e senha são obrigatórios" }, 400)
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey)

  let autorizado = callerIsEquipeBase
  if (!autorizado) {
    const { data } = await supabaseAdmin
      .from("atleta_responsaveis")
      .select("id")
      .eq("atleta_id", atletaId)
      .eq("responsavel_id", caller.id)
      .maybeSingle()
    autorizado = !!data
  }
  if (!autorizado) {
    return jsonResponse({ error: "Somente o responsável pelo atleta (ou a equipe) pode trocar essa senha" }, 403)
  }

  const { data: atleta, error: atletaError } = await supabaseAdmin
    .from("atletas_base")
    .select("profile_id")
    .eq("id", atletaId)
    .single()

  if (atletaError || !atleta?.profile_id) {
    return jsonResponse({ error: "Este atleta ainda não tem login criado" }, 400)
  }

  const { error } = await supabaseAdmin.auth.admin.updateUserById(atleta.profile_id, { password: senha })
  if (error) return jsonResponse({ error: error.message }, 400)

  return jsonResponse({ ok: true })
})
