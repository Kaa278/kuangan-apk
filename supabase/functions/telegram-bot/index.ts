// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

// Ensure CUI2 is imported
import { createId } from "https://esm.sh/@paralleldrive/cuid2@2.2.2";

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const telegramToken = Deno.env.get("TELEGRAM_BOT_TOKEN") ?? "";
const aiApiKey = Deno.env.get("GROQ_API_KEY") ?? Deno.env.get("OPENROUTER_API_KEY") ?? "";
const textModel = Deno.env.get("GROQ_MODEL_TELEGRAM_TEXT") ?? Deno.env.get("OPENROUTER_MODEL") ?? "qwen/qwen3.8-27b";
const visionModel = Deno.env.get("GROQ_MODEL_TELEGRAM_VISION") ?? "qwen/qwen3.8-27b";
const flutterModel = Deno.env.get("GROQ_MODEL_FLUTTER") ?? "qwen/qwen3.8-27b";
const aiBaseUrl = Deno.env.get("AI_BASE_URL") ?? "https://api.groq.com/openai/v1";

console.log(`Kathlyn Edge Function initialized. Text Model: ${textModel}, Vision Model: ${visionModel}, Flutter Model: ${flutterModel}, BaseUrl: ${aiBaseUrl}`);

const supabase = createClient(supabaseUrl, supabaseAnonKey);
const receiptSchema = {
  type: "object",
  properties: {
    store: { type: "string" },
    date: { type: "string" },
    total: { type: "number" },
    suggestedCategory: { type: "string" },
    items: {
      type: "array",
      items: {
        type: "object",
        properties: {
          name: { type: "string" },
          price: { type: "number" },
          quantity: { type: "number" }
        },
        required: ["name", "price", "quantity"],
        additionalProperties: false
      }
    },
    type: { type: "string" }
  },
  required: ["store", "date", "total", "suggestedCategory", "items", "type"],
  additionalProperties: false
};

function extractResponseText(data: any): string {
  const directText = data?.output_text;
  if (typeof directText === "string" && directText.trim()) return directText;

  const contentText = data?.output?.flatMap((entry: any) => entry?.content ?? [])
    ?.map((item: any) => item?.text)
    ?.filter(Boolean)
    ?.join("\n");
  if (typeof contentText === "string" && contentText.trim()) return contentText;

  const messageText = data?.choices?.[0]?.message?.content;
  if (typeof messageText === "string" && messageText.trim()) return messageText;

  return "";
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  const chunkSize = 0x8000;
  let binary = "";

  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, i + chunkSize);
    binary += String.fromCharCode(...chunk);
  }

  return btoa(binary);
}

