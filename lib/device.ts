import { userAgent } from "next/server";

// 태블릿을 모바일로 볼지 PC로 볼지 PO와 디자이너가 정하기 전까지는 모바일로 본다. 근거는 Linear 4-50 "열린 질문"이다.
// iPad Safari는 기본으로 PC처럼 요청하므로 여기서는 PC로 잡힌다.
const MOBILE_DEVICE_TYPES = new Set(["mobile", "tablet"]);

// 화면 폭이 아니라 요청 헤더로 판별한다. 모바일에서 "데스크톱 사이트 요청"을 켜면 PC로 본다.
export function isMobileRequest(headers: Headers): boolean {
  const { type } = userAgent({ headers }).device;
  return type !== undefined && MOBILE_DEVICE_TYPES.has(type);
}
