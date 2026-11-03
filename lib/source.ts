export const SOURCE_COOKIE = "from";
export const DIRECT_SOURCE = "direct";
export const TEST_SOURCE = "test";

const SOURCE_PATTERN = /^[a-z0-9_-]{1,32}$/;

export function normalizeSource(raw: string | null | undefined): string {
  const value = raw?.trim().toLowerCase() ?? "";
  return SOURCE_PATTERN.test(value) ? value : DIRECT_SOURCE;
}
