import { describe, expect, it } from "vitest";
import { FavoritesController } from "@/backend/controllers/favorites.controller";
import { FavoritesService } from "@/backend/services/favorites.service";
import type {
  FavoriteEntity,
  FavoritesRepository,
} from "@/backend/repositories/interfaces/favorites-repository";

class InMemoryDbFavoritesRepository implements FavoritesRepository {
  private readonly favorites: FavoriteEntity[] = [];
  private readonly allowedUserByTenant = new Map<string, string>([["tenant-1", "user-1"]]);
  private readonly productsByTenant = new Map<string, Set<string>>([
    ["tenant-1", new Set(["550e8400-e29b-41d4-a716-446655440000"])],
  ]);

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
    return this.productsByTenant.get(tenantId)?.has(productId) ?? false;
  }
  async userCanAccessTenant(userId: string, tenantId: string): Promise<boolean> {
    return this.allowedUserByTenant.get(tenantId) === userId;
  }
}

describe("favorites controller integration", () => {
  it("fluxo completo com isolamento por tenant", async () => {
    const repository = new InMemoryDbFavoritesRepository();
    const controller = new FavoritesController(new FavoritesService(repository));

    const toggleResponse = await controller.toggle({
      body: {
        customerPhone: "+5511999999999",
        productId: "550e8400-e29b-41d4-a716-446655440000",
      },
      params: {},
      context: { userId: "user-1", tenantId: "tenant-1" },
    });
    expect(toggleResponse.status).toBe(200);
    expect(toggleResponse.body.success).toBe(true);

    const unauthorizedListResponse = await controller.list({
      body: { customerPhone: "+5511999999999" },
      params: {},
      context: { userId: "user-2", tenantId: "tenant-1" },
    });
    expect(unauthorizedListResponse.status).toBe(403);
    expect(unauthorizedListResponse.body.success).toBe(false);
    expect(unauthorizedListResponse.body.error?.code).toBe("UNAUTHORIZED");
  });
});
