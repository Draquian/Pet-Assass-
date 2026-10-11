import 'package:flutter/material.dart';

import '../models/player.dart';
import '../services/game_service.dart';
import 'single_device_game_screen.dart';

/// Pantalla per al mode d'un sol mòbil.
///
/// Mostra la llista de jugadors com a botons. Cada jugador toca el seu nom
/// (en privat), veu el seu objectiu i prem "Ho tinc clar" per tornar.
/// Un indicador visual marca els jugadors que ja han vist el seu objectiu.
class SingleDeviceRevealScreen extends StatefulWidget {
  final List<Player> orderedPlayers;
  final Map<String, String> itemByPlayer;
  final String gameMode;

  /// Ordre original d'inscripció dels jugadors.
  /// Si s'especifica, la llista de botons es mostra en aquest ordre
  /// en lloc de l'ordre circular barrejat (que es manté per calcular objectius).
  final List<Player>? registrationOrder;

  const SingleDeviceRevealScreen({
    super.key,
    required this.orderedPlayers,
    this.itemByPlayer = const {},
    this.gameMode = '',
    this.registrationOrder,
  });

  @override
  State<SingleDeviceRevealScreen> createState() =>
      _SingleDeviceRevealScreenState();
}

class _SingleDeviceRevealScreenState extends State<SingleDeviceRevealScreen> {
  /// Jugadors que ja han vist el seu objectiu.
  final Set<String> _seen = {};

  /// Jugador que s'està revelant ara. Null = mostrar la llista.
  String? _revealingPlayer;

  String? _targetOf(String playerName) =>
      GameService.targetFor(widget.orderedPlayers, playerName);

  @override
  Widget build(BuildContext context) {
    if (_revealingPlayer != null) {
      return _buildRevealView(context, _revealingPlayer!);
    }
    return _buildPlayerList(context);
  }

  // ── Llista de jugadors ────────────────────────────────────────────────────

  Widget _buildPlayerList(BuildContext context) {
    final allSeen = _seen.length == widget.orderedPlayers.length;
    // Mostrar en ordre d'inscripció si està disponible; sinó, ordre circular.
    final displayPlayers = widget.registrationOrder ?? widget.orderedPlayers;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Qui ets?'),
          automaticallyImplyLeading: true,
        ),
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
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSecondaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cada jugador toca el seu nom en privat per veure el seu objectiu.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: displayPlayers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final player = displayPlayers[index];
                    final hasSeen = _seen.contains(player.name);
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: Icon(hasSeen
                            ? Icons.check_circle
                            : Icons.person_outline),
                        label: Text(
                          player.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          foregroundColor: hasSeen
                              ? Theme.of(context).colorScheme.primary
                              : null,
                          side: hasSeen
                              ? BorderSide(
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                )
                              : null,
                        ),
                        onPressed: () =>
                            setState(() => _revealingPlayer = player.name),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Comptador de jugadors que han vist l'objectiu
              Text(
                '${_seen.length} / ${widget.orderedPlayers.length} jugadors han vist el seu objectiu',
                style: Theme.of(context).textTheme.bodySmall,
              ),
                if (allSeen) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Tots a punt — Comença la partida!'),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SingleDeviceGameScreen(
                            orderedPlayers: widget.orderedPlayers,
                            itemByPlayer: widget.itemByPlayer,
                            gameMode: widget.gameMode,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Vista de revelació de l'objectiu ─────────────────────────────────────

  Widget _buildRevealView(BuildContext context, String playerName) {
    final target = _targetOf(playerName) ?? '???';
    final item = widget.itemByPlayer[playerName];
    final colorScheme = Theme.of(context).colorScheme;
    final isWord =
        widget.gameMode.toLowerCase().contains('paraula');
    final itemTitle =
        isWord ? 'LA PARAULA SECRETA' : "L'OBJECTE ASSIGNAT";
    final itemSubtitle = isWord
        ? 'Digues aquesta paraula al teu objectiu per eliminar-lo'
        : 'Dóna-li aquest objecte al teu objectiu per eliminar-lo';

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
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
                            itemTitle,
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
                      const SizedBox(height: 4),
                      Text(
                        itemSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.7),
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
                  onPressed: () {
                    setState(() {
                      _seen.add(playerName);
                      _revealingPlayer = null;
                    });
                  },
                  child: const Text('Ho tinc clar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
