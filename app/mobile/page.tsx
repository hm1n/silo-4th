import type { Metadata } from "next";
import { CopyCurrentUrl } from "./copy-current-url";

export const metadata: Metadata = {
  title: "PC에서 열어 주세요",
};

// 모바일로 들어오면 `proxy.ts`가 주소는 그대로 두고 이 화면을 보여 준다. 최종 모양은 Linear 4-5 디자인을 따른다.
export default function MobileNotice() {
  return (
    <main>
      <h1>PC에서 열어 주세요</h1>
      <p>아래 주소를 PC 브라우저에서 열면 이어서 시작할 수 있어요.</p>
      <CopyCurrentUrl />
    </main>
  );
}
