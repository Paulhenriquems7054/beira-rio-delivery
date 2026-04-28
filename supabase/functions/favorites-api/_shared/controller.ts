import type { RequestContext } from "./auth.ts";
import { toErrorResponse } from "./error.ts";
import { FavoritesService } from "./service.ts";
import {
  createFavoriteSchema,
  favoriteIdSchema,
  listFavoritesSchema,
  validateSchema,
} from "./validation.ts";

export class FavoritesController {
  constructor(private readonly service: FavoritesService) {}

  async list(query: URLSearchParams, context: RequestContext) {
    try {
      const { customerPhone } = validateSchema(listFavoritesSchema, {
        customerPhone: query.get("customerPhone"),
      });
      const data = await this.service.list(customerPhone, context);
      return { status: 200, body: { success: true, data } };
    } catch (error) {
      return toErrorResponse(error);
    }
  }

  async toggle(body: unknown, context: RequestContext) {
    try {
      const input = validateSchema(createFavoriteSchema, body);
      const data = await this.service.toggle(input, context);
      return { status: 200, body: { success: true, data } };
    } catch (error) {
      return toErrorResponse(error);
    }
  }

  async delete(params: { favoriteId: string }, context: RequestContext) {
    try {
      const { favoriteId } = validateSchema(favoriteIdSchema, params);
      await this.service.delete(favoriteId, context);
      return { status: 204, body: { success: true } };
    } catch (error) {
      return toErrorResponse(error);
    }
  }
}
