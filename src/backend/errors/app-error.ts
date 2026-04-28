import { ERROR_CODES, type ErrorCode } from "@/backend/errors/error-codes";

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly status: number;
  readonly details?: Record<string, unknown>;

  constructor(
    code: ErrorCode,
    message: string,
    status = 400,
    details?: Record<string, unknown>,
  ) {
    super(message);
    this.name = "AppError";
    this.code = code;
    this.status = status;
    this.details = details;
  }
}

export const isAppError = (error: unknown): error is AppError => error instanceof AppError;

export const internalError = (message = "Erro interno") =>
  new AppError(ERROR_CODES.INTERNAL_ERROR, message, 500);
