const MAX_NAME_LENGTH = 80;

/**
 * Acota una lista de nombres que llega del cliente (ingredientes escritos a
 * mano, recetas a excluir): solo strings, sin espacios sobrantes, sin vacíos
 * ni duplicados (sin distinguir mayúsculas), cada uno de hasta
 * [MAX_NAME_LENGTH] caracteres y como mucho [max] elementos. Lo que no es
 * una lista devuelve `[]` — nunca se confía en la forma del payload
 * (Instrucciones.md §70).
 */
export function sanitizeNameList(raw: unknown, max: number): string[] {
  if (!Array.isArray(raw)) return [];
  const seen = new Set<string>();
  const out: string[] = [];
  for (const value of raw) {
    if (typeof value !== "string") continue;
    const name = value.replace(/\s+/g, " ").trim().slice(0, MAX_NAME_LENGTH);
    const key = name.toLowerCase();
    if (name.length === 0 || seen.has(key)) continue;
    seen.add(key);
    out.push(name);
    if (out.length === max) break;
  }
  return out;
}
