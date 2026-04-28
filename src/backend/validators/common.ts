import { z } from "zod";

export const uuidSchema = z.string().uuid("UUID inválido");

export const safePhoneSchema = z
  .string()
  .trim()
  .regex(/^\+?[1-9]\d{7,14}$/, "Telefone inválido")
  .max(16, "Telefone excede o limite");

export const safeString = (fieldName: string, min = 1, max = 120) =>
  z
    .string({ required_error: `${fieldName} é obrigatório` })
    .trim()
    .min(min, `${fieldName} deve ter pelo menos ${min} caracteres`)
    .max(max, `${fieldName} deve ter no máximo ${max} caracteres`);
