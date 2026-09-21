/// YYYY-MM-DD — mismo formato que usa `functions/src/plan/generateDailyPlan.ts`
/// para el id del documento `users/{uid}/nutritionPlans/{date}` y
/// `functions/src/ai/quota.ts` para `aiUsage/{date}`. Un solo lugar para no
/// repetir el `padLeft` en cada sitio que arme una fecha para Firestore.
String dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
