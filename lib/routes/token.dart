import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'package:zeytin/logic/account.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/models/response.dart';

List<Map<String, dynamic>> tokens = [];
void tokenRoutes(Zeytin zeytin, Router router) {
  router.post('/token/create', (Request request) async {
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
            error:
                "Email and password parameters are mandatory when making requests to this endpoint.",
          ).toMap(),
        ),
      );
    }
    String? myToken = getTokenByCredentials(email, password);
    if (myToken != null) {
      bool valid = isTokenValid(myToken);
      if (valid) {
        return Response.ok(
          jsonEncode(
            ZeytinResponse(
              isSuccess: true,
              message: "Oki doki!",
              data: {"token": myToken},
            ).toMap(),
          ),
        );
      } else {
        return await _createToken(zeytin, router, email, password);
      }
    } else {
      return await _createToken(zeytin, router, email, password);
    }
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
