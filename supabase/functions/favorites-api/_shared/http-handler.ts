import type { RequestContext } from "./auth.ts";
import { AppError, ERROR_CODES, toErrorResponse } from "./error.ts";

export interface FavoritesHttpController {
  list: (query: URLSearchParams, context: RequestContext) => Promise<{ status: number; body: unknown }>;
  toggle: (body: unknown, context: RequestContext) => Promise<{ status: number; body: unknown }>;
  delete: (
    params: { favoriteId: string },
    context: RequestContext,
  ) => Promise<{ status: number; body: unknown }>;
}

interface HandlerDeps {
  buildContext: (request: Request) => Promise<RequestContext>;
  controller: FavoritesHttpController;
  audit: (
    context: RequestContext,
    metadata: { route: string; status: number; duration_ms: number },
  ) => Promise<void>;
  alertOnError?: (payload: {
    requestId: string;
    route: string;
    status: number;
    message: string;
  }) => Promise<void>;
}

export function resolveRoute(request: Request) {
  const url = new URL(request.url);
  const parts = url.pathname.split("/").filter(Boolean);
  const index = parts.lastIndexOf("favorites-api");
  const routeParts = index >= 0 ? parts.slice(index + 1) : [];
  return { method: request.method.toUpperCase(), routeParts, url };
}

function jsonResponse(status: number, body: unknown, requestId: string): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "x-powered-by": "favorites-api-edge",
      "access-control-allow-origin": "*",
      "x-request-id": requestId,
    },
  });
}

export function createFavoritesHttpHandler(deps: HandlerDeps) {
  return async (request: Request): Promise<Response> => {
    const fallbackRequestId = crypto.randomUUID();
    if (request.method === "OPTIONS") {
      return new Response("ok", {
        headers: {
          "access-control-allow-origin": "*",
          "access-control-allow-methods": "GET,POST,DELETE,OPTIONS",
          "access-control-allow-headers": "authorization, content-type, x-tenant-id",
        },
      });
    }

    const start = Date.now();
    let context: RequestContext;
    try {
      context = await deps.buildContext(request);
    } catch (error) {
      const mapped = toErrorResponse(error);
      return jsonResponse(mapped.status, mapped.body, fallbackRequestId);
    }

    const { method, routeParts, url } = resolveRoute(request);
    const routeKey = `${method} /${routeParts.join("/")}`;

    let result: { status: number; body: unknown };
    try {
      if (method === "GET" && routeParts.length === 1 && routeParts[0] === "favorites") {
        result = await deps.controller.list(url.searchParams, context);
      } else if (method === "POST" && routeParts.length === 1 && routeParts[0] === "favorites") {
        result = await deps.controller.toggle(await request.json(), context);
      } else if (method === "DELETE" && routeParts.length === 2 && routeParts[0] === "favorites") {
        result = await deps.controller.delete({ favoriteId: routeParts[1] }, context);
      } else {
        throw new AppError(ERROR_CODES.NOT_FOUND, "Endpoint não encontrado", 404, { routeKey });
      }
    } catch (error) {
      result = toErrorResponse(error);
    }

    await deps.audit(context, {
      route: routeKey,
      status: result.status,
      duration_ms: Date.now() - start,
    });

    if (result.status >= 500 && deps.alertOnError) {
      await deps.alertOnError({
        requestId: context.requestId,
        route: routeKey,
        status: result.status,
        message: "favorites-api internal error",
      });
    }

    return jsonResponse(result.status, result.body, context.requestId);
  };
}
