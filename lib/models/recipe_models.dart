class Ingredient {
  final String name;
  final num quantity;
  final String unit;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        name: (json['name'] ?? '').toString(),
        quantity: (json['quantity'] is num) ? (json['quantity'] as num) : 0,
        unit: (json['unit'] ?? '').toString(),
      );
}

class Nutrition {
  final num calories;
  final num proteinG;
  final num carbsG;
  final num fatG;

  Nutrition({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory Nutrition.fromJson(Map<String, dynamic> json) => Nutrition(
        calories: (json['calories'] is num) ? (json['calories'] as num) : 0,
        proteinG: (json['protein_g'] is num) ? (json['protein_g'] as num) : 0,
        carbsG: (json['carbs_g'] is num) ? (json['carbs_g'] as num) : 0,
        fatG: (json['fat_g'] is num) ? (json['fat_g'] as num) : 0,
      );
}

/// ✅ LIST ITEM MODEL (GET /recipes)
class RecipeSummary {
  final String id;
  final String title;
  final String? cuisine;
  final String dietStyle;
  final int cookTimeMinutes;
  final int servings;
  final String? imageUrl;
  final DateTime? createdAt;

  RecipeSummary({
    required this.id,
    required this.title,
    required this.cuisine,
    required this.dietStyle,
    required this.cookTimeMinutes,
    required this.servings,
    required this.imageUrl,
    required this.createdAt,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) => RecipeSummary(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        cuisine: json['cuisine']?.toString(),
        dietStyle: (json['dietStyle'] ?? '').toString(),
        cookTimeMinutes: _toInt(json['cookTimeMinutes']),
        servings: _toInt(json['servings']),
        imageUrl: json['imageUrl']?.toString(),
        createdAt: _toDate(json['createdAt']),
      );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}

/// ✅ FULL RECIPE MODEL (GET /recipes/{id} and POST /recipes/generate)
class Recipe {
  final String id; // ✅ included so you can call getById(recipe.id) if needed
  final String title;
  final String? cuisine;
  final String dietStyle;
  final int cookTimeMinutes;
  final int servings;
  final List<Ingredient> ingredients;
  final List<String> steps;
  final Nutrition? nutrition;
  final String? imageUrl;

  Recipe({
    required this.id,
    required this.title,
    required this.cuisine,
    required this.dietStyle,
    required this.cookTimeMinutes,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    required this.imageUrl,
  });

  factory Recipe.fromJson(Map<String, dynamic> json, {required String id}) {
    return Recipe(
      id: id,
      title: (json['title'] ?? '').toString(),
      cuisine: json['cuisine']?.toString(),
      dietStyle: (json['dietStyle'] ?? 'any').toString(),
      cookTimeMinutes: RecipeSummary._toInt(json['cookTimeMinutes']),
      servings: RecipeSummary._toInt(json['servings']),
      ingredients: (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => Ingredient.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      steps: (json['steps'] as List<dynamic>? ?? []).map((e) => '$e').toList(),
      nutrition: json['nutrition'] == null
          ? null
          : Nutrition.fromJson(Map<String, dynamic>.from(json['nutrition'] as Map)),
      imageUrl: json['imageUrl']?.toString(),
    );
  }
}