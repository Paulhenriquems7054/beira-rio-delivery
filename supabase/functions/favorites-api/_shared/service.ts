import type { RequestContext } from "./auth.ts";
import { AppError, ERROR_CODES } from "./error.ts";
import type { FavoriteEntity } from "./repository.ts";
import { FavoritesRepository } from "./repository.ts";

export class FavoritesService {
  constructor(private readonly repository: FavoritesRepository) {}

  async list(customerPhone: string, context: RequestContext): Promise<FavoriteEntity[]> {
    await this.ensureTenantAccess(context);
    return this.repository.listByCustomer(customerPhone, context.tenantId);
  }

  async toggle(input: { customerPhone: string; productId: string }, context: RequestContext) {
    await this.ensureTenantAccess(context);
    const productBelongs = await this.repository.productBelongsToTenant(input.productId, context.tenantId);
    if (!productBelongs) {
      throw new AppError(ERROR_CODES.BUSINESS_RULE_ERROR, "Produto fora do tenant", 409);
    }

    const existing = await this.repository.findByCustomerAndProduct(
      input.customerPhone,
      input.productId,
      context.tenantId,
    );
    if (existing) {
      await this.repository.deleteById(existing.id, context.tenantId);
      return { action: "removed", favoriteId: existing.id };
    }

    const created = await this.repository.create({
      tenantId: context.tenantId,
      customerPhone: input.customerPhone,
      productId: input.productId,
    });

    return { action: "added", favoriteId: created.id };
  }

  async delete(favoriteId: string, context: RequestContext): Promise<void> {
    await this.ensureTenantAccess(context);
    const existing = await this.repository.findById(favoriteId, context.tenantId);
    if (!existing) throw new AppError(ERROR_CODES.NOT_FOUND, "Favorito não encontrado", 404);
    await this.repository.deleteById(favoriteId, context.tenantId);
  }

  private async ensureTenantAccess(context: RequestContext) {
    const hasAccess = await this.repository.userCanAccessTenant(context.userId, context.tenantId);
    if (!hasAccess) {
      throw new AppError(ERROR_CODES.UNAUTHORIZED, "Usuário sem acesso ao tenant", 403);
    }
  }
}
