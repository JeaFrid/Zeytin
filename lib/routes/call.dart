import 'dart:async';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/logic/live_engine.dart';
import 'package:zeytin/routes/token.dart';
import 'package:zeytin/tools/tokener.dart';
import 'package:zeytin/config.dart';
import 'package:uuid/uuid.dart';

void callRoutes(Zeytin zeytin, Router router) {
  router.post('/call/join', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];

    if (token == null || data == null) {
      return Response.badRequest(body: "Missing parameters");
    }

    var tokenData = getTokenData(token);
    if (tokenData == null || !isTokenValid(token)) {
      return Response.forbidden("Invalid token");
    }
    String password = tokenData["password"];

    try {
      var params = ZeytinTokener(password).decryptMap(data);
      String roomName = params["roomName"];
      String uid = params["uid"];
      String connectionIdentity = "$uid-${const Uuid().v4().substring(0, 6)}";

      String liveToken = LiveEngine.createToken(
        roomName: roomName,
        identity: connectionIdentity,
        name: "User-$uid",
        isAdmin: true,
      );

      final responseData = ZeytinTokener(
        password,
      ).encryptMap({"serverUrl": ZeytinConfig.liveKitUrl, "token": liveToken});

      return Response.ok(
        jsonEncode({
          "isSuccess": true,
          "message": "Ready to connect",
          "data": responseData,
        }),
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({"error": e.toString()}),
      );
    }
  });

  router.post('/call/check', (Request request) async {
    final payload = await request.readAsString();
    final datas = jsonDecode(payload);

    final String? token = datas['token'];
    final String? data = datas['data'];

    if (token == null || data == null) {
      return Response.badRequest(body: "Missing parameters");
    }

    var tokenData = getTokenData(token);
    if (tokenData == null || !isTokenValid(token)) {
      return Response.forbidden("Invalid token");
    }
    String password = tokenData["password"];

    try {
      var params = ZeytinTokener(password).decryptMap(data);
      String roomName = params["roomName"];
      bool isActive = await LiveEngine.isRoomActive(roomName);

      final responseData = ZeytinTokener(
        password,
      ).encryptMap({"isActive": isActive});

      return Response.ok(
        jsonEncode({
          "isSuccess": true,
          "message": "Checked",
          "data": responseData,
        }),
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({"error": e.toString()}),
      );
    }
  });

  router.get('/call/stream/<token>', (Request request, String token) {
    return webSocketHandler((WebSocketChannel webSocket, a) {
      var tokenData = getTokenData(token);
      if (tokenData == null || !isTokenValid(token)) {
        webSocket.sink.add(jsonEncode({"error": "Unauthorized"}));
        webSocket.sink.close();
        return;
      }
      String password = tokenData["password"];

      String? encryptedData = request.url.queryParameters['data'];
      if (encryptedData == null) {
        webSocket.sink.add(jsonEncode({"error": "Missing data parameter"}));
        webSocket.sink.close();
        return;
      }

      String roomName;
      try {
        var params = ZeytinTokener(password).decryptMap(encryptedData);
        roomName = params["roomName"];
      } catch (e) {
        webSocket.sink.add(jsonEncode({"error": "Invalid data encryption"}));
        webSocket.sink.close();
        return;
      }

      bool? lastStatus;
      Timer? timer;

      LiveEngine.isRoomActive(roomName).then((isActive) {
        lastStatus = isActive;
        webSocket.sink.add(jsonEncode({"isActive": isActive}));
      });

      timer = Timer.periodic(Duration(seconds: 5), (_) async {
        bool currentStatus = await LiveEngine.isRoomActive(roomName);
        if (currentStatus != lastStatus) {
          lastStatus = currentStatus;
          webSocket.sink.add(jsonEncode({"isActive": currentStatus}));
        }
      });

      webSocket.stream.listen(
        (message) {},
        onDone: () {
          timer?.cancel();
        },
        onError: (error) {
          timer?.cancel();
        },
      );
    })(request);
  });
}
