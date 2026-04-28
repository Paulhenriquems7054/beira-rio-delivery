import type { z } from "zod";
import { AppError } from "@/backend/errors/app-error";
import { ERROR_CODES } from "@/backend/errors/error-codes";

export function validateSchema<TSchema extends z.ZodTypeAny>(
  schema: TSchema,
  payload: unknown,
): z.infer<TSchema> {
  const result = schema.safeParse(payload);

  if (!result.success) {
    const issue = result.error.issues[0];
    throw new AppError(
      ERROR_CODES.VALIDATION_ERROR,
      issue?.message ?? "Dados inválidos",
      400,
      {
        field: issue?.path?.join(".") ?? "unknown",
        issues: result.error.issues.map((currentIssue) => ({
          field: currentIssue.path.join("."),
          message: currentIssue.message,
        })),
      },
    );
  }

  return result.data;
}
