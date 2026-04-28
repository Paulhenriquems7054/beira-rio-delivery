import { describe, expect, it, vi } from "vitest";
import { AppError, ERROR_CODES } from "../../../../supabase/functions/favorites-api/_shared/error";
import {
  createFavoritesHttpHandler,
  type FavoritesHttpController,
} from "../../../../supabase/functions/favorites-api/_shared/http-handler";

const controllerStub: FavoritesHttpController = {
  list: vi.fn(async () => ({ status: 200, body: { success: true, data: [] } })),
  toggle: vi.fn(async (_body, context) => {
    if (context.tenantId === "22222222-2222-4222-8222-222222222222") {
      return {
        status: 403,
        body: {
          success: false,
          error: { code: "UNAUTHORIZED", message: "Usuário sem acesso ao tenant", details: {} },
        },
      };
    }
    return { status: 200, body: { success: true, data: { action: "added", favoriteId: "f-1" } } };
  }),
  delete: vi.fn(async () => ({ status: 204, body: { success: true } })),
};

describe("favorites edge http integration", () => {
  it("retorna 401 para JWT invalido", async () => {
    const handler = createFavoritesHttpHandler({
      buildContext: async () => {
        throw new AppError(ERROR_CODES.UNAUTHORIZED, "JWT inválido", 401);
      },
      controller: controllerStub,
      audit: async () => {},
    });

    const response = await handler(new Request("http://localhost/functions/v1/favorites-api/favorites", { method: "GET" }));
    const body = await response.json();

    expect(response.status).toBe(401);
    expect(body.error.code).toBe("UNAUTHORIZED");
  });

  it("retorna 401 para tenant invalido/ausente", async () => {
    const handler = createFavoritesHttpHandler({
      buildContext: async () => {
        throw new AppError(ERROR_CODES.UNAUTHORIZED, "tenant_id ausente no header/token", 401);
      },
      controller: controllerStub,
      audit: async () => {},
    });

    const response = await handler(new Request("http://localhost/functions/v1/favorites-api/favorites", { method: "GET" }));
    const body = await response.json();

    expect(response.status).toBe(401);
    expect(body.error.message).toContain("tenant_id");
  });

  it("retorna 403 para tentativa cross-tenant", async () => {
    const auditSpy = vi.fn(async () => {});
    const handler = createFavoritesHttpHandler({
      buildContext: async () => ({
        requestId: "req-1",
        userId: "user-1",
        tenantId: "22222222-2222-4222-8222-222222222222",
        ipAddress: "127.0.0.1",
        user: { id: "user-1" } as any,
      }),
      controller: controllerStub,
      audit: auditSpy,
    });

    const response = await handler(
      new Request("http://localhost/functions/v1/favorites-api/favorites", {
        method: "POST",
        body: JSON.stringify({
          customerPhone: "+5511999999999",
          productId: "550e8400-e29b-41d4-a716-446655440000",
        }),
      }),
    );
    const body = await response.json();

    expect(response.status).toBe(403);
    expect(body.error.code).toBe("UNAUTHORIZED");
    expect(auditSpy).toHaveBeenCalledOnce();
  });
});
