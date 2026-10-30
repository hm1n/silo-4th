// 코드가 바뀐 상태로 턴을 끝내려 하면 npm run check를 돌리고, 실패하면 끝내지 못하게 막는다.
// 근거: _docs/wiki/adr/0001-ai-coding-rule-enforcement.md
import { spawnSync } from "node:child_process";
import { readFileSync } from "node:fs";

const input = JSON.parse(readFileSync(0, "utf8"));
// 이미 한 번 막혀서 다시 멈추는 중이면 통과시켜 무한 루프를 막는다.
if (input.stop_hook_active) process.exit(0);

const root = process.env.CLAUDE_PROJECT_DIR ?? input.cwd;
const run = (cmd, args) =>
  spawnSync(cmd, args, { cwd: root, encoding: "utf8", shell: process.platform === "win32" });

// _docs만 바뀐 턴에는 검사하지 않는다.
const changed = run("git", ["status", "--porcelain", "--untracked-files=all"])
  .stdout.split("\n")
  .map((line) => line.slice(3).trim())
  .filter((file) => file && !file.startsWith("_docs/") && /\.(ts|tsx|mts|js|mjs|jsx|json)$/.test(file));
if (changed.length === 0) process.exit(0);

const result = run("npm", ["run", "check"]);
if (result.status !== 0) {
  const output = `${result.stdout}${result.stderr}`.split("\n").slice(-60).join("\n");
  console.error(`npm run check가 실패했다. 고친 뒤에 작업을 끝낸다.\n${output}`);
  process.exit(2);
}
