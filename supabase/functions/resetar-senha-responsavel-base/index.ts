// Edge Function: resetar-senha-responsavel-base
//
// A equipe das Categorias de Base (professor/coordenador/admin) precisa
// poder trocar a senha do responsável direto na tela de edição do
// atleta (ex: responsável esqueceu a senha). Trocar a senha de OUTRA
// pessoa exige privilégio de admin do Supabase Auth (service role),
// por isso essa ação precisa passar por uma Edge Function — mesmo
// padrão já usado em resetar-senha-atleta.
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

  if (!callerIsEquipeBase) {
    return jsonResponse({ error: "Somente a equipe das Categorias de Base pode trocar essa senha" }, 403)
  }

  const { responsavelId, senha } = await req.json()
  if (!responsavelId || !senha) {
    return jsonResponse({ error: "responsavelId e senha são obrigatórios" }, 400)
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey)

  // Confere que o alvo é mesmo um responsável de algum atleta da base
  // (evita usar essa função pra mexer na senha de qualquer perfil).
  const { data: vinculo } = await supabaseAdmin
    .from("atleta_responsaveis")
    .select("id")
    .eq("responsavel_id", responsavelId)
    .limit(1)
    .maybeSingle()
  if (!vinculo) {
    return jsonResponse({ error: "Esse perfil não é responsável de nenhum atleta da base" }, 400)
  }

  const { error } = await supabaseAdmin.auth.admin.updateUserById(responsavelId, { password: senha })
  if (error) return jsonResponse({ error: error.message }, 400)

  return jsonResponse({ ok: true })
})
