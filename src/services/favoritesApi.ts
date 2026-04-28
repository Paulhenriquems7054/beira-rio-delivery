import { supabase } from "@/integrations/supabase/client";

export interface FavoriteApiItem {
  id: string;
  tenantId: string;
  customerPhone: string;
  productId: string;
  createdAt: string;
}

interface ApiErrorPayload {
  error?: { message?: string };
}

async function getAuthHeaders(tenantId: string, clientRequestId: string): Promise<Record<string, string>> {
  const { data, error } = await supabase.auth.getSession();
  const token = data.session?.access_token;

  if (error || !token) {
    throw new Error("Sessão inválida. Faça login novamente.");
  }

  return {
    Authorization: `Bearer ${token}`,
    "x-tenant-id": tenantId,
    "Content-Type": "application/json",
    "x-client-request-id": clientRequestId,
  };
}

async function parseJsonResponse<T>(response: Response): Promise<T> {
  let payload: T | ApiErrorPayload | null = null;
  try {
    payload = (await response.json()) as T | ApiErrorPayload;
  } catch {
    payload = null;
  }

  if (!response.ok) {
    const requestId = response.headers.get("x-request-id");
    const message = (payload as ApiErrorPayload | null)?.error?.message ?? "Falha na API de favoritos";
    throw new Error(requestId ? `${message} (request: ${requestId})` : message);
  }

  return payload as T;
}

export async function listFavorites(params: {
  customerPhone: string;
  tenantId: string;
}): Promise<FavoriteApiItem[]> {
  const clientRequestId = crypto.randomUUID();
  const headers = await getAuthHeaders(params.tenantId, clientRequestId);
  const query = new URLSearchParams({ customerPhone: params.customerPhone });
  const endpoint = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/favorites-api/favorites?${query.toString()}`;

  const response = await fetch(endpoint, { method: "GET", headers });
  const payload = await parseJsonResponse<{ success: true; data: FavoriteApiItem[] }>(response);
  return payload.data ?? [];
}

export async function toggleFavorite(params: {
  customerPhone: string;
  productId: string;
  tenantId: string;
}) {
  const clientRequestId = crypto.randomUUID();
  const headers = await getAuthHeaders(params.tenantId, clientRequestId);
  const endpoint = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/favorites-api/favorites`;

  const response = await fetch(endpoint, {
    method: "POST",
    headers,
    body: JSON.stringify({
      customerPhone: params.customerPhone,
      productId: params.productId,
    }),
  });

  return parseJsonResponse<{ success: true; data: { action: "added" | "removed"; favoriteId: string } }>(
    response,
  );
}
