// 환경 변수는 이 파일에서만 읽는다. 다른 파일의 process.env 접근은 eslint가 막는다.
// 값은 사용하는 시점에 읽어서, 키가 없어도 빌드는 통과하고 실제 호출에서만 실패한다.

function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`환경 변수 ${name}이 비어 있다. .env.example을 참고해 설정한다.`);
  return value;
}

export const env = {
  get ANTHROPIC_API_KEY() {
    return required("ANTHROPIC_API_KEY");
  },
  get ANTHROPIC_MODEL() {
    return required("ANTHROPIC_MODEL");
  },
  get DATABASE_URL() {
    return required("DATABASE_URL");
  },
  get AUTH_SECRET() {
    return required("AUTH_SECRET");
  },
  get AUTH_URL() {
    return required("AUTH_URL");
  },
  get AUTH_GOOGLE_ID() {
    return required("AUTH_GOOGLE_ID");
  },
  get AUTH_GOOGLE_SECRET() {
    return required("AUTH_GOOGLE_SECRET");
  },
};
