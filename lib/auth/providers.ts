// 브라우저와 서버가 함께 쓰는 로그인 방법 목록. 비밀값은 lib/auth/index.ts에서만 읽는다.
// 카카오나 네이버를 더하려면 여기에 항목을 넣고, 서버 설정에 키를 잇고, enabledProviders에 켠다.
export const providers = {
  google: { label: "Google로 계속하기" },
} as const satisfies Record<string, { label: string }>;

export type ProviderId = keyof typeof providers;

export const enabledProviders: readonly ProviderId[] = ["google"];

export type LoginButton = { provider: ProviderId; label: string };

export function loginButtons(enabled: readonly ProviderId[]): LoginButton[] {
  return enabled.map((provider) => ({ provider, label: providers[provider].label }));
}
