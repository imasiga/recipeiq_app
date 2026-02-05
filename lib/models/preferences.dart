class Preferences {
  final String? chefId; // ✅ added
  final String dietStyle;
  final List<String> allergies;
  final List<String> cuisines;
  final int maxCookTimeMinutes;
  final String spiceLevel; // mild | medium | hot
  final int servingsDefault;
  final String units; // imperial | metric

  Preferences({
    required this.chefId, // ✅ added
    required this.dietStyle,
    required this.allergies,
    required this.cuisines,
    required this.maxCookTimeMinutes,
    required this.spiceLevel,
    required this.servingsDefault,
    required this.units,
  });

  factory Preferences.fromJson(Map<String, dynamic> json) {
    return Preferences(
      chefId: (json['chefId'] as String?)?.trim().isEmpty == true
          ? null
          : json['chefId'] as String?, // ✅ added
      dietStyle: (json['dietStyle'] ?? 'any').toString(),
      allergies: (json['allergies'] as List? ?? []).map((e) => e.toString()).toList(),
      cuisines: (json['cuisines'] as List? ?? []).map((e) => e.toString()).toList(),
      maxCookTimeMinutes: _toInt(json['maxCookTimeMinutes'], fallback: 30),
      spiceLevel: (json['spiceLevel'] ?? 'medium').toString(),
      servingsDefault: _toInt(json['servingsDefault'], fallback: 2),
      units: (json['units'] ?? 'metric').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'chefId': chefId, // ✅ added
        'dietStyle': dietStyle,
        'allergies': allergies,
        'cuisines': cuisines,
        'maxCookTimeMinutes': maxCookTimeMinutes,
        'spiceLevel': spiceLevel,
        'servingsDefault': servingsDefault,
        'units': units,
      };

  static int _toInt(dynamic v, {required int fallback}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }
}