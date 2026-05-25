import 'api_client.dart';

class SubscriptionApi {
  SubscriptionApi(this._apiClient);

  final ApiClient _apiClient;

  Future<bool> getIsPro() async {
    final response = await _apiClient.get('/api/v1/subscription');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to load subscription status ${response.statusCode}: ${response.body}',
      );
    }

    final json = _apiClient.decodeJsonObject(response);
    return json['is_pro'] == true;
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
