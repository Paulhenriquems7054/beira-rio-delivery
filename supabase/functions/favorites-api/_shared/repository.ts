import type { SupabaseClient } from "npm:@supabase/supabase-js@2.49.8";
import { AppError, ERROR_CODES } from "./error.ts";

export interface FavoriteEntity {
  id: string;
  tenantId: string;
  customerPhone: string;
  productId: string;
  createdAt: string;
}

type FavoriteRow = {
  id: string;
  store_id: string;
  customer_phone: string;
  product_id: string;
  created_at: string;
};

const FAVORITES_TABLE = "favorites";

function mapFavorite(row: FavoriteRow): FavoriteEntity {
  return {
    id: row.id,
    tenantId: row.store_id,
    customerPhone: row.customer_phone,
    productId: row.product_id,
    createdAt: row.created_at,
  };
}

export class FavoritesRepository {
  constructor(private readonly db: SupabaseClient) {}

  async userCanAccessTenant(userId: string, tenantId: string): Promise<boolean> {
    const { data, error } = await this.db
      .from("stores")
      .select("id")
      .eq("id", tenantId)
      .eq("user_id", userId)
      .maybeSingle();
    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Erro ao validar tenant", 500);
    return Boolean(data);
  }

  async productBelongsToTenant(productId: string, tenantId: string): Promise<boolean> {
    const { data, error } = await this.db
      .from("products")
      .select("id")
      .eq("id", productId)
      .eq("store_id", tenantId)
      .maybeSingle();
    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Erro ao validar produto", 500);
    return Boolean(data);
  }

  async listByCustomer(customerPhone: string, tenantId: string): Promise<FavoriteEntity[]> {
    const { data, error } = await this.db
      .from(FAVORITES_TABLE)
      .select("id, store_id, customer_phone, product_id, created_at")
      .eq("store_id", tenantId)
      .eq("customer_phone", customerPhone)
      .order("created_at", { ascending: false });
    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Erro ao listar favoritos", 500);
    return (data ?? []).map((row) => mapFavorite(row as FavoriteRow));
  }

  async findByCustomerAndProduct(
    customerPhone: string,
    productId: string,
    tenantId: string,
  ): Promise<FavoriteEntity | null> {
    const { data, error } = await this.db
      .from(FAVORITES_TABLE)
      .select("id, store_id, customer_phone, product_id, created_at")
      .eq("store_id", tenantId)
      .eq("customer_phone", customerPhone)
      .eq("product_id", productId)
      .maybeSingle();
    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Erro ao consultar favorito", 500);
    return data ? mapFavorite(data as FavoriteRow) : null;
  }

  async findById(id: string, tenantId: string): Promise<FavoriteEntity | null> {
    const { data, error } = await this.db
      .from(FAVORITES_TABLE)
      .select("id, store_id, customer_phone, product_id, created_at")
      .eq("id", id)
      .eq("store_id", tenantId)
      .maybeSingle();
    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Erro ao buscar favorito", 500);
    return data ? mapFavorite(data as FavoriteRow) : null;
  }

  async create(input: { tenantId: string; customerPhone: string; productId: string }): Promise<FavoriteEntity> {
    const { data, error } = await this.db
      .from(FAVORITES_TABLE)
      .insert({
        store_id: input.tenantId,
        customer_phone: input.customerPhone,
        product_id: input.productId,
      })
      .select("id, store_id, customer_phone, product_id, created_at")
      .single();
    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Erro ao criar favorito", 500, { error });
    return mapFavorite(data as FavoriteRow);
  }

  async deleteById(id: string, tenantId: string): Promise<void> {
    const { error } = await this.db.from(FAVORITES_TABLE).delete().eq("id", id).eq("store_id", tenantId);
    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Erro ao remover favorito", 500);
  }
}
