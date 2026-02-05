import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../api/api_client.dart';
import '../api/preferences_api.dart';
import '../app/app_state.dart';
import 'generate_screen.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl(useTunnel: true));
  late final prefsApi = PreferencesApi(_apiClient);

  // ✅ Chef dropdown options (simple, no extra screen)
  static const List<Map<String, String>> _chefOptions = [
    {'id': 'chef_italian_male', 'label': 'Italian Chef (Male)'},
    {'id': 'chef_italian_female', 'label': 'Italian Chef (Female)'},
    {'id': 'chef_japanese_male', 'label': 'Japanese Chef (Male)'},
    {'id': 'chef_japanese_female', 'label': 'Japanese Chef (Female)'},
    {'id': 'chef_indian_male', 'label': 'Indian Chef (Male)'},
    {'id': 'chef_indian_female', 'label': 'Indian Chef (Female)'},
    {'id': 'chef_mexican_male', 'label': 'Mexican Chef (Male)'},
    {'id': 'chef_mexican_female', 'label': 'Mexican Chef (Female)'},
    {'id': 'chef_french_male', 'label': 'French Chef (Male)'},
    {'id': 'chef_mediterranean_female', 'label': 'Mediterranean Chef (Female)'},
    {'id': 'chef_chinese_female', 'label': 'Chinese Chef (Female)'},
  ];

  String? chefId; // selected chef id
  String dietStyle = 'halal';
  String spiceLevel = 'medium';
  String units = 'imperial';
  int maxCookTimeMinutes = 25;
  int servingsDefault = 2;

  final allergiesController = TextEditingController(text: 'dairy');
  final cuisinesController = TextEditingController(text: 'American');

  bool busy = false;
  String? error;

  List<String> _csvToList(String s) =>
      s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });

    try {
      await prefsApi.update(
        chefId: chefId,
        dietStyle: dietStyle,
        allergies: _csvToList(allergiesController.text),
        cuisines: _csvToList(cuisinesController.text),
        maxCookTimeMinutes: maxCookTimeMinutes,
        spiceLevel: spiceLevel,
        servingsDefault: servingsDefault,
        units: units,
      );

      await AppState.setHasPreferences(true);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GenerateScreen()),
      );
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
    allergiesController.dispose();
    cuisinesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Preferences')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ✅ Chef dropdown
            DropdownButtonFormField<String>(
              value: chefId,
              decoration: const InputDecoration(labelText: 'Chef'),
              hint: const Text('Choose a chef'),
              items: _chefOptions
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c['id']!,
                      child: Text(c['label']!),
                    ),
                  )
                  .toList(),
              onChanged: busy ? null : (v) => setState(() => chefId = v),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: dietStyle,
              decoration: const InputDecoration(labelText: 'Diet style'),
              items: const [
                DropdownMenuItem(value: 'halal', child: Text('Halal')),
                DropdownMenuItem(value: 'vegetarian', child: Text('Vegetarian')),
                DropdownMenuItem(value: 'keto', child: Text('Keto')),
                DropdownMenuItem(value: 'high_protein', child: Text('High Protein')),
              ],
              onChanged:
                  busy ? null : (v) => setState(() => dietStyle = v ?? dietStyle),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: allergiesController,
              decoration: const InputDecoration(
                labelText: 'Allergies (comma separated)',
                hintText: 'dairy, peanuts',
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: cuisinesController,
              decoration: const InputDecoration(
                labelText: 'Cuisines (comma separated)',
                hintText: 'American, Mediterranean',
              ),
            ),

            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: spiceLevel,
              decoration: const InputDecoration(labelText: 'Spice level'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged:
                  busy ? null : (v) => setState(() => spiceLevel = v ?? spiceLevel),
            ),

            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: units,
              decoration: const InputDecoration(labelText: 'Units'),
              items: const [
                DropdownMenuItem(value: 'imperial', child: Text('Imperial')),
                DropdownMenuItem(value: 'metric', child: Text('Metric')),
              ],
              onChanged: busy ? null : (v) => setState(() => units = v ?? units),
            ),

            const SizedBox(height: 12),
            Text('Max cook time: $maxCookTimeMinutes minutes'),
            Slider(
              value: maxCookTimeMinutes.toDouble(),
              min: 10,
              max: 90,
              divisions: 16,
              onChanged: busy
                  ? null
                  : (v) => setState(() => maxCookTimeMinutes = v.round()),
            ),

            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Servings: '),
                IconButton(
                  onPressed: busy || servingsDefault <= 1
                      ? null
                      : () => setState(() => servingsDefault--),
                  icon: const Icon(Icons.remove),
                ),
                Text('$servingsDefault'),
                IconButton(
                  onPressed: busy ? null : () => setState(() => servingsDefault++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 16),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),

            FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Saving...' : 'Save preferences'),
            ),
          ],
        ),
      ),
    );
  }
}