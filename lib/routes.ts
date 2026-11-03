export const HOME_PATH = "/";
export const START_PATH = "/start";
export const STUDY_PATH = "/study";
export const MOBILE_NOTICE_PATH = "/mobile";
export const CLEAR_SESSION_PATH = "/api/session/clear";

export function isStudyPath(pathname: string): boolean {
  return pathname === STUDY_PATH || pathname.startsWith(`${STUDY_PATH}/`);
}
