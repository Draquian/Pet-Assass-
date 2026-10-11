import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/game_state.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';

/// Pantalla de rendició. Es mostra quan el jugador prem "Em rendeixo".
/// Genera el mateix QR de traspàs d'objectiu que "M'han eliminat", però
/// precedit d'un missatge explicatiu indicant qui era el seu assassí.
class SurrenderScreen extends StatefulWidget {
  final GameState state;

  const SurrenderScreen({super.key, required this.state});

  @override
  State<SurrenderScreen> createState() => _SurrenderScreenState();
}

class _SurrenderScreenState extends State<SurrenderScreen> {
  bool _confirmed = false;
  String? _lastWords;

  final _lastWordsController = TextEditingController();

  @override
  void dispose() {
    _lastWordsController.dispose();
    super.dispose();
  }

  Future<void> _markEliminated() async {
    final newState = GameState(
      gameId: widget.state.gameId,
      myName: widget.state.myName,
      myPin: widget.state.myPin,
      status: PlayerStatus.eliminated,
      currentTarget: null,
      gameMode: widget.state.gameMode,
      myHunter: widget.state.myHunter,
    );
    await StorageService.saveState(newState);
    setState(() {
      _lastWords = _lastWordsController.text.trim().isEmpty
          ? null
          : _lastWordsController.text.trim();
      _confirmed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hunter = widget.state.myHunter ?? '???';

    // ── Pas 1: pantalla de confirmació ──────────────────────────────────────
    if (!_confirmed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Em rendeixo')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.flag, size: 64, color: colorScheme.error),
              const SizedBox(height: 24),
              Text(
                'Segur que et vols rendir?',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Si et rendeixes, seràs eliminat/da de la partida i\net desvelarem a qui havies de mostrar el QR.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              // Últimes paraules opcional
              const Text(
                'Últimes paraules (opcional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _lastWordsController,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  hintText: 'Escriu alguna cosa...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.flag),
                  label: const Text('Sí, em rendeixo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    foregroundColor: colorScheme.onError,
                  ),
                  onPressed: _markEliminated,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel·lar'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Pas 2: mostra el QR perquè l'assassí l'escaneji ────────────────────
    // Nota: no s'inclou 'killer' perquè és una rendició, no un assassinat.
    final payload = <String, dynamic>{
      'type': 'handoff',
      'gameId': widget.state.gameId,
      'eliminated': widget.state.myName,
      'nextTarget': widget.state.currentTarget,
      'nextItem': widget.state.assignedItem,
      if (_lastWords != null) 'lastWords': _lastWords,
    };
    final encrypted = CryptoService.encryptJson(payload);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Has deixat la partida'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flag, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'T\'has rendit',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // ── Qui et perseguia (revelat ara) ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.error.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search,
                            size: 16, color: colorScheme.onErrorContainer),
                        const SizedBox(width: 6),
                        Text(
                          'QUI ET VOLIA DONAR EL PETÓ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      hunter,
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onErrorContainer,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ensenya-li el codi QR de sota.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onErrorContainer
                            .withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: encrypted,
                  version: QrVersions.auto,
                  size: 260,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Ja l\'han escanejat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
