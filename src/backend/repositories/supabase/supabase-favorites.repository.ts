import type { SupabaseClient } from "@supabase/supabase-js";
import { AppError } from "@/backend/errors/app-error";
import { ERROR_CODES } from "@/backend/errors/error-codes";
import type {
  FavoriteEntity,
  FavoritesRepository,
} from "@/backend/repositories/interfaces/favorites-repository";

type FavoriteRow = {
  id: string;
  store_id: string;
  customer_phone: string;
  product_id: string;
  created_at: string;
};

const FAVORITES_TABLE = "favorites";

function mapFavoriteRow(row: FavoriteRow): FavoriteEntity {
  return {
    id: row.id,
    tenantId: row.store_id,
    customerPhone: row.customer_phone,
    productId: row.product_id,
    createdAt: row.created_at,
  };
}

export class SupabaseFavoritesRepository implements FavoritesRepository {
  constructor(private readonly db: SupabaseClient<any>) {}

  async findById(id: string, tenantId: string): Promise<FavoriteEntity | null> {
    const { data, error } = await this.db
      .from(FAVORITES_TABLE)
      .select("id, store_id, customer_phone, product_id, created_at")
      .eq("id", id)
      .eq("store_id", tenantId)
      .maybeSingle();

    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Falha ao buscar favorito", 500, { error });
    return data ? mapFavoriteRow(data as FavoriteRow) : null;
  }

  async listByCustomer(customerPhone: string, tenantId: string): Promise<FavoriteEntity[]> {
    const { data, error } = await this.db
      .from(FAVORITES_TABLE)
      .select("id, store_id, customer_phone, product_id, created_at")
      .eq("customer_phone", customerPhone)
      .eq("store_id", tenantId);

    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Falha ao listar favoritos", 500, { error });
    return (data ?? []).map((row: FavoriteRow) => mapFavoriteRow(row));
  }

  async findByCustomerAndProduct(
    customerPhone: string,
    productId: string,
    tenantId: string,
  ): Promise<FavoriteEntity | null> {
    const { data, error } = await this.db
      .from(FAVORITES_TABLE)
      .select("id, store_id, customer_phone, product_id, created_at")
      .eq("customer_phone", customerPhone)
      .eq("product_id", productId)
      .eq("store_id", tenantId)
      .maybeSingle();

    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Falha ao consultar favorito", 500, { error });
    return data ? mapFavoriteRow(data as FavoriteRow) : null;
  }

  async create(input: {
    customerPhone: string;
    productId: string;
    tenantId: string;
  }): Promise<FavoriteEntity> {
    const { data, error } = await this.db
      .from(FAVORITES_TABLE)
      .insert({
        customer_phone: input.customerPhone,
        product_id: input.productId,
        store_id: input.tenantId,
      })
      .select("id, store_id, customer_phone, product_id, created_at")
      .single();

    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Falha ao criar favorito", 500, { error });
    return mapFavoriteRow(data as FavoriteRow);
  }

  async delete(id: string, tenantId: string): Promise<void> {
    const { error } = await this.db.from(FAVORITES_TABLE).delete().eq("id", id).eq("store_id", tenantId);
    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Falha ao remover favorito", 500, { error });
  }

  async productBelongsToTenant(productId: string, tenantId: string): Promise<boolean> {
    const { data, error } = await this.db
      .from("products")
      .select("id")
      .eq("id", productId)
      .eq("store_id", tenantId)
      .maybeSingle();

    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Falha ao validar produto", 500, { error });
    return Boolean(data);
  }

  async userCanAccessTenant(userId: string, tenantId: string): Promise<boolean> {
    const { data, error } = await this.db
      .from("stores")
      .select("id")
      .eq("id", tenantId)
      .eq("user_id", userId)
      .maybeSingle();

    if (error) throw new AppError(ERROR_CODES.INTERNAL_ERROR, "Falha ao validar tenant", 500, { error });
    return Boolean(data);
  }
}
