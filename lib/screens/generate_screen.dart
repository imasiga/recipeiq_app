import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/favorites_api.dart';
import '../api/preferences_api.dart';
import '../api/recipes_api.dart';
import '../api/subscription_api.dart';
import '../config/api_config.dart';
import '../models/chef_catalog.dart';
import '../models/recipe_models.dart';
import '../utils/image_url.dart';
import 'preferences_screen.dart';
import 'chef_select_screen.dart';
import '../l10n/app_localizations.dart';
import 'paywall_screen.dart';
import 'recipes_list_screen.dart';

class GenerateScreen extends StatefulWidget {
  final String? initialChefId;

  const GenerateScreen({super.key, this.initialChefId});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  final String _baseUrl = ApiConfig.baseUrl();

  late final ApiClient _apiClient = ApiClient(baseUrl: _baseUrl);
  late final RecipesApi _recipesApi = RecipesApi(_apiClient);
  late final SubscriptionApi _subscriptionApi = SubscriptionApi(_apiClient);

  final queryController = TextEditingController();

  int? _aiCreditsRemaining;
  bool _isPro = false;

  bool busy = false;
  Recipe? recipe;
  String? error;

  int _imageRefreshAttempts = 0;
  static const int _maxImageRefreshAttempts = 4;

  String? _chefId;

  // ⭐ Favorites (API)
  late final FavoritesApi _favoritesApi = FavoritesApi(_apiClient);
  bool _favBusy = false;
  bool _isFavorite = false;

  // If the user saved before imageUrl was ready, we’ll upsert later.
  bool _favNeedsImageUpdate = false;
  List<String> _loadingMessages(AppLocalizations l10n) => [
    l10n.loadingMessageWarmingUpChef,
    l10n.loadingMessageBalancingFlavors,
    l10n.loadingMessageMixingIngredients,
    l10n.loadingMessagePlatingSomethingSpecial,
    l10n.loadingMessageFinishingTouches,
  ];

