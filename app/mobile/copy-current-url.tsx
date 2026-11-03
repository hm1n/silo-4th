"use client";

import { useState, useSyncExternalStore } from "react";

type CopyStatus = "idle" | "copied" | "failed";

const subscribe = () => () => {};

// 주소창의 주소를 그대로 보여 준다. 안내 화면은 원래 주소에 덮어 보여 주므로 `?from=`까지 남아 있다.
export function CopyCurrentUrl() {
  const url = useSyncExternalStore(
    subscribe,
    () => window.location.href,
    () => "",
  );
  const [status, setStatus] = useState<CopyStatus>("idle");

  async function copy() {
    try {
      // HTTPS가 아니면 clipboard가 없어 예외가 난다.
      await navigator.clipboard.writeText(url);
      setStatus("copied");
    } catch {
      setStatus("failed");
    }
  }

  return (
    <div>
      <p>{url}</p>
      <button type="button" disabled={!url} onClick={copy}>
        주소 복사
      </button>
      {status === "copied" && <p role="status">주소를 복사했어요</p>}
      {status === "failed" && <p role="alert">복사하지 못했어요. 주소를 길게 눌러 복사해 주세요.</p>}
    </div>
  );
}
