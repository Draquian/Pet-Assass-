import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as enc;

/// Cifra y descifra el contenido de los códigos QR con AES-256 (CBC).
///
/// LIMITACIÓN DE SEGURIDAD (léela, es importante):
/// La clave está incrustada en el código de la app y es la misma para
/// todas las instalaciones. Esto impide que alguien lea el contenido de
/// un QR con un lector genérico o una web de "escanear QR online",
/// que era el riesgo principal a evitar. NO protege frente a alguien que
/// descompile la propia app para extraer la clave: es un cifrado
/// "anti-cotilleo casual", no de grado militar. Para una partida entre
/// amigos es más que suficiente.
///
/// Si algún día quieres cerrar del todo esa puerta, la alternativa es
/// que el master muestre un QR individual y distinto a cada jugador
/// (modo "máxima privacidad" que descartamos para esta primera versión).
class CryptoService {
  static const String _passphrase = 'PetoAssessi-clave-de-partida-2026';

  static enc.Key get _key {
    final digest = crypto.sha256.convert(utf8.encode(_passphrase));
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Cifra un mapa JSON y lo devuelve como texto listo para meter en un QR.
  static String encryptJson(Map<String, dynamic> data) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(jsonEncode(data), iv: iv);
    // Guardamos IV + texto cifrado juntos para poder descifrar después.
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return base64Url.encode(combined);
  }

  /// Descifra el texto leído de un QR. Devuelve null si no es válido
  /// (QR de otra app, corrupto, o cifrado con otra clave).
  static Map<String, dynamic>? decryptJson(String payload) {
    try {
      final combined = base64Url.decode(payload);
      if (combined.length <= 16) return null;
      final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
      final cipherBytes = Uint8List.fromList(combined.sublist(16));
      final encrypter = enc.Encrypter(enc.AES(_key, mode: enc.AESMode.cbc));
      final decrypted = encrypter.decrypt(enc.Encrypted(cipherBytes), iv: iv);
      return jsonDecode(decrypted) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}
