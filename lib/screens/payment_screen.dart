import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  final String planName;
  final String price;
  final String period;

  const PaymentScreen({
    super.key,
    required this.planName,
    required this.price,
    required this.period,
  });

  static const _bg = Color.fromRGBO(7, 10, 16, 1);
  static const _accent = Color.fromRGBO(255, 210, 21, 1);

  @override
  Widget build(BuildContext context) {
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
                'You selected the $planName plan.',
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
                      planName,
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$price $period',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Secure payment will be connected here.',
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
              const Spacer(),
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Payment gateway is ready to be connected.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Pay now',
                  style: TextStyle(
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
