import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../api/api_client.dart';
import '../api/subscription_api.dart';
import '../app/app_state.dart';
import '../config/api_config.dart' as appcfg;

class PaymentScreen extends StatefulWidget {
  final String planName;
  final String price;
  final String period;
  final String productId;

  const PaymentScreen({
    super.key,
    required this.planName,
    required this.price,
    required this.period,
    required this.productId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const _bg = Color.fromRGBO(7, 10, 16, 1);
  static const _accent = Color.fromRGBO(255, 210, 21, 1);

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final ApiClient _apiClient = ApiClient(baseUrl: appcfg.ApiConfig.baseUrl());
  late final SubscriptionApi _subscriptionApi = SubscriptionApi(_apiClient);
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  ProductDetails? _productDetails;
  bool _isLoading = true;
  bool _storeAvailable = false;
  bool _isPurchasing = false;
  bool _purchaseSucceeded = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();

    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _isPurchasing = false;
          _statusMessage = 'Payment failed. Please try again.';
        });
      },
    );

    _loadProduct();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    final available = await _inAppPurchase.isAvailable();

    if (!available) {
      if (!mounted) return;
      setState(() {
        _storeAvailable = false;
        _isLoading = false;
        _statusMessage = 'Payments are not available on this device.';
      });
      return;
    }

    final response = await _inAppPurchase.queryProductDetails({
      widget.productId,
    });

    if (!mounted) return;

    if (response.error != null) {
      setState(() {
        _storeAvailable = true;
        _isLoading = false;
        _statusMessage = response.error!.message;
      });
      return;
    }

    if (response.productDetails.isEmpty) {
      setState(() {
        _storeAvailable = true;
        _isLoading = false;
        _statusMessage =
            'This subscription is not available yet. Please check the App Store product setup.';
      });
      return;
    }

    setState(() {
      _storeAvailable = true;
      _isLoading = false;
      _productDetails = response.productDetails.first;
      _statusMessage = null;
    });
  }

  Future<void> _buySubscription() async {
    final product = _productDetails;

    if (product == null || !_storeAvailable || _isPurchasing) {
      return;
    }

    setState(() {
      _isPurchasing = true;
      _statusMessage = 'Opening secure App Store payment...';
    });

    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPurchasing = false;
        _statusMessage = 'Unable to start payment. Please try again.';
      });
    }
  }

  Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.productID != widget.productId) {
        continue;
      }

      if (purchase.status == PurchaseStatus.pending) {
        if (!mounted) return;
        setState(() {
          _isPurchasing = true;
          _statusMessage = 'Payment is pending...';
        });
      } else if (purchase.status == PurchaseStatus.error) {
        if (!mounted) return;
        setState(() {
          _isPurchasing = false;
          _statusMessage =
              purchase.error?.message ?? 'Payment failed. Please try again.';
        });
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Verifying your subscription...';
        });

        final transactionId =
            purchase.purchaseID ??
            purchase.verificationData.localVerificationData;

        bool verified = false;

        try {
          verified = await _subscriptionApi.syncApplePurchase(
            productId: purchase.productID,
            transactionId: transactionId,
            verificationData: purchase.verificationData.serverVerificationData,
          );
        } catch (_) {
          verified = false;
        }

        if (verified) {
          await AppState.setIsPro(true);
        }

        if (!mounted) return;
        setState(() {
          _isPurchasing = false;
          _purchaseSucceeded = verified;
          _statusMessage = verified
              ? 'Payment successful. Your subscription is active.'
              : 'Payment completed, but server verification is not available yet.';
        });

        if (purchase.pendingCompletePurchase) {
          unawaited(_inAppPurchase.completePurchase(purchase));
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (!mounted) return;
        setState(() {
          _isPurchasing = false;
          _statusMessage = 'Payment was cancelled.';
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _statusMessage = 'Checking for previous purchases...';
    });

    await _inAppPurchase.restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    final displayedPrice = _productDetails?.price ?? widget.price;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/logo_full.png',
                width: 130,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 26),
              const Text(
                'Complete your payment',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'You selected the ${widget.planName} plan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: _accent.withValues(alpha: 0.75),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.planName,
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$displayedPrice ${widget.period}',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isLoading
                          ? 'Loading secure payment...'
                          : 'Secure payment powered by the App Store.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_statusMessage != null)
                Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: _isPurchasing ? null : _restorePurchases,
                child: const Text(
                  'Restore purchase',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: const Color.fromRGBO(20, 20, 20, 1),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: _purchaseSucceeded
                    ? () => Navigator.of(context).pop(true)
                    : _isLoading || !_storeAvailable || _isPurchasing
                    ? null
                    : _buySubscription,
                child: _isPurchasing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(
                        _purchaseSucceeded ? 'Continue' : 'Pay now',
                        style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
