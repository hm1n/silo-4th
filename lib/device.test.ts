import { expect, it } from "vitest";
import { isMobileRequest } from "./device";

const userAgents = {
  androidChrome:
    "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36",
  iphoneSafari:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1",
  windowsChrome:
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36",
  macSafari:
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15",
};

function isMobile(userAgent: string) {
  return isMobileRequest(new Headers({ "user-agent": userAgent }));
}

it("TC-21 휴대폰은 모바일로, PC는 PC로 판별해요", () => {
  expect(isMobile(userAgents.androidChrome)).toBe(true);
  expect(isMobile(userAgents.iphoneSafari)).toBe(true);
  expect(isMobile(userAgents.windowsChrome)).toBe(false);
  expect(isMobile(userAgents.macSafari)).toBe(false);
});
