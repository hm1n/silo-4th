import { Suspense } from "react";
import { SocialLoginButtons } from "@/app/_components/social-login-buttons";

// 로그인한 학습자는 `proxy.ts`가 학습 화면으로 보내므로, 이 화면은 로그인하지 않은 사람만 본다.
export default function Home({ searchParams }: PageProps<"/">) {
  return (
    <main className="mx-auto flex w-full max-w-md flex-col gap-6 p-8">
      <p>오늘 AI에게 물어본 내용, 내일 진짜 혼자 풀 수 있는지 확인해 드려요</p>
      <Suspense>
        <Login searchParams={searchParams} />
      </Suspense>
    </main>
  );
}

async function Login({ searchParams }: Pick<PageProps<"/">, "searchParams">) {
  const { error } = await searchParams;
  return <SocialLoginButtons error={typeof error === "string" ? error : undefined} />;
}
