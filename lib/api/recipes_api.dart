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
  }) async {
    final body = <String, dynamic>{
      'query': query,
      if (maxCookTimeMinutes != null) 'maxCookTimeMinutes': maxCookTimeMinutes,
      if (servings != null) 'servings': servings,
    };

    final resp = await _client.post('/api/v1/recipes/generate', body: body);
    final json = _decodeJsonResponse(resp);

    // Backend returns: { "recipeId": "...", "recipe": { ... } }
    final recipeId = (json['recipeId'] ?? '').toString();
    final recipeJson =
        (json['recipe'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

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
        (json['recipe'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    if (recipeId.isEmpty) {
      throw Exception('API returned missing id: ${jsonEncode(json)}');
    }

    return Recipe.fromJson(recipeJson, id: recipeId);
  }
}