// Edge Function: resumir-regulamento
//
// Recebe a URL pública de um regulamento em PDF (já enviado ao Storage)
// e devolve um resumo gerado por IA (Claude), em português, com os
// pontos principais para os associados consultarem rapidamente.
//
// A chave da API (ANTHROPIC_API_KEY) fica guardada como "secret" no
// Supabase - nunca é exposta ao navegador. Veja o passo a passo de
// configuracao em supabase/COMO_CONFIGURAR_RESUMO_IA.md

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

function arrayBufferParaBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer)
  let binary = ""
  const tamanhoBloco = 0x8000
  for (let i = 0; i < bytes.length; i += tamanhoBloco) {
    binary += String.fromCharCode(...bytes.subarray(i, i + tamanhoBloco))
  }
  return btoa(binary)
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders })
  }

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY")
  if (!apiKey) {
    return new Response(
      JSON.stringify({ error: "ANTHROPIC_API_KEY não configurada nos secrets da Edge Function" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }

  try {
    const { regulamentoUrl } = await req.json()
    if (!regulamentoUrl) {
      return new Response(
        JSON.stringify({ error: "Informe regulamentoUrl" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const pdfRes = await fetch(regulamentoUrl)
    if (!pdfRes.ok) {
      return new Response(
        JSON.stringify({ error: "Não foi possível baixar o PDF do regulamento" }),
        { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }
    const pdfBuffer = await pdfRes.arrayBuffer()

    if (pdfBuffer.byteLength > 30 * 1024 * 1024) {
      return new Response(
        JSON.stringify({ error: "PDF muito grande para resumir automaticamente (máximo 30 MB)" }),
        { status: 422, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const base64 = arrayBufferParaBase64(pdfBuffer)

    const claudeRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 900,
        messages: [
          {
            role: "user",
            content: [
              { type: "document", source: { type: "base64", media_type: "application/pdf", data: base64 } },
              {
                type: "text",
                text: "Resuma este regulamento de campeonato de vôlei em português, em até 8 tópicos curtos " +
                  "(formato de disputa, regras de categoria, premiação, horários gerais e outros pontos " +
                  "importantes para os atletas saberem rapidamente sem ler o documento inteiro). Formate a " +
                  "resposta em Markdown: use \"## \" para um ou dois títulos de seção se fizer sentido, e \"- \" " +
                  "para cada item de lista. Seja direto, sem introdução nem conclusão.",
              },
            ],
          },
        ],
      }),
    })

    if (!claudeRes.ok) {
      const texto = await claudeRes.text()
      return new Response(
        JSON.stringify({ error: "Falha ao gerar o resumo: " + texto }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    const claudeData = await claudeRes.json()
    const blocoTexto = (claudeData?.content ?? []).find((c: { type: string }) => c.type === "text")
    const resumo = blocoTexto?.text ?? ""

    if (!resumo) {
      return new Response(
        JSON.stringify({ error: "A IA não retornou nenhum resumo" }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      )
    }

    return new Response(JSON.stringify({ resumo }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    })
  } catch (err) {
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    )
  }
})
