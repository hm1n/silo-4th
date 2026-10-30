"use client";

// 배포 환경의 Sentry 소스맵 확인용 임시 페이지다. 확인하면 지운다.
export default function SentryCheck() {
  return (
    <button
      type="button"
      onClick={() => {
        throw new Error("Sentry 소스맵 확인용 오류");
      }}
    >
      오류 보내기
    </button>
  );
}
