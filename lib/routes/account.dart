import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zeytin/logic/account.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/logic/gatekeeper.dart';
import 'package:zeytin/models/response.dart';
import 'package:zeytin/config.dart';
import 'package:zeytin/tools/ip.dart';
import 'package:zeytin/tools/tokener.dart';
import 'package:zeytin/routes/token.dart';

void accountRoutes(Zeytin zeytin, Router router) {
  router.post('/truck/create', (Request request) async {
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

    final String ip = getClientIp(request);
    final activity = Gatekeeper.ipRegistry[ip];
    final now = DateTime.now().millisecondsSinceEpoch;

    if (activity != null) {
      if (activity.truckCount >= ZeytinConfig.maxTruckPerIp) {
        activity.isBanned = true;
        return Response.forbidden(
          jsonEncode(
            ZeytinResponse(
              isSuccess: false,
              message: "Opss...",
              error:
                  "You have reached the maximum truck limit for this IP. You are banned!",
            ).toMap(),
          ),
        );
      }
      if (now - activity.lastTruckCreated <
          ZeytinConfig.truckCreationCooldownMs) {
        return Response(
          429,
          body: jsonEncode(
            ZeytinResponse(
              isSuccess: false,
              message: "Opss...",
              error:
                  "You can only create one truck every 10 minutes. Slow down.",
            ).toMap(),
          ),
        );
      }
    }

    if (zeytin.getAllTruck().length >= ZeytinConfig.maxTruckCount) {
      return Response(
        507,
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "System storage is full. No more trucks can be created.",
          ).toMap(),
        ),
      );
    }

    ZeytinResponse zeytinResponse = await ZeytinAccounts.createAccount(
      zeytin,
      email,
      password,
    );

    if (zeytinResponse.isSuccess) {
      if (activity != null) {
        activity.lastTruckCreated = now;
        activity.truckCount++;
      }
      return Response.ok(jsonEncode(zeytinResponse.toMap()));
    } else {
      return Response.badRequest(body: jsonEncode(zeytinResponse.toMap()));
    }
  });

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
