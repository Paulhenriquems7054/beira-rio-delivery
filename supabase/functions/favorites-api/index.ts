import { createClient } from "npm:@supabase/supabase-js@2.49.8";
import { buildRequestContext } from "./_shared/auth.ts";
import { FavoritesController } from "./_shared/controller.ts";
import { createFavoritesHttpHandler } from "./_shared/http-handler.ts";
import { FavoritesRepository } from "./_shared/repository.ts";
import { FavoritesService } from "./_shared/service.ts";
import { writeAuditLog } from "./_shared/audit.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const ALERT_WEBHOOK_URL = Deno.env.get("ALERT_WEBHOOK_URL");

if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("Missing required Supabase env vars");
}

const db = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
const controller = new FavoritesController(new FavoritesService(new FavoritesRepository(db)));

Deno.serve(
  createFavoritesHttpHandler({
    buildContext: (request) => buildRequestContext(request, SUPABASE_URL, SUPABASE_ANON_KEY),
    controller,
    audit: async (context, metadata) => {
      await writeAuditLog(db, context, "favorites_api_request", {
        route: metadata.route,
        status: metadata.status,
        duration_ms: metadata.duration_ms,
      });
    },
    alertOnError: async (payload) => {
      if (!ALERT_WEBHOOK_URL) return;
      try {
        await fetch(ALERT_WEBHOOK_URL, {
          method: "POST",
          headers: { "content-type": "application/json" },
          body: JSON.stringify({
            service: "favorites-api",
            ...payload,
            timestamp: new Date().toISOString(),
          }),
        });
      } catch (error) {
        console.error("[favorites-api] alert webhook failed", error);
      }
    },
  }),
);
