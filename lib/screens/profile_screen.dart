import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_screen.dart';
import 'preferences_screen.dart';
import '../app/app_language.dart';
import '../app/app_state.dart';
import 'language_screen.dart';
import '../api/account_api.dart';
import '../api/api_client.dart';
import '../config/api_config.dart' as appcfg;
import '../app/app_appearance.dart';
import 'appearance_screen.dart';
import '../l10n/app_localizations.dart';
import 'paywall_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _btnBg = Color.fromRGBO(70, 78, 89, 1);
  static const _btnText = Color.fromRGBO(255, 210, 21, 1);

  bool _busy = false;
  String? _error;

  final ApiClient _apiClient = ApiClient(baseUrl: appcfg.ApiConfig.baseUrl());
  late final AccountApi _accountApi = AccountApi(_apiClient);

  Future<void> _openSubscriptionManagement() async {
    final uri = Uri.parse('https://apps.apple.com/account/subscriptions');

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open subscription settings.')),
      );
    }
  }

  Future<AuthUser?> _getUser() async {
    try {
      return await Amplify.Auth.getCurrentUser();
    } on AuthException {
      return null;
    }
  }

  Future<String?> _getDisplayName() async {
    try {
      final attrs = await Amplify.Auth.fetchUserAttributes();

      String? find(AuthUserAttributeKey key) {
        for (final a in attrs) {
          if (a.userAttributeKey == key) return a.value.trim();
        }
        return null;
      }

      final name = find(AuthUserAttributeKey.name);
      if (name != null && name.isNotEmpty) return name;

      final email = find(AuthUserAttributeKey.email);
      if (email != null && email.isNotEmpty) return email;

      return null;
    } on AuthException {
      return null;
    }
  }

  Future<String?> _getProfilePhotoUrl() async {
    try {
      final resp = await _apiClient.get('/api/user');
      if (resp.statusCode < 200 || resp.statusCode >= 300) return null;

      final json = _apiClient.decodeJsonObject(resp);
      final raw = (json['profile_photo_url'] ?? '').toString().trim();
      if (raw.isEmpty) return null;

      return raw;
    } catch (_) {
      return null;
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _error = null;
    });

    await _apiClient.clearToken();

    try {
      await Amplify.Auth.signOut();
    } catch (_) {
      // Treat sign-out as successful even if the remote session is already invalid.
    }

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUploadProfilePhoto() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (file == null || !mounted) return;

      setState(() {
        _busy = true;
        _error = null;
      });

      await _accountApi.uploadProfilePhoto(file.path);

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          'Delete account?',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: _btnBg,
          ),
        ),
        content: const Text(
          'This will permanently delete your account and app data. This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            height: 1.45,
            color: _btnBg,
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _btnBg,
              side: BorderSide(color: _btnBg.withValues(alpha: 0.18)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _btnBg,
              foregroundColor: _btnText,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await _accountApi.deleteAccount();
      await _apiClient.clearToken();

      try {
        await Amplify.Auth.signOut();
      } catch (_) {
        // Account is already deleted or session is already invalid.
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          l10n.profileTitle,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w900,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait<dynamic>([
            _getUser(),
            _getDisplayName(),
            _getProfilePhotoUrl(),
            AppState.isPro(),
          ]),
          builder: (context, snap) {
            final user = snap.data?[0] as AuthUser?;
            final displayName = snap.data?[1] as String?;
            final profilePhotoUrl = snap.data?[2] as String?;
            final isPro = snap.data?[3] as bool? ?? false;
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (user == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 46,
                        color: scheme.onSurface.withValues(alpha: 0.60),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Not signed in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: _btnBg,
                            foregroundColor: _btnText,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _busy
                              ? null
                              : () {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const AuthScreen(),
                                    ),
                                    (_) => false,
                                  );
                                },
                          child: Text(l10n.goToLogin),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Material(
                  elevation: isDark ? 2 : 10,
                  color: isDark
                      ? const Color.fromRGBO(255, 255, 255, 0.06)
                      : Colors.white,
                  shadowColor: Colors.black.withValues(
                    alpha: isDark ? 0.22 : 0.10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 42,
                                backgroundColor: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : _btnBg.withValues(alpha: 0.08),
                                backgroundImage:
                                    (profilePhotoUrl != null &&
                                        profilePhotoUrl.trim().isNotEmpty)
                                    ? NetworkImage(profilePhotoUrl)
                                    : null,
                                child:
                                    (profilePhotoUrl == null ||
                                        profilePhotoUrl.trim().isEmpty)
                                    ? Icon(
                                        Icons.person_rounded,
                                        size: 42,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.82,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Material(
                                  color: _btnBg,
                                  borderRadius: BorderRadius.circular(999),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(999),
                                    onTap: _busy
                                        ? null
                                        : _pickAndUploadProfilePhoto,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                                        color: Color.fromRGBO(255, 210, 21, 1),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.signedInAs,
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          displayName ?? user.username,
                          style: const TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Material(
                  elevation: isDark ? 2 : 8,
                  color: scheme.surface,
                  shadowColor: Colors.black.withValues(
                    alpha: isDark ? 0.22 : 0.10,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: isPro
                        ? _openSubscriptionManagement
                        : () async {
                            final upgraded = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (_) => PaywallScreen(
                                      selectedGoals: const [],
                                      selectedDiets: const [],
                                      selectedSources: const [],
                                      age: 18,
                                    ),
                                  ),
                                );

                            if (upgraded == true && mounted) {
                              setState(() {});
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _btnText.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _btnText.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color.fromRGBO(255, 210, 21, 1),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPro ? 'Recipe iQ Pro Active' : l10n.goPro,
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: scheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPro
                                      ? 'Manage or cancel your subscription'
                                      : l10n.upgradeToRecipeIqPro,
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontWeight: FontWeight.w700,
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isPro)
                            Icon(
                              Icons.chevron_right_rounded,
                              color: scheme.onSurface.withValues(alpha: 0.72),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? scheme.onSurface : _btnBg,
                      side: BorderSide(
                        color: isDark
                            ? scheme.outline.withValues(alpha: 0.28)
                            : _btnBg.withValues(alpha: 0.18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PreferencesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(l10n.preferences),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? scheme.onSurface : _btnBg,
                      side: BorderSide(
                        color: isDark
                            ? scheme.outline.withValues(alpha: 0.28)
                            : _btnBg.withValues(alpha: 0.18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              LanguageScreen(appLanguage: AppLanguage.instance),
                        ),
                      );
                    },
                    icon: const Icon(Icons.language_rounded),
                    label: Text(l10n.language),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? scheme.onSurface : _btnBg,
                      side: BorderSide(
                        color: isDark
                            ? scheme.outline.withValues(alpha: 0.28)
                            : _btnBg.withValues(alpha: 0.18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppearanceScreen(
                            appAppearance: AppAppearance.instance,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.palette_outlined),
                    label: Text(l10n.appearance),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.red.shade300
                          : Colors.red.shade700,
                      side: BorderSide(
                        color: isDark
                            ? Colors.red.shade300.withValues(alpha: 0.38)
                            : Colors.red.withValues(alpha: 0.22),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: _busy ? null : _deleteAccount,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: Text(l10n.deleteAccountAndData),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _btnBg,
                      foregroundColor: _btnText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: _busy ? null : _signOut,
                    icon: const Icon(Icons.logout),
                    label: Text(_busy ? 'Signing out…' : l10n.signOut),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
