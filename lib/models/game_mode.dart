/// Formas predefinidas de "eliminar" al objetivo.
///
/// Es solo información que se muestra a los jugadores: nunca cambia el
/// funcionamiento de la app. Es el propio grupo el que decide y hace
/// cumplir la norma sobre el terreno.
enum GameMode { kiss, item, word, custom }

const Map<GameMode, String> gameModeTitles = {
  GameMode.kiss: 'Dona un petó a la galta',
  GameMode.item: 'Dóna-li un objecte',
  GameMode.word: 'Paraula secreta',
  GameMode.custom: 'Personalitzat',
};

const Map<GameMode, String> gameModeDescriptions = {
  GameMode.kiss: 'Dona un petó al teu objectiu sense que ningú et vegi.',
  GameMode.item: 'Fes que el teu objectiu porti l\'objecte definit.',
  GameMode.word: 'Digues-li al teu objectiu la paraula secreta.',
};
