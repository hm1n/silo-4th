// 한국 시간 새벽 4시를 하루의 시작으로 본다. 한국은 서머타임이 없어 UTC에 9시간을 더하고 4시간을 뺀 날짜가 학습일이다.
const STUDY_DAY_OFFSET_MS = (9 - 4) * 60 * 60 * 1000;

export function studyDay(at: Date): string {
  return new Date(at.getTime() + STUDY_DAY_OFFSET_MS).toISOString().slice(0, 10);
}
