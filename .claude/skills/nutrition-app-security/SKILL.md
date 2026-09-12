---
name: nutrition-app-security
description: Security rules for this nutrition app — secrets, Firebase Auth/Firestore/Storage rules, OpenAI backend proxying, subscription/premium trust boundaries, AI output validation. Use whenever touching authentication, Firestore/Storage access, Cloud Functions, OpenAI/AI integration, subscriptions, or any secret/config value.
---

# Nutrition App — Security Rules

Derived from `Instrucciones.md` (sections 19-38, 69-70, 75, 80). This is a checklist to apply, not a summary to skim — re-read the source sections for a security-sensitive task.

## Absolute rules — never violate

- Never put an OpenAI API key, Firebase Admin credentials, or any backend secret inside the Flutter app (Dart constants, assets, build config, committed `.env`). The Flutter client is assumed fully inspectable/manipulable.
- OpenAI is only ever called from a secure backend (Firebase Cloud Function): `Flutter → Firebase Auth token → Cloud Function → validation → OpenAI → structured/safety validation → Flutter`. Never call OpenAI directly from Flutter.
- Never trust client-supplied `userId`, `isPremium`/subscription status, role, or AI usage-count values. All authorization and quota enforcement happens server-side (Cloud Functions + Firestore rules), the client only *displays* what the server says.
- Never store raw passwords — use Firebase Authentication.
- Never log secrets, tokens, or unnecessary personal/medical data.

## Firestore & Storage

- Design ownership explicitly, e.g. `users/{userId}/...` subcollections. Rules must check `request.auth.uid == userId` (or equivalent) on every read/write/update/delete — a user must never reach another user's data by changing a document ID.
- Validate allowed fields and types in rules where practical; don't allow arbitrary client-written fields (especially anything premium/limit/role-related).
- Images (food photos): validate type/size before upload, compress client-side for UX but don't rely on that for security, use Storage rules scoped per user, avoid exposing public URLs unnecessarily.

## AI safety — treat all AI output as untrusted input

- Request structured (JSON-schema-like) output from the model when the app needs structured data; never blindly deserialize free-form text into app models.
- Validate schema, required fields, types, and value ranges server-side before returning AI output to the client.
- On validation failure: don't show invalid content, attempt safe recovery if reasonable, log non-sensitive diagnostics, return a safe fallback.
- Deterministic safety rules (allergies, restrictions, medical flags) sit between the user profile and the AI request/response — don't rely solely on the LLM to enforce safety constraints.
- Never let the app present AI nutrition estimates as medically precise, and never let it diagnose, recommend medication changes, or tell a user to stop prescribed medication.

## Cost / abuse control

- Every AI-calling Cloud Function enforces server-side rate limits and daily/monthly usage quotas (free vs. premium tiers). The client may display remaining usage but never enforces it.
- Minimize what's sent to OpenAI per request — only the fields relevant to that specific task (e.g. goal, restrictions, available ingredients), not the entire user profile or full conversation history.

## Subscriptions

- Subscription state is validated via the official Apple/Google billing verification flow server-side, written to Firestore by a trusted backend process — never set directly by the client.

## Before shipping a security-sensitive change

Mentally check: secrets, Firebase rules, App Check, auth, authorization, Firestore/Storage access, Cloud Functions input validation, OpenAI key isolation, rate limiting, subscription trust boundary, logging hygiene. Flag anything unresolved instead of assuming it's fine.
