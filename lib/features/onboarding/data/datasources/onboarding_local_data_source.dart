import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/onboarding_answers.dart';

/// Única clase del proyecto que importa `shared_preferences`. Guarda el
/// borrador de Onboarding como un blob JSON bajo una sola clave — no hay
/// necesidad de un esquema relacional para un objeto que vive poco tiempo
/// (entre "Empezar" y crear la cuenta).
class OnboardingLocalDataSource {
  static const _draftKey = 'onboarding_draft_v1';

  Future<void> saveDraft(OnboardingAnswers answers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(answers.toJson()));
  }

  Future<OnboardingAnswers?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return null;
    return OnboardingAnswers.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }
}
