// Edit/Write 직후 수정한 파일만 린트한다. 실패하면 exit 2로 에러를 Claude에게 돌려준다.
// 근거: _docs/wiki/adr/0001-ai-coding-rule-enforcement.md
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";

const input = JSON.parse(readFileSync(0, "utf8"));
const target = input.tool_input?.file_path;
if (!target || !/\.(ts|tsx|mts|js|mjs|jsx)$/.test(target)) process.exit(0);

const root = process.env.CLAUDE_PROJECT_DIR ?? input.cwd;
const result = spawnSync("npx", ["--no-install", "eslint", "--max-warnings=0", target], {
  cwd: root,
  encoding: "utf8",
  shell: process.platform === "win32",
});

if (result.status !== 0) {
  console.error(`eslint가 실패했다. 아래 문제를 고친다.\n${result.stdout}${result.stderr}`);
  process.exit(2);
}
