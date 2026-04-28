type LogPayload = Record<string, unknown>;

function formatPayload(payload?: LogPayload): string {
  if (!payload) return "";
  try {
    return ` ${JSON.stringify(payload)}`;
  } catch {
    return "";
  }
}

export const logger = {
  info(message: string, payload?: LogPayload) {
    console.info(`[INFO] ${message}${formatPayload(payload)}`);
  },
  warn(message: string, payload?: LogPayload) {
    console.warn(`[WARN] ${message}${formatPayload(payload)}`);
  },
  error(message: string, payload?: LogPayload) {
    console.error(`[ERROR] ${message}${formatPayload(payload)}`);
  },
};
