import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'package:zeytin/logic/account.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/models/response.dart';
import 'package:zeytin/tools/tokener.dart';

List<Map<String, dynamic>> tokens = [];
List<Map<String, dynamic>> handshakePool = [];

void cleanHandshakePool() {
  final now = DateTime.now().millisecondsSinceEpoch;
  handshakePool.removeWhere((element) => now > element['expires']);
}

void tokenRoutes(Zeytin zeytin, Router router) {
  router.post('/token/create', (Request request) async {
    final payload = await request.readAsString();
    final incomingData = jsonDecode(payload);

    final String? encryptedPayload = incomingData['data'];

    if (encryptedPayload == null) {
      return Response.badRequest(
        body: jsonEncode({
          "isSuccess": false,
          "message": "Secure payload required.",
        }),
      );
    }

    cleanHandshakePool();

    String? decryptedData;
    for (var handshake in handshakePool) {
      try {
        decryptedData = ZeytinTokener(
          handshake['key'],
        ).decryptString(encryptedPayload);
        break;
      } catch (_) {
        continue;
      }
    }

    if (decryptedData == null) {
      return Response.forbidden(
        jsonEncode({
          "isSuccess": false,
          "message": "Invalid or expired handshake key.",
        }),
      );
    }

    final parts = decryptedData.split('|');
    if (parts.length != 2) {
      return Response.badRequest(body: "Invalid payload format");
    }

    final String email = parts[0];
    final String password = parts[1];
    return await _createToken(zeytin, router, email, password);
  });
  router.delete('/token/delete', (Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    final String? email = data['email'];
    final String? password = data['password'];

    if (email == null || password == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opps...",
            error: "Credentials are required.",
          ).toMap(),
        ),
      );
    }

    final bool deleted = _deleteTokenByCredentials(email, password);

    if (deleted) {
      return Response.ok(
        jsonEncode(
          ZeytinResponse(
            isSuccess: true,
            message: "Token deleted successfully.",
          ).toMap(),
        ),
      );
    } else {
      return Response.notFound(
        jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "No active token found or invalid credentials.",
          ).toMap(),
        ),
      );
    }
  });
  router.post('/token/handshake', (Request request) async {
    cleanHandshakePool();
    String tempKey = Uuid().v4().replaceAll('-', '').substring(0, 32);
    final now = DateTime.now().millisecondsSinceEpoch;

    handshakePool.add({"key": tempKey, "expires": now + 10000});

    return Response.ok(
      jsonEncode({
        "isSuccess": true,
        "message":
            "Handshake established. Use this key for the next 10 seconds.",
        "tempKey": tempKey,
      }),
    );
  });
}

bool _deleteTokenByCredentials(String email, String password) {
  final initialLength = tokens.length;
  tokens.removeWhere(
    (element) => element['email'] == email && element['password'] == password,
  );
  return tokens.length < initialLength;
}

Future<Response> _createToken(
  Zeytin zeytin,
  Router router,
  String email,
  String password,
) async {
  ZeytinResponse zeytinResponse = await ZeytinAccounts.login(
    zeytin,
    email,
    password,
  );
  if (zeytinResponse.isSuccess) {
    String token = Uuid().v4();
    String id = zeytinResponse.data!["id"];
    tokens.add({
      "truck": id,
      "email": email,
      "password": password,
      "token": token,
      "create_at": DateTime.now().millisecondsSinceEpoch,
    });
    return Response.ok(
      jsonEncode(
        ZeytinResponse(
          isSuccess: true,
          message: "Oki doki!",
          data: {"token": token},
        ).toMap(),
      ),
    );
  } else {
    return Response.badRequest(body: jsonEncode(zeytinResponse.toMap()));
  }
}

Map<String, dynamic>? getTokenData(String token) {
  try {
    return tokens.firstWhere((element) => element['token'] == token);
  } catch (_) {
    return null;
  }
}

bool isTokenValid(String token) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final index = tokens.indexWhere((element) => element['token'] == token);

  if (index == -1) {
    return false;
  }

  final tokenData = tokens[index];
  final createdAt = tokenData['create_at'] as int;

  if (now - createdAt > 120000) {
    tokens.removeAt(index);
    return false;
  }

  return true;
}

String? getTokenByCredentials(String email, String password) {
  try {
    final entry = tokens.firstWhere(
      (element) => element['email'] == email && element['password'] == password,
    );
    return entry['token'] as String;
  } catch (_) {
    return null;
  }
}
