// 로그인 실패로 돌아오면 Better Auth가 `?error=<코드>`를 붙인다. Google 화면에서 취소하면 access_denied가 온다.
export function loginNotice(error: string | undefined): string | null {
  if (!error) return null;
  if (error === "access_denied") return "로그인을 취소했어요";
  return "로그인하지 못했어요. 다시 시도해 주세요.";
}
