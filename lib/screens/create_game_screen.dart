import 'package:flutter/material.dart';

import '../models/game_mode.dart';
import '../models/player.dart';
import '../services/crypto_service.dart';
import '../services/game_service.dart';
import 'show_qr_screen.dart';
import 'single_device_reveal_screen.dart';

const int _minPlayers = 3;

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _nameController = TextEditingController();
  final _customModeController = TextEditingController();
  // Un ítem/palabra por línea para los modos 'item' y 'word'.
  final _listController = TextEditingController();
  final List<Player> _players = [];

  bool _pinEnabled = false;
  bool _singleDevice = false;
  GameMode _selectedMode = GameMode.kiss;

  /// Devuelve la lista de ítems/palabras limpia (sin líneas vacías).
  List<String> get _parsedList => _listController.text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  bool get _needsList =>
      _selectedMode == GameMode.item || _selectedMode == GameMode.word;

  @override
  void dispose() {
    _nameController.dispose();
    _customModeController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _addPlayer() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    if (_players.any((p) => p.name.toLowerCase() == name.toLowerCase())) {
      _showSnack('Ja hi ha un jugador amb aquest nom. Afegeix cognoms o inicials.');
      return;
    }

    // El PIN se genera siempre, se use o no: así puedes cambiar entre
    // "blindado" y "abierto" en cualquier momento sin romper nada.
    final pin = GameService.generatePin();
    final player = Player(name: name, pin: pin);
    setState(() {
      _players.add(player);
      _nameController.clear();
    });

    if (!_pinEnabled) return;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('PIN de $name'),
        content: Text(
          'El seu codi secret és:\n\n$pin\n\n'
          'Digueu-li en persona, sense que el vegin els altres jugadors. '
          'El necessitarà per identificar-se en escanejar el QR de la partida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entés'),
          ),
        ],
      ),
    );
  }

  void _removePlayer(int index) {
    setState(() => _players.removeAt(index));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _generateGame() {
    if (_players.length < _minPlayers) {
      _showSnack('Afegeix com a mínim $_minPlayers jugadors.');
      return;
    }
    if (_selectedMode == GameMode.custom &&
        _customModeController.text.trim().isEmpty) {
      _showSnack('Descriu la manera d\'eliminar, o tria una opció predefinida.');
      return;
    }
    if (_needsList && _parsedList.isEmpty) {
      final label =
          _selectedMode == GameMode.item ? 'objectes' : 'paraules secretes';
      _showSnack('Afegeix com a mínim un element a la llista de $label.');
      return;
    }
    if (_needsList && _parsedList.length != _players.length) {
      final label =
          _selectedMode == GameMode.item ? 'objectes' : 'paraules secretes';
      _showSnack(
        'La llista de $label té ${_parsedList.length} elements '
        'però hi ha ${_players.length} jugadors. Han de ser iguals.',
      );
      return;
    }

    // Descripción base del modo.
    String modeDescription = _selectedMode == GameMode.custom
        ? _customModeController.text.trim()
        : gameModeDescriptions[_selectedMode] ?? '';

    final gameId = GameService.generateGameId();
    final ordered = GameService.shuffleCircular(_players);

    // Si hay lista, asignamos un ítem a cada jugador (en orden barajado).
    List<String>? shuffledItems;
    final Map<String, String> itemByPlayer = {};
    if (_needsList && _parsedList.isNotEmpty) {
      shuffledItems = List<String>.from(_parsedList)..shuffle();
      for (int i = 0; i < ordered.length; i++) {
        itemByPlayer[ordered[i].name] = shuffledItems[i];
      }
    }

    if (_singleDevice) {
      // Mode un sol mòbil: mostra la llista de revelació directament.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SingleDeviceRevealScreen(
            orderedPlayers: ordered,
            itemByPlayer: itemByPlayer,
            gameMode: modeDescription,
            registrationOrder: List.from(_players),
          ),
        ),
      );
      return;
    }

    final payload = {
      'type': 'init',
      'gameId': gameId,
      'pinEnabled': _pinEnabled,
      'mode': modeDescription,
      'players': ordered.asMap().entries.map((e) {
        final json = e.value.toJson();
        if (shuffledItems != null) json['assignedItem'] = shuffledItems[e.key];
        return json;
      }).toList(),
    };
    final encrypted = CryptoService.encryptJson(payload);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShowQrScreen(
          encryptedPayload: encrypted,
          gameId: gameId,
          orderedPlayers: ordered,
          pinEnabled: _pinEnabled,
          gameMode: modeDescription,
          itemByPlayer: itemByPlayer,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear partida')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Un sol mòbil'),
              subtitle: Text(
                _singleDevice
                    ? 'Tots els jugadors usaran aquest mòbil per veure el seu objectiu.'
                    : 'Mode normal: cada jugador usa el seu propi mòbil.',
              ),
              value: _singleDevice,
              onChanged: (v) => setState(() => _singleDevice = v),
            ),
            const Divider(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Jugadors blindats amb PIN'),
              subtitle: Text(
                _pinEnabled
                    ? 'Cada jugador necessita el seu PIN per identificar-se.'
                    : 'Mode obert: ningun nom de jugador esta protegit.',
              ),
              value: _pinEnabled,
              onChanged: _singleDevice ? null : (v) => setState(() => _pinEnabled = v),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<GameMode>(
              value: _selectedMode,
              decoration: const InputDecoration(
                labelText: 'Forma de "eliminar"',
                // helperText: 'Solo informativo: no cambia cómo funciona la app.',
                border: OutlineInputBorder(),
              ),
              items: GameMode.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(gameModeTitles[m]!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() {
                _selectedMode = v ?? _selectedMode;
                _listController.clear();
              }),
            ),
            if (_selectedMode == GameMode.custom) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customModeController,
                maxLength: 120,
                decoration: const InputDecoration(
                  labelText: 'Descriu com s\'elimina',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            if (_needsList) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _listController,
                minLines: 3,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: _selectedMode == GameMode.item
                      ? 'Llista d\'objectes (un per línia)'
                      : 'Llista de paraules secretes (una per línia)',
                  hintText: _selectedMode == GameMode.item
                      ? 'Ej:\nGot\nLlapis\nMartell'
                      : 'Ej:\nSecret\nParlamentar\nConcubina',
                  helperText:
                      'Cada jugador verá la lista completa en su QR.',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
            const SizedBox(height: 4),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nom del jugador',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addPlayer(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addPlayer,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _players.isEmpty
                  ? const Center(child: Text('No hi ha jugadors'))
                  : ListView.builder(
                      itemCount: _players.length,
                      itemBuilder: (context, index) {
                        final p = _players[index];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text('${index + 1}')),
                            title: Text(p.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removePlayer(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shuffle),
                label: Text('Mesclar i crear partida (${_players.length})'),
                onPressed:
                    _players.length >= _minPlayers ? _generateGame : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
