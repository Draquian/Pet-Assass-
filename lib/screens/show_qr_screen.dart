import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/player.dart';
import 'identify_screen.dart';

class ShowQrScreen extends StatelessWidget {
  final String encryptedPayload;
  final String gameId;
  final List<Player> orderedPlayers;
  final bool pinEnabled;
  final String gameMode;
  final Map<String, String> itemByPlayer;

  const ShowQrScreen({
    super.key,
    required this.encryptedPayload,
    required this.gameId,
    required this.orderedPlayers,
    required this.pinEnabled,
    required this.gameMode,
    this.itemByPlayer = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partida creada')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Que tots els jugadors obrin Petó Assassí, i seleccionin: '
                '"Entrar a una partida" i escanejin aquest codi:',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: encryptedPayload,
                  version: QrVersions.auto,
                  size: 260,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 8),
              Text('Codi de la partida: $gameId',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(pinEnabled ? Icons.lock : Icons.lock_open,
                              size: 18),
                          const SizedBox(width: 8),
                          Text(
                            pinEnabled
                                ? 'Jugadors amb PIN'
                                : 'Mode obert (sense PIN)',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.rule, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(gameMode)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person),
                  label: const Text('Jo també vui jugar'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IdentifyScreen(
                          gameId: gameId,
                          orderedPlayers: orderedPlayers,
                          pinEnabled: pinEnabled,
                          gameMode: gameMode,
                          itemByPlayer: itemByPlayer,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
