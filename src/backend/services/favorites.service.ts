import { AppError } from "@/backend/errors/app-error";
import { ERROR_CODES } from "@/backend/errors/error-codes";
import { logger } from "@/backend/logging/logger";
import type {
  FavoriteEntity,
  FavoritesRepository,
} from "@/backend/repositories/interfaces/favorites-repository";
import type { RequestContext } from "@/backend/types/http";
import type { CreateFavoriteInput } from "@/backend/validators/favorite.schemas";

export class FavoritesService {
  constructor(private readonly repository: FavoritesRepository) {}

  async listByCustomer(customerPhone: string, context: RequestContext): Promise<FavoriteEntity[]> {
    await this.ensureTenantAccess(context);
    return this.repository.listByCustomer(customerPhone, context.tenantId);
  }

  async toggleFavorite(input: CreateFavoriteInput, context: RequestContext) {
    await this.ensureTenantAccess(context);
    await this.ensureProductAccess(input.productId, context.tenantId);

    const existing = await this.repository.findByCustomerAndProduct(
      input.customerPhone,
      input.productId,
      context.tenantId,
    );

    if (existing) {
      await this.repository.delete(existing.id, context.tenantId);
      logger.info("Favorite removed", { tenantId: context.tenantId, userId: context.userId });
      return { action: "removed" as const, favoriteId: existing.id };
    }

    const created = await this.repository.create({
      customerPhone: input.customerPhone,
      productId: input.productId,
      tenantId: context.tenantId,
    });
    logger.info("Favorite created", { tenantId: context.tenantId, userId: context.userId });
    return { action: "added" as const, favoriteId: created.id };
  }

  async deleteFavorite(favoriteId: string, context: RequestContext): Promise<void> {
    await this.ensureTenantAccess(context);

    const existing = await this.repository.findById(favoriteId, context.tenantId);
    if (!existing) {
      throw new AppError(ERROR_CODES.NOT_FOUND, "Favorito não encontrado", 404);
    }

    await this.repository.delete(favoriteId, context.tenantId);
  }

  private async ensureProductAccess(productId: string, tenantId: string): Promise<void> {
    const belongs = await this.repository.productBelongsToTenant(productId, tenantId);
    if (!belongs) {
      throw new AppError(
        ERROR_CODES.BUSINESS_RULE_ERROR,
        "Produto não pertence ao tenant informado",
        409,
        { productId, tenantId },
      );
    }
  }

  private async ensureTenantAccess(context: RequestContext): Promise<void> {
    const allowed = await this.repository.userCanAccessTenant(context.userId, context.tenantId);
    if (!allowed) {
      throw new AppError(
        ERROR_CODES.UNAUTHORIZED,
        "Usuário sem permissão para o tenant",
        403,
        { userId: context.userId, tenantId: context.tenantId },
      );
    }
  }
}
