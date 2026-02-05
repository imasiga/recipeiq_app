import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../api/api_client.dart';
import '../api/recipes_api.dart';
import '../models/recipe_models.dart';
import '../utils/image_url.dart';

class RecipeDetailScreen extends StatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final String _baseUrl = ApiConfig.baseUrl(useTunnel: true);
  late final ApiClient _apiClient = ApiClient(baseUrl: _baseUrl);
  late final RecipesApi _recipesApi = RecipesApi(_apiClient);

  bool loading = true;
  String? error;
  Recipe? recipe;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  if (!mounted) return;

  setState(() {
    loading = true;
    error = null;
  });

  try {
    await _apiClient.ensureAnonymousToken();
    final r = await _recipesApi.getById(widget.recipeId);

    if (!mounted) return;
    setState(() {
      recipe = r;
      loading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      error = e.toString();
      loading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final r = recipe;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe'),
        actions: [
          IconButton(
            onPressed: loading ? null : _load,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : (error != null)
              ? Center(
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
                )
              : (r == null)
                  ? const Center(child: Text('Recipe not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _HeaderImage(url: r.imageUrl, apiBaseUrl: _baseUrl),
                        const SizedBox(height: 12),
                        Text(
                          r.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [
                            if ((r.cuisine ?? '').trim().isNotEmpty) r.cuisine,
                            if (r.dietStyle.trim().isNotEmpty) r.dietStyle,
                            '${r.cookTimeMinutes} min',
                            'Serves ${r.servings}',
                          ]
                              .where((e) => e != null && e.toString().trim().isNotEmpty)
                              .join(' • '),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 18),
                        Text('Ingredients', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...r.ingredients.map(
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• ${i.quantity} ${i.unit} ${i.name}'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text('Steps', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...r.steps.asMap().entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text('${e.key + 1}. ${e.value}'),
                              ),
                            ),
                        if (r.nutrition != null) ...[
                          const SizedBox(height: 18),
                          Text('Nutrition', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text('Calories: ${r.nutrition!.calories}'),
                          Text('Protein: ${r.nutrition!.proteinG} g'),
                          Text('Carbs: ${r.nutrition!.carbsG} g'),
                          Text('Fat: ${r.nutrition!.fatG} g'),
                        ],
                      ],
                    ),
    );
  }
}

class _HeaderImage extends StatelessWidget {
  final String? url;
  final String apiBaseUrl;

  const _HeaderImage({required this.url, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    final raw = (url ?? '').trim();

    if (raw.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 220,
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          alignment: Alignment.center,
          child: const Icon(Icons.fastfood, size: 40),
        ),
      );
    }

    final cleaned = raw.startsWith('http')
        ? raw.replaceFirst(RegExp(r'^.*(https?://)'), r'$1')
        : raw;
    final fixed = ImageUrl.normalize(rawUrl: cleaned, apiBaseUrl: apiBaseUrl);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        fixed,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 220,
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            alignment: Alignment.center,
            child: const Icon(Icons.broken_image, size: 40),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: 220,
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}