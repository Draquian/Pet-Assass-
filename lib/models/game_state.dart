/// Estado de la partida tal como lo ve ESTE móvil.
///
/// Importante: no existe un estado global compartido (no hay servidor).
/// Cada dispositivo solo conoce su propio estado: quién es, si sigue vivo,
/// y a quién persigue ahora mismo. Esto es intencional: así ningún
/// dispositivo necesita conocer la cadena completa de la partida.
enum PlayerStatus { none, alive, eliminated, winner }

class GameState {
  final String gameId;
  final String myName;
  final String myPin;
  final PlayerStatus status;
  final String? currentTarget;

  /// Descripción de cómo se elimina en esta partida (informativo).
  final String gameMode;

  /// Ítem u objeto asignado a este jugador para eliminar a su objetivo.
  /// Solo se rellena en modos 'item' o 'word'.
  final String? assignedItem;

  /// Nom del jugador que m'està perseguint a mi (qui em vol donar el petó).
  /// Es calcula a partir de l'ordre circular en el moment d'identificar-se
  /// i s'hereta quan es fa un traspàs d'objectiu.
  final String? myHunter;

  const GameState({
    required this.gameId,
    required this.myName,
    required this.myPin,
    required this.status,
    this.currentTarget,
    this.gameMode = '',
    this.assignedItem,
    this.myHunter,
  });

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'myName': myName,
        'myPin': myPin,
        'status': status.name,
        'currentTarget': currentTarget,
        'gameMode': gameMode,
        'assignedItem': assignedItem,
        'myHunter': myHunter,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        gameId: json['gameId'] as String,
        myName: json['myName'] as String,
        myPin: json['myPin'] as String,
        status: PlayerStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => PlayerStatus.none,
        ),
        currentTarget: json['currentTarget'] as String?,
        gameMode: json['gameMode'] as String? ?? '',
        assignedItem: json['assignedItem'] as String?,
        myHunter: json['myHunter'] as String?,
      );
}
