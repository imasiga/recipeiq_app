import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'auth_screen.dart';
import 'payment_screen.dart';

class PaywallScreen extends StatefulWidget {
  final List<String> selectedGoals;
  final List<String> selectedDiets;
  final List<String> selectedSources;
  final int age;

  const PaywallScreen({
    super.key,
    required this.selectedGoals,
    required this.selectedDiets,
    required this.selectedSources,
    required this.age,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  static const _btnText = Color.fromRGBO(255, 210, 21, 1);

  String _selectedPlan = 'monthly';

  void _goToAuth(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  void _goToPayment(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isYearly = _selectedPlan == 'yearly';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          planName: isYearly
              ? l10n.paywallYearlyTitle
              : l10n.paywallMonthlyTitle,
          price: isYearly ? '\$89.99' : '\$7.99',
          period: isYearly ? '/ year' : '/ month',
        ),
      ),
    );
  }

  Widget _featureItem({required IconData icon, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _btnText.withValues(alpha: 0.80)),
            ),
            child: Icon(icon, color: _btnText, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planCard({
    required bool selected,
    required VoidCallback onTap,
    required String badge,
    required String title,
    required String subtitle,
    required String price,
    required String period,
    String? savings,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: selected ? 0.09 : 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? _btnText.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.10),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? _btnText
                        : Colors.white.withValues(alpha: 0.45),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _btnText,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badge.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _btnText,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: Color.fromRGBO(20, 20, 20, 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    period,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  if (savings != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      savings,
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: _btnText,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkItem(String text) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check,
            color: Color.fromRGBO(40, 220, 120, 1),
            size: 20,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.88),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(7, 10, 16, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(7, 10, 16, 1),
        surfaceTintColor: const Color.fromRGBO(7, 10, 16, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              left: -90,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _btnText.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              top: 80,
              right: -80,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _btnText.withValues(alpha: 0.08),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Image.asset(
                    'assets/images/logo_full.png',
                    width: 130,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.paywallProLabel,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: _btnText,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.paywallPremiumHeadline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      color: Colors.white,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.paywallPremiumSubheadline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _featureItem(
                        icon: Icons.all_inclusive,
                        label: l10n.paywallFeatureCredits,
                      ),
                      const SizedBox(width: 10),
                      _featureItem(
                        icon: Icons.calendar_month_rounded,
                        label: l10n.paywallFeatureMealPlans,
                      ),
                      const SizedBox(width: 10),
                      _featureItem(
                        icon: Icons.shopping_cart_outlined,
                        label: l10n.paywallFeatureGroceryLists,
                      ),
                      const SizedBox(width: 10),
                      _featureItem(
                        icon: Icons.bolt_rounded,
                        label: l10n.paywallFeatureSaveTime,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _planCard(
                    selected: _selectedPlan == 'monthly',
                    onTap: () {
                      setState(() {
                        _selectedPlan = 'monthly';
                      });
                    },
                    badge: l10n.paywallMostPopular,
                    title: l10n.paywallMonthlyTitle,
                    subtitle: l10n.paywallBilledMonthly,
                    price: '\$7.99',
                    period: '/ month',
                  ),
                  const SizedBox(height: 14),
                  _planCard(
                    selected: _selectedPlan == 'yearly',
                    onTap: () {
                      setState(() {
                        _selectedPlan = 'yearly';
                      });
                    },
                    badge: '',
                    title: l10n.paywallYearlyTitle,
                    subtitle: l10n.paywallBilledYearly,
                    price: '\$89.99',
                    period: '/ year',
                    savings: l10n.paywallBestValue,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _checkItem(l10n.paywallTrialBadge),
                      const SizedBox(width: 10),
                      _checkItem(l10n.paywallCancelAnytime),
                      const SizedBox(width: 10),
                      _checkItem(l10n.paywallSecurePrivate),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _btnText,
                        foregroundColor: const Color.fromRGBO(20, 20, 20, 1),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: () => _goToPayment(context),
                      child: Text(
                        l10n.paywallStartFreeTrial,
                        style: const TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.paywallThenMonthlyCancelAnytime,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  const SizedBox(height: 22),
                  TextButton(
                    onPressed: () => _goToAuth(context),
                    child: Text(
                      l10n.continueWithoutTrialSignIn,
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: scheme.onPrimary.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.paywallTermsAndPrivacy,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
