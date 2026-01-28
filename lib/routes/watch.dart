import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:zeytin/logic/engine.dart';
import 'package:zeytin/routes/token.dart';
import 'package:zeytin/tools/tokener.dart';

void watchRoutes(Zeytin zeytin, Router router) {
  router.get('/data/watch/<token>/<boxId>', (
    Request request,
    String token,
    String boxId,
  ) {
    return webSocketHandler((WebSocketChannel webSocket, _) {
      final tokenData = getTokenData(token);

      if (tokenData == null || !isTokenValid(token)) {
        webSocket.sink.add(jsonEncode({"error": "Unauthorized"}));
        webSocket.sink.close();
        return;
      }

      final String truckId = tokenData["truck"];
      final String password = tokenData["password"];
      final tokener = ZeytinTokener(password);

      final subscription = zeytin.changes.listen((change) {
        // Sadece bu kullanıcıya ait TRUCK ve seçtiği BOX ise gönder
        if (change["truckId"] == truckId && change["boxId"] == boxId) {
          final payload = {
            "op": change["op"],
            "tag": change["tag"],
            "data": change["value"] != null
                ? tokener.encryptMap(change["value"])
                : null,
            "entries": change["entries"] != null
                ? tokener.encryptMap(change["entries"])
                : null,
          };
          webSocket.sink.add(jsonEncode(payload));
        }
      });

      webSocket.stream.listen(
        null,
        onDone: () {
          subscription.cancel();
        },
      );
    })(request);
  });
}
