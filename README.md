This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## 환경 변수

`.env.example`을 복사해 `.env.local`을 만들고 값을 채운다. 키마다 어디서 값을 받는지 주석에 적혀 있다.

## 테스트

| 종류 | 실행 | 필요한 것 |
| --- | --- | --- |
| 단위 | `npm test` | 없음 |
| 통합 | `npm run test:integration` | `.env.test.local` |
| E2E | `npm run test:e2e` | `.env.local` |

### 통합 테스트

통합 테스트는 운영 DB가 아닌 Neon `test` 브랜치에 실제로 쓰고 지운다. 저장소 루트에 `.env.test.local`을 만들고 아래 키를 넣는다. 이 파일은 `.gitignore`에 걸려 올라가지 않는다.

```bash
# Neon 콘솔 > Branches > test > Connect에서 복사한다. 운영 브랜치 주소를 넣지 않는다.
DATABASE_URL=
# 아무 값이나 된다. `openssl rand -base64 32`로 만든다.
AUTH_SECRET=
AUTH_URL=http://localhost:3000
# Google 토큰 교환은 테스트에서 가짜 응답으로 바꾸므로 실제 값이 필요 없다.
AUTH_GOOGLE_ID=test-google-id
AUTH_GOOGLE_SECRET=test-google-secret
```

스키마를 바꿨다면 테스트 전에 test 브랜치에 마이그레이션을 적용한다.

```bash
node --env-file=.env.test.local node_modules/drizzle-kit/bin.cjs migrate
```

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