function escapeMarkdown(text: string = ""): string {
  return text.replace(/([_*`\[])/g, "\\$1");
}

function buildPreviewMessage({
  amount,
  date,
  note,
  category,
  wallet,
  isIncome,
}: {
  amount: number;
  date: Date;
  note: string;
  category: string;
  wallet: string;
  isIncome: boolean;
}) {
  const formattedAmount = new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
  }).format(amount);
  const formattedDate = new Intl.DateTimeFormat('id-ID', {
    dateStyle: 'long',
  }).format(date);
  const title = isIncome ? "Konfirmasi Pemasukan" : "Konfirmasi Pengeluaran";
  const isoDate = date.toISOString().split("T")[0];
  const type = isIncome ? "income" : "expense";

  return `📝 **${title}**\n\n💰 Jumlah: ${escapeMarkdown(formattedAmount)}\n📅 Tanggal: ${escapeMarkdown(formattedDate)}\n📝 Ket: ${escapeMarkdown(note || '-')}\n📂 Kat: ${escapeMarkdown(category)}\n💳 Dompet: ${escapeMarkdown(wallet)}\n🔖 Ref: ${escapeMarkdown(`${isoDate}|${type}`)}\n\n_Pastikan data sudah benar, lalu klik tombol di bawah._`;
}

function parseConfirmationMessage(text: string) {
  const normalized = text
    .replace(/\\/g, "")
    .replace(/\*\*/g, "")
    .replace(/\r/g, "");
  const amountMatch = normalized.match(/💰 Jumlah:\s*Rp\s*([\d.]+)/);
  const noteMatch = normalized.match(/📝 Ket:\s*(.+)/);
  const categoryMatch = normalized.match(/📂 Kat:\s*(.+)/);
  const walletMatch = normalized.match(/💳 Dompet:\s*(.+)/);
  const refMatch = normalized.match(/🔖 Ref:\s*([0-9-]+)\|(income|expense)/);

  if (!amountMatch || !categoryMatch || !walletMatch || !refMatch) {
    return null;
  }

  const amount = Number(amountMatch[1].replace(/\./g, ""));
  const parsedDate = new Date(`${refMatch[1]}T12:00:00.000Z`);

  if (Number.isNaN(amount) || Number.isNaN(parsedDate.getTime())) {
    return null;
  }

  return {
    amount,
    date: parsedDate,
    note: (noteMatch?.[1] ?? "-").trim(),
    category: categoryMatch[1].trim(),
    wallet: walletMatch[1].trim(),
    type: refMatch[2],
  };
}

async function sendMessage(chatId: number | string, text: string, replyMarkup?: any) {
  const payload: any = {
    chat_id: chatId,
    text: text.replace(/\\n/g, "\n"),
    parse_mode: "Markdown"
  };
  if (replyMarkup) {
    payload.reply_markup = replyMarkup;
  }
  const res = await fetch(`https://api.telegram.org/bot${telegramToken}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
  const data = await res.json();
  return data?.result?.message_id;
}

async function editMessageText(chatId: number | string, messageId: number, text: string, replyMarkup?: any) {
  const payload: any = {
    chat_id: chatId,
    message_id: messageId,
    text: text.replace(/\\n/g, "\n"),
    parse_mode: "Markdown"
  };
  if (replyMarkup) payload.reply_markup = replyMarkup;
  await fetch(`https://api.telegram.org/bot${telegramToken}/editMessageText`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
}

async function parseTextWithAI(text: string, userContext: string = "") {
  const prompt = `You are Kathlyn, a friendly and smart financial assistant for the app KuAngan.
Your personality: Helpful, supportive, insightful, and slightly informal. Use "Aku" (you) and "Kamu" (user).
If the user is happy, be happy with them. If they are overspending, give a gentle reminder or a "Hemat Tip".

User Context:
${userContext}

Analyze the user's message and determine the "intent":
1. "record_transaction": Log income/expense (e.g., "Makan 20rb", "Gaji 5jt").
2. "query_balance": Asking for wallet balance.
3. "query_summary": Asking for summary or breakdown of income/expense (e.g., "rekap hari ini", "pemasukan bulan ini", "pengeluaran minggu ini").
4. "general_chat": Chatting, asking for advice, or anything else.

For "general_chat", provide a warm, human-like response in "content". 
If the user asks for tips, give practical Indonesian-related financial advice.
If they just say hello, greet them by name if known from context.

CRITICAL RULES FOR "total" IN "record_transaction":
- Calculate the exact amount based on common Indonesian multipliers.
- 'k' or 'rb' or 'ribu' = multiply by 1,000 (e.g., "1k" = 1000, "15rb" = 15000)
- 'jt' or 'juta' = multiply by 1,000,000 (e.g., "5jt" = 5000000)
- Never assume formatting like '1k' means 100,000. 1k is always 1,000.

Return ONLY JSON:
{
  "intent": "record_transaction" | "query_balance" | "query_summary" | "general_chat",
  "data": { "store": string, "date": "YYYY-MM-DD", "total": number, "suggestedCategory": string, "type": "income" | "expense", "period": "today" | "this_week" | "this_month" | "all" },
  "content": "Warm conversational response for general_chat"
}`;

  const res = await fetch(`${aiBaseUrl}/chat/completions`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${aiApiKey}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://kuangan.app",
    },
    body: JSON.stringify({
      model: textModel,
      max_tokens: 512,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: prompt },
        { role: "user", content: text }
      ]
    })
  });

  const data = await res.json();
  if (!res.ok) {
    console.error("AI API Error (Text):", data);
    return { _error: data?.error?.message || "AI API Error" };
  }
  const content = data?.choices?.[0]?.message?.content ?? "";
  const parsed = extractJson(content);

  // If AI failed to return valid JSON but returned text, treat as general_chat
  if (!parsed && content) {
    return { intent: "general_chat", content: content };
  }
  return parsed;
}

