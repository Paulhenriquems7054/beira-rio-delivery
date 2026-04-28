import { describe, expect, it } from "vitest";
import { FavoritesService } from "@/backend/services/favorites.service";
import { AppError } from "@/backend/errors/app-error";
import type {
  FavoriteEntity,
  FavoritesRepository,
} from "@/backend/repositories/interfaces/favorites-repository";

const context = { userId: "user-1", tenantId: "tenant-1" };

class InMemoryFavoritesRepository implements FavoritesRepository {
  private readonly favorites: FavoriteEntity[] = [];

  async findById(id: string, tenantId: string): Promise<FavoriteEntity | null> {
    return this.favorites.find((item) => item.id === id && item.tenantId === tenantId) ?? null;
  }

  async listByCustomer(customerPhone: string, tenantId: string): Promise<FavoriteEntity[]> {
    return this.favorites.filter((item) => item.customerPhone === customerPhone && item.tenantId === tenantId);
  }

  async findByCustomerAndProduct(
    customerPhone: string,
    productId: string,
    tenantId: string,
  ): Promise<FavoriteEntity | null> {
    return (
      this.favorites.find(
        (item) =>
          item.customerPhone === customerPhone &&
          item.productId === productId &&
          item.tenantId === tenantId,
      ) ?? null
    );
  }

  async create(input: {
    customerPhone: string;
    productId: string;
    tenantId: string;
  }): Promise<FavoriteEntity> {
    const entity: FavoriteEntity = {
      id: crypto.randomUUID(),
      customerPhone: input.customerPhone,
      productId: input.productId,
      tenantId: input.tenantId,
      createdAt: new Date().toISOString(),
    };
    this.favorites.push(entity);
    return entity;
  }

  async delete(id: string, tenantId: string): Promise<void> {
    const index = this.favorites.findIndex((item) => item.id === id && item.tenantId === tenantId);
    if (index >= 0) this.favorites.splice(index, 1);
  }

  async productBelongsToTenant(productId: string, tenantId: string): Promise<boolean> {
    return productId === "550e8400-e29b-41d4-a716-446655440000" && tenantId === "tenant-1";
  }

  async userCanAccessTenant(userId: string, tenantId: string): Promise<boolean> {
    return userId === "user-1" && tenantId === "tenant-1";
  }
}

describe("favorites service", () => {
  it("adiciona e remove favorito no toggle", async () => {
    const repository = new InMemoryFavoritesRepository();
    const service = new FavoritesService(repository);

    const add = await service.toggleFavorite(
      {
        customerPhone: "+5511999999999",
        productId: "550e8400-e29b-41d4-a716-446655440000",
      },
      context,
    );
    expect(add.action).toBe("added");

    const remove = await service.toggleFavorite(
      {
        customerPhone: "+5511999999999",
        productId: "550e8400-e29b-41d4-a716-446655440000",
      },
      context,
    );
    expect(remove.action).toBe("removed");
  });

  it("bloqueia acesso entre tenants", async () => {
    const repository = new InMemoryFavoritesRepository();
    const service = new FavoritesService(repository);

    await expect(
      service.listByCustomer("+5511999999999", { userId: "user-2", tenantId: "tenant-1" }),
    ).rejects.toThrow(AppError);
  });
});
