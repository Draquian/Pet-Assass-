import 'dart:math';

import '../models/player.dart';

/// Lógica pura del juego: generar identificadores, barajar en círculo y
/// calcular objetivos. Es una lista enlazada circular clásica:
/// P1 -> P2 -> P3 -> ... -> Pn -> P1.
///
/// Cuando alguien elimina a su objetivo, ese jugador desaparece de la
/// cadena y el cazador "hereda" directamente el objetivo de su víctima.
/// Esto se resuelve solo, jugador a jugador, sin que ningún dispositivo
/// necesite conocer la cadena completa (ver GameState).
class GameService {
  static String generateGameId() {
    final rnd = Random.secure();
    return List.generate(6, (_) => rnd.nextInt(10)).join();
  }

  static String generatePin() {
    final rnd = Random.secure();
    return List.generate(4, (_) => rnd.nextInt(10)).join();
  }

  /// Devuelve una nueva lista con los jugadores en un orden aleatorio,
  /// que se interpreta como un círculo (el último apunta al primero).
  static List<Player> shuffleCircular(List<Player> players) {
    final list = List<Player>.from(players);
    list.shuffle(Random.secure());
    return list;
  }

  /// Dado el orden circular completo y mi nombre, calcula a quién persigo.
  static String? targetFor(List<Player> orderedPlayers, String myName) {
    final index = orderedPlayers.indexWhere((p) => p.name == myName);
    if (index == -1) return null;
    final nextIndex = (index + 1) % orderedPlayers.length;
    return orderedPlayers[nextIndex].name;
  }

  /// Dado el orden circular completo y mi nombre, calcula quién me persigue a mí.
  static String? hunterFor(List<Player> orderedPlayers, String myName) {
    final index = orderedPlayers.indexWhere((p) => p.name == myName);
    if (index == -1) return null;
    final prevIndex = (index - 1 + orderedPlayers.length) % orderedPlayers.length;
    return orderedPlayers[prevIndex].name;
  }
}
