// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const aiApiKey = Deno.env.get("GROQ_API_KEY") ?? Deno.env.get("OPENROUTER_API_KEY") ?? "";
const configuredModel = Deno.env.get("GROQ_MODEL_FLUTTER") ?? Deno.env.get("GROQ_MODEL") ?? "";
const aiBaseUrl = Deno.env.get("AI_BASE_URL") ?? "https://api.groq.com/openai/v1";

// Auto fallback candidate models if any model is deprecated by Groq
const candidateModels = [
  configuredModel,
  "qwen/qwen3.8-27b",
  "openai/gpt-oss-120b",
  "openai/gpt-oss-20b",
  "groq/compound-mini",
].filter(Boolean);

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { ocrText } = await req.json();

    if (!ocrText || typeof ocrText !== "string" || !ocrText.trim()) {
      return new Response(
        JSON.stringify({ error: "Teks OCR struk tidak boleh kosong." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (!aiApiKey) {
      return new Response(
        JSON.stringify({ error: "GROQ_API_KEY belum dikonfigurasi di Supabase Edge Function secrets." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let parsedResult = null;
    let lastError = null;

    // Loop through candidate models until one succeeds
    for (const model of candidateModels) {
      try {
        console.log(`Trying AI model: ${model}`);
        const response = await fetch(`${aiBaseUrl}/chat/completions`, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${aiApiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: model,
            max_tokens: 1000,
            messages: [
              {
                role: "system",
                content: "You are a receipt parser. Return only valid JSON. No markdown. No explanation.",
              },
              {
                role: "user",
                content: `Analyze this receipt OCR text.

Return ONLY valid JSON in this exact structure:
{
  "store": "Store name",
  "date": "YYYY-MM-DD",
  "total": 0,
  "suggestedCategory": "Category",
  "items": [
    {
      "name": "item",
      "price": 0,
      "quantity": 1
    }
  ],
  "type": "expense"
}

Rules:
- Return JSON only.
- Do not wrap JSON in markdown.
- The "total" must be the final grand total.
- Ignore cash/tunai, paid amount, change/kembali, subtotal, tax if grand total exists.
- If there are multiple totals, choose the final amount the customer paid.
- If the year is visible, use that year.
- If no year is visible, use the current year.
- Date format must be YYYY-MM-DD.
- Total and item prices must be numbers only.
- suggestedCategory should be one of: Makanan, Transportasi, Belanja, Tagihan, Hiburan, Kesehatan, Pendidikan, Lainnya.
- type must be "expense".
- Store must be the real merchant/store name, not POS, cashier, waiter, order id, or receipt number.
- If items are unclear, return an empty items array.

OCR Text:
${ocrText}`,
              },
            ],
          }),
        });

        if (!response.ok) {
          const errData = await response.json().catch(() => ({}));
          const errMsg = errData?.error?.message || `HTTP ${response.status}`;
          console.warn(`Model ${model} failed: ${errMsg}`);
          lastError = errMsg;
          continue; // Try next model
        }

        const data = await response.json();
        const responseText = data?.choices?.[0]?.message?.content?.toString() ?? "";
        const cleanJsonStr = responseText.trim();
        const firstBrace = cleanJsonStr.indexOf("{");
        const lastBrace = cleanJsonStr.lastIndexOf("}");

        if (firstBrace === -1 || lastBrace === -1 || lastBrace < firstBrace) {
          throw new Error(`Format respons AI tidak valid: ${responseText}`);
        }

        parsedResult = JSON.parse(cleanJsonStr.substring(firstBrace, lastBrace + 1));
        console.log(`Successfully parsed receipt using model ${model}`);
        break; // Success!
      } catch (err) {
        console.warn(`Error with model ${model}:`, err);
        lastError = err.message || String(err);
      }
    }

    if (!parsedResult) {
      return new Response(
        JSON.stringify({ error: `Gagal memproses struk dengan AI: ${lastError}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(JSON.stringify(parsedResult), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message || "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
