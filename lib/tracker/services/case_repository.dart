import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/case_record.dart';

class CaseRepository {
  static const _casesKey = 'immigro_cases_v1';

  Future<List<ImmigrationCase>> loadCases() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_casesKey);
    if (encoded == null || encoded.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ImmigrationCase.fromJson)
        .toList();
  }

  Future<void> saveCases(List<ImmigrationCase> cases) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(cases.map((item) => item.toJson()).toList());
    await prefs.setString(_casesKey, encoded);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_casesKey);
  }
}
