import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zeytin/logic/account.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/models/response.dart';
import 'package:zeytin/config.dart';
import 'package:zeytin/tools/ip.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert' as convert;

void adminRoutes(Zeytin zeytin, Router router) {
  router.post('/admin/truck/create', (Request request) async {
    final clientIp = getClientIp(request);
    if (clientIp != '127.0.0.1' && clientIp != 'localhost' && clientIp != '::1') {
      return Response.forbidden(
        jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Access Denied",
            error: "Admin endpoints are only accessible from localhost.",
          ).toMap(),
        ),
      );
    }

    final payload = await request.readAsString();
    final data = jsonDecode(payload);
    final String? adminSecret = data['adminSecret'];
    if (adminSecret == null || adminSecret != ZeytinConfig.adminSecret) {
      return Response.forbidden(
        jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Access Denied",
            error: "Invalid admin secret.",
          ).toMap(),
        ),
      );
    }

    final String? email = data['email'];
    final String? password = data['password'];

    if (email == null || password == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Bad Request",
            error: "Email and password are required.",
          ).toMap(),
        ),
      );
    }
    if (zeytin.getAllTruck().length >= ZeytinConfig.maxTruckCount) {
      return Response(
        507,
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Storage Full",
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
      return Response.ok(
        jsonEncode(
          ZeytinResponse(
            isSuccess: true,
            message: "Account created successfully!",
            data: {
              "truckId": zeytinResponse.data!['id'],
              "email": email,
              "password": password,
            },
          ).toMap(),
        ),
      );
    } else {
      return Response.badRequest(body: jsonEncode(zeytinResponse.toMap()));
    }
  });

  router.post('/admin/truck/changePassword', (Request request) async {
    final clientIp = getClientIp(request);
    if (clientIp != '127.0.0.1' && clientIp != 'localhost' && clientIp != '::1') {
      return Response.forbidden(
        jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Access Denied",
            error: "Admin endpoints are only accessible from localhost.",
          ).toMap(),
        ),
      );
    }

    final payload = await request.readAsString();
    final data = jsonDecode(payload);
    final String? adminSecret = data['adminSecret'];
    if (adminSecret == null || adminSecret != ZeytinConfig.adminSecret) {
      return Response.forbidden(
        jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Access Denied",
            error: "Invalid admin secret.",
          ).toMap(),
        ),
      );
    }

    final String? email = data['email'];
    final String? newPassword = data['newPassword'];

    if (email == null || newPassword == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Bad Request",
            error: "Email and newPassword are required.",
          ).toMap(),
        ),
      );
    }
    final results = await zeytin.filter(
      'system',
      'trucks',
      (data) => data['email']?.toString().toLowerCase() == email.toLowerCase(),
    );

    if (results.isEmpty) {
      return Response.notFound(
        jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Not Found",
            error: "No account found with this email address.",
          ).toMap(),
        ),
      );
    }

    final truckData = results.first;
    final targetTruckId = truckData['id'] as String;
    final passwordBytes = convert.utf8.encode(newPassword + targetTruckId);
    final hashedPassword = sha256.convert(passwordBytes).toString();
    truckData['password'] = hashedPassword;
    truckData['passwordUpdatedAt'] = DateTime.now().toIso8601String();
    await zeytin.put(
      truckId: 'system',
      boxId: 'trucks',
      tag: targetTruckId,
      value: truckData,
    );
    return Response.ok(
      jsonEncode(
        ZeytinResponse(
          isSuccess: true,
          message: "Password changed successfully!",
          data: {
            "truckId": targetTruckId,
            "email": email,
            "newPassword": newPassword,
          },
        ).toMap(),
      ),
    );
  });
}
