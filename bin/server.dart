import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';
import 'package:zeytin/config.dart';
import 'package:zeytin/html/hello_world.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/logic/gatekeeper.dart';
import 'package:zeytin/routes/account.dart';
import 'package:zeytin/routes/call.dart';
import 'package:zeytin/routes/crud.dart';
import 'package:zeytin/routes/storage.dart';
import 'package:zeytin/routes/token.dart';
import 'package:zeytin/routes/watch.dart';

void main() async {
  final router = Router();
  var zeytin = Zeytin("./zeytin");
  var zeytinError = Zeytin("./zeytin_err");

  router.get('/', (Request request) {
    return Response.ok(helloWorldHTML, headers: {'content-type': 'text/html'});
  });
  router.get('/github', (Request request) {
    return Response.found('https://github.com/JeaFrid/zeytin');
  });

  accountRoutes(zeytin, router);
  crudRoutes(zeytin, router);
  tokenRoutes(zeytin, router);
  storageRoutes(zeytin, router);
  watchRoutes(zeytin, router);
  callRoutes(zeytin, router);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware((innerHandler) {
        return (request) async {
          if (request.method == 'OPTIONS') {
            return Response.ok(
              '',
              headers: {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods':
                    'GET, POST, PUT, DELETE, OPTIONS',
                'Access-Control-Allow-Headers':
                    'Origin, Content-Type, X-Auth-Token, Authorization',
              },
            );
          }
          final response = await innerHandler(request);
          return response.change(
            headers: {
              'Access-Control-Allow-Origin': '*',
              'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'Access-Control-Allow-Headers':
                  'Origin, Content-Type, X-Auth-Token, Authorization',
            },
          );
        };
      })
      .addMiddleware(handleErrorsMiddleware(zeytinError))
      .addMiddleware(jsonResponseMiddleware())
      .addMiddleware(gatekeeperMiddleware())
      .addHandler(router.call);

  // Dynamic port priority: Env > Config
  final int port = int.parse(
    Platform.environment['ZEYTIN_PORT'] ?? ZeytinConfig.serverPort.toString(),
  );
  final server = await serve(handler, '0.0.0.0', port);
  print('The Zeytin server has started on port ${server.port}! Have fun!');
}

Middleware gatekeeperMiddleware() {
  return (innerHandler) {
    return (request) async {
      final securityCheck = await Gatekeeper.check(request);
      if (securityCheck != null) {
        return securityCheck;
      }
      return await innerHandler(request);
    };
  };
}

Middleware handleErrorsMiddleware(Zeytin zeytinError) {
  return (innerHandler) {
    return (request) async {
      if (request.headers['upgrade']?.toLowerCase() == 'websocket') {
        return innerHandler(request);
      }

      try {
        return await innerHandler(request);
      } catch (e, stackTrace) {
        String code = Uuid().v4();
        print("Error Code: $code");
        print("Exception: $e");
        print("StackTrace: $stackTrace");

        await zeytinError.put(
          truckId: "system",
          boxId: "errors",
          tag: code,
          value: {
            "code": code,
            "error": e.toString(),
            "stackTrace": stackTrace.toString(),
            "createdAt": DateTime.now().toIso8601String(),
          },
        );

        return Response.internalServerError(
          body: jsonEncode({
            "isSuccess": false,
            "message": "System Error",
            "error": "Error Code: $code. Contact system administrator.",
          }),
        );
      }
    };
  };
}

Middleware jsonResponseMiddleware() {
  return (innerHandler) {
    return (request) async {
      final response = await innerHandler(request);

      if (response.headers.containsKey('content-type')) {
        return response;
      }

      return response.change(headers: {'content-type': 'application/json'});
    };
  };
}