  int _loadingMessageIndex = 0;
  Timer? _loadingMessageTimer;
  double _loadingProgress = 0.0;
  Timer? _loadingProgressTimer;
  AppLocalizations get l10n => AppLocalizations.of(context)!;
  @override
  void initState() {
    super.initState();
    _chefId = widget.initialChefId;
    unawaited(_loadSubscriptionStatus());
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final status = await _subscriptionApi.getStatus();
      if (!mounted) return;

      setState(() {
        _isPro = status.isPro;
        _aiCreditsRemaining = status.aiCreditsRemaining;
      });
    } catch (_) {
      // Ignore for now. The generate endpoint will still enforce credits.
    }
  }

  Future<void> _openPaywallForCredits() async {
    final upgraded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(
          selectedGoals: const [],
          selectedDiets: const [],
          selectedSources: const [],
          age: 18,
        ),
      ),
    );

    if (upgraded == true) {
      unawaited(_loadSubscriptionStatus());
    }
  }

  void _startLoadingMessages() {
    _loadingMessageTimer?.cancel();
    _loadingMessageIndex = 0;

    _loadingMessageTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !busy) return;
      setState(() {
        _loadingMessageIndex =
            (_loadingMessageIndex + 1) %
            _loadingMessages(AppLocalizations.of(context)!).length;
      });
    });
    _loadingProgressTimer?.cancel();
    _loadingProgress = 0.0;

    _loadingProgressTimer = Timer.periodic(const Duration(milliseconds: 120), (
      _,
    ) {
      if (!mounted || !busy) return;

      setState(() {
        if (_loadingProgress < 0.82) {
          _loadingProgress += 0.015;
        } else if (_loadingProgress < 0.94) {
          _loadingProgress += 0.003;
        }
        if (_loadingProgress > 0.94) {
          _loadingProgress = 0.94;
        }
      });
    });
  }

  void _stopLoadingMessages() {
    _loadingProgressTimer?.cancel();
    _loadingProgressTimer = null;
    _loadingProgress = 1.0;
    _loadingMessageTimer?.cancel();
    _loadingMessageTimer = null;
    _loadingMessageIndex = 0;
  }

  Future<void> _refreshFavoriteStatusForRecipe(String recipeId) async {
    try {
      await _apiClient.ensureAnonymousToken();
      final exists = await _favoritesApi.exists(recipeId);
      if (!mounted) return;
      setState(() => _isFavorite = exists);
    } catch (_) {
      // ignore (offline/unavailable)
    }
  }

  Future<void> _upsertFavorite(Recipe r) async {
    final item = FavoriteItem(
      recipeId: r.id,
      title: r.title,
      imageUrl: (r.imageUrl ?? '').trim(),
      cookTimeMinutes: r.cookTimeMinutes,
      servings: r.servings,
      chefId: (_chefId ?? '').trim(),
    );

    await _apiClient.ensureAnonymousToken();
    await _favoritesApi.store(item);
  }

  Future<void> _maybeUpdateFavoriteImage(Recipe latest) async {
    if (!_isFavorite) return;
    if (!_favNeedsImageUpdate) return;

    final img = (latest.imageUrl ?? '').trim();
    if (img.isEmpty) return;

    try {
      await _upsertFavorite(latest);
      if (!mounted) return;
      setState(() => _favNeedsImageUpdate = false);
    } catch (_) {
      // ignore; we'll try again on next refresh tick if needed
    }
  }

  Future<void> _toggleFavorite() async {
    final r = recipe;
    if (r == null) return;
    if (_favBusy) return;

    setState(() => _favBusy = true);

    try {
      await _apiClient.ensureAnonymousToken();

      if (_isFavorite) {
        await _favoritesApi.destroy(r.id);
        if (!mounted) return;
        setState(() {
          _isFavorite = false;
          _favNeedsImageUpdate = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.removedFromFavorites)));
      } else {
        await _upsertFavorite(r);

        if (!mounted) return;
        setState(() {
          _isFavorite = true;
          _favNeedsImageUpdate = (r.imageUrl ?? '').trim().isEmpty;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.savedToFavorites)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.favoriteFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _favBusy = false);
    }
  }

  void _scheduleImageRefreshIfNeeded() {
    final r = recipe;
    if (r == null) return;

    final hasMissing = (r.imageUrl ?? '').trim().isEmpty;
    if (!hasMissing) return;

    if (_imageRefreshAttempts >= _maxImageRefreshAttempts) return;
    _imageRefreshAttempts++;

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      if (busy) return;

      try {
        final latest = await _recipesApi.getById(r.id);
        if (!mounted) return;

        setState(() => recipe = latest);

        await _maybeUpdateFavoriteImage(latest);
      } catch (_) {
        // ignore
      }
    });
  }

  Future<void> _pickChefFromGenerate() async {
    final selectedChefId = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChefSelectScreen(returnSelection: true, initialChefId: _chefId),
      ),
    );

    if (!mounted || selectedChefId == null) return;

    setState(() => _chefId = selectedChefId);

    try {
      final prefsApi = PreferencesApi(_apiClient);
      await prefsApi.update(chefId: selectedChefId, cuisines: const []);
    } catch (_) {
      // ignore
    }
  }

  Future<void> generate() async {
    final q = queryController.text.trim();
    if (q.isEmpty) {
      setState(() => error = l10n.enterSomethingToCook);
      return;
    }
    if ((_chefId ?? '').trim().isEmpty) {
      setState(() => error = l10n.selectChefFirst);
      return;
    }
    setState(() {
      busy = true;
      _startLoadingMessages();
      error = null;
      recipe = null;
      _isFavorite = false;
      _favNeedsImageUpdate = false;
      _imageRefreshAttempts = 0;
    });

    try {
      await _apiClient.ensureAnonymousToken();

      final r = await _recipesApi.generate(
        query: q,
        maxCookTimeMinutes: null,
        servings: null,
        chefId: _chefId,
      );

      if (!mounted) return;
      setState(() => recipe = r);
      unawaited(_loadSubscriptionStatus());

      await _refreshFavoriteStatusForRecipe(r.id);

      _scheduleImageRefreshIfNeeded();
    } on AiCreditsExhaustedException catch (e) {
      if (!mounted) return;
      setState(() => error = e.message);
      await _openPaywallForCredits();
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      _stopLoadingMessages();
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    _loadingMessageTimer?.cancel();
    _loadingProgressTimer?.cancel();
    queryController.dispose();
    super.dispose();
  }

  Widget _imageBlock(String? url) {
    const h = 220.0;
    const radius = 16.0;

    final raw = (url ?? '').trim();
    final hasImage = raw.isNotEmpty;

    return Material(
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: h,
        width: double.infinity,
        child: hasImage
            ? _buildRecipeImage(raw, h)
            : Container(
                height: h,
                width: double.infinity,
                color: const Color.fromRGBO(247, 248, 250, 1),
                alignment: Alignment.center,
                child: busy
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: SizedBox(
                                height: 14,
                                child: LinearProgressIndicator(
                                  value: _loadingProgress,
                                  backgroundColor: const Color.fromRGBO(
                                    70,
                                    78,
                                    89,
                                    0.14,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color.fromRGBO(255, 210, 21, 1),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${(_loadingProgress * 100).round()}%',
                              style: const TextStyle(
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Color.fromRGBO(70, 78, 89, 1),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Color.fromRGBO(70, 78, 89, 0.45),
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          'assets/images/logo_image_only.png',
                          height: 46,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
      ),
    );
  }

  Widget _buildRecipeImage(String raw, double h) {
    final cleaned = raw.trim();

    final fixed = ImageUrl.normalize(rawUrl: cleaned, apiBaseUrl: _baseUrl);

    return Image.network(
      fixed,
      height: h,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, err, stack) {
        return Container(
          height: h,
          alignment: Alignment.center,
          color: Colors.black12,
          child: Text(l10n.imageFailedToLoad),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = recipe?.imageUrl;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final chef = ChefCatalog.byId(_chefId, l10n);
    final chefName = chef?.name ?? l10n.notSelected;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Image.asset(
          'assets/images/logo_words_only.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              tooltip: l10n.notifications,
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.notificationsSoon)));
              },
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 18,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecipesListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PreferencesScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Chef tile
            Material(
              elevation: isDark ? 2 : 8,
              color: scheme.surface,
              shadowColor: Colors.black.withValues(alpha: isDark ? 0.22 : 0.12),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: scheme.outline.withValues(alpha: isDark ? 0.28 : 0.16),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: busy ? null : _pickChefFromGenerate,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Image.asset(
                          ChefCatalog.imageAssetFor(chef?.id),
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 54,
                                height: 54,
                                color: scheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.person,
                                  size: 28,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chefName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              chef?.cuisine ?? l10n.cuisine,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? scheme.onSurface.withValues(alpha: 0.88)
                                    : const Color.fromRGBO(70, 78, 89, 0.75),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.tapToChangeChef,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? scheme.onSurface.withValues(alpha: 0.78)
                                    : const Color.fromRGBO(70, 78, 89, 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.selectedChefDeterminesCuisine,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 210, 21, 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color.fromRGBO(255, 210, 21, 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color.fromRGBO(255, 210, 21, 1),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _isPro
                          ? 'Pro credits left: ${_aiCreditsRemaining ?? 100}'
                          : 'Free AI credits left: ${_aiCreditsRemaining ?? 5}',
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: queryController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => busy ? null : generate(),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                labelText: l10n.whatDoYouWantToEat,
                hintText: l10n.foodHintExample,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(70, 78, 89, 1),
                  foregroundColor: const Color.fromRGBO(255, 210, 21, 1),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: busy ? null : generate,
                child: Text(busy ? l10n.spinning : l10n.generateRecipe),
              ),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            Expanded(
              child: ListView(
                children: [
                  _imageBlock(imageUrl),
                  const SizedBox(height: 12),
                  if (recipe == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      busy
                          ? _loadingMessages(l10n)[_loadingMessageIndex]
                          : l10n.yourRecipeWillAppearHere,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: busy
                            ? const Color.fromRGBO(255, 210, 21, 1)
                            : scheme.onSurface.withValues(alpha: 0.92),
                      ),
                    ),
                  ] else ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe!.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(
                                70,
                                78,
                                89,
                                1,
                              ),
                              foregroundColor: const Color.fromRGBO(
                                255,
                                210,
                                21,
                                1,
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _favBusy ? null : _toggleFavorite,
                            icon: Icon(
                              _isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 20,
                            ),
                            label: Text(
                              _favBusy
                                  ? l10n.saving
                                  : (_isFavorite
                                        ? l10n.savedToFavorites
                                        : l10n.saveToFavorites),
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: const Color.fromRGBO(255, 210, 21, 1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 210, 21, 1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${recipe!.cookTimeMinutes} min',
                            style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: Color.fromRGBO(70, 78, 89, 1),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l10n.recipeDetails,
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.6,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            l10n.servesCount(recipe!.servings),
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.16 : 0.04,
                            ),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.ingredients,
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...recipe!.ingredients.map(
                            (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(top: 7),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        255,
                                        210,
                                        21,
                                        1,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${i.quantity} ${i.unit} ${i.name}',
                                      style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.steps,
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...recipe!.steps.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        70,
                                        78,
                                        89,
                                        1,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${e.key + 1}',
                                      style: const TextStyle(
                                        fontFamily: 'Raleway',
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