async function parseImageWithAI(fileId: string, caption: string, categoryList: string = "") {
  // 1. Get file path
  const fileRes = await fetch(`https://api.telegram.org/bot${telegramToken}/getFile?file_id=${fileId}`);
  const fileData = await fileRes.json();
  if (!fileData.ok) throw new Error("Failed to get file path");

  const filePath = fileData.result.file_path;

  // 2. Download Image
  const imgRes = await fetch(`https://api.telegram.org/file/bot${telegramToken}/${filePath}`);
  const imgBlob = await imgRes.blob();
  const buffer = await imgBlob.arrayBuffer();

  // 3. Convert to base64
  const base64Str = arrayBufferToBase64(buffer);
  const dataUrl = `data:image/jpeg;base64,${base64Str}`;

  // 4. Send to AI using the Groq Responses API for image input
  const res = await fetch(`${aiBaseUrl}/responses`, {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${aiApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: visionModel,
      max_output_tokens: 512,
      text: {
        format: {
          type: "json_schema",
          name: "receipt_parser",
          schema: receiptSchema
        }
      },
      input: [
        {
          role: "user",
          content: [
            {
              type: "input_text",
              text: `Analyze this receipt${caption ? ` with extra note: ${caption}` : ""}.
Available Categories: ${categoryList}

Return ONLY valid JSON format exactly like this:
{
  "store": "Name of the store",
  "date": "YYYY-MM-DD",
  "total": number,
  "suggestedCategory": "Pick one from Available Categories that matches best",
  "items": [{"name": "item", "price": 0, "quantity": 1}],
  "type": "expense"
}
CRITICAL RULES FOR TOTAL:
- "total" MUST be the exact Grand Total to be paid.
- Do NOT use cash given ("Bayar", "Cash") or change ("Kembali").
- If there's a discount or tax, the total is the final amount after those.
Note for multipliers: 'rb'/'k' = 1,000, 'jt' = 1,000,000.`
            },
            {
              type: "input_image",
              image_url: dataUrl
            }
          ]
        }
      ]
    })
  });

  const data = await res.json();
  if (!res.ok) {
    console.error("AI API Error (Image):", data);
    return { _error: data?.error?.message || "AI API Error" };
  }
  const content = extractResponseText(data);
  console.log("AI API Image Raw Text:", content);
  return extractJson(content);
}

