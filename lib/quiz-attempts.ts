import "server-only";
import { captureException } from "@sentry/nextjs";
import { eq } from "drizzle-orm";
import { safeMessage } from "@/lib/auth/sentry-logger";
import { getDb } from "@/lib/db";
import { CONFIDENCES, type GRADINGS, type QuizAnswer, quizAttempt, quizProblem } from "@/lib/db/schema";
import { env } from "@/lib/env";
import { gradeFreeAnswer } from "@/lib/llm/grading";
import {
  type BlankAnswer,
  type ChoiceAnswer,
  type FreeAnswer,
  type GradableProblem,
  gradeBlank,
  gradeChoice,
  toGradable,
} from "@/lib/quiz-grading";
import { studyDay } from "@/lib/study-day";

type Confidence = (typeof CONFIDENCES)[number];
type Grading = (typeof GRADINGS)[number];

export type AttemptInput = {
  attemptId: string;
  problemId: string;
  chosenIndex: number | null;
  // 공백만 있으면 비어 있는 것으로 바꿔 둔다.
  answerText: string | null;
  confidence: Confidence | null;
  hintUsed: boolean;
  dontKnow: boolean;
};

// 채점 결과와 함께 정답과 해설을 내려준다. 서술형 잘 모르겠어요는 해설 없이 다음 문제로 가므로 저장 확인만 담는다.
export type AttemptResult =
  | { outcome: "graded"; format: "mcq" | "blank"; isCorrect: boolean; answer: QuizAnswer; explanation: string }
  | {
      outcome: "graded";
      format: "free";
      grading: Grading;
      gradingReason: string | null;
      answer: QuizAnswer;
      explanation: string;
    }
  | { outcome: "ungraded"; answer: QuizAnswer; explanation: string }
  | { outcome: "skipped" };

export type Submission =
  | { kind: "saved"; result: AttemptResult }
  | { kind: "invalid" }
  | { kind: "unknown-problem" }
  | { kind: "not-yours" };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
// 서술형 설명은 채점 AI에게도 넘기므로, 화면을 거치지 않고 아주 긴 글을 보내지 못하게 막는다.
const MAX_ANSWER_LENGTH = 4000;

// 학습자의 답은 쿼리 값으로 오류 메시지에 담긴다. 값을 지운 메시지만 Sentry로 보낸다.
export function reportQuizError(error: unknown) {
  captureException(new Error(safeMessage(error, "quiz-attempts")));
}

function isConfidence(value: unknown): value is Confidence {
  return CONFIDENCES.some((confidence) => confidence === value);
}

// 요청 본문은 화면을 거치지 않고도 보낼 수 있어 아무 값이나 올 수 있다. 채점 결과처럼 모르는 필드는 버린다.
export function parseAttemptInput(input: unknown): AttemptInput | undefined {
  if (typeof input !== "object" || input === null) return undefined;
  const { attemptId, problemId, chosenIndex, answerText, confidence, hintUsed, dontKnow } = input as Record<
    string,
    unknown
  >;
  if (typeof attemptId !== "string" || !UUID.test(attemptId)) return undefined;
  if (typeof problemId !== "string" || !UUID.test(problemId)) return undefined;
  const isIndex = typeof chosenIndex === "number" && Number.isInteger(chosenIndex) && chosenIndex >= 0;
  // 비어 있는 답 칸은 빼고 보내도, null로 보내도 같게 본다.
  if (chosenIndex != null && !isIndex) return undefined;
  if (answerText != null && (typeof answerText !== "string" || answerText.length > MAX_ANSWER_LENGTH)) {
    return undefined;
  }
  if (confidence != null && !isConfidence(confidence)) return undefined;
  if (typeof hintUsed !== "boolean" || typeof dontKnow !== "boolean") return undefined;
  return {
    attemptId,
    problemId,
    chosenIndex: chosenIndex ?? null,
    answerText: answerText?.trim() ? answerText : null,
    confidence: confidence ?? null,
    hintUsed,
    dontKnow,
  };
}

// 포맷에 맞게 받은 답이다. 채점에 쓸 정답을 함께 들고 다닌다.
// 잘 모르겠어요는 서술형에만 있고, 그때만 확신도가 비어도 받는다.
type Answer =
  | { kind: "choice"; chosenIndex: number; confidence: Confidence; key: ChoiceAnswer }
  | { kind: "blank"; text: string; confidence: Confidence; key: BlankAnswer }
  | { kind: "free"; text: string; confidence: Confidence; key: FreeAnswer }
  | { kind: "dont-know"; text: string | null };

function answerFor(
  problem: GradableProblem,
  { chosenIndex, answerText, confidence, dontKnow }: AttemptInput,
): Answer | undefined {
  if (problem.format === "free" && dontKnow) {
    return confidence === null ? { kind: "dont-know", text: answerText } : undefined;
  }
  if (dontKnow || confidence === null) return undefined;
  switch (problem.format) {
    case "mcq":
      if (chosenIndex === null || chosenIndex >= problem.answer.choices.length) return undefined;
      return { kind: "choice", chosenIndex, confidence, key: problem.answer };
    case "blank":
      return answerText === null ? undefined : { kind: "blank", text: answerText, confidence, key: problem.answer };
    case "free":
      return answerText === null ? undefined : { kind: "free", text: answerText, confidence, key: problem.answer };
  }
}

