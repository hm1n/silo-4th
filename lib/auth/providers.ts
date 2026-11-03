export const providers = {
  google: { label: "Google로 계속하기" },
} as const satisfies Record<string, { label: string }>;

export type ProviderId = keyof typeof providers;

export const enabledProviders: readonly ProviderId[] = ["google"];

export type LoginButton = { provider: ProviderId; label: string };

export function loginButtons(enabled: readonly ProviderId[]): LoginButton[] {
  return enabled.map((provider) => ({ provider, label: providers[provider].label }));
}
