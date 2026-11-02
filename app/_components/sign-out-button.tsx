"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { authClient, succeeded } from "@/lib/auth/client";

export function SignOutButton() {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [failed, setFailed] = useState(false);

  async function signOut() {
    setPending(true);
    setFailed(false);
    if (await succeeded(authClient.signOut())) {
      router.refresh();
      return;
    }
    setFailed(true);
    setPending(false);
  }

  return (
    <div>
      {failed && <p role="alert">로그아웃하지 못했어요. 다시 시도해 주세요.</p>}
      <button type="button" disabled={pending} onClick={signOut}>
        로그아웃
      </button>
    </div>
  );
}
