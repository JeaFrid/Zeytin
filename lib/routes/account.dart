import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zeytin/logic/account.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/logic/gatekeeper.dart';
import 'package:zeytin/models/response.dart';
import 'package:zeytin/config.dart';
import 'package:zeytin/tools/ip.dart';

void accountRoutes(Zeytin zeytin, Router router) {
  router.post('/truck/create', (Request request) async {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    final String? email = data['email'];
    final String? password = data['password'];

    if (email == null || password == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Email and password parameters are mandatory.",
          ).toMap(),
        ),
      );
    }
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
    final data = jsonDecode(payload);

    final String? email = data['email'];
    final String? password = data['password'];

    if (email == null || password == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Email and password parameters are mandatory.",
          ).toMap(),
        ),
      );
    }

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