function answerColumns(answer: Answer) {
  switch (answer.kind) {
    case "choice":
      return { chosenIndex: answer.chosenIndex, answerText: null, confidence: answer.confidence, dontKnow: false };
    case "blank":
    case "free":
      return { chosenIndex: null, answerText: answer.text, confidence: answer.confidence, dontKnow: false };
    case "dont-know":
      return { chosenIndex: null, answerText: answer.text, confidence: null, dontKnow: true };
  }
}

type Grade = { isCorrect: boolean | null; grading: Grading | null; gradingReason: string | null };

const UNGRADED: Grade = { isCorrect: null, grading: null, gradingReason: null };

async function grade(answer: Answer, { stem, code }: { stem: string; code: string | null }): Promise<Grade> {
  switch (answer.kind) {
    case "choice":
      return { ...UNGRADED, isCorrect: gradeChoice(answer.key, answer.chosenIndex) };
    case "blank":
      return { ...UNGRADED, isCorrect: gradeBlank(answer.key, answer.text) };
    case "dont-know":
      return UNGRADED;
    case "free":
      // AI 채점이 실패해도 풀이는 남긴다. 채점 결과를 비워 두면 응답이 채점하지 못했다고 알린다.
      try {
        const { grading, reason } = await gradeFreeAnswer({ stem, code, ...answer.key, answer: answer.text });
        return { ...UNGRADED, grading, gradingReason: reason };
      } catch (error) {
        reportQuizError(error);
        return UNGRADED;
      }
  }
}

type SavedAttempt = Grade &
  Pick<typeof quizAttempt.$inferSelect, "learnerId" | "dontKnow"> &
  Pick<typeof quizProblem.$inferSelect, "format" | "answer" | "explanation">;

function toResult(saved: SavedAttempt): AttemptResult {
  const { answer, explanation } = saved;
  if (saved.dontKnow) return { outcome: "skipped" };
  if (saved.format === "free") {
    return saved.grading
      ? { outcome: "graded", format: "free", grading: saved.grading, gradingReason: saved.gradingReason, answer, explanation }
      : { outcome: "ungraded", answer, explanation };
  }
  if (saved.isCorrect === null) throw new Error(`${saved.format} 풀이에 채점 결과가 없다.`);
  return { outcome: "graded", format: saved.format, isCorrect: saved.isCorrect, answer, explanation };
}

async function savedAttempt(attemptId: string): Promise<SavedAttempt | undefined> {
  const [saved] = await getDb()
    .select({
      learnerId: quizAttempt.learnerId,
      dontKnow: quizAttempt.dontKnow,
      isCorrect: quizAttempt.isCorrect,
      grading: quizAttempt.grading,
      gradingReason: quizAttempt.gradingReason,
      format: quizProblem.format,
      answer: quizProblem.answer,
      explanation: quizProblem.explanation,
    })
    .from(quizAttempt)
    .innerJoin(quizProblem, eq(quizProblem.id, quizAttempt.problemId))
    .where(eq(quizAttempt.id, attemptId));
  return saved;
}

// 같은 풀이 ID가 다시 오면 다시 채점하지 않고 처음 저장한 결과를 그대로 돌려준다.
function replay(saved: SavedAttempt, learnerId: string): Submission {
  return saved.learnerId === learnerId ? { kind: "saved", result: toResult(saved) } : { kind: "not-yours" };
}

export async function submitAttempt(learnerId: string, input: AttemptInput): Promise<Submission> {
  const existing = await savedAttempt(input.attemptId);
  if (existing) return replay(existing, learnerId);

  const db = getDb();
  // 내려간 문제도 받는다. 학습자가 풀던 중에 내려갔을 수 있다.
  const [problem] = await db.select().from(quizProblem).where(eq(quizProblem.id, input.problemId));
  if (!problem) return { kind: "unknown-problem" };
  // 기본 문제는 누구나 풀고, 학습자에게 만든 문제는 그 학습자만 푼다.
  if (problem.learnerId !== null && problem.learnerId !== learnerId) return { kind: "not-yours" };
  const gradable = toGradable(problem.format, problem.answer);
  const answer = answerFor(gradable, input);
  if (!answer) return { kind: "invalid" };

  // 학습자가 답을 낸 시각이다. 서술형 채점을 기다리는 시간은 넣지 않는다.
  const answeredAt = new Date();
  const graded = await grade(answer, problem);
  const columns = answerColumns(answer);
  const [inserted] = await db
    .insert(quizAttempt)
    .values({
      id: input.attemptId,
      learnerId,
      problemId: problem.id,
      studyDay: studyDay(answeredAt),
      ...columns,
      hintUsed: input.hintUsed,
      ...graded,
      answeredAt,
      appVersion: env.APP_VERSION,
    })
    .onConflictDoNothing()
    .returning({ id: quizAttempt.id });
  if (inserted) {
    const { format, answer: key, explanation } = problem;
    const result = toResult({ ...graded, learnerId, dontKnow: columns.dontKnow, format, answer: key, explanation });
    return { kind: "saved", result };
  }
  // 같은 풀이 ID가 동시에 왔으면 먼저 저장한 요청의 결과를 따른다.
  const saved = await savedAttempt(input.attemptId);
  if (!saved) throw new Error("겹친 풀이 ID의 풀이를 읽지 못했다.");
  return replay(saved, learnerId);
}
