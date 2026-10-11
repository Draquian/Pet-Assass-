import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_state.dart';

/// Guarda el estado de la partida en el almacenamiento local del móvil,
/// para que sobreviva a cerrar la app o reiniciar el teléfono. No se
/// guarda nada más: en particular, nunca se persiste la lista completa
/// de jugadores, solo el nombre y el objetivo propios.
class StorageService {
  static const _key = 'peto_assessi_game_state';

  static Future<void> saveState(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  static Future<GameState?> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return GameState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
