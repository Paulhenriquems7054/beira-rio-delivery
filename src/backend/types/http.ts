export interface RequestContext {
  userId: string;
  tenantId: string;
  role?: "owner" | "manager" | "staff" | "superadmin";
  requestId?: string;
}

export interface ApiRequest<TBody = unknown, TParams = Record<string, string>> {
  body: TBody;
  params: TParams;
  context: RequestContext;
}

export interface ApiResponse<TData = unknown> {
  success: boolean;
  data?: TData;
  error?: {
    code: string;
    message: string;
    details: Record<string, unknown>;
  };
}
