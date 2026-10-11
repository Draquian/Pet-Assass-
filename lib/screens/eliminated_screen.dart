import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'home_screen.dart';

class EliminatedScreen extends StatelessWidget {
  const EliminatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.close, size: 72),
                const SizedBox(height: 16),
                Text('Has estat eliminat',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                  'Gràcies per jugar.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    await StorageService.clearState();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    }
                  },
                  child: const Text('Sortir de la partida'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
