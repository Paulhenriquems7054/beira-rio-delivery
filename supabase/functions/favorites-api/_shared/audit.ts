import type { SupabaseClient } from "npm:@supabase/supabase-js@2.49.8";
import type { RequestContext } from "./auth.ts";

export async function writeAuditLog(
  db: SupabaseClient,
  context: RequestContext,
  action: string,
  metadata: Record<string, unknown>,
) {
  const { error } = await db.from("audit_logs").insert({
    store_id: context.tenantId,
    user_id: context.userId,
    action,
    ip_address: context.ipAddress,
    metadata: {
      request_id: context.requestId,
      ...metadata,
    },
  });

  if (error) {
    console.error("[favorites-api] failed to write audit log", error);
  }
}
