import 'api_client.dart';

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.isPro,
    required this.aiCreditsRemaining,
    required this.aiCreditsUsed,
  });

  final bool isPro;
  final int aiCreditsRemaining;
  final int aiCreditsUsed;
}

class SubscriptionApi {
  SubscriptionApi(this._apiClient);

  final ApiClient _apiClient;

  Future<SubscriptionStatus> getStatus() async {
    final response = await _apiClient.get('/api/v1/subscription');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load subscription status ${response.statusCode}: ${response.body}',
      );
    }

    final json = _apiClient.decodeJsonObject(response);
    final credits = json['ai_credits'] is Map<String, dynamic>
        ? json['ai_credits'] as Map<String, dynamic>
        : <String, dynamic>{};

    return SubscriptionStatus(
      isPro: json['is_pro'] == true,
      aiCreditsRemaining: (credits['remaining'] as num?)?.toInt() ?? 0,
      aiCreditsUsed: (credits['used'] as num?)?.toInt() ?? 0,
    );
  }

  Future<bool> getIsPro() async {
    final status = await getStatus();
    return status.isPro;
  }

  Future<bool> syncApplePurchase({
    required String productId,
    required String transactionId,
    String? verificationData,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/subscription/apple/sync',
      body: {
        'product_id': productId,
        'transaction_id': transactionId,
        if (verificationData != null && verificationData.isNotEmpty)
          'verification_data': verificationData,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to sync subscription ${response.statusCode}: ${response.body}',
      );
    }

    final json = _apiClient.decodeJsonObject(response);
    return json['is_pro'] == true;
  }
}
