import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../api/preferences_api.dart';
import '../config/api_config.dart';
import 'preferences_screen.dart';
import 'generate_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl(useTunnel: true));
  late final prefsApi = PreferencesApi(apiClient);

  bool busy = false;

  Future<void> continueFlow() async {
    setState(() => busy = true);

    try {
      final prefs = await prefsApi.get();

      if (!mounted) return;

      if (prefs == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PreferencesScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => GenerateScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          onPressed: busy ? null : continueFlow,
          child: Text(busy ? 'Please wait...' : 'Continue'),
        ),
      ),
    );
  }
}