import { Suspense } from "react";
import { SignOutButton } from "@/app/_components/sign-out-button";
import { SocialLoginButtons } from "@/app/_components/social-login-buttons";
import { getCurrentLearner } from "@/lib/auth";

type SearchParams = Promise<{ [key: string]: string | string[] | undefined }>;

// 첫 화면은 4-51에서 만든다. 그 전까지 로그인을 직접 확인할 수 있게 버튼과 현재 학습자를 보여 준다.
export default function Home({ searchParams }: { searchParams: SearchParams }) {
  return (
    <main>
      <Suspense>
        <LoginStatus searchParams={searchParams} />
      </Suspense>
    </main>
  );
}

async function LoginStatus({ searchParams }: { searchParams: SearchParams }) {
  const { error } = await searchParams;
  const learner = await getCurrentLearner();

  if (learner) {
    return (
      <>
        <p>현재 학습자 ID: {learner.id}</p>
        <SignOutButton />
      </>
    );
  }
  return <SocialLoginButtons error={typeof error === "string" ? error : undefined} />;
}
