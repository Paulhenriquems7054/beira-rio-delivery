import { AppError, isAppError } from "@/backend/errors/app-error";
import { ERROR_CODES } from "@/backend/errors/error-codes";
import { logger } from "@/backend/logging/logger";

export interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details: Record<string, unknown>;
  };
}

export function toErrorResponse(error: unknown): ErrorResponse {
  if (isAppError(error)) {
    return {
      success: false,
      error: {
        code: error.code,
        message: error.message,
        details: error.details ?? {},
      },
    };
  }

  logger.error("Unhandled error", { error });
  return {
    success: false,
    error: {
      code: ERROR_CODES.INTERNAL_ERROR,
      message: "Erro interno do servidor",
      details: {},
    },
  };
}

export function getErrorStatus(error: unknown): number {
  return error instanceof AppError ? error.status : 500;
}
