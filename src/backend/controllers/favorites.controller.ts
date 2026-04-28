import { getErrorStatus, toErrorResponse } from "@/backend/errors/error-handler";
import type { FavoritesService } from "@/backend/services/favorites.service";
import type { ApiRequest, ApiResponse } from "@/backend/types/http";
import {
  createFavoriteSchema,
  favoriteIdParamsSchema,
} from "@/backend/validators/favorite.schemas";
import { safePhoneSchema } from "@/backend/validators/common";
import { validateSchema } from "@/backend/validators/validate-schema";

export class FavoritesController {
  constructor(private readonly service: FavoritesService) {}

  list = async (request: ApiRequest<{ customerPhone: string }>): Promise<{ status: number; body: ApiResponse }> => {
    try {
      const customerPhone = validateSchema(safePhoneSchema, request.body.customerPhone);
      const data = await this.service.listByCustomer(customerPhone, request.context);
      return { status: 200, body: { success: true, data } };
    } catch (error) {
      return { status: getErrorStatus(error), body: toErrorResponse(error) };
    }
  };

  toggle = async (request: ApiRequest): Promise<{ status: number; body: ApiResponse }> => {
    try {
      const input = validateSchema(createFavoriteSchema, request.body);
      return {
        status: 200,
        body: { success: true, data: await this.service.toggleFavorite(input, request.context) },
      };
    } catch (error) {
      return { status: getErrorStatus(error), body: toErrorResponse(error) };
    }
  };

  delete = async (
    request: ApiRequest<unknown, { favoriteId: string }>,
  ): Promise<{ status: number; body: ApiResponse }> => {
    try {
      const { favoriteId } = validateSchema(favoriteIdParamsSchema, request.params);
      await this.service.deleteFavorite(favoriteId, request.context);
      return { status: 204, body: { success: true } };
    } catch (error) {
      return { status: getErrorStatus(error), body: toErrorResponse(error) };
    }
  };
}
