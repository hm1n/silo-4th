import { existsSync } from "node:fs";
import { defineConfig } from "drizzle-kit";

// drizzle-kit은 .env.local을 읽지 않아서 직접 불러온다.
if (existsSync(".env.local")) process.loadEnvFile(".env.local");

export default defineConfig({
  dialect: "postgresql",
  schema: "./lib/db/schema.ts",
  out: "./drizzle",
  dbCredentials: { url: process.env.DATABASE_URL ?? "" },
});
