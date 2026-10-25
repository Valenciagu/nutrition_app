/// Compara dos versiones `x.y.z` numéricamente (no como texto: `1.10.0` es
/// mayor que `1.9.0`). Segmentos faltantes cuentan como 0 y cualquier sufijo
/// no numérico (`-beta`, `+3`) se ignora. Negativo si [a] < [b], 0 si son
/// iguales, positivo si [a] > [b].
int compareVersions(String a, String b) {
  List<int> parse(String version) => version
      .split(RegExp(r'[-+]'))
      .first
      .split('.')
      .map((part) => int.tryParse(part.trim()) ?? 0)
      .toList();

  final left = parse(a);
  final right = parse(b);
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l.compareTo(r);
  }
  return 0;
}
