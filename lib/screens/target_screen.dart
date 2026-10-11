import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../services/storage_service.dart';
import 'eliminated_screen.dart';
import 'scan_handoff_screen.dart';
import 'surrender_screen.dart';
import 'show_handoff_qr_screen.dart';
import 'winner_screen.dart';

/// Pantalla principal mientras el jugador sigue vivo. Cualquier jugador
/// alive puede, en cualquier momento:
///  a) marcar que ha eliminado a su objetivo (abre la cámara para
///     escanear la confirmación de su víctima), o
///  b) marcar que le han eliminado a él (muestra su propio QR para que
///     lo escanee quien le ha cazado).
class TargetScreen extends StatefulWidget {
  final GameState initialState;

  const TargetScreen({super.key, required this.initialState});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> {
  late GameState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
  }

  Future<void> _refresh() async {
    final loaded = await StorageService.loadState();
    if (loaded != null && mounted) {
      setState(() => _state = loaded);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state.status == PlayerStatus.winner) {
      return const WinnerScreen();
    }
    if (_state.status == PlayerStatus.eliminated) {
      return const EliminatedScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petó Assassí'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Bones, ${_state.myName}',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 32),
              const Text('EL TEU OBJECTIU ÉS', style: TextStyle(letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(
                _state.currentTarget ?? '—',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (_state.assignedItem != null) ...[
                const SizedBox(height: 20),
                Builder(builder: (context) {
                  final isWord =
                      _state.gameMode.toLowerCase().contains('paraula');
                  final itemTitle =
                      isWord ? 'LA PARAULA SECRETA' : 'L\'OBJECTE ASSIGNAT';
                  final itemSubtitle = isWord
                      ? 'Digues aquesta paraula al teu objectiu per eliminar-lo'
                      : 'Dóna-li aquest objecte al teu objectiu per eliminar-lo';
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isWord
                                  ? Icons.chat_bubble_outline
                                  : Icons.inventory_2_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              itemTitle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _state.assignedItem!,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemSubtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                                .withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (_state.gameMode.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.rule, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_state.gameMode)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('He eliminat al meu objectiu'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanHandoffScreen(state: _state),
                      ),
                    );
                    _refresh();
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code),
                  label: const Text('M\'han eliminat'),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShowHandoffQrScreen(state: _state),
                      ),
                    );
                    _refresh();
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.flag),
                  label: const Text('Em rendeixo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurrenderScreen(state: _state),
                      ),
                    );
                    _refresh();
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
