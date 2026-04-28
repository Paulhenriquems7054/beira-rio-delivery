export interface FavoriteEntity {
  id: string;
  tenantId: string;
  customerPhone: string;
  productId: string;
  createdAt: string;
}

export interface FavoritesRepository {
  findById(id: string, tenantId: string): Promise<FavoriteEntity | null>;
  listByCustomer(customerPhone: string, tenantId: string): Promise<FavoriteEntity[]>;
  findByCustomerAndProduct(
    customerPhone: string,
    productId: string,
    tenantId: string,
  ): Promise<FavoriteEntity | null>;
  create(input: { customerPhone: string; productId: string; tenantId: string }): Promise<FavoriteEntity>;
  delete(id: string, tenantId: string): Promise<void>;
  productBelongsToTenant(productId: string, tenantId: string): Promise<boolean>;
  userCanAccessTenant(userId: string, tenantId: string): Promise<boolean>;
}
