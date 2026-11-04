import { redirect } from "next/navigation";
import { Suspense } from "react";
import { SignOutButton } from "@/app/_components/sign-out-button";
import { getCurrentLearner } from "@/lib/auth";
import { HOME_PATH, STUDY_PATH } from "@/lib/routes";
import { StartForm } from "./start-form";

export default function StartPage() {
  return (
    <main className="mx-auto flex w-full max-w-md flex-col gap-6 p-8">
      <Suspense>
        <StartGate />
      </Suspense>
    </main>
  );
}

async function StartGate() {
  const learner = await getCurrentLearner();
  if (!learner) redirect(HOME_PATH);
  if (learner.consentedAt) redirect(STUDY_PATH);
  return (
    <>
      <StartForm />
      {/* 동의하고 싶지 않은 학습자가 다른 계정으로 바꿀 수 있게 둔다. */}
      <SignOutButton />
    </>
  );
}
