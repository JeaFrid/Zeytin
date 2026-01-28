import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/models/response.dart';

class ZeytinAccounts {
  static String _generateHash(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    return sha256.convert(bytes).toString();
  }

  static Future<bool> isEmailRegistered(Zeytin zeytin, String email) async {
    final results = await zeytin.filter(
      "system",
      "trucks",
      (data) => data["email"] == email,
    );
    return results.isNotEmpty;
  }

  static Future<ZeytinResponse> createAccount(
    Zeytin zeytin,
    String email,
    String password,
  ) async {
    
    if (await isEmailRegistered(zeytin, email)) {
      return ZeytinResponse(
        isSuccess: false,
        message: "Opss...",
        error: "This email has been used before.",
      );
    }

    String truckID = const Uuid().v1();
    String hashedPassword = _generateHash(password, truckID);

    await zeytin.put(
      truckId: "system",
      boxId: "trucks",
      tag: truckID,
      value: {
        "email": email,
        "password": hashedPassword,
        "id": truckID,
        "createdAt": DateTime.now().toIso8601String(),
      },
    );
    await Directory(
      "${zeytin.rootPath}/$truckID/storage",
    ).create(recursive: true);
    await zeytin.createTruck(truckId: truckID);
    return ZeytinResponse(
      isSuccess: true,
      message: "Oki doki!",
      data: {"id": truckID},
    );
  }

  static Future<ZeytinResponse> login(
    Zeytin zeytin,
    String email,
    String password,
  ) async {
    final results = await zeytin.filter(
      "system",
      "trucks",
      (data) => data["email"] == email,
    );

    if (results.isNotEmpty) {
      String truckID = results.first["id"];
      String storedHash = results.first["password"];
      String loginHash = _generateHash(password, truckID);

      if (storedHash == loginHash) {
        return ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: {"id": truckID},
        );
      }
    }
    return ZeytinResponse(
      isSuccess: false,
      message: "Opss...",
      error: "The email or password doesn't match.",
    );
  }
}
