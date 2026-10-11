/// Representa a un jugador dentro de la ronda circular de la partida.
///
/// El [pin] es un código de 4 dígitos que el master reparte en persona a
/// cada jugador. Sirve para que, al identificarse tras escanear el QR
/// inicial, nadie pueda seleccionar el nombre de otra persona por error
/// o a propósito.
class Player {
  final String name;
  final String pin;

  const Player({required this.name, required this.pin});

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        name: json['n'] as String,
        pin: json['p'] as String,
      );

  Map<String, dynamic> toJson() => {'n': name, 'p': pin};
}
