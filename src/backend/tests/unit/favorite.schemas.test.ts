import { describe, expect, it } from "vitest";
import { createFavoriteSchema } from "@/backend/validators/favorite.schemas";
import { validateSchema } from "@/backend/validators/validate-schema";
import { AppError } from "@/backend/errors/app-error";

describe("favorite schema validation", () => {
  it("aceita payload valido", () => {
    const payload = {
      customerPhone: "+5511999999999",
      productId: "550e8400-e29b-41d4-a716-446655440000",
    };

    const parsed = validateSchema(createFavoriteSchema, payload);
    expect(parsed.customerPhone).toBe(payload.customerPhone);
  });

  it("rejeita telefone invalido", () => {
    expect(() =>
      validateSchema(createFavoriteSchema, {
        customerPhone: "abc",
        productId: "550e8400-e29b-41d4-a716-446655440000",
      }),
    ).toThrow(AppError);
  });
});
