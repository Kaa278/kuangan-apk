// @ts-nocheck
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.3";
import { createId } from "https://esm.sh/@paralleldrive/cuid2@2.2.2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const supabase = createClient(supabaseUrl, serviceRoleKey);

const defaultWallet = {
  name: "Dompet Utama",
  balance: 0,
  color: "#2563EB",
  icon: "wallet",
};

const defaultCategories = [
  { name: "Makanan & Minuman", color: "#F59E0B", icon: "🍜", type: "expense" },
  { name: "Transportasi", color: "#3B82F6", icon: "🛵", type: "expense" },
  { name: "Belanja", color: "#EC4899", icon: "🛍️", type: "expense" },
  { name: "Tagihan", color: "#8B5CF6", icon: "📄", type: "expense" },
  { name: "Hiburan", color: "#06B6D4", icon: "🎉", type: "expense" },
  { name: "Kesehatan", color: "#EF4444", icon: "💊", type: "expense" },
  { name: "Pendidikan", color: "#84CC16", icon: "📚", type: "expense" },
  { name: "Lainnya", color: "#64748B", icon: "📝", type: "expense" },
  { name: "Gaji", color: "#10B981", icon: "💼", type: "income" },
  { name: "Bonus", color: "#14B8A6", icon: "🎁", type: "income" },
  { name: "Investasi", color: "#0EA5E9", icon: "📈", type: "income" },
  { name: "Lainnya", color: "#94A3B8", icon: "💰", type: "income" },
];

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { name, email, password, token } = await req.json();
    const normalizedEmail = String(email ?? "").trim().toLowerCase();
    const trimmedName = String(name ?? "").trim();
    const trimmedPassword = String(password ?? "").trim();
    const trimmedToken = String(token ?? "").trim();

    if (!trimmedName || !normalizedEmail || !trimmedPassword || !trimmedToken) {
      return new Response(
        JSON.stringify({ error: "Data verifikasi belum lengkap." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: otpRow, error: otpError } = await supabase
      .from("signup_otps")
      .select("*")
      .eq("email", normalizedEmail)
      .eq("token", trimmedToken)
      .maybeSingle();

    if (otpError) {
      throw otpError;
    }

    if (!otpRow) {
      return new Response(
        JSON.stringify({ error: "Kode verifikasi tidak cocok atau sudah tidak berlaku." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (new Date(otpRow.expires_at).getTime() < Date.now()) {
      await supabase.from("signup_otps").delete().eq("id", otpRow.id);
      return new Response(
        JSON.stringify({ error: "Kode verifikasi sudah kedaluwarsa. Minta kode baru, ya." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: authUsersResult, error: authUsersError } =
      await supabase.auth.admin.listUsers();
    if (authUsersError) {
      throw authUsersError;
    }

    const existingAuthUser = authUsersResult.users.find(
      (user: any) => String(user.email ?? "").toLowerCase() === normalizedEmail,
    );

    if (existingAuthUser) {
      return new Response(
        JSON.stringify({
          error:
            "Email ini sudah terdaftar sebelum verifikasi selesai. Bersihkan data signup lama dulu lalu coba daftar ulang.",
        }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const { data: existingPublicUser, error: publicUserError } = await supabase
      .from("users")
      .select("id")
      .eq("email", normalizedEmail)
      .maybeSingle();

    if (publicUserError) {
      throw publicUserError;
    }

    if (existingPublicUser) {
      return new Response(
        JSON.stringify({
          error:
            "Email ini sudah punya data akun sebelum verifikasi selesai. Hapus data signup lama dulu lalu coba daftar ulang.",
        }),
        { status: 409, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const createdUser = await supabase.auth.admin.createUser({
      email: normalizedEmail,
      password: trimmedPassword,
      email_confirm: true,
      user_metadata: { name: trimmedName },
    });

    if (createdUser.error || !createdUser.data.user) {
      throw createdUser.error ?? new Error("Gagal membuat akun auth.");
    }

    const authUser = createdUser.data.user;

    const { error: insertUserError } = await supabase.from("users").insert({
      id: authUser.id,
      email: normalizedEmail,
      name: trimmedName,
      password_hash: "managed_by_supabase_auth",
    });

    if (insertUserError) {
      await supabase.auth.admin.deleteUser(authUser.id);
      throw insertUserError;
    }

    const { count: walletCount, error: walletCountError } = await supabase
      .from("wallets")
      .select("id", { count: "exact", head: true })
      .eq("user_id", authUser.id);

    if (walletCountError) {
      throw walletCountError;
    }

    if ((walletCount ?? 0) == 0) {
      const { error: walletError } = await supabase.from("wallets").insert({
        id: createId(),
        user_id: authUser.id,
        ...defaultWallet,
      });

      if (walletError) {
        throw walletError;
      }
    }

    const { count: categoryCount, error: categoryCountError } = await supabase
      .from("categories")
      .select("id", { count: "exact", head: true })
      .eq("user_id", authUser.id);

    if (categoryCountError) {
      throw categoryCountError;
    }

    if ((categoryCount ?? 0) == 0) {
      const { error: categoryError } = await supabase
        .from("categories")
        .insert(
          defaultCategories.map((category) => ({
            id: createId(),
            user_id: authUser.id,
            ...category,
          })),
        );

      if (categoryError) {
        throw categoryError;
      }
    }

    await supabase.from("signup_otps").delete().eq("id", otpRow.id);

    return new Response(
      JSON.stringify({ success: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error?.message || "Terjadi kesalahan saat verifikasi signup." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
