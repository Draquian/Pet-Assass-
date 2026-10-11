import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/player.dart';
import '../services/game_service.dart';
import '../services/storage_service.dart';
import 'target_screen.dart';

class IdentifyScreen extends StatefulWidget {
  final String gameId;
  final List<Player> orderedPlayers;
  final bool pinEnabled;
  final String gameMode;
  /// Ítem asignado a cada jugador por nombre. Vacío si no hay modo item/word.
  final Map<String, String> itemByPlayer;

  const IdentifyScreen({
    super.key,
    required this.gameId,
    required this.orderedPlayers,
    required this.pinEnabled,
    required this.gameMode,
    this.itemByPlayer = const {},
  });

  @override
  State<IdentifyScreen> createState() => _IdentifyScreenState();
}

class _IdentifyScreenState extends State<IdentifyScreen> {
  Player? _selected;
  final _pinController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final selected = _selected;
    if (selected == null) {
      setState(() => _error = 'Selecciona el teu nom dels de la llista.');
      return;
    }
    if (widget.pinEnabled && _pinController.text.trim() != selected.pin) {
      setState(() => _error = 'El PIN no és correcte.');
      return;
    }

    final target = GameService.targetFor(widget.orderedPlayers, selected.name);
    final hunter = GameService.hunterFor(widget.orderedPlayers, selected.name);
    final assignedItem = widget.itemByPlayer[selected.name];
    final state = GameState(
      gameId: widget.gameId,
      myName: selected.name,
      myPin: selected.pin,
      status: PlayerStatus.alive,
      currentTarget: target,
      gameMode: widget.gameMode,
      assignedItem: assignedItem,
      myHunter: hunter,
    );
    await StorageService.saveState(state);

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => TargetScreen(initialState: state)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Qui ets?')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.gameMode.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.rule, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(widget.gameMode)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: ListView.builder(
                itemCount: widget.orderedPlayers.length,
                itemBuilder: (context, index) {
                  final p = widget.orderedPlayers[index];
                  final isSelected = _selected?.name == p.name;
                  return Card(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      title: Text(p.name),
                      onTap: () => setState(() {
                        _selected = p;
                        _error = null;
                      }),
                      trailing:
                          isSelected ? const Icon(Icons.check_circle) : null,
                    ),
                  );
                },
              ),
            ),
            if (widget.pinEnabled)
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'El teu PIN',
                  border: OutlineInputBorder(),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirm,
                child: const Text('Confirmar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
