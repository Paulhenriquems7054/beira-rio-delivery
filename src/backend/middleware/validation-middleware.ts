import type { z } from "zod";
import { validateSchema } from "@/backend/validators/validate-schema";

export function withValidation<TSchema extends z.ZodTypeAny, TInput, TOutput>(
  schema: TSchema,
  handler: (validated: z.infer<TSchema>) => Promise<TOutput>,
  getPayload: (input: TInput) => unknown = (input) => input,
) {
  return async (input: TInput): Promise<TOutput> => {
    const payload = getPayload(input);
    const validated = validateSchema(schema, payload);
    return handler(validated);
  };
}
