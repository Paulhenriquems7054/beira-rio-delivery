import { createClient } from "npm:@supabase/supabase-js@2.49.8";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const SUPERADMIN_ALLOWLIST_EMAILS = Deno.env.get("SUPERADMIN_ALLOWLIST_EMAILS") ?? "";

if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("Missing required Supabase env vars");
}

type ErrorPayload = {
  success: false;
  error: { code: string; message: string; details?: Record<string, unknown> };
};

function json(status: number, body: unknown, requestId: string): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "access-control-allow-origin": "*",
      "x-request-id": requestId,
    },
  });
}

function unauthorized(message: string, requestId: string): Response {
  const payload: ErrorPayload = {
    success: false,
    error: { code: "UNAUTHORIZED", message },
  };
  return json(401, payload, requestId);
}

function parseAllowlist(): Set<string> {
  return new Set(
    SUPERADMIN_ALLOWLIST_EMAILS
      .split(",")
      .map((email) => email.trim().toLowerCase())
      .filter(Boolean),
  );
}

function getToken(request: Request): string | null {
  const auth = request.headers.get("authorization") ?? "";
  const [scheme, token] = auth.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !token) return null;
  return token;
}

Deno.serve(async (request) => {
  const requestId = crypto.randomUUID();

  if (request.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "access-control-allow-origin": "*",
        "access-control-allow-methods": "POST,OPTIONS",
        "access-control-allow-headers":
          "authorization, content-type, apikey, x-client-info, x-client-request-id",
      },
    });
  }

  if (request.method !== "POST") {
    return json(
      405,
      { success: false, error: { code: "METHOD_NOT_ALLOWED", message: "Use POST" } },
      requestId,
    );
  }

  const token = getToken(request);
  if (!token) return unauthorized("Token JWT ausente", requestId);

  const authClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const userResult = await authClient.auth.getUser();
  const user = userResult.data.user;
  if (!user || userResult.error) {
    return unauthorized("JWT inválido", requestId);
  }

  const allowlist = parseAllowlist();
  const userEmail = user.email?.toLowerCase() ?? "";
  const isSuperRole = (user.app_metadata as Record<string, unknown> | undefined)?.role === "superadmin";
  const isAllowedByEmail = userEmail && allowlist.has(userEmail);
  if (!isSuperRole && !isAllowedByEmail) {
    return unauthorized("Usuário sem permissão de superadmin", requestId);
  }

  let body: { storeId?: string };
  try {
    body = (await request.json()) as { storeId?: string };
  } catch {
    return json(
      400,
      { success: false, error: { code: "VALIDATION_ERROR", message: "Body JSON inválido" } },
      requestId,
    );
  }

  const storeId = body.storeId;
  if (!storeId) {
    return json(
      400,
      { success: false, error: { code: "VALIDATION_ERROR", message: "storeId é obrigatório" } },
      requestId,
    );
  }

  const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const cleanupTables = [
    "subscription_events",
    "audit_logs",
    "delivery_zones",
    "coupons",
    "categories",
    "baskets",
    "products",
    "direct_deliveries",
    "favorites",
  ];

  try {
    for (const table of cleanupTables) {
      await (adminClient as any).from(table).delete().eq("store_id", storeId);
    }

    const { data: deletedRows, error: deleteError } = await (adminClient as any)
      .from("stores")
      .delete()
      .eq("id", storeId)
      .select("id");

    if (deleteError) throw deleteError;
    if (!deletedRows || deletedRows.length === 0) {
      return json(
        404,
        { success: false, error: { code: "NOT_FOUND", message: "Loja não encontrada para exclusão" } },
        requestId,
      );
    }

    await (adminClient as any).from("audit_logs").insert({
      store_id: null,
      user_id: user.id,
      action: "superadmin_delete_store",
      ip_address: request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown",
      metadata: {
        request_id: requestId,
        deleted_store_id: storeId,
        deleted_by_email: user.email ?? null,
      },
    });

    return json(200, { success: true, data: { deletedStoreId: storeId } }, requestId);
  } catch (error: any) {
    return json(
      500,
      {
        success: false,
        error: {
          code: "INTERNAL_ERROR",
          message: "Falha ao excluir loja",
          details: { reason: error?.message ?? "unknown" },
        },
      },
      requestId,
    );
  }
});
