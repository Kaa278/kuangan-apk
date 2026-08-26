// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const resendApiKey = Deno.env.get("RESEND_API_KEY") ?? "";
const resendFromEmail = Deno.env.get("RESEND_FROM_EMAIL") ?? "";
const otpExpirySeconds = 3600;

const supabase = createClient(supabaseUrl, serviceRoleKey);

function buildOtpEmailHtml(token: string) {
  return `
<div style="margin:0;padding:0;background:#eff6ff;font-family:Arial,Helvetica,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="width:100%;background:linear-gradient(180deg,#eff6ff 0%,#dbeafe 100%);padding:36px 16px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width:520px;background:#ffffff;border-radius:24px;padding:40px 32px;box-shadow:0 16px 50px rgba(30,64,175,0.12);border:1px solid #dbeafe;">
          <tr>
            <td align="center">
              <div style="display:inline-block;background:linear-gradient(135deg,#2563eb,#1d4ed8);padding:14px 22px;border-radius:18px;box-shadow:0 10px 24px rgba(37,99,235,0.22);">
                <span style="font-size:22px;font-weight:700;color:#ffffff;letter-spacing:0.4px;">Kuangan</span>
              </div>
            </td>
          </tr>
          <tr>
            <td align="center" style="padding-top:28px;">
              <h1 style="margin:0;font-size:24px;line-height:1.3;color:#0f172a;font-weight:800;">Verifikasi Akun Kamu</h1>
              <p style="margin:12px 0 0 0;font-size:15px;line-height:1.7;color:#475569;max-width:400px;">
                Masukkan kode berikut di aplikasi Kuangan untuk menyelesaikan proses pendaftaran akun.
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding-top:30px;">
              <div style="background:linear-gradient(180deg,#f8fbff 0%,#eff6ff 100%);border:1px solid #bfdbfe;border-radius:20px;padding:24px 16px;text-align:center;">
                <div style="font-size:12px;font-weight:700;color:#64748b;letter-spacing:1.6px;text-transform:uppercase;margin-bottom:12px;">
                  Kode Verifikasi
                </div>
                <div style="font-size:36px;line-height:1;font-weight:800;letter-spacing:10px;color:#1d4ed8;">${token}</div>
              </div>
            </td>
          </tr>
          <tr>
            <td align="center" style="padding-top:24px;">
              <p style="margin:0;font-size:14px;line-height:1.7;color:#334155;">Kode ini bersifat rahasia dan jangan dibagikan ke siapa pun.</p>
              <p style="margin:10px 0 0 0;font-size:13px;line-height:1.7;color:#94a3b8;">Jika kamu tidak merasa mendaftar di Kuangan, abaikan email ini.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</div>`;
}

async function sendOtpEmail(email: string, token: string) {
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${resendApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: resendFromEmail,
      to: [email],
      subject: "Kode verifikasi Kuangan",
      html: buildOtpEmailHtml(token),
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(data?.message || "Gagal mengirim email OTP.");
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { name, email } = await req.json();
    const normalizedEmail = String(email ?? "").trim().toLowerCase();
    const trimmedName = String(name ?? "").trim();

    if (!trimmedName || !normalizedEmail) {
      return new Response(
        JSON.stringify({ error: "Nama dan email wajib diisi." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const gmailRegex = /^[a-zA-Z0-9._%+-]+@gmail\.com$/;
    if (!gmailRegex.test(normalizedEmail)) {
      return new Response(
        JSON.stringify({ error: "Gunakan alamat Gmail yang valid." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: existingUser } = await supabase.auth.admin.listUsers();
    const emailAlreadyUsed = existingUser?.users?.some(
      (user: any) => String(user.email ?? "").toLowerCase() === normalizedEmail,
    );
    if (emailAlreadyUsed) {
      return new Response(
        JSON.stringify({ error: "Email ini sudah terdaftar. Silakan masuk atau gunakan email lain." }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: existingPublicUser, error: existingPublicUserError } = await supabase
      .from("users")
      .select("id")
      .eq("email", normalizedEmail)
      .maybeSingle();

    if (existingPublicUserError) {
      throw existingPublicUserError;
    }

    if (existingPublicUser) {
      return new Response(
        JSON.stringify({
          error:
            "Email ini sudah punya data akun di sistem. Hapus data signup lama dulu atau gunakan email lain.",
        }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const token = String(Math.floor(100000 + Math.random() * 900000));
    const expiresAt = new Date(Date.now() + otpExpirySeconds * 1000).toISOString();

    await supabase
      .from("signup_otps")
      .delete()
      .eq("email", normalizedEmail);

    const { error: insertError } = await supabase
      .from("signup_otps")
      .insert({
        email: normalizedEmail,
        name: trimmedName,
        token,
        expires_at: expiresAt,
      });

    if (insertError) {
      throw insertError;
    }

    await sendOtpEmail(normalizedEmail, token);

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error?.message || "Terjadi kesalahan saat meminta OTP." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
