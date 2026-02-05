import 'dart:convert';
import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'screens/welcome_screen.dart';

void main() => runApp(const RecipeIQApp());

class RecipeIQApp extends StatelessWidget {
  const RecipeIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecipeIQ',
      theme: ThemeData(useMaterial3: true),
      home: const WelcomeScreen(),
    );
  }
}

// Keep this for debugging if you want
class BackendTestPage extends StatefulWidget {
  const BackendTestPage({super.key});

  @override
  State<BackendTestPage> createState() => _BackendTestPageState();
}

class _BackendTestPageState extends State<BackendTestPage> {
  final api = ApiClient(baseUrl: 'http://127.0.0.1:8000');

  String output = 'Tap "Generate" to test the backend.';
  bool busy = false;

  Future<void> generate() async {
    setState(() {
      busy = true;
      output = 'Working...';
    });

    try {
      await api.ensureAnonymousToken();

      final res = await api.post(
        '/api/v1/recipes/generate',
        body: {
          'query': 'high protein chicken salad',
          'maxCookTimeMinutes': 20,
          'servings': 2,
        },
      );

      if (res.statusCode != 201) {
        setState(() => output = 'Error ${res.statusCode}\n${res.body}');
        return;
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final recipe = data['recipe'];
      setState(() => output = const JsonEncoder.withIndent('  ').convert(recipe));
    } catch (e) {
      setState(() => output = 'Exception: $e');
    } finally {
      setState(() => busy = false);
    }
  }

  Future<void> clearToken() async {
    await api.clearToken();
    setState(() => output = 'Token cleared. Tap "Generate" again.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RecipeIQ Backend Test'),
        actions: [
          IconButton(
            onPressed: busy ? null : clearToken,
            icon: const Icon(Icons.logout),
            tooltip: 'Clear token',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: SelectableText(output),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : generate,
        icon: busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator())
            : const Icon(Icons.play_arrow),
        label: const Text('Generate'),
      ),
    );
  }
}