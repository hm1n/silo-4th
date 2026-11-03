CREATE TABLE "concepts" (
	"id" text PRIMARY KEY NOT NULL,
	"unit_id" text NOT NULL,
	"title" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "messages" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"question_id" uuid NOT NULL,
	"seq" integer NOT NULL,
	"role" text NOT NULL,
	"content" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "messages_seq_check" CHECK ("messages"."seq" >= 1),
	CONSTRAINT "messages_role_check" CHECK ("messages"."role" in ('user', 'assistant'))
);
--> statement-breakpoint
CREATE TABLE "questions" (
	"id" uuid PRIMARY KEY NOT NULL,
	"learner_id" uuid NOT NULL,
	"unit_id" text,
	"asked_at" timestamp with time zone DEFAULT now() NOT NULL,
	"study_day" date NOT NULL,
	"answered_at" timestamp with time zone,
	"status" text DEFAULT 'pending' NOT NULL,
	"app_version" text NOT NULL,
	"summary" text,
	"keywords" text[],
	"summarized_at" timestamp with time zone,
	CONSTRAINT "questions_status_check" CHECK ("questions"."status" in ('pending', 'ok', 'error'))
);
--> statement-breakpoint
CREATE TABLE "question_concepts" (
	"question_id" uuid NOT NULL,
	"concept_id" text NOT NULL,
	CONSTRAINT "question_concepts_question_id_concept_id_pk" PRIMARY KEY("question_id","concept_id")
);
--> statement-breakpoint
CREATE TABLE "units" (
	"id" text PRIMARY KEY NOT NULL,
	"title" text NOT NULL,
	"content" text NOT NULL
);
--> statement-breakpoint
ALTER TABLE "concepts" ADD CONSTRAINT "concepts_unit_id_units_id_fk" FOREIGN KEY ("unit_id") REFERENCES "public"."units"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "messages" ADD CONSTRAINT "messages_question_id_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "questions" ADD CONSTRAINT "questions_learner_id_learners_id_fk" FOREIGN KEY ("learner_id") REFERENCES "public"."learners"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "questions" ADD CONSTRAINT "questions_unit_id_units_id_fk" FOREIGN KEY ("unit_id") REFERENCES "public"."units"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "question_concepts" ADD CONSTRAINT "question_concepts_question_id_questions_id_fk" FOREIGN KEY ("question_id") REFERENCES "public"."questions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "question_concepts" ADD CONSTRAINT "question_concepts_concept_id_concepts_id_fk" FOREIGN KEY ("concept_id") REFERENCES "public"."concepts"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "messages_question_seq_idx" ON "messages" USING btree ("question_id","seq");--> statement-breakpoint
CREATE INDEX "questions_learner_id_idx" ON "questions" USING btree ("learner_id");--> statement-breakpoint
CREATE INDEX "question_concepts_concept_id_idx" ON "question_concepts" USING btree ("concept_id");--> statement-breakpoint
-- 단원 ID는 한 번 넣으면 바꾸지 않는다. 본문을 고칠 때는 새 마이그레이션에서 UPDATE한다.
INSERT INTO "units" ("id", "title", "content") VALUES
	('s2-05', 'GROUP BY와 HAVING', '# GROUP BY와 HAVING

## 이 단원에서 배우는 것

- COUNT(*)와 COUNT(컬럼)이 왜 서로 다른 값을 내는지 설명할 수 있어요.
- GROUP BY를 쓸 때 SELECT에 무엇을 쓸 수 있고 무엇을 쓸 수 없는지 구분할 수 있어요.
- WHERE와 HAVING이 각각 언제 행을 거르는지 처리 순서로 설명할 수 있어요.
- 조건에 맞는 행이 하나도 없을 때 결과가 0인지, NULL인지, 아예 나오지 않는지 예측할 수 있어요.

## 개념 한눈에 보기

| 개념 | 한 줄 정리 |
| -- | -- |
| 집계 함수와 NULL | COUNT(*)만 NULL이 있는 행도 세요. 나머지 집계 함수는 NULL을 빼고 계산해요 |
| GROUP BY 규칙 | 같은 값끼리 묶어서 그룹마다 한 행을 만들어요. SELECT에는 묶은 컬럼과 집계 함수만 쓸 수 있어요 |
| WHERE와 HAVING | WHERE는 묶기 전에 행을 거르고, HAVING은 묶은 뒤에 그룹을 걸러요 |
| 공집합 집계 | 대상 행이 없을 때, GROUP BY가 없으면 한 행이 나오고 GROUP BY가 있으면 아무 행도 나오지 않아요 |

## 이 단원에서 쓰는 데이터

이 단원의 예제는 모두 사원 테이블 `EMP`를 써요. 아래는 이 단원에 필요한 컬럼만 뽑은 거예요.

| ENAME (이름) | JOB (직무) | SAL (급여) | COMM (수당) | DEPTNO (부서) |
| -- | -- | -- | -- | -- |
| 김대표 | CEO | 9000 | NULL | 10 |
| 이개발 | MANAGER | 6000 | NULL | 10 |
| 박영업 | MANAGER | 6000 | 500 | 20 |
| 최코드 | DEV | 4000 | NULL | 10 |
| 정코드 | DEV | 4000 | NULL | 10 |
| 한세일 | SALES | 3500 | 300 | 20 |
| 윤세일 | SALES | 3000 | 0 | 20 |
| 강신입 | DEV | 3000 | NULL | 10 |
| 조미정 | SALES | 2800 | NULL | NULL |
| 서인턴 | DEV | NULL | NULL | 10 |

시험에 자주 나오는 함정이 데이터에 일부러 들어 있어요. 아래 세 사람을 기억해 두면 예제를 따라가기 쉬워요.

- **서인턴**은 급여(SAL)가 NULL이에요. 아직 급여가 정해지지 않았다고 생각하면 돼요.
- **윤세일**은 수당(COMM)이 0이에요. NULL과 달리 0은 "값이 있다"는 뜻이에요.
- **조미정**은 부서(DEPTNO)가 NULL이에요. 아직 부서에 배치되지 않았어요.

부서 30(기획)도 있지만, 30번 부서에 속한 사원은 한 명도 없어요.

## 설명

### 1. 집계 함수와 NULL

집계 함수는 여러 행을 받아서 값 하나로 돌려주는 함수예요. COUNT, SUM, AVG, MAX, MIN이 대표적이에요.

규칙은 하나만 기억하면 돼요. **COUNT(*)를 빼면 모든 집계 함수가 NULL을 무시해요.** COUNT(*)는 "행이 몇 개인가"를 세기 때문에, 값이 NULL이어도 행이 있으면 세요.

먼저 개수를 세 볼게요.

```sql
SELECT COUNT(*)            AS C_ALL,
       COUNT(SAL)          AS C_SAL,
       COUNT(COMM)         AS C_COMM,
       COUNT(DISTINCT JOB) AS C_JOB
FROM EMP;
```

| C_ALL | C_SAL | C_COMM | C_JOB |
| -- | -- | -- | -- |
| 10 | 9 | 3 | 4 |

하나씩 따라가 볼게요.

1. `COUNT(*)`는 행 수예요. 사원이 10명이라 10이에요.
2. `COUNT(SAL)`은 SAL이 NULL이 아닌 행만 세요. 서인턴이 빠져서 9예요.
3. `COUNT(COMM)`은 COMM이 NULL이 아닌 행만 세요. 박영업(500), 한세일(300), 윤세일(0)이 남아서 3이에요. **0은 NULL이 아니라서 세요.**
4. `COUNT(DISTINCT JOB)`은 겹치지 않는 직무 수예요. CEO, MANAGER, DEV, SALES로 4예요.

이번에는 합계와 평균을 구해 볼게요.

```sql
SELECT SUM(COMM)            AS S_COMM,
       ROUND(AVG(COMM), 1)  AS A_COMM,
       AVG(NVL(COMM, 0))    AS A_NVL
FROM EMP;
```

| S_COMM | A_COMM | A_NVL |
| -- | -- | -- |
| 800 | 266.7 | 80 |

1. `SUM(COMM)`은 NULL을 빼고 더해요. 500 + 300 + 0 = 800이에요.
2. `AVG(COMM)`은 나누는 수에서도 NULL을 빼요. 그래서 10으로 나누지 않고, 값이 있는 3명으로 나눠요. 800 ÷ 3 = 266.7이에요.
3. `NVL(COMM, 0)`은 NULL을 0으로 바꿔요. 그러면 10명 모두 값이 생겨서 800 ÷ 10 = 80이 돼요. "수당이 없는 사람도 0으로 치고 평균을 내고 싶다"면 이렇게 써요.

### 2. GROUP BY 규칙

GROUP BY는 지정한 컬럼의 값이 같은 행끼리 묶어서, **그룹마다 한 행**을 만들어요. 부서별 인원과 급여를 구해 볼게요.

```sql
SELECT DEPTNO,
       COUNT(*)            AS CNT,
       SUM(SAL)            AS SUM_SAL,
       ROUND(AVG(SAL), 1)  AS AVG_SAL
FROM EMP
GROUP BY DEPTNO
ORDER BY DEPTNO;
```

| DEPTNO | CNT | SUM_SAL | AVG_SAL |
| -- | -- | -- | -- |
| 10 | 6 | 26000 | 5200 |
| 20 | 3 | 12500 | 4166.7 |
| NULL | 1 | 2800 | 2800 |

1. 10번 부서는 6명이에요. 그런데 평균은 26000 ÷ 6이 아니라 26000 ÷ 5 = 5200이에요. 서인턴의 급여가 NULL이라서 나누는 수에서 빠졌어요.
2. 부서가 NULL인 조미정은 버려지지 않아요. GROUP BY는 NULL끼리도 같은 그룹으로 묶기 때문에, **NULL 그룹**이 한 행 생겨요.
3. 30번 부서는 결과에 나오지 않아요. EMP에 30번 부서 사원이 한 명도 없어서 묶을 행이 없기 때문이에요.

**SELECT에 쓸 수 있는 것**

그룹이 한 행으로 줄었기 때문에, SELECT에는 그룹마다 값이 하나로 정해지는 것만 쓸 수 있어요.

| 쓸 수 있어요 | 쓸 수 없어요 |
| -- | -- |
| GROUP BY에 쓴 컬럼 (DEPTNO) | GROUP BY에 쓰지 않은 컬럼 (ENAME) |
| 집계 함수 (COUNT, SUM 등) | |
| 상수 (예: ''A'') | |

예를 들어 아래 SQL은 오류가 나요. 10번 부서에는 김대표, 이개발, 최코드 등 6명이 있는데, 한 행에 이름을 하나만 보여 줄 수는 없기 때문이에요.

```sql
-- 오류 (ORA-00979)
SELECT DEPTNO, ENAME
FROM EMP
GROUP BY DEPTNO;
```

또 하나 자주 나오는 함정이 있어요. **GROUP BY에는 SELECT에서 붙인 별칭을 쓸 수 없어요.** SQL은 GROUP BY를 SELECT보다 먼저 처리하기 때문에, GROUP BY를 처리하는 시점에는 아직 별칭이 없어요.

```sql
-- 오류: D라는 별칭은 아직 없어요
SELECT DEPTNO AS D, COUNT(*)
FROM EMP
GROUP BY D;
```

### 3. WHERE와 HAVING

WHERE와 HAVING은 둘 다 조건을 걸지만, **거르는 시점**이 달라요. SQL은 아래 순서로 처리돼요.

| 순서 | 절 | 하는 일 |
| -- | -- | -- |
| 1 | FROM | 테이블을 가져와요 |
| 2 | **WHERE** | 행을 걸러요 (묶기 전) |
| 3 | GROUP BY | 그룹으로 묶어요 |
| 4 | **HAVING** | 그룹을 걸러요 (묶은 뒤) |
| 5 | SELECT | 보여 줄 컬럼을 골라요 |
| 6 | ORDER BY | 정렬해요 |

WHERE를 처리하는 시점에는 아직 그룹이 없어서 SUM이나 AVG 값도 없어요. 그래서 **집계 함수를 쓰는 조건은 WHERE에 쓸 수 없고, HAVING에 써야 해요.** WHERE에 쓰면 ORA-00934 오류가 나요.

두 조건을 함께 써 볼게요. "10번 부서에서, 직무별 평균 급여가 4000 이상인 직무"를 구하는 SQL이에요.

```sql
SELECT JOB, AVG(SAL) AS AVG_SAL
FROM EMP
WHERE DEPTNO = 10          -- ① 10번 부서 행만
GROUP BY JOB               -- ② 직무별로 묶기
HAVING AVG(SAL) >= 4000    -- ③ 평균 4000 이상만
ORDER BY JOB;
```

| JOB | AVG_SAL |
| -- | -- |
| CEO | 9000 |
| MANAGER | 6000 |

1. **WHERE:** 10번 부서 6명만 남아요. 박영업도 MANAGER지만 20번 부서라서 여기서 빠져요.
2. **GROUP BY:** 남은 6명을 직무로 묶어요. CEO는 김대표(9000), MANAGER는 이개발(6000), DEV는 최코드(4000), 정코드(4000), 강신입(3000), 서인턴(NULL)이에요.
3. **HAVING:** DEV의 평균은 서인턴을 빼고 11000 ÷ 3 = 3666.7이에요. 4000보다 작아서 빠지고, CEO와 MANAGER만 남아요.

**GROUP BY 없이 HAVING만 쓰면** 테이블 전체가 그룹 하나가 돼요.

```sql
SELECT COUNT(*) AS CNT, MAX(SAL) AS MX
FROM EMP
HAVING MAX(SAL) > 5000;
```

| CNT | MX |
| -- | -- |
| 10 | 9000 |

전체에서 가장 높은 급여가 9000이라서 조건을 통과하고, 한 행이 나와요. 조건을 `COUNT(*) > 100`으로 바꾸면 그룹 하나가 통째로 빠져서 아무 행도 나오지 않아요.

### 4. 공집합 집계

공집합은 조건에 맞는 행이 하나도 없는 경우를 말해요. 시험에 자주 나오는 주제예요. 사원이 없는 30번 부서로 확인해 볼게요.

**GROUP BY가 없을 때**

```sql
SELECT COUNT(*)   AS CNT,
       COUNT(SAL) AS CNT_SAL,
       SUM(SAL)   AS SUM_SAL,
       MAX(SAL)   AS MAX_SAL
FROM EMP
WHERE DEPTNO = 30;
```

| CNT | CNT_SAL | SUM_SAL | MAX_SAL |
| -- | -- | -- | -- |
| 0 | 0 | NULL | NULL |

GROUP BY가 없으면 "전체가 그룹 하나"예요. 그래서 대상 행이 0개여도 결과는 **한 행**이 나와요. COUNT는 셀 것이 없으니 0이고, SUM과 MAX는 계산할 값이 없으니 NULL이에요.

**GROUP BY가 있을 때**

```sql
SELECT DEPTNO, COUNT(*) AS CNT
FROM EMP
WHERE DEPTNO = 30
GROUP BY DEPTNO;
```

| DEPTNO | CNT |
| -- | -- |

결과가 **0행**이에요. 묶을 행이 없어서 그룹 자체가 만들어지지 않았어요. 그래서 "CNT가 0인 행"도 나오지 않아요.

**NULL 대신 0을 받고 싶을 때**

| SQL | 결과 | 이유 |
| -- | -- | -- |
| `NVL(SUM(SAL), 0)` | 0 | SUM 결과인 NULL을 0으로 바꿔요 |
| `SUM(NVL(SAL, 0))` | NULL | 0으로 바꿀 행 자체가 없어서, SUM은 여전히 NULL이에요 |

NVL을 SUM의 **바깥**에 써야 0을 받을 수 있어요.

## 자주 하는 오해

| 오해 | 실제 |
| -- | -- |
| AVG(COMM)은 전체 인원으로 나눈다 | 값이 있는 행 수로 나눠요. 800 ÷ 10이 아니라 800 ÷ 3 = 266.7이에요 |
| COUNT(COMM)은 0도 빼고 센다 | 0은 값이에요. NULL만 빠져요. 그래서 윤세일도 세요 |
| SUM(SAL + COMM)과 SUM(SAL) + SUM(COMM)은 같다 | 달라요. COMM이 NULL인 사원은 SAL + COMM도 NULL이 돼서 통째로 빠져요 |
| 집계 함수 조건도 WHERE에 쓸 수 있다 | WHERE를 처리할 때는 아직 집계 값이 없어요. HAVING에 써야 해요 |
| 행이 없으면 SUM은 0이다 | NULL이에요. GROUP BY가 있으면 아예 행이 나오지 않아요 |
'),
	('s2-07', '조인', '# 조인

## 이 단원에서 배우는 것

- EQUI JOIN과 NON-EQUI JOIN의 차이를 설명하고, 조인 키가 NULL이거나 범위에 맞지 않는 행이 왜 빠지는지 설명할 수 있어요.
- 테이블 N개를 조인할 때 필요한 최소 조인 조건 수(N−1)를 알고, 조건이 빠졌을 때 늘어나는 행 수를 계산할 수 있어요.
- Oracle `(+)` 문법에서 `(+)`의 위치를 보고 어느 쪽 행이 모두 남는지 예측할 수 있어요.
- INNER, CROSS, NATURAL, USING, ON 조인의 문법 규칙(접두사, SELECT * 컬럼 수)을 설명할 수 있어요.
- LEFT / RIGHT / FULL OUTER JOIN의 결과 행 수를 예측할 수 있어요.
- OUTER JOIN에서 조건을 ON에 둘 때와 WHERE에 둘 때 결과가 어떻게 달라지는지 예측할 수 있어요.

## 개념 한눈에 보기

| 개념 | 한 줄 정리 |
| -- | -- |
| EQUI JOIN (등가 조인) | 두 테이블의 컬럼 값이 `=`로 같은 행끼리 붙여요. 조인 키가 NULL인 행은 빠져요 |
| NON-EQUI JOIN (비등가 조인) | `=`가 아니라 BETWEEN, >, < 같은 조건으로 붙여요. 급여 등급 테이블이 대표 예예요 |
| 조인 조건 N−1개와 카테시안 곱 | 테이블 N개는 조인 조건이 최소 N−1개 필요해요. 빠지면 행 수가 곱으로 늘어나요 |
| Oracle (+) OUTER JOIN | NULL로 채워질 쪽 컬럼에 `(+)`를 붙이면, 반대쪽 행이 모두 남아요. Oracle 전용 문법이에요 |
| INNER JOIN, CROSS JOIN과 ON 절 | 표준 문법은 FROM 절에 `JOIN … ON 조건`을 써요. CROSS JOIN은 모든 조합을 만들어요 |
| NATURAL JOIN과 USING 절 | 이름이 같은 컬럼으로 조인해요. 공통 컬럼은 결과에 한 번만 나오고, 접두사를 붙일 수 없어요 |
| LEFT / RIGHT / FULL OUTER JOIN | 기준 쪽 행은 짝이 없어도 남기고, 반대쪽을 NULL로 채워요. FULL은 양쪽 모두 남겨요 |
| OUTER JOIN에서 ON과 WHERE | 안쪽 테이블 조건을 ON에 두면 기준 행이 남고, WHERE에 두면 NULL 행이 지워져 INNER JOIN처럼 돼요 |

## 이 단원에서 쓰는 데이터

이 단원에서는 테이블 세 개를 써요. 아래는 이 단원에 필요한 컬럼만 뽑은 거예요.

**부서 테이블 `DEPT`**

| DEPTNO (부서 번호) | DNAME (부서 이름) | LOC (위치) |
| -- | -- | -- |
| 10 | 개발 | 서울 |
| 20 | 영업 | 부산 |
| 30 | 기획 | 서울 |

**사원 테이블 `EMP`**

| EMPNO (사원 번호) | ENAME (이름) | SAL (급여) | DEPTNO (부서) |
| -- | -- | -- | -- |
| 1001 | 김대표 | 9000 | 10 |
| 1002 | 이개발 | 6000 | 10 |
| 1003 | 박영업 | 6000 | 20 |
| 1004 | 최코드 | 4000 | 10 |
| 1005 | 정코드 | 4000 | 10 |
| 1006 | 한세일 | 3500 | 20 |
| 1007 | 윤세일 | 3000 | 20 |
| 1008 | 강신입 | 3000 | 10 |
| 1009 | 조미정 | 2800 | NULL |
| 1010 | 서인턴 | NULL | 10 |

EMP에는 이 밖에도 JOB(직무), MGR(상사 번호), HIREDATE(입사일), COMM(수당) 컬럼이 있어요. EMP는 모두 8개 컬럼이고, DEPT는 3개 컬럼이에요. 이 숫자는 6번 설명에서 다시 써요.

**급여 등급 테이블 `SALGRADE`**

| GRADE (등급) | LOSAL (최저 급여) | HISAL (최고 급여) |
| -- | -- | -- |
| 1 | 0 | 2999 |
| 2 | 3000 | 3999 |
| 3 | 4000 | 5999 |
| 4 | 6000 | 9999 |

조인 결과의 행 수를 바꾸는 함정이 데이터에 일부러 들어 있어요. 아래 세 가지를 기억해 두면 예제를 따라가기 쉬워요.

- **조미정**은 부서(DEPTNO)가 NULL이에요. 어느 부서와도 짝이 맞지 않아요.
- **서인턴**은 급여(SAL)가 NULL이에요. 어느 급여 등급에도 들어가지 않아요.
- **30번 기획** 부서에는 사원이 한 명도 없어요. EMP 쪽에 짝이 없어요.

## 설명

### 1. EQUI JOIN (등가 조인)

조인(JOIN)은 여러 테이블의 행을 조건에 맞춰 옆으로 이어 붙이는 거예요. 1번부터 4번까지는 Oracle의 전통 문법으로 배워요. 전통 문법은 FROM에 테이블을 쉼표로 나열하고, 조인 조건을 WHERE에 써요.

조인 조건이 `=`이면 EQUI JOIN(등가 조인)이라고 해요. 보통 한 테이블의 기본키(PK)와 다른 테이블의 외래키(FK)를 연결해요. 여기서는 EMP.DEPTNO(외래키)와 DEPT.DEPTNO(기본키)를 연결해요.

```sql
SELECT E.ENAME, E.DEPTNO, D.DNAME
FROM EMP E, DEPT D
WHERE E.DEPTNO = D.DEPTNO
ORDER BY E.EMPNO;
```

`EMP E`의 E는 테이블 별칭이에요. 별칭을 붙이면 `E.DEPTNO`처럼 어느 테이블의 컬럼인지 짧게 적을 수 있어요.

| ENAME | DEPTNO | DNAME |
| -- | -- | -- |
| 김대표 | 10 | 개발 |
| 이개발 | 10 | 개발 |
| 박영업 | 20 | 영업 |
| 최코드 | 10 | 개발 |
| 정코드 | 10 | 개발 |
| 한세일 | 20 | 영업 |
| 윤세일 | 20 | 영업 |
| 강신입 | 10 | 개발 |
| 서인턴 | 10 | 개발 |

결과는 9행이에요. 하나씩 따라가 볼게요.

1. EMP의 10행 하나하나에 대해 DEPTNO가 같은 DEPT 행을 찾아요. 10번 부서 사원 6명은 ''개발''에, 20번 부서 사원 3명은 ''영업''에 붙어요.
2. 조미정은 DEPTNO가 NULL이에요. `NULL = 10`은 참(TRUE)이 아니라 UNKNOWN(알 수 없음)이 돼요. 조건이 참인 행만 남기 때문에 조미정은 어느 부서와도 붙지 않고 빠져요.
3. 30번 기획 부서는 DEPTNO가 30인 사원이 없어서 결과에 나오지 않아요.
4. 그래서 사원 10명이 아니라 9행이에요. 서인턴은 급여가 NULL이지만, 이번 조인은 급여를 쓰지 않으니 그대로 남아요.

### 2. NON-EQUI JOIN (비등가 조인)

두 테이블에 같은 값이 없어서 "범위 안에 드는지"로 연결해야 할 때가 있어요. 이렇게 `=`가 아닌 조건(BETWEEN, >, < 등)으로 붙이는 조인을 NON-EQUI JOIN(비등가 조인)이라고 해요.

SALGRADE에는 등급별 급여 구간(LOSAL ~ HISAL)만 있고, EMP의 급여와 똑같은 값은 없어요. 그래서 `=`로는 붙일 수 없고, BETWEEN으로 붙여요.

```sql
SELECT E.ENAME, E.SAL, S.GRADE
FROM EMP E, SALGRADE S
WHERE E.SAL BETWEEN S.LOSAL AND S.HISAL
ORDER BY E.EMPNO;
```

| ENAME | SAL | GRADE |
| -- | -- | -- |
| 김대표 | 9000 | 4 |
| 이개발 | 6000 | 4 |
| 박영업 | 6000 | 4 |
| 최코드 | 4000 | 3 |
| 정코드 | 4000 | 3 |
| 한세일 | 3500 | 2 |
| 윤세일 | 3000 | 2 |
| 강신입 | 3000 | 2 |
| 조미정 | 2800 | 1 |

하나씩 따라가 볼게요.

1. 김대표의 급여 9000은 6000 ~ 9999 구간에 들어가서 GRADE 4가 돼요.
2. 윤세일의 급여 3000은 2등급의 최저 급여(LOSAL)와 같아요. BETWEEN은 양 끝 값을 포함하기 때문에 3000 ~ 3999 구간인 GRADE 2가 돼요.
3. 조미정은 부서가 없지만 급여 2800이 있어서 GRADE 1로 붙어요. 이번 조인은 DEPTNO를 쓰지 않기 때문이에요.
4. 서인턴은 급여가 NULL이라 `NULL BETWEEN 0 AND 2999`가 UNKNOWN이 돼요. 어느 등급과도 붙지 않고 빠져요.
5. 그래서 이번에도 9행이에요. 하지만 1번 예제에서는 조미정이 빠졌고, 이번에는 서인턴이 빠졌어요. 빠지는 사람이 조인 조건에 따라 달라져요.

등급 구간이 서로 겹치지 않기 때문에, 사원 한 명은 등급 하나에만 붙어요. 그래서 NON-EQUI JOIN이라고 해서 행이 늘어나는 것은 아니에요. 행 수는 데이터에 따라 달라져요.

### 3. 조인 조건 N−1개와 카테시안 곱

테이블 2개는 조인 조건 1개로 이어져요. 테이블이 3개면 사슬처럼 이어야 하니 조건이 2개 필요해요. 이렇게 테이블이 N개면 조인 조건은 **최소 N−1개**가 필요해요.

조건이 하나라도 빠지면, 그 테이블의 행은 다른 테이블의 모든 행과 하나씩 짝지어져요. 이것을 카테시안 곱(Cartesian Product)이라고 해요. 카테시안 곱의 행 수는 각 테이블 행 수를 곱한 값이에요.

먼저 테이블 3개를 조건 2개로 바르게 조인해 볼게요.

```sql
-- 테이블 3개, 조건 2개 (N-1 = 2)
SELECT E.ENAME, D.DNAME, S.GRADE
FROM EMP E, DEPT D, SALGRADE S
WHERE E.DEPTNO = D.DEPTNO
  AND E.SAL BETWEEN S.LOSAL AND S.HISAL
ORDER BY E.EMPNO;
```

| ENAME | DNAME | GRADE |
| -- | -- | -- |
| 김대표 | 개발 | 4 |
| 이개발 | 개발 | 4 |
| 박영업 | 영업 | 4 |
| 최코드 | 개발 | 3 |
| 정코드 | 개발 | 3 |
| 한세일 | 영업 | 2 |
| 윤세일 | 영업 | 2 |
| 강신입 | 개발 | 2 |

하나씩 따라가 볼게요.

1. 첫 번째 조건 `E.DEPTNO = D.DEPTNO`에서 부서가 NULL인 조미정이 빠져요.
2. 두 번째 조건 `E.SAL BETWEEN …`에서 급여가 NULL인 서인턴이 빠져요.
3. 두 사람이 빠져서 8행이에요.

이번에는 조건을 빼 볼게요. 먼저 EMP와 DEPT를 조건 없이 조인해요.

```sql
SELECT COUNT(*) AS CNT
FROM EMP E, DEPT D;
```

| CNT |
| -- |
| 30 |

다음은 테이블 3개에 조건을 1개만 쓴 경우예요.

```sql
SELECT COUNT(*) AS CNT
FROM EMP E, DEPT D, SALGRADE S
WHERE E.DEPTNO = D.DEPTNO;
```

| CNT |
| -- |
| 36 |

하나씩 따라가 볼게요.

1. 첫 번째 쿼리는 조인 조건이 없어요. EMP 10행 각각이 DEPT 3행 모두와 짝지어져서 10 × 3 = 30행이에요.
2. 두 번째 쿼리는 EMP와 DEPT 사이에만 조건이 있어요. 이 둘은 1번 예제처럼 9행으로 이어져요.
3. 그런데 SALGRADE에는 아무 조건이 없어요. 그래서 9행 각각이 SALGRADE 4행 모두와 짝지어져 9 × 4 = 36행이 돼요.

### 4. Oracle (+) OUTER JOIN

1번 EQUI JOIN에서는 짝이 없는 행(30번 기획, 조미정)이 사라졌어요. 짝이 없어도 한쪽 테이블의 행을 모두 남기는 조인을 OUTER JOIN(외부 조인)이라고 해요. 짝이 없는 자리는 NULL로 채워요.

Oracle 전통 문법에서는 **값이 없어서 NULL로 채워질 쪽** 컬럼에 `(+)`를 붙여요. "모자란 쪽에 (+)를 붙인다"고 기억하면 돼요. `(+)`가 **붙지 않은 쪽**의 행이 모두 남아요.

```sql
SELECT D.DEPTNO, D.DNAME, E.ENAME
FROM DEPT D, EMP E
WHERE D.DEPTNO = E.DEPTNO(+)
ORDER BY D.DEPTNO, E.EMPNO;
```

`E.DEPTNO(+)`는 "EMP 쪽 값이 모자랄 수 있다"는 뜻이에요. 그래서 반대쪽인 DEPT의 행이 모두 남아요. 표준 문법으로는 `DEPT LEFT OUTER JOIN EMP`와 같아요(7번에서 배워요).

| DEPTNO | DNAME | ENAME |
| -- | -- | -- |
| 10 | 개발 | 김대표 |
| 10 | 개발 | 이개발 |
| 10 | 개발 | 최코드 |
| 10 | 개발 | 정코드 |
| 10 | 개발 | 강신입 |
| 10 | 개발 | 서인턴 |
| 20 | 영업 | 박영업 |
| 20 | 영업 | 한세일 |
| 20 | 영업 | 윤세일 |
| 30 | 기획 | NULL |

하나씩 따라가 볼게요.

1. 10번, 20번 부서는 EQUI JOIN과 똑같이 사원 6명, 3명과 붙어요. 여기까지 9행이에요.
2. 30번 기획은 짝이 되는 사원이 없어요. 하지만 `(+)`가 EMP 쪽에 있으니 DEPT 행은 남고, ENAME 자리는 NULL로 채워져요. 그래서 10행이에요.
3. 조미정은 여전히 나오지 않아요. 이번에 모두 남는 쪽은 DEPT이고, 조미정은 EMP 쪽 행이기 때문이에요.

방향을 바꿔서 `(+)`를 DEPT 쪽에 붙여 볼게요.

```sql
SELECT E.ENAME, E.DEPTNO, D.DNAME
FROM EMP E, DEPT D
WHERE E.DEPTNO = D.DEPTNO(+)
ORDER BY E.EMPNO;
```

| ENAME | DEPTNO | DNAME |
| -- | -- | -- |
| 김대표 | 10 | 개발 |
| 이개발 | 10 | 개발 |
| 박영업 | 20 | 영업 |
| 최코드 | 10 | 개발 |
| 정코드 | 10 | 개발 |
| 한세일 | 20 | 영업 |
| 윤세일 | 20 | 영업 |
| 강신입 | 10 | 개발 |
| 조미정 | NULL | NULL |
| 서인턴 | 10 | 개발 |

이번에는 EMP의 행이 모두 남아요. 조미정이 DNAME NULL로 나오고, 사원이 없는 기획은 빠져요. 행 수는 똑같이 10행이지만 들어 있는 행이 달라요.

**추가 조건에도 `(+)`를 붙여야 해요**

조인 조건 말고 다른 조건을 더 쓸 때도, NULL로 채워질 쪽 컬럼에는 `(+)`를 붙여야 OUTER JOIN이 유지돼요. "급여 6000 이상인 사원만 부서에 붙이되, 부서는 모두 남기기"를 써 볼게요.

```sql
SELECT D.DNAME, E.ENAME, E.SAL
FROM DEPT D, EMP E
WHERE D.DEPTNO = E.DEPTNO(+)
  AND E.SAL(+) >= 6000
ORDER BY D.DEPTNO, E.EMPNO;
```

| DNAME | ENAME | SAL |
| -- | -- | -- |
| 개발 | 김대표 | 9000 |
| 개발 | 이개발 | 6000 |
| 영업 | 박영업 | 6000 |
| 기획 | NULL | NULL |

하나씩 따라가 볼게요.

1. 급여가 6000 이상인 사원은 김대표, 이개발, 박영업 세 명이에요. 이 세 명만 부서에 붙어요.
2. 기획은 붙을 사원이 없지만, DEPT 행은 모두 남기 때문에 NULL로 채워져 남아요. 그래서 4행이에요.
3. `E.SAL(+)`에서 `(+)`를 빼고 `E.SAL >= 6000`이라고만 쓰면 결과가 달라져요. 기획 행은 SAL이 NULL이라 `NULL >= 6000`이 UNKNOWN이 되고, 이 조건에서 지워져요. 결과는 김대표, 이개발, 박영업 3행만 남아요. 이 차이는 8번에서 표준 문법으로 다시 볼게요.

**`(+)` 문법의 제약**

- `(+)`는 한쪽에만 붙일 수 있어요. 양쪽 행을 모두 남기는 FULL OUTER JOIN은 이 문법으로 쓸 수 없어요. 표준 문법의 `FULL OUTER JOIN`을 써요.
- `(+)`가 붙은 조건은 OR나 IN과 함께 쓸 수 없어요.

> SQL Server에는 `(+)`가 없어요. 예전에 쓰던 `*=`, `=*` 문법도 지금은 지원하지 않으니, 표준 문법의 OUTER JOIN을 써요.

### 5. INNER JOIN, CROSS JOIN과 ON 절

5번부터는 ANSI/ISO 표준 조인 문법이에요. 표준 문법은 조인 조건을 WHERE가 아니라 FROM 절의 `ON`에 써요. 조인 조건(ON)과 결과를 거르는 조건(WHERE)이 나뉘어서 읽기 쉬워요.

INNER JOIN은 양쪽 테이블 모두에 짝이 있는 행만 붙이는 조인이에요. 1번 EQUI JOIN과 결과가 같아요. `INNER`는 생략할 수 있어서 `JOIN`만 쓰면 INNER JOIN이에요. ON에는 두 컬럼의 이름이 달라도 되고, `=`가 아닌 조건을 써도 돼요.

```sql
SELECT E.ENAME, D.DNAME
FROM EMP E INNER JOIN DEPT D
  ON E.DEPTNO = D.DEPTNO
WHERE D.LOC = ''부산''
ORDER BY E.EMPNO;
```

| ENAME | DNAME |
| -- | -- |
| 박영업 | 영업 |
| 한세일 | 영업 |
| 윤세일 | 영업 |

하나씩 따라가 볼게요.

1. ON으로 EMP와 DEPT를 붙이면 9행이에요. 조미정은 DEPTNO가 NULL이라 빠지고, 기획은 짝이 없어서 빠져요.
2. WHERE의 `D.LOC = ''부산''`이 그중 부산에 있는 영업 부서 3행만 남겨요.
3. INNER JOIN에서는 `D.LOC = ''부산''`을 WHERE 대신 ON에 `AND`로 붙여도 결과가 같아요. 결과가 달라지는 것은 OUTER JOIN뿐이에요(8번에서 배워요).

**CROSS JOIN**

CROSS JOIN은 조건 없이 모든 조합을 만드는 조인이에요. 3번에서 본 카테시안 곱을 일부러 만드는 문법이에요. CROSS JOIN에는 ON을 쓰지 않아요.

```sql
SELECT COUNT(*) AS CNT
FROM EMP CROSS JOIN DEPT;
```

| CNT |
| -- |
| 30 |

EMP 10행과 DEPT 3행의 모든 조합이라 10 × 3 = 30행이에요. 3번에서 `FROM EMP E, DEPT D`에 조건을 쓰지 않았을 때와 같은 결과예요.

### 6. NATURAL JOIN과 USING 절

NATURAL JOIN은 두 테이블에서 **이름이 같은 모든 컬럼**으로 자동으로 EQUI JOIN을 해요. EMP와 DEPT에서 이름이 같은 컬럼은 DEPTNO 하나라서, `E.DEPTNO = D.DEPTNO`로 조인한 것과 같아요.

USING 절은 이름이 같은 컬럼 가운데 **조인에 쓸 컬럼을 직접 골라** 적는 방법이에요. `USING (DEPTNO)`처럼 괄호 안에 컬럼 이름을 써요.

먼저 USING으로 박영업(사원 번호 1003)의 부서를 찾아볼게요.

```sql
SELECT DEPTNO, DNAME, ENAME
FROM DEPT D JOIN EMP E
  USING (DEPTNO)
WHERE EMPNO = 1003;
```

| DEPTNO | DNAME | ENAME |
| -- | -- | -- |
| 20 | 영업 | 박영업 |

`SELECT DEPTNO`에 `D.`나 `E.`를 붙이지 않은 것을 눈여겨봐 주세요. 이유는 아래에서 설명할게요.

**SELECT * 의 컬럼 수가 달라요**

같은 조인을 `SELECT *`로 실행하면, USING(또는 NATURAL)과 ON의 결과 컬럼 수가 달라요. 시험에 자주 나오는 부분이에요.

```sql
-- (1) USING
SELECT *
FROM DEPT D JOIN EMP E
  USING (DEPTNO)
WHERE EMPNO = 1003;

-- (2) ON
SELECT *
FROM DEPT D JOIN EMP E
  ON D.DEPTNO = E.DEPTNO
WHERE EMPNO = 1003;
```

결과는 둘 다 박영업 한 행이지만, 나오는 컬럼이 이렇게 달라요.

| 쿼리 | 컬럼 수 | 나오는 컬럼 (순서대로) |
| -- | -- | -- |
| (1) USING | 10개 | **DEPTNO**, DNAME, LOC, EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, COMM |
| (2) ON | 11개 | DEPTNO, DNAME, LOC, EMPNO, ENAME, JOB, MGR, HIREDATE, SAL, COMM, DEPTNO |

`(1)`을 `DEPT NATURAL JOIN EMP`로 바꿔 실행해도 같은 10개 컬럼이 나와요.

하나씩 따라가 볼게요.

1. USING과 NATURAL은 DEPTNO를 "하나의 공통 컬럼"으로 합쳐서 맨 앞에 한 번만 보여 줘요. DEPT 3개 + EMP 8개 − 공통 1개 = 10개 컬럼이에요.
2. ON은 두 테이블의 DEPTNO를 각각 다른 컬럼으로 둬요. 그래서 3 + 8 = 11개 컬럼이고, DEPTNO가 두 번 나와요.
3. USING과 NATURAL에서는 공통 컬럼이 하나로 합쳐졌으니, 어느 테이블의 DEPTNO인지 고를 수 없어요. 그래서 공통 컬럼에 `D.DEPTNO`처럼 접두사(테이블 별칭)를 붙이면 오류가 나요(Oracle ORA-25154, ORA-25155). `DEPTNO`라고만 써야 해요.

**그 밖의 규칙**

- NATURAL JOIN에는 ON이나 USING을 함께 쓰지 않아요.
- NATURAL JOIN은 이름이 같은 컬럼을 모두 조인 조건으로 써요. 이름만 같고 뜻이 다른 컬럼이 있으면 그 컬럼까지 조건이 되어 원하지 않은 결과가 나올 수 있어요.
- USING에 쓰는 컬럼은 양쪽 테이블에 같은 이름으로 있어야 해요. 이름이 다르면 ON을 써요.

> SQL Server는 NATURAL JOIN과 USING을 지원하지 않아요. ON만 써요.

### 7. LEFT / RIGHT / FULL OUTER JOIN

표준 문법의 OUTER JOIN은 어느 쪽 행을 모두 남길지를 키워드로 정해요.

| 문법 | 모두 남는 쪽 |
| -- | -- |
| `A LEFT OUTER JOIN B` | 왼쪽 A의 행. 짝이 없으면 B 컬럼을 NULL로 채워요 |
| `A RIGHT OUTER JOIN B` | 오른쪽 B의 행. 짝이 없으면 A 컬럼을 NULL로 채워요 |
| `A FULL OUTER JOIN B` | 양쪽 행 모두 |

`OUTER`는 생략할 수 있어서 `LEFT JOIN`이라고만 써도 돼요. 이 데이터에서는 사원이 없는 **30번 기획**과 부서가 없는 **조미정**이 행 수 차이를 만들어요. FULL OUTER JOIN으로 두 경우를 한 번에 볼게요.

```sql
SELECT E.ENAME,
       E.DEPTNO AS E_DEPTNO,
       D.DEPTNO AS D_DEPTNO,
       D.DNAME
FROM EMP E FULL OUTER JOIN DEPT D
  ON E.DEPTNO = D.DEPTNO
ORDER BY E.EMPNO, D.DEPTNO;
```

| ENAME | E_DEPTNO | D_DEPTNO | DNAME |
| -- | -- | -- | -- |
| 김대표 | 10 | 10 | 개발 |
| 이개발 | 10 | 10 | 개발 |
| 박영업 | 20 | 20 | 영업 |
| 최코드 | 10 | 10 | 개발 |
| 정코드 | 10 | 10 | 개발 |
| 한세일 | 20 | 20 | 영업 |
| 윤세일 | 20 | 20 | 영업 |
| 강신입 | 10 | 10 | 개발 |
| 조미정 | NULL | NULL | NULL |
| 서인턴 | 10 | 10 | 개발 |
| NULL | NULL | 30 | 기획 |

조미정 행은 DEPT 쪽 컬럼(D_DEPTNO, DNAME)이 NULL이고, 기획 행은 EMP 쪽 컬럼(ENAME, E_DEPTNO)이 NULL이에요.

같은 `EMP E ○○ JOIN DEPT D ON E.DEPTNO = D.DEPTNO`에서 조인 종류만 바꾸면 행 수가 이렇게 달라요. CROSS JOIN은 ON 없이 실행한 값이에요.

| 조인 종류 | 행 수 |
| -- | -- |
| INNER | 9 |
| LEFT | 10 |
| RIGHT | 10 |
| FULL | 11 |
| CROSS | 30 |

하나씩 따라가 볼게요.

1. INNER는 9행이에요. 짝이 있는 사원 9명이에요.
2. LEFT(EMP 기준)는 10행이에요. 9행에 부서가 없는 조미정이 DNAME NULL로 더해져요.
3. RIGHT(DEPT 기준)는 10행이에요. 9행에 사원이 없는 기획이 ENAME NULL로 더해져요. 조미정은 빠져요.
4. FULL은 11행이에요. 짝이 있는 9행 + 왼쪽에만 있는 조미정 1행 + 오른쪽에만 있는 기획 1행이에요. LEFT 10행과 RIGHT 10행을 더한 20행이 아니에요. 두 결과에 겹치는 9행은 한 번만 세요.

### 8. OUTER JOIN에서 ON과 WHERE

처리 순서로 이해하면 쉬워요. **ON은 조인하면서 "누구와 붙을지"를 정하고, WHERE는 조인이 끝난 결과에서 "어떤 행을 남길지"를 정해요.**

OUTER JOIN은 ON에서 짝을 찾지 못한 기준 행도 NULL로 채워서 살려 둬요. 그런데 WHERE에서 그 NULL 컬럼에 조건을 걸면 결과가 UNKNOWN이 되어 다시 지워져요. 여기서 기준 테이블은 모두 남는 쪽(LEFT JOIN의 왼쪽)이고, 안쪽 테이블은 NULL로 채워질 수 있는 쪽이에요.

같은 조건 `E.SAL >= 6000`을 ON에 둘 때와 WHERE에 둘 때를 비교해 볼게요.

```sql
-- (1) 안쪽 테이블(EMP) 조건을 ON에
SELECT D.DNAME, E.ENAME, E.SAL
FROM DEPT D LEFT OUTER JOIN EMP E
  ON D.DEPTNO = E.DEPTNO
 AND E.SAL >= 6000
ORDER BY D.DEPTNO, E.EMPNO;
```

| DNAME | ENAME | SAL |
| -- | -- | -- |
| 개발 | 김대표 | 9000 |
| 개발 | 이개발 | 6000 |
| 영업 | 박영업 | 6000 |
| 기획 | NULL | NULL |

```sql
-- (2) 같은 조건을 WHERE에
SELECT D.DNAME, E.ENAME, E.SAL
FROM DEPT D LEFT OUTER JOIN EMP E
  ON D.DEPTNO = E.DEPTNO
WHERE E.SAL >= 6000
ORDER BY D.DEPTNO, E.EMPNO;
```

| DNAME | ENAME | SAL |
| -- | -- | -- |
| 개발 | 김대표 | 9000 |
| 개발 | 이개발 | 6000 |
| 영업 | 박영업 | 6000 |

하나씩 따라가 볼게요.

1. (1)은 "급여 6000 이상인 사원만 붙여라"라는 뜻이에요. 김대표, 이개발, 박영업이 붙고, 기획은 붙을 사원이 없지만 LEFT JOIN의 기준 행이라 NULL로 남아요. 그래서 4행이에요. 4번의 `E.SAL(+) >= 6000` 예제와 같은 결과예요.
2. (2)는 먼저 LEFT JOIN으로 10행(기획 NULL 행 포함)을 만들어요. 그다음 WHERE가 급여 6000 미만인 사원과, `NULL >= 6000`이 UNKNOWN인 기획 행을 지워요. 그래서 3행이에요.
3. (2)의 결과는 INNER JOIN 결과와 같아요. 안쪽 테이블 조건을 WHERE에 두면 OUTER JOIN을 쓴 의미가 없어져요.

**기준 테이블의 조건을 ON에 두면**

반대로 기준 테이블(DEPT) 쪽 조건을 ON에 두면, 기준 행은 걸러지지 않아요.

```sql
SELECT D.DNAME, D.LOC, E.ENAME
FROM DEPT D LEFT OUTER JOIN EMP E
  ON D.DEPTNO = E.DEPTNO
 AND D.LOC = ''부산''
ORDER BY D.DEPTNO, E.EMPNO;
```

| DNAME | LOC | ENAME |
| -- | -- | -- |
| 개발 | 서울 | NULL |
| 영업 | 부산 | 박영업 |
| 영업 | 부산 | 한세일 |
| 영업 | 부산 | 윤세일 |
| 기획 | 서울 | NULL |

하나씩 따라가 볼게요.

1. ON의 `D.LOC = ''부산''`은 "부산에 있는 부서에만 사원을 붙여라"라는 뜻이 돼요.
2. 영업(부산)에는 사원 3명이 붙어요.
3. 개발(서울)은 조건에 맞지 않아 사원이 붙지 않아요. 하지만 LEFT JOIN의 기준 행이라 사라지지 않고 ENAME NULL로 남아요. 기획(서울)도 마찬가지예요.
4. 그래서 5행이에요. 같은 `D.LOC = ''부산''`을 WHERE에 두면 영업 3행만 남아요.

**정리**

| 하고 싶은 것 | 조건을 둘 곳 |
| -- | -- |
| 기준 행은 모두 남기고, 붙일 상대만 고르기 | ON |
| 결과 행 자체를 줄이기 | WHERE |
| 짝이 없는 행만 찾기 | WHERE에 `IS NULL` |

짝이 없는 행만 찾고 싶다면 안쪽 테이블의 컬럼에 `IS NULL` 조건을 걸어요. 예를 들어 `DEPT D LEFT OUTER JOIN EMP E ON D.DEPTNO = E.DEPTNO`에 `WHERE E.EMPNO IS NULL`을 붙이면, 사원이 없는 30번 기획 1행만 나와요.

## 자주 하는 오해

| 오해 | 실제 |
| -- | -- |
| 조인 키가 둘 다 NULL이면 같은 값이니 붙는다 | `NULL = NULL`은 UNKNOWN이라 EQUI JOIN에서 빠져요. 조미정은 EMP와 DEPT의 EQUI JOIN 결과 9행에 들어가지 않아요 |
| NON-EQUI JOIN은 결과가 항상 EQUI JOIN보다 많다 | 행 수는 데이터에 달려 있어요. 급여 등급처럼 구간이 겹치지 않으면 사원 한 명에 등급 하나씩만 붙어요. 이 데이터에서는 둘 다 9행이에요 |
| 테이블 3개를 조인하면 조건도 3개가 필요하다 | 최소 N−1 = 2개예요. 조건이 모자라면 카테시안 곱이 생겨요. EMP·DEPT·SALGRADE에 조건이 1개뿐이면 9 × 4 = 36행이에요 |
| `(+)`를 붙인 쪽 테이블의 행이 모두 남는다 | 반대예요. `(+)`는 NULL로 채워질(모자란) 쪽에 붙고, **붙지 않은 쪽** 행이 모두 남아요 |
| OUTER JOIN의 추가 조건은 `(+)` 없이 써도 OUTER JOIN이 유지된다 | 안쪽 테이블 조건에 `(+)`가 없으면 NULL 행이 지워져 INNER JOIN처럼 돼요. 4행이 아니라 3행이 나와요 |
| USING 컬럼에도 `E.DEPTNO`처럼 접두사를 붙이는 게 안전하다 | NATURAL JOIN과 USING의 공통 컬럼에 접두사를 붙이면 오류예요 |
| NATURAL JOIN과 USING의 SELECT * 컬럼 수는 ON과 같다 | 공통 컬럼이 하나로 합쳐져서 그만큼 적어요. DEPT와 EMP는 USING 10개, ON 11개예요 |
| FULL OUTER JOIN 행 수 = LEFT 행 수 + RIGHT 행 수 | 겹치는 부분은 한 번만 세요. 10 + 10 = 20이 아니라 9 + 1 + 1 = 11행이에요 |
| OUTER JOIN에서도 조건을 ON에 두든 WHERE에 두든 같다 | 같은 것은 INNER JOIN뿐이에요. 안쪽 테이블 조건을 WHERE에 두면 4행이 3행으로 줄어 INNER JOIN처럼 돼요 |
| LEFT OUTER JOIN에서 기준 테이블 조건을 ON에 두면 기준 행이 걸러진다 | 기준 행은 그대로 남고 상대만 붙지 않아요. `ON … AND D.LOC = ''부산''`이어도 개발과 기획은 NULL로 남아 5행이에요 |
'),
	('s2-09', '서브쿼리', '# 서브쿼리

## 이 단원에서 배우는 것

- 서브쿼리가 돌려주는 결과(한 행, 여러 행, 여러 컬럼)에 맞는 연산자를 고를 수 있어요.
- 서브쿼리를 쓰는 위치(SELECT 절, FROM 절, WHERE 절)에 따라 이름과 규칙이 어떻게 다른지 구분할 수 있어요.
- `> ANY`, `> ALL` 같은 조건을 최솟값·최댓값 비교로 바꿔서 결과를 예측할 수 있어요.
- 연관 서브쿼리와 EXISTS가 어떻게 동작하는지 설명할 수 있어요.
- NOT IN 서브쿼리 결과에 NULL이 하나라도 섞이면 왜 결과가 0행이 되는지 설명할 수 있어요.

## 개념 한눈에 보기

| 개념 | 한 줄 정리 |
| -- | -- |
| 반환 결과에 따른 분류 | 서브쿼리가 한 행을 돌려주면 `=`, 여러 행이면 `IN`·`ANY`·`ALL`, 여러 컬럼이면 `(컬럼1, 컬럼2) IN`을 써요 |
| 위치에 따른 분류와 뷰 | SELECT 절은 스칼라 서브쿼리, FROM 절은 인라인 뷰, WHERE·HAVING 절은 중첩 서브쿼리예요. 뷰는 SELECT에 이름을 붙여 저장한 거예요 |
| 연관 서브쿼리와 EXISTS | 메인쿼리의 컬럼을 쓰는 서브쿼리는 메인쿼리 행마다 다시 계산돼요. EXISTS는 결과가 한 행이라도 있으면 참이에요 |
| NOT IN과 NULL | NOT IN 목록에 NULL이 하나라도 있으면 결과가 0행이 돼요. NOT EXISTS는 NULL의 영향을 받지 않아요 |

## 이 단원에서 쓰는 데이터

이 단원의 예제는 사원 테이블 `EMP`와 부서 테이블 `DEPT`를 써요. 아래는 이 단원에 필요한 컬럼만 뽑은 거예요.

**EMP (사원)**

| EMPNO (사번) | ENAME (이름) | JOB (직무) | SAL (급여) | DEPTNO (부서) |
| -- | -- | -- | -- | -- |
| 1001 | 김대표 | CEO | 9000 | 10 |
| 1002 | 이개발 | MANAGER | 6000 | 10 |
| 1003 | 박영업 | MANAGER | 6000 | 20 |
| 1004 | 최코드 | DEV | 4000 | 10 |
| 1005 | 정코드 | DEV | 4000 | 10 |
| 1006 | 한세일 | SALES | 3500 | 20 |
| 1007 | 윤세일 | SALES | 3000 | 20 |
| 1008 | 강신입 | DEV | 3000 | 10 |
| 1009 | 조미정 | SALES | 2800 | NULL |
| 1010 | 서인턴 | DEV | NULL | 10 |

**DEPT (부서)**

| DEPTNO (부서 번호) | DNAME (부서 이름) |
| -- | -- |
| 10 | 개발 |
| 20 | 영업 |
| 30 | 기획 |

시험에 자주 나오는 함정이 데이터에 일부러 들어 있어요. 아래 내용을 기억해 두면 예제를 따라가기 쉬워요.

- **서인턴**은 급여(SAL)가 NULL이에요. 급여를 비교하는 조건에서는 늘 빠져요.
- **조미정**은 부서(DEPTNO)가 NULL이에요. 아직 부서에 배치되지 않았어요. 이 단원의 NOT IN 함정은 조미정 때문에 생겨요.
- **30번 기획 부서**에는 사원이 한 명도 없어요.

## 설명

### 1. 반환 결과에 따른 분류

서브쿼리(Subquery)는 SQL 문장 안에 괄호로 넣은 또 하나의 SELECT예요. 서브쿼리를 품고 있는 바깥쪽 SELECT는 메인쿼리라고 불러요. 메인쿼리는 서브쿼리의 결과를 값처럼 받아서 써요.

그래서 **서브쿼리가 몇 행, 몇 컬럼을 돌려주는지에 맞는 연산자**를 써야 해요.

| 서브쿼리 결과 | 이름 | 쓸 수 있는 연산자 |
| -- | -- | -- |
| 1행 | 단일 행 서브쿼리 | `=`, `<>`, `>`, `>=`, `<`, `<=` |
| 여러 행 | 다중 행 서브쿼리 | `IN`, `NOT IN`, `ANY`(`SOME`), `ALL`, `EXISTS` |
| 여러 컬럼 | 다중 컬럼 서브쿼리 | `(컬럼1, 컬럼2) IN (SELECT a, b ...)` |

**단일 행 서브쿼리**

전체 평균 급여보다 많이 받는 사원을 찾아볼게요.

```sql
SELECT ENAME, SAL
FROM EMP
WHERE SAL > (SELECT AVG(SAL) FROM EMP)
ORDER BY EMPNO;
```

| ENAME | SAL |
| -- | -- |
| 김대표 | 9000 |
| 이개발 | 6000 |
| 박영업 | 6000 |

하나씩 따라가 볼게요.

1. 서브쿼리 `SELECT AVG(SAL) FROM EMP`가 먼저 계산돼요. 급여 합계 41300을, 급여가 있는 9명(서인턴 제외)으로 나눠서 약 4588.9예요. 결과가 한 행이라서 `>`를 쓸 수 있어요.
2. 메인쿼리는 `WHERE SAL > 4588.9`처럼 동작해요.
3. 4588.9보다 많이 받는 김대표(9000), 이개발(6000), 박영업(6000) 3명이 남아요.

**여러 행이 나오는데 `=`를 쓰면 오류예요**

```sql
-- 오류 (ORA-01427)
SELECT ENAME, SAL
FROM EMP
WHERE SAL = (SELECT SAL FROM EMP WHERE DEPTNO = 20);
```

20번 부서 사원은 박영업(6000), 한세일(3500), 윤세일(3000) 3명이라서 서브쿼리가 3행을 돌려줘요. `=`는 값 하나와만 비교할 수 있기 때문에 오류가 나요. 서브쿼리가 여러 행을 돌려줄 수 있다면 `IN`, `ANY`, `ALL`을 써야 해요.

**다중 행 서브쿼리: ANY와 ALL**

`ANY`는 "목록 안의 값 중 **하나라도** 조건을 만족하면 참"이고, `ALL`은 "목록 안의 값 **모두에 대해** 조건을 만족해야 참"이에요. `SOME`은 `ANY`와 같은 뜻이에요.

20번 부서의 누군가보다 많이 받는 사원을 찾아볼게요.

```sql
SELECT ENAME, SAL
FROM EMP
WHERE SAL > ANY (SELECT SAL
                 FROM EMP
                 WHERE DEPTNO = 20)
ORDER BY EMPNO;
```

| ENAME | SAL |
| -- | -- |
| 김대표 | 9000 |
| 이개발 | 6000 |
| 박영업 | 6000 |
| 최코드 | 4000 |
| 정코드 | 4000 |
| 한세일 | 3500 |

하나씩 따라가 볼게요.

1. 서브쿼리 결과는 {6000, 3500, 3000}이에요.
2. `> ANY`는 이 중 하나보다만 크면 참이에요. 가장 작은 값인 3000보다 크기만 하면 되니까, 결국 `> 3000`과 같아요.
3. 3000을 받는 윤세일과 강신입은 3000보다 "크지" 않아서 빠져요. 2800을 받는 조미정도 빠져요.
4. 서인턴은 급여가 NULL이라 비교 결과가 UNKNOWN(참도 거짓도 아닌 상태)이 되고, WHERE는 참인 행만 남기기 때문에 빠져요.
5. 그래서 6명이 남아요.

같은 서브쿼리에 `ALL`을 쓰면 결과가 크게 달라져요.

```sql
SELECT ENAME, SAL
FROM EMP
WHERE SAL > ALL (SELECT SAL
                 FROM EMP
                 WHERE DEPTNO = 20)
ORDER BY EMPNO;
```

| ENAME | SAL |
| -- | -- |
| 김대표 | 9000 |

1. `> ALL`은 6000, 3500, 3000 **모두보다** 커야 해요. 가장 큰 값인 6000보다 커야 한다는 뜻이라서 `> 6000`과 같아요.
2. 이개발과 박영업은 6000으로 같아서 "크지" 않아요. 그래서 김대표 1명만 남아요.
3. 방향을 바꿔 `< ALL`로 쓰면 가장 작은 값 3000보다 작아야 해서, 2800인 조미정 1명만 나와요.

ANY와 ALL은 최솟값·최댓값으로 바꿔서 생각하면 쉬워요.

| 조건 | 같은 뜻 | 이 데이터에서 |
| -- | -- | -- |
| `> ANY` | `> MIN` (최솟값보다 크다) | `> 3000` → 6명 |
| `< ANY` | `< MAX` (최댓값보다 작다) | `< 6000` → 6명 |
| `> ALL` | `> MAX` (최댓값보다 크다) | `> 6000` → 1명 |
| `< ALL` | `< MIN` (최솟값보다 작다) | `< 3000` → 1명 |
| `= ANY` | `IN` | 6000, 3500, 3000 중 하나 → 5명 |

`< ANY`의 6명은 최코드, 정코드, 한세일, 윤세일, 강신입, 조미정이에요. `= ANY`의 5명은 이개발, 박영업, 한세일, 윤세일, 강신입이에요.

**다중 컬럼 서브쿼리**

서브쿼리가 컬럼 두 개 이상을 돌려주면, 메인쿼리에서도 컬럼을 괄호로 묶어 짝을 맞춰 비교해요. 부서별로 가장 많이 받는 사원을 찾아볼게요.

```sql
SELECT ENAME, DEPTNO, SAL
FROM EMP
WHERE (DEPTNO, SAL) IN (SELECT DEPTNO, MAX(SAL)
                        FROM EMP
                        GROUP BY DEPTNO)
ORDER BY EMPNO;
```

| ENAME | DEPTNO | SAL |
| -- | -- | -- |
| 김대표 | 10 | 9000 |
| 박영업 | 20 | 6000 |

하나씩 따라가 볼게요.

1. 서브쿼리는 부서별 최고 급여를 구해요. 결과는 (10, 9000), (20, 6000), (NULL, 2800) 3행이에요. 마지막 행은 부서가 NULL인 조미정 혼자 만든 그룹이에요.
2. 메인쿼리는 각 사원의 (DEPTNO, SAL) 짝이 이 3개 중 하나와 똑같은지 봐요. 김대표의 (10, 9000)과 박영업의 (20, 6000)이 맞아요.
3. 조미정의 (NULL, 2800)은 서브쿼리 결과에 그대로 있는데도 빠져요. `NULL = NULL`은 참이 아니라 UNKNOWN이기 때문이에요.

참고로 다중 컬럼 IN은 Oracle에서는 쓸 수 있지만, SQL Server에서는 지원하지 않아요.

### 2. 위치에 따른 분류와 뷰

서브쿼리는 SQL의 어느 절에 들어가느냐에 따라서도 이름과 규칙이 달라요.

| 위치 | 이름 | 특징 |
| -- | -- | -- |
| SELECT 절 | 스칼라 서브쿼리 | 반드시 1행 1열을 돌려줘야 해요. 0행이면 NULL, 2행 이상이면 오류예요 |
| FROM 절 | 인라인 뷰 | 실행할 때 만들어지는 임시 테이블이에요. 안의 컬럼을 메인쿼리에서 쓸 수 있고, ORDER BY도 쓸 수 있어요 |
| WHERE / HAVING 절 | 중첩 서브쿼리 | 조건을 비교할 때 써요. 1번에서 본 예제가 모두 여기에 해당해요 |

**스칼라 서브쿼리**

스칼라(scalar)는 "값 하나"라는 뜻이에요. SELECT 절에 넣은 서브쿼리는 컬럼 자리에 들어가기 때문에, 행마다 값 하나만 돌려줘야 해요. SALES 직무 사원의 부서 이름을 붙여 볼게요.

```sql
SELECT E.ENAME,
       (SELECT D.DNAME
        FROM DEPT D
        WHERE D.DEPTNO = E.DEPTNO) AS DNAME
FROM EMP E
WHERE E.JOB = ''SALES''
ORDER BY E.EMPNO;
```

| ENAME | DNAME |
| -- | -- |
| 한세일 | 영업 |
| 윤세일 | 영업 |
| 조미정 | NULL |

하나씩 따라가 볼게요.

1. SALES 사원은 한세일, 윤세일, 조미정 3명이에요. 스칼라 서브쿼리는 이 3명 각각에 대해 한 번씩 부서 이름을 찾아요.
2. 한세일과 윤세일은 20번 부서라서 ''영업''을 찾아요.
3. 조미정은 DEPTNO가 NULL이라 맞는 부서가 없어서 서브쿼리가 0행을 돌려줘요. 이때 **오류가 아니라 NULL**이 돼요. 조미정의 행 자체는 결과에 남아요. 같은 내용을 INNER JOIN으로 썼다면 조미정은 빠졌을 거예요.
4. 서브쿼리에서 조건을 빼고 `(SELECT DNAME FROM DEPT)`로 쓰면 3행(개발, 영업, 기획)이 나와서 오류가 나요.

**인라인 뷰**

FROM 절에 넣은 서브쿼리는 그 자리에서 임시 테이블처럼 쓰여요. 부서별 인원과 평균 급여를 먼저 만들고, 그 결과를 DEPT와 조인해 볼게요.

```sql
SELECT D.DNAME,
       V.CNT,
       ROUND(V.AVG_SAL) AS AVG_SAL
FROM DEPT D,
     (SELECT DEPTNO,
             COUNT(*) AS CNT,
             AVG(SAL) AS AVG_SAL
      FROM EMP
      GROUP BY DEPTNO) V
WHERE D.DEPTNO = V.DEPTNO
ORDER BY D.DEPTNO;
```

| DNAME | CNT | AVG_SAL |
| -- | -- | -- |
| 개발 | 6 | 5200 |
| 영업 | 3 | 4167 |

하나씩 따라가 볼게요.

1. 인라인 뷰 V는 부서별로 묶어서 (10, 6명, 5200), (20, 3명, 4166.7), (NULL, 1명, 2800) 3행을 만들어요.
2. 10번 부서의 평균은 26000 ÷ 6이 아니라 26000 ÷ 5 = 5200이에요. AVG는 NULL을 빼고 계산하기 때문에 서인턴이 나누는 수에서 빠졌어요.
3. DEPT와 부서 번호로 조인하면 개발(10)과 영업(20)만 짝이 맞아요. 조미정의 NULL 그룹은 짝이 없어서 빠지고, 30번 기획은 V에 행이 없어서 빠져요.
4. 메인쿼리가 인라인 뷰 안에서 만든 컬럼 `V.CNT`, `V.AVG_SAL`을 그대로 SELECT에 썼어요. **인라인 뷰의 컬럼은 메인쿼리에서 쓸 수 있지만, WHERE 절 중첩 서브쿼리의 컬럼은 메인쿼리에서 쓸 수 없어요.** 이 차이가 시험에 나와요.

**뷰(View)**

뷰는 SELECT 문장에 이름을 붙여 데이터베이스에 저장해 둔 거예요. 인라인 뷰를 이름 붙여 저장했다고 생각하면 돼요. 뷰는 데이터를 따로 저장하지 않고 SELECT 정의만 저장하기 때문에 **가상 테이블**이라고 불러요. 뷰를 조회할 때마다 저장된 SELECT가 실행돼요.

사원과 부서를 조인한 결과를 뷰로 만들어 볼게요.

```sql
CREATE VIEW V_EMP_DEPT AS
SELECT E.EMPNO, E.ENAME, D.DNAME
FROM EMP E
JOIN DEPT D ON E.DEPTNO = D.DEPTNO;
```

이제 이 뷰를 테이블처럼 조회할 수 있어요.

```sql
SELECT DNAME, COUNT(*) AS CNT
FROM V_EMP_DEPT
GROUP BY DNAME;
```

| DNAME | CNT |
| -- | -- |
| 개발 | 6 |
| 영업 | 3 |

뷰 안의 조인이 INNER JOIN이라서 부서가 없는 조미정은 뷰에 들어가지 않아요. 그래서 개발 6명, 영업 3명으로 모두 9명이에요.

뷰의 장점은 세 가지로 정리돼요.

| 장점 | 뜻 |
| -- | -- |
| 독립성 | 테이블 구조가 바뀌어도 뷰 정의만 고치면, 뷰를 쓰는 SQL은 그대로 둘 수 있어요 |
| 편리성 | 복잡한 조인이나 조건을 이름 하나로 간단히 쓸 수 있어요 |
| 보안성 | 보여 주고 싶은 컬럼만 담아서, 나머지 컬럼은 숨길 수 있어요 |

뷰의 정의는 **ALTER VIEW로 바꿀 수 없어요.** 정의를 바꾸려면 DROP VIEW로 지우고 다시 만들어야 해요. Oracle에서는 `CREATE OR REPLACE VIEW`로 한 번에 다시 만들 수 있어요.

### 3. 연관 서브쿼리와 EXISTS

서브쿼리는 메인쿼리의 컬럼을 쓰는지에 따라 두 가지로 나뉘어요.

| 종류 | 메인쿼리 컬럼 사용 | 실행 방식 |
| -- | -- | -- |
| 비연관 서브쿼리 | 쓰지 않아요 | 서브쿼리가 혼자 한 번 실행되고, 그 결과를 메인쿼리에 넘겨요 |
| 연관 서브쿼리 | 써요 | 메인쿼리의 행이 바뀔 때마다 서브쿼리가 다시 계산돼요 |

1번에서 본 예제들은 모두 비연관 서브쿼리예요. 이번에는 연관 서브쿼리로 "자기 부서 평균보다 많이 받는 사원"을 찾아볼게요.

```sql
SELECT E.ENAME, E.DEPTNO, E.SAL
FROM EMP E
WHERE E.SAL > (SELECT AVG(X.SAL)
               FROM EMP X
               WHERE X.DEPTNO = E.DEPTNO)
ORDER BY E.EMPNO;
```

| ENAME | DEPTNO | SAL |
| -- | -- | -- |
| 김대표 | 10 | 9000 |
| 이개발 | 10 | 6000 |
| 박영업 | 20 | 6000 |

서브쿼리 안의 `E.DEPTNO`는 메인쿼리의 사원 E를 가리켜요. 그래서 메인쿼리가 어떤 사원을 보고 있느냐에 따라 서브쿼리가 구하는 평균이 달라져요.

하나씩 따라가 볼게요.

1. 이개발(10번)을 볼 때 서브쿼리는 `X.DEPTNO = 10`으로 10번 부서 평균 5200을 구해요. 6000 > 5200이라 참이에요. 김대표(9000)도 같은 이유로 남아요.
2. 최코드(10번, 4000)는 4000 > 5200이 거짓이라 빠져요.
3. 한세일(20번)을 볼 때 서브쿼리는 20번 부서 평균 약 4166.7을 구해요. 3500 > 4166.7이 거짓이라 빠져요. 박영업(6000)은 참이라 남아요.
4. 조미정은 `X.DEPTNO = NULL`이 어떤 행과도 맞지 않아서 평균이 NULL이에요. 비교가 UNKNOWN이 되어 빠져요.
5. 서인턴은 자기 급여가 NULL이라 비교가 UNKNOWN이 되어 빠져요.

**EXISTS**

EXISTS는 서브쿼리 결과가 **한 행이라도 있으면 참**, 한 행도 없으면 거짓이에요. 행이 있는지만 보고 값은 보지 않기 때문에, 서브쿼리의 SELECT에는 `SELECT 1`이나 `SELECT ''X''`처럼 아무 값이나 써요. 주로 연관 서브쿼리와 함께 써요.

사원이 한 명도 없는 부서를 찾아볼게요.

```sql
SELECT D.DEPTNO, D.DNAME
FROM DEPT D
WHERE NOT EXISTS (SELECT 1
                  FROM EMP E
                  WHERE E.DEPTNO = D.DEPTNO)
ORDER BY D.DEPTNO;
```

| DEPTNO | DNAME |
| -- | -- |
| 30 | 기획 |

하나씩 따라가 볼게요.

1. 10번 개발을 볼 때 서브쿼리는 10번 부서 사원 6명을 찾아요. 행이 있으니 EXISTS는 참, NOT EXISTS는 거짓이라 빠져요.
2. 20번 영업도 사원 3명이 있어서 빠져요.
3. 30번 기획을 볼 때 서브쿼리는 0행이에요. NOT EXISTS가 참이라 남아요.

`NOT EXISTS`를 `EXISTS`로 바꾸면 반대로 사원이 있는 10 개발, 20 영업 2행이 나와요.

### 4. NOT IN과 NULL 함정

3번에서 NOT EXISTS로 찾은 "사원이 없는 부서"를 NOT IN으로 찾아볼게요. 같은 결과가 나올 것 같지만, 결과가 비어 있어요.

```sql
SELECT D.DEPTNO, D.DNAME
FROM DEPT D
WHERE D.DEPTNO NOT IN (SELECT E.DEPTNO
                       FROM EMP E);
```

| DEPTNO | DNAME |
| -- | -- |

0행이에요. 하나씩 따라가 볼게요.

1. 서브쿼리는 사원 10명의 부서 번호를 돌려줘요. 겹치는 값을 빼면 {10, 20, NULL}이에요. NULL은 조미정의 부서예요.
2. `NOT IN`은 "목록의 모든 값과 다르다"는 뜻이라서, `AND`로 이어진 비교로 바뀌어요. 30번 부서라면 `30 <> 10 AND 30 <> 20 AND 30 <> NULL`이에요.
3. `30 <> 10`은 참, `30 <> 20`도 참이에요. 그런데 `30 <> NULL`은 NULL과 비교했기 때문에 UNKNOWN이에요.
4. 참 AND 참 AND UNKNOWN은 UNKNOWN이에요. WHERE는 참인 행만 남기기 때문에 30번도 빠져요. 10번과 20번은 목록에 있어서 처음부터 거짓이에요.
5. 그래서 아무 행도 남지 않아요.

해결하려면 서브쿼리에서 NULL을 빼면 돼요.

```sql
SELECT D.DEPTNO, D.DNAME
FROM DEPT D
WHERE D.DEPTNO NOT IN (SELECT E.DEPTNO
                       FROM EMP E
                       WHERE E.DEPTNO IS NOT NULL);
```

| DEPTNO | DNAME |
| -- | -- |
| 30 | 기획 |

이제 목록이 {10, 20}이 되어서 `30 <> 10 AND 30 <> 20`이 참이고, 30 기획 1행이 나와요.

**NOT EXISTS와 IN은 괜찮아요**

- NOT EXISTS는 "짝이 되는 행이 있는가"만 보기 때문에 NULL의 영향을 받지 않아요. 3번 예제에서 NULL을 따로 빼지 않았는데도 30 기획이 제대로 나왔어요.
- `IN`은 NULL이 섞여도 괜찮아요. `x IN (10, 20, NULL)`은 `x = 10 OR x = 20 OR x = NULL`이라서, 맞는 값이 하나라도 있으면 참이에요. 그래서 `DEPTNO IN (SELECT DEPTNO FROM EMP)`는 10 개발, 20 영업 2행이 정상으로 나와요.

정리하면, **NULL이 문제를 일으키는 것은 NOT IN뿐**이에요.

## 자주 하는 오해

| 오해 | 실제 |
| -- | -- |
| `> ANY`는 "모두보다 크다"는 뜻이다 | `> ANY`는 하나라도보다 크면, 즉 최솟값보다 크면 참이에요. 20번 부서 급여로 비교하면 `> 3000`이라 6명이에요. "모두보다 크다"는 `> ALL`이고, `> 6000`이라 김대표 1명이에요 |
| 여러 행이 나오는 서브쿼리에도 `=`를 쓸 수 있다 | 오류(ORA-01427)가 나요. 20번 부서 급여는 3행이라 `IN`이나 `ANY`를 써야 해요 |
| 스칼라 서브쿼리가 0행이면 오류다 | 0행이면 NULL이 돼요. 조미정의 부서 이름이 NULL로 나온 것처럼요. 오류는 2행 이상일 때 나요 |
| NOT IN과 NOT EXISTS는 언제나 결과가 같다 | 서브쿼리 결과에 NULL이 있으면 NOT IN만 0행이 돼요. 같은 질문에 NOT EXISTS는 30 기획 1행, NOT IN은 0행이었어요 |
| 서브쿼리 안의 컬럼은 메인쿼리 SELECT에서 쓸 수 있다 | WHERE 절 중첩 서브쿼리의 컬럼은 쓸 수 없어요. FROM 절 인라인 뷰의 컬럼만 쓸 수 있어요 |
| 뷰는 결과 데이터를 따로 저장한다 | 뷰는 SELECT 정의만 저장하는 가상 테이블이에요. 조회할 때마다 SELECT가 다시 실행돼요 |
| 뷰 정의는 ALTER VIEW로 고친다 | ALTER VIEW로는 정의를 바꿀 수 없어요. 지우고 다시 만들거나, Oracle에서는 `CREATE OR REPLACE VIEW`를 써요 |
'),
	('s2-11', '그룹 함수', '# 그룹 함수

## 이 단원에서 배우는 것

- ROLLUP, CUBE, GROUPING SETS가 각각 어떤 소계와 총계를 만드는지 설명할 수 있어요.
- 결과표에서 어떤 행이 상세 행이고, 어떤 행이 소계나 총계 행인지 알아볼 수 있어요.
- ROLLUP의 인자 순서를 바꿨을 때 결과가 어떻게 달라지는지 예측할 수 있어요.
- 결과표만 보고 ROLLUP, CUBE, GROUPING SETS 중 무엇을 썼는지 고를 수 있어요.
- GROUPING 함수로 소계 행의 NULL과 원래 데이터의 NULL을 구분할 수 있어요.

## 개념 한눈에 보기

| 개념 | 한 줄 정리 |
| -- | -- |
| ROLLUP과 인자 순서 | 오른쪽 컬럼부터 하나씩 빼면서 소계를 만들고, 마지막에 총계를 붙여요. 인자 순서가 바뀌면 소계 기준이 바뀌어요 |
| CUBE와 GROUPING SETS | CUBE는 가능한 모든 조합(2^n개)의 소계와 총계를 만들어요. GROUPING SETS는 괄호 안에 나열한 그룹만 만들고, 총계는 붙이지 않아요 |
| 결과표로 그룹 함수 고르기 | 총계 행이 있는지, 두 번째 컬럼만의 소계 행이 있는지를 보고 셋을 가려요 |
| GROUPING 함수 | 그 행이 해당 컬럼을 빼고 집계한 소계·총계 행이면 1, 아니면 0을 돌려줘요. 소계의 NULL과 데이터의 NULL을 구분할 때 써요 |

## 이 단원에서 쓰는 데이터

GROUP BY 하나로는 "부서별 합계"처럼 한 가지 기준의 결과만 나와요. 이 단원에서 배우는 그룹 함수(ROLLUP, CUBE, GROUPING SETS)를 쓰면 여기에 **소계 행과 총계 행**을 한 번에 붙일 수 있어요. 시험에서는 결과표를 보여 주고 "어떤 GROUP BY를 썼나"를 고르게 하는 문제가 많이 나와요.

설명 1~3의 예제는 매출 테이블 `SALES`를 써요. 부서별, 연도별, 분기별 매출 금액이 들어 있어요.

| DEPTNO (부서) | YR (연도) | QTR (분기) | AMT (금액) |
| -- | -- | -- | -- |
| 10 | 2025 | Q1 | 100 |
| 10 | 2025 | Q2 | 150 |
| 10 | 2026 | Q1 | 80 |
| 20 | 2025 | Q1 | 200 |
| 20 | 2025 | Q2 | NULL |
| 20 | 2026 | Q1 | 120 |

- **20번 부서의 2025년 Q2** 행은 금액(AMT)이 NULL이에요. SUM은 NULL을 빼고 더하기 때문에, 20번 부서의 2025년 합계는 200 + NULL이 아니라 200이에요.

설명 4의 예제는 사원 테이블 `EMP`를 써요. 아래는 필요한 컬럼만 뽑은 거예요.

| ENAME (이름) | SAL (급여) | DEPTNO (부서) |
| -- | -- | -- |
| 김대표 | 9000 | 10 |
| 이개발 | 6000 | 10 |
| 최코드 | 4000 | 10 |
| 정코드 | 4000 | 10 |
| 강신입 | 3000 | 10 |
| 서인턴 | NULL | 10 |
| 박영업 | 6000 | 20 |
| 한세일 | 3500 | 20 |
| 윤세일 | 3000 | 20 |
| 조미정 | 2800 | NULL |

- **조미정**은 부서(DEPTNO)가 NULL이에요. 이 사람 때문에 결과표에 "부서가 NULL인 행"이 생겨서, 소계 행과 헷갈리게 돼요. 설명 4에서 다뤄요.
- **서인턴**은 급여(SAL)가 NULL이에요. 10번 부서의 급여 합계에서 빠져요.

## 설명

### 1. ROLLUP과 인자 순서

먼저 그룹 함수 없이 부서별, 연도별 합계를 구해 볼게요.

```sql
SELECT DEPTNO, YR, SUM(AMT) AS TOTAL
FROM SALES
GROUP BY DEPTNO, YR
ORDER BY DEPTNO, YR;
```

| DEPTNO | YR | TOTAL |
| -- | -- | -- |
| 10 | 2025 | 250 |
| 10 | 2026 | 80 |
| 20 | 2025 | 200 |
| 20 | 2026 | 120 |

부서와 연도가 모두 값으로 채워진 4행이 나와요. 이렇게 GROUP BY 기준 컬럼이 모두 값으로 채워진 행을 이 단원에서는 **상세 행**이라고 부를게요.

이제 GROUP BY 자리에 `ROLLUP(DEPTNO, YR)`을 써 볼게요. ROLLUP은 상세 행에 더해, **오른쪽 컬럼부터 하나씩 빼면서** 다시 집계한 행을 붙여 줘요.

- (DEPTNO, YR)로 묶은 상세 행
- YR을 빼고 DEPTNO로만 묶은 **부서별 소계** 행
- 둘 다 빼고 전체를 하나로 묶은 **총계** 행

그래서 컬럼이 n개면 묶는 단계는 n + 1개예요. 컬럼이 2개인 지금은 3단계예요.

```sql
SELECT DEPTNO, YR, SUM(AMT) AS TOTAL
FROM SALES
GROUP BY ROLLUP(DEPTNO, YR)
ORDER BY DEPTNO, YR;
```

| DEPTNO | YR | TOTAL |
| -- | -- | -- |
| 10 | 2025 | 250 |
| 10 | 2026 | 80 |
| 10 | NULL | 330 |
| 20 | 2025 | 200 |
| 20 | 2026 | 120 |
| 20 | NULL | 320 |
| NULL | NULL | 650 |

**소계와 총계 행은 이렇게 알아봐요**

소계 행에서는 묶음에서 뺀 컬럼에 넣을 값이 없어요. 그래서 그 자리가 **NULL**로 나와요. 결과표에서 NULL이 어느 자리에 있는지를 보면 행의 종류를 알 수 있어요.

| 행 모양 | 무슨 행인지 | 위 결과의 예 |
| -- | -- | -- |
| 두 자리 모두 값 | 상세 행 | 10, 2025, 250 |
| YR 자리만 NULL | 부서별 소계 (연도를 뺌) | 10, NULL, 330 |
| DEPTNO 자리만 NULL | 연도별 소계 (부서를 뺌) | 이 결과에는 없어요 |
| 두 자리 모두 NULL | 총계 (둘 다 뺌) | NULL, NULL, 650 |

하나씩 따라가 볼게요.

1. 처음 4행은 상세 행이에요. 앞에서 GROUP BY DEPTNO, YR로 구한 결과와 같아요.
2. 20번 부서의 2025년은 200이에요. 2025년 Q2의 금액이 NULL이라서 SUM에서 빠졌어요.
3. `10, NULL, 330`은 10번 부서의 소계예요. 연도를 빼고 10번 부서 전체를 더해서 250 + 80 = 330이에요.
4. `20, NULL, 320`은 20번 부서의 소계예요. 200 + 120 = 320이에요.
5. 마지막 `NULL, NULL, 650`은 총계예요. 330 + 320 = 650이에요.
6. 상세 4행 + 소계 2행 + 총계 1행으로 모두 7행이에요.

ROLLUP 결과의 행 순서는 보장되지 않아요. 상세 행과 소계 행이 섞여 나올 수 있으니, 결과를 볼 때는 ORDER BY를 붙이세요. 위 예제는 ORDER BY DEPTNO, YR로 정렬해서 NULL이 각 부서의 맨 아래에 왔어요. Oracle은 오름차순 정렬에서 NULL을 맨 뒤에 놓기 때문이에요.

**인자 순서를 바꾸면**

이번에는 괄호 안의 순서를 `ROLLUP(YR, DEPTNO)`로 바꿔 볼게요.

```sql
SELECT DEPTNO, YR, SUM(AMT) AS TOTAL
FROM SALES
GROUP BY ROLLUP(YR, DEPTNO)
ORDER BY YR, DEPTNO;
```

| DEPTNO | YR | TOTAL |
| -- | -- | -- |
| 10 | 2025 | 250 |
| 20 | 2025 | 200 |
| NULL | 2025 | 450 |
| 10 | 2026 | 80 |
| 20 | 2026 | 120 |
| NULL | 2026 | 200 |
| NULL | NULL | 650 |

하나씩 따라가 볼게요.

1. 이번에는 오른쪽 컬럼이 DEPTNO예요. 그래서 DEPTNO를 먼저 빼고 YR로만 묶은 **연도별 소계**가 생겨요.
2. `NULL, 2025, 450`은 2025년 소계예요. 10번 부서 250 + 20번 부서 200 = 450이에요. DEPTNO 자리만 NULL이에요.
3. `NULL, 2026, 200`은 2026년 소계예요. 80 + 120 = 200이에요.
4. 상세 4행과 총계 650은 앞의 결과와 같아요.
5. 행 수는 7행으로 같지만, 소계가 "부서별"에서 "연도별"로 바뀌었어요.

정리하면 **ROLLUP(A, B)와 ROLLUP(B, A)는 결과가 달라요.** 인자 순서가 소계 기준을 정해요.

### 2. CUBE와 GROUPING SETS

**CUBE**

CUBE는 괄호 안 컬럼으로 만들 수 있는 **모든 조합**으로 묶어요. `CUBE(DEPTNO, YR)`이면 아래 4가지로 묶어요.

- (DEPTNO, YR): 상세 행
- (DEPTNO): 부서별 소계
- (YR): 연도별 소계
- (): 총계. 빈 괄호 `()`는 "아무 컬럼으로도 나누지 않고 전체를 하나로 묶는다"는 뜻이에요

컬럼이 n개면 조합은 2^n개예요. 모든 조합을 다 만들기 때문에 인자 순서를 바꿔도 결과 내용은 같아요. 행이 나오는 순서만 다를 수 있어요.

```sql
SELECT DEPTNO, YR, SUM(AMT) AS TOTAL
FROM SALES
GROUP BY CUBE(DEPTNO, YR)
ORDER BY DEPTNO, YR;
```

| DEPTNO | YR | TOTAL |
| -- | -- | -- |
| 10 | 2025 | 250 |
| 10 | 2026 | 80 |
| 10 | NULL | 330 |
| 20 | 2025 | 200 |
| 20 | 2026 | 120 |
| 20 | NULL | 320 |
| NULL | 2025 | 450 |
| NULL | 2026 | 200 |
| NULL | NULL | 650 |

하나씩 따라가 볼게요.

1. 위쪽 6행은 ROLLUP(DEPTNO, YR) 결과의 상세 행과 부서별 소계(330, 320)와 같아요.
2. `NULL, 2025, 450`과 `NULL, 2026, 200`은 연도별 소계예요. ROLLUP(DEPTNO, YR)에는 없던 행이에요. DEPTNO 자리만 NULL이에요.
3. 마지막 `NULL, NULL, 650`은 총계예요.
4. ROLLUP(DEPTNO, YR)의 7행에 연도별 소계 2행이 더해져서 모두 9행이에요.

**GROUPING SETS**

GROUPING SETS는 괄호 안에 **나열한 그룹만** 따로 집계해서 합쳐요. `GROUPING SETS(DEPTNO, YR)`이면 "부서별"과 "연도별" 두 가지로만 묶어요.

```sql
SELECT DEPTNO, YR, SUM(AMT) AS TOTAL
FROM SALES
GROUP BY GROUPING SETS(DEPTNO, YR)
ORDER BY DEPTNO, YR;
```

| DEPTNO | YR | TOTAL |
| -- | -- | -- |
| 10 | NULL | 330 |
| 20 | NULL | 320 |
| NULL | 2025 | 450 |
| NULL | 2026 | 200 |

하나씩 따라가 볼게요.

1. `10, NULL, 330`과 `20, NULL, 320`은 DEPTNO로만 묶은 부서별 결과예요. 연도로는 나누지 않았으니 YR 자리가 NULL이에요.
2. `NULL, 2025, 450`과 `NULL, 2026, 200`은 YR로만 묶은 연도별 결과예요. DEPTNO 자리가 NULL이에요.
3. (부서, 연도) 상세 행이 없어요. 나열하지 않았기 때문이에요.
4. **총계 650 행도 없어요.** GROUPING SETS는 총계를 자동으로 붙이지 않아요.

그래서 GROUPING SETS(DEPTNO, YR)는 "GROUP BY DEPTNO 결과"와 "GROUP BY YR 결과"를 UNION ALL로 이어 붙인 것과 같아요.

총계가 필요하면 빈 괄호 `()`를 직접 나열하면 돼요.

```sql
SELECT DEPTNO, YR, SUM(AMT) AS TOTAL
FROM SALES
GROUP BY GROUPING SETS(DEPTNO, YR, ())
ORDER BY DEPTNO, YR;
```

| DEPTNO | YR | TOTAL |
| -- | -- | -- |
| 10 | NULL | 330 |
| 20 | NULL | 320 |
| NULL | 2025 | 450 |
| NULL | 2026 | 200 |
| NULL | NULL | 650 |

`()`를 넣었더니 마지막에 총계 650 행이 생겨서 5행이 됐어요.

**셋은 서로 바꿔 쓸 수 있어요**

GROUPING SETS에 그룹을 어떻게 나열하느냐에 따라 ROLLUP이나 CUBE와 같은 결과를 만들 수 있어요.

| 그룹 함수 | 같은 결과를 내는 GROUPING SETS |
| -- | -- |
| ROLLUP(A, B) | GROUPING SETS((A, B), A, ()) |
| CUBE(A, B) | GROUPING SETS((A, B), A, B, ()) |

예를 들어 `GROUPING SETS((DEPTNO, YR), DEPTNO, ())`를 실행하면 ROLLUP(DEPTNO, YR)과 똑같은 7행이 나와요. `GROUPING SETS((DEPTNO, YR), DEPTNO, YR, ())`는 CUBE(DEPTNO, YR)과 똑같은 9행이 나와요. 괄호로 묶은 `(A, B)`는 "A와 B 두 컬럼으로 함께 묶는다"는 뜻이고, 이것이 상세 행을 만들어요.

### 3. 결과표로 그룹 함수 고르기

결과표만 주고 어떤 그룹 함수를 썼는지 묻는 문제는 아래 표로 풀 수 있어요. A는 괄호 안 첫 번째 컬럼, B는 두 번째 컬럼이에요.

| 확인할 것 | ROLLUP(A, B) | CUBE(A, B) | GROUPING SETS(A, B) |
| -- | -- | -- | -- |
| (A, B) 상세 행 | 있음 | 있음 | 없음 |
| A별 소계 (B 자리 NULL) | 있음 | 있음 | 있음 |
| B별 소계 (A 자리 NULL) | 없음 | 있음 | 있음 |
| 총계 (둘 다 NULL) | 있음 | 있음 | 없음 |
| 묶는 단계 수 | n + 1 | 2^n | 나열한 수 |

하나씩 따라가 볼게요. 앞에서 본 SALES 결과로 확인해요.

1. **총계 650 행이 있는지** 먼저 봐요. 없으면 GROUPING SETS예요. 위의 4행 결과가 여기에 해당해요.
2. 총계가 있으면, **연도만의 소계**(`NULL, 2025, 450`처럼 DEPTNO 자리만 NULL인 행)가 있는지 봐요. 부서별 소계도 있고 연도별 소계도 있으면 CUBE예요. 위의 9행 결과예요.
3. 총계가 있고 연도별 소계가 없으면 ROLLUP(DEPTNO, YR)이에요. 위의 첫 번째 7행 결과예요.
4. 반대로 총계가 있는데 부서별 소계(`10, NULL, 330`)가 없고 연도별 소계만 있으면 ROLLUP(YR, DEPTNO)예요.

한 가지 주의할 점이 있어요. 원래 데이터에 NULL이 들어 있으면 "NULL이 보이면 소계 행"이라고 단정할 수 없어요. 이 경우는 다음 설명에서 다뤄요.

### 4. GROUPING 함수

`GROUPING(컬럼)`은 그 행이 해당 컬럼을 **묶음에서 빼고 집계한 행**(소계나 총계)이면 1을, 그 컬럼의 원래 값으로 묶은 행이면 0을 돌려줘요.

이 함수가 필요한 이유는 이래요. 소계 행의 NULL과 원래 데이터의 NULL은 결과표에서 똑같이 NULL로 보여요. EMP에는 부서가 NULL인 조미정이 있어서, `ROLLUP(DEPTNO)`를 하면 DEPTNO가 NULL인 행이 두 개 생겨요.

- 조미정 한 명으로 이루어진 "부서가 NULL인 그룹" 행
- 모든 사원을 더한 총계 행

GROUPING으로 두 행을 구분하고, 각각에 이름을 붙여 볼게요.

```sql
SELECT DEPTNO,
       GROUPING(DEPTNO) AS G,
       CASE WHEN GROUPING(DEPTNO) = 1 THEN ''전체''
            WHEN DEPTNO IS NULL THEN ''부서없음''
            ELSE TO_CHAR(DEPTNO)
       END AS LABEL,
       COUNT(*) AS CNT,
       SUM(SAL) AS SUM_SAL
FROM EMP
GROUP BY ROLLUP(DEPTNO)
ORDER BY GROUPING(DEPTNO), DEPTNO;
```

| DEPTNO | G | LABEL | CNT | SUM_SAL |
| -- | -- | -- | -- | -- |
| 10 | 0 | 10 | 6 | 26000 |
| 20 | 0 | 20 | 3 | 12500 |
| NULL | 0 | 부서없음 | 1 | 2800 |
| NULL | 1 | 전체 | 10 | 41300 |

하나씩 따라가 볼게요.

1. 10번 부서 행은 G가 0이에요. DEPTNO의 원래 값 10으로 묶은 행이에요. CNT는 6명인데 SUM_SAL은 26000이에요. 서인턴의 급여가 NULL이라 합계에서 빠졌어요. COUNT(*)는 행 수를 세기 때문에 서인턴도 세서 6이에요.
2. 세 번째 행은 DEPTNO가 NULL이지만 G가 0이에요. 조미정의 원래 DEPTNO 값이 NULL이라서 생긴 그룹이고, 묶음에서 뺀 행이 아니에요. 그래서 CASE의 두 번째 조건에 걸려 ''부서없음''이 붙었어요.
3. 마지막 행은 DEPTNO를 묶음에서 빼고 전체를 집계한 총계 행이라 G가 1이에요. CASE의 첫 번째 조건에 걸려 ''전체''가 붙었어요. CNT 10은 조미정까지 모두 센 값이에요.
4. 두 행 모두 DEPTNO는 NULL이지만, G 값으로 둘을 구분할 수 있어요.

CASE에서 GROUPING 조건을 먼저 쓴 데도 이유가 있어요. `DEPTNO IS NULL`을 먼저 쓰면 총계 행도 그 조건에 걸려서 ''부서없음''이 붙어 버려요.

Oracle 문제에서는 CASE 대신 `DECODE(GROUPING(DEPTNO), 1, ''전체'', ...)`처럼 DECODE로 쓰는 경우도 자주 나와요. GROUPING 값이 1이면 ''전체''를 보여 준다는 뜻으로 읽으면 돼요.

SQL Server에서도 GROUPING 함수는 똑같이 쓸 수 있어요. SQL Server에는 `GROUP BY DEPTNO WITH ROLLUP` 같은 예전 문법도 있어요.

## 자주 하는 오해

| 오해 | 실제 |
| -- | -- |
| ROLLUP(A, B)와 ROLLUP(B, A)는 결과가 같다 | 소계 기준이 바뀌어요. ROLLUP(DEPTNO, YR)에는 부서별 소계(330, 320)가, ROLLUP(YR, DEPTNO)에는 연도별 소계(450, 200)가 나와요. CUBE와 GROUPING SETS만 인자 순서와 상관없어요 |
| GROUPING SETS도 마지막에 총계가 붙는다 | 나열한 그룹만 만들어요. GROUPING SETS(DEPTNO, YR)는 4행이고 총계 650이 없어요. `()`를 넣어야 총계가 나와요 |
| 결과에서 NULL이 보이면 무조건 소계 행이다 | 원래 데이터가 NULL인 그룹도 NULL로 보여요. 조미정의 행(CNT 1)은 DEPTNO가 NULL이지만 GROUPING이 0인 데이터 행이에요 |
| GROUPING(컬럼)은 컬럼 값이 NULL이면 1이다 | 그 컬럼을 묶음에서 빼고 집계한 행이면 1이에요. 값이 NULL인지와는 상관없어요. 조미정의 행은 NULL이어도 0이에요 |
| CUBE(A, B, C)는 묶는 단계가 4개다 | 2^3 = 8개예요. 4개(n + 1)는 ROLLUP(A, B, C)예요 |
'),
	('s2-12', '윈도우 함수', '# 윈도우 함수

## 이 단원에서 배우는 것

- RANK, DENSE_RANK, ROW_NUMBER가 동점을 어떻게 처리하는지 보고 결과를 예측할 수 있어요.
- NULL이 섞여 있을 때 Oracle에서 순위가 어떻게 매겨지는지 설명할 수 있어요.
- ORDER BY만 쓴 집계 윈도우 함수의 기본 범위(RANGE 누적)와 ROWS의 차이를 설명하고, 동점이 있을 때 누적합을 예측할 수 있어요.
- LAG, LEAD, FIRST_VALUE, LAST_VALUE의 결과를 예측하고, LAST_VALUE에서 자주 틀리는 이유를 설명할 수 있어요.
- RATIO_TO_REPORT, PERCENT_RANK, CUME_DIST, NTILE 값을 직접 계산할 수 있어요.

## 개념 한눈에 보기

| 개념 | 한 줄 정리 |
| -- | -- |
| 순위 함수 | RANK는 동점 다음 순위를 건너뛰고, DENSE_RANK는 건너뛰지 않고, ROW_NUMBER는 동점이어도 1, 2, 3처럼 서로 다른 번호를 붙여요 |
| 집계 윈도우 함수와 프레임 | ORDER BY가 있으면 기본 계산 범위는 "처음부터 현재 값까지(RANGE)"라서 동점 행은 같은 누적값을 받아요. ROWS는 한 줄씩 계산해요 |
| 행 순서 함수 | LAG/LEAD는 n행 앞/뒤의 값을, FIRST_VALUE/LAST_VALUE는 계산 범위의 처음/끝 값을 가져와요. 기본 범위에서 LAST_VALUE는 현재 행 값이에요 |
| 비율 함수 | RATIO_TO_REPORT는 합계 대비 비율, PERCENT_RANK는 (순위−1)÷(행 수−1), CUME_DIST는 현재 값 이하인 행의 비율, NTILE(n)은 n개 그룹으로 나눈 번호예요 |

## 이 단원에서 쓰는 데이터

이 단원의 예제는 모두 사원 테이블 `EMP`를 써요. 아래는 이 단원에 필요한 컬럼만 뽑은 거예요.

| EMPNO (사번) | ENAME (이름) | HIREDATE (입사일) | SAL (급여) | DEPTNO (부서) |
| -- | -- | -- | -- | -- |
| 1001 | 김대표 | 2015-01-01 | 9000 | 10 |
| 1002 | 이개발 | 2016-03-01 | 6000 | 10 |
| 1003 | 박영업 | 2016-05-01 | 6000 | 20 |
| 1004 | 최코드 | 2018-07-01 | 4000 | 10 |
| 1005 | 정코드 | 2019-02-01 | 4000 | 10 |
| 1006 | 한세일 | 2019-06-01 | 3500 | 20 |
| 1007 | 윤세일 | 2020-01-01 | 3000 | 20 |
| 1008 | 강신입 | 2021-09-01 | 3000 | 10 |
| 1009 | 조미정 | 2022-04-01 | 2800 | NULL |
| 1010 | 서인턴 | 2023-01-02 | NULL | 10 |

이 단원에서 결과를 헷갈리게 만드는 사람들이에요. 미리 봐 두면 예제를 따라가기 쉬워요.

- **서인턴**은 급여(SAL)가 NULL이에요. Oracle은 정렬할 때 NULL을 **가장 큰 값**으로 다뤄요. 그래서 급여가 높은 순(DESC)으로 줄을 세우면 서인턴이 맨 앞에 와요. 순위 결과가 크게 달라지니 꼭 기억해 두세요.
- **이개발과 박영업**(6000), **최코드와 정코드**(4000), **윤세일과 강신입**(3000)은 급여가 같아요. 동점을 어떻게 처리하는지가 이 단원의 핵심이에요.
- **조미정**은 부서(DEPTNO)가 NULL이에요. 그래서 부서 10이나 20으로 거른 예제에는 나오지 않아요.

## 설명

윈도우 함수는 행을 줄이지 않고, **각 행 옆에 계산 결과를 붙여 주는 함수**예요. GROUP BY는 그룹마다 한 행으로 줄이지만, 윈도우 함수는 원래 행 수가 그대로 남아요. 함수 뒤에 `OVER (...)`를 붙여서 쓰고, 괄호 안에는 아래 세 가지를 쓸 수 있어요.

| 쓰는 것 | 하는 일 |
| -- | -- |
| PARTITION BY | 행을 그룹으로 나눠요. 계산은 그룹 안에서만 해요 |
| ORDER BY | 그룹 안에서 행의 순서를 정해요 |
| ROWS / RANGE | 계산에 넣을 행의 범위(프레임)를 정해요 |

### 1. 순위 함수

순위 함수는 ORDER BY 기준으로 순위를 매겨요. 세 함수는 **동점일 때만** 결과가 달라져요.

| 함수 | 순위 매기는 방법 | 동점 다음 순위 |
| -- | -- | -- |
| RANK | 나보다 앞선 사람 수 + 1 | 건너뛰어요 (1, 2, 2, 4) |
| DENSE_RANK | 나보다 앞선 서로 다른 값의 수 + 1 | 건너뛰지 않아요 (1, 2, 2, 3) |
| ROW_NUMBER | 그냥 줄 번호 | 동점도 서로 다른 번호예요 (1, 2, 3, 4) |

ROW_NUMBER는 동점끼리 누가 먼저 번호를 받을지 정해져 있지 않아요. 그래서 아래 예제는 ORDER BY에 EMPNO를 하나 더 넣어서 순서를 고정했어요.

먼저 급여가 NULL인 서인턴을 빼고 순위를 매겨 볼게요.

```sql
SELECT ENAME, SAL,
       RANK()       OVER (ORDER BY SAL DESC) AS RK,
       DENSE_RANK() OVER (ORDER BY SAL DESC) AS DRK,
       ROW_NUMBER() OVER (ORDER BY SAL DESC, EMPNO) AS RN
FROM EMP
WHERE SAL IS NOT NULL
ORDER BY SAL DESC, EMPNO;
```

| ENAME | SAL | RK | DRK | RN |
| -- | -- | -- | -- | -- |
| 김대표 | 9000 | 1 | 1 | 1 |
| 이개발 | 6000 | 2 | 2 | 2 |
| 박영업 | 6000 | 2 | 2 | 3 |
| 최코드 | 4000 | 4 | 3 | 4 |
| 정코드 | 4000 | 4 | 3 | 5 |
| 한세일 | 3500 | 6 | 4 | 6 |
| 윤세일 | 3000 | 7 | 5 | 7 |
| 강신입 | 3000 | 7 | 5 | 8 |
| 조미정 | 2800 | 9 | 6 | 9 |

하나씩 따라가 볼게요.

1. **이개발, 박영업(6000):** 앞선 사람은 김대표 1명이라 RANK는 둘 다 2예요.
2. **최코드, 정코드(4000):** 앞선 사람이 김대표, 이개발, 박영업 3명이라 RANK는 4예요. 3위가 없어졌어요. 이것이 "동점 다음 순위를 건너뛴다"는 뜻이에요.
3. **같은 4000의 DENSE_RANK:** 앞선 서로 다른 값은 9000, 6000 두 개라 3이에요. 건너뛰지 않아요.
4. **ROW_NUMBER:** 동점과 상관없이 1부터 9까지 한 번씩 붙어요. 이개발과 박영업은 사번이 빠른 이개발이 2, 박영업이 3이에요.

**NULL이 섞이면 순위가 어떻게 될까요?**

이번에는 서인턴을 빼지 않고, 사원 10명 전체로 순위를 매겨 볼게요. 시험에 자주 나오는 함정이에요.

```sql
SELECT ENAME, SAL,
       RANK()       OVER (ORDER BY SAL DESC) AS RK,
       DENSE_RANK() OVER (ORDER BY SAL DESC) AS DRK
FROM EMP
ORDER BY SAL DESC, EMPNO;
```

| ENAME | SAL | RK | DRK |
| -- | -- | -- | -- |
| 서인턴 | NULL | 1 | 1 |
| 김대표 | 9000 | 2 | 2 |
| 이개발 | 6000 | 3 | 3 |
| 박영업 | 6000 | 3 | 3 |
| 최코드 | 4000 | 5 | 4 |
| 정코드 | 4000 | 5 | 4 |
| 한세일 | 3500 | 7 | 5 |
| 윤세일 | 3000 | 8 | 6 |
| 강신입 | 3000 | 8 | 6 |
| 조미정 | 2800 | 10 | 7 |

하나씩 따라가 볼게요.

1. Oracle은 NULL을 가장 큰 값으로 다뤄요. 그래서 높은 순(DESC)으로 세우면 급여가 없는 **서인턴이 1위**가 돼요.
2. 그 바람에 모든 사람이 한 칸씩 밀려요. 김대표는 2위, 이개발과 박영업은 3위예요.
3. 한세일은 앞선 사람이 6명이라 RANK 7이에요. 앞선 서로 다른 값은 NULL, 9000, 6000, 4000 네 개라 DENSE_RANK는 5예요. 서인턴을 뺐던 위 표와 비교하면 RANK 6, DENSE_RANK 4에서 하나씩 늘었어요.

서인턴을 맨 뒤로 보내고 싶으면 ORDER BY에 `NULLS LAST`를 붙여요. `NULLS LAST`는 "NULL을 맨 뒤에 둔다"는 뜻이에요.

```sql
SELECT ENAME, SAL,
       RANK() OVER (ORDER BY SAL DESC NULLS LAST) AS RK
FROM EMP;
```

이렇게 쓰면 김대표가 다시 1위가 되고, 한세일은 RANK 6으로 돌아와요. 서인턴은 10위로 맨 뒤에 가요.

정리하면 Oracle에서 NULL의 위치는 아래와 같아요.

| 정렬 | NULL의 위치 | 바꾸는 방법 |
| -- | -- | -- |
| ASC (낮은 순) | 맨 뒤 | `NULLS FIRST` |
| DESC (높은 순) | 맨 앞 | `NULLS LAST` |

SQL Server는 반대로 NULL을 가장 작은 값으로 다뤄요. 문제에 "Oracle 기준"이라고 나오면 NULL이 DESC에서 맨 앞이라는 점을 먼저 떠올리세요.

**PARTITION BY로 그룹마다 따로 매기기**

PARTITION BY를 붙이면 부서마다 순위를 따로 매겨요. 이때도 행은 줄지 않아요. 20번 부서로 확인해 볼게요.

```sql
SELECT ENAME, DEPTNO, SAL,
       RANK() OVER (PARTITION BY DEPTNO
                    ORDER BY SAL DESC) AS DEPT_RK,
       SUM(SAL) OVER (PARTITION BY DEPTNO) AS DEPT_SUM
FROM EMP
WHERE DEPTNO = 20
ORDER BY SAL DESC;
```

| ENAME | DEPTNO | SAL | DEPT_RK | DEPT_SUM |
| -- | -- | -- | -- | -- |
| 박영업 | 20 | 6000 | 1 | 12500 |
| 한세일 | 20 | 3500 | 2 | 12500 |
| 윤세일 | 20 | 3000 | 3 | 12500 |

1. 박영업은 전체에서는 이개발과 공동 2위였지만, 20번 부서 안에서는 가장 높아서 1위예요.
2. DEPT_SUM은 20번 부서 급여를 모두 더한 값(6000 + 3500 + 3000 = 12500)이에요. GROUP BY와 달리 3명의 행이 그대로 남고, 각 행에 같은 합계가 붙어요.

### 2. 집계 윈도우 함수와 프레임

SUM, AVG, COUNT, MAX, MIN 같은 집계 함수도 OVER를 붙이면 윈도우 함수가 돼요. 이때는 **프레임** 안의 행만 계산해요. 프레임은 "현재 행을 계산할 때 함께 넣을 행의 범위"를 말해요.

프레임은 OVER 안에 무엇을 썼는지에 따라 정해져요.

| OVER 안에 쓴 것 | 프레임 |
| -- | -- |
| 아무것도 없음 `OVER ()` | 파티션 전체 |
| ORDER BY만 | 처음부터 현재 값까지 (RANGE 누적) |
| ORDER BY + ROWS | 직접 정한 행 범위 |

ORDER BY만 쓰면 Oracle은 `RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW`를 쓴 것으로 봐요. "처음부터 현재 행까지"라는 뜻이에요.

여기서 RANGE와 ROWS의 차이가 중요해요.

- **RANGE**는 값을 기준으로 범위를 잡아요. ORDER BY 값이 같은 행(동점)을 한 묶음으로 보고 함께 넣어요.
- **ROWS**는 실제 행을 한 줄씩 세서 범위를 잡아요. 동점이어도 아직 오지 않은 행은 넣지 않아요.

범위를 쓸 때는 아래 표현을 조합해요.

| 표현 | 뜻 |
| -- | -- |
| UNBOUNDED PRECEDING | 맨 처음 행 |
| n PRECEDING | n행 앞 |
| CURRENT ROW | 현재 행 |
| n FOLLOWING | n행 뒤 |
| UNBOUNDED FOLLOWING | 맨 마지막 행 |

세 가지 방식을 한 번에 비교해 볼게요.

```sql
SELECT ENAME, SAL,
       SUM(SAL) OVER (ORDER BY SAL) AS RANGE_SUM,
       SUM(SAL) OVER (
         ORDER BY SAL, EMPNO
         ROWS BETWEEN UNBOUNDED PRECEDING
                  AND CURRENT ROW
       ) AS ROWS_SUM,
       SUM(SAL) OVER () AS ALL_SUM
FROM EMP
WHERE SAL IS NOT NULL
ORDER BY SAL, EMPNO;
```

| ENAME | SAL | RANGE_SUM | ROWS_SUM | ALL_SUM |
| -- | -- | -- | -- | -- |
| 조미정 | 2800 | 2800 | 2800 | 41300 |
| 윤세일 | 3000 | 8800 | 5800 | 41300 |
| 강신입 | 3000 | 8800 | 8800 | 41300 |
| 한세일 | 3500 | 12300 | 12300 | 41300 |
| 최코드 | 4000 | 20300 | 16300 | 41300 |
| 정코드 | 4000 | 20300 | 20300 | 41300 |
| 이개발 | 6000 | 32300 | 26300 | 41300 |
| 박영업 | 6000 | 32300 | 32300 | 41300 |
| 김대표 | 9000 | 41300 | 41300 | 41300 |

하나씩 따라가 볼게요.

1. **윤세일의 RANGE_SUM:** RANGE는 "3000 이하인 값 전부"를 더해요. 조미정 2800, 윤세일 3000, 강신입 3000이 들어가서 8800이에요. 강신입은 아직 다음 줄인데도 같은 값이라 함께 들어가요. 강신입의 RANGE_SUM도 똑같이 8800이에요.
2. **윤세일의 ROWS_SUM:** ROWS는 "지금 줄까지"만 더해요. 조미정 2800 + 윤세일 3000 = 5800이에요. 다음 줄인 강신입에서 3000이 더해져 8800이 돼요.
3. **동점 묶음의 마지막 행**(강신입, 정코드, 박영업)에서는 RANGE_SUM과 ROWS_SUM이 같아져요.
4. **ALL_SUM:** OVER 안이 비어 있어서 모든 행이 같은 프레임이에요. 9명 급여를 모두 더한 41300이 모든 행에 붙어요.

ROWS로 한 줄씩 셀 때 동점끼리의 순서는 정해져 있지 않아요. 그래서 ROWS_SUM에는 ORDER BY에 EMPNO를 더 넣어서 순서를 고정했어요.

**앞뒤 몇 행만 계산하기**

`ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING`처럼 쓰면 "앞 1행, 현재 행, 뒤 1행"까지 최대 3행을 계산해요. 20번 부서로 확인해 볼게요.

```sql
SELECT ENAME, SAL,
       SUM(SAL) OVER (
         ORDER BY SAL, EMPNO
         ROWS BETWEEN 1 PRECEDING
                  AND 1 FOLLOWING
       ) AS MOV_SUM,
       COUNT(SAL) OVER (
         ORDER BY SAL, EMPNO
         ROWS BETWEEN 1 PRECEDING
                  AND 1 FOLLOWING
       ) AS MOV_CNT
FROM EMP
WHERE DEPTNO = 20
ORDER BY SAL, EMPNO;
```

| ENAME | SAL | MOV_SUM | MOV_CNT |
| -- | -- | -- | -- |
| 윤세일 | 3000 | 6500 | 2 |
| 한세일 | 3500 | 12500 | 3 |
| 박영업 | 6000 | 9500 | 2 |

1. **윤세일:** 첫 행이라 앞 행이 없어요. 윤세일 3000 + 한세일 3500 = 6500이고, 2행만 계산했어요.
2. **한세일:** 앞뒤가 다 있어서 3000 + 3500 + 6000 = 12500, 3행이에요.
3. **박영업:** 마지막 행이라 뒤 행이 없어요. 3500 + 6000 = 9500, 2행이에요.

### 3. 행 순서 함수

행 순서 함수는 ORDER BY로 정한 순서에서 **다른 행의 값을 가져오는** 함수예요.

| 함수 | 가져오는 값 |
| -- | -- |
| `LAG(컬럼, n, 기본값)` | n행 앞의 값 (n을 생략하면 1) |
| `LEAD(컬럼, n, 기본값)` | n행 뒤의 값 (n을 생략하면 1) |
| `FIRST_VALUE(컬럼)` | 프레임의 첫 번째 값 |
| `LAST_VALUE(컬럼)` | 프레임의 마지막 값 |

LAG와 LEAD의 기본값은 **가리킬 행이 아예 없을 때** 대신 보여 줄 값이에요. 생략하면 NULL이 나와요.

**LAG와 LEAD**

10번 부서를 입사일 순으로 세우고, 바로 앞 사람과 바로 뒤 사람의 급여를 가져와 볼게요.

```sql
SELECT ENAME, HIREDATE, SAL,
       LAG(SAL) OVER (ORDER BY HIREDATE) AS PREV_SAL,
       LEAD(SAL, 1, 0)
         OVER (ORDER BY HIREDATE) AS NEXT_SAL
FROM EMP
WHERE DEPTNO = 10
ORDER BY HIREDATE;
```

| ENAME | HIREDATE | SAL | PREV_SAL | NEXT_SAL |
| -- | -- | -- | -- | -- |
| 김대표 | 2015-01-01 | 9000 | NULL | 6000 |
| 이개발 | 2016-03-01 | 6000 | 9000 | 4000 |
| 최코드 | 2018-07-01 | 4000 | 6000 | 4000 |
| 정코드 | 2019-02-01 | 4000 | 4000 | 3000 |
| 강신입 | 2021-09-01 | 3000 | 4000 | NULL |
| 서인턴 | 2023-01-02 | NULL | 3000 | 0 |

하나씩 따라가 볼게요.

1. **김대표의 PREV_SAL:** 가장 먼저 입사해서 앞 행이 없어요. LAG에 기본값을 주지 않았으니 NULL이에요.
2. **강신입의 NEXT_SAL:** 다음 행(서인턴)은 있어요. 그런데 서인턴의 급여가 NULL이라 그대로 NULL을 가져와요. 기본값 0은 쓰이지 않아요.
3. **서인턴의 NEXT_SAL:** 가장 늦게 입사해서 다음 행이 아예 없어요. 이때 기본값 0이 나와요.

2번과 3번의 차이가 시험에 자주 나와요. **기본값은 값이 NULL일 때가 아니라, 가리킬 행이 없을 때만** 쓰여요.

**FIRST_VALUE와 LAST_VALUE**

같은 순서로 첫 번째 사람과 마지막 사람의 이름을 가져와 볼게요. LAST_VALUE는 기본 프레임으로 한 번, 프레임을 넓혀서 한 번 써 봤어요.

```sql
SELECT ENAME, HIREDATE,
       FIRST_VALUE(ENAME)
         OVER (ORDER BY HIREDATE) AS FIRST_NM,
       LAST_VALUE(ENAME)
         OVER (ORDER BY HIREDATE) AS LAST_DEF,
       LAST_VALUE(ENAME) OVER (
         ORDER BY HIREDATE
         ROWS BETWEEN UNBOUNDED PRECEDING
                  AND UNBOUNDED FOLLOWING
       ) AS LAST_ALL
FROM EMP
WHERE DEPTNO = 10
ORDER BY HIREDATE;
```

| ENAME | HIREDATE | FIRST_NM | LAST_DEF | LAST_ALL |
| -- | -- | -- | -- | -- |
| 김대표 | 2015-01-01 | 김대표 | 김대표 | 서인턴 |
| 이개발 | 2016-03-01 | 김대표 | 이개발 | 서인턴 |
| 최코드 | 2018-07-01 | 김대표 | 최코드 | 서인턴 |
| 정코드 | 2019-02-01 | 김대표 | 정코드 | 서인턴 |
| 강신입 | 2021-09-01 | 김대표 | 강신입 | 서인턴 |
| 서인턴 | 2023-01-02 | 김대표 | 서인턴 | 서인턴 |

하나씩 따라가 볼게요.

1. **FIRST_NM:** 기본 프레임은 "처음부터 현재 행까지"예요. 첫 번째 값은 언제나 김대표라서 모든 행이 김대표예요.
2. **LAST_DEF:** 같은 기본 프레임에서 마지막 값은 **현재 행 자신**이에요. 그래서 이개발 행에는 이개발, 최코드 행에는 최코드가 나와요. 부서의 마지막 입사자를 기대했다면 틀린 결과예요.
3. **LAST_ALL:** 프레임을 `UNBOUNDED FOLLOWING`(맨 마지막 행)까지 넓혔어요. 이제 프레임의 끝이 서인턴이라 모든 행에 서인턴이 나와요.

LAST_VALUE로 파티션 전체의 마지막 값을 구하려면 **프레임을 UNBOUNDED FOLLOWING까지 넓혀야** 해요.

### 4. 비율 함수

비율 함수는 각 행이 전체에서 어느 정도 위치나 비중인지 계산해요.

| 함수 | 계산 | 특징 |
| -- | -- | -- |
| RATIO_TO_REPORT(컬럼) | 컬럼 값 ÷ 파티션의 합계 | OVER 안에 ORDER BY를 쓰지 않아요. 모두 더하면 1이에요 |
| PERCENT_RANK() | (RANK − 1) ÷ (행 수 − 1) | 첫 행은 0, 마지막 행은 1이에요 |
| CUME_DIST() | 현재 값 이하인 행 수 ÷ 행 수 | 동점은 묶음의 마지막 행 기준이에요. 마지막 행은 1이에요 |
| NTILE(n) | 행을 n개 그룹으로 나눈 번호 | 나누어떨어지지 않으면 앞 그룹부터 1행씩 더 받아요 |

결과표가 넓어지지 않도록 쿼리를 둘로 나눴어요. 먼저 RATIO_TO_REPORT와 PERCENT_RANK예요.

```sql
SELECT ENAME, SAL,
       ROUND(RATIO_TO_REPORT(SAL) OVER (), 3) AS RATIO,
       ROUND(PERCENT_RANK()
               OVER (ORDER BY SAL), 3) AS PR
FROM EMP
WHERE SAL IS NOT NULL
ORDER BY SAL, EMPNO;
```

| ENAME | SAL | RATIO | PR |
| -- | -- | -- | -- |
| 조미정 | 2800 | 0.068 | 0 |
| 윤세일 | 3000 | 0.073 | 0.125 |
| 강신입 | 3000 | 0.073 | 0.125 |
| 한세일 | 3500 | 0.085 | 0.375 |
| 최코드 | 4000 | 0.097 | 0.5 |
| 정코드 | 4000 | 0.097 | 0.5 |
| 이개발 | 6000 | 0.145 | 0.75 |
| 박영업 | 6000 | 0.145 | 0.75 |
| 김대표 | 9000 | 0.218 | 1 |

하나씩 따라가 볼게요.

1. **RATIO:** 9명의 급여 합계는 41300이에요. 김대표는 9000 ÷ 41300 = 0.218이에요.
2. **PR:** 행 수가 9라서 분모는 9 − 1 = 8이에요. 조미정은 낮은 순 RANK 1이라 (1 − 1) ÷ 8 = 0이에요.
3. 윤세일과 강신입은 동점이라 RANK가 둘 다 2예요. (2 − 1) ÷ 8 = 0.125예요.
4. 한세일은 앞에 3명이 있어서 RANK 4예요. (4 − 1) ÷ 8 = 0.375예요. 김대표는 RANK 9라서 (9 − 1) ÷ 8 = 1이에요.

이어서 CUME_DIST와 NTILE이에요.

```sql
SELECT ENAME, SAL,
       ROUND(CUME_DIST()
               OVER (ORDER BY SAL), 3) AS CD,
       NTILE(4) OVER (ORDER BY SAL, EMPNO) AS NT
FROM EMP
WHERE SAL IS NOT NULL
ORDER BY SAL, EMPNO;
```

| ENAME | SAL | CD | NT |
| -- | -- | -- | -- |
| 조미정 | 2800 | 0.111 | 1 |
| 윤세일 | 3000 | 0.333 | 1 |
| 강신입 | 3000 | 0.333 | 1 |
| 한세일 | 3500 | 0.444 | 2 |
| 최코드 | 4000 | 0.667 | 2 |
| 정코드 | 4000 | 0.667 | 3 |
| 이개발 | 6000 | 0.889 | 3 |
| 박영업 | 6000 | 0.889 | 4 |
| 김대표 | 9000 | 1 | 4 |

하나씩 따라가 볼게요.

1. **CD:** 조미정은 2800 이하가 자기 1명뿐이라 1 ÷ 9 = 0.111이에요.
2. 윤세일은 3000 이하가 조미정, 윤세일, 강신입 3명이라 3 ÷ 9 = 0.333이에요. 아직 다음 줄인 강신입까지 세는 이유는 "현재 값 이하"가 기준이기 때문이에요. 그래서 동점인 강신입도 같은 0.333이에요.
3. 김대표는 9000 이하가 9명 전부라 9 ÷ 9 = 1이에요.
4. **NT:** 9행을 4개 그룹으로 나누면 9 ÷ 4 = 2, 나머지 1이에요. 남는 1행은 첫 그룹이 받아서 그룹 크기는 3, 2, 2, 2가 돼요. 조미정, 윤세일, 강신입이 1그룹, 한세일과 최코드가 2그룹이에요.
5. 최코드와 정코드는 같은 4000인데 2그룹과 3그룹으로 갈라졌어요. NTILE은 **동점을 신경 쓰지 않고** 행 수만으로 나눠요.

## 자주 하는 오해

| 오해 | 실제 |
| -- | -- |
| 윈도우 함수도 GROUP BY처럼 행이 줄어든다 | 원래 행 수 그대로예요. 20번 부서 3명에 DEPT_SUM 12500이 각각 붙어요 |
| 급여 높은 순(DESC) 순위에서 NULL은 꼴찌다 | Oracle은 NULL을 가장 큰 값으로 봐서 DESC면 1위예요. 10번 부서에서 서인턴이 1위, 김대표가 2위가 돼요. 맨 뒤로 보내려면 `NULLS LAST`를 써요. SQL Server는 반대예요 |
| RANK와 DENSE_RANK는 동점 다음 순위가 같다 | RANK는 건너뛰고 DENSE_RANK는 건너뛰지 않아요. 4000인 최코드는 RANK 4, DENSE_RANK 3이에요 |
| ORDER BY만 쓴 SUM OVER는 한 줄씩 누적한다 | 기본 프레임은 RANGE라 동점 행이 같은 누적값을 받아요. 윤세일과 강신입이 둘 다 8800이에요. 한 줄씩 누적하려면 ROWS를 직접 써야 해요 |
| LAST_VALUE는 파티션의 마지막 값을 준다 | 기본 프레임이 현재 행까지라 현재 행 값이 나와요. 마지막 값을 받으려면 UNBOUNDED FOLLOWING까지 넓혀야 해요 |
| LEAD(SAL, 1, 0)은 다음 값이 NULL이면 0을 준다 | 기본값은 가리킬 행이 없을 때만 써요. 강신입의 다음 행인 서인턴은 급여가 NULL이라 NULL이 나와요 |
| NTILE은 동점을 같은 그룹에 넣는다 | 행 수만으로 나눠요. 4000인 최코드와 정코드가 2그룹과 3그룹으로 갈라져요 |
');
