import "server-only";
import { captureException } from "@sentry/nextjs";
import { and, asc, desc, eq, lt, TransactionRollbackError } from "drizzle-orm";
import { alias } from "drizzle-orm/pg-core";
import { safeMessage } from "@/lib/auth/sentry-logger";
import { getDb } from "@/lib/db";
import { message, question, questionSession, unit } from "@/lib/db/schema";
import { env } from "@/lib/env";
import { streamAnswer } from "@/lib/llm/answer";
import { type SessionSummary, type SessionTurn, toSessionList } from "@/lib/question-sessions";
import { studyDay } from "@/lib/study-day";

export type AskInput = { questionId: string; sessionId: string; unitId: string; content: string };

export type Claim =
  // 이 요청이 AI 답을 받아 저장해야 한다.
  | { kind: "answer" }
  | { kind: "saved"; answer: string }
  // 같은 질문 ID로 온 다른 요청이 아직 답을 받고 있다.
  | { kind: "pending" }
  | { kind: "unknown-unit" }
  | { kind: "not-yours" };

// DB 오류 메시지는 쿼리 값으로 질문 원문과 AI 답을 담는다. 값을 지운 메시지만 Sentry로 보낸다.
export function reportQuestionError(error: unknown) {
  captureException(new Error(safeMessage(error, "questions")));
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
// 질문은 그대로 저장하고 AI에게도 넘기므로, 화면을 거치지 않고 아주 긴 글을 보내지 못하게 막는다.
const MAX_QUESTION_LENGTH = 4000;

// 요청 본문은 화면을 거치지 않고도 보낼 수 있어 타입과 달리 아무 값이나 올 수 있다.
export function parseAskInput(input: unknown): AskInput | undefined {
  if (typeof input !== "object" || input === null) return undefined;
  const { questionId, sessionId, unitId, content } = input as Record<string, unknown>;
  if (typeof questionId !== "string" || !UUID.test(questionId)) return undefined;
  if (typeof sessionId !== "string" || !UUID.test(sessionId)) return undefined;
  if (typeof unitId !== "string" || typeof content !== "string") return undefined;
  if (!content.trim() || content.length > MAX_QUESTION_LENGTH) return undefined;
  return { questionId, sessionId, unitId, content };
}

// 새 질문이면 저장하고, 같은 질문 ID가 다시 왔으면 저장된 상태를 보고 이 요청이 할 일을 정한다.
// 세션은 그 세션의 첫 질문과 함께 저장한다. 이미 있는 질문이면 처음 저장한 세션에 그대로 둔다.
export async function claimQuestion(
  learnerId: string,
  { questionId, sessionId, unitId, content }: AskInput,
): Promise<Claim> {
  const db = getDb();
  const [opened] = await db.select({ id: unit.id }).from(unit).where(eq(unit.id, unitId));
  if (!opened) return { kind: "unknown-unit" };

  const askedAt = new Date();
  const saved = await db
    .transaction(async (tx) => {
      await tx.insert(questionSession).values({ id: sessionId, learnerId }).onConflictDoNothing();
      const [owner] = await tx
        .select({ learnerId: questionSession.learnerId })
        .from(questionSession)
        .where(eq(questionSession.id, sessionId));
      if (owner?.learnerId !== learnerId) return "not-yours";
      const [row] = await tx
        .insert(question)
        .values({
          id: questionId,
          learnerId,
          sessionId,
          unitId,
          askedAt,
          studyDay: studyDay(askedAt),
          appVersion: env.APP_VERSION,
        })
        .onConflictDoNothing()
        .returning({ id: question.id });
      // 이미 있는 질문이면 이 요청이 새로 만든 세션도 남기지 않는다.
      if (!row) tx.rollback();
      await tx.insert(message).values({ questionId, seq: 1, role: "user", content });
      return "created";
    })
    .catch((error: unknown) => {
      if (error instanceof TransactionRollbackError) return "exists";
      throw error;
    });
  if (saved === "not-yours") return { kind: "not-yours" };
  if (saved === "created") return { kind: "answer" };

  const [existing] = await db
    .select({ learnerId: question.learnerId, status: question.status })
    .from(question)
    .where(eq(question.id, questionId));
  if (existing?.learnerId !== learnerId) return { kind: "not-yours" };
  if (existing.status === "ok") return { kind: "saved", answer: await savedAnswer(questionId) };

  // 실패한 질문만 다시 시도한다. 같은 질문이 동시에 다시 와도 한 요청만 줄을 가져간다.
  const [retried] = await db
    .update(question)
    .set({ status: "pending" })
    .where(and(eq(question.id, questionId), eq(question.status, "error")))
    .returning({ id: question.id });
  return retried ? { kind: "answer" } : { kind: "pending" };
}

async function savedAnswer(questionId: string) {
  const [saved] = await getDb()
    .select({ content: message.content })
    .from(message)
    .where(and(eq(message.questionId, questionId), eq(message.role, "assistant")))
    .orderBy(desc(message.seq))
    .limit(1);
  if (!saved) throw new Error("ok인 질문에 AI 답이 없다.");
  return saved.content;
}

// 저장이 커밋됐는데 실패로 보고된 경우에는 이미 ok이므로 건드리지 않는다.
function markError(questionId: string) {
  return getDb()
    .update(question)
    .set({ status: "error" })
    .where(and(eq(question.id, questionId), eq(question.status, "pending")));
}

// claimQuestion이 answer를 돌려준 질문에 AI 답을 받아 저장한다. 답 글은 생기는 대로 onText로 넘긴다.
// 다시 시도할 때도 처음 저장한 단원과 질문 원문으로 묻는다.
// 같은 세션에서 이 질문보다 먼저 묻고 답을 받은 질문과 답을 함께 넘겨, 앞의 대화를 알고 답하게 한다.
// 이 요청이 가져간 줄이므로, 어디서 실패하든 error로 돌려놓아야 다시 시도할 수 있다. 중간에 받은 답 조각은 저장하지 않는다.
export async function answerQuestion(questionId: string, onText: (text: string) => void): Promise<"ok" | "error"> {
  const db = getDb();
  try {
    const [asked] = await db
      .select({
        unitContent: unit.content,
        question: message.content,
        sessionId: question.sessionId,
        askedAt: question.askedAt,
      })
      .from(message)
      .innerJoin(question, eq(question.id, message.questionId))
      .innerJoin(unit, eq(unit.id, question.unitId))
      .where(and(eq(message.questionId, questionId), eq(message.seq, 1)));
    if (!asked) throw new Error("답할 질문을 찾지 못했다.");
    const history = await db
      .select({ role: message.role, content: message.content })
      .from(message)
      .innerJoin(question, eq(question.id, message.questionId))
      .where(
        and(eq(question.sessionId, asked.sessionId), eq(question.status, "ok"), lt(question.askedAt, asked.askedAt)),
      )
      .orderBy(asc(question.askedAt), asc(question.id), asc(message.seq));

    let reply: string;
    try {
      reply = await streamAnswer({ unitContent: asked.unitContent, history, question: asked.question }, onText);
    } catch (error) {
      // Anthropic SDK 오류는 보낸 질문을 담지 않는다.
      captureException(error);
      await markError(questionId);
      return "error";
    }

    await db.transaction(async (tx) => {
      await tx.insert(message).values({ questionId, seq: 2, role: "assistant", content: reply });
      await tx.update(question).set({ status: "ok", answeredAt: new Date() }).where(eq(question.id, questionId));
    });
    return "ok";
  } catch (error) {
    await markError(questionId);
    throw error;
  }
}

// 질문 창의 세션 목록이다. 질문을 한 번도 저장하지 않은 세션은 목록에 없다.
export async function listSessions(learnerId: string): Promise<SessionSummary[]> {
  const asked = await getDb()
    .select({ sessionId: question.sessionId, content: message.content, askedAt: question.askedAt })
    .from(question)
    .innerJoin(message, and(eq(message.questionId, question.id), eq(message.seq, 1)))
    .where(eq(question.learnerId, learnerId));
  return toSessionList(asked);
}

// 학습자의 세션이 아니면 undefined를 돌려준다. 세션 ID는 주소에서 오므로 아무 값이나 올 수 있다.
export async function sessionTurns(learnerId: string, sessionId: string): Promise<SessionTurn[] | undefined> {
  if (!UUID.test(sessionId)) return undefined;
  const db = getDb();
  const [owned] = await db
    .select({ id: questionSession.id })
    .from(questionSession)
    .where(and(eq(questionSession.id, sessionId), eq(questionSession.learnerId, learnerId)));
  if (!owned) return undefined;
  const answer = alias(message, "answer");
  return db
    .select({ questionId: question.id, unitId: question.unitId, content: message.content, answer: answer.content })
    .from(question)
    .innerJoin(message, and(eq(message.questionId, question.id), eq(message.seq, 1)))
    .leftJoin(answer, and(eq(answer.questionId, question.id), eq(answer.seq, 2)))
    .where(eq(question.sessionId, sessionId))
    .orderBy(asc(question.askedAt), asc(question.id));
}
