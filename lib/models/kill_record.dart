/// Registre d'una eliminació: qui ha matat a qui.
///
/// Només es crea quan hi ha un asesinato real (not a rendició sense killer).
/// Les rendicions que no tenen un killer identificat no generen KillRecord.
///
/// Camps:
/// - [killer]: nom del jugador que ha eliminat.
/// - [victim]: nom del jugador eliminat.
/// - [lastWords]: últimes paraules opcionals del victim (pot ser null o buit).
class KillRecord {
  final String killer;
  final String victim;
  final String? lastWords;

  const KillRecord({
    required this.killer,
    required this.victim,
    this.lastWords,
  });

  Map<String, dynamic> toJson() => {
        'killer': killer,
        'victim': victim,
        if (lastWords != null && lastWords!.isNotEmpty) 'lastWords': lastWords,
      };

  factory KillRecord.fromJson(Map<String, dynamic> json) => KillRecord(
        killer: json['killer'] as String,
        victim: json['victim'] as String,
        lastWords: json['lastWords'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      other is KillRecord &&
      other.killer == killer &&
      other.victim == victim;

  @override
  int get hashCode => Object.hash(killer, victim);
}
