import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../api/api_client.dart';
import '../api/recipes_api.dart';
import '../models/recipe_models.dart';
import 'recipe_detail_screen.dart';
import '../utils/image_url.dart';

class RecipesListScreen extends StatefulWidget {
  const RecipesListScreen({super.key});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  final String _baseUrl = ApiConfig.baseUrl(useTunnel: true);
  late final ApiClient _apiClient = ApiClient(baseUrl: _baseUrl);
  late final RecipesApi _recipesApi = RecipesApi(_apiClient);

  bool loading = true;
  String? error;
  List<RecipeSummary> items = [];

  int _imageRefreshAttempts = 0;
  static const int _maxImageRefreshAttempts = 4;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _scheduleImageRefreshIfNeeded() {
    final hasMissing = items.any((r) => (r.imageUrl ?? '').trim().isEmpty);
    if (!hasMissing) return;

    if (_imageRefreshAttempts >= _maxImageRefreshAttempts) return;
    _imageRefreshAttempts++;

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (!loading) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await _apiClient.ensureAnonymousToken();
      final data = await _recipesApi.list();
      if (!mounted) return;

      setState(() => items = data);

      // If images are generated asynchronously, this helps refresh a few times.
      _scheduleImageRefreshIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    } else if (items.isEmpty) {
      body = const Center(child: Text('No recipes yet. Generate one!'));
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final r = items[index];
            return _RecipeCard(
              item: r,
              apiBaseUrl: _baseUrl,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(recipeId: r.id),
                  ),
                );
              },
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
        actions: [
          IconButton(
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeSummary item;
  final String apiBaseUrl;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.item,
    required this.apiBaseUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if ((item.cuisine ?? '').trim().isNotEmpty) item.cuisine!.trim(),
      if (item.dietStyle.trim().isNotEmpty) item.dietStyle.trim(),
      '${item.cookTimeMinutes} min',
      'Serves ${item.servings}',
    ];

    final subtitle = subtitleParts.join(' • ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.35),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: _Thumb(url: item.imageUrl, apiBaseUrl: apiBaseUrl),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? url;
  final String apiBaseUrl;

  const _Thumb({required this.url, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    final raw = (url ?? '').trim();

    if (raw.isEmpty) {
      return Container(
        width: 110,
        height: 90,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        alignment: Alignment.center,
        child: const Icon(Icons.fastfood),
      );
    }

    final cleaned = raw.startsWith('http')
        ? raw.replaceFirst(RegExp(r'^.*(https?://)'), r'$1')
        : raw;
    final fixed = ImageUrl.normalize(rawUrl: cleaned, apiBaseUrl: apiBaseUrl);

    return Image.network(
      fixed,
      width: 110,
      height: 90,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: 110,
        height: 90,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const SizedBox(
          width: 110,
          height: 90,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}