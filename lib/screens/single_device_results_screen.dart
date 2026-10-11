import 'package:flutter/material.dart';

import '../models/kill_record.dart';
import '../models/player.dart';
import 'home_screen.dart';

/// Pantalla de resultats finals en el mode d'un sol mòbil.
///
/// Regles de victòria (única font de veritat):
/// - Si queda exactament 1 jugador viu → és el vencedor automàtic.
/// - Si queden 2 o més vius → els marcats com 'winner' guanyen.
///   Si cap no ha estat marcat, no hi ha vencedor.
/// - Els eliminats mai compten com a supervivents.
///
/// Seccions mostrades:
/// 1. Vencedor / Vencedors (o cap guanyador).
/// 2. Jugadors vius / supervivents.
/// 3. Historial killer → víctima (si n'hi ha).
/// 4. Últimes paraules dels eliminats (si n'hi ha).
class SingleDeviceResultsScreen extends StatelessWidget {
  final List<Player> allPlayers;

  /// Estat de cada jugador: 'alive', 'eliminated' o 'winner'.
  final Map<String, String> status;

  /// Historial d'assassinats confirmats durant la partida.
  final List<KillRecord> killHistory;

  /// Últimes paraules per jugador eliminat (nom → text).
  /// Pot contenir jugadors sense KillRecord (rendicions amb últimes paraules).
  final Map<String, String> lastWords;

  const SingleDeviceResultsScreen({
    super.key,
    required this.allPlayers,
    required this.status,
    this.killHistory = const [],
    this.lastWords = const {},
  });

  // ── Càlcul de resultats (lògica centralitzada) ────────────────────────────

  /// Jugadors que no han estat eliminats.
  List<Player> get _alivePlayers =>
      allPlayers.where((p) => status[p.name] != 'eliminated').toList();

  /// Jugadors marcats explícitament com vencedors.
  List<Player> get _markedWinners =>
      allPlayers.where((p) => status[p.name] == 'winner').toList();

  /// Determinació de guanyadors definitius.
  List<Player> _computeWinners() {
    final alive = _alivePlayers;
    if (alive.length == 1) return [alive.first];
    if (alive.length > 1) return _markedWinners;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alive = _alivePlayers;
    final winners = _computeWinners();

    // Últimes paraules amb contingut
    final lastWordsEntries = lastWords.entries
        .where((e) => e.value.isNotEmpty)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultats de la partida'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── 1. Bloc de vencedors ─────────────────────────────────────
            _WinnersBlock(
              winners: winners,
              alivePlayers: alive,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 24),

            // ── 2. Jugadors vius / supervivents ──────────────────────────
            _SectionHeader(
              icon: Icons.favorite,
              iconColor: Colors.green,
              title: 'Jugadors vius (${alive.length})',
            ),
            const SizedBox(height: 8),
            if (alive.isEmpty)
              _EmptyNote(
                text: 'No queda cap jugador viu.',
                colorScheme: colorScheme,
              )
            else
              ...alive.map((player) {
                final isWinner = winners.any((w) => w.name == player.name);
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isWinner
                      ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isWinner
                          ? colorScheme.primary
                          : Colors.green.withValues(alpha: 0.2),
                      foregroundColor:
                          isWinner ? Colors.white : Colors.green,
                      child: Icon(isWinner ? Icons.emoji_events : Icons.person),
                    ),
                    title: Text(
                      player.name,
                      style: TextStyle(
                        fontWeight: isWinner
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    trailing: isWinner
                        ? Chip(
                            avatar: const Icon(Icons.star,
                                size: 14, color: Colors.white),
                            label: const Text('Guanyador'),
                            backgroundColor: colorScheme.primary,
                            labelStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : const Chip(
                            label: Text('Supervivent'),
                            labelStyle: TextStyle(fontSize: 11),
                          ),
                  ),
                );
              }),

            // ── 3. Historial d'assassinats ────────────────────────────────
            if (killHistory.isNotEmpty) ...[
              const SizedBox(height: 24),
              const _SectionHeader(
                icon: Icons.gavel,
                iconColor: Colors.deepOrange,
                title: 'Qui ha matat a qui',
              ),
              const SizedBox(height: 8),
              ...killHistory.map(
                (record) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          Colors.deepOrange.withValues(alpha: 0.15),
                      foregroundColor: Colors.deepOrange,
                      child: const Icon(Icons.gavel, size: 18),
                    ),
                    title: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: record.killer,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '  →  '),
                          TextSpan(
                            text: record.victim,
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    subtitle: (record.lastWords != null &&
                            record.lastWords!.isNotEmpty)
                        ? Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.format_quote,
                                    size: 14, color: colorScheme.outline),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    record.lastWords!,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ],

            // ── 4. Últimes paraules (de rendicions sense KillRecord) ───────
            // Mostrem les últimes paraules de jugadors eliminats que NO
            // apareixen ja a l'historial de kills (per evitar duplicats).
            if (lastWordsEntries.isNotEmpty) ...[
              () {
                final lastWordsWithoutKill = lastWordsEntries
                    .where((e) =>
                        !killHistory.any((r) =>
                            r.victim == e.key &&
                            r.lastWords != null &&
                            r.lastWords!.isNotEmpty))
                    .toList();
                if (lastWordsWithoutKill.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const _SectionHeader(
                      icon: Icons.chat_bubble_outline,
                      iconColor: Colors.purple,
                      title: 'Últimes paraules',
                    ),
                    const SizedBox(height: 8),
                    ...lastWordsWithoutKill.map(
                      (entry) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                Colors.purple.withValues(alpha: 0.15),
                            foregroundColor: Colors.purple,
                            child: const Icon(Icons.chat_bubble_outline,
                                size: 18),
                          ),
                          title: Text(
                            entry.key,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.format_quote,
                                    size: 14, color: colorScheme.outline),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }(),
            ],

            const SizedBox(height: 24),

            // ── Botó per tornar a l'inici ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Tornar a l\'inici'),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blocs auxiliars ───────────────────────────────────────────────────────────

class _WinnersBlock extends StatelessWidget {
  final List<Player> winners;
  final List<Player> alivePlayers;
  final ColorScheme colorScheme;

  const _WinnersBlock({
    required this.winners,
    required this.alivePlayers,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: winners.isNotEmpty
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: winners.isNotEmpty
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            winners.isNotEmpty
                ? Icons.emoji_events
                : Icons.sentiment_neutral,
            size: 48,
            color: winners.isNotEmpty
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            winners.isEmpty
                ? 'Cap guanyador'
                : winners.length == 1
                    ? 'Vencedor / Vencedora'
                    : 'Vencedors',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: winners.isNotEmpty
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          if (winners.isNotEmpty) ...[
            Text(
              winners.map((p) => p.name).join(', '),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimaryContainer,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              alivePlayers.length == 1
                  ? 'Últim supervivent de la partida!'
                  : 'Marcats com a vencedors de la partida!',
              style: TextStyle(
                fontSize: 12,
                color:
                    colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
            ),
          ] else ...[
            Text(
              alivePlayers.isEmpty
                  ? 'Tots els jugadors han estat eliminats.'
                  : 'Hi ha supervivents però cap marcat com a vencedor.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _EmptyNote({required this.text, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          text,
          style: TextStyle(color: colorScheme.outline),
        ),
      ),
    );
  }
}
