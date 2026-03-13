import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/models/response.dart';
import 'package:zeytin/routes/token.dart';
import 'package:zeytin/tools/tokener.dart';
import 'package:zeytin/logic/mail.dart';

void mailRoutes(Zeytin zeytin, Router router) {
  router.post('/mail/send', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];

    if (token == null || data == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Token and data parameters are mandatory.",
          ).toMap(),
        ),
      );
    }

    var tokenData = getTokenData(token);
    if (tokenData == null || !isTokenValid(token)) {
      return Response.forbidden(
        jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Invalid or expired token.",
          ).toMap(),
        ),
      );
    }

    String password = tokenData["password"];
    Map<String, dynamic> dataDecrypted;

    try {
      dataDecrypted = ZeytinTokener(password).decryptMap(data);
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Data decryption failed. Invalid payload.",
          ).toMap(),
        ),
      );
    }

    final String? to = dataDecrypted['to'];
    final String? subject = dataDecrypted['subject'];
    final String? html = dataDecrypted['html'];

    if (to == null || subject == null || html == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error:
                "to, subject, and html parameters are required in encrypted data.",
          ).toMap(),
        ),
      );
    }

    bool isSent = await EmailService.sendCustomEmail(
      toEmail: to,
      subject: subject,
      htmlContent: html,
    );

    if (isSent) {
      return Response.ok(
        jsonEncode(
          ZeytinResponse(
            isSuccess: true,
            message: "Email deployed successfully!",
          ).toMap(),
        ),
      );
    } else {
      return Response.internalServerError(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Failed to send email. Check server logs.",
          ).toMap(),
        ),
      );
    }
  });
}
