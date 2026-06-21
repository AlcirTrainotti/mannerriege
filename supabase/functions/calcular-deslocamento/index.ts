// Edge Function: calcular-deslocamento
//
// Recebe dois enderecos e devolve o tempo estimado de carro entre eles,
// em minutos, usando a API gratuita do OpenRouteService (openrouteservice.org).
//
// A chave da API (ORS_API_KEY) fica guardada como "secret" no Supabase -
// nunca e exposta ao navegador. Veja o passo a passo de configuracao em
// supabase/COMO_CONFIGURAR_DESLOCAMENTO.md

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

async function geocodificar(endereco: string, apiKey: string) {
  const url = `https://api.openrouteservice.org/geocode/search?api_key=${apiKey}&text=${encodeURIComponent(endereco)}&size=1&boundary.country=BR`
  const res = await fetch(url)
  if (!res.ok) return null
  const data = await res.json()
  const coords = data?.features?.[0]?.geometry?.coordinates
  return coords ?? null // [longitude, latitude]
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  const apiKey = Deno.env.get("ORS_API_KEY")
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: "ORS_API_KEY não configurada nos secrets da Edge Function" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  try {
    const { enderecoA, enderecoB } = await req.json()
    if (!enderecoA || !enderecoB) {
      return new Response(
        JSON.stringify({ error: "Informe enderecoA e enderecoB" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const [coordA, coordB] = await Promise.all([
      geocodificar(enderecoA, apiKey),
      geocodificar(enderecoB, apiKey),
    ])

    if (!coordA || !coordB) {
      return new Response(
        JSON.stringify({ error: "Não foi possível localizar um dos endereços informados" }),
        { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const matrixRes = await fetch("https://api.openrouteservice.org/v2/matrix/driving-car", {
      method: "POST",
      headers: {
        Authorization: apiKey,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        locations: [coordA, coordB],
        metrics: ["duration"],
      }),
    })

    if (!matrixRes.ok) {
      const texto = await matrixRes.text()
      return new Response(
        JSON.stringify({ error: "Falha ao calcular a rota: " + texto }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const matrixData = await matrixRes.json()
    const segundos = matrixData?.durations?.[0]?.[1]

    if (segundos == null) {
      return new Response(
        JSON.stringify({ error: "Não foi possível calcular a rota entre os endereços" }),
        { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const minutos = Math.round(segundos / 60)

    return new Response(JSON.stringify({ minutos }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
