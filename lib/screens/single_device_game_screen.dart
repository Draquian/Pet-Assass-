import 'package:flutter/material.dart';

import '../models/kill_record.dart';
import '../models/player.dart';
import '../services/game_service.dart';
import 'single_device_results_screen.dart';

enum _PlayerStatus { alive, eliminated, winner }

/// Pantalla principal de la partida en mode un sol mòbil.
///
/// Mostra la llista de jugadors. Per a cada jugador:
///  - Toca el nom per consultar el seu objectiu (en privat).
///  - Botó per marcar-lo com eliminat (amb diàleg per identificar qui l'ha matat
///    i per escriure les últimes paraules).
///  - Botó per marcar-lo com a vencedor.
///
/// Al final, "La partida ha acabat" mostra els resultats.
class SingleDeviceGameScreen extends StatefulWidget {
  final List<Player> orderedPlayers;
  final Map<String, String> itemByPlayer;
  final String gameMode;

  const SingleDeviceGameScreen({
    super.key,
    required this.orderedPlayers,
    this.itemByPlayer = const {},
    this.gameMode = '',
  });

  @override
  State<SingleDeviceGameScreen> createState() => _SingleDeviceGameScreenState();
}

class _SingleDeviceGameScreenState extends State<SingleDeviceGameScreen> {
  late final Map<String, _PlayerStatus> _status;

  /// Historial d'eliminacions (killer → victim).
  final List<KillRecord> _killHistory = [];

  /// Últimes paraules per jugador eliminat (nom → text).
  final Map<String, String> _lastWords = {};

  /// Jugador que s'està consultant ara. Null = llista principal.
  String? _consultingPlayer;

  @override
  void initState() {
    super.initState();
    _status = {for (final p in widget.orderedPlayers) p.name: _PlayerStatus.alive};
  }

  String? _targetOf(String name) =>
      GameService.targetFor(widget.orderedPlayers, name);

  List<Player> get _alivePlayers =>
      widget.orderedPlayers.where((p) => _status[p.name] == _PlayerStatus.alive || _status[p.name] == _PlayerStatus.winner).toList();

  void _setWinner(String name) {
    setState(() {
      if (_status[name] == _PlayerStatus.winner) {
        _status[name] = _PlayerStatus.alive;
      } else {
        _status[name] = _PlayerStatus.winner;
      }
    });
  }

