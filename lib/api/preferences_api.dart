import 'dart:convert';

import '../api/api_client.dart';
import '../models/preferences.dart'; // <-- adjust if your Preferences class is in a different file

class PreferencesApi {
  final ApiClient _client;
  PreferencesApi(this._client);

  Map<String, dynamic> _decode(dynamic resp) {
    final body = (resp as dynamic).body as String?;
    if (body == null || body.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(body);
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{'data': decoded};
  }

  /// GET /api/v1/preferences
  Future<Preferences> get() async {
    final resp = await _client.get('/api/v1/preferences');
    final json = _decode(resp);

    final prefJson = (json['preferences'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return Preferences.fromJson(prefJson);
  }

  /// PUT /api/v1/preferences
  /// Only sends the fields provided (so we don't accidentally overwrite chefId or other fields).
  Future<Preferences> update({
    String? chefId,
    String? dietStyle,
    List<String>? allergies,
    List<String>? cuisines,
    int? maxCookTimeMinutes,
    String? spiceLevel,
    int? servingsDefault,
    String? units,
  }) async {
    final body = <String, dynamic>{
      if (chefId != null) 'chefId': chefId,
      if (dietStyle != null) 'dietStyle': dietStyle,
      if (allergies != null) 'allergies': allergies,
      if (cuisines != null) 'cuisines': cuisines,
      if (maxCookTimeMinutes != null) 'maxCookTimeMinutes': maxCookTimeMinutes,
      if (spiceLevel != null) 'spiceLevel': spiceLevel,
      if (servingsDefault != null) 'servingsDefault': servingsDefault,
      if (units != null) 'units': units,
    };

    final resp = await _client.put('/api/v1/preferences', body: body);
    final json = _decode(resp);

    final prefJson = (json['preferences'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return Preferences.fromJson(prefJson);
  }
}