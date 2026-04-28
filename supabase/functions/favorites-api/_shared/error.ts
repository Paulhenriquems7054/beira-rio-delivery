export const ERROR_CODES = {
  VALIDATION_ERROR: "VALIDATION_ERROR",
  BUSINESS_RULE_ERROR: "BUSINESS_RULE_ERROR",
  UNAUTHORIZED: "UNAUTHORIZED",
  NOT_FOUND: "NOT_FOUND",
  INTERNAL_ERROR: "INTERNAL_ERROR",
} as const;

export type ErrorCode = (typeof ERROR_CODES)[keyof typeof ERROR_CODES];

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly status: number;
  readonly details: Record<string, unknown>;

  constructor(
    code: ErrorCode,
    message: string,
    status = 400,
    details: Record<string, unknown> = {},
  ) {
    super(message);
    this.code = code;
    this.status = status;
    this.details = details;
  }
}

export function toErrorResponse(error: unknown) {
  if (error instanceof AppError) {
    return {
      status: error.status,
      body: {
        success: false,
        error: {
          code: error.code,
          message: error.message,
          details: error.details,
        },
      },
    };
  }

  console.error("[favorites-api] unhandled error", error);
  return {
    status: 500,
    body: {
      success: false,
      error: {
        code: ERROR_CODES.INTERNAL_ERROR,
        message: "Erro interno do servidor",
        details: {},
      },
    },
  };
}
