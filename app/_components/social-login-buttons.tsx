"use client";

import { useState } from "react";
import { authClient, succeeded } from "@/lib/auth/client";
import { loginNotice } from "@/lib/auth/login-notice";
import { enabledProviders, loginButtons, type ProviderId } from "@/lib/auth/providers";

export function SocialLoginButtons({ error }: { error?: string }) {
  const [pending, setPending] = useState(false);
  const [requestFailed, setRequestFailed] = useState(false);
  const notice = loginNotice(requestFailed ? "request_failed" : error);

  async function signIn(provider: ProviderId) {
    setPending(true);
    setRequestFailed(false);
    const started = await succeeded(
      authClient.signIn.social({ provider, callbackURL: "/study", errorCallbackURL: "/" }),
    );
    // 성공하면 Google로 이동하므로 버튼을 다시 켜지 않는다.
    if (!started) {
      setRequestFailed(true);
      setPending(false);
    }
  }

  return (
    <div>
      {notice && <p role="alert">{notice}</p>}
      {loginButtons(enabledProviders).map(({ provider, label }) => (
        <button key={provider} type="button" disabled={pending} onClick={() => signIn(provider)}>
          {label}
        </button>
      ))}
    </div>
  );
}
