import { sql } from "drizzle-orm";
import {
  boolean,
  check,
  date,
  index,
  integer,
  pgTable,
  primaryKey,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from "drizzle-orm/pg-core";
import { DIRECT_SOURCE } from "@/lib/source";

export const QUESTION_STATUSES = ["pending", "ok", "error"] as const;
export const MESSAGE_ROLES = ["user", "assistant"] as const;

function oneOf(values: readonly string[]) {
  return sql.raw(values.map((value) => `'${value}'`).join(", "));
}

const timestamps = {
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .defaultNow()
    .$onUpdate(() => new Date())
    .notNull(),
};

export const learner = pgTable("learners", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  email: text("email").notNull().unique(),
  emailVerified: boolean("email_verified").default(false).notNull(),
  image: text("image"),
  consentedAt: timestamp("consented_at", { withTimezone: true }),
  examDate: date("exam_date"),
  source: text("source").default(DIRECT_SOURCE).notNull(),
  isTest: boolean("is_test").default(false).notNull(),
  ...timestamps,
});

export const account = pgTable(
  "account",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    providerId: text("provider_id").notNull(),
    accountId: text("account_id").notNull(),
    userId: uuid("learner_id")
      .notNull()
      .references(() => learner.id, { onDelete: "cascade" }),
    accessToken: text("access_token"),
    refreshToken: text("refresh_token"),
    idToken: text("id_token"),
    accessTokenExpiresAt: timestamp("access_token_expires_at", { withTimezone: true }),
    refreshTokenExpiresAt: timestamp("refresh_token_expires_at", { withTimezone: true }),
    scope: text("scope"),
    password: text("password"),
    ...timestamps,
  },
  (table) => [
    uniqueIndex("account_provider_account_idx").on(table.providerId, table.accountId),
    index("account_learner_id_idx").on(table.userId),
  ],
);

export const session = pgTable(
  "session",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    token: text("token").notNull().unique(),
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
    ipAddress: text("ip_address"),
    userAgent: text("user_agent"),
    userId: uuid("learner_id")
      .notNull()
      .references(() => learner.id, { onDelete: "cascade" }),
    ...timestamps,
  },
  (table) => [index("session_learner_id_idx").on(table.userId)],
);

export const verification = pgTable(
  "verification",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    identifier: text("identifier").notNull(),
    value: text("value").notNull(),
    expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
    ...timestamps,
  },
  (table) => [index("verification_identifier_idx").on(table.identifier)],
);

// 단원과 개념 ID는 한 번 넣으면 바꾸지 않는다. 바꾸면 기존 질문이 다른 단원과 개념을 가리킨다.
export const unit = pgTable("units", {
  id: text("id").primaryKey(),
  title: text("title").notNull(),
  content: text("content").notNull(),
});

export const concept = pgTable("concepts", {
  id: text("id").primaryKey(),
  unitId: text("unit_id")
    .notNull()
    .references(() => unit.id),
  title: text("title").notNull(),
});

// 질문 창의 대화 하나다. 클라이언트가 ID를 만들고, 그 대화의 첫 질문을 저장할 때 함께 저장한다.
export const questionSession = pgTable(
  "question_sessions",
  {
    id: uuid("id").primaryKey(),
    learnerId: uuid("learner_id")
      .notNull()
      .references(() => learner.id),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [index("question_sessions_learner_id_idx").on(table.learnerId)],
);

// 질문 내역은 지우지 않으므로 학습자를 지워도 함께 지우지 않는다.
export const question = pgTable(
  "questions",
  {
    // 클라이언트가 만들어 보낸다. 같은 ID로 다시 오면 한 건만 남긴다.
    id: uuid("id").primaryKey(),
    learnerId: uuid("learner_id")
      .notNull()
      .references(() => learner.id),
    sessionId: uuid("session_id")
      .notNull()
      .references(() => questionSession.id),
    unitId: text("unit_id").references(() => unit.id),
    askedAt: timestamp("asked_at", { withTimezone: true }).defaultNow().notNull(),
    studyDay: date("study_day").notNull(),
    answeredAt: timestamp("answered_at", { withTimezone: true }),
    status: text("status", { enum: QUESTION_STATUSES }).default("pending").notNull(),
    appVersion: text("app_version").notNull(),
    summary: text("summary"),
    keywords: text("keywords").array(),
    summarizedAt: timestamp("summarized_at", { withTimezone: true }),
  },
  (table) => [
    index("questions_learner_id_idx").on(table.learnerId),
    index("questions_session_id_idx").on(table.sessionId),
    check("questions_status_check", sql`${table.status} in (${oneOf(QUESTION_STATUSES)})`),
  ],
);

export const questionConcept = pgTable(
  "question_concepts",
  {
    questionId: uuid("question_id")
      .notNull()
      .references(() => question.id),
    conceptId: text("concept_id")
      .notNull()
      .references(() => concept.id),
  },
  (table) => [
    primaryKey({ columns: [table.questionId, table.conceptId] }),
    index("question_concepts_concept_id_idx").on(table.conceptId),
  ],
);

export const message = pgTable(
  "messages",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    questionId: uuid("question_id")
      .notNull()
      .references(() => question.id),
    seq: integer("seq").notNull(),
    role: text("role", { enum: MESSAGE_ROLES }).notNull(),
    content: text("content").notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  },
  (table) => [
    uniqueIndex("messages_question_seq_idx").on(table.questionId, table.seq),
    check("messages_seq_check", sql`${table.seq} >= 1`),
    check("messages_role_check", sql`${table.role} in (${oneOf(MESSAGE_ROLES)})`),
  ],
);
