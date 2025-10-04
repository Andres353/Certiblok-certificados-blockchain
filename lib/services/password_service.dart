// lib/services/password_service.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordService {
  /// Genera un hash SHA-256 de la contraseña
  static String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifica si la contraseña coincide con el hash
  static bool verifyPassword(String password, String hashedPassword) {
    return hashPassword(password) == hashedPassword;
  }
}
