// Everything an app needs to integrate LivenessDetector, in one file to copy from:
//   1. run the check,
//   2. the backend calls around it (session -> challenge -> check -> face-match),
//   3. user-facing messages for each failure reason.
// The UI in App.tsx only calls these.
import {
  start,
  type Challenge,
  type LivenessAction,
  type LivenessOptions,
  type LivenessReason,
  type LivenessResult,
} from '@airookies/react-native-liveness-detector';

// ---- 1. Run the check ----------------------------------------------------------------

/**
 * Shows the SDK's full-screen check. Resolves for every outcome (passed, failed,
 * cancelled, error); rejects only if the screen can't be shown at all.
 */
export const runLiveness = (options: LivenessOptions): Promise<LivenessResult> => start(options);

/** Quick start: no backend, the SDK picks the colours and one head turn. */
export const quickStartOptions = (): LivenessOptions => ({ challenge: { id: `demo-${Date.now()}` } });

/** An evidence file's exact bytes as base64 (RN's fetch reads file:// URIs on both platforms). */
export async function readBase64(uri: string): Promise<string> {
  const blob = await (await fetch(uri)).blob();
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result).replace(/^data:.*?;base64,/, ''));
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(blob);
  });
}

// ---- 2. Backend calls ------------------------------------------------------------------
// In production, your own backend should hold the API key and make these calls; the app
// only receives the challenge and sends the evidence. The example calls Face Match
// directly so it runs without a backend of your own.

type Json = Record<string, any>;

/** What your session endpoint returns: identifies this verification on Face Match. */
export interface FaceMatchSession {
  request_id: string;
  row_id: number;
  session_token: string;
}

/** A response's HTTP status and its (unwrapped) JSON body. */
export interface ApiResponse {
  status: number;
  body: Json;
  retryAfter: string | null;
}

const ACTIONS: Record<string, LivenessAction> = {
  turnleft: 'turn_left',
  turnright: 'turn_right',
  blink: 'blink',
  mouthopen: 'mouth_open',
  smile: 'smile',
};

export class FaceMatchApi {
  private base: string;

  constructor(baseUrl: string, private apiKey: string) {
    this.base = baseUrl.trim().replace(/\/api\/client\/.*$|\/+$/, '');
    this.apiKey = apiKey.trim();
  }

  /** Your backend creates the session; here it is any URL that returns the three fields. */
  async createSession(sessionUrl: string): Promise<FaceMatchSession> {
    const { body } = await this.post(sessionUrl.trim(), {}, false);
    if (!body.request_id || body.row_id == null || !body.session_token) {
      throw new Error('session response is missing request_id, row_id or session_token');
    }
    return body as FaceMatchSession;
  }

  /** POST /api/client/challenge. Single-use and valid for 90 s: fetch one per attempt. */
  async challenge(s: FaceMatchSession, colorCount = 4): Promise<[ApiResponse, Challenge | null]> {
    const r = await this.post(`${this.base}/api/client/challenge`, { ...s, sequence_length: colorCount });
    if (r.body.code !== 0) return [r, null];
    const actions = Array.isArray(r.body.actions)
      ? r.body.actions.map((a: string) => ACTIONS[a.replace(/_/g, '').toLowerCase()]).filter(Boolean)
      : undefined; // undefined: the SDK picks a turn
    return [r, { id: r.body.challenge_id, colors: r.body.colors, actions, colorCount }];
  }

  /** POST /api/client/face-match with the evidence of a passed check and the ID photo (base64 JPEG). */
  async faceMatch(s: FaceMatchSession, result: LivenessResult, idPhotoBase64: string): Promise<ApiResponse> {
    if (result.status !== 'passed' || !result.selfie || !result.archive) {
      throw new Error('only a passed check has evidence');
    }
    return this.post(`${this.base}/api/client/face-match`, {
      request_id: s.request_id,
      row_id: s.row_id,
      challenge_id: result.challengeId,
      integrity: result.integrity,
      data: {
        image1: {
          base64: await readBase64(result.selfie.uri),
          border: false,
          liveness_check: true,
          sequence: await readBase64(result.archive.uri),
        },
        image2: { base64: idPhotoBase64, border: true, liveness_check: false, sequence: '' },
      },
    });
  }

  private async post(url: string, body: Json, withKey = true): Promise<ApiResponse> {
    const res = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...(withKey && this.apiKey ? { 'X-API-KEY': this.apiKey } : {}) },
      body: JSON.stringify(body),
    });
    const text = await res.text();
    let json: Json;
    try {
      json = JSON.parse(text);
    } catch {
      json = { message: text.slice(0, 200) };
    }
    // Face Match wraps responses as data.response, response, or neither.
    return { status: res.status, body: json?.data?.response ?? json?.response ?? json, retryAfter: res.headers.get('Retry-After') };
  }
}

// ---- 3. Messages -----------------------------------------------------------------------

/** Suggested text for each reason (docs/integration/README.md): [English, Mongolian]. */
const MESSAGES: Record<LivenessReason, [string, string]> = {
  none: ['Passed', 'Амжилттай'],
  step_timeout: ['Time ran out. Try again and follow the prompts.', 'Хугацаа дууслаа. Зааврыг дагаад дахин оролдоно уу.'],
  session_timeout: ['Time ran out. Try again and follow the prompts.', 'Хугацаа дууслаа. Зааврыг дагаад дахин оролдоно уу.'],
  face_lost: ['Keep your face in the oval.', 'Нүүрээ зууван хүрээнд байлгана уу.'],
  multiple_faces: ['Only one person, please.', 'Зөвхөн нэг хүн байх ёстой.'],
  flash_failed: ['Hold still during the flash.', 'Гэрэл анивчих үед хөдлөхгүй байна уу.'],
  cancelled: ['Cancelled.', 'Цуцлагдлаа.'],
  camera_permission_denied: ['Allow camera access in Settings.', 'Тохиргооноос камерын зөвшөөрөл олгоно уу.'],
  camera_unavailable: ["The camera couldn't start. Try again later.", 'Камер ажиллахгүй байна. Дараа дахин оролдоно уу.'],
  integrity_failed: ["The check can't run on this device.", 'Энэ төхөөрөмж дээр шалгалт ажиллахгүй.'],
  unsupported_device: ['Use a real device.', 'Бодит утас ашиглана уу.'],
  internal_error: ['Something went wrong. Try again.', 'Алдаа гарлаа. Дахин оролдоно уу.'],
};

export function reasonMessage(reason: LivenessReason, locale = Intl.DateTimeFormat().resolvedOptions().locale): string {
  return MESSAGES[reason][locale.startsWith('mn') ? 1 : 0];
}
