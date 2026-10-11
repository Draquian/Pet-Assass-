import 'package:flutter/material.dart';

import 'create_game_screen.dart';
import 'scan_join_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10030B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/logo/screen_logo.jpeg',
                width: 140,
                height: 140,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 16),
              Text('Petó Assassí',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              // const Text(
              //   'El joc de l\'assassí, sense internet ni cobertura.',
              //   textAlign: TextAlign.center,
              // ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.fiber_new),
                  label: const Text('Generar partida'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateGameScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.group_add),
                  label: const Text('Entrar a una partida'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanJoinScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
