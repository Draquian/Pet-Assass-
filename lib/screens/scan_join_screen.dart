import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/player.dart';
import '../services/crypto_service.dart';
import 'identify_screen.dart';

class ScanJoinScreen extends StatefulWidget {
  const ScanJoinScreen({super.key});

  @override
  State<ScanJoinScreen> createState() => _ScanJoinScreenState();
}

class _ScanJoinScreenState extends State<ScanJoinScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null) return;

    final data = CryptoService.decryptJson(raw);
    if (data == null || data['type'] != 'init') {
      _showError('Aquest codi QR no és vàlid per a una partida de Petó Assessí.');
      return;
    }

    _handled = true;
    final gameId = data['gameId'] as String;
    final pinEnabled = data['pinEnabled'] as bool? ?? true;
    final gameMode = data['mode'] as String? ?? '';
    final playersJson = (data['players'] as List).cast<Map<String, dynamic>>();
    final players = playersJson.map(Player.fromJson).toList();

    // Extraemos el ítem asignado a cada jugador (si existe).
    final Map<String, String> itemByPlayer = {};
    for (final pj in playersJson) {
      final name = pj['n'] as String? ?? '';
      final item = pj['assignedItem'] as String?;
      if (name.isNotEmpty && item != null) itemByPlayer[name] = item;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => IdentifyScreen(
          gameId: gameId,
          orderedPlayers: players,
          pinEnabled: pinEnabled,
          gameMode: gameMode,
          itemByPlayer: itemByPlayer,
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escaneja el QR de la partida')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
