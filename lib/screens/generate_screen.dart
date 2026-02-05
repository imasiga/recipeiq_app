import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../api/api_client.dart';
import '../api/recipes_api.dart';
import '../models/recipe_models.dart';
import 'recipes_list_screen.dart';

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  // Keep this consistent with the rest of your app.
  final String _baseUrl = ApiConfig.baseUrl(useTunnel: true);

  late final ApiClient _apiClient = ApiClient(baseUrl: _baseUrl);
  late final RecipesApi _recipesApi = RecipesApi(_apiClient);

  final queryController =
      TextEditingController(text: 'high protein chicken salad');

  bool busy = false;
  Recipe? recipe;
  String? error;

  int _imageRefreshAttempts = 0;
  static const int _maxImageRefreshAttempts = 4;

  String _normalizeImageUrl(String rawUrl) {
    final s = rawUrl.trim();
    if (s.isEmpty) return s;

    // ✅ If API returns "/storage/....", prefix with current API base URL
    if (s.startsWith('/')) {
      return '${_baseUrl.replaceAll(RegExp(r'/$'), '')}$s';
    }

    try {
      final u = Uri.parse(s);

      // If not localhost, keep as-is
      if (u.host != '127.0.0.1' && u.host != 'localhost') return s;

      // Replace localhost host/scheme with whatever baseUrl is (tunnel-safe)
      final b = Uri.parse(_baseUrl);

      return u
          .replace(
            scheme: b.scheme,
            host: b.host,
            port: b.hasPort ? b.port : u.port,
          )
          .toString();
    } catch (_) {
      return s;
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
      } catch (_) {
        // ignore
      }
    });
  }

  Future<void> generate() async {
    final q = queryController.text.trim();
    if (q.isEmpty) {
      setState(() => error = 'Please enter something to cook.');
      return;
    }

    setState(() {
      busy = true;
      error = null;
      recipe = null;
      _imageRefreshAttempts = 0;
    });

    try {
      await _apiClient.ensureAnonymousToken();

      final r = await _recipesApi.generate(
        query: q,
        maxCookTimeMinutes: 20,
        servings: 2,
      );

      if (!mounted) return;
      setState(() => recipe = r);

      // ✅ If image not ready, auto refresh a few times
      _scheduleImageRefreshIfNeeded();
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  Widget _imageBlock(String? url) {
    final raw = (url ?? '').trim();

    if (raw.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black12,
        ),
        child: const Text('No image yet'),
      );
    }

    // ✅ This is the ONLY URL we use for Image.network
    final u = _normalizeImageUrl(raw);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        u,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, err, stack) {
          return Container(
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black12,
            ),
            child: const Text('Image failed to load'),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = recipe?.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RecipeIQ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecipesListScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: queryController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => busy ? null : generate(),
              decoration: const InputDecoration(
                labelText: 'What do you want to eat?',
                hintText: 'e.g. halal high protein chicken salad',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: busy ? null : generate,
              child: busy
                  ? const Text('Generating...')
                  : const Text('Generate recipe'),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            if (recipe != null)
              Expanded(
                child: ListView(
                  children: [
                    _imageBlock(imageUrl),
                    const SizedBox(height: 12),
                    Text(
                      recipe!.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(recipe!.cuisine ?? '—')} • ${recipe!.cookTimeMinutes} min • Serves ${recipe!.servings}',
                    ),
                    const SizedBox(height: 16),
                    Text('Ingredients',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    ...recipe!.ingredients.map(
                      (i) => Text('• ${i.quantity} ${i.unit} ${i.name}'),
                    ),
                    const SizedBox(height: 16),
                    Text('Steps', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    ...recipe!.steps
                        .asMap()
                        .entries
                        .map((e) => Text('${e.key + 1}. ${e.value}')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}