import 'dart:convert';

import '../api/api_client.dart';
import '../models/recipe_models.dart';

class RecipesApi {
  final ApiClient _client;

  RecipesApi(this._client);

  Map<String, dynamic> _decodeJsonResponse(dynamic resp) {
    final body = (resp as dynamic).body as String?;
    if (body == null || body.isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;

    return <String, dynamic>{'data': decoded};
  }

  Future<Recipe> generate({
    required String query,
    int? maxCookTimeMinutes,
    int? servings,
    String? chefId, // ✅ add this
  }) async {
    final body = <String, dynamic>{
      'query': query,
      ...?((maxCookTimeMinutes != null)
          ? {'maxCookTimeMinutes': maxCookTimeMinutes}
          : null),
      ...?((servings != null) ? {'servings': servings} : null),
      ...?((chefId != null && chefId.trim().isNotEmpty)
          ? {'chefId': chefId.trim()}
          : null),
    };

    final resp = await _client.post('/api/v1/recipes/generate', body: body);
    final json = _decodeJsonResponse(resp);

    if (resp.statusCode == 402 && json['code'] == 'AI_CREDITS_EXHAUSTED') {
      throw AiCreditsExhaustedException(
        (json['message'] ?? 'You have used all your AI credits.').toString(),
      );
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Generate failed ${resp.statusCode}: ${resp.body}');
    }

    // Backend returns: { "recipeId": "...", "recipe": { ... } }
    final recipeId = (json['recipeId'] ?? '').toString();
    final recipeJson =
        (json['recipe'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    if (recipeId.isEmpty) {
      throw Exception('API returned missing recipeId: ${jsonEncode(json)}');
    }

    return Recipe.fromJson(recipeJson, id: recipeId);
  }

  Future<List<RecipeSummary>> list() async {
    final resp = await _client.get('/api/v1/recipes');
    final json = _decodeJsonResponse(resp);

    final items = (json['items'] as List? ?? []);
    return items
        .map((e) => RecipeSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Recipe> getById(String id) async {
    final resp = await _client.get('/api/v1/recipes/$id');
    final json = _decodeJsonResponse(resp);

    // Backend returns: { "id": "...", "recipe": { ... }, "createdAt": ... }
    final recipeId = (json['id'] ?? id).toString();
    final recipeJson =
        ((json['recipe'] as Map?)?.cast<String, dynamic>()) ??
              Map<String, dynamic>.from(json)
          ..remove('id')
          ..remove('createdAt');

    if (recipeId.isEmpty) {
      throw Exception('API returned missing id: ${jsonEncode(json)}');
    }

    return Recipe.fromJson(recipeJson, id: recipeId);
  }

  Future<void> delete(String id) async {
    final resp = await _client.delete('/api/v1/recipes/$id');

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('Delete failed ${resp.statusCode}: ${resp.body}');
    }
  }
}

class AiCreditsExhaustedException implements Exception {
  AiCreditsExhaustedException(this.message);

  final String message;

  @override
  String toString() => message;
}