  /// Obre el diàleg per marcar un jugador com eliminat.
  /// Demana qui l'ha matat (optional) i les últimes paraules (optional).
  Future<void> _showEliminateDialog(String victimName) async {
    // Si ja estava eliminat, simplement el restaura (toggle off).
    if (_status[victimName] == _PlayerStatus.eliminated) {
      setState(() {
        _status[victimName] = _PlayerStatus.alive;
        _killHistory.removeWhere((r) => r.victim == victimName);
        _lastWords.remove(victimName);
      });
      return;
    }

    final aliveOthers = widget.orderedPlayers
        .where((p) => p.name != victimName && _status[p.name] != _PlayerStatus.eliminated)
        .toList();

    String? selectedKiller;
    final lastWordsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Eliminació de $victimName'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Qui l'ha eliminat?
                    const Text(
                      'Qui l\'ha eliminat?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (aliveOthers.isEmpty)
                      const Text(
                        'No hi ha cap jugador viu per assignar com a killer.',
                        style: TextStyle(fontSize: 12),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // Opció "ningú / rendició"
                          ChoiceChip(
                            label: const Text('Rendició / Sense killer'),
                            selected: selectedKiller == null,
                            onSelected: (_) =>
                                setDialogState(() => selectedKiller = null),
                          ),
                          ...aliveOthers.map(
                            (p) => ChoiceChip(
                              label: Text(p.name),
                              selected: selectedKiller == p.name,
                              onSelected: (_) =>
                                  setDialogState(() => selectedKiller = p.name),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    // Últimes paraules
                    const Text(
                      'Últimes paraules (opcional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: lastWordsController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        hintText: 'Escriu alguna cosa...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel·lar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Confirmar eliminació'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _status[victimName] = _PlayerStatus.eliminated;

      // Registrar KillRecord només si hi ha killer (no és una rendició pura)
      if (selectedKiller != null) {
        final record = KillRecord(
          killer: selectedKiller!,
          victim: victimName,
          lastWords: lastWordsController.text.trim().isEmpty
              ? null
              : lastWordsController.text.trim(),
        );
        // Evitar duplicats
        _killHistory.removeWhere((r) => r.victim == victimName);
        _killHistory.add(record);
      }

      // Guardar últimes paraules fins i tot en rendicions
      final words = lastWordsController.text.trim();
      if (words.isNotEmpty) {
        _lastWords[victimName] = words;
      } else {
        _lastWords.remove(victimName);
      }
    });
  }

  Future<void> _confirmEndGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finalitzar partida?'),
        content: const Text(
            'Segur que vols acabar la partida? Es mostrarà la pantalla de resultats.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finalitzar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      _endGame();
    }
  }

  void _endGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SingleDeviceResultsScreen(
          allPlayers: widget.orderedPlayers,
          status: Map.fromEntries(
            _status.entries.map(
              (e) => MapEntry(
                e.key,
                switch (e.value) {
                  _PlayerStatus.alive => 'alive',
                  _PlayerStatus.eliminated => 'eliminated',
                  _PlayerStatus.winner => 'winner',
                },
              ),
            ),
          ),
          killHistory: List.unmodifiable(_killHistory),
          lastWords: Map.unmodifiable(_lastWords),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_consultingPlayer != null) {
      return _buildConsultView(context, _consultingPlayer!);
    }
    return _buildGameList(context);
  }

  // ── Llista principal ──────────────────────────────────────────────────────

  Widget _buildGameList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partida en curs'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          if (widget.gameMode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.rule, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(widget.gameMode,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              itemCount: widget.orderedPlayers.length,
              itemBuilder: (context, index) {
                final player = widget.orderedPlayers[index];
                final st = _status[player.name]!;
                final isEliminated = st == _PlayerStatus.eliminated;
                final isWinner = st == _PlayerStatus.winner;
                final hasKillRecord = _killHistory.any((r) => r.victim == player.name);
                final hasLastWords = _lastWords.containsKey(player.name);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    color: isEliminated
                        ? colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5)
                        : isWinner
                            ? colorScheme.primaryContainer
                            : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // ── Nom (toca per consultar objectiu) ──────────
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: isEliminated
                                  ? null
                                  : () => setState(
                                      () => _consultingPlayer = player.name),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          isWinner
                                              ? Icons.emoji_events
                                              : isEliminated
                                                  ? Icons.close
                                                  : Icons.person_outline,
                                          size: 20,
                                          color: isWinner
                                              ? colorScheme.primary
                                              : isEliminated
                                                  ? colorScheme.outline
                                                  : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            player.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              decoration: isEliminated
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: isEliminated
                                                  ? colorScheme.outline
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (!isEliminated) ...[
                                          const SizedBox(width: 4),
                                          Icon(Icons.visibility_outlined,
                                              size: 14,
                                              color: colorScheme.outline),
                                        ],
                                      ],
                                    ),
                                    // Indicadors d'info adicional si eliminat
                                    if (isEliminated) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          if (hasKillRecord) ...[
                                            Icon(Icons.gavel,
                                                size: 11,
                                                color: colorScheme.outline),
                                            const SizedBox(width: 3),
                                            Text(
                                              'killer registrat',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: colorScheme.outline),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          if (hasLastWords) ...[
                                            Icon(Icons.chat_bubble_outline,
                                                size: 11,
                                                color: colorScheme.outline),
                                            const SizedBox(width: 3),
                                            Text(
                                              'últimes paraules',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: colorScheme.outline),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // ── Botons d'acció ─────────────────────────────
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Eliminar
                              _ActionChip(
                                icon: Icons.close,
                                label: 'Eliminat',
                                active: isEliminated,
                                activeColor: colorScheme.error,
                                onTap: () => _showEliminateDialog(player.name),
                              ),
                              const SizedBox(width: 4),
                              // Vencedor
                              _ActionChip(
                                icon: Icons.emoji_events,
                                label: 'Guanya',
                                active: isWinner,
                                activeColor: colorScheme.primary,
                                onTap: isEliminated
                                    ? null
                                    : () => _setWinner(player.name),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Estadística ràpida ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite, size: 14, color: Colors.green.withValues(alpha: 0.8)),
                const SizedBox(width: 4),
                Text(
                  '${_alivePlayers.length} vius',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
                const SizedBox(width: 16),
                Icon(Icons.close, size: 14, color: colorScheme.error.withValues(alpha: 0.7)),
                const SizedBox(width: 4),
                Text(
                  '${widget.orderedPlayers.length - _alivePlayers.length} eliminats',
                  style: TextStyle(fontSize: 12, color: colorScheme.outline),
                ),
                if (_killHistory.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.gavel, size: 14, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${_killHistory.length} assassinats',
                    style: TextStyle(fontSize: 12, color: colorScheme.outline),
                  ),
                ],
              ],
            ),
          ),

          // ── Botó de final de partida ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flag_outlined),
                label: const Text('La partida ha acabat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                ),
                onPressed: _confirmEndGame,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vista de consulta de l'objectiu ──────────────────────────────────────

  Widget _buildConsultView(BuildContext context, String playerName) {
    final target = _targetOf(playerName) ?? '???';
    final item = widget.itemByPlayer[playerName];
    final colorScheme = Theme.of(context).colorScheme;
    final isWord = widget.gameMode.toLowerCase().contains('paraula');

    return Scaffold(
      appBar: AppBar(
        title: Text(playerName),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'EL TEU OBJECTIU ÉS',
                style: TextStyle(letterSpacing: 2, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                target,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              if (item != null) ...[
                const SizedBox(height: 28),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
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
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isWord ? 'LA PARAULA SECRETA' : "L'OBJECTE ASSIGNAT",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      setState(() => _consultingPlayer = null),
                  child: const Text('Tornar a la partida'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget auxiliar: botó d'acció compacte ─────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: onTap == null
                ? Theme.of(context).colorScheme.outlineVariant
                : active
                    ? activeColor
                    : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: active
                  ? Colors.white
                  : onTap == null
                      ? Theme.of(context).colorScheme.outlineVariant
                      : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active
                    ? Colors.white
                    : onTap == null
                        ? Theme.of(context).colorScheme.outlineVariant
                        : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
