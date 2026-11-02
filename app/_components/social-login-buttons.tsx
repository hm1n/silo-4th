"use client";

import { authClient } from "@/lib/auth/client";
import { loginNotice } from "@/lib/auth/login-notice";
import { enabledProviders, loginButtons } from "@/lib/auth/providers";

export function SocialLoginButtons({ error }: { error?: string }) {
  const notice = loginNotice(error);

  return (
    <div>
      {notice && <p role="alert">{notice}</p>}
      {loginButtons(enabledProviders).map(({ provider, label }) => (
        <button
          key={provider}
          type="button"
          onClick={() =>
            authClient.signIn.social({ provider, callbackURL: "/study", errorCallbackURL: "/" })
          }
        >
          {label}
        </button>
      ))}
    </div>
  );
}
