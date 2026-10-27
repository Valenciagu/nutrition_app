import { test } from "node:test";
import assert from "node:assert/strict";
import {
  nameMatchesAvoidedFoods,
  parseDateKey,
  parseManualMacros,
  parseMealName,
  parsePortion,
} from "../src/mealLog/input";

const NOW = new Date("2026-10-26T15:00:00Z");

test("parseDateKey acepta hoy, hasta 2 días atrás y 1 adelante (husos horarios)", () => {
  for (const date of ["2026-10-24", "2026-10-25", "2026-10-26", "2026-10-27"]) {
    assert.equal(parseDateKey(date, NOW), date);
  }
});

test("parseDateKey rechaza formatos raros y días lejanos", () => {
  for (const date of ["2026-10-23", "2026-10-28", "26-10-2026", "2026-13-01", "", 20261026, undefined]) {
    assert.throws(() => parseDateKey(date, NOW));
  }
});

test("parseMealName recorta y colapsa espacios, exige 2-80 caracteres", () => {
  assert.equal(parseMealName("  Dos   arepas con queso "), "Dos arepas con queso");
  assert.throws(() => parseMealName("a"));
  assert.throws(() => parseMealName("x".repeat(81)));
  assert.throws(() => parseMealName(42));
});

test("parseManualMacros: kcal obligatoria, proteína 0 por defecto, carbos/grasas opcionales", () => {
  assert.deepEqual(parseManualMacros({ calories: 450.4 }), { calories: 450, proteinGrams: 0, carbsGrams: null, fatGrams: null });
  assert.deepEqual(parseManualMacros({ calories: 300, proteinGrams: 20, carbsGrams: 30, fatGrams: 10 }), {
    calories: 300,
    proteinGrams: 20,
    carbsGrams: 30,
    fatGrams: 10,
  });
  assert.throws(() => parseManualMacros({}));
  assert.throws(() => parseManualMacros({ calories: -5 }));
  assert.throws(() => parseManualMacros({ calories: 6000 }));
  assert.throws(() => parseManualMacros({ calories: "300" }));
  assert.throws(() => parseManualMacros({ calories: 300, proteinGrams: Number.NaN }));
});

test("parsePortion: 0,25-5 redondeado a cuartos", () => {
  assert.equal(parsePortion(1.5), 1.5);
  assert.equal(parsePortion(0.3), 0.25);
  assert.throws(() => parsePortion(0.1));
  assert.throws(() => parsePortion(6));
  assert.throws(() => parsePortion(undefined));
});

test("nameMatchesAvoidedFoods avisa por subcadena, sin importar mayúsculas", () => {
  assert.equal(nameMatchesAvoidedFoods("Arepa con QUESO", ["lactose"]), true);
  assert.equal(nameMatchesAvoidedFoods("Ensalada de atún", ["fish"]), true);
  assert.equal(nameMatchesAvoidedFoods("Ensalada de pollo", ["fish", "nuts"]), false);
  assert.equal(nameMatchesAvoidedFoods("Arepa con queso", []), false);
});
