import { after, before, beforeEach, test } from "node:test";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from "firebase/firestore";

// Tests de `firestore.rules` contra el emulador — se corren con
// `npm run test:rules` (levanta el emulador vía `firebase emulators:exec`).
// No tocan el proyecto real: usan un projectId de demo.

let env: RulesTestEnvironment;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-nutrition-app",
    firestore: { rules: readFileSync(resolve(__dirname, "../../../../firestore.rules"), "utf8") },
  });
});

after(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

const alice = () => env.authenticatedContext("alice").firestore();
const bob = () => env.authenticatedContext("bob").firestore();
const anon = () => env.unauthenticatedContext().firestore();

async function seed(path: string, data: Record<string, unknown>) {
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), path), data);
  });
}

test("users: el dueño crea su documento solo con campos permitidos", async () => {
  await assertSucceeds(setDoc(doc(alice(), "users/alice"), { onboarding: { goal: "loseFat" } }));
});

test("users: nadie puede escribirse premium al crear su documento", async () => {
  await assertFails(setDoc(doc(alice(), "users/alice"), { subscription: { isPremium: true } }));
});

test("users: nadie puede escribirse premium al actualizar (ni con merge)", async () => {
  await seed("users/alice", { onboarding: {}, subscription: { isPremium: false } });
  await assertFails(updateDoc(doc(alice(), "users/alice"), { "subscription.isPremium": true }));
  await assertFails(setDoc(doc(alice(), "users/alice"), { subscription: { isPremium: true } }, { merge: true }));
});

test("users: actualizar un campo permitido funciona aunque exista subscription", async () => {
  await seed("users/alice", { onboarding: {}, subscription: { isPremium: false } });
  await assertSucceeds(updateDoc(doc(alice(), "users/alice"), { notificationPreferences: { enabled: true } }));
});

test("users: nadie lee ni escribe el documento de otro, ni sin sesión", async () => {
  await seed("users/alice", { onboarding: {} });
  await assertFails(getDoc(doc(bob(), "users/alice")));
  await assertFails(setDoc(doc(bob(), "users/alice"), { onboarding: {} }));
  await assertFails(getDoc(doc(anon(), "users/alice")));
});

test("users: el cliente no puede borrar su propio documento", async () => {
  await seed("users/alice", { onboarding: {} });
  await assertFails(deleteDoc(doc(alice(), "users/alice")));
});

test("aiUsage: el contador de cuota es invisible para el cliente", async () => {
  await seed("users/alice/aiUsage/2026-10-19", { count: 1 });
  await assertFails(getDoc(doc(alice(), "users/alice/aiUsage/2026-10-19")));
  await assertFails(setDoc(doc(alice(), "users/alice/aiUsage/2026-10-19"), { count: 0 }));
});

for (const collection of ["nutritionPlans", "recipes"]) {
  test(`${collection}: el dueño lee, pero nadie escribe contenido de la IA`, async () => {
    await seed(`users/alice/${collection}/x`, { name: "algo" });
    await assertSucceeds(getDoc(doc(alice(), `users/alice/${collection}/x`)));
    await assertFails(getDoc(doc(bob(), `users/alice/${collection}/x`)));
    await assertFails(setDoc(doc(alice(), `users/alice/${collection}/x`), { name: "editado" }));
  });
}

test("shoppingLists: solo checkedItems, y como lista", async () => {
  await assertSucceeds(setDoc(doc(alice(), "users/alice/shoppingLists/2026-W43"), { checkedItems: ["pollo"] }));
  await assertFails(setDoc(doc(alice(), "users/alice/shoppingLists/2026-W43"), { checkedItems: "pollo" }));
  await assertFails(setDoc(doc(alice(), "users/alice/shoppingLists/2026-W43"), { checkedItems: [], extra: 1 }));
  await assertFails(setDoc(doc(bob(), "users/alice/shoppingLists/2026-W43"), { checkedItems: [] }));
});
