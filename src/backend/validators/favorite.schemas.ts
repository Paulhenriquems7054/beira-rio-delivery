import { z } from "zod";
import { safePhoneSchema, uuidSchema } from "@/backend/validators/common";

export const createFavoriteSchema = z.object({
  customerPhone: safePhoneSchema,
  productId: uuidSchema,
});

export const updateFavoriteSchema = z.object({
  customerPhone: safePhoneSchema.optional(),
  productId: uuidSchema.optional(),
});

export const favoriteIdParamsSchema = z.object({
  favoriteId: uuidSchema,
});

export type CreateFavoriteInput = z.infer<typeof createFavoriteSchema>;
export type UpdateFavoriteInput = z.infer<typeof updateFavoriteSchema>;
