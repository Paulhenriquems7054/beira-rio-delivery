import { z } from "npm:zod@3.25.76";
import { AppError, ERROR_CODES } from "./error.ts";

export const uuidSchema = z.string().uuid("UUID inválido");
export const customerPhoneSchema = z
  .string()
  .trim()
  .regex(/^\+?[1-9][0-9]{7,14}$/, "Telefone inválido");

export const createFavoriteSchema = z.object({
  customerPhone: customerPhoneSchema,
  productId: uuidSchema,
});

export const listFavoritesSchema = z.object({
  customerPhone: customerPhoneSchema,
});

export const favoriteIdSchema = z.object({
  favoriteId: uuidSchema,
});

export function validateSchema<T>(schema: z.ZodType<T>, payload: unknown): T {
  const parsed = schema.safeParse(payload);
  if (!parsed.success) {
    const issue = parsed.error.issues[0];
    throw new AppError(
      ERROR_CODES.VALIDATION_ERROR,
      issue?.message ?? "Payload inválido",
      400,
      {
        field: issue?.path.join(".") ?? "unknown",
        issues: parsed.error.issues.map((currentIssue) => ({
          field: currentIssue.path.join("."),
          message: currentIssue.message,
        })),
      },
    );
  }

  return parsed.data;
}
