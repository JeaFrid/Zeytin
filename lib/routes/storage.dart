import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mime/mime.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/models/response.dart';
import 'package:zeytin/routes/token.dart';

void storageRoutes(Zeytin zeytin, Router router) {
  router.post('/storage/upload', (Request request) async {
    final multipartRequest = request.multipart();

    if (multipartRequest == null) {
      return Response.badRequest(
        body: jsonEncode(
          ZeytinResponse(
            isSuccess: false,
            message: "Opss...",
            error: "Multipart request expected.",
          ).toMap(),
        ),
      );
    }

    String? token;
    String? truckId;
    final forbiddenExtensions = [
      '.exe',
      '.sh',
      '.bat',
      '.php',
      '.py',
      '.js',
      '.htm',
      '.html',
      '.svg',
    ];

    await for (final part in multipartRequest.parts) {
      final contentDisposition = part.headers['content-disposition'];
      if (contentDisposition == null) continue;

      if (contentDisposition.contains('name="token"')) {
        token = await part.readString();
        final tokenData = getTokenData(token);
        if (tokenData != null) {
          truckId = tokenData["truck"];
        }
      }

      if (contentDisposition.contains('name="file"')) {
        if (token == null || truckId == null) {
          return Response.forbidden(
            jsonEncode(
              ZeytinResponse(
                isSuccess: false,
                message: "Opss...",
                error: "Invalid or missing token before file part.",
              ).toMap(),
            ),
          );
        }

        final match = RegExp(
          r'filename="([^"]+)"',
        ).firstMatch(contentDisposition);
        final fileName = match?.group(1) ?? "unnamed_file";
        final extension = p.extension(fileName).toLowerCase();
        final safeName = fileName.replaceAll(RegExp(r'[^\w\-. ]'), '');
        if (safeName != fileName ||
            fileName.contains('..') ||
            !fileName.contains('.')) {
          return Response.forbidden(
            jsonEncode(
              ZeytinResponse(
                isSuccess: false,
                message: "Opss...",
                error: "The file name contains invalid characters!",
              ).toMap(),
            ),
          );
        }
        if (forbiddenExtensions.contains(extension)) {
          return Response.forbidden(
            jsonEncode(
              ZeytinResponse(
                isSuccess: false,
                message: "Risky file!",
                error:
                    "I know you're innocent. You're not a malicious hacker. But still, to be on the safe side, I can't accept these files.",
              ).toMap(),
            ),
          );
        }

        final storageDir = Directory("${zeytin.rootPath}/$truckId/storage");
        if (!await storageDir.exists()) {
          await storageDir.create(recursive: true);
        }

        final file = File(p.join(storageDir.path, fileName));
        final ios = file.openWrite();
        await ios.addStream(part);
        await ios.close();

        return Response.ok(
          jsonEncode(
            ZeytinResponse(
              isSuccess: true,
              message: "Oki doki!",
              data: {"url": "/$truckId/$fileName"},
            ).toMap(),
          ),
        );
      }
    }

    return Response.badRequest(
      body: jsonEncode(
        ZeytinResponse(
          isSuccess: false,
          message: "Opss...",
          error: "Missing file part.",
        ).toMap(),
      ),
    );
  });

  router.get('/<truckId>/<fileName>', (
    Request request,
    String truckId,
    String fileName,
  ) async {
    final filePath = "${zeytin.rootPath}/$truckId/storage/$fileName";
    final file = File(filePath);

    if (await file.exists()) {
      final contentType =
          lookupMimeType(fileName) ?? 'application/octet-stream';

      return Response.ok(
        file.openRead(),
        headers: {'Content-Type': contentType, 'Content-Disposition': 'inline'},
      );
    }

    return Response.notFound(
      jsonEncode(
        ZeytinResponse(
          isSuccess: false,
          message: "Opss...",
          error: "Dosya bulunamadı.",
        ).toMap(),
      ),
    );
  });
}
