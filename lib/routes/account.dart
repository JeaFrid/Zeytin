import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zeytin/logic/account.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/models/response.dart';
import 'package:zeytin/tools/tokener.dart';
import 'package:zeytin/routes/token.dart';

void accountRoutes(Zeytin zeytin, Router router) {
  router.post('/truck/id', (Request request) async {
    final payload = await request.readAsString();
    final incomingData = jsonDecode(payload);

    final String? encryptedPayload = incomingData['data'];

    if (encryptedPayload == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Secure payload required.",
          ).toMap(),
        ),
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
        jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Invalid or expired handshake key.",
          ).toMap(),
        ),
      );
    }

    final parts = decryptedData.split('|');
    if (parts.length != 2) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Invalid payload format.",
          ).toMap(),
        ),
      );
    }

    final String email = parts[0];
    final String password = parts[1];

    ZeytinResponse zeytinResponse = await ZeytinAccounts.login(
      zeytin,
      email,
      password,
    );

    if (zeytinResponse.isSuccess) {
      return Response.ok(jsonEncode(zeytinResponse.toMap()));
    } else {
      return Response.badRequest(body: jsonEncode(zeytinResponse.toMap()));
    }
  });
}
