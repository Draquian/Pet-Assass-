import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import 'home_screen.dart';

class WinnerScreen extends StatelessWidget {
  const WinnerScreen({super.key});

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
                const Icon(Icons.emoji_events, size: 88, color: Colors.amber),
                const SizedBox(height: 16),
                Text('¡La victòria és teva!',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Ets l\'únic jugador viu.',
                    textAlign: TextAlign.center),
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
                  child: const Text('Tornar al menú'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
