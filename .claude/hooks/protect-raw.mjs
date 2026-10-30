// _docs/raw/ 아래 이미 있는 파일을 Edit/Write로 고치려 하면 막는다. 새 원본 저장은 허용한다.
// 근거: _docs/CLAUDE.md "raw" 규칙, _docs/raw/2026-10-30-ai-harness-rules.md
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";

const input = JSON.parse(readFileSync(0, "utf8"));
const target = input.tool_input?.file_path ?? input.tool_input?.notebook_path;
if (!target) process.exit(0);

const root = process.env.CLAUDE_PROJECT_DIR ?? input.cwd;
const rawDir = path.resolve(root, "_docs", "raw");
const abs = path.resolve(input.cwd ?? root, target);
const rel = path.relative(rawDir.toLowerCase(), abs.toLowerCase());
const insideRaw = rel !== "" && !rel.startsWith("..") && !path.isAbsolute(rel);

if (insideRaw && existsSync(abs)) {
  console.error(
    `_docs/raw/${path.relative(rawDir, abs).replace(/\\/g, "/")}은 raw 원본이라 수정할 수 없다. ` +
      "수정 사항은 별도 메모로 남겨야 한다 (_docs/CLAUDE.md \"raw\").",
  );
  process.exit(2);
}