function extractJson(text: string): any {
  let cleanStr = text.trim();
  if (cleanStr.startsWith('```json')) cleanStr = cleanStr.substring(7);
  if (cleanStr.startsWith('```')) cleanStr = cleanStr.substring(3);
  if (cleanStr.endsWith('```')) cleanStr = cleanStr.substring(0, cleanStr.length - 3);

  const match = cleanStr.match(/\{[\s\S]*\}/);
  if (match) {
    try {
      return JSON.parse(match[0]);
    } catch (_) { return null; }
  }
  return null;
}

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  let body: any = {};
  let chatId: any = null;

  try {
    body = await req.json();
    console.log("Incoming Webhook Body Type:", body.callback_query ? "callback" : "message");

    const rawChatId = body?.message?.chat?.id || body?.callback_query?.message?.chat?.id;
    if (rawChatId) chatId = String(rawChatId);

    // Fast Response to Telegram to prevent timeouts
    const response = new Response("OK", { status: 200 });

    // Process in background
    (async () => {
      let processingMsgId: number | null = null;
      try {
        if (!chatId) return;

        if (body.message?.text === "/ping") {
          await sendMessage(chatId, `Pong! 🏓\n\nStatus: Alive\nText Model: ${textModel}\nVision Model: ${visionModel}`);
          return;
        }

        // Check for callback queries (Inline button clicks)
        if (body.callback_query) {
          console.log("Processing Callback Query:", body.callback_query.data);
          const cb = body.callback_query;
          const data = cb.data;

          if (data.startsWith("undo_")) {
            await fetch(`https://api.telegram.org/bot${telegramToken}/editMessageText`, {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                chat_id: chatId,
                message_id: cb.message.message_id,
                text: "↩️ **Transaksi Dibatalkan.**\n\nData belum disimpan ke KuAngan. Silakan kirim ulang jika perlu.",
                parse_mode: "Markdown",
                reply_markup: { inline_keyboard: [] }
              })
            });
            return;
          }

          if (data.startsWith("confirm_")) {
            const { data: user } = await supabase
              .from("users")
              .select("id")
              .eq("telegram_id", chatId)
              .maybeSingle();

            if (!user) {
              await sendMessage(chatId, "❌ Akun Telegram ini belum tertaut ke KuAngan.");
              return;
            }

            const parsed = parseConfirmationMessage(cb.message?.text || "");
            if (!parsed) {
              await sendMessage(chatId, "❌ Data konfirmasi tidak valid. Silakan kirim ulang transaksi.");
              return;
            }

            const { data: wallets } = await supabase
              .from("wallets")
              .select("id, name, balance")
              .eq("user_id", user.id);
            const { data: categories } = await supabase
              .from("categories")
              .select("id, name, type")
              .eq("user_id", user.id);

            const wallet = wallets?.find((item: any) => item.name === parsed.wallet);
            const category = categories?.find((item: any) => item.name === parsed.category)
              || categories?.find((item: any) => item.type === parsed.type);

            if (!wallet || !category) {
              await sendMessage(chatId, "❌ Dompet atau kategori untuk transaksi ini tidak ditemukan. Silakan kirim ulang.");
              return;
            }

            const transactionId = createId();
            const { error: txError } = await supabase.from("transactions").insert({
              id: transactionId,
              user_id: user.id,
              wallet_id: wallet.id,
              category_id: category.id,
              amount: parsed.amount,
              type: parsed.type,
              date: parsed.date.toISOString(),
              note: parsed.note === "-" ? "Transaksi Telegram" : parsed.note,
              store: parsed.note === "-" ? "Transaksi Telegram" : parsed.note,
              source: "ai_scan"
            });
            if (txError) throw txError;

            const balanceDelta = parsed.type === "income" ? parsed.amount : -parsed.amount;
            await supabase.from("wallets").update({
              balance: wallet.balance + balanceDelta
            }).eq("id", wallet.id);

            const successTitle = parsed.type === "income"
              ? "Pemasukan Berhasil Dicatat!"
              : "Pengeluaran Berhasil Dicatat!";
            const finalMsgText = `✅ **${successTitle}**\n\n💰 Jumlah: ${escapeMarkdown(new Intl.NumberFormat('id-ID', {
              style: 'currency',
              currency: 'IDR',
              maximumFractionDigits: 0,
            }).format(parsed.amount))}\n📅 Tanggal: ${escapeMarkdown(new Intl.DateTimeFormat('id-ID', {
              dateStyle: 'long',
            }).format(parsed.date))}\n📝 Ket: ${escapeMarkdown(parsed.note)}\n📂 Kat: ${escapeMarkdown(category.name)}\n💳 Dompet: ${escapeMarkdown(wallet.name)}\n\n_Data sudah disimpan ke KuAngan._`;

            await fetch(`https://api.telegram.org/bot${telegramToken}/editMessageText`, {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                chat_id: chatId,
                message_id: cb.message.message_id,
                text: finalMsgText,
                parse_mode: "Markdown",
                reply_markup: { inline_keyboard: [] }
              })
            });
            return;
          }
        }

        // Check if it's a valid message
        if (!body?.message?.chat?.id) return;

        const text = body.message.text;
        const photo = body.message.photo;
        const caption = body.message.caption || "";

        console.log(`Processing Message from ${chatId}: ${text || "[Media]"}`);

        // 1. Get user by telegram_id
        const { data: user, error: userError } = await supabase
          .from("users")
          .select("id, name")
          .eq("telegram_id", chatId)
          .maybeSingle();

        if (userError) throw userError;

        if (!user) {
          console.warn(`User not found for Telegram ID: ${chatId}`);
          await sendMessage(chatId, `❌ Akun Anda belum tertaut dengan KuAngan.\n\nSilakan buka menu **Pengaturan** di aplikasi KuAngan, lalu masukkan **Telegram ID** Anda: \`${chatId}\``);
          return;
        }

        if (text?.startsWith("/start")) {
          await sendMessage(chatId, `✅ Berhasil terhubung, ${user.name || "User"}!\n\nKirim pengeluaran Anda dalam teks (contoh: "Beli kopi 25rb") atau kirim foto struk belanja untuk diproses oleh Kathlyn.`);
          return;
        }

        // 1.5 Fetch Context for AI
        const { data: wallets } = await supabase.from("wallets").select("id, name, balance").eq("user_id", user.id);
        const { data: categories } = await supabase.from("categories").select("id, name, type").eq("user_id", user.id);
        const today = new Date().toISOString().split('T')[0];
        const { data: todayTxs } = await supabase.from("transactions").select("amount, type").eq("user_id", user.id).gte("date", today);

        const totalExpense = (todayTxs || []).filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
        const walletContext = (wallets || []).map(w => `- ${w.name}: Rp ${new Intl.NumberFormat('id-ID').format(w.balance)}`).join("\n") || "No wallets";
        const categoryList = (categories || []).map(c => c.name).join(", ") || "No categories";

        const userContext = `Today's Date: ${today}
User Name: ${user.name || "User"}
Available Categories: ${categoryList}
Current Wallets:
${walletContext}
Today's Total Spending: Rp ${new Intl.NumberFormat('id-ID').format(totalExpense)}`;

        // 2. AI Processing
        let aiResult = null;
        if (photo && photo.length > 0) {
          processingMsgId = await sendMessage(chatId, "📸 Memproses gambar struk Anda...");
          const fileId = photo[photo.length - 1].file_id;
          aiResult = await parseImageWithAI(fileId, caption, categoryList);
          if (aiResult && !aiResult.intent) aiResult.intent = "record_transaction";
        } else if (text) {
          processingMsgId = await sendMessage(chatId, "📝 Memproses pesan Anda...");

          const textPromptSuffix = `\n\n- Unless a specific date is mentioned in my message, USE TODAY (${today}) as the date.\n- Use the most relevant category from 'Available Categories' (${categoryList}).`;
          aiResult = await parseTextWithAI(text + textPromptSuffix, userContext);
        }

        if (aiResult?._error) {
          const errMsg = `❌ **Gagal Memproses**\n\nKathlyn tidak dapat terhubung ke layanan AI saat ini ("_${aiResult._error}_").`;
          if (processingMsgId) await editMessageText(chatId, processingMsgId, errMsg);
          else await sendMessage(chatId, errMsg);
          return;
        }

        const intent = aiResult?.intent || "record_transaction";

        if (intent === "general_chat") {
          const msg = aiResult.content || "Maaf, Kathlyn tidak mengerti. Ada lagi yang bisa Kathlyn bantu?";
          if (processingMsgId) await editMessageText(chatId, processingMsgId, msg);
          else await sendMessage(chatId, msg);
          return;
        }

        if (intent === "query_balance") {
          const { data: bWallets } = await supabase.from("wallets").select("name, balance").eq("user_id", user.id);
          let balMsg = "";
          if (!bWallets || bWallets.length === 0) {
            balMsg = "💰 Kamu belum memiliki dompet yang terdaftar di KuAngan.";
          } else {
            const total = bWallets.reduce((sum, w) => sum + w.balance, 0);
            const list = bWallets.map(w => `💳 **${w.name}**: Rp ${new Intl.NumberFormat('id-ID').format(w.balance)}`).join('\n');
            balMsg = `📊 **Status Saldo Kamu**\n\n${list}\n\n💰 **Total Saldo**: Rp ${new Intl.NumberFormat('id-ID').format(total)}`;
          }
          if (processingMsgId) await editMessageText(chatId, processingMsgId, balMsg);
          else await sendMessage(chatId, balMsg);
          return;
        }

        if (intent === "query_summary" || intent === "query_daily_summary") {
          const period = aiResult?.data?.period || aiResult?.period || "today";
          let startDateStr = today;
          let title = "Hari Ini";

          if (period === "this_month") {
            const dateObj = new Date();
            dateObj.setDate(1);
            startDateStr = dateObj.toISOString().split('T')[0];
            title = "Bulan Ini";
          } else if (period === "this_week") {
            const dateObj = new Date();
            const day = dateObj.getDay();
            const diff = dateObj.getDate() - day + (day === 0 ? -6 : 1);
            dateObj.setDate(diff);
            startDateStr = dateObj.toISOString().split('T')[0];
            title = "Minggu Ini";
          } else if (period === "all" || text.toLowerCase().includes("semua")) {
            startDateStr = "2000-01-01";
            title = "Semua";
          }

          const { data: txs } = await supabase.from("transactions").select("amount, type, note, categories(name)").eq("user_id", user.id).gte("date", startDateStr);
          let sumMsg = "";
          if (!txs || txs.length === 0) {
            sumMsg = `📝 Belum ada transaksi yang dicatat untuk ${title.toLowerCase()}.`;
          } else {
            const income = txs.filter(t => t.type === 'income').reduce((s, t) => s + t.amount, 0);
            const expense = txs.filter(t => t.type === 'expense').reduce((s, t) => s + t.amount, 0);
            const incomeBreakdown = txs.filter(t => t.type === 'income').map(t => `- **${t.categories?.name || 'Lainnya'}**: Rp ${new Intl.NumberFormat('id-ID').format(t.amount)}${t.note ? ` (${t.note})` : ''}`).join('\n');
            const expenseBreakdown = txs.filter(t => t.type === 'expense').map(t => `- **${t.categories?.name || 'Lainnya'}**: Rp ${new Intl.NumberFormat('id-ID').format(t.amount)}${t.note ? ` (${t.note})` : ''}`).join('\n');

            sumMsg = `📅 **Ringkasan ${title}**\n\n📈 Pemasukan: Rp ${new Intl.NumberFormat('id-ID').format(income)}\n📉 Pengeluaran: Rp ${new Intl.NumberFormat('id-ID').format(expense)}\n\n💰 Selisih: Rp ${new Intl.NumberFormat('id-ID').format(income - expense)}`;
            if (incomeBreakdown) sumMsg += `\n\n📥 **Detail Pemasukan:**\n${incomeBreakdown}`;
            if (expenseBreakdown) sumMsg += `\n\n📤 **Detail Pengeluaran:**\n${expenseBreakdown}`;
          }
          if (processingMsgId) await editMessageText(chatId, processingMsgId, sumMsg);
          else await sendMessage(chatId, sumMsg);
          return;
        }

        // --- record_transaction ---
        const txData = aiResult?.data || aiResult;
        if (!txData || (!txData.store && !txData.total)) {
          const failMsg = "❌ Maaf, Kathlyn gagal mengerti atau server sedang sibuk. Coba ulangi dengan tulisan yang lebih jelas!";
          if (intent === "record_transaction") {
            if (processingMsgId) await editMessageText(chatId, processingMsgId, failMsg);
            else await sendMessage(chatId, failMsg);
          }
          return;
        }

        const wallet = wallets?.[0];
        if (!wallet || !categories?.length) {
          const errWallet = "❌ Anda belum memiliki Akun Dompet atau Kategori.";
          if (processingMsgId) await editMessageText(chatId, processingMsgId, errWallet);
          else await sendMessage(chatId, errWallet);
          return;
        }

        // Robust category lookup explicitly prioritizing suggestedCategory over raw store string
        const suggestedCatStr = (txData.suggestedCategory || txData.category || "").toLowerCase();
        let selectedCat = categories.find((c: any) => suggestedCatStr === c.name.toLowerCase() || suggestedCatStr.includes(c.name.toLowerCase()) || c.name.toLowerCase().includes(suggestedCatStr));

        if (!selectedCat) {
          const storeStr = (txData.store || "").toLowerCase();
          selectedCat = categories.find((c: any) => storeStr.includes(c.name.toLowerCase()));
        }

        const isIncome = txData.type === "income" || suggestedCatStr.includes("income") || suggestedCatStr.includes("gaji");
        const type = isIncome ? "income" : "expense";

        if (!selectedCat) {
          selectedCat = categories.find((c: any) => c.type === type) || categories[0];
        }

        const totalAmount = txData.total || 0;
        let txDate = new Date();
        if (txData.date) {
          try {
            const datePart = new Date(txData.date);
            const now = new Date();
            txDate = new Date(datePart.getFullYear(), datePart.getMonth(), datePart.getDate(), now.getHours(), now.getMinutes(), now.getSeconds());
          } catch (_) { }
        }

        const inlineKeyboard = { inline_keyboard: [[{ text: "✅ Benar", callback_data: "confirm_pending" }, { text: "❌ Batal", callback_data: "undo_pending" }]] };
        const finalMsgText = buildPreviewMessage({
          amount: totalAmount,
          date: txDate,
          note: txData.store || txData.note || "-",
          category: selectedCat.name,
          wallet: wallet.name,
          isIncome,
        });

        if (processingMsgId) {
          await editMessageText(chatId, processingMsgId, finalMsgText, inlineKeyboard);
        } else {
          await sendMessage(chatId, finalMsgText, inlineKeyboard);
        }

      } catch (err) {
        console.error("Background Error:", err);
        const exceptionMsg = `❌ **Kathlyn Terhenti Sejenak**\n\nTerjadi kesalahan internal ("_${err.message}_"). Coba lagi ya.`;
        if (processingMsgId) {
          try { await editMessageText(chatId, processingMsgId, exceptionMsg); } catch (_) { }
        } else if (chatId) {
          await sendMessage(chatId, exceptionMsg);
        }
      }
    })();

    return response;

  } catch (error) {
    console.error("Webhook Serve Error:", error);
    return new Response("Error", { status: 500 });
  }
});
