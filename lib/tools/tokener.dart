import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class ZeytinTokener {
  final Key key;
  final Encrypter encrypter;

  ZeytinTokener(String passphrase)
    : key = _deriveKey(passphrase),
      encrypter = Encrypter(AES(_deriveKey(passphrase), mode: AESMode.cbc));

  String encryptString(String text) {
    final iv = IV.fromSecureRandom(16);
    final encrypted = encrypter.encrypt(text, iv: iv);
    return "${iv.base64}:${encrypted.base64}";
  }

  String decryptString(String encryptedData) {
    final parts = encryptedData.split(':');
    if (parts.length != 2) throw FormatException("Invalid format");
    final iv = IV.fromBase64(parts[0]);
    final decrypted = encrypter.decrypt(Encrypted.fromBase64(parts[1]), iv: iv);
    return decrypted;
  }

  static Key _deriveKey(String passphrase) {
    final bytes = utf8.encode(passphrase);
    final hash = sha256.convert(bytes).bytes;
    return Key(Uint8List.fromList(hash));
  }

  String encryptMap(Map<String, dynamic> data) {
    final iv = IV.fromSecureRandom(16);
    final plainText = jsonEncode(data);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return "${iv.base64}:${encrypted.base64}";
  }

  Map<String, dynamic> decryptMap(String encryptedData) {
    final parts = encryptedData.split(':');
    if (parts.length != 2) {
      throw FormatException("Invalid encrypted data format");
    }
    final iv = IV.fromBase64(parts[0]);
    final cipherText = parts[1];
    final decrypted = encrypter.decrypt(
      Encrypted.fromBase64(cipherText),
      iv: iv,
    );
    return jsonDecode(decrypted) as Map<String, dynamic>;
  }
}
