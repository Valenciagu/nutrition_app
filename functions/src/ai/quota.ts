import { getFirestore, FieldValue, type Transaction } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/v2/https";

/**
 * Daily request limits per AI feature and tier (Instrucciones.md §28: usage
 * must be server-side enforced; the client may only display what's left).
 * No numeric limit is specified in the product spec — these are reasonable
 * MVP placeholders, centralized here so no call site needs to change if they
 * move. `isPremium` today is always false for every user (Epic 13 —
 * Subscriptions — doesn't exist yet, so nothing writes that flag); this is
 * still wired through now so Epic 13 only has to start writing a trusted
 * flag, not redesign quota enforcement.
 */
const DAILY_LIMITS: Record<string, { free: number; premium: number }> = {
  nutritionQa: { free: 10, premium: 50 },
};

export interface QuotaCheckResult {
  remainingToday: number;
}

/**
 * Atomically checks and consumes one unit of today's AI quota for `feature`.
 * Throws `resource-exhausted` (Instrucciones.md §28-29) if the user already
 * hit today's limit for that feature.
 *
 * Storage: `users/{uid}/aiUsage/{yyyy-mm-dd}`, one flat integer field per
 * feature (e.g. `nutritionQa`). Deliberately NOT a nested `counts` map —
 * Firestore's `set(..., {merge:true})` does not reliably deep-merge nested
 * map fields across SDK versions, so a flat top-level field per feature is
 * used instead; that merge behavior IS well-defined. This doc is written
 * ONLY by Cloud Functions — Firestore rules must never grant the client
 * write access to `aiUsage` (it's the server-trusted usage counter,
 * Instrucciones.md §70).
 */
export async function consumeAiQuota(userId: string, isPremium: boolean, feature: string): Promise<QuotaCheckResult> {
  const limit = DAILY_LIMITS[feature];
  if (!limit) {
    throw new Error(`consumeAiQuota: no configured daily limit for feature "${feature}"`);
  }
  const dailyLimit = isPremium ? limit.premium : limit.free;

  const db = getFirestore();
  const docRef = db.collection("users").doc(userId).collection("aiUsage").doc(todayKey());

  return db.runTransaction(async (tx: Transaction) => {
    const snap = await tx.get(docRef);
    const currentCount = (snap.data()?.[feature] as number | undefined) ?? 0;

    if (currentCount >= dailyLimit) {
      throw new HttpsError(
        "resource-exhausted",
        "Alcanzaste tu límite diario de consultas de IA. Vuelve a intentarlo mañana.",
      );
    }

    tx.set(docRef, { [feature]: currentCount + 1, updatedAt: FieldValue.serverTimestamp() }, { merge: true });

    return { remainingToday: dailyLimit - (currentCount + 1) };
  });
}

/**
 * Best-effort refund when the OpenAI call fails after quota was already
 * consumed, so a failed request doesn't cost the user part of their daily
 * limit. Not transactional with the original consume — a lost race here just
 * means a user occasionally keeps one fewer request than they should, never
 * more, so it fails safe. Never let a refund error surface to the caller.
 */
export async function refundAiQuota(userId: string, feature: string): Promise<void> {
  const db = getFirestore();
  const docRef = db.collection("users").doc(userId).collection("aiUsage").doc(todayKey());
  try {
    await db.runTransaction(async (tx: Transaction) => {
      const snap = await tx.get(docRef);
      const currentCount = (snap.data()?.[feature] as number | undefined) ?? 0;
      if (currentCount > 0) {
        tx.set(docRef, { [feature]: currentCount - 1 }, { merge: true });
      }
    });
  } catch {
    // Best-effort only.
  }
}

function todayKey(): string {
  return new Date().toISOString().slice(0, 10); // YYYY-MM-DD (UTC)
}
