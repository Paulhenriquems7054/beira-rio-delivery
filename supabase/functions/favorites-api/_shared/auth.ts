import { createClient, type User } from "npm:@supabase/supabase-js@2.49.8";
import { AppError, ERROR_CODES } from "./error.ts";

export interface RequestContext {
  requestId: string;
  user: User;
  userId: string;
  tenantId: string;
  ipAddress: string;
}

function getBearerToken(request: Request): string {
  const authorization = request.headers.get("authorization") ?? "";
  const [scheme, token] = authorization.split(" ");

  if (scheme?.toLowerCase() !== "bearer" || !token) {
    throw new AppError(ERROR_CODES.UNAUTHORIZED, "Token JWT ausente", 401);
  }

  return token;
}

function getValidUuid(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  return uuidRegex.test(value) ? value : null;
}

function resolveTenantId(request: Request, user: User): string {
  const headerTenant = getValidUuid(request.headers.get("x-tenant-id"));
  if (headerTenant) return headerTenant;

  const metadataTenant = getValidUuid(
    (user.app_metadata as Record<string, unknown> | undefined)?.tenant_id ??
      (user.user_metadata as Record<string, unknown> | undefined)?.tenant_id,
  );
  if (metadataTenant) return metadataTenant;

  throw new AppError(ERROR_CODES.UNAUTHORIZED, "tenant_id ausente no header/token", 401);
}

export async function buildRequestContext(
  request: Request,
  supabaseUrl: string,
  supabaseAnonKey: string,
): Promise<RequestContext> {
  const token = getBearerToken(request);
  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: { headers: { Authorization: `Bearer ${token}` } },
  });

  const userResponse = await authClient.auth.getUser();
  const user = userResponse.data.user;
  if (userResponse.error || !user) {
    throw new AppError(ERROR_CODES.UNAUTHORIZED, "JWT inválido", 401, {
      authError: userResponse.error?.message,
    });
  }

  return {
    requestId: crypto.randomUUID(),
    user,
    userId: user.id,
    tenantId: resolveTenantId(request, user),
    ipAddress: request.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown",
  };
}
